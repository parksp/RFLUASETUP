-- Dedicated tail setup: draft edits, fresh-block merge, verified EEPROM save.
return function(h)
 local M={};local view='menu';local focus=1;local controls={};local cfg,inputs,servos={},{},{}
 local draft={};local selected=3;local ready,busy,over,drag=false,false,false,false
 local editing=nil;local increments={1,10,.1};local incrementIndex=1;local held=nil;local heldAt=0;local heldOpened=false
 local liveBusy=false;local undo={};local liveLast={};local livePending={};local applyLive
 local state='READING FC...';local epoch=0;local started=0;local target=0;local pending=nil;local modal=nil
 local function round(v)return v>=0 and math.floor(v+.5)or math.ceil(v-.5)end
 local function fail(s)busy=false;liveBusy=false;livePending={};pending=nil;drag=false;state=s or'FC ERROR / REOPEN'end
 local function q(cmd,payload,ok)
  local token=epoch;started=getTime();rf2.mspQueue:add({command=cmd,payload=payload,maxAttempts=1,replyTimeout=4,
   processReply=function(_,b)if token==epoch then if ok then ok(b)end end end,
   errorHandler=function()if token==epoch then fail('FC REQUEST FAILED / MSP '..cmd)end end})
 end
 local function disarm(done)q(101,nil,function(b)if #b<10 then fail('STATUS READ FAILED')elseif b[7]%2~=0 then fail('DISARM FC FIRST')else done()end end)end
 local function override(raw,done)local p={3};rf2.mspHelper.writeU16(p,raw);q(191,p,done)end
 local function clearTargets()
  local queue=rf2.mspQueue.messageQueue
  if queue then for n=#queue,1,-1 do if queue[n].tailTarget then table.remove(queue,n)end end end
 end
 local function release(done)clearTargets();pending=nil;busy=true;override(2501,function()over=false;target=0;drag=false;if done then done()else busy=false;state='OVERRIDE OFF'end end)end
 local function read(done)
  local token=epoch;started=getTime()
  h.mixer().read(function(_,c)if token~=epoch then return end
   rf2.mixerInputsApi=rf2.mixerInputsApi or rf2.useApi('mspMixerInputs')
   rf2.mixerInputsApi.read(function(t)if token~=epoch then return end
    h.servos().getServoConfigurations(function(_,s)if token==epoch then done(c,t,s)end end,nil,function()if token==epoch then fail('SERVO READ FAILED')end end)
   end,function(e)if token==epoch then fail(e)end end,nil,{3})
  end,nil,nil,function()if token==epoch then fail('MIXER READ FAILED')end end)
 end
 local function loadFC()busy=true;read(function(c,t,s)cfg=c;inputs=t;servos=s;draft={};ready=true;busy=false;state='FC VALUES / OVERRIDE OFF'end)end
 function M.open()epoch=epoch+1;view='menu';focus=1;modal=nil;draft={};ready=false;busy=true;over=false;target=0;pending=nil;editing=nil;held=nil;heldOpened=false;incrementIndex=1
  if not h.ready()then fail('NO FC LINK');return end;release(loadFC)
 end
 local function mode()return draft.tail_rotor_mode or(cfg.tail_rotor_mode and cfg.tail_rotor_mode.value)or 0 end
 local function val(k)
  if draft[k]~=nil then return draft[k]end
  if k=='direction'then return inputs[3]and(inputs[3].rate<0 and -1 or 1)or 1 end
  if k=='cal'then return inputs[3]and math.abs(inputs[3].rate)/10 or 0 end
  if k=='cw'then return inputs[3]and -inputs[3].min*(mode()==0 and 24 or 100)/1000 or 0 end
  if k=='ccw'then return inputs[3]and inputs[3].max*(mode()==0 and 24 or 100)/1000 or 0 end
  if k=='trim'then return cfg.tail_center_trim and cfg.tail_center_trim.value/10 or 0 end
  local s=servos[selected];return s and s[k]and s[k].value or 0
 end
 function M.commit(k,v)
  if ready and not busy then
   if k=='trim'or k=='cal'or k=='cw'or k=='ccw'then
    if draft.tail_rotor_mode~=nil or draft.direction~=nil then state='SAVE TYPE / DIRECTION BEFORE LIVE EDIT';return end
    draft[k]=v;livePending[k]=v;applyLive(false)
   else if liveBusy then return end;draft[k]=v;state='DRAFT / APPLY & SAVE'end
  end
 end
 applyLive=function(restoring,onDone)
  if liveBusy then state='WAIT FOR LIVE UPDATE';return end
  local edits={};for k,v in pairs(restoring and undo or livePending)do edits[k]=v end
  if not next(edits)then if onDone then onDone()end;return end
  if not restoring then livePending={}end
  -- A trim edit needs only the mixer block; input edits need mixer + yaw input.
  -- Servo configuration reads are unrelated to these live operations.
  local onlyTrim=true;for k in pairs(edits)do if k~='trim'then onlyTrim=false end end
  local function fetch(done)
   local token=epoch;started=getTime()
   h.mixer().read(function(_,c)
    if token~=epoch then return end
    if onlyTrim then done(c,inputs,servos);return end
    rf2.mixerInputsApi=rf2.mixerInputsApi or rf2.useApi('mspMixerInputs')
    rf2.mixerInputsApi.read(function(t)if token==epoch then done(c,t,servos)end end,function(e)if token==epoch then fail(e)end end,nil,{3})
   end,nil,nil,function()if token==epoch then fail('MIXER READ FAILED')end end)
  end
  liveBusy=true;state=restoring and'RESTORING UNSAVED VALUES...'or'APPLYING LIVE / NOT SAVED...'
  disarm(function()fetch(function(c,t,s)
   local token=epoch;local i=t[3]
   if not i or not inputs[3]then fail('INPUT READ FAILED / NO WRITE');return end
   if c.tail_rotor_mode.value~=cfg.tail_rotor_mode.value or(i.rate<0)~=(inputs[3].rate<0)then fail('TAIL TYPE / DIRECTION CHANGED / REOPEN');return end
   local function raw(k)if k=='trim'then return c.tail_center_trim.value elseif k=='cal'then return i.rate elseif k=='cw'then return i.min else return i.max end end
   local want={};local configChanged=false;local inputChanged=false
   for k,v in pairs(edits)do
    local before=raw(k)
    if restoring then
     if before~=liveLast[k]and before~=undo[k]then fail('RESTORE CONFLICT / CHECK FC');return end
     want[k]=v
    else
     if undo[k]==nil then undo[k]=before end
     if k=='trim'then want[k]=round(v*10)elseif k=='cal'then want[k]=round(v*10)*(i.rate<0 and -1 or 1)else want[k]=round(v*1000/(c.tail_rotor_mode.value==0 and 24 or 100))*(k=='cw'and -1 or 1)end
     liveLast[k]=want[k]
    end
    if k=='trim'then c.tail_center_trim.value=want[k];configChanged=true elseif k=='cal'then i.rate=want[k];inputChanged=true elseif k=='cw'then i.min=want[k];inputChanged=true else i.max=want[k];inputChanged=true end
   end
   local function verified()
    fetch(function(g,gi,gs)
     for k,v in pairs(want)do local actual=k=='trim'and g.tail_center_trim.value or k=='cal'and gi[3].rate or k=='cw'and gi[3].min or gi[3].max
      if actual~=v then fail('LIVE VERIFY FAILED / CHECK FC');return end
     end
     cfg=g;inputs=gi;servos=gs;liveBusy=false
     if restoring then undo={};liveLast={};livePending={};draft={};state='RESTORED / NOT SAVED';if onDone then onDone()end
     else state='LIVE / NOT SAVED';if next(livePending)then applyLive(false)end end
    end)
   end
   local function writeInput()if inputChanged then local p={3};for _,k in ipairs({'rate','min','max'})do rf2.mspHelper.writeU16(p,i[k])end;q(171,p,verified)else verified()end end
   if configChanged then h.mixer().write(c,function()if token==epoch then writeInput()end end,function()if token==epoch then fail('LIVE WRITE FAILED / MSP 43')end end)else writeInput()end
  end)end)
 end
 local sendTarget
 sendTarget=function(v)
  local limit=mode()==0 and 60 or 125;v=math.max(-limit,math.min(limit,v))
  target=v;pending=v;if busy or liveBusy or not over then return end
  local raw=round(v*1000/(mode()==0 and 24 or 100));pending=nil
  -- Like Full Setup: queue the target immediately without locking UI on ACK.
  -- Keep only the latest unsent tail target so a drag does not build a backlog.
  local p={3};rf2.mspHelper.writeU16(p,raw);local token=epoch
  local queue=rf2.mspQueue.messageQueue
  if queue then for n=#queue,1,-1 do local m=queue[n];if m.tailTarget then m.payload=p;return end end end
  rf2.mspQueue:add({command=191,payload=p,tailTarget=true,maxAttempts=1,replyTimeout=4,
   processReply=function()if token==epoch and over and not busy and not liveBusy then state='OVERRIDE ON / TARGET ONLY'end end,
   errorHandler=function()if token==epoch and over and not busy then drag=false;state='OVERRIDE REQUEST FAILED / MSP 191'end end})
 end
 local function save()
  if liveBusy then modal=nil;state='WAIT FOR LIVE UPDATE / THEN SAVE';return end
  modal=nil;busy=true;state='CHECKING DISARM...'
  local expected={};for k,v in pairs(draft)do expected[k]=v end
  local original=servos[selected];local originalRate=inputs[3]and inputs[3].rate;local savedIndex=selected
  disarm(function()release(function()read(function(c,t,s)
   local token=epoch;local row=s[savedIndex];local configChanged=expected.tail_rotor_mode~=nil or expected.trim~=nil
   local inputChanged=expected.direction~=nil or expected.cal~=nil or expected.cw~=nil or expected.ccw~=nil
   local servoChanged=false
   if view=='defaults'and(c.tail_rotor_mode.value~=0 or mode()~=0)then fail('MOTOR TAIL / NO SERVO WRITE');return end
   for _,k in ipairs({'mid','min','max','scaleNeg','scalePos','rate','speed','flags'})do
    if expected[k]~=nil then
     if not row or not original then fail('TAIL SERVO MISSING');return end
     if k=='flags'then local mask=bit32.bxor(original.flags.value,expected[k]);row.flags.value=bit32.bor(bit32.band(row.flags.value,bit32.bnot(mask)),bit32.band(expected[k],mask))else row[k].value=expected[k]end
     servoChanged=true
    end
   end
   if servoChanged and row.min.value>row.max.value then fail('SERVO MIN / MAX INVALID');return end
   if expected.tail_rotor_mode~=nil then c.tail_rotor_mode.value=expected.tail_rotor_mode end
   if expected.trim~=nil then c.tail_center_trim.value=round(expected.trim*10)end
   local i=t[3]
   if inputChanged then
    if not i or not originalRate then fail('TAIL INPUT MISSING');return end
    if (i.rate<0)~=(originalRate<0)and expected.direction==nil then fail('YAW DIRECTION CHANGED / REOPEN');return end
    local sign=expected.direction or(i.rate<0 and -1 or 1)
    i.rate=round((expected.cal or math.abs(i.rate)/10)*10)*sign
    if i.rate==0 then fail('ZERO CALIBRATION / NO WRITE');return end
    local scale=c.tail_rotor_mode.value==0 and 24 or 100
    if expected.cw~=nil then i.min=-round(expected.cw*1000/scale)end
    if expected.ccw~=nil then i.max=round(expected.ccw*1000/scale)end
   end
   local function verify(done)read(function(g,gi,gs)
    if configChanged then for k,v in pairs(c)do if type(v)=='table'and v.value~=nil and(not g[k]or g[k].value~=v.value)then fail('MIXER VERIFY FAILED / NO EEPROM');return end end end
    if inputChanged then for _,k in ipairs({'rate','min','max'})do if gi[3][k]~=i[k]then fail('YAW VERIFY FAILED / NO EEPROM');return end end end
    if servoChanged then for k,v in pairs(row)do if gs[savedIndex][k].value~=v.value then fail('SERVO VERIFY FAILED / NO EEPROM');return end end end
    done(g,gi,gs)
   end)end
   local function finishWrites()verify(function()q(250,nil,function()verify(function(g,gi,gs)cfg=g;inputs=gi;servos=gs;draft={};undo={};liveLast={};livePending={};busy=false;state='SAVED / VERIFIED / OVERRIDE OFF'end)end)end)end
   local function writeServo()if servoChanged then h.servos().setServoConfiguration(savedIndex,row,function()if token==epoch then finishWrites()end end,function()if token==epoch then fail('SERVO WRITE FAILED')end end)else finishWrites()end end
   local function writeInput()if inputChanged then local p={3};for _,k in ipairs({'rate','min','max'})do rf2.mspHelper.writeU16(p,i[k])end;q(171,p,writeServo)else writeServo()end end
   if configChanged then h.mixer().write(c,function()if token==epoch then writeInput()end end,function()if token==epoch then fail('FC REQUEST FAILED / MSP 43')end end)else writeInput()end
  end)end)end)
 end
 function M.back()if busy or liveBusy then state='WAIT FOR FC / RETRY BACK';return end
  if next(draft)then modal='discard';return end
  release(function()busy=false;applyLive(true,function()if view=='menu'then epoch=epoch+1;h.back()else view='menu';focus=1;state='RESTORED / OVERRIDE OFF'end end)end)
 end
 function M.activate(a)
  local k=a.key;if k~='number'and k~='increment'then editing=nil end;if k=='back'then M.back();return end
  if k=='cancel'then modal=nil;return end
  if k=='confirm'then local m=modal;modal=nil;if m=='save'then save()elseif m=='discard'then draft={};M.back()end;return end
  if busy or modal or not ready then return end
  if k=='view'then if next(draft)or liveBusy then state='SAVE OR BACK TO DISCARD';return end;view=a.value;focus=1;return end
  if k=='save'then if next(draft)then modal='save'else state='NO CHANGES'end;return end
  if k=='override'then if over then release()elseif next(draft)then state='APPLY DRAFT BEFORE TEST'else busy=true;disarm(function()override(0,function()over=true;busy=false;target=0;state='OVERRIDE ON / TARGET ONLY'end)end)end;return end
  if k=='preset'then if over and not next(draft)then sendTarget(a.value)end;return end
  if k=='step'then if over and not next(draft)then sendTarget(math.max(mode()==0 and -60 or -125,math.min(mode()==0 and 60 or 125,target+a.value)))end;return end
  if (k=='mode'or k=='direction')and(next(undo)or liveBusy)then state='SAVE OR RESTORE LIVE VALUES FIRST';return end
  if k=='mode'then h.choice('TAIL ROTOR TYPE',{{'VARIABLE PITCH',0},{'MOTORIZED',1},{'BIDIRECTIONAL',2}},mode()+1,function(v)draft.cw=nil;draft.ccw=nil;M.commit('tail_rotor_mode',v)end);return end
  if k=='direction'then M.commit('direction',-val('direction'));return end
  if k=='reverse'then M.commit('flags',bit32.bxor(val('flags'),1));return end
  if k=='pulse'then local small=a.value==760;M.commit('mid',a.value);M.commit('rate',333);M.commit('min',small and -350 or -700);M.commit('max',small and 350 or 700);M.commit('scaleNeg',small and 250 or 500);M.commit('scalePos',small and 250 or 500);return end
  if k=='servo'then if next(draft)then state='SAVE OR DISCARD FIRST';return end;local list={};local ix=1;for i=0,31 do if servos[i]then list[#list+1]={'SERVO '..(i+1),i};if i==selected then ix=#list end end end;h.choice('TAIL SERVO OUTPUT',list,ix,function(v)selected=v end);return end
  if k=='increment'then incrementIndex=incrementIndex%3+1;return end
  if k=='number'then
   if editing and editing.value==a.value and not a.roller then h.number(a.value,val(a.value),a.lo,a.hi,a.decimal)
   elseif editing and editing.value==a.value and a.roller then incrementIndex=incrementIndex%3+1
   else editing=a;state='SELECTED / ROLLER EDIT / TAP AGAIN: INPUT'end;return end
 end
 local function btn(id,label,x,y,w,hh,a)controls[#controls+1]=a;if a.key=='number'then a.x=x;a.y=y;a.w=w;a.h=hh end;h.button(id,label,x,y,w,hh,focus==#controls or(editing and a.key=='number'and editing.value==a.value),a,'cyan')end
 local function action(k,v)return{kind='easyTail',key=k,value=v}end
 local function number(k,label,x,y,lo,hi,decimal)local a=action('number',k);a.lo=lo;a.hi=hi;a.decimal=decimal;h.txt(x,y+8,label,'text');btn('tail'..k,string.format(decimal and'%.1f'or'%d',val(k)),x+260,y,110,34,a)end
 local function picture()
  local function line(a,b,c,d,color)h.line(a,b,c,d,color or'text')end
  local travel=over and math.max(-1,math.min(1,target/(mode()==0 and 60 or 125)))or 0
  local pitch=travel*60*math.pi/180
  h.txt(190,105,'TOP VIEW / NOSE UP','muted')
  h.fill(195,136,30,79,'panel2');h.box(195,136,30,79,'cyan');h.box(180,208,59,42,'cyan')
  line(239,229,421,229);line(408,196,408,262)
  -- Blade chord projects narrower and changes slant with pitch, not rotor azimuth.
  local w=math.max(4,14*math.cos(pitch));local skew=12*math.sin(pitch)
  line(408-w,196,408-w+skew,133);line(408-w+skew,133,408+w+skew,133);line(408+w+skew,133,408+w,196);line(408+w,196,408-w,196)
  line(408-w,262,408-w-skew,330);line(408-w-skew,330,408+w-skew,330);line(408+w-skew,330,408+w,262);line(408+w,262,408-w,262)
  local x=310+travel*55
  if mode()==0 then h.fill(x,210,16,38,'orange');line(x+8,215,408,197,'orange');line(x+8,242,408,261,'orange');line(x+8,248,270,284,'orange');line(270,284,224,284,'orange')end
  h.txt(260,346,mode()==0 and'PITCH SLIDER'or'MOTOR TAIL','orange')
  if over then h.txt(25,310,'TARGET '..string.format('%+.1f',target)..(mode()==0 and' deg'or' %'),'cyan')
  else h.txt(25,310,'OVERRIDE OFF','muted')end
 end
 function M.draw()
  controls={};h.header('TAIL / SETUP',state)
  if view=='menu'then btn('taildefault','1. TAIL SERVO DEFAULT SETUP',30,130,740,64,action('view','defaults'));btn('tailsettings','2. TAIL ROTOR SETTINGS',30,212,740,64,action('view','settings'))
  elseif view=='defaults'then
   if mode()~=0 then h.txt(35,150,'MOTORIZED TAIL / NO VARIABLE-PITCH SERVO','orange')else
    btn('tailservo','TAIL SERVO '..(selected+1),30,105,260,36,action('servo'));btn('tailreverse',bit32.band(val('flags'),1)==0 and'NORMAL'or'REVERSED',420,105,250,36,action('reverse'))
    btn('tail1520','1520 us / DEFAULTS',30,147,350,35,action('pulse',1520));btn('tail760','760 us / DEFAULTS',420,147,350,35,action('pulse',760))
    for n,r in ipairs({{'mid','Center pulse [us]',50,2250},{'rate','Update rate [Hz]',50,5000},{'min','Minimum offset [us]',-1000,1000},{'max','Maximum offset [us]',-1000,1000},{'scaleNeg','Negative scale',100,1000},{'scalePos','Positive scale',100,1000},{'speed','Speed [ms]',0,60000}})do local col=(n-1)%2;local row=math.floor((n-1)/2);number(r[1],r[2],25+col*390,195+row*48,r[3],r[4],false)end
   end
  else picture()
   btn('tailoverride',over and'OVERRIDE ON'or'OVERRIDE OFF',25,156,155,38,action('override'))
   btn('tailminus22',mode()==0 and'-22 deg'or'-22 %',25,207,72,36,action('preset',-22));btn('tailplus22',mode()==0 and'+22 deg'or'+22 %',104,207,72,36,action('preset',22))
   btn('tailcw','CW',255,149,65,34,action('preset',-val('cw')));btn('tailcenter','CENTER',328,149,86,34,action('preset',0));btn('tailccw','CCW',422,149,65,34,action('preset',val('ccw')))
   btn('tailmode',({'VARIABLE PITCH','MOTORIZED','BIDIRECTIONAL'})[mode()+1],510,120,265,35,action('mode'));h.txt(510,101,'Tail rotor type','muted')
   btn('taildir','YAW: '..(val('direction')==1 and'NORMAL'or'REVERSED'),510,164,265,35,action('direction'))
   local rows={{'trim','Yaw center trim [%]',-50,50},{'cal','Yaw calibration [%]',.1,500},{'cw',mode()==0 and'CW blade limit [deg]'or'CW output limit [%]',0,mode()==0 and 60 or 250},{'ccw',mode()==0 and'CCW blade limit [deg]'or'CCW output limit [%]',0,mode()==0 and 60 or 250}}
   for n,r in ipairs(rows)do local y=209+(n-1)*42;local act=action('number',r[1]);act.lo=r[3];act.hi=r[4];act.decimal=true;h.txt(510,y+9,r[2],'text');btn('tail'..r[1],string.format('%.1f',val(r[1])),700,y,75,34,act)end
   local limit=mode()==0 and 60 or 125
   h.txt(25,395,'TARGET','muted');btn('tailzero','0',115,385,65,36,action('preset',0));btn('tailleft','<',190,385,38,36,action('step',-1));btn('tailright','>',737,385,38,36,action('step',1))
   local shown=over and target or 0;h.line(250,402,710,402,'muted');local x=250+(math.max(-limit,math.min(limit,shown))+limit)/(limit*2)*460;h.fill(x-5,389,10,27,over and'orange'or'cyan')
   for n=0,12 do local tx=250+n/12*460;h.line(tx,412,tx,n%2==0 and 421 or 417,'muted');if n%2==0 then h.txt(tx-12,425,string.format('%.0f',-limit+n/12*limit*2),'muted')end end
   h.hit('tailbar',240,378,480,44,action('slider'))
  end
  btn('tailsave','APPLY & SAVE',560,62,180,34,action('save'))
  if view~='menu'then btn('tailincrement','STEP '..tostring(increments[incrementIndex]),25,62,125,34,action('increment'))end
  h.footer(view=='settings'and'OFF: centered preview / ON: target. Picture is not measured pitch. RTN: back.'or'Draft edits / Save verifies FC values. Disconnect motor before testing.')
  if modal then h.clearHits();controls={};h.fill(100,140,600,220,'panel');h.box(100,140,600,220,'orange');h.txt(125,172,modal=='save'and'APPLY DRAFT & SAVE TO FC?'or'DISCARD UNSAVED CHANGES?','orange');btn('tailcancel','CANCEL',145,270,210,50,action('cancel'));btn('tailconfirm','CONFIRM',440,270,210,50,action('confirm'))end
 end
 function M.event(e,touch)
  if not modal and not busy and type(touch)=='table'then
   local x,y=h.coords(touch.x,touch.y)
   if e==EVT_TOUCH_FIRST then
    for _,a in ipairs(controls)do if a.key=='number'and x>=a.x and x<=a.x+a.w and y>=a.y and y<=a.y+a.h then held=a;heldAt=getTime();heldOpened=false;return 0 end end
   elseif held and e==EVT_TOUCH_SLIDE then
    if x<held.x or x>held.x+held.w or y<held.y or y>held.y+held.h then held=nil end;return 0
   elseif held and e==EVT_TOUCH_BREAK then
    local a=held;held=nil;if not heldOpened then M.activate(a)end;heldOpened=false;return 0
   end
  end
  if view=='settings'and not modal and type(touch)=='table'then local x,y=h.coords(touch.x,touch.y)
   -- Release events may contain reset coordinates; retain the last pressed/dragged target.
   if drag and e==EVT_TOUCH_BREAK then drag=false;return 0 end
   local tap=EVT_TOUCH_TAP and e==EVT_TOUCH_TAP
   if (e==EVT_TOUCH_FIRST or tap)and x>=240 and x<=720 and y>=378 and y<=422 and over and not busy and not next(draft)then drag=not tap;local limit=mode()==0 and 60 or 125;sendTarget(math.max(-limit,math.min(limit,((x-250)/460*2-1)*limit)));return 0 end
   if drag and e==EVT_TOUCH_SLIDE then local limit=mode()==0 and 60 or 125;sendTarget(math.max(-limit,math.min(limit,((x-250)/460*2-1)*limit)));return 0 end
  end
  if editing and not modal and not busy then
   if e==EVT_VIRTUAL_NEXT or e==EVT_VIRTUAL_PREV then
    local step=editing.decimal and increments[incrementIndex]or math.max(1,increments[incrementIndex]);local v=val(editing.value)+(e==EVT_VIRTUAL_NEXT and step or -step)
    v=math.max(editing.lo,math.min(editing.hi,v));M.commit(editing.value,round(v*(editing.decimal and 10 or 1))/(editing.decimal and 10 or 1));return 0
   elseif e==EVT_VIRTUAL_ENTER then incrementIndex=incrementIndex%3+1;return 0
   elseif (EVT_VIRTUAL_ENTER_LONG and e==EVT_VIRTUAL_ENTER_LONG)or(EVT_ENTER_LONG and e==EVT_ENTER_LONG)then h.number(editing.value,val(editing.value),editing.lo,editing.hi,editing.decimal);return 0 end
  end
  if e==EVT_VIRTUAL_NEXT then focus=focus%math.max(1,#controls)+1;return 0 elseif e==EVT_VIRTUAL_PREV then focus=(focus-2)%math.max(1,#controls)+1;return 0 elseif e==EVT_VIRTUAL_ENTER then if controls[focus]then local a=controls[focus];a.roller=true;M.activate(a);a.roller=nil end;return 0 end;return e
 end
 function M.tick()
  if held and not heldOpened and getTime()-heldAt>=70 and not busy then editing=held;heldOpened=true;h.number(held.value,val(held.value),held.lo,held.hi,held.decimal)end
  if (busy or liveBusy)and getTime()-started>1600 then epoch=epoch+1;rf2.mspQueue:clear();fail('FC TIMEOUT / CHECK UNSAVED FC VALUES');ready=false;release(function()busy=false;state='TIMEOUT / OVERRIDE OFF / CHECK FC'end)end
 end
 return M
end
