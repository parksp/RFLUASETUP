-- Standalone center-trim workflow. All output changes require fresh DISARM status.
return function(h)
 local M={}
 local page='menu'
 local cfg,enabled,angles={},{},{}
 local ready,busy,blocked=false,false,false
 local state,front,selected='SELECT CENTER TRIM',false,1
 local controls,focus={},1
 local dial,edit,drag=0,false,nil
 local mode=nil
 local active={} -- Trim selection is independent of overrides that hold position.
 local live,lastPWM={},-1000
 local returnAt,notice=nil,nil
 local review=nil
 local draft,defaultTab,defaultReview,pulseChosen={},1,false,false
 local fields={'mid','min','max','scaleNeg','scalePos','rate','speed','flags'}
 local epoch,flight,pending,polling=0,false,nil,false
 local deferred=nil
 local stopping,transaction,exitAfter=false,false,false
 local lastStatus,feedbackAt=-1000,-1000
 local stop,flush,drain,sample
 local function now()return getTime and getTime()or 0 end
 local function copy(t)local r={};for k,v in pairs(t)do r[k]=type(v)=='table'and copy(v)or v end;return r end
 local function any()return enabled[0]or enabled[1]or enabled[2]end
 local function queue(cmd,payload,ok,err)rf2.mspQueue:add({command=cmd,payload=payload,processReply=ok,errorHandler=err})end
 local function fail(msg)
  stop(function()blocked=true;state=msg..' / RTN TO RETRY'end)
 end
 stop=function(done)
  if stopping then return end
  epoch=epoch+1;local token=epoch
  pending=nil;deferred=nil;review=nil;drag=nil;edit=false;busy=true;stopping=true;state='RELEASING OVERRIDES...'
  local function errorStop()
   if token~=epoch then return end
   stopping=false;busy=false;transaction=false;blocked=true;state='STOP FAILED / RTN TO RETRY'
  end
  h.disable(function()
   if token~=epoch then return end
   -- Also release mixer tests left by another setup page. Never enable a motor.
   local function release(i)
    if token~=epoch then return end
    if i>4 then
     enabled={};angles={};live={};lastPWM=-1000;mode=nil;active={};dial=0;flight=false;polling=false;stopping=false;busy=false;transaction=false;notice=nil
     if done then done()end
     return
    end
    local p={i};rf2.mspHelper.writeU16(p,2501)
    queue(191,p,function()release(i+1)end,errorStop)
   end
   release(1)
  end,errorStop)
 end
 -- Measured MSP_SERVO output, never an estimate from the requested angle.
 sample=function(done)
  polling=true;local token=epoch
  queue(103,nil,function(_,b)
   if token~=epoch then return end
   polling=false;lastPWM=now();live={}
   if #b>=6 then for i=0,2 do live[i]=b[i*2+1]+256*b[i*2+2]end end
   if done then done()end
  end,function()
   if token~=epoch then return end
   polling=false;live={};lastPWM=now()
   if any()then fail('LIVE OUTPUT READ FAILED')elseif done then done()end
  end)
 end
 local function statusCheck(ok)
  local token=epoch
  queue(101,nil,function(_,b)
   if token~=epoch then return end
   lastStatus=now()
   if #b<10 then fail('INVALID FC STATUS');return end
   if b[7]%2~=0 then fail('DISARM FC FIRST');return end
   ok()
  end,function()if token==epoch then fail('NO FC STATUS')end end)
 end
 local function read(done)
  busy=true;ready=false;blocked=false;state='READING SERVO CENTERS...';local token=epoch
  h.servos().getServoConfigurations(function(_,d)
   if token~=epoch then return end
   for i=0,2 do
    if not d[i]or not d[i].mid or not d[i].flags then busy=false;blocked=true;state='NEED S1-S3 / RTN TO RETRY';return end
   end
   cfg=copy(d);ready=true;busy=false;state='SELECT S1 / S2 / S3';if done then done()end
  end,nil,function()if token==epoch then busy=false;blocked=true;state='READ FAILED / RTN TO RETRY'end end)
 end
 function M.open()page='menu';focus=1;state='SELECT CENTER TRIM'end
 local function submenu()
  page='menu';ready=false;blocked=false;exitAfter=false;returnAt=nil;focus=1;state='OVERRIDES RELEASED'
 end
 function M.back()
  if page=='menu'then h.back();return end
  if page=='mount'then submenu();return end
  returnAt=returnAt or now()
  if transaction then exitAfter=true;drag=nil;edit=false;state='FINISHING WRITE / THEN RETURN';return end
  if stopping then exitAfter=true;return end
  stop(submenu)
 end
 -- One complete group in flight; replace queued group targets with the newest snapshot.
 flush=function()
  if flight or not pending or stopping or blocked or polling then return end
  if any()and now()-lastStatus>=50 then return end
  local snapshot=pending;pending=nil;flight=true;local token=epoch
  local function send(i)
   if token~=epoch then return end
   if i>2 then
    flight=false
    if now()-lastPWM>=20 and not busy then sample(function()flush();drain()end)
    else flush();drain()end
    return
   end
   if snapshot[i]==nil then send(i+1);return end
   h.override(i,snapshot[i],true,function()if token==epoch then send(i+1)end end,
    function()if token==epoch then flight=false;fail('GROUP MOVE FAILED')end end)
  end
  send(0)
 end
 drain=function()
  if not flight and not pending and not polling and deferred and not stopping then
   local fn=deferred;deferred=nil;fn()
  end
 end
 local function afterMoves(fn)
  busy=true;drag=nil;edit=false;deferred=fn;flush();drain()
 end
 local function finishWrite(msg)
  transaction=false;busy=false;state=msg
  if exitAfter then exitAfter=false;stop(submenu)end
 end
 local function writeSelected(patches,success)
  -- Refresh full configs immediately before selective writes; preserve rate, limits and tail.
  transaction=true;busy=true;local token=epoch
  h.servos().getServoConfigurations(function(_,fresh)
   if token~=epoch then return end
   for i,p in pairs(patches)do
    if not fresh[i]then transaction=false;fail('SERVO READ FAILED');return end
    for k,v in pairs(p)do
     local d=fresh[i][k]
     if not d or v<d.min or v>d.max then transaction=false;fail('CENTER / FLAGS OUT OF RANGE');return end
     d.value=v
    end
   end
   local function write(i)
    if token~=epoch then return end
    if i<=2 then
     if not patches[i]then write(i+1);return end
     h.servos().setServoConfiguration(i,fresh[i],function()write(i+1)end,
      function()transaction=false;fail('PARTIAL APPLY / NOT SAVED')end)
    else
     queue(250,nil,function()
      if token~=epoch then return end
      h.servos().getServoConfigurations(function(_,got)
       if token~=epoch then return end
       for j,p in pairs(patches)do for k,v in pairs(p)do
        if not got[j]or not got[j][k]or got[j][k].value~=v then transaction=false;fail('SAVED / VERIFY MISMATCH');return end
       end end
       cfg=copy(got);finishWrite(success)
      end,nil,function()transaction=false;fail('SAVED / VERIFY READ FAILED')end)
     end,function()transaction=false;fail('APPLIED / EEPROM SAVE FAILED')end)
    end
   end
   -- A fresh arm check is also required after release/config reads, before any write.
   statusCheck(function()state='SAVING SELECTED SERVO VALUES...';write(0)end)
  end,nil,function()transaction=false;fail('CONFIG READ FAILED')end)
 end
 local function applyCenter(confirm)
  if not any()then state='SELECT A SERVO FIRST';return end
  local expected=confirm and review or nil
  local chosen={};for i=0,2 do if enabled[i]then chosen[i]=true end end
  afterMoves(function()
   statusCheck(function()
    state='READING ACTUAL OUTPUT...';local token=epoch
    queue(103,nil,function(_,b)
     if token~=epoch then return end
     local patches={}
     for i in pairs(chosen)do
      local p=i*2+1
      if #b<p+1 then fail('PWM READ FAILED');return end
      local value=b[p]+256*b[p+1];local d=cfg[i].mid
      if value<d.min or value>d.max then fail('PWM OUT OF CENTER RANGE');return end
      patches[i]={mid=value}
     end
     live={};for i=0,2 do if #b>=i*2+2 then live[i]=b[i*2+1]+256*b[i*2+2]end end;lastPWM=now()
     local same=expected~=nil
     for i,p in pairs(patches)do if not expected or not expected[i]or expected[i].mid~=p.mid then same=false end end
     if not same then
      review=patches;busy=false;edit=false;drag=nil;focus=1
      state=confirm and'OUTPUT CHANGED / CHECK VALUES AGAIN'or'CHECK CENTER VALUES / NOT SAVED'
      return
     end
     stop(function()
      if exitAfter then submenu();return end
      writeSelected(patches,'CENTER SAVED / VERIFIED')
     end)
    end,function()if token==epoch then fail('PWM READ FAILED')end end)
   end)
  end)
 end
 local function toggle(i)
  afterMoves(function()
   statusCheck(function()
    local token=epoch
    local function choose()
     if token~=epoch then return end
     enabled[i]=true;angles[i]=angles[i]or 0;mode=nil;active[i]=not active[i]or nil;selected=i
     local n,last=0,nil;for j in pairs(active)do n=n+1;last=j end
     dial=n==1 and angles[last]or 0;busy=false;edit=n>0
     lastPWM=-1000;state=n>0 and'GREEN SERVOS TRIM / RED SERVOS HOLD'or'ALL HELD / SELECT SERVOS TO TRIM'
    end
    -- Selection is not an OFF toggle and must never re-center an enabled servo.
    if enabled[i]then choose();return end
    h.override(i,0,true,choose,function()if token==epoch then fail('OVERRIDE SWITCH FAILED')end end)
   end)
  end)
 end
 local function axis(which)
  afterMoves(function()
   statusCheck(function()
    local all=which=='ALL';local target=not all and mode~=which and which or nil;local token=epoch
    -- Existing overrides hold their positions. Only enable missing servos at zero.
    local function enable(i)
     if token~=epoch then return end
     if i>2 then mode=target;active=all and{[0]=true,[1]=true,[2]=true}or{};dial=0;lastPWM=-1000;busy=false;edit=target~=nil or all;state=target and(target..' / ALL SERVOS HELD')or(all and'ALL SELECTED / SAME-DIRECTION TRIM'or'ALL HELD / SELECT SERVOS TO TRIM');return end
     if (not target and not all)or enabled[i]then enable(i+1);return end
     h.override(i,0,true,function()
      if token~=epoch then return end
      enabled[i]=true;angles[i]=0;enable(i+1)
     end,function()if token==epoch then fail('AXIS ENABLE FAILED')end end)
    end
    enable(0)
   end)
  end)
 end
 local function reverse(i)
  stop(function()
   if exitAfter then submenu();return end
   -- Read current flags, not a cached value that another screen may have changed.
   busy=true;local token=epoch
   h.servos().getServoConfigurations(function(_,fresh)
    if token~=epoch then return end
    if not fresh[i]or not fresh[i].flags then fail('DIRECTION READ FAILED');return end
    writeSelected({[i]={flags=bit32.bxor(fresh[i].flags.value,1)}},'S'..(i+1)..' DIRECTION SAVED')
   end,nil,function()if token==epoch then fail('DIRECTION READ FAILED')end end)
  end)
 end
 local function groupSigns()
  -- FRONT reverses the prior lateral mapping; REAR mirrors the physical layout.
  if mode=='AILERON'then return front and{[1]=-1,[2]=1}or{[1]=1,[2]=-1}end
  -- Moving S1 from the nose to the tail reverses the physical pitch tilt.
  if mode=='ELEVATOR'then return front and{[0]=-1,[1]=1,[2]=1}or{[0]=1,[1]=-1,[2]=-1}end
  local signs={};for i in pairs(active)do if enabled[i]then signs[i]=1 end end;return signs
 end
 local function change(value)
  if busy or review or blocked or not ready or not any()or(not mode and next(active)==nil)then return end
  local delta=math.floor(value+.5)-dial;local lo,hi=-90-dial,90-dial;local signs=groupSigns()
  for i,s in pairs(signs)do
   local a=angles[i]or 0
   lo=math.max(lo,s==1 and -90-a or a-90);hi=math.min(hi,s==1 and 90-a or a+90)
  end
  delta=math.max(lo,math.min(hi,delta));if delta==0 then return end
  dial=dial+delta;local snapshot={}
  for i,s in pairs(signs)do angles[i]=(angles[i]or 0)+s*delta;snapshot[i]=angles[i]end
  pending=snapshot;flush()
  if now()-feedbackAt>=6 then
   feedbackAt=now()
   if type(playTone)=='function'then pcall(playTone,1800,12,0)end
   if type(playHaptic)=='function'then pcall(playHaptic,12,0)end
  end
 end
 function M.commit(key,value)
  if page~='defaults'or busy or blocked or defaultReview then return end
  local field=string.match(key or'','^default:(%w+)$')
  local d=field and cfg[0]and cfg[0][field]
  if not d or value~=math.floor(value)or value<d.min or value>d.max then return end
  for i=0,2 do draft[i][field]=value end
  state='DRAFT / NOT SAVED'
 end
 function M.activate(a)
  if a.key=='back'then M.back();return end
  if a.key=='alloff'and page=='trim'and not transaction and not stopping then
   stop(function()if exitAfter then submenu()else state='ALL OVERRIDES OFF'end end);return
  end
  if busy then return end
  if page=='menu'and a.key=='custom'then h.fullServos();return end
  if page=='menu'and a.key=='defaults'then
   page='defaults';ready=false;blocked=false;exitAfter=false;defaultReview=false;pulseChosen=false;defaultTab=1;edit=false;focus=1
   if not h.ready()then state='FC OFFLINE / RTN TO RETRY';return end
   stop(function()if exitAfter then submenu();return end;read(function()
    draft={};for i=0,2 do draft[i]={};for _,k in ipairs(fields)do draft[i][k]=cfg[i][k].value end end
    state='SELECT PULSE WIDTH / DRAFT ONLY'
   end)end);return
  end
  if page=='defaults'then
   if not ready or blocked then return end
   if defaultReview then
    if a.key=='cancel'then defaultReview=false;state='DRAFT / NOT SAVED'
    elseif a.key=='confirm'then local patches=copy(draft);defaultReview=false;stop(function()
     if exitAfter then submenu()else writeSelected(patches,'DEFAULTS SAVED / VERIFIED')end
    end)end
    return
   end
   if a.key=='dtab'then defaultTab=a.index;focus=a.index
   elseif a.key=='pulse'and(a.index==1520 or a.index==760)then
    pulseChosen=true
    for i=0,2 do
     draft[i].mid=a.index
     draft[i].rate=333
     if a.index==1520 then draft[i].min=-700;draft[i].max=700;draft[i].scaleNeg=500;draft[i].scalePos=500;draft[i].flags=bit32.bor(draft[i].flags,2)end
     if a.index==760 then draft[i].min=-350;draft[i].max=350;draft[i].scaleNeg=250;draft[i].scalePos=250 end
    end
    state=a.index==1520 and'1520 DEFAULTS / 333 Hz / NOT SAVED'or'760 / LIMITS -350 TO 350 / 333 Hz / NOT SAVED'
   elseif a.key=='rate'then M.commit('default:rate',a.index)
   elseif a.key=='dnumber'then local d=cfg[0][a.index];h.number('default:'..a.index,draft[0][a.index],d.min,d.max)
   elseif a.key=='dreverse'then draft[a.index].flags=bit32.bxor(draft[a.index].flags,1);state='DRAFT / NOT SAVED'
   elseif a.key=='dgeo'then local on=bit32.band(draft[0].flags,2)==0;for i=0,2 do draft[i].flags=on and bit32.bor(draft[i].flags,2)or bit32.band(draft[i].flags,1)end;state='DRAFT / NOT SAVED'
   elseif a.key=='dsave'then
    if not pulseChosen then state='SELECT 1520 OR 760 FIRST';return end
    for i=0,2 do if draft[i].min>0 or draft[i].max<0 or draft[i].min>=draft[i].max then state='INVALID MIN / MAX';return end end
    defaultReview=true;focus=1;state='CHECK ALL S1-S3 VALUES / NOT SAVED'
   end
   return
  end
  if review then
   if a.key=='confirm'then applyCenter(true)
   elseif a.key=='cancel'then review=nil;edit=any()and true or false;state='SAVE CANCELLED / OVERRIDES HELD'end
   return
  end
  if a.key=='enter'and page=='menu'then
   page='mount';focus=1;edit=false;ready=false;blocked=false;exitAfter=false;return
  end
  if a.key=='mount'and page=='mount'and(a.index=='front'or a.index=='rear')then
   page='trim';front=a.index=='front';selected=1;focus=1;ready=false;blocked=false;exitAfter=false
   if not h.ready()then state='FC OFFLINE / RTN TO RETRY';return end
   stop(function()if exitAfter then submenu()else read()end end);return
  end
  if page~='trim'or not ready or blocked then return end
  if a.key=='select'then toggle(a.index)
  elseif a.key=='reverse'then reverse(a.index)
  elseif a.key=='apply'then applyCenter(false)
  elseif a.key=='allon'then axis('ALL')
  elseif a.key=='axis'then axis(a.index)
  elseif a.key=='front'then afterMoves(function()front=not front;dial=0;busy=false;edit=any()and true or false end)
  elseif a.key=='ruler'then edit=not edit end
 end
 local function btn(label,x,y,w,ht,key,index,color)
  local n=#controls+1;local a={kind='easyServo',key=key,index=index};controls[n]=a
  h.button('ct'..n,label,x,y,w,ht,not edit and focus==n,a,color or'cyan')
 end
 local function disc(x,y,color)
  for dy=-11,11 do local dx=math.floor(math.sqrt(121-dy*dy));h.fill(x-dx,y+dy,dx*2+1,1,color)end
 end
 local function litButton(label,x,y,w,ht,key,index,on)
  btn('',x,y,w,ht,key,index,on and'red'or'cyan')
  if on then h.fill(x+2,y+2,w-4,ht-4,'red')end
  h.txt(x+8,y+(ht-18)/2,label,on and'text'or'muted',true)
 end
 local function nose(x,y)
  h.line(x,y+22,x,y,'red');h.line(x,y,x-7,y+9,'red');h.line(x,y,x+7,y+9,'red')
  h.txt(x-36,y+26,'HELI FRONT','red')
 end
 local function miniSwash(cx,cy,isFront)
  local r=52
  for n=0,31 do local a=n*math.pi/16;local b=(n+1)*math.pi/16;h.line(cx+r*math.cos(a),cy+r*math.sin(a),cx+r*math.cos(b),cy+r*math.sin(b),'muted')end
  local aa=isFront and{-90,30,150}or{90,210,330}
  for i=1,3 do local a=aa[i]*math.pi/180;local x,y=cx+r*math.cos(a),cy+r*math.sin(a);h.line(cx,cy,x,y,'cyan');h.txt(x-8,y-7,'S'..i,'text')end
  nose(cx+96,cy-20)
 end
 function M.draw()
  controls={};h.header(page=='menu'and'SERVO / SWASH SETUP'or(page=='defaults'and'SWASH SERVO DEFAULT SETUP'or'SERVO REVERSE SETUP / SERVO CENTER PULSE TRIM'),busy and'WAIT...'or'')
  if page=='menu'then
   btn('1. SWASH SERVO DEFAULT SETUP',20,112,760,70,'defaults')
   btn('',20,204,552,94,'enter');h.txt(36,225,'2. SERVO REVERSE SETUP /','text',true);h.txt(36,256,'SERVO CENTER PULSE TRIM','text',true)
   btn('',590,204,190,94,'custom');h.txt(608,225,'CUSTOM FINE','cyan',true);h.txt(608,256,'SERVO SETUP','cyan',true)
   if notice then h.txt(20,330,notice,'orange');h.txt(20,357,'Check FC power and saved values before reconnecting.','orange')end
   h.footer('RTN: previous menu');return
  end
  if page=='mount'then
   h.txt(80,132,'IS THE ELEVATOR SERVO AT THE FRONT OR REAR?','text',true)
   h.txt(80,172,'Choose the actual mounting position before adjusting.','muted')
   miniSwash(175,255,true);miniSwash(515,255,false)
   btn('FRONT',80,326,300,66,'mount','front')
   btn('REAR',420,326,300,66,'mount','rear')
   h.txt(80,408,'No overrides enabled before you choose.','green')
   h.footer('Select FRONT or REAR each time / RTN: cancel');return
  end
  h.txt(20,84,state,'orange')
  if page=='defaults'then
   if not ready then h.txt(30,160,'Connect FC. RTN and reopen to retry.','text');return end
   if defaultReview then
    h.txt(28,112,'WARNING: CURRENT SAVED VALUES WILL BE CHANGED.','orange',true)
    h.txt(28,137,'Confirm to apply these settings to S1 / S2 / S3.','text')
    h.txt(345,157,'S1','cyan');h.txt(495,157,'S2','cyan');h.txt(645,157,'S3','cyan')
    for n,k in ipairs(fields)do
     local y=176+(n-1)*25;h.txt(30,y,k,'text')
     for i=0,2 do local v=draft[i][k];if k=='flags'then v=(bit32.band(v,1)>0 and'Reverse'or'Normal')..(bit32.band(v,2)>0 and' / Geo ON'or' / Geo OFF')end;h.txt(310+i*150,y,tostring(v),'green')end
    end
    btn('CANCEL',30,392,330,42,'cancel');btn('CONFIRM & SAVE',410,392,360,42,'confirm',nil,'orange')
   else
    local tabs={'1. PULSE','2. RATE / SPEED','3. REVERSE','4. LIMITS / GEO'}
    for i,t in ipairs(tabs)do btn(t,20+(i-1)*190,112,182,38,'dtab',i,defaultTab==i and'orange'or'cyan')end
    if defaultTab==1 then
     h.txt(30,172,'Select the specification of your S1-S3 servos.','text')
     btn('1520 us',30,213,350,66,'pulse',1520);btn('760 us',420,213,350,66,'pulse',760)
     h.txt(30,303,'1520: Min -700 / Max 700 / Scale -/+ 500 / Geo ON','green')
     h.txt(30,330,'760: Min -350 / Max 350 / Scale -/+ 250. Rate: 333 Hz.','muted')
     h.txt(30,357,'Centers: '..draft[0].mid..' / '..draft[1].mid..' / '..draft[2].mid..' us','text')
    elseif defaultTab==2 then
     for i,v in ipairs({50,100,200,250,333,560})do btn(v..' Hz',30+((i-1)%3)*250,164+math.floor((i-1)/3)*46,230,40,'rate',v)end
     btn('Custom Rate (Hz)',30,264,340,48,'dnumber','rate');btn('Speed (ms)',420,264,350,48,'dnumber','speed')
     h.txt(30,325,'Rates: '..draft[0].rate..' / '..draft[1].rate..' / '..draft[2].rate..' Hz','green')
     h.txt(30,350,'Speeds: '..draft[0].speed..' / '..draft[1].speed..' / '..draft[2].speed..' ms','green')
     h.txt(30,375,'Use only the Hz specified for your servo model.','orange')
    elseif defaultTab==3 then
     h.txt(30,180,'Reverse is selected independently for each servo.','text')
     for i=0,2 do btn('S'..(i+1)..': '..(bit32.band(draft[i].flags,1)>0 and'Reverse'or'Normal'),30+i*250,235,230,65,'dreverse',i)end
    else
     for i,k in ipairs({'min','max','scaleNeg','scalePos'})do
      local x=30+((i-1)%2)*390;local y=174+math.floor((i-1)/2)*66
      btn(k..': '..draft[0][k]..' / '..draft[1][k]..' / '..draft[2][k],x,y,350,48,'dnumber',k)
     end
     local g={};for i=0,2 do g[#g+1]=bit32.band(draft[i].flags,2)>0 and'ON'or'OFF'end
     btn('Geo correction: '..table.concat(g,' / '),30,318,740,48,'dgeo')
    end
    btn('REVIEW & SAVE S1-S3',30,398,740,38,'dsave',nil,'orange')
   end
   h.footer('Draft only until confirmed / Check servo rated pulse & Hz / RTN: discard & return');return
  end
  if review then
   h.fill(100,112,600,316,'panel2');h.box(100,112,600,316,'orange')
   h.txt(124,130,'SAVE THESE VALUES AS SERVO CENTERS?','text',true)
   h.txt(124,160,'Measured output -> Center (us)','green')
   for i=0,2 do
    local p=review[i]
    h.txt(136,196+i*42,'S'..(i+1)..': '..(p and(tostring(p.mid)..' us')or'UNCHANGED'),p and'green'or'muted',true)
   end
   h.txt(124,327,'CANCEL keeps overrides ON. RTN releases & returns.','muted')
   btn('CANCEL',128,365,250,44,'cancel')
   btn('CONFIRM & SAVE',422,365,250,44,'confirm',nil,'orange')
   h.footer('Only the listed values will be saved after confirmation.');return
  end
  if not ready then h.txt(30,160,'Connect FC. RTN and reopen to retry.','text');return end
  h.fill(20,104,596,334,'panel')
  local cx,cy,r=315,260,154
  for n=0,63 do local a=n*math.pi/32;local b=(n+1)*math.pi/32;h.line(cx+r*math.cos(a),cy+r*math.sin(a),cx+r*math.cos(b),cy+r*math.sin(b),'muted')end
  local aa=front and{-90,30,150}or{90,210,330}
  -- Each servo has its own 100px card: selection, live pulse, then direction.
  -- Keep pulse text outside every action hitbox for both mounting orientations.
  local positions=front and{{366,112,110},{480,322,136},{20,322,136}}
   or{{366,330,110},{20,112,136},{480,112,136}}
  for i=0,2 do
   local a=aa[i+1]*math.pi/180;local x,y=cx+r*math.cos(a),cy+r*math.sin(a)
   local color=enabled[i]and(active[i]and'green'or'red')or'muted'
   h.line(cx,cy,x,y,'cyan');disc(x,y,color)
   local p=positions[i+1]
   btn('',p[1],p[2],p[3],36,'select',i,enabled[i]and color or'cyan')
   h.txt(p[1]+36,p[2]+8,'S'..(i+1),enabled[i]and color or'text',true)
   local labelY=p[2]+42
   h.txt(p[1]+8,labelY,(live[i]and now()-lastPWM<100 and tostring(live[i])or'--')..' us','green',true)
   local rx,ry=(cx+x)/2-42,(cy+y)/2-14
   btn('',rx,ry,84,28,'reverse',i)
   h.txt(rx+10,ry+7,bit32.band(cfg[i].flags.value,1)~=0 and'Reverse'or'Normal','text',false)
  end
  nose(cx,218)
  btn(front and'ELEVATOR FRONT'or'ELEVATOR REAR',474,398,146,32,'front')
  litButton('OVERRIDE ALL',20,222,140,40,'allon',nil,enabled[0]and enabled[1]and enabled[2])
  litButton('ALL OFF',20,270,140,40,'alloff',nil,false)
  litButton('AILERON TRIM',474,220,146,44,'axis','AILERON',mode=='AILERON')
  litButton('ELEVATOR TRIM',474,270,146,44,'axis','ELEVATOR',mode=='ELEVATOR')
  btn('CENTER APPLY',20,398,140,32,'apply',nil,'orange')
  h.fill(632,103,148,335,'panel2');h.box(632,103,148,335,'cyan')
  local ids={};for i=0,2 do if active[i]then ids[#ids+1]='S'..(i+1)end end
  h.txt(640,115,mode and(mode..' TRIM')or(#ids>0 and(table.concat(ids,'+')..' TRIM')or'SELECT SERVO'),'cyan')
  btn('',642,143,128,284,'ruler',nil,edit and'orange'or'cyan')
  for k=-14,14 do local value=dial+k;local y=285-k*9
   if value>=-90 and value<=90 then
    h.fill(value%5==0 and 706 or 737,y,value%5==0 and 56 or 25,1,'muted')
    if value%5==0 then h.txt(650,y-7,tostring(value),'text')end
   end
  end
  h.fill(644,285,124,2,'orange')
  h.footer('Red dots: hold / Green dots: trim together / Green numbers: live us / RTN: release')
 end
 function M.event(e,touch)
  if e==EVT_VIRTUAL_EXIT then M.back();return 0 end
  if page=='trim'and not review and type(touch)=='table'then
   local x,y=h.coords(touch.x,touch.y)
   if EVT_TOUCH_FIRST and e==EVT_TOUCH_FIRST and x>=642 and x<=770 and y>=143 and y<=427 then
    if not busy and not blocked and any()and(mode or next(active)~=nil)then drag={y=y,value=dial};edit=true end
    return 0
   elseif drag and((EVT_TOUCH_SLIDE and e==EVT_TOUCH_SLIDE)or(EVT_TOUCH_BREAK and e==EVT_TOUCH_BREAK))then
    change(drag.value+(drag.y-y)/9)
    if EVT_TOUCH_BREAK and e==EVT_TOUCH_BREAK then drag=nil end
    return 0
   elseif EVT_TOUCH_TAP and e==EVT_TOUCH_TAP and x>=642 and x<=770 and y>=143 and y<=427 then return 0 end
  end
  if busy then return 0 end
  if edit and page=='trim'then
   if e==EVT_VIRTUAL_NEXT or e==EVT_VIRTUAL_PREV then change(dial+(e==EVT_VIRTUAL_NEXT and 1 or -1));return 0 end
   if e==EVT_VIRTUAL_ENTER then edit=false;return 0 end
  end
  if e==EVT_VIRTUAL_NEXT or e==EVT_VIRTUAL_PREV then if #controls>0 then focus=(focus-1+(e==EVT_VIRTUAL_NEXT and 1 or -1))%#controls+1 end;return 0 end
  if e==EVT_VIRTUAL_ENTER then if controls[focus]then M.activate(controls[focus])end;return 0 end
  return e
 end
 function M.tick()
  -- Disconnected FC must not trap RTN behind an unanswered release/write.
  -- Clear the transport too, so stale movement cannot be replayed on reconnect.
  if (page=='trim'or page=='defaults')and returnAt and now()-returnAt>=300 then
   epoch=epoch+1
   rf2.mspQueue:clear()
   pending=nil;deferred=nil;flight=false;polling=false;stopping=false;transaction=false;busy=false
   drag=nil;edit=false;review=nil;enabled={};angles={};live={};mode=nil;active={}
   submenu();notice='FC NO RESPONSE / RELEASE & SAVE NOT CONFIRMED';return
  end
  if page~='trim'or not ready or stopping or blocked or transaction then return end
  if not flight and not polling and rf2.mspQueue:isProcessed()and any()and now()-lastStatus>=50 then
   polling=true;local token=epoch
   statusCheck(function()if token~=epoch then return end;polling=false;flush();drain()end)
   return
  end
  if not flight and not polling and not busy and rf2.mspQueue:isProcessed()and now()-lastPWM>=(any()and 20 or 100)then
   sample(function()flush();drain()end);return
  end
  flush();drain()
 end
 return M
end
