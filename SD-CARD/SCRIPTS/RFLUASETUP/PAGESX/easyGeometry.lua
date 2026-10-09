-- Main rotor geometry: one ruler edits exactly one selected parameter.
-- Calibration is live in FC RAM. EEPROM is written only by Apply & Save.
return function(h)
 local M={}
 local axis,field,focus=1,'angle',1
 local rollFront=false
 local cfg,inputs,angles={}, {}, {[1]=0,[2]=0,[4]=0}
 local values={cyclic=0,collective=0,geometry=0}
 local trimKeys={trimRoll='swash_trim_roll',trimPitch='swash_trim_pitch',trimCollective='swash_trim_collective'}
 local pending,dirty={},{}
 local ready,working,over,blocked,stopping,saving=false,false,false,false,false,false
 local leaving,saveRequested,edit,drag,modal=false,false,false,nil,nil
 local waitingForOn=false
 local entryChoice=nil
 local epoch,at,lastStatus=0,0,-1000
 local waitingCommand=nil;local inputReadMode=nil;local inputsAvailable=false
 local liveReplyDelayed=false
 local monitoring=false
 local incrementIndex=1
 local increments={.1,1,10}
 local state='READING FC...'
 local controls={}
 local names={[1]='CYCLIC ROLL',[2]='CYCLIC ELEVATOR',[4]='COLLECTIVE',[5]='SWASH TRIM'}
 local labels={angle='Override angle [deg]',cyclic='Cyclic Calibration [%]',collective='Collective Calibration [%]',geometry='Geometry correct [%]',trimRoll='Roll trim [%]',trimPitch='Pitch trim [%]',trimCollective='Collective trim [%]'}
 local flush,stop,fault,startSave,enable
 local function now()return getTime and getTime()or 0 end
 local function round(v)return v>=0 and math.floor(v+.5)or math.ceil(v-.5)end
 local function clone(t)local r={};for k,v in pairs(t)do r[k]=type(v)=='table'and clone(v)or v end;return r end
 local function current()return field=='angle'and angles[axis]or values[field]or 0 end
 local function step()return increments[incrementIndex]end
 local function limits()if field=='angle'then return -18,18 elseif trimKeys[field]then return -100,100 elseif field=='geometry'then return -25,25 else return .1,200 end end
 local function begin(s)working=true;at=now();waitingCommand=nil;liveReplyDelayed=false;monitoring=false;state=s end
 local function q(cmd,payload,ok,err)
  local token=epoch;at=now();waitingCommand=cmd
  rf2.mspQueue:add({command=cmd,payload=payload,processReply=function(m,b)if token==epoch then at=now();waitingCommand=nil;liveReplyDelayed=false;if ok then ok(m,b)end end end,errorHandler=function()if token==epoch then(err or fault)('FC REQUEST FAILED / MSP '..cmd)end end})
 end
 local function readInputs(done,onError)
  local fail=onError or fault
  local function bulk()
   q(170,nil,function(_,b)
    if #b<30 or #b%6~=0 then fail('INPUT READ ERROR / MSP 170');return end
    b.offset=1;local t={};for i=0,#b/6-1 do t[i]={rate=rf2.mspHelper.readS16(b),min=rf2.mspHelper.readS16(b),max=rf2.mspHelper.readS16(b)}end
    inputReadMode='bulk';done(t)
   end,fail)
  end
  if inputReadMode=='bulk'then bulk();return end
  local ids={1,2,4};local t={}
  local function one(n)
   local i=ids[n];if not i then inputReadMode='single';done(t);return end
   local function failed(s)if inputReadMode~='single'and n==1 then bulk()else fail(s)end end
   q(174,{i},function(_,b)
    if #b~=6 then failed('INPUT READ ERROR / MSP 174');return end
    b.offset=1;t[i]={rate=rf2.mspHelper.readS16(b),min=rf2.mspHelper.readS16(b),max=rf2.mspHelper.readS16(b)};one(n+1)
   end,failed)
  end
  one(1)
 end
 local function read(done,optionalInputs)
  local token=epoch;at=now();waitingCommand=42
  h.mixer().read(function(_,c)
   if token~=epoch then return end
   readInputs(function(t)done(c,t)end,optionalInputs and function()done(c,nil)end or nil)
  end,nil,nil,function()if token==epoch then fault('CONFIG READ ERROR')end end)
 end
 local function status(ok,onError)
  if not h.ready()then(onError or fault)('NO FC LINK');return end
  q(101,nil,function(_,b)
   if #b<10 then(onError or fault)('STATUS READ ERROR');return end
   lastStatus=now();if b[7]%2~=0 then fault('DISARM FC FIRST');return end;ok()
  end,onError)
 end
 local function finished()
  working=false;state=next(dirty)and(over and'LIVE / NOT SAVED / ALL ON'or'LIVE / NOT SAVED / ALL OFF')or(over and'OVERRIDE ALL ON'or'OVERRIDE ALL OFF')
  if leaving then stop(h.back)else flush()end
 end
 stop=function(done)
  if liveReplyDelayed and rf2.mspQueue.clear then rf2.mspQueue:clear()end
  epoch=epoch+1;pending={};drag=nil;edit=false;modal=nil;waitingForOn=false;entryChoice=nil;saveRequested=false;saving=false;stopping=true
  begin('RELEASING OVERRIDES...')
  waitingCommand=196
  local token=epoch
  local function failedStop()
   if token~=epoch then return end
   stopping=false;working=false;blocked=true;modal=nil;entryChoice=nil;state='STOP FAILED / ALL OFF RETRY'
  end
  h.disable(function()
   if token~=epoch then return end
   local function release(i)
    if i>4 then
     angles={[1]=0,[2]=0,[4]=0};over=false;working=false;stopping=false;lastStatus=now()
     state='OVERRIDE ALL OFF';if done then done()end;return
    end
    local p={i};rf2.mspHelper.writeU16(p,2501);q(191,p,function()release(i+1)end,failedStop)
   end
   release(1)
  end,failedStop)
 end
 fault=function(s)
  if stopping then working=false;stopping=false;blocked=true;state='STOP FAILED / ALL OFF RETRY';return end
  stop(function()blocked=true;state=s..' / OVERRIDE OFF';if leaving then h.back()end end)
 end
 function M.open()
  inputReadMode=nil;inputsAvailable=false;axis=1;field='angle';focus=1;rollFront=false;ready=false;blocked=false;leaving=false;dirty={};pending={};values={cyclic=0,collective=0,geometry=0}
  stop(function()
   if not h.ready()then working=false;state='NO FC LINK / REOPEN';return end
   begin('READING FC...');read(function(c,t)
    cfg=c;inputs=t or{};inputsAvailable=t~=nil;values.cyclic=t and math.abs(t[1].rate)/10 or nil;values.collective=t and math.abs(t[4].rate)/10 or nil;values.geometry=c.swash_geo_correction.value/5
    for k,f in pairs(trimKeys)do values[k]=c[f].value/10 end
    ready=true;working=false;blocked=false;state='FC VALUES / ALL OFF';focus=1
    if entryChoice=='on'then modal=nil;entryChoice=nil;enable()
    elseif entryChoice=='off'then modal=nil;entryChoice=nil
    else modal=waitingForOn and'enable'or'entry'end
    waitingForOn=false
   end,true)
  end)
  modal='entry';focus=1
 end
 local function liveError(s)
  if saving then fault(s);return end
  working=false;liveReplyDelayed=false;pending={};state=s..' / OVERRIDE HELD'
 end
 local function writeInput(i,d,ok)
  local p={i};for _,k in ipairs({'rate','min','max'})do rf2.mspHelper.writeU16(p,d[k])end;q(171,p,ok,liveError)
 end
 -- Live calibration uses loaded inputs, preserving signs/limits. Save reads back for verification.
 local function apply(key,v,done)
  if key=='geometry'or trimKeys[key]then
   local token=epoch;local c=clone(cfg);local f=trimKeys[key]or'swash_geo_correction'
   c[f].value=round(v*(trimKeys[key]and 10 or 5));at=now();waitingCommand=43
   h.mixer().write(c,function()if token==epoch then cfg=c;liveReplyDelayed=false;done()end end,function()if token==epoch then liveError('FC REQUEST FAILED / MSP 43')end end)
  else
    local t=clone(inputs or{});local ids=key=='cyclic'and{1,2}or{4}
    for _,i in ipairs(ids)do if not t[i]then fault('INPUT NOT LOADED / REOPEN');return elseif t[i].rate==0 then fault('ZERO RATE / SET DIRECTION FIRST');return end end
    local function nextInput(n)
     local i=ids[n];if not i then done();return end
     t[i].rate=round(v*10)*(t[i].rate<0 and -1 or 1);writeInput(i,t[i],function()inputs[i]=clone(t[i]);nextInput(n+1)end)
    end
    nextInput(1)
  end
 end
 flush=function()
  if working or stopping or saving or blocked or not ready then return end
  if not h.ready()or not rf2.mspQueue:isProcessed()then return end
  local key,v=next(pending)
  if not key then if saveRequested then startSave()end;return end
  pending[key]=nil;begin('APPLYING / LIVE FC...')
  local function update()
   if type(key)=='number'then
    if not over then finished();return end
    local p={key};rf2.mspHelper.writeU16(p,round(v*1000/12));q(191,p,finished,liveError)
   else apply(key,v,finished)end
  end
  update()
 end
 local function change(v)
  if not ready or blocked or stopping or saving or saveRequested or not over then return end
  if (field=='cyclic'or field=='collective')and not inputsAvailable then state='INPUT READ FAILED / REOPEN TO RETRY';return end
  local lo,hi=limits();v=math.max(lo,math.min(hi,round(v*10)/10))
  if field=='angle'then angles[axis]=v;pending[axis]=v
  else values[field]=v;dirty[field]=v;pending[field]=v end
  state='UPDATE PENDING';flush()
 end
 enable=function()
  if not ready or working or blocked then return end
  modal=nil;begin('CHECKING DISARM...')
  status(function()
   local ids={1,2,4};local function nextAxis(n)
    local i=ids[n];if not i then over=true;angles={[1]=0,[2]=0,[4]=0};finished();return end
    local p={i};rf2.mspHelper.writeU16(p,0);q(191,p,function()nextAxis(n+1)end)
   end
   nextAxis(1)
  end)
 end
 startSave=function()
  if working then return end
  saveRequested=false;saving=true;begin('APPLY & SAVE...');local expected=clone(dirty)
  status(function()
   local keys={};for k in pairs(expected)do keys[#keys+1]=k end
   local function nextField(n)
    local k=keys[n];if k then apply(k,expected[k],function()nextField(n+1)end);return end
    q(250,nil,function()
     read(function(c,t)
      for k,v in pairs(expected)do
       local good=trimKeys[k]and c[trimKeys[k]].value==round(v*10)or k=='geometry'and c.swash_geo_correction.value==round(v*5)or k=='collective'and math.abs(t[4].rate)==round(v*10)or k=='cyclic'and math.abs(t[1].rate)==round(v*10)and math.abs(t[2].rate)==round(v*10)
       if not good then fault('SAVE VERIFY FAILED');return end
      end
      cfg=c;inputs=t;dirty={};working=false;saving=false;state=over and'SAVED / VERIFIED / ALL ON'or'SAVED / VERIFIED / ALL OFF'
      if leaving then stop(h.back)end
     end,not expected.cyclic and not expected.collective)
    end)
   end
   nextField(1)
  end)
 end
 function M.back()
  if modal=='entry'then leaving=true;stop(h.back);return end
  if modal then modal=nil;return end
  leaving=true;drag=nil;edit=false
  if saving or saveRequested then state='FINISH SAVE / THEN RETURN';return end
  stop(h.back)
 end
 function M.commit(key,v)if key==field and type(v)=='number'then change(v)end end
 function M.activate(a)
  local k=a.key
  if k=='back'then M.back();return end
  if k=='all'then
   if over or blocked then if saving then state='WAIT FOR SAVE';return end;stop(function()blocked=false;state='OVERRIDE ALL OFF'end)
   elseif working then waitingForOn=true
   elseif ready then modal='enable';focus=1 end;return
  end
  if k=='entryOff'and modal=='entry'then entryChoice='off';modal=nil;focus=1;if not working then entryChoice=nil;state='OVERRIDE ALL OFF'end;return end
  if k=='entryOn'and modal=='entry'then
   if blocked or(not working and not ready)then modal=nil;state='NO FC LINK / REOPEN';return end
   if working or not ready then entryChoice='on';modal=nil else enable()end;return
  end
  if k=='cancel'then modal=nil;return end
  if k=='help'then modal='help';focus=1;return end
  if k=='confirm'then local m=modal;modal=nil;if m=='enable'then enable()elseif m=='save'then saveRequested=true;flush()end;return end
  if modal or stopping or saving or saveRequested then return end
  if k=='increment'then incrementIndex=incrementIndex%#increments+1;drag=nil;return end
  if k=='axis'then axis=a.index;field=axis==5 and'trimRoll'or'angle';edit=false;drag=nil;return end
  if k=='preset'then field='angle';edit=false;drag=nil;change(a.index);return end
  if k=='field'then
   local alreadySelected=field==a.index
   field=a.index;edit=over and not blocked;drag=nil
   if (field=='cyclic'or field=='collective')and not inputsAvailable then edit=false;state='INPUT READ FAILED / REOPEN TO RETRY';return end
   if alreadySelected and over and not blocked then edit=false;local lo,hi=limits();h.number(field,current(),lo,hi,.1)end
   return
  end
  if k=='ruler'then edit=over and not edit;return end
  if k=='number'then if over and not blocked then local lo,hi=limits();h.number(field,current(),lo,hi,step()==.2 and .2 or .1)end;return end
  if k=='save'and ready then if next(dirty)then modal='save';focus=1 else state='NO CALIBRATION CHANGES'end;return end
 end
 local function line(x,y,x2,y2,c)h.line(x,y,x2,y2,c or'text')end
 local function path(cx,cy,pts,c)for i=1,#pts-1 do local a,b=pts[i],pts[i+1];line(cx+a[1],cy+a[2],cx+b[1],cy+b[2],c)end end
 local function ellipse(x,y,rx,ry,c,tilt)
  local ca,sa=math.cos(tilt or 0),math.sin(tilt or 0);local px,py=x+rx*ca,y+rx*sa
  for i=1,32 do local a=i*math.pi/16;local dx,dy=math.cos(a)*rx,math.sin(a)*ry;local nx,ny=x+dx*ca-dy*sa,y+dx*sa+dy*ca;line(px,py,nx,ny,c);px,py=nx,ny end
 end
 local function helicopter()
  local side=axis==2;local x,y=230,185
  local baseLine,basePath,baseEllipse=line,path,ellipse
  local scaleX=side and .9 or 1.5
  local function mx(v)return (side and 315 or 300)+(v-230)*scaleX end
  local function my(v)return 280+(v-203)*1.5 end
  local function line(a,b,c,d,color)baseLine(mx(a),my(b),mx(c),my(d),color)end
  local function path(cx,cy,pts,color)local p={};for i,v in ipairs(pts)do p[i]={v[1]*scaleX,v[2]*1.5}end;basePath(mx(cx),my(cy),p,color)end
  local function ellipse(cx,cy,rx,ry,color,t)
   local pts={};for i=0,32 do local a=i*math.pi/16;local dx,dy=math.cos(a)*rx,math.sin(a)*ry;pts[#pts+1]={dx*math.cos(t or 0)-dy*math.sin(t or 0),dx*math.sin(t or 0)+dy*math.cos(t or 0)}end;path(cx,cy,pts,color)
  end
  do
   local baseLine,basePath,baseEllipse=line,path,ellipse
   local function mx(v)return x+(side and -1 or 1)*(v-x)*1.2 end
   local function line(a,b,c,d,color)baseLine(mx(a),y+(b-y)*1.2,mx(c),y+(d-y)*1.2,color)end
   local function path(cx,cy,pts,color)local p={};for i,v in ipairs(pts)do p[i]={(side and -1 or 1)*v[1]*1.2,v[2]*1.2}end;basePath(cx,cy,p,color)end
   local function ellipse(cx,cy,rx,ry,color,t)baseEllipse(mx(cx),y+(cy-y)*1.2,rx*1.2,ry*1.2,color,side and -(t or 0)or t)end
  if side then
   line(x-27,y-18,x-27,y+25,'text')
   path(x,y,{{-65,20},{-94,26},{-108,45},{-103,61},{-82,69},{-45,69},{-22,53},{-12,33},{-35,21},{-65,20}},'cyan')
   path(x,y,{{-71,27},{-93,33},{-98,45},{-70,47},{-53,28},{-71,27}},'muted')
   path(x,y,{{-14,37},{135,29},{135,38},{-22,52}},'cyan');line(x+128,y+12,x+141,y+56,'orange');ellipse(x+135,y+34,18,18,'orange')
   line(x-91,y+64,x-91,y+79,'text');line(x-42,y+67,x-42,y+79,'text');line(x-114,y+79,x-20,y+79,'text')
  else
   line(x,y-18,x,y+29,'text')
   path(x,y,{{-16,24},{-35,31},{-43,50},{-35,65},{-22,71},{22,71},{35,65},{43,50},{35,31},{16,24},{-16,24}},'cyan')
   path(x,y,{{-18,30},{-30,37},{-28,46},{28,46},{30,37},{18,30},{-18,30}},'muted')
   line(x-34,y+57,x-63,y+80,'text');line(x+34,y+57,x+63,y+80,'text');line(x-75,y+80,x-46,y+80,'text');line(x+46,y+80,x+75,y+80,'text')
   if not rollFront then path(x,y,{{-4,48},{-7,85},{7,85},{4,48},{-4,48}},'orange');line(x-22,y+64,x+22,y+64,'orange');line(x+7,y+66,x+32,y+66,'orange');line(x+32,y+54,x+32,y+80,'orange')end
  end
  end
  if side then x=x+32.4 end
  -- This is an illustration of the requested angle, never measured blade pitch.
  local a=axis~=5 and over and angles[axis]or 0;local tilt=axis==4 and 0 or a*math.pi/180;if axis==1 and rollFront then tilt=-tilt end;if axis==5 then tilt=math.max(-12,math.min(12,values.trimRoll or 0))*.1*math.pi/180 end;local sy=y+18+(axis==4 and -a*1.1 or axis==5 and -(values.trimCollective or 0)*.08 or 0)
  local left=sy-math.sin(tilt)*38;local right=sy+math.sin(tilt)*38
  line(x-38,left,x-37,y+30,'muted');line(x+38,right,x+37,y+30,'muted');ellipse(x,sy,38,8,'green',tilt);ellipse(x,sy+5,38,8,'green',tilt);line(x-38,left,x-38,left+5,'green');line(x+38,right,x+38,right+5,'green');ellipse(x,sy,8,5,'muted',tilt)
  -- Both rear views use the same fore/aft two-blade layout.
  local rotorY=200
  local ca,sa=math.cos(tilt),math.sin(tilt)
  local function blade(points)
   local p={};for i,v in ipairs(points)do p[i]={v[1]*ca-v[2]*sa,v[1]*sa+v[2]*ca}end
   path(x,rotorY,p,'text')
  end
  if side then
   blade({{-29,-4},{29,-4},{29,4},{-29,4},{-29,-4}})
  else
   blade({{-6,-45},{6,-45},{6,-7},{-6,-7},{-6,-45}})
   blade({{-6,7},{6,7},{6,45},{-6,45},{-6,7}})
  end
  ellipse(x,rotorY,7,4,'text',tilt)
  -- Rectangular pitch gauge mounted at the main blade; command target only.
  local gx,gy=300,167
  if axis~=5 then
  h.fill(gx,gy,116,38,'panel');h.box(gx,gy,116,38,'orange')
  h.txt(gx+7,gy+3,'TARGET [deg]','orange')
  h.txt(gx+7,gy+18,string.format('%+.1f',a),over and'green'or'muted',true)
  baseLine(mx(x),my(y-18),gx,gy+25,'orange')
  end
  h.txt(24,148,side and'SIDE VIEW: TAIL < / FRONT >'or(rollFront and'FRONT VIEW'or'TAIL / REAR VIEW'),'muted')
 end
 local function btn(label,x,y,w,hh,key,index,on)
  local a={kind='easyGeometry',key=key,index=index};controls[#controls+1]=a
  local focused=not edit and focus==#controls
  h.button('eg'..#controls,label,x,y,w,hh,on or(key~='axis'and focused),a,on and'orange'or'cyan')
  if key=='axis'and focused and not on then h.box(x+2,y+2,w-4,hh-4,'muted')end
 end
 function M.draw()
  controls={};h.header('SERVO / SWASH 4 / MAIN ROTOR GEOMETRY',saving and'SAVING...'or stopping and'OFF...'or not ready and'READING...'or(over and'ALL ON'or'ALL OFF'))
  btn('APPLY & SAVE',592,59,151,29,'save')
  for n,i in ipairs({1,2,4,5})do btn(names[i],20+(n-1)*151,95,143,36,'axis',i,axis==i)end
  h.fill(20,143,598,295,'panel2');h.box(20,143,598,295,'line');helicopter()
  h.txt(24,173,'OVERRIDE ALL','cyan')
  btn(blocked and'RETRY OFF'or'ON / OFF',24,190,112,28,'all',nil,over and not blocked)
  if axis~=5 then
   for n,v in ipairs({12,0,-12})do btn(v==0 and'0.0 deg'or string.format('%+.1f deg',v),24,222+(n-1)*43,112,34,'preset',v,over and math.abs(angles[axis]-v)<.05)end
  end
  local keys=axis==5 and{'trimRoll','trimPitch','trimCollective'}or(axis==1 or axis==2)and{'angle','cyclic'}or{'angle','collective','geometry'}
  for n,k in ipairs(keys)do
   local y=214+(n-1)*72;btn('',452,y,166,62,'field',k,field==k)
   h.txt(460,y+8,labels[k],field==k and'cyan'or'text')
   local v=k=='angle'and angles[axis]or values[k];h.txt(460,y+33,v and string.format('%+.1f',v)or'READ FAILED',over and'green'or'muted',true)
  end
  h.fill(632,103,148,335,'panel2');h.box(632,103,148,335,'cyan')
  h.txt(640,115,field=='angle'and'ANGLE [deg]'or'VALUE [%]','cyan')
  btn('',642,178,128,249,'ruler');h.txt(650,150,(field=='cyclic'or field=='collective')and not inputsAvailable and'NO DATA'or string.format('%+.1f',current()),over and'green'or'muted',true)
  btn(string.format('%g',step()),728,145,42,28,'increment')
  local cy=285;local unit=step();local base=math.floor(current()/unit);local frac=current()/unit-base
  local lo,hi=limits()
  for n=-14,14 do local yy=cy-(n-frac)*9;local v=(base+n)*unit
   if yy>=178 and yy<=421 and v>=lo and v<=hi then
    local major=(base+n)%5==0;h.fill(major and 706 or 737,yy,major and 56 or 25,1,'muted')
    if major then h.txt(650,yy-7,string.format('%.1f',v),'text')end
   end
  end
  h.fill(644,cy,124,2,'orange')
  if blocked or(not working and not ready)or string.find(state,'^SAVED')or string.find(state,'INPUT READ FAILED')or string.find(state,'FAILED')or string.find(state,'OVERRIDE HELD')or liveReplyDelayed then h.txt(24,423,state,'orange')end
  h.footer('Click: select / Click selected value: input / Touch ruler: adjust / RTN: return')
  if modal then
   controls={};h.clearHits();h.fill(105,130,590,240,'panel');h.box(105,130,590,240,'orange')
   if modal=='entry'then
    h.txt(130,150,'MIXER OVERRIDE: ON OR OFF?','cyan',true)
    h.txt(130,195,'Disconnect motor power before enabling overrides.','orange')
    h.txt(130,229,'ON: hold main rotor servos / OFF: view settings only','text')
    btn('OVERRIDE OFF',150,292,200,44,'entryOff');btn('OVERRIDE ON',425,292,225,44,'entryOn');return
   end
   if modal=='help'then
    h.txt(130,150,'MAIN ROTOR GEOMETRY HELP','cyan',true)
    h.txt(130,192,'One ruler changes only the selected axis or parameter.','text')
    h.txt(130,224,'Cyclic Calibration is shared by Roll and Pitch.','text')
    h.txt(130,256,'Calibration is LIVE on FC. APPLY & SAVE writes EEPROM.','orange')
    h.txt(130,278,'Hold +/-12 deg; adjust Calibration to match your gauge.','text')
    btn('CLOSE',295,302,210,44,'cancel');return
   end
   h.txt(130,150,modal=='enable'and'ENABLE MAIN ROTOR OVERRIDE?'or'SAVE GEOMETRY CALIBRATION?','orange',true)
   h.txt(130,195,modal=='enable'and'Disconnect motor power. Main rotor servos will move.'or'Calibration is already live on the FC. Save to EEPROM.','text')
   h.txt(130,229,modal=='enable'and'Roll / Pitch / Collective start at zero. Tail stays OFF.'or'Override angles are temporary and are not saved.','muted')
   btn('CANCEL',150,292,200,44,'cancel');btn(modal=='enable'and'ALL ON'or'APPLY & SAVE',425,292,225,44,'confirm')
  end
 end
 function M.event(e,touch)
  if e==EVT_VIRTUAL_EXIT then M.back();return 0 end
  if modal then
   if modal=='entry'then
    if e==EVT_VIRTUAL_NEXT or e==EVT_VIRTUAL_PREV then focus=focus==1 and 2 or 1;return 0 elseif e==EVT_VIRTUAL_ENTER then M.activate({key=focus==1 and'entryOff'or'entryOn'});return 0 end;return e
   end
   if e==EVT_VIRTUAL_NEXT or e==EVT_VIRTUAL_PREV then focus=focus==1 and 2 or 1;return 0 elseif e==EVT_VIRTUAL_ENTER then M.activate({key=focus==2 and'confirm'or'cancel'});return 0 end;return e
  end
  if type(touch)=='table'then
   local x,y=h.coords(touch.x,touch.y)
   if e==EVT_TOUCH_FIRST and x>=642 and x<=770 and y>=178 and y<=427 then if over and not blocked and not saving and not stopping then drag={y=y,value=current(),step=step(),axis=axis,field=field};edit=true end;return 0
   elseif drag and(e==EVT_TOUCH_SLIDE or e==EVT_TOUCH_BREAK)then change(drag.value+(drag.y-y)/9*drag.step);if e==EVT_TOUCH_BREAK then drag=nil end;return 0
   elseif e==EVT_TOUCH_TAP and x>=642 and x<=770 and y>=178 and y<=427 then return 0 end
  end
  if edit then
   if e==EVT_VIRTUAL_NEXT or e==EVT_VIRTUAL_PREV then change(current()+(e==EVT_VIRTUAL_NEXT and 1 or -1)*step());return 0 elseif e==EVT_VIRTUAL_ENTER then M.activate({key='field',index=field,roller=true});return 0 end
  end
  if e==EVT_VIRTUAL_NEXT or e==EVT_VIRTUAL_PREV then focus=(focus-1+(e==EVT_VIRTUAL_NEXT and 1 or -1))%math.max(1,#controls)+1;return 0 elseif e==EVT_VIRTUAL_ENTER then if controls[focus]then local a=controls[focus];M.activate({key=a.key,index=a.index,roller=true})end;return 0 end;return e
 end
 function M.tick()
  if waitingForOn and ready and not working and not blocked and not leaving then waitingForOn=false;modal='enable';focus=1 end
  local timeout=waitingCommand==101 and 300 or waitingCommand==250 and 1000 or 600
  if working and now()-at>timeout then
   local failedCommand=waitingCommand or'?'
   if monitoring then
    epoch=epoch+1;if rf2.mspQueue.clear then rf2.mspQueue:clear()end
    monitoring=false;working=false;lastStatus=now();state='STATUS REPLY DELAY / OVERRIDE HELD';return
   end
   if not saving and not stopping and not leaving and(waitingCommand==191 or waitingCommand==171 or waitingCommand==43)then
    liveReplyDelayed=true;at=now();state='FC REPLY DELAY / MSP '..failedCommand..' / OVERRIDE HELD';return
   end
   if not stopping and not leaving then
    if rf2.mspQueue.clear then rf2.mspQueue:clear()end
    fault('FC NO RESPONSE / MSP '..failedCommand);return
   end
   epoch=epoch+1;pending={};waitingForOn=false;drag=nil;edit=false;working=false;saving=false;stopping=false;blocked=true
   if rf2.mspQueue.clear then rf2.mspQueue:clear()end
   state='FC NO RESPONSE / MSP '..failedCommand..' / OFF UNCONFIRMED'
   -- A release retry is required; never claim the FC acknowledged OFF.
   if leaving then leaving=false;h.back('FC NO RESPONSE / GEOMETRY RELEASE & SAVE UNCONFIRMED')end
   return
  end
  if over and not working and not blocked and not edit and not drag and not modal and not(h.editing and h.editing())and not next(pending)and rf2.mspQueue:isProcessed()and now()-lastStatus>=100 then
   begin('CHECKING DISARM...');monitoring=true
   status(function()monitoring=false;finished()end,function(s)monitoring=false;lastStatus=now();working=false;state=s..' / OVERRIDE HELD'end)
  else flush()end
 end
 return M
end









