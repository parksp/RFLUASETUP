-- Easy Setup owns its draft. Only save() sends configuration writes.
return function(h)
 local M={}
 local steps={'SWASH','COLL DIR','SERVOS','TRIM','COLLECTIVE','CYCLIC','TAIL'}
 local step=1
 local inputs={}
 local editedServo,editedMix,editedInput={},{},{}
 local mixTest=false
 local testAxis,testValue=4,0
 local tailPage=1
 local draft,mix,ready,busy,dirty={},nil,false,false,false
 local state,sel,focus,front='READING FC...',0,1,false
 local active,angle,modal=nil,0,nil
 local allMode=false
 local enabled={}
 local trimDrag=nil
 local rulerEdit=false
 local feedbackAt=-1000
 local anglesByServo={}
 local details=false
 local overrideView=false
 local controls={}
 local lastPoll=0
 local pwm,pwmAt={},{}
 local lastPwmPoll=0
 local pwmConfig=nil
 local pollPending=false
 local epoch=0
 local overridePending,nextAngle=false,nil
 local fields={'mid','min','max','rate','flags','scaleNeg','scalePos','speed'}
 local names={'None','Direct','CCPM 120','CCPM 135','CCPM 140','FPM 90 L','FPM 90 V'}
 local function copy(t)
  if type(t)~='table' then return t end
  local out={};for k,v in pairs(t)do out[k]=copy(v)end;return out
 end
 local function changed()dirty=true;state='DRAFT / APPLY BEFORE TEST'end
 local function failed(s)busy=false;state=s or 'FAILED / CHECK FC'end
 local function queue(cmd,payload,ok,err)
  rf2.mspQueue:add({command=cmd,payload=payload,processReply=ok,errorHandler=err})
 end
 local function readPWM(done,background)
  local i=sel;local token=epoch
  if background then pollPending=true else busy=true end
  lastPwmPoll=getTime and getTime()or 0
  queue(103,nil,function(_,b)
   if background then pollPending=false;if token~=epoch then return end else busy=false end
   for si=0,3 do
    local offset=si*2+1
    if #b>=offset+1 then pwm[si]=b[offset]+b[offset+1]*256;pwmAt[si]=getTime and getTime()or 0
    else pwm[si]=nil end
   end
   if not pwm[i]then state='PWM READ FAILED';return end
   if done then done()end
  end,function()
   if background then pollPending=false;if token~=epoch then return end else busy=false end
   pwm={};state='PWM READ FAILED / RETRY'
  end)
 end
 -- Wait for FC acknowledgement before switching servos or leaving the page.
 local function stop(done)
  epoch=epoch+1;nextAngle=nil;trimDrag=nil;rulerEdit=false
  busy=true;state='STOPPING OVERRIDE...'
  local function disable()
   h.disable(function()
    local function release(i)
     if i>4 then active=nil;enabled={};allMode=false;mixTest=false;anglesByServo={};angle=0;busy=false;if done then done()end;return end
     local p={i};rf2.mspHelper.writeU16(p,2501)
     queue(191,p,function()release(i+1)end,function()failed('MIXER STOP FAILED / ALL OFF')end)
    end
    release(1)
   end,
    function()failed('STOP FAILED - RETRY ALL OFF')end)
  end
  if allMode then disable()elseif active~=nil then h.override(active,0,true,disable,disable)else disable()end
 end
 local function readInputs(done,onError)
  queue(170,nil,function(_,b)
   if #b<30 or #b%6~=0 then onError();return end
   b.offset=1;local t={}
   for i=0,#b/6-1 do t[i]={rate=rf2.mspHelper.readS16(b),min=rf2.mspHelper.readS16(b),max=rf2.mspHelper.readS16(b)}end
   done(t)
  end,onError)
 end
 local function flushOverride()
  if busy or overridePending or active==nil or nextAngle==nil then return end
  -- A continuously dragged ruler must not starve the 500 ms ARM/link check.
  if (getTime and getTime()or 0)-lastPoll>=50 then return end
  local value=nextAngle;nextAngle=nil;local token=epoch
  anglesByServo[active]=value
  overridePending=true
  h.override(active,value,true,function()
   overridePending=false;if token~=epoch then return end
   state=allMode and'OVERRIDE ALL ON - S1 / S2 / S3'or'OVERRIDE ACTIVE';lastPwmPoll=-1000;flushOverride()
  end,function()
   overridePending=false;if token~=epoch then return end
   stop(function()failed('OVERRIDE FAILED / STOPPED')end)
  end)
 end
 local function disarmed(done)
  busy=true;state='CHECKING DISARM...'
  queue(101,nil,function(_,b)
   if #b<10 then failed('STATUS READ ERROR');return end
   -- MSP_STATUS starts its packed flight-mode flags at byte 7 (ARM = bit 0).
   if b[7]%2~=0 then failed('DISARM FC FIRST');return end
   lastPoll=getTime and getTime()or 0
   done()
  end,function()failed('NO FC STATUS / TRY AGAIN')end)
 end
 local function read()
  ready=false;busy=true;state='READING FC...'
  h.servos().getServoConfigurations(function(_,d)
   for i=0,2 do
    if not d[i] then failed('NEED AT LEAST 3 SERVOS');return end
    for _,key in ipairs(fields)do if not d[i][key]or d[i][key].value==nil then failed('INCOMPLETE SERVO DATA');return end end
   end
   draft=copy(d)
   h.mixer().read(function(_,m)
    mix=copy(m)
    readInputs(function(t)inputs=t;editedServo={};editedMix={};editedInput={};ready=true;busy=false;dirty=false;state='FC VALUES / NOT EDITED'end,
     function()failed('INPUT READ FAILED / RELOAD')end)
   end,nil,nil,
    function()failed('MIXER READ FAILED / RELOAD')end)
  end,nil,function()failed('SERVO READ FAILED / RELOAD')end)
 end
 function M.open()
  step=1;tailPage=1;sel=0;focus=1;modal=nil;details=false;overrideView=false;active=nil;angle=0;ready=false;dirty=false;front=false;pwm={};pwmAt={}
  if not h.ready()then failed('FC NOT READY / RELOAD');return end
  stop(read)
 end
 local function confirm(kind,value)modal={kind=kind,value=value,yes=false}end
 local function verify()
  state='VERIFYING FC...'
  h.servos().getServoConfigurations(function(_,got)
   for i in pairs(editedServo)do for _,key in ipairs(fields)do
    if not got[i]or not got[i][key]or got[i][key].value~=draft[i][key].value then failed('SAVED / VERIFY MISMATCH');return end
   end end
   h.mixer().read(function(_,gotMix)
    for key in pairs(editedMix)do if gotMix[key].value~=mix[key].value then failed('SAVED / MIXER MISMATCH');return end end
    readInputs(function(gotInput)
     for i in pairs(editedInput)do for _,key in ipairs({'rate','min','max'})do
      if gotInput[i][key]~=inputs[i][key]then failed('SAVED / INPUT MISMATCH');return end
     end end
     busy=false;dirty=false;editedServo={};editedMix={};editedInput={};state='SAVED / VERIFIED'
    end,function()failed('SAVED / INPUT VERIFY FAILED')end)
   end,nil,nil,function()failed('SAVED / VERIFY READ FAILED')end)
  end,nil,function()failed('SAVED / VERIFY READ FAILED')end)
 end
 local function save()
  if not ready or busy then return end
  for i in pairs(editedServo)do if draft[i].min.value>=draft[i].max.value then failed('MIN MUST BE LESS THAN MAX');return end end
  stop(function()disarmed(function()
   state='SAVING TO FC...'
   local function writeServo(i)
    if i<4 then
     if not editedServo[i]then writeServo(i+1);return end
     h.servos().setServoConfiguration(i,draft[i],function()writeServo(i+1)end,
      function()failed('PARTIAL APPLY / RETRY SAVE')end)
    else
     -- Preserve mixer fields outside this wizard's explicit edits.
     h.mixer().read(function(_,fresh)
      for key in pairs(editedMix)do fresh[key].value=mix[key].value end
      h.mixer().write(fresh,function()
       local function writeInput(ix)
        if ix>4 then queue(250,nil,verify,function()failed('APPLIED / EEPROM SAVE FAILED')end);return end
        if not editedInput[ix]then writeInput(ix+1);return end
        local p={ix};local d=inputs[ix]
        for _,key in ipairs({'rate','min','max'})do rf2.mspHelper.writeU16(p,d[key])end
        queue(171,p,function()writeInput(ix+1)end,function()failed('PARTIAL APPLY / INPUT FAILED')end)
       end
       writeInput(1)
      end,function()failed('PARTIAL APPLY / MIXER FAILED')end)
     end,nil,nil,function()failed('PARTIAL APPLY / MIXER READ FAIL')end)
    end
   end
   writeServo(0)
  end)end)
 end
 local function leave()stop(function()h.back()end)end
 function M.back()
  if busy then return end
  if modal then modal=nil;return end
  if details then
   if allMode then epoch=epoch+1;nextAngle=nil;angle=anglesByServo[sel]or 0;details=false;overrideView=false;focus=1;state='OVERRIDE ALL ON - SELECT SERVO'
   else stop(function()details=false;overrideView=false;focus=1;state=dirty and'DRAFT / NOT SAVED'or'FC VALUES'end)end
   return
  end
  if dirty then stop(function()confirm('leave')end)else leave()end
 end
 function M.commit(key,v)
  if not ready or busy then return end
  if string.sub(key,1,4)=='cfg:'then
   local k=string.sub(key,5);local d=mix[k];if not d then return end
   local scale=k=='swash_pitch_limit'and 1000/12 or k=='swash_geo_correction'and 5 or 10
   d.value=math.max(d.min,math.min(d.max,math.floor(v*scale+.5)));editedMix[k]=true;changed()
  elseif string.sub(key,1,3)=='in:'then
   local axis,k=string.match(key,'^in:(%d):(%a+)$');axis=tonumber(axis);local d=inputs[axis];if not d then return end
   if k=='rate'then d.rate=(d.rate<0 and -1 or 1)*math.floor(math.max(0,math.min(axis==3 and 500 or 200,v))*10+.5)
   else local raw=math.floor(math.max(0,math.min(axis==3 and 60 or 30,v))*1000/(axis==3 and 24 or 12)+.5);d[k]=k=='min'and -raw or raw end
   if (axis==1 or axis==2)and k=='max'then d.min=-d.max end
   editedInput[axis]=true;changed()
  elseif key=='allRate'then
   for i=0,2 do local d=draft[i].rate;if v<d.min or v>d.max then state='RATE OUT OF RANGE';return end end
   confirm('rate',v)
  elseif key=='pwm'then
   if active~=sel or not pwmConfig then return end
   -- Inverse of flight/servos.c: offset / side scale, reverse, inverse geometry.
   local delta=v-pwmConfig.mid.value
   local scale=delta<0 and pwmConfig.scaleNeg.value or pwmConfig.scalePos.value
   if scale<=0 then state='INVALID FC SERVO SCALE';return end
   local pos=delta/scale
   if bit32.band(pwmConfig.flags.value,1)~=0 then pos=-pos end
   if bit32.band(pwmConfig.flags.value,2)~=0 then pos=math.sin(pos/1.14591559026)/0.7660444431 end
   local target=pos*50
   if target < -90.001 or target > 90.001 then state='PWM OUTSIDE OVERRIDE RANGE';return end
   M.commit('angle',math.max(-90,math.min(90,target)))
  elseif key=='angle'then
   if active~=sel then return end
   angle=v;nextAngle=v;flushOverride()
  else
   local d=draft[sel][key];if not d then return end
   if key=='min'and v>=draft[sel].max.value or key=='max'and v<=draft[sel].min.value then state='MIN MUST BE LESS THAN MAX';return end
   d.value=math.max(d.min,math.min(d.max,v));editedServo[sel]=true;changed()
  end
 end
 local function startOverride(i)
  if dirty then state='APPLY & SAVE BEFORE SERVO TEST';return end
  stop(function()disarmed(function()
   active=i;angle=0
   h.override(i,0,true,function()enabled[i]=true;state='OVERRIDE ACTIVE';readPWM()end,
    function()stop(function()failed('OVERRIDE FAILED / STOPPED')end)end)
  end)end)
 end
 local function startAll()
  if dirty then state='APPLY & SAVE BEFORE TRIM TEST';return end
  if allMode then state='OVERRIDE ALL ALREADY ON';return end
  stop(function()disarmed(function()
   local function enable(i)
    if i==3 then allMode=true;active=sel;angle=0;state='OVERRIDE ALL ON - SELECT SERVO';readPWM();return end
    h.override(i,0,true,function()enabled[i]=true;anglesByServo[i]=0;enable(i+1)end,
     function()stop(function()failed('ALL ENABLE FAILED / STOPPED')end)end)
   end
   enable(0)
  end)end)
 end
 local function pickTrim(i)
  if not enabled[i]then state='TURN S'..(i+1)..' OVERRIDE ON FIRST';return false end
  epoch=epoch+1;nextAngle=nil;trimDrag=nil;rulerEdit=false
  sel=i;active=i;angle=anglesByServo[i]or 0;pwmConfig=nil
  return true
 end
 local function toggleServo(i)
  if enabled[i]then
   epoch=epoch+1;nextAngle=nil;trimDrag=nil;rulerEdit=false;busy=true
   h.override(i,0,false,function()
    enabled[i]=nil;anglesByServo[i]=nil;allMode=false;busy=false
    if active==i then active=nil;for j=0,2 do if enabled[j]then active=j;break end end end
    if active~=nil then sel=active;angle=anglesByServo[active]or 0 else angle=0 end
    state='S'..(i+1)..' OVERRIDE OFF'
   end,function()stop(function()failed('DISABLE FAILED / ALL STOPPED')end)end)
   return
  end
  if dirty then state='APPLY & SAVE BEFORE SERVO TEST';return end
  if active==nil or mixTest then sel=i;startOverride(i);return end
  disarmed(function()
   h.override(i,0,true,function()
    enabled[i]=true;anglesByServo[i]=0;allMode=enabled[0]and enabled[1]and enabled[2]or false
    busy=false;pickTrim(i);state='S'..(i+1)..' OVERRIDE ON';lastPwmPoll=-1000
   end,function()stop(function()failed('ENABLE FAILED / ALL STOPPED')end)end)
  end)
 end
 local function trimValue(v)
  if busy or modal or not enabled[sel]then return end
  v=math.max(-90,math.min(90,math.floor(v+.5)))
  if v==angle then return end
  active=sel;M.commit('angle',v)
  local now=getTime and getTime()or 0
  if now-feedbackAt>=6 then
   feedbackAt=now
   -- EdgeTX duration is milliseconds. Do not queue feedback faster than 60 ms.
   if type(playTone)=='function'then pcall(playTone,1800,12,0)end
   if type(playHaptic)=='function'then pcall(playHaptic,12,0)end
  end
 end
 local function modalYes()
  local c=modal;modal=nil
  if c.kind=='preset'then
   local first,last=0,2;if step==7 then first=3;last=3 end
   for i=first,last do draft[i].mid.value=c.value;draft[i].min.value=c.value==760 and -350 or -700;draft[i].max.value=c.value==760 and 350 or 700;editedServo[i]=true end
   changed()
  elseif c.kind=='save'then save()
  elseif c.kind=='leave'then leave()
  elseif c.kind=='reload'then stop(read)
  elseif c.kind=='rate'then
   for i=0,2 do draft[i].rate.value=c.value;editedServo[i]=true end
   changed()
  elseif c.kind=='center'then
   draft[sel].mid.value=c.value
   editedServo[sel]=true
   if allMode then changed();state='CENTER '..c.value..' / DRAFT - ALL ON'
   else stop(function()changed();state='CENTER '..c.value..' / DRAFT'end)end
  elseif c.kind=='override'then startOverride(c.value)end
 end
 local function moveStep(n)
  stop(function()step=math.max(1,math.min(7,n));details=false;focus=1;sel=step==7 and 3 or 0;state=dirty and'DRAFT / APPLY BEFORE TEST'or'FC VALUES'end)
 end
 local function testMixer(axis,value)
  if dirty then state='APPLY & SAVE BEFORE MIXER TEST';return end
  if step==7 and mix.tail_rotor_mode.value~=0 then state='MOTORIZED TAIL: USE FULL SETUP';return end
  stop(function()disarmed(function()
   local function send(i)
    if i>4 then mixTest=true;testAxis=axis;testValue=value;busy=false;state='MIXER TEST ON / ALL OFF TO RELEASE';return end
    local p={i};rf2.mspHelper.writeU16(p,i==axis and value or 0)
    queue(191,p,function()send(i+1)end,function()stop(function()failed('MIXER TEST FAILED / STOPPED')end)end)
   end
   send(1)
  end)end)
 end
 function M.activate(a)
  local key=a.key
  if busy then return end
  if modal then
   if key=='yes'then modalYes()elseif key=='no'then modal=nil end
   return
  end
  if key=='back'then M.back();return end
  if key=='close'then M.back();return end
  if key=='off'then if h.ready()then stop(function()state='ALL OVERRIDES OFF'end)end;return end
  if key=='reload'then if not h.ready()then state='FC NOT READY';return end;if dirty then confirm('reload')else stop(read)end;return end
  if not ready then return end
  if key=='toggleServo'then toggleServo(a.index)
  elseif key=='trim'then pickTrim(a.index)
  elseif key=='trimUp'then trimValue(angle+1)
  elseif key=='trimDown'then trimValue(angle-1)
  elseif key=='trimRuler'then if enabled[sel]then rulerEdit=not rulerEdit else state='ENABLE OVERRIDE FIRST'end
  elseif key=='prev'or key=='next'then return
  elseif key=='tailPage'then tailPage=tailPage==1 and 2 or 1;focus=1
  elseif key=='direction'then
   local axis=a.index;local d=inputs[axis]
   if d.rate==0 then state='SET NONZERO CALIBRATION FIRST';return end
   stop(function()d.rate=-d.rate;editedInput[axis]=true;changed()end)
  elseif key=='input'then
   local axis,k=string.match(a.index,'^(%d):(%a+)$');axis=tonumber(axis);local d=inputs[axis]
   local value=k=='rate'and math.abs(d.rate)/10 or math.abs(d[k])*(axis==3 and 24 or 12)/1000
   local max=k=='rate'and(axis==3 and 500 or 200)or(axis==3 and 60 or 30)
   stop(function()h.number('in:'..a.index,value,0,max)end)
  elseif key=='config'then
   local d=mix[a.index];local scale=a.index=='swash_pitch_limit'and 1000/12 or a.index=='swash_geo_correction'and 5 or 10
   stop(function()h.number('cfg:'..a.index,d.value/scale,d.min/scale,d.max/scale)end)
  elseif key=='test'then
   local axis,value=string.match(a.index,'^(%d):([%-%.%d]+)$');testMixer(tonumber(axis),tonumber(value))
  elseif key=='select'or key=='openOverride'then
   sel=a.index;details=true;overrideView=true;focus=1
   pwmConfig=nil
   if dirty and not allMode then overrideView=false;return end
   if allMode then epoch=epoch+1;nextAngle=nil;active=sel;angle=anglesByServo[sel]or 0
   elseif active~=sel then startOverride(sel)end
  elseif key=='settings'then overrideView=not overrideView;focus=1
  elseif key=='allOn'then startAll()
  elseif key=='fullOverride'then stop(function()state='FC VALUES / DRAFT RETAINED';h.fullOverride()end)
  elseif key=='override'then
   if active==a.index then stop(function()state='OVERRIDE OFF'end)
   else sel=a.index;details=true;confirm('override',a.index)end
  elseif key=='swash'then
   local items={};for i,v in ipairs(names)do items[i]={v,i-1}end
   stop(function()h.choice('SWASH TYPE',items,mix.swash_type.value+1,function(v)mix.swash_type.value=v;editedMix.swash_type=true;changed()end)end)
  elseif key=='front'then front=not front
  elseif key=='servoSelect'then
   if step==7 and(not draft[3]or mix.tail_rotor_mode.value~=0)then state='NO VARIABLE TAIL SERVO';return end
   stop(function()h.choice(step==7 and'TAIL S4 PULSE'or'SERVO PULSE WIDTH',{{'1520 us',1520},{'760 us',760}},draft[sel].mid.value<1000 and 2 or 1,function(v)confirm('preset',v)end)end)
  elseif key=='allRate'then
   local low,high=draft[0].rate.min,draft[0].rate.max
   for i=1,2 do low=math.max(low,draft[i].rate.min);high=math.min(high,draft[i].rate.max)end
   stop(function()h.number('allRate',draft[sel].rate.value,low,high)end)
  elseif key=='preset'then
   stop(function()confirm('preset',a.index)end)
  elseif key=='reverse'or key=='geo'then
   local mask=key=='reverse'and 1 or 2
   local si=a.index~=nil and a.index or sel
   draft[si].flags.value=bit32.bxor(draft[si].flags.value,mask);editedServo[si]=true;changed()
  elseif key=='save'then stop(function()confirm('save')end)
  elseif key=='angle'then if active==sel then h.number('angle',angle,-90,90)else state='ENABLE OVERRIDE FIRST'end
  elseif key=='pwm'then
   if active~=sel then state='ENABLE OVERRIDE FIRST';return end
   busy=true;state='READING FC PWM LIMITS...'
   h.servos().getServoConfigurations(function(_,data)
    if not data[sel]then failed('SERVO READ FAILED');return end
    pwmConfig=copy(data[sel]);local d=pwmConfig
    local low=d.mid.value+math.max(d.min.value,-1.8*d.scaleNeg.value)
    local high=d.mid.value+math.min(d.max.value,1.8*d.scalePos.value)
    readPWM(function()h.number('pwm',pwm[sel],math.ceil(low),math.floor(high))end)
   end,nil,function()failed('SERVO READ FAILED')end)
  elseif key=='up'or key=='down'then if active==sel then M.commit('angle',math.max(-90,math.min(90,angle+(key=='up'and 1 or -1))))else state='ENABLE OVERRIDE FIRST'end
  elseif key=='center'then
   if active~=sel then state='ENABLE OVERRIDE FIRST';return end
   state='READING ACTUAL PWM...'
   readPWM(function()
    local value=pwm[sel];local d=draft[sel].mid
    if value<d.min or value>d.max then state='PWM OUT OF CENTER RANGE';return end
    confirm('center',value)
   end)
  elseif draft[sel][key]then local d=draft[sel][key];h.number(key,d.value,d.min,d.max)end
 end
 local function btn(label,x,y,w,ht,key,index,accent)
  local n=#controls+1;local action={kind='easyServo',key=key,index=index}
  controls[n]=action;h.button('es'..n,label,x,y,w,ht,focus==n,action,accent or'cyan')
 end
 local function drawModal()
  local c=modal;h.clearHits();controls={}
  h.fill(78,99,644,298,'panel');h.box(78,99,644,298,'orange')
  local title,line1,line2,line3='CONFIRM','','',''
  if c.kind=='preset'then title='SERVO SELECT - IS THIS CORRECT?';line1=(step==7 and'Replace S4'or'Replace S1-S3')..' Center / Min / Max. Rate stays unchanged.';line2=c.value==760 and'Center 760 us   Min -350   Max +350'or'Center 1520 us   Min -700   Max +700';line3='YES changes draft. APPLY & SAVE before testing motion.'
  elseif c.kind=='save'then title='REVIEW / APPLY & SAVE';line1='Swash: '..names[mix.swash_type.value+1];line2='Apply pending servo/swash edits, save, then read back.';line3='DISARM. Verify Center, direction and servo specifications.'
  elseif c.kind=='override'then title='MOVE SERVO '..(c.value+1)..'?';line1='Disconnect motor power and remove blades.';line2='One servo moves using the CURRENT FC settings.';line3='Unsaved draft values are not used for this test.'
  elseif c.kind=='center'then title='SET SERVO '..(sel+1)..' CENTER?';line1='Actual output: '..c.value..' us';line2='Center: '..draft[sel].mid.value..' -> '..c.value..' us';line3=allMode and'Draft center only. ALL stays ON until ALL OFF / exit.'or'Set draft center and stop override. Save on final review.'
  elseif c.kind=='rate'then title='SET SERVO 1-3 RATE?';line1='S1 '..draft[0].rate.value..' / S2 '..draft[1].rate.value..' / S3 '..draft[2].rate.value..' Hz';line2='New draft rate for Servo 1-3: '..c.value..' Hz';line3='Use a rate supported by your servos. FC is not written.'
  else title=c.kind=='leave'and'DISCARD UNSAVED CHANGES?'or'RELOAD AND DISCARD DRAFT?';line1='Unsaved servo and swash changes will be discarded.';line2='Overrides will be stopped before continuing.'end
  h.txt(99,119,title,'orange',true);h.txt(99,159,line1,'text');h.txt(99,187,line2,'text');h.txt(99,215,line3,'muted')
  if c.kind=='save'then
   for i=0,3 do local d=draft[i];if d then h.txt(99,240+i*21,string.format('S%d  C %d   %d / %d   %d Hz   REV %s',i+1,d.mid.value,d.min.value,d.max.value,d.rate.value,bit32.band(d.flags.value,1)~=0 and'ON'or'OFF'),'cyan')end end
  end
  focus=c.yes and 2 or 1
  btn('NO / CANCEL',120,337,236,42,'no');btn(c.kind=='save'and'APPLY & SAVE'or'YES / CONTINUE',410,337,266,42,'yes',nil,'orange')
 end
 local function drawDetails()
  h.clearHits();controls={}
  h.fill(88,98,624,332,'panel');h.box(88,98,624,332,'cyan')
  local d=draft[sel]
  if not overrideView then
   h.txt(113,112,'SERVO '..(sel+1)..(sel==3 and' / TAIL'or(sel==0 and' / ELEVATOR'or' / CYCLIC')),'cyan',true)
   h.txt(113,141,allMode and'OVERRIDE ALL ON / edits below are draft only'or(active==sel and'OVERRIDE ON / edits below are draft only'or'OVERRIDE OFF / draft only'),'orange')
   local rows={{'CENTER [us]','mid'},{'RATE [Hz]','rate'},{'MIN','min'},{'MAX','max'},{'REVERSE','reverse'},{'GEO CORR','geo'}}
   for j,r in ipairs(rows)do
    local x=(j%2==1)and 113 or 414;local y=183+math.floor((j-1)/2)*51
    h.txt(x,y+8,r[1],'text');local v
    if r[2]=='reverse'or r[2]=='geo'then v=bit32.band(d.flags.value,r[2]=='reverse'and 1 or 2)~=0 and'ON'or'OFF'else v=tostring(d[r[2]].value)end
    btn(v,x+136,y,138,33,r[2])
   end
   btn('OVERRIDE / PWM',113,382,250,34,'settings',nil,'orange')
   btn('CLOSE',474,382,213,34,'close',nil,'cyan')
   return
  end
  h.txt(113,112,'#'..(sel+1)..' S'..(sel+1),'cyan',true)
  h.txt(113,145,allMode and'ALL ON / EDIT SELECTED SERVO'or'SERVO OVERRIDE / ONE SERVO ONLY','orange',true)
  btn('SERVO SETTINGS',430,177,257,34,'settings')
  h.txt(113,187,'UP / DOWN or tap PWM.','text')
  h.txt(113,215,'Testing uses the current FC settings, not unsaved draft.','muted')
  h.txt(113,244,allMode and'Close keeps ALL ON. Use ALL OFF or exit setup to release.'or'Closing this window returns to neutral and disables Override.','muted')
  btn(allMode and'ALL OFF'or(active==sel and'OVERRIDE ON'or'OVERRIDE OFF'),113,286,210,33,'override',sel,'orange')
  btn(string.format('TEST %.1f deg',angle),430,286,257,33,'angle',nil,'orange')
  btn('',113,324,108,30,'up',nil,'orange')
  for row=0,15 do h.fill(167-row,331+row,row*2+1,1,'orange')end
  local fresh=pwm[sel]and(getTime and getTime()or 0)-(pwmAt[sel]or-1000)<150
  btn('PWM '..(fresh and tostring(pwm[sel])or'--'),113,355,108,34,'pwm',nil,'orange')
  btn('',113,390,108,30,'down',nil,'orange')
  for row=0,15 do h.fill(167-row,413-row,row*2+1,1,'orange')end
  h.txt(237,335,'CENTER [us]','cyan')
  btn(tostring(d.mid.value),237,355,175,34,'mid',nil,'green')
  h.txt(237,402,'UP +1 / DOWN -1','muted')
  h.txt(430,331,'Actual PWM -> draft center','muted')
  btn('SET CENTER',430,355,257,34,'center',nil,'green')
  btn(allMode and'CLOSE / KEEP ON'or'CLOSE / STOP',474,390,213,30,'close',nil,'cyan')
 end

 local function inputText(axis,key)
  local d=inputs[axis];if not d then return '--'end
  if key=='rate'then return string.format('%.1f %%',math.abs(d.rate)/10)end
  return string.format('%.1f deg',math.abs(d[key])*(axis==3 and 24 or 12)/1000)
 end
 local function row(n,label,value,key,index)
  local y=166+(n-1)*45
  h.txt(400,y+3,label,'text')
  btn(value,605,y-1,175,34,key,index)
 end
 local function diagram()
  h.fill(20,160,360,190,'panel');h.txt(30,165,'HELI FRONT ^','cyan')
  local cx,cy,r=196,257,52
  for n=0,47 do local a=n*math.pi/24;local b=(n+1)*math.pi/24;h.line(cx+r*math.cos(a),cy+r*math.sin(a),cx+r*math.cos(b),cy+r*math.sin(b),'cyan')end
  local aa=front and{-90,30,150}or{90,210,330}
  for i=0,2 do local a=aa[i+1]*math.pi/180;h.line(cx,cy,cx+r*math.cos(a),cy+r*math.sin(a),(allMode or active==i)and'orange'or'cyan')end
  local pos=front and{{155,189},{257,264},{31,264}}or{{155,297},{31,195},{257,195}}
  for i=0,2 do local x,y=pos[i+1][1],pos[i+1][2];local d=draft[i]
   if step==3 then btn('S'..(i+1)..' REV '..(bit32.band(d.flags.value,1)~=0 and'ON'or'OFF'),x,y,112,28,'reverse',i)
   elseif step==4 then btn('S'..(i+1)..' TRIM',x,y,112,28,'select',i)
   else h.fill(x,y,112,40,'panel');h.txt(x,y,'S'..(i+1)..' C '..d.mid.value,'cyan')end
   if step==3 or step==4 then h.txt(x,y+30,'C '..d.mid.value..' us','green')
   else local fresh=pwm[i]and(getTime and getTime()or 0)-(pwmAt[i]or-1000)<150;h.txt(x,y+19,'PWM '..(fresh and pwm[i]or'--'),'muted')end
  end
 end
 local function tests(axis)
  local d=inputs[axis]
  btn('TEST -',400,355,120,35,'test',axis..':'..d.min,'orange')
  btn('ZERO',530,355,120,35,'test',axis..':0','orange')
  btn('TEST +',660,355,120,35,'test',axis..':'..d.max,'orange')
 end
 local function drawTouchSetup()
  h.fill(20,102,598,300,'panel')
  local cx,cy,r=125,155,46
  for n=0,47 do local a=n*math.pi/24;local b=(n+1)*math.pi/24;h.line(cx+r*math.cos(a),cy+r*math.sin(a),cx+r*math.cos(b),cy+r*math.sin(b),'muted')end
  local arms=front and{-90,30,150}or{90,210,330}
  for i=0,2 do
   local a=arms[i+1]*math.pi/180;local x,y=cx+r*math.cos(a),cy+r*math.sin(a)
   h.line(cx,cy,x,y,'cyan')
   local c=enabled[i]and(sel==i and'orange'or'green')or'muted'
   for dy=-6,6 do local dx=math.floor(math.sqrt(36-dy*dy));h.fill(x-dx,y+dy,dx*2+1,1,c)end
   h.txt(x+(math.cos(a)<-.2 and -30 or 12),y-8,'S'..(i+1),c)
  end
  btn(front and'ELEVATOR FRONT'or'ELEVATOR REAR',20,219,210,32,'front')
  h.txt(250,106,'SWASHPLATE TYPE','muted')
  btn(names[mix.swash_type.value+1],250,127,360,34,'swash')
  h.txt(250,174,'SERVO PULSE WIDTH','muted')
  local pulse=draft[0].mid.value
  local same=pulse==draft[1].mid.value and pulse==draft[2].mid.value
  btn(same and(pulse..' us')or'MIXED',250,195,360,34,'servoSelect')
  h.txt(250,240,'Pulse selection -> S1 / S2 / S3 Center','muted')
  local xs={145,302,459}
  for i=0,2 do h.txt(xs[i+1]+54,259,'S'..(i+1),'cyan',true)end
  h.txt(25,287,'OVERRIDE','muted');h.txt(25,323,'DIRECTION','muted');h.txt(25,359,'TRIM','muted');h.txt(25,388,'CENTER us','muted')
  for i=0,2 do local x=xs[i+1];local d=draft[i]
   btn(enabled[i]and'ON'or'OFF',x,280,145,32,'toggleServo',i,enabled[i]and'orange'or'cyan')
   btn(bit32.band(d.flags.value,1)~=0 and'Reverse'or'Normal',x,316,145,32,'reverse',i)
   btn(tostring(enabled[i]and(sel==i and angle or anglesByServo[i]or 0)or 0),x,352,145,32,'trim',i,enabled[i]and'orange'or'muted')
   h.txt(x+35,388,d.mid.value..' us','cyan')
  end
  h.fill(632,102,148,300,'panel2');h.box(632,102,148,300,'cyan')
  h.txt(650,111,'S'..(sel+1)..' TRIM','cyan',true)
  h.txt(686,136,enabled[sel]and tostring(angle)or'0',enabled[sel]and'orange'or'muted',true)
  local fresh=pwm[sel]and(getTime and getTime()or 0)-(pwmAt[sel]or-1000)<150
  h.txt(643,161,'PWM '..(fresh and pwm[sel]or'--')..' us','muted')
  btn('+1  UP',644,184,124,28,'trimUp',nil,enabled[sel]and'orange'or'muted')
  btn('',644,218,124,135,'trimRuler',nil,rulerEdit and'orange'or'cyan')
  local v=math.floor(angle+.5)
  for k=-7,7 do local y=285-k*9;local val=v+k
   if val>=-90 and val<=90 then h.fill(val%5==0 and 711 or 733,y,val%5==0 and 50 or 28,1,'muted');if val%5==0 then h.txt(652,y-7,tostring(val),'text')end end
  end
  h.fill(645,285,122,2,enabled[sel]and'orange'or'muted')
  btn('-1  DOWN',644,365,124,28,'trimDown',nil,enabled[sel]and'orange'or'muted')
 end
 function M.draw()
  controls={};h.header('SERVO / SWASH SETUP',busy and'WAIT...'or(dirty and'DRAFT'or'FC VALUES'))
  h.txt(20,84,state,'orange')
  if ready then drawTouchSetup()else h.txt(30,170,'Connect FC, then RELOAD.','text')end
  btn(allMode and'ALL ON / S1-S3'or'OVERRIDE ALL ON',20,410,190,32,'allOn',nil,'orange')
  btn('ALL OFF',220,410,115,32,'off',nil,'orange')
  btn('APPLY & SAVE',345,410,200,32,'save',nil,'orange')
  btn('RELOAD',555,410,110,32,'reload')
  btn('< MENU',675,410,105,32,'back')
  h.footer('Trim = temporary Override (1 deg). Center = draft us. Motor unplugged.')
  if modal then drawModal()end
 end
 function M.event(e,touch)
  if type(touch)=='table'and not details and not modal and(step==1 or step==3 or step==4)then
   local x,y=h.coords(touch.x,touch.y)
   if EVT_TOUCH_FIRST and e==EVT_TOUCH_FIRST and x>=644 and x<=768 and y>=218 and y<=353 then
    if not busy and enabled[sel]then trimDrag={y=y,value=angle,index=sel};rulerEdit=false else state='ENABLE OVERRIDE FIRST'end
    return 0
   elseif trimDrag and((EVT_TOUCH_SLIDE and e==EVT_TOUCH_SLIDE)or(EVT_TOUCH_BREAK and e==EVT_TOUCH_BREAK))then
    if not busy and enabled[trimDrag.index]and sel==trimDrag.index then trimValue(trimDrag.value+(trimDrag.y-y)/9)end
    if EVT_TOUCH_BREAK and e==EVT_TOUCH_BREAK then trimDrag=nil end
    return 0
   elseif EVT_TOUCH_TAP and e==EVT_TOUCH_TAP and x>=644 and x<=768 and y>=218 and y<=353 then return 0 end
  end
  if rulerEdit and not modal then
   if e==EVT_VIRTUAL_EXIT or e==EVT_VIRTUAL_ENTER then rulerEdit=false;return 0 end
   if e==EVT_VIRTUAL_NEXT or e==EVT_VIRTUAL_PREV then trimValue(angle+(e==EVT_VIRTUAL_NEXT and 1 or -1));return 0 end
  end
  if e==EVT_VIRTUAL_EXIT then M.back();return 0 end
  if busy then return 0 end
  if e==EVT_VIRTUAL_NEXT or e==EVT_VIRTUAL_PREV then
   if modal then modal.yes=not modal.yes elseif #controls>0 then focus=(focus-1+(e==EVT_VIRTUAL_NEXT and 1 or -1))%#controls+1 end
   return 0
  elseif e==EVT_VIRTUAL_ENTER then if modal then if modal.yes then modalYes()else modal=nil end elseif controls[focus]then M.activate(controls[focus])end;return 0 end
  return e
 end
 function M.tick()
  flushOverride()
  if not ready or busy or pollPending or overridePending or not rf2.mspQueue:isProcessed()then return end
  local now=getTime and getTime()or 0
  if (active==nil and not mixTest)or now-lastPoll<50 then
   if now-lastPwmPoll>=20 then readPWM(nil,true)end
   return
  end
  lastPoll=now
  pollPending=true;local token=epoch
  queue(101,nil,function(_,b)
   pollPending=false;if token~=epoch then return end
   if #b<10 or b[7]%2~=0 then stop(function()failed('OVERRIDE STOPPED / CHECK DISARM')end)else flushOverride()end
  end,function()pollPending=false;if token==epoch then stop(function()failed('LINK ERROR / OVERRIDE STOPPED')end)end end)
 end
 return M
end
