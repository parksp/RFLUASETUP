;(function()
 local oldBit32=bit32
 local function signed32(n)n=n%4294967296;if n>=2147483648 then n=n-4294967296 end;return math.floor(n)end
 -- Fengari integers are 32-bit; emulate EdgeTX bit32's accepted unsigned inputs.
 bit32={band=function(a,b)return oldBit32.band(signed32(a),signed32(b))end,
  bor=function(a,b)return oldBit32.bor(signed32(a),signed32(b))end,
  bxor=function(a,b)return oldBit32.bxor(signed32(a),signed32(b))end,
  lshift=function(a,b)return oldBit32.lshift(signed32(a),b)end,
  rshift=function(a,b)return oldBit32.rshift(signed32(a),b)end,
  btest=function(a,b)return oldBit32.band(signed32(a),signed32(b))~=0 end}
 local originalProcess=Q.processQueue
 local wireFeature=2^31+2^10+2^3
 local crsf={mode=1,rate=250,ratio=8,sensors={3,4,5,6,60,95}}
 local readFail,writeFail,shortRead=false,false,false
 Q.processQueue=function(self)
  local m=self.items[1]
  if m and(m.command==36 or m.command==37)then
   table.remove(self.items,1);table.insert(self.log,{command=m.command,payload=m.payload})
   if m.command==36 then
    if readFail then if m.errorHandler then m.errorHandler()end;return end
    local b={};helper.writeU32(b,wireFeature);if shortRead then b={1,2}end;b.offset=1
    if m.processReply then m.processReply(m,b)end
   else
    if writeFail then if m.errorHandler then m.errorHandler()end;return end
    local p=m.payload;wireFeature=p[1]+p[2]*256+p[3]*65536+p[4]*16777216.0
    if m.processReply then m.processReply(m,{})end
   end
  else originalProcess(self)end
 end
 testMotor.write=function(c)Q:add({command=222,payload={c.poles[1]}})end
 testEsc.write=function(c)Q:add({command=216,payload={c.protocol.value or 0}})end
 if rfGearSetup then rfGearSetup.active=false end
 requestMotor();pump()
 motorFeature={bitfield=0};rfRpmSensor=false;rfMotorRpmDirty=false;rfMotorEscDirty=false
 local features,esc,rx,telem=count(37),count(216),count(45),count(74);local saved=count(250)
 local old=wireFeature
 saveMotor();pump()
 assert(wireFeature==old,'REGRESSION: motor-only SAVE overwrote live RX/telemetry FEATURE bits from stale cache')
 assert(count(37)==features and count(216)==esc,'motor-only save sent unrelated FEATURE/ESC writes')
 assert(count(250)==saved+1)
 applyMotorLive();pump();assert(count(37)==features and wireFeature==old,'live motor edit touched shared features')
 -- Explicit RPM-sensor change merges only bit30 into a fresh FC feature read.
 rfRpmSensor=true;rfMotorRpmDirty=true;motorFeature={bitfield=0};saved=count(250)
 saveMotor();pump();assert(wireFeature==old+2^30,'RPM enable lost other live feature bits')
 assert(not rfMotorRpmDirty and count(250)==saved+1)
 wireFeature=2^31+2^30+2^14+2^10;motorFeature={bitfield=0};rfRpmSensor=false;rfMotorRpmDirty=true
 saveMotor();pump();assert(wireFeature==2^31+2^14+2^10,'RPM disable overwrote telemetry or unrelated feature bits')
 -- Failed, short, and rejected feature operations block EEPROM and motor writes.
 for _,mode in ipairs({'read','short','write'})do
  readFail=mode=='read';shortRead=mode=='short';writeFail=mode=='write'
  local beforeSave,beforeMotor=count(250),count(222)
  rfRpmSensor=true;rfMotorRpmDirty=true;saveMotor();pump()
  assert(count(250)==beforeSave and count(222)==beforeMotor and not rfMotorSaving,'feature failure allowed incomplete save')
 end
 readFail=false;shortRead=false;writeFail=false;saveMotor();pump()
 assert(not rfMotorRpmDirty)
 esc=count(216);rfMotorEscDirty=true;saveMotor();pump();assert(count(216)==esc+1 and not rfMotorEscDirty,'explicit ESC edit not saved')
 assert(count(45)==rx and count(74)==telem,'motor path wrote receiver or CRSF configuration')
 assert(crsf.mode==1 and crsf.rate==250 and crsf.ratio==8 and #crsf.sensors==6)
 Q.processQueue=originalProcess
 bit32=oldBit32
 print('PASS: stale feature-cache reproduction, motor-only isolation, fresh RPM bit30 merge, telemetry bit10/high-bit preservation, read/write failure guards; no RX/CRSF writes')
end)()
