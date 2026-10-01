-- RF SETUP HELI 0.2.0 - reviewed UI shell for TX16S / EdgeTX
local VERSION="0.6.91 BETA"
local page="home"
local selected=1
local scroll=1
local help=false
local touchDown=nil
local pageSwipe=nil
local swipeMomentum=0
local swipeNext=0
local numEdit=nil
local activationSource='touch';rfChoiceTouchGuard=0;rfModalTouchAction=nil
local numFocus=1
local lastTouchId,lastTouchAt=nil,-1000
local servoSelectedId=nil;local mixerSelectedId=nil;local mixerNav=1;local mixerScroll=1;local mixerCursor=2;local mixerRowCount=1
local W,H=800,480
local hit={}
local saveMode=1
local armedLock=true
setupSel=1;setupConfirm=nil;setupState='READY';easyMenuFocus=1;easyBoardFocus=1;easyFocus=1;easyState='READ FC';easyDraft={roll=0,pitch=0,yaw=0};easyDirty=false;easyFlip=false;easyFacing=0;easyConfirm=false;easyTrimFocus=1;easyTrimDraft={roll=0,pitch=0};easyTrimDirty=false;easyTrimConfirm=false;easyRxFocus=1;easyRxScroll=1;easyRxState='READ ONLY';easyCalConfirm=false;easyCalState='READY'
cfgSel=2;cfgScroll=1;cfgState='NOT READ';cfgSaveConfirm=false;cfgSerialUnlocked=false;cfgSerialConfirm=false;cfgPortEdit=nil;cfgNameEdit=nil;cfgNameFocus=1;attitudeBackPage='status';cfgName='';cfgPilot=nil;cfgStats=nil;cfgAcc=nil;cfgFeature=0;cfgAdvanced={gyro=1,pid=1};cfgSensor={acc=0,baro=0,mag=0,gyro=0,fsr=0,move=0,duration=0,yaw=0,overflow=0};cfgAlign={roll=0,pitch=0,yaw=0};cfgSensorAlign={gyro1=0,gyro2=0,mag=0};cfgPorts={}
homeHw={sensors=0,flashSupported=false,flashReady=false,flashTotal=0,flashUsed=0};homeHwAt=-1000;homeHwBusy=false;homeFlashHoldAt=nil;homeFlashHolding=false;homeFlashConfirm=false;homeFlashState='';statusRxScroll=1;statusYawOffset=0;statusInstrument=1;statusLive={state='WAITING FC',roll=0,pitch=0,yaw=0,rx={1500,1500,1500,1500,1000,1500,1500,1500,1500,1500,1500,1500,1500,1500,1500,1500},voltage=0,current=0,mah=0,rssi=0,cpu=0,load=0,flags=0,profile=0,motors=0};statusLiveAt=-1000;statusLiveBusy=false;statusFastAt=-1000;statusFastBusy=false;statusFastPhase=0;statusLivePhase=0

local rfReady,pidApi,statusApi,servoApi,mixerApi,motorApi,featureApi=false,nil,nil,nil,nil,nil,nil;dataflashApi=nil
nameApi=nil;pilotApi=nil;statsApi=nil;accTrimApi=nil
escSensorApi=nil;govApi=nil;govConfig=nil;govState='NOT READ';govDirty=false;govTab=1;govFocus=1;govScroll=1;govExpert=false;govVisibleTabs={1};govRxMin=1000;govRxMax=2000;govRcCenter=1500;govRcDeflection=500;govRcLow=0;govRcHigh=0;govRcMap={0,1,2,3,4,5,6,7};govThrottlePwm=1000;govRxAt=-1000;govCurvePoints=9;govThrottleCommand=0;govCurveDrag=nil;govCurveEdit=false;govCurveCurrent=0;govLiveReadAt=-1000;govLiveReadBusy=false
local mixerConfig=nil;local mixerState='NOT READ';local swashSelect=nil;local choiceSelect=nil;local swashNames={[0]='None','Direct','CCPM 120 deg','CCPM 135 deg','CCPM 140 deg','FPM 90 deg L','FPM 90 deg V'}
local pidData,pidState,pidProfile={},"OFFLINE",0
local pidSel,pidEditing,pidDirty=1,false,false
local pidError=nil
local pidMap={0,1,2,3,12,4,5,6,7,13,8,9,10,11,14,15,16}
local function setPidState(v) pidState=v end
local function initRF()
 local ok,err=pcall(function()
  chdir('/SCRIPTS/RFLUASETUP');assert(loadScript('/SCRIPTS/RFLUASETUP/rf2.lua'))()
  rf2.radio=rf2.executeScript('radios');rf2.mspQueue=rf2.executeScript('MSP/mspQueue');rf2.mspHelper=rf2.executeScript('MSP/mspHelper')
  pidApi=rf2.useApi('mspPidTuning');statusApi=rf2.useApi('mspStatus');servoApi=rf2.useApi('mspServos');mixerApi=rf2.useApi('mspMixer');motorApi=rf2.useApi('mspMotorConfig');featureApi=rf2.useApi('mspFeatureConfig');nameApi=rf2.useApi('mspName');pilotApi=rf2.useApi('mspPilotConfig');statsApi=rf2.useApi('mspFlightStats');accTrimApi=rf2.useApi('mspAccTrim');escSensorApi=rf2.useApi('mspEscSensorConfig');govApi=rf2.useApi('mspGovernorConfig');dataflashApi=rf2.useApi('mspDataflash');pidData=pidApi.getDefaults();rfReady=true
 end)
 if not ok then pidError=tostring(err);pidState='START ERROR' end
end
local function pidLoaded(_,data) pidData=data;pidDirty=false;pidState='CONNECTED / READY' end
local function statusLoaded(_,st) pidProfile=st.profile or 0 end
local function requestPid()
 if not rfReady then return end
 pidState='READING FC...';statusApi.getStatus(statusLoaded,nil);pidApi.read(pidLoaded,nil,pidData)
end
local function savePid()
 if not rfReady or pidState=='SAVING...' then return end
 pidState='SAVING...';pidApi.write(pidData)
 if escSensorConfig then escSensorApi.write(escSensorConfig)end
 rf2.mspQueue:add({command=250,processReply=function()pidDirty=false;pidState='SAVED TO FC' end,errorHandler=function()pidState='APPLIED / SAVE AFTER DISARM';pidDirty=false end})
end
local function selectProfile()
 if not rfReady then return end
 local nextProfile=(pidProfile+1)%6;pidState='CHANGING PROFILE...'
 rf2.mspQueue:add({command=210,payload={nextProfile},processReply=function()pidProfile=nextProfile;requestPid()end,errorHandler=function()pidState='PROFILE CHANGE ERROR'end})
end
local function pidValue(sel)local k=pidMap[sel];return k and pidData[k] and pidData[k].value or nil end
local function changePid(delta)
 local k=pidMap[pidSel];if not k or not pidData[k] or pidData[k].value==nil then return end
 local d=pidData[k];d.value=math.max(d.min or 0,math.min(d.max or 1000,d.value+delta));pidDirty=true;pidState='CHANGED / NOT SAVED'
end


local C={bg={11,20,32},panel={22,34,50},panel2={31,47,67},line={52,72,94},text={235,242,248},muted={151,174,195},cyan={46,205,190},blue={48,116,180},orange={244,169,65},red={231,91,91},green={87,196,126},greenShade={28,67,53},purple={138,120,220},pid={75,52,91}}
local rgb={}
local function initColors() if lcd.RGB then for k,v in pairs(C) do rgb[k]=lcd.RGB(v[1],v[2],v[3]) end end end
initColors()
local function col(k) if lcd.setColor and CUSTOM_COLOR and rgb[k] then lcd.setColor(CUSTOM_COLOR,rgb[k]);return CUSTOM_COLOR end return 0 end
local function sx(v)return math.floor(v*(LCD_W or W)/W+.5)end
local function sy(v)return math.floor(v*(LCD_H or H)/H+.5)end
local function fill(x,y,w,h,c)if lcd.drawFilledRectangle then lcd.drawFilledRectangle(sx(x),sy(y),sx(w),sy(h),col(c))end end
local function box(x,y,w,h,c)if lcd.drawRectangle then lcd.drawRectangle(sx(x),sy(y),sx(w),sy(h),col(c))end end
local function txt(x,y,s,c,big,inv)local f=(big and 0 or (SMLSIZE or 0))+col(c or 'text');if inv and not CUSTOM_COLOR then f=f+(INVERS or 0)end;lcd.drawText(sx(x),sy(y),tostring(s or ''),f)end
local function add(id,x,y,w,h,action)hit[#hit+1]={id=id,x=sx(x),y=sy(y),w=sx(w),h=sy(h),action=action}end
local function button(id,label,x,y,w,h,focus,action,accent)
 focus=focus or(page=='mixer'and mixerSelectedId==id)or(page=='servos'and servoSelectedId==id);fill(x,y,w,h,focus and 'blue' or 'panel2');box(x,y,w,h,focus and (accent or 'cyan') or 'line');if focus then fill(x,y,5,h,accent or 'cyan')end
 txt(x+14,y+(h-18)/2,label,focus and 'text' or 'muted',false,focus);add(id,x,y,w,h,action)
end
local function header(title,status)
 lcd.clear();fill(0,0,800,480,'bg');fill(0,0,800,56,'panel');fill(0,0,6,56,'cyan')
 txt(20,13,"ROTORFLIGHT HELI SETUP",'text',true);fill(310,10,210,36,'bg');box(310,10,210,36,rfReady and'cyan'or'line');fill(321,22,10,10,rfReady and'green'or'red');txt(338,18,rfReady and'FC LINK'or'NO LINK',rfReady and'cyan'or'muted',true);fill(414,16,1,24,'line');txt(428,18,saveMode==2 and'AUTO'or'MANUAL',saveMode==2 and'green'or'orange',true);txt(625,18,status or 'PREVIEW','orange')
 txt(20,63,title,'cyan',true);button('help','?',744,62,36,34,false,{kind='help'})
end
advBackTarget='full'
local home={{'Full Setup','BETA TEST','full'},{'Easy Setup','FC ALIGNMENT','easy'},{'PROFILE FAST LINK','PID GAINS','profileGains'},{'RATES FAST LINK','RATE TABLE','rateTable'},{'Options','UNDER REPAIR','options'},{'Exit','CLOSE','exit'}}
local full={
 {'Status','Live FC, attitude, battery and receiver','status'},
 {'Setup','Calibration, save, reset and reboot tools','setup'},
 {'Configuration','Name, system, features, ports and alignment','configuration'},
 {'Receiver','Protocol, range, telemetry, channels and preview','receiver'},
 {'Failsafe','Pulse range and channel fallback','failsafe'},
 {'Power','Battery, SmartFuel, voltage and current meters','power'},
 {'Servos','Center, limits, rate, reverse and live output','servos'},
 {'Mixer','Swash type, directions, trims and tail','mixer'},
 {'Gyro','Expert lowpass, notch, dynamic and RPM filters','gyro'},
 {'Rates','Rates, dynamics and rate profiles','rates'},
 {'Profiles','PID, controller, rescue and governor profiles','profiles'},
 {'Modes','Flight modes, AUX ranges and linked modes','modes'},
 {'Adjustments','In-flight adjustment ranges','adjustments'},
 {'Beeper','Analog and DShot beeper conditions','beeper'},
 {'Sensors','Live gyro, accelerometer, altitude and debug','sensors'},
 {'Blackbox','Logging device, mode, rate, fields and storage','blackbox'},
 {'Motors','Throttle, ESC telemetry, RPM and live data','motors'},
 {'Governor','Mode, ramp, filters, bypass curve and monitor','governor'}
}
local screens={
 servos={title='SERVOS',note='All values are preview only',rows={{'Servo','Center','Min / Max','Rate','Reverse','Live PWM'},{'#1','1544','-700 / 700','333 Hz','Normal','1526 us'},{'#2','1500','-700 / 700','333 Hz','Normal','1482 us'},{'#3','1456','-700 / 700','333 Hz','Normal','1438 us'},{'#4 Tail','760','-350 / 350','500 Hz','Normal','788 us'}}},
 direction={title='DIRECTION CHECK',note='Move one control at a time. Remove motor power.',rows={{'Check','Command','Expected response'},{'Collective','Raise collective','Swash rises level'},{'Aileron','Move right','Swash commands right'},{'Elevator','Move forward','Swash commands forward'},{'Tail','Rudder right','Tail command right'},{'Gyro compensation','Tilt aircraft','Swash opposes movement'}}},
 mixer={title='MIXER',note='Rotorflight mixer values and exact swash labels',rows={{'Main rotor','CCPM 120 deg','CW','Aileron: Normal'},{'Swash choices','None / Direct / CCPM 120 / 135 / 140','FPM 90 L / V',''},{'Control direction','Elevator: Reverse','Collective: Normal','',''},{'Cyclic trims','Roll 0.0%','Pitch 0.0%','Collective 8.1%'},{'Tail rotor','Variable Pitch','Direction: Normal','Center trim 1.5'},{'Mixer override','OFF','Passthrough: OFF','Temporary'}}},
 geometry={title='GEOMETRY & OVERRIDE',note='Set override angle, measure blade angle, then enter result.',rows={{'Measurement','Override angle','Measured value','Calibration'},{'Cyclic','-18 ... +18 deg','0.0 deg','78.0%'},{'Collective','-18 ... +18 deg','0.0 deg','92.1%'},{'Collective geometry','-18 ... +18 deg','0.0 deg','-5.2%'},{'Pitch limits','-15 / +15 deg','Total 0 deg','Preview'},{'Passthrough','OFF','TX controls mixer','Use with care'}}},
 motors={title='MOTORS',note='DANGER: disconnect motor or remove blades before testing.',rows={{'Throttle protocol (ESC)','PWM / OneShot','MultiShot / Brushed','DSHOT 150/300/600'},{'Update frequency','100 Hz','Motor stop','934 us'},{'Throttle low / high','950 / 1917 us','Live update','OFF'},{'ESC telemetry correction','Voltage 0%','Current 0%','Consumption 0%'},{'RPM source','Main rotor sensor','Motor poles','10'},{'RPM & Gearing','Aircraft Reference >','Gear Calculator >','Tail Pulley included'},{'Throttle / ESC calibration','LOW / HIGH setup','Override disabled','Safety dialog required'}}},
 governor={title='GOVERNOR',note='Tap ? for short help. Values match Rotorflight units.',rows={{'General','Mode: ELECTRIC','Autorotation 0 s','Hold timeout 5.0 s'},{'Throttle','Type: FUNCTION','Idle 0%','Handover 20%'},{'Motor ramp','Spoolup 10.0 s','Spooldown 3.0 s','Tracking 2.0 s'},{'Recovery','2.0 s','State','OFF / IDLE / AUTO / RUN'},{'Bypass curve','5 points','0 / 0 / 0 / 0 / 0%','Touch graph planned'},{'Profile values','Full headspeed','Min / Max throttle','PID + precomp'}}},
 profiles={title='PROFILES',note='Profile follows FC P1/P2/P3 when live connection is added.',pid=true,rows={{'PROFILE','P1','P2','P3'},{'PID GAINS','ROLL P 60  I 100  D 20','PITCH P 80  I 100  D 40','YAW P 120  I 180  D 30'},{'Feedforward / Boost','Roll 100 / 0','Pitch 100 / 0','Yaw 20 / 0'},{'Controller settings','Ground effect / I-term relax','Error limits / HSI','Cross coupling'},{'Bandwidth','Roll / Pitch / Yaw','D-term cutoff','B-term cutoff'},{'Tail rotor','Stop gains / precomp','TTA gain / limit','Inertia precomp'},{'Governor profile','Headspeed / throttle','PID / precomp','Behavior toggles'}}}
}
local function footer(msg)txt(20,449,msg or 'Roller: select   ENTER: open   RTN: back','muted');txt(430,463,'v'..VERSION..'  |  BLADE PARK','muted');end
local function drawList(title,list,back)
 header(title,'PREVIEW / NO FC WRITE');local visible=7
 if selected<scroll then scroll=selected elseif selected>=scroll+visible then scroll=selected-visible+1 end
 local wide=#list>visible and 712 or 760;for i=scroll,math.min(#list,scroll+visible-1) do local y=105+(i-scroll)*46;local a=list[i];button('row'..i,a[1],20,y,wide,40,selected==i,{kind='open',index=i});txt(380,y+11,a[2] or '','muted')end
 if #list>visible then local maxScroll=math.max(1,#list-visible+1);scroll=math.max(1,math.min(maxScroll,scroll));button('fullUp','^',748,105,32,34,false,{kind='fullScroll',delta=-3},'cyan');fill(758,145,10,210,'line');local th=math.max(30,math.floor(210*visible/#list));local ty=145+math.floor((210-th)*(scroll-1)/math.max(1,maxScroll-1));fill(752,ty,22,th,'orange');box(752,ty,22,th,'cyan');button('fullDown','v',748,364,32,34,false,{kind='fullScroll',delta=3},'cyan');txt(665,421,selected..' / '..#list,'orange',true)end
 footer(back and 'Roller: select   ENTER: open   RTN: Home' or nil)
end
drawRotorflightLogo=function(x,y)fill(x+13,y+13,6,6,'cyan');if lcd.drawLine then lcd.drawLine(sx(x+16),sy(y+16),sx(x+31),sy(y+9),col('cyan'));lcd.drawLine(sx(x+16),sy(y+16),sx(x+29),sy(y+25),col('cyan'));lcd.drawLine(sx(x+16),sy(y+16),sx(x+4),sy(y+27),col('purple'));lcd.drawLine(sx(x+16),sy(y+16),sx(x+2),sy(y+8),col('purple'));lcd.drawLine(sx(x+31),sy(y+9),sx(x+25),sy(y+8),col('cyan'));lcd.drawLine(sx(x+29),sy(y+25),sx(x+24),sy(y+27),col('cyan'));lcd.drawLine(sx(x+4),sy(y+27),sx(x+6),sy(y+21),col('purple'));lcd.drawLine(sx(x+2),sy(y+8),sx(x+8),sy(y+9),col('purple'))end end
drawRoundTile=function(x,y,w,h,bg,border,selected)fill(x+5,y+6,w,h,'line');fill(x+6,y,w-12,h,bg);fill(x,y+6,w,h-12,bg);fill(x+3,y+3,w-6,h-6,bg);if lcd.drawLine then lcd.drawLine(sx(x+7),sy(y),sx(x+w-7),sy(y),col(border));lcd.drawLine(sx(x+7),sy(y+h-1),sx(x+w-7),sy(y+h-1),col(border));lcd.drawLine(sx(x),sy(y+7),sx(x),sy(y+h-7),col(border));lcd.drawLine(sx(x+w-1),sy(y+7),sx(x+w-1),sy(y+h-7),col(border));lcd.drawLine(sx(x+2),sy(y+4),sx(x+6),sy(y),col(border));lcd.drawLine(sx(x+w-7),sy(y),sx(x+w-2),sy(y+5),col(border));lcd.drawLine(sx(x+2),sy(y+h-5),sx(x+6),sy(y+h-1),col(border));lcd.drawLine(sx(x+w-7),sy(y+h-1),sx(x+w-2),sy(y+h-5),col(border));if selected then lcd.drawLine(sx(x+9),sy(y+3),sx(x+w-9),sy(y+3),col('cyan'))end end end
drawFullIcon=function(k,x,y,c)local function ln(a,b,d,e)if lcd.drawLine then lcd.drawLine(sx(a),sy(b),sx(d),sy(e),col(c))end end;if k=='status'then fill(x+8,y+8,18,18,'panel2');box(x+8,y+8,18,18,c);ln(x+11,y+17,x+15,y+17);ln(x+15,y+17,x+18,y+12);ln(x+18,y+12,x+23,y+22)elseif k=='setup'then ln(x+9,y+25,x+25,y+9);fill(x+8,y+21,7,7,c);box(x+19,y+7,8,8,c)elseif k=='configuration'then box(x+9,y+9,17,17,c);fill(x+14,y+14,7,7,c)elseif k=='receiver'then ln(x+17,y+25,x+17,y+12);ln(x+10,y+17,x+17,y+10);ln(x+24,y+17,x+17,y+10);fill(x+14,y+23,7,4,c)elseif k=='failsafe'then ln(x+17,y+7,x+27,y+12);ln(x+27,y+12,x+24,y+24);ln(x+24,y+24,x+17,y+29);ln(x+17,y+29,x+10,y+24);ln(x+10,y+24,x+7,y+12);ln(x+7,y+12,x+17,y+7)elseif k=='power'then box(x+7,y+11,22,14,c);fill(x+29,y+15,4,6,c);fill(x+11,y+15,10,6,c)elseif k=='motors'or k=='governor'then fill(x+15,y+15,6,6,c);ln(x+18,y+18,x+31,y+18);ln(x+18,y+18,x+5,y+18);ln(x+18,y+18,x+18,y+5);ln(x+18,y+18,x+18,y+31)elseif k=='servos'then box(x+7,y+10,23,17,c);ln(x+11,y+18,x+26,y+18);fill(x+15,y+15,6,6,c)elseif k=='mixer'then for i=0,2 do ln(x+7,y+10+i*8,x+30,y+10+i*8);fill(x+12+i*6,y+7+i*8,5,7,c)end elseif k=='gyro'or k=='sensors'then ln(x+6,y+18,x+12,y+11);ln(x+12,y+11,x+18,y+25);ln(x+18,y+25,x+24,y+8);ln(x+24,y+8,x+31,y+18)elseif k=='rates'then ln(x+7,y+27,x+7,y+13);ln(x+7,y+27,x+30,y+27);ln(x+9,y+24,x+16,y+17);ln(x+16,y+17,x+22,y+20);ln(x+22,y+20,x+29,y+9)elseif k=='profiles'then fill(x+7,y+8,7,21,c);fill(x+16,y+12,7,17,c);fill(x+25,y+5,7,24,c)elseif k=='modes'or k=='adjustments'then for i=0,2 do ln(x+7,y+10+i*9,x+30,y+10+i*9);fill(x+12+i*6,y+7+i*9,6,6,c)end elseif k=='beeper'then ln(x+8,y+14,x+15,y+14);ln(x+15,y+14,x+22,y+8);ln(x+22,y+8,x+22,y+27);ln(x+22,y+27,x+15,y+21);ln(x+15,y+21,x+8,y+21)elseif k=='blackbox'then box(x+7,y+8,24,21,c);for i=0,2 do fill(x+11+i*7,y+13,3,11,c)end else box(x+8,y+8,22,22,c)end end
drawFullGrid=function()header('','FULL SETUP');if rfLogo and lcd.drawBitmap then lcd.drawBitmap(rfLogo,sx(18),sy(56))else drawRotorflightLogo(20,62);txt(62,69,'LUA ROTORFLIGHT CONFIGURATOR','cyan',true)end;local visible=16;local first=math.floor((math.max(1,scroll)-1)/4)*4+1;if selected<first then first=math.floor((selected-1)/4)*4+1 elseif selected>first+visible-1 then first=math.floor((selected-1)/4-3)*4+1 end;first=math.max(1,math.min(math.max(1,#full-visible+1),first));first=math.floor((first-1)/4)*4+1;scroll=first;for i=first,math.min(#full,first+visible-1)do local n=i-first;local coln=n%4;local row=math.floor(n/4);local x=20+coln*184;local y=112+row*72;local a=full[i];local active=selected==i;drawRoundTile(x,y,176,64,active and'blue'or'panel',active and'cyan'or'line',active);fill(x,y,6,64,active and'cyan'or({'cyan','orange','purple','green'})[i%4+1]);drawFullIcon(a[3],x+12,y+14,active and'cyan'or'muted');local label=#a[1]>16 and(string.sub(a[1],1,14)..'..')or a[1];txt(x+52,y+23,label,active and'cyan'or'text',true);add('fullTile'..i,x,y,176,64,{kind='open',index=i})end;if #full>visible then button('fullUp','^',756,105,24,32,false,{kind='fullScroll',delta=-4},'cyan');fill(763,143,10,210,'line');local maxFirst=math.max(1,#full-visible+1);local ty=143+math.floor(178*(first-1)/math.max(1,maxFirst-1));fill(758,ty,20,32,'orange');button('fullDown','v',756,362,24,32,false,{kind='fullScroll',delta=4},'cyan')end;footer('Roller: select   ENTER: open   RTN: Home')end
local function fit(v,n)v=tostring(v or'');if #v>n then return string.sub(v,1,n-2)..'..'end;return v end
local function drawScreen(s)
 header(s.title,'PREVIEW / NO FC WRITE');txt(20,96,s.note,'orange')
 local y=127
 for i,r in ipairs(s.rows) do
   local h=i==1 and 34 or 37;fill(20,y,760,h,(s.pid and i==2) and 'pid' or (i%2==0 and 'panel2' or 'panel'));box(20,y,760,h,'line')
   local xpos={34,220,425,610};for c=1,4 do if r[c] then txt(xpos[c],y+9,fit(r[c],c==4 and 18 or 20),(s.pid and i==2) and 'text' or (c==1 and 'cyan' or 'text')) end end
   y=y+h+3;if y>416 then break end
 end
 button('back','< Back',650,425,130,40,false,{kind='back'});footer('Values shown for layout review. Nothing is sent to the FC.')
end
local function drawOptions()
 header('OPTIONS','BETA TEST')
 fill(20,96,760,76,'panel');box(20,96,760,76,'red');txt(34,105,'BETA TEST NOTICE','red',true)
 txt(34,128,'Verify settings, directions, failsafe and motor behavior before flight.','orange')
 txt(34,149,'Disconnect motor power during initial tests. Use is at your own risk.','muted')
 local opts={{'Save mode',saveMode==1 and 'MANUAL SAVE' or 'AUTO APPLY & SAVE'},{'Armed safety',armedLock and 'Block permanent save while armed' or 'Firmware rules only'},{'Verification','OFF (fast)','Optional read-back verification'},{'Help buttons','ON','Local help text'}}
 for i,a in ipairs(opts)do local y=180+(i-1)*50;fill(20,y,760,42,i==selected and 'blue' or 'panel');box(20,y,760,42,i==selected and 'cyan' or 'line');txt(36,y+8,a[1],'cyan');txt(220,y+8,a[2],'text');if a[3]then txt(510,y+8,a[3],'muted')end;add('opt'..i,20,y,760,42,{kind='option',index=i})end
 button('back','< Back',650,393,130,40,false,{kind='back'});footer()
end
local function drawHelp()
 fill(55,88,690,300,'panel');box(55,88,690,300,'cyan');txt(78,108,'HELP','cyan',true)
 local lines={'This build checks the complete menu layout on TX16S MK3.','Touch and roller navigation are enabled.','Displayed values are examples for screen review.','No value is read from or written to the flight controller.','After this UI passes, live FC pages will be connected in order,','starting with Profiles / PID.'}
 for i,v in ipairs(lines)do txt(78,153+(i-1)*32,v,i==4 and 'orange' or 'text')end
 button('closehelp','Close',570,329,145,42,true,{kind='help'})
end

local function drawLiveProfiles()
 header('PROFILES / PID',pidState);txt(20,94,'Live FC values. Orange means changed but not saved.','muted')
 local names={'ROLL','PITCH','YAW'};local heads={'P','I','D','FF','BOOST'}
 for c=1,5 do txt(176+(c-1)*104,127,heads[c],'cyan')end
 for r=1,3 do
  txt(34,166+(r-1)*64,names[r],r==1 and 'red' or (r==2 and 'green' or 'cyan'),true)
  for c=1,5 do local n=(r-1)*5+c;local x=146+(c-1)*104;local y=153+(r-1)*64;local focus=pidSel==n
   fill(x,y,88,43,focus and 'pid' or 'panel2');box(x,y,88,43,focus and 'orange' or 'line');txt(x+23,y+12,pidValue(n)or'--',pidDirty and 'orange' or 'text',false,focus);add('pid'..n,x,y,88,43,{kind='pid',index=n})
  end
 end
 txt(34,355,'HSI OFFSET','muted');local labs={'ROLL','PITCH'}
 for j=1,2 do local n=15+j;local x=218+(j-1)*150;local focus=pidSel==n;txt(x-60,357,labs[j],'cyan');fill(x,345,92,40,focus and 'pid'or'panel2');box(x,345,92,40,focus and'orange'or'line');txt(x+25,356,pidValue(n)or'--',pidDirty and'orange'or'text');add('pid'..n,x,345,92,40,{kind='pid',index=n})end
 local controls={{18,'Apply & Save',20,403,180},{19,'Reload FC',210,403,140},{20,'Profile P'..(pidProfile+1),360,403,150}}
 for _,a in ipairs(controls)do button('ctl'..a[1],a[2],a[3],a[4],a[5],40,pidSel==a[1],{kind='pidctl',index=a[1]},a[1]==18 and'orange'or'cyan')end
 button('minus','-10',520,403,70,40,false,{kind='delta',value=-10});button('plus','+10',600,403,70,40,false,{kind='delta',value=10});button('back','<',680,403,100,40,false,{kind='back'})
 footer(pidError or (pidEditing and 'EDITING: roller changes value   ENTER: finish' or 'Roller: select   ENTER: edit/open   RTN: Full Setup'))
end



local servoData,servoState={},'NOT READ'
local overrideValue,overrideAngle,overrideOn={},{},{false,false,false,false}
local overrideDrag,overrideLastSend,overrideLastX=nil,-1000,nil
local servoOutput,servoOutputAt,servoOutputPending={},-1000,false
local servoSel,servoEdit,servoTab=1,false,1
local centerConfirm=nil
local servoFields={'mid','min','max','scaleNeg','scalePos','rate','speed','flags'}
local servoLabels={'Center','Min','Max','Scale -','Scale +','Rate Hz','Speed ms','Reverse / Geo'}
local function requestServos()if not rfReady then return end;servoState='READING FC...';local gotConfig,gotOverride=false,false;local function ready()if gotConfig and gotOverride then servoState='CONNECTED / READY';servoEdit=false end end;servoApi.getServoConfigurations(function(_,d)servoData=d;gotConfig=true;ready()end,nil);rf2.mspQueue:add({command=192,processReply=function(_,b)b.offset=1;for i=0,3 do local v=rf2.mspHelper.readS16(b);overrideValue[i]=v;overrideOn[i]=v>=-2000 and v<=2000;overrideAngle[i]=overrideOn[i]and (v>=0 and math.floor(v*50/1000+.5)or math.ceil(v*50/1000-.5))or 0 end;gotOverride=true;ready()end,errorHandler=function()gotOverride=true;servoState='CONFIG READY / OVERRIDE READ ERROR';ready()end})end
local function servoCell()local si=math.floor((servoSel-1)/8);local fi=(servoSel-1)%8+1;return si,fi,servoData[si]and servoData[si][servoFields[fi]]end
local function changeServo(delta)local _,fi,d=servoCell();if not d or d.value==nil then return end;local step=(fi==1 and 1)or(fi>=4 and fi<=7 and 1)or 1;d.value=math.max(d.min or 0,math.min(d.max or 65535,d.value+delta*step));servoState='CHANGED / NOT SAVED'end
local function saveServos()
 if not servoData[0]then return end;servoState='SAVING...';for i=0,#servoData do servoApi.setServoConfiguration(i,servoData[i])end
 if escSensorConfig then escSensorApi.write(escSensorConfig)end
 rf2.mspQueue:add({command=250,processReply=function()servoState='SAVED TO FC'end,errorHandler=function()servoState='APPLIED / SAVE AFTER DISARM'end})
end

local function sendOverride(si,angle,on,onReply,onError)
 local v=on and (angle>=0 and math.floor(angle*1000/50+.5)or math.ceil(angle*1000/50-.5))or 2001;local m={command=193,payload={si},processReply=onReply,errorHandler=onError};rf2.mspHelper.writeU16(m.payload,v);rf2.mspQueue:add(m);overrideValue[si]=v;overrideAngle[si]=angle;overrideOn[si]=on;servoState=on and'OVERRIDE ACTIVE - DISARM ONLY'or'OVERRIDE OFF'
end
local function disableOverrides(onReply,onError)
 overrideDrag=nil
 if not rfReady then if onError then onError()end;return end;local any=false;for i=0,3 do if overrideOn[i]then any=true end;overrideOn[i]=false;overrideAngle[i]=0 end;if any or onReply then local m={command=196,payload={},processReply=onReply,errorHandler=onError};rf2.mspHelper.writeU16(m.payload,2001);rf2.mspQueue:add(m)end
end

local function commitCenterFromOutput(si)
 local cfg=servoData[si];local out=servoOutput[si];if not overrideOn[si]then servoState='ENABLE OVERRIDE FIRST';return end
 if not cfg or not cfg.mid or not out then servoState='WAIT FOR PWM OUTPUT';return end
 if out<(cfg.mid.min or 50)or out>(cfg.mid.max or 2250)then servoState='PWM OUT OF CENTER RANGE';return end
 cfg.mid.value=out;servoState='CENTER '..out..' us / SAVING...';servoApi.setServoConfiguration(si,cfg);if escSensorConfig then escSensorApi.write(escSensorConfig)end
 rf2.mspQueue:add({command=250,processReply=function()servoState='CENTER '..out..' us SAVED' end,errorHandler=function()servoState='CENTER APPLIED / SAVE AFTER DISARM' end});local m={command=193,payload={si}};rf2.mspHelper.writeU16(m.payload,2001);rf2.mspQueue:add(m);overrideOn[si]=false;overrideAngle[si]=0
end

local function askCenterFromOutput(si)
 local cfg=servoData[si];local out=servoOutput[si];if not overrideOn[si]then servoState='ENABLE OVERRIDE FIRST';return end;if not cfg or not cfg.mid or not out then servoState='WAIT FOR PWM OUTPUT';return end;if out<(cfg.mid.min or 50)or out>(cfg.mid.max or 2250)then servoState='PWM OUT OF CENTER RANGE';return end;centerConfirm={index=si,pwm=out,old=cfg.mid.value}
end

local function drawCenterConfirm()
 local c=centerConfirm;if not c then return end;hit={};fill(105,100,590,275,'panel');box(105,100,590,275,'green');txt(140,125,'SET SERVO CENTER?','green',true);txt(140,172,'Servo #'..(c.index+1),'text',true);txt(140,208,'Current Center: '..c.old,'muted');txt(140,238,'New Center: '..c.pwm,'text',true);txt(140,274,'This value will be saved to the FC.','orange');button('centerNo','NO',150,310,210,48,false,{kind='centerNo'});button('centerYes','YES / SAVE',435,310,210,48,true,{kind='centerYes'},'green')
end

local function requestServoOutput()
 if not rfReady or servoOutputPending or not rf2.mspQueue:isProcessed()then return end
 servoOutputPending=true;rf2.mspQueue:add({command=103,processReply=function(_,b)b.offset=1;for i=0,3 do if b.offset+1<=#b then servoOutput[i]=rf2.mspHelper.readU16(b)end end;servoOutputPending=false end,errorHandler=function()servoOutputPending=false end})
end

local function sliderAngle(x)local left,right=sx(372),sx(698);local q=math.max(0,math.min(1,(x-left)/(right-left)));return math.floor(-90+q*180+.5)end
local function updateOverrideSlider(si,x,final)
 overrideLastX=x;local a=sliderAngle(x);overrideAngle[si]=a;overrideOn[si]=true;servoState='OVERRIDE '..a..' deg - DISARM ONLY';local now=getTime and getTime()or 0
 if final or (now-overrideLastSend>=5 and rf2.mspQueue:isProcessed())then sendOverride(si,a,true);overrideLastSend=now end
end

local function drawOverrideBody()
 txt(12,128,'SERVO','cyan');txt(55,128,'ON','cyan');txt(125,128,'ANGLE','cyan');txt(205,128,'PWM','cyan');txt(266,128,'CENTER','cyan');txt(440,128,'ADJUST','cyan')
 for si=0,3 do local y=153+si*55;local a=math.max(-90,math.min(90,overrideAngle[si]or 0));txt(12,y+14,'#'..(si+1),'text',true);button('oe'..si,overrideOn[si]and'ON'or'OFF',42,y,58,43,overrideOn[si],{kind='overrideEnable',index=si},overrideOn[si]and'orange'or'cyan');button('oa'..si,tostring(a)..' deg',106,y,76,43,false,{kind='overrideAngle',index=si});txt(190,y+14,servoOutput[si]and tostring(servoOutput[si])or'READ...','text',true);button('oc'..si,'SET C',260,y,58,43,true,{kind='setCenter',index=si},'green');button('ol'..si,'<',323,y,40,43,false,{kind='overrideStep',index=si,delta=-1},'cyan');fill(372,y+18,326,7,'line');local kx=372+math.floor((a+90)*326/180);fill(kx-6,y+8,12,27,overrideOn[si]and'orange'or'muted');for tv=-90,90,5 do local tx=372+math.floor((tv+90)*326/180);local th=tv%20==0 and 8 or tv%10==0 and 6 or 3;fill(tx,y+25,1,th,'muted');if tv%20==0 then txt(tx-(tv<=-20 and 8 or tv>=20 and 5 or 2),y+34,tostring(tv),'muted')end end;add('os'..si,367,y,336,50,{kind='overrideSlider',index=si});button('or'..si,'>',710,y,40,43,false,{kind='overrideStep',index=si,delta=1},'cyan')end
 button('offall','DISABLE ALL',20,382,180,40,false,{kind='overrideAllOff'},'orange');button('tab1','< Servo Settings',210,382,180,40,false,{kind='servotab',value=1});button('back','< Back',650,382,130,40,false,{kind='back'});footer('WARNING: DISARM only. Servos move immediately. Leaving this page disables all.')
end

local function toggleServoFlag(si,mask)local d=servoData[si]and servoData[si].flags;if not d then return end;d.value=bit32.bxor(d.value,mask);servoState='CHANGED / NOT SAVED';if saveMode==2 then saveServos()end end

local function servoTopButton(id,label,x,w,active,accent)local chosen=servoSelectedId==id;fill(x,94,w,38,active and'blue'or'pid');box(x,94,w,38,(accent=='orange'or chosen)and'orange'or'cyan');if chosen then fill(x,94,5,38,'orange')end;txt(x+13,105,label,active and'text'or'muted');add(id,x,94,w,38,{kind='servotab',value=id=='st1'and 1 or id=='st2'and 2 or 3})end
local function servoTop()servoTopButton('st1','PULSE & LIMITS',20,245,servoTab==1,'cyan');servoTopButton('st2','RATE & DIRECTION',277,245,servoTab==2,'cyan');servoTopButton('st3','SERVO OVERRIDE',534,246,servoTab==3,'orange')end
local function drawOverrideBody()
 txt(12,159,'SERVO','cyan');txt(55,159,'ON','cyan');txt(125,159,'ANGLE','cyan');txt(205,159,'PWM','cyan');txt(266,159,'CENTER','cyan');txt(440,159,'ADJUST','cyan')
 for si=0,3 do local y=180+si*48;local a=math.max(-90,math.min(90,overrideAngle[si]or 0));txt(12,y+12,'#'..(si+1),'text',true);button('oe'..si,overrideOn[si]and'ON'or'OFF',42,y,58,39,overrideOn[si],{kind='overrideEnable',index=si},'orange');button('oa'..si,tostring(a)..' deg',106,y,76,39,false,{kind='overrideAngle',index=si});txt(190,y+12,servoOutput[si]and tostring(servoOutput[si])or'READ...','text',true);button('oc'..si,'SET C',260,y,58,39,true,{kind='setCenter',index=si},'green');button('ol'..si,'<',323,y,40,39,false,{kind='overrideStep',index=si,delta=-1},'cyan');fill(372,y+16,326,7,'line');local kx=372+math.floor((a+90)*326/180);fill(kx-6,y+6,12,25,overrideOn[si]and'orange'or'muted');add('os'..si,367,y,336,42,{kind='overrideSlider',index=si});button('or'..si,'>',710,y,40,39,false,{kind='overrideStep',index=si,delta=1},'cyan')end
 button('offall','DISABLE ALL',20,382,180,40,false,{kind='overrideAllOff'},'orange');button('ssave','SAVE',500,382,80,40,false,{kind='servoctl',value='save'},'orange');button('sreload','RELOAD',590,382,90,40,false,{kind='servoctl',value='reload'});button('back','<',690,382,90,40,false,{kind='back'});footer('WARNING: DISARM only. Touch opens editor immediately; OK confirms the value.')
end
local function drawLiveServos()
 header('SERVOS',servoState);servoTop();txt(20,139,servoTab==3 and'Servo Override is temporary and is not saved.'or'Live FC servo configuration. Four primary outputs shown together.','muted');if servoTab==3 then drawOverrideBody();return end
 local first=servoTab==1 and 1 or 5;local last=servoTab==1 and 4 or 8;txt(25,161,'SERVO','cyan');for fi=first,last do txt(135+(fi-first)*150,161,servoLabels[fi],'cyan')end
 for si=0,3 do local y=181+si*48;txt(35,y+12,'#'..(si+1),'text',true);for fi=first,last do local n=si*8+fi;local x=120+(fi-first)*150;local d=servoData[si]and servoData[si][servoFields[fi]];local v=d and d.value or'--';local focus=servoSel==n;if fi==8 and d then local rev=bit32.btest(d.value,1);local geo=bit32.btest(d.value,2);button('rev'..si,rev and'R ON'or'R OFF',x,y,62,39,rev,{kind='servoflag',index=si,mask=1},'orange');button('geo'..si,geo and'G ON'or'G OFF',x+68,y,62,39,geo,{kind='servoflag',index=si,mask=2},'cyan')else fill(x,y,130,39,focus and'pid'or'panel2');box(x,y,130,39,focus and'orange'or'line');txt(x+18,y+11,v,(string.find(servoState,'CHANGED',1,true)and'orange'or'text'));add('servo'..n,x,y,130,39,{kind='servo',index=n})end end end
 button('ssave','SAVE',500,382,80,40,false,{kind='servoctl',value='save'},'orange');button('sreload','RELOAD',590,382,90,40,false,{kind='servoctl',value='reload'});button('back','< BACK',690,382,90,40,false,{kind='back'});footer(servoEdit and'EDITING: roller changes value   ENTER: finish'or'Roller and touch enabled. Touch opens editor immediately; OK confirms the value.')
end

local directionAtt={roll=0,pitch=0,yaw=0};local directionState='WAITING FC';local directionPending=false;local directionAt=-1000;local directionPass={false,false,false};local directionSel=1;local mixerTab=1;local mixerSub=1
local mixerInputs={};local inputBusy=false;local inputSaving=false;local mixerLiveConfig=false;local mixerLiveInputs={};local mixerOverride={};local mixerOverrideOn={false,false,false,false};local mixerDrag=nil;local mixerGaugeEdit=nil;local mixerLastX=nil;local mixerLastSend=-1000
local mixerTabs={'MAIN ROTOR SETTING','DIRECTION CHECK','SWASHPLATE TRIM','MAIN ROTOR GEOMETRY','TAIL ROTOR SETTING','MIXER OVERRIDE EASY','MIXER OVERRIDE'}
local mixerMenu=false;local mixerMenuSel=1;local mixerMenuScroll=1
local mixerNotes={'Swash type, rotor and control directions','Check compensation while moving aircraft','Roll, pitch and collective trims','Calibration, geometry, limits and phase','Tail type, direction, calibration and limits','Linked override with calibration values','Direct temporary override for all axes'}
local function f1(v)return string.format('%.1f',(v or 0)/10)end
local function directionLabel(i)local d=mixerInputs[i];return not d and'READ...'or d.rate==0 and'DISABLED'or d.rate<0 and'Reverse'or'Normal'end
local function requestMixerInputs()
 if not rfReady or inputBusy or inputSaving then return end;inputBusy=true;mixerInputs={};directionPass={false,false,false}
 rf2.mspQueue:add({command=170,processReply=function(_,q)inputBusy=false;q.offset=1;local n=math.floor(#q/6);for i=0,n-1 do mixerInputs[i]={rate=rf2.mspHelper.readS16(q),min=rf2.mspHelper.readS16(q),max=rf2.mspHelper.readS16(q)}end;if not mixerInputs[4]then mixerState='MIXER INPUT READ ERROR'end end,errorHandler=function()inputBusy=false;mixerState='MIXER INPUT READ ERROR'end})
end
local function requestMixerOverride()rf2.mspQueue:add({command=190,processReply=function(_,q)q.offset=1;local n=math.floor(#q/2);for i=0,n-1 do local v=rf2.mspHelper.readS16(q);mixerOverride[i]=v;mixerOverrideOn[i]=v>=-2500 and v<=2500 end end})end
local function saveMixerInputs()
 if inputBusy or inputSaving then return false end;local pending={};for i=1,4 do if mixerInputs[i]and mixerInputs[i].dirty then pending[#pending+1]=i end end;if #pending==0 then return false end;inputSaving=true;mixerState='SAVING INPUTS...'
 local function nextWrite(n)local i=pending[n];if not i then if escSensorConfig then escSensorApi.write(escSensorConfig)end
 rf2.mspQueue:add({command=250,processReply=function()inputSaving=false;for _,k in ipairs(pending)do mixerInputs[k].dirty=false end;mixerState='SAVED TO FC'end,errorHandler=function()inputSaving=false;mixerState='APPLIED / SAVE AFTER DISARM'end});return end;local d=mixerInputs[i];local q={i};rf2.mspHelper.writeU16(q,d.rate);rf2.mspHelper.writeU16(q,d.min);rf2.mspHelper.writeU16(q,d.max);rf2.mspQueue:add({command=171,payload=q,processReply=function()nextWrite(n+1)end,errorHandler=function()inputSaving=false;mixerState='INPUT WRITE ERROR'end})end;nextWrite(1)
end
local function saveMixerConfigOnly()if not mixerConfig then return end;mixerState='SAVING CONFIG...';mixerApi.write(mixerConfig)end
local function saveAllMixer()saveMixerConfigOnly();if not saveMixerInputs()then if escSensorConfig then escSensorApi.write(escSensorConfig)end
 rf2.mspQueue:add({command=250,processReply=function()mixerState='SAVED TO FC'end,errorHandler=function()mixerState='APPLIED / SAVE AFTER DISARM'end})end end
local function requestMixerConfig()if not rfReady or not mixerApi or inputSaving then return end;mixerState='READING FC...';requestMixerInputs();requestMixerOverride();mixerApi.read(function(_,d)mixerConfig=d;mixerState='CONNECTED / READY'end,nil,mixerConfig)end
local function dirtyMixer()mixerState='LIVE ON FC / NOT SAVED';if saveMode==2 then mixerLiveConfig=false;saveAllMixer()else mixerLiveConfig=true end end
local function toggleDirection(i)local d=mixerInputs[i];if not d or d.rate==0 then return end;d.rate=-d.rate;d.dirty=true;mixerLiveInputs[i]=true;if i<=3 then directionPass[i]=false end;dirtyMixer()end
local function chooseSwash(v)mixerConfig.swash_type.value=v;swashSelect=nil;directionPass={false,false,false};dirtyMixer()end
local function drawSwashSelect()if not swashSelect then return end;hit={};fill(145,70,510,365,'panel');box(145,70,510,365,'cyan');txt(180,88,'SELECT SWASHPLATE TYPE','cyan',true);for i=0,6 do local y=125+i*40;button('sw'..i,swashNames[i],180,y,440,34,swashSelect==i,{kind='swashChoice',value=i},'cyan')end end
local function cycleValue(d)local v=d.value+1;if v>d.max then v=d.min end;d.value=v;dirtyMixer()end
local function openChoice(title,items,selected,apply)choiceSelect={title=title,items=items,selected=selected or 1,apply=apply}end
local function chooseChoice()if not choiceSelect then return end;local q=choiceSelect;local it=q.items[q.selected];choiceSelect=nil;rfChoiceTouchGuard=(getTime and getTime()or 0)+8;if it and q.apply then q.apply(it[2])end end
local function drawChoice()if not choiceSelect then return end;hit={};fill(145,70,510,365,'panel');box(145,70,510,365,'cyan');txt(180,88,choiceSelect.title,'cyan',true);local first=math.max(1,math.min(math.max(1,#choiceSelect.items-6),choiceSelect.selected-3));local last=math.min(#choiceSelect.items,first+6);for i=first,last do local it=choiceSelect.items[i];local y=125+(i-first)*40;button('ch'..i,string.sub(tostring(it[1]),1,42),180,y,405,34,choiceSelect.selected==i,{kind='choice',value=i},'cyan')end;if #choiceSelect.items>7 then button('choiceUp','^',594,125,40,42,false,{kind='choiceStep',delta=-1},'cyan');button('choiceDown','v',594,363,40,42,false,{kind='choiceStep',delta=1},'cyan');txt(500,410,choiceSelect.selected..' / '..#choiceSelect.items,'muted')end end
local function enumItems(d)local t={};if not d then return t end;for i=d.min,d.max do t[#t+1]={d.table and d.table[i]or tostring(i),i}end;return t end
local function openEnumChoice(key,title)local d=mixerConfig and mixerConfig[key];if not d then return end;local items=enumItems(d);local sel=1;for i,it in ipairs(items)do if it[2]==d.value then sel=i end end;openChoice(title,items,sel,function(v)d.value=v;dirtyMixer()end)end
local function openDirectionChoice(i,title)local d=mixerInputs[i];if not d or d.rate==0 then return end;openChoice(title,{{'Normal',1},{'Reverse',-1}},d.rate<0 and 2 or 1,function(sign)d.rate=math.abs(d.rate)*sign;d.dirty=true;mixerLiveInputs[i]=true;if i<=3 then directionPass[i]=false end;dirtyMixer()end)end
local function editMixField(label,kind,index,value,min,max,y,display)local shown=display or tostring(value or'--');txt(30,y+12,label,'text');button('mf'..kind..index,shown,470,y,210,40,false,{kind='mixfield',fieldKind=kind,index=index,value=value,min=min,max=max},'cyan')end
local function bottom()button('mchoose','< MIXER MENU',20,400,190,38,false,{kind='mixerMenu'},'cyan');button('msave','APPLY & SAVE',470,400,150,38,false,{kind='mixerControl',value='save'},'orange');button('back','< BACK',650,400,130,38,false,{kind='back'});footer('MENU / RTN returns to the Mixer list. Override values are temporary.')end
local function mixerTopButton(id,label,x,y,w,active,i)local chosen=mixerSelectedId==id;fill(x,y,w,34,active and'blue'or'pid');box(x,y,w,34,(i>=6 or chosen)and'orange'or'cyan');if chosen then fill(x,y,5,34,'orange')end;txt(x+10,y+9,label,active and'text'or'muted');add(id,x,y,w,34,{kind='mixerTopTab',value=i})end
local function mixerTop()
 local tabs={'MAIN ROTOR','DIRECTION','SWASH TRIM','GEOMETRY','TAIL ROTOR','OVERRIDE EASY','OVERRIDE'};for i=1,4 do mixerTopButton('mxt'..i,tabs[i],20+(i-1)*190,94,185,mixerTab==i,i)end;for i=5,7 do mixerTopButton('mxt'..i,tabs[i],20+(i-5)*253,132,248,mixerTab==i,i)end
end
local function mixerBase(name,state)header('MIXER / '..name,state or mixerState);mixerTop()end
local function mixFooter()button('mxsave','APPLY & SAVE',470,402,150,36,false,{kind='mixerControl',value='save'},'orange');button('mxback','< BACK',650,402,130,36,false,{kind='back'});txt(22,414,mixerScroll..'','muted');footer('Roller: move/select   ENTER: edit   Touch: open/edit   OK: confirm')end
local function drawMixerScrollbar(total)
 if total<=4 then return end
 local maxStart=total-3;local trackY=218;local trackH=156;local thumbH=math.max(24,math.floor(trackH*4/total));local pos=(mixerScroll-1)/(maxStart-1);local thumbY=trackY+math.floor((trackH-thumbH)*pos)
 button('mxup','^',740,181,40,32,false,{kind='mixScroll',delta=-1},'cyan');fill(753,trackY,14,trackH,'line');fill(746,thumbY,28,thumbH,'orange');button('mxdown','v',740,376,40,22,false,{kind='mixScroll',delta=1},'cyan')
 for n=1,maxStart do local y=trackY+math.floor((n-1)*trackH/maxStart);local h=math.max(10,math.ceil(trackH/maxStart));add('mxtrack'..n,738,y,42,h,{kind='mixScrollTo',value=n})end
end
local function mixRows(rows)
 mixerRowCount=#rows;local visible=4;if mixerNav<mixerScroll then mixerScroll=mixerNav elseif mixerNav>=mixerScroll+visible then mixerScroll=mixerNav-visible+1 end
 for i=mixerScroll,math.min(#rows,mixerScroll+visible-1)do local r=rows[i];local y=177+(i-mixerScroll)*52;fill(20,y,710,46,'panel2');box(20,y,710,46,mixerNav==i and'orange'or'line');txt(34,y+13,r[1],i==mixerNav and'cyan'or'text');button('mxr'..i,r[2]or'--',462,y+4,258,38,mixerNav==i,r[3],r[4]or'cyan')end
 if #rows>visible then txt(690,386,mixerNav..' / '..#rows,'muted');drawMixerScrollbar(#rows)end
end
local function cfgRow(label,key,fmt)local d=mixerConfig and mixerConfig[key];return{label,d and(fmt and fmt(d.value)or tostring(d.value))or'READ...',{kind='mixfield',fieldKind='config',index=key,value=d and d.value,min=d and d.min,max=d and d.max}}end
local function inpRow(label,axis,key,min,max,fmt)local d=mixerInputs[axis];local v=d and d[key];return{label,v and(fmt and fmt(v)or tostring(v))or'READ...',{kind='mixfield',fieldKind='input',index=axis..':'..key,value=v,min=min,max=max}}end
local function drawMainRotor()mixerBase('MAIN ROTOR SETTING');local v=mixerConfig and mixerConfig.swash_type and mixerConfig.swash_type.value;local rows={{'Swashplate Type',v~=nil and swashNames[v]or'READ...',{kind='mixfield',fieldKind='swash',value=v}},{'Main Rotor Direction',mixerConfig and(mixerConfig.main_rotor_dir.value==0 and'Clockwise'or'Counter CW')or'READ...',{kind='mixfield',fieldKind='enum',index='main_rotor_dir'}},{'Aileron Direction',directionLabel(1),{kind='mixfield',fieldKind='dir',index=1}},{'Elevator Direction',directionLabel(2),{kind='mixfield',fieldKind='dir',index=2}},{'Collective Direction',directionLabel(4),{kind='mixfield',fieldKind='dir',index=4}}};mixRows(rows);mixFooter()end
local function requestDirectionAttitude()if not rfReady or directionPending or not rf2.mspQueue:isProcessed()then return end;directionPending=true;rf2.mspQueue:add({command=108,processReply=function(_,q)q.offset=1;directionAtt.roll=rf2.mspHelper.readS16(q)/10;directionAtt.pitch=rf2.mspHelper.readS16(q)/10;directionAtt.yaw=rf2.mspHelper.readS16(q);directionPending=false;directionState='LIVE'end,errorHandler=function()directionPending=false;directionState='ATTITUDE READ ERROR'end})end
local function drawDirectionCheck()mixerBase('DIRECTION CHECK',directionState);local rows={{'ROLL: Tilt RIGHT / correct LEFT',directionLabel(1),{kind='mixerDirection',index=1}},{'PITCH: Nose DOWN / correct REAR',directionLabel(2),{kind='mixerDirection',index=2}},{'COLLECTIVE: Raise / swash level',directionLabel(4),{kind='mixerDirection',index=4}},{'Live FC attitude',string.format('R %+.1f  P %+.1f',directionAtt.roll,directionAtt.pitch),{kind='noop'}}};mixRows(rows);mixFooter()end
local function drawTrim()mixerBase('SWASHPLATE TRIM');mixRows({cfgRow('Roll trim [%]','swash_trim_roll',f1),cfgRow('Pitch trim [%]','swash_trim_pitch',f1),cfgRow('Collective trim [%]','swash_trim_collective',f1)});mixFooter()end
local function drawGeometry()mixerBase('MAIN ROTOR GEOMETRY');local deg=function(v)return string.format('%.1f deg',v*12/1000)end;mixRows({inpRow('Cyclic calibration [%]',1,'rate',-2000,2000,f1),inpRow('Cyclic blade pitch limit',1,'max',0,2500,deg),inpRow('Collective calibration [%]',4,'rate',-2000,2000,f1),inpRow('Collective blade pitch limit',4,'max',0,2500,deg),cfgRow('Geometry correction','swash_geo_correction',function(v)return f1(v*2)end),cfgRow('Total blade pitch limit','swash_pitch_limit',deg),cfgRow('Swashplate phase angle','swash_phase',f1),cfgRow('Positive tilt correction','collective_tilt_correction_pos'),cfgRow('Negative tilt correction','collective_tilt_correction_neg')});mixFooter()end
local function drawTail()mixerBase('TAIL ROTOR SETTING');local mode=mixerConfig and mixerConfig.tail_rotor_mode;local q=mixerInputs[3];local rows={{'Tail Rotor Type',mode and mode.table[mode.value]or'READ...',{kind='mixfield',fieldKind='enum',index='tail_rotor_mode'}},{'Yaw Control Direction',directionLabel(3),{kind='mixfield',fieldKind='dir',index=3}},cfgRow('Yaw center trim','tail_center_trim',f1),inpRow('Yaw calibration [%]',3,'rate',-5000,5000,function(v)return f1(math.abs(v))end),inpRow('CW yaw blade limit',3,'min',-2500,0,function(v)return string.format('%.1f deg',-v*24/1000)end),inpRow('CCW yaw blade limit',3,'max',0,2500,function(v)return string.format('%.1f deg',v*24/1000)end)};mixRows(rows);mixFooter()end
local function overrideScale(axis)return axis==3 and((mixerConfig and mixerConfig.tail_rotor_mode.value or 0)>0 and 100 or 24)or 12 end
local function mixerOverrideAngle(axis)local v=mixerOverride[axis]or 0;return v*overrideScale(axis)/1000 end
local function sendMixerOverride(axis,ang,on)local raw=2501;if on then raw=math.floor(ang*1000/overrideScale(axis)+(ang>=0 and .5 or-.5));raw=math.max(-2500,math.min(2500,raw))end;local q={axis};rf2.mspHelper.writeU16(q,raw);rf2.mspQueue:add({command=191,payload=q});mixerOverride[axis]=raw;mixerOverrideOn[axis]=on;mixerState=on and'OVERRIDE ACTIVE - DISARM ONLY'or'OVERRIDE OFF'end
local function disableMixerOverrides()mixerDrag=nil;for _,axis in ipairs({1,2,3,4})do if mixerOverrideOn[axis]then sendMixerOverride(axis,0,false)end end end
local function drawOverrideAxisRow(i,axis,name,lim,y)
 local ang=math.max(-lim,math.min(lim,mixerOverrideAngle(axis)));add('mxr'..i,20,y,710,45,{kind='mixOverrideSlider',axis=axis,limit=lim});box(20,y,710,45,mixerNav==i and'orange'or'line');txt(28,y+13,name,'cyan',true)
 button('moe'..axis,mixerOverrideOn[axis]and'ON'or'OFF',102,y+3,58,39,mixerOverrideOn[axis],{kind='mixOverrideEnable',axis=axis},'orange');button('mov'..axis,string.format('%+.1f',ang),166,y+3,82,39,false,{kind='mixOverrideValue',axis=axis,limit=lim},'cyan');button('mol'..axis,'<',254,y+3,40,39,false,{kind='mixOverrideStep',axis=axis,delta=-1},'cyan');fill(300,y+18,330,7,'line');if mixerGaugeEdit==axis then box(296,y+5,340,34,'orange')elseif mixerSelectedId=='mos'..axis then box(296,y+5,340,34,'cyan')end;local kx=300+math.floor((ang+lim)*330/(lim*2));fill(kx-6,y+8,12,27,mixerOverrideOn[axis]and'orange'or'muted');for n=0,12 do local tx=300+math.floor(n*330/12);local major=n%2==0;fill(tx,y+24,1,major and 7 or 4,'muted');if major then local v=math.floor((-lim+n*lim/6)*10+.5)/10;local label=math.abs(v-math.floor(v))<.05 and tostring(math.floor(v))or string.format('%.1f',v);txt(tx-(#label*3),y+31,label,'muted')end end;add('mos'..axis,294,y,342,45,{kind='mixOverrideSlider',axis=axis,limit=lim});button('mor'..axis,'>',680,y+3,40,39,false,{kind='mixOverrideStep',axis=axis,delta=1},'cyan')
end
function rfEasyInputDisplay(axis,key,raw)
 if key=='rate'then return string.format('%.1f',math.abs(raw)/10)end;if axis==3 and key=='min'then return string.format('%.1f',-raw*24/1000)end;if axis==3 and key=='max'then return string.format('%.1f',raw*24/1000)end;if key=='max'and(axis==1 or axis==4)then return string.format('%.1f',raw*12/1000)end;return tostring(raw)
end
function rfEasyConfigDisplay(key,raw)
 if key=='swash_geo_correction'then return string.format('%.1f',raw/5)end;if key=='tail_center_trim'then return string.format('%.1f',raw/10)end;return tostring(raw)
end
local function drawOverrides(easy)
 mixerBase(easy and'MIXER OVERRIDE EASY'or'MIXER OVERRIDE')
 local items={{'axis',1,'ROLL',18},{'axis',2,'PITCH',18},{'axis',4,'COLLECTIVE',18},{'axis',3,'TAIL',((mixerConfig and mixerConfig.tail_rotor_mode.value or 0)>0 and 125 or 60)}}
 if easy then items={{'axis',1,'ROLL',18},{'input',1,'rate','Cyclic calibration [%]',-2000,2000},{'axis',2,'PITCH',18},{'axis',4,'COLLECTIVE',18},{'input',4,'rate','Collective calibration [%]',-2000,2000},{'config','swash_geo_correction','Collective Geometry Correction [%]',-125,125},{'axis',3,'TAIL',((mixerConfig and mixerConfig.tail_rotor_mode.value or 0)>0 and 125 or 60)},{'config','tail_center_trim','Yaw Center Trim [%]',-500,500},{'input',3,'rate','Yaw Calibration [%]',-5000,5000},{'input',3,'min','CW Yaw Blade Angle Limit [deg]',-2500,0},{'input',3,'max','CCW Yaw Blade Angle Limit [deg]',0,2500}}end
 mixerRowCount=#items;local visible=4;if mixerNav<mixerScroll then mixerScroll=mixerNav elseif mixerNav>=mixerScroll+visible then mixerScroll=mixerNav-visible+1 end
 for i=mixerScroll,math.min(#items,mixerScroll+visible-1)do local it=items[i];local y=184+(i-mixerScroll)*49;if it[1]=='axis'then drawOverrideAxisRow(i,it[2],it[3],it[4],y)else local value,act;if it[1]=='input'then local d=mixerInputs[it[2]];value=d and rfEasyInputDisplay(it[2],it[3],d[it[3]])or'READ...';act={kind='mixfield',fieldKind='input',index=it[2]..':'..it[3],value=d and d[it[3]],min=it[5],max=it[6]}else local d=mixerConfig and mixerConfig[it[2]];value=d and rfEasyConfigDisplay(it[2],d.value)or'READ...';act={kind='mixfield',fieldKind='config',index=it[2],value=d and d.value,min=it[4],max=it[5]}end;fill(20,y,760,45,'panel2');box(20,y,710,45,mixerNav==i and'orange'or'line');txt(34,y+13,(it[1]=='input' and it[4] or it[3]),'text');button('mxr'..i,value,462,y+3,258,39,mixerNav==i,act,'cyan')end end
 if #items>visible then txt(690,386,mixerNav..' / '..#items,'muted');drawMixerScrollbar(#items)end;mixFooter()
end

local function drawMixerPage()if mixerTab==1 then drawMainRotor()elseif mixerTab==2 then drawDirectionCheck()elseif mixerTab==3 then drawTrim()elseif mixerTab==4 then drawGeometry()elseif mixerTab==5 then drawTail()elseif mixerTab==6 then drawOverrides(true)else drawOverrides(false)end end


-- Rotorflight 2.3.0 Expert Gyro / MSP 92,93,154,155
gyTab=1;gyAxis=1;gySel=1;gyScroll=1;gyState='NOT READ';gyRows={};gyFeature=0;gyBusy=false
gyF={hardware=0,lpf1type=0,lpf1hz=0,lpf2type=0,lpf2hz=0,notch1hz=0,notch1cut=0,notch2hz=0,notch2cut=0,dynmin=0,dynmax=0,dyncount=0,dynq=10,dynnmin=10,dynnmax=100,rpmpreset=0,rpmmin=1}
gyBanks={};for a=1,3 do gyBanks[a]={};for _,z in ipairs({10,11,12,13,14,15,16,17,18,20,21,22,23,24})do gyBanks[a][z]={enabled=false,type=1,q=25}end end
gyTabs={'LOWPASS','NOTCH','DYNAMIC','RPM','CUSTOM'}
gyTypes={{'Disabled',0},{'1st Order',1},{'2nd Order',2}}
gyPresets={{'Custom',0},{'Low',1},{'Medium',2},{'High',3}}
gySources={{10,'Main Motor'},{11,'Main Rotor H1'},{12,'Main Rotor H2'},{13,'Main Rotor H3'},{14,'Main Rotor H4'},{15,'Main Rotor H5'},{16,'Main Rotor H6'},{17,'Main Rotor H7'},{18,'Main Rotor H8'},{20,'Tail Motor'},{21,'Tail Rotor H1'},{22,'Tail Rotor H2'},{23,'Tail Rotor H3'},{24,'Tail Rotor H4'}}
function gyU32(b)local a=rf2.mspHelper.readU16(b);local c=rf2.mspHelper.readU16(b);return a+c*65536 end
function gyFeatureOn(bit)return bit32.band(gyFeature,2^bit)~=0 end
function gyBuildRows()local r={};if gyTab==1 then r={{'section','GYRO LOWPASS FILTER 1'},{'choice','Filter type','lpf1type'},{'number','Cutoff frequency [Hz]','lpf1hz',0,1000},{'toggle','Dynamic cutoff','lpfdyn'},{'number','Dynamic minimum [Hz]','dynmin',0,1000},{'number','Dynamic maximum [Hz]','dynmax',0,1000},{'section','GYRO LOWPASS FILTER 2 - EXPERT'},{'choice','Filter type','lpf2type'},{'number','Cutoff frequency [Hz]','lpf2hz',0,1000}}
 elseif gyTab==2 then r={{'section','STATIC NOTCH FILTER 1 - EXPERT'},{'toggle','Enable Notch 1','notch1on'},{'number','Center frequency [Hz]','notch1hz',0,1000},{'number','Cutoff frequency [Hz]','notch1cut',0,1000},{'section','STATIC NOTCH FILTER 2 - EXPERT'},{'toggle','Enable Notch 2','notch2on'},{'number','Center frequency [Hz]','notch2hz',0,1000},{'number','Cutoff frequency [Hz]','notch2cut',0,1000}}
 elseif gyTab==3 then r={{'section','DYNAMIC NOTCH FILTER - EXPERT'},{'toggle','Dynamic Notch','dynfeature'},{'number','Notch count','dyncount',0,8},{'number','Notch Q','dynq',10,100,10},{'number','Minimum frequency [Hz]','dynnmin',10,200},{'number','Maximum frequency [Hz]','dynnmax',100,500}}
 elseif gyTab==4 then r={{'section','RPM FILTER - EXPERT'},{'toggle','RPM Filter','rpmfeature'},{'choice','Filter preset','rpmpreset'},{'number','Minimum frequency [Hz]','rpmmin',1,100},{'info','Custom configuration','Open CUSTOM tab for Roll / Pitch / Yaw notch banks'}}
 else r={{'section','CUSTOM RPM NOTCH BANK'},{'axis','Axis','axis'}};for _,z in ipairs(gySources)do local d=gyBanks[gyAxis][z[1]];r[#r+1]={'custom',z[2],z[1],d.enabled and 1 or 0};r[#r+1]={'ctype','  Notch type',z[1]};r[#r+1]={'cq','  Q',z[1],15,100,10}end end;gyRows=r;gySel=math.max(1,math.min(#r,gySel))end
function gyReadCustomAxis(axis,done)rf2.mspQueue:add({command=154,payload={axis-1},processReply=function(_,b)b.offset=1;local raw={};while b.offset+3<=#b do local src=rf2.mspHelper.readU8(b);local cen=rf2.mspHelper.readU16(b);if cen>=32768 then cen=cen-65536 end;local q=rf2.mspHelper.readU8(b);raw[#raw+1]={src=src,cen=cen,q=q}end;for _,z in ipairs(gySources)do gyBanks[axis][z[1]]={enabled=false,type=1,q=25}end;local i=1;while i<=#raw do local x=raw[i];if x.src>0 and gyBanks[axis][x.src]then local n=1;while i+n<=#raw and raw[i+n].src==x.src and raw[i+n].q==x.q do n=n+1 end;gyBanks[axis][x.src]={enabled=true,type=math.min(3,n),q=x.q};i=i+n else i=i+1 end end;if done then done()end end,errorHandler=function()if done then done()end end})end
function gyRead()if not rfReady or gyBusy then return end;gyBusy=true;gyState='READING FC...';local pending=2;local function done()pending=pending-1;if pending==0 then gyReadCustomAxis(1,function()gyReadCustomAxis(2,function()gyReadCustomAxis(3,function()gyBusy=false;gyState='CONNECTED / EXPERT';gyBuildRows()end)end)end)end end
 rf2.mspQueue:add({command=36,processReply=function(_,b)b.offset=1;gyFeature=gyU32(b);done()end,errorHandler=done})
 rf2.mspQueue:add({command=92,processReply=function(_,b)b.offset=1;gyF.hardware=rf2.mspHelper.readU8(b);gyF.lpf1type=rf2.mspHelper.readU8(b);gyF.lpf1hz=rf2.mspHelper.readU16(b);gyF.lpf2type=rf2.mspHelper.readU8(b);gyF.lpf2hz=rf2.mspHelper.readU16(b);gyF.notch1hz=rf2.mspHelper.readU16(b);gyF.notch1cut=rf2.mspHelper.readU16(b);gyF.notch2hz=rf2.mspHelper.readU16(b);gyF.notch2cut=rf2.mspHelper.readU16(b);gyF.dynmin=rf2.mspHelper.readU16(b);gyF.dynmax=rf2.mspHelper.readU16(b);gyF.dyncount=rf2.mspHelper.readU8(b);gyF.dynq=rf2.mspHelper.readU8(b);gyF.dynnmin=rf2.mspHelper.readU16(b);gyF.dynnmax=rf2.mspHelper.readU16(b);if b.offset<=#b then gyF.rpmpreset=rf2.mspHelper.readU8(b);gyF.rpmmin=rf2.mspHelper.readU8(b)end;done()end,errorHandler=done})end
function gyWriteFeature()local q={};rf2.mspHelper.writeU32(q,gyFeature);rf2.mspQueue:add({command=37,payload=q});gyState='LIVE ON FC / NOT SAVED'end
function gyWriteFilter()local q={gyF.hardware,gyF.lpf1type};rf2.mspHelper.writeU16(q,gyF.lpf1hz);q[#q+1]=gyF.lpf2type;rf2.mspHelper.writeU16(q,gyF.lpf2hz);rf2.mspHelper.writeU16(q,gyF.notch1hz);rf2.mspHelper.writeU16(q,gyF.notch1cut);rf2.mspHelper.writeU16(q,gyF.notch2hz);rf2.mspHelper.writeU16(q,gyF.notch2cut);rf2.mspHelper.writeU16(q,gyF.dynmin);rf2.mspHelper.writeU16(q,gyF.dynmax);q[#q+1]=gyF.dyncount;q[#q+1]=gyF.dynq;rf2.mspHelper.writeU16(q,gyF.dynnmin);rf2.mspHelper.writeU16(q,gyF.dynnmax);q[#q+1]=gyF.rpmpreset;q[#q+1]=gyF.rpmmin;rf2.mspQueue:add({command=93,payload=q});gyState='LIVE ON FC / NOT SAVED'end
function gyWriteCustom(axis)local q={axis-1};local count=0;for _,z in ipairs(gySources)do local src=z[1];local d=gyBanks[axis][src];if d.enabled then local typ=d.type;local multi=src==11 or src==12 or src==21 or src==22;if not multi then typ=1 end;local off=math.floor(((typ==3 and 200 or 100)/(d.q/10)));local centers=typ==1 and{0}or(typ==2 and{-off,off}or{-off,0,off});for _,c in ipairs(centers)do if count<16 then q[#q+1]=src;rf2.mspHelper.writeU16(q,c<0 and c+65536 or c);q[#q+1]=d.q;count=count+1 end end end end;while count<16 do q[#q+1]=0;rf2.mspHelper.writeU16(q,0);q[#q+1]=0;count=count+1 end;rf2.mspQueue:add({command=155,payload=q});gyState='CUSTOM LIVE ON FC / NOT SAVED'end
function gyToggle(k)if k=='lpfdyn'then if gyF.dynmin>0 and gyF.dynmin<gyF.dynmax then gyF.dynmin=0;gyF.dynmax=0 else gyF.dynmin=100;gyF.dynmax=300 end;gyWriteFilter()elseif k=='notch1on'then if gyF.notch1hz>0 and gyF.notch1cut>0 then gyF.notch1hz=0;gyF.notch1cut=0 else gyF.notch1hz=200;gyF.notch1cut=100 end;gyWriteFilter()elseif k=='notch2on'then if gyF.notch2hz>0 and gyF.notch2cut>0 then gyF.notch2hz=0;gyF.notch2cut=0 else gyF.notch2hz=400;gyF.notch2cut=300 end;gyWriteFilter()elseif k=='dynfeature'or k=='rpmfeature'then local bit=k=='dynfeature'and 29 or 30;gyFeature=bit32.bxor(gyFeature,2^bit);gyWriteFeature()end;gyBuildRows()end
function gyBool(k)if k=='lpfdyn'then return gyF.dynmin>0 and gyF.dynmin<gyF.dynmax elseif k=='notch1on'then return gyF.notch1hz>0 and gyF.notch1cut>0 elseif k=='notch2on'then return gyF.notch2hz>0 and gyF.notch2cut>0 elseif k=='dynfeature'then return gyFeatureOn(29)elseif k=='rpmfeature'then return gyFeatureOn(30)end end
function gyCommit(k,v)if string.sub(k,1,2)=='cq'then local src=tonumber(string.sub(k,3));gyBanks[gyAxis][src].q=v;gyWriteCustom(gyAxis)else gyF[k]=v;gyWriteFilter()end;gyBuildRows()end
function gyNumber(k,v,lo,hi,scale)numEdit={kind='gyro',index=k,text=scale and string.format('%.1f',v/scale)or tostring(v),original=scale and v/scale or v,min=scale and lo/scale or lo,max=scale and hi/scale or hi,error=nil,mode=activationSource=='roller'and'dial'or'direct'};if scale then numEdit.scale=scale;numEdit.decimals=1 end;activationSource='touch';numFocus=1 end
function gyChoose(k)local items,sel;if k=='rpmpreset'then items=gyPresets;sel=gyF[k]+1 else items=gyTypes;sel=gyF[k]+1 end;openChoice('SELECT '..string.upper(k),items,sel,function(v)gyF[k]=v;gyWriteFilter();gyBuildRows()end)end
function gyActivate(i)local r=gyRows[i];if not r or r[1]=='section'or r[1]=='info'then return end;gySel=i;if r[1]=='number'then gyNumber(r[3],gyF[r[3]],r[4],r[5],r[6])elseif r[1]=='choice'then gyChoose(r[3])elseif r[1]=='toggle'then gyToggle(r[3])elseif r[1]=='axis'then local items={{'ROLL',1},{'PITCH',2},{'YAW',3}};openChoice('SELECT RPM FILTER AXIS',items,gyAxis,function(v)gyAxis=v;gySel=1;gyScroll=1;gyBuildRows()end)elseif r[1]=='custom'then local d=gyBanks[gyAxis][r[3]];d.enabled=not d.enabled;gyWriteCustom(gyAxis);gyBuildRows()elseif r[1]=='ctype'then local src=r[3];local d=gyBanks[gyAxis][src];local multi=src==11 or src==12 or src==21 or src==22;local items=multi and{{'Single',1},{'Double',2},{'Triple',3}}or{{'Single',1}};openChoice('SELECT NOTCH TYPE',items,d.type,function(v)d.type=v;gyWriteCustom(gyAxis);gyBuildRows()end)elseif r[1]=='cq'then local d=gyBanks[gyAxis][r[3]];gyNumber('cq'..r[3],d.q,r[4],r[5],r[6])end end
function gySave()rf2.mspQueue:add({command=250,processReply=function()gyState='SAVED TO FC EEPROM'end,errorHandler=function()gyState='SAVE FAILED - DISARM FC'end})end
function gyRowValue(r)local k=r[3];if r[1]=='toggle'then return gyBool(k)and'ON'or'OFF'elseif r[1]=='choice'then local a=k=='rpmpreset'and gyPresets or gyTypes;return a[(gyF[k]or 0)+1][1]elseif r[1]=='number'then return r[6]and string.format('%.1f',gyF[k]/r[6])or tostring(gyF[k])elseif r[1]=='axis'then return({'ROLL','PITCH','YAW'})[gyAxis]elseif r[1]=='custom'then return gyBanks[gyAxis][r[3]].enabled and'ON'or'OFF'elseif r[1]=='ctype'then return({'Single','Double','Triple'})[gyBanks[gyAxis][r[3]].type]elseif r[1]=='cq'then return string.format('%.1f',gyBanks[gyAxis][r[3]].q/10)elseif r[1]=='info'then return r[3]end;return''end
function drawGyro()gyBuildRows();header('GYRO - EXPERT MODE',gyState);for i,n in ipairs(gyTabs)do local x=20+(i-1)*148;button('gyTab'..i,n,x,62,140,34,gyTab==i,{kind='gyTab',value=i},i==1 and'green'or(i==2 and'orange'or(i==3 and'purple'or'cyan')))end;local visible=6;if gySel<gyScroll then gyScroll=gySel elseif gySel>=gyScroll+visible then gyScroll=gySel-visible+1 end;gyScroll=math.max(1,math.min(math.max(1,#gyRows-visible+1),gyScroll));local y=104;for i=gyScroll,math.min(#gyRows,gyScroll+visible-1)do local r=gyRows[i];local sec=r[1]=='section';fill(20,y,712,44,sec and'panel2'or(gySel==i and'pid'or'panel'));box(20,y,712,44,gySel==i and'cyan'or'line');if sec then fill(20,y,8,44,'purple');txt(42,y+13,r[2],'cyan',true)else txt(34,y+13,r[2],'text');button('gyRow'..i,gyRowValue(r),500,y+5,212,34,gySel==i,{kind='gyRow',index=i},r[1]=='toggle'and'green'or'cyan')end;y=y+47 end;button('gyUp','^',748,105,32,34,false,{kind='gyScroll',delta=-3},'cyan');fill(758,145,10,210,'line');local th=math.max(24,math.floor(210*visible/math.max(visible,#gyRows)));local ty=145+math.floor((210-th)*(gyScroll-1)/math.max(1,#gyRows-visible));fill(753,ty,20,th,'orange');button('gyDown','v',748,364,32,34,false,{kind='gyScroll',delta=3},'cyan');button('gyRead','READ FC',20,405,150,36,false,{kind='gyRead'},'cyan');button('gySave','SAVE',178,405,150,36,false,{kind='gySave'},'orange');button('gyBack','< BACK',630,405,150,36,false,{kind='back'},'cyan');footer('Expert Mode. Changes apply immediately; SAVE writes EEPROM.')end

local fcInfo={state='NOT CHECKED',name='--',variant='--',version='--',api='--'}
local function textFromBytes(buf)local v='';for _,n in ipairs(buf or{})do if n==0 then break end;if n>=32 and n<=126 then v=v..string.char(n)end end;return v end
local function requestInfo()
 if not rfReady or fcInfo.state=='READING...' then return end
 fcInfo.state='READING...';local pending=4;local failed=false
 local function done()pending=pending-1;if pending==0 then fcInfo.state=failed and'PARTIAL / RETRY'or'CONNECTED'end end
 local function fail()failed=true;done()end
 rf2.mspQueue:add({command=1,processReply=function(_,b)if #b>=3 then fcInfo.api=tostring(b[2])..'.'..tostring(b[3]);rf2.apiVersion=b[2]+b[3]/100 else failed=true end;done()end,errorHandler=fail})
 rf2.mspQueue:add({command=2,processReply=function(_,b)local v=textFromBytes(b);fcInfo.variant=v~=''and v or'--';done()end,errorHandler=fail})
 rf2.mspQueue:add({command=3,processReply=function(_,b)if #b>=3 then fcInfo.version=tostring(b[1])..'.'..tostring(b[2])..'.'..tostring(b[3])else failed=true end;done()end,errorHandler=fail})
 rf2.mspQueue:add({command=10,processReply=function(_,b)local v=textFromBytes(b);fcInfo.name=v~=''and v or'(unnamed)';done()end,errorHandler=fail})
end
function requestHomeHardware()
 if not rfReady or homeHwBusy or not rf2.mspQueue:isProcessed()then return end;homeHwBusy=true;local pending=2;local function done()pending=pending-1;if pending<=0 then homeHwBusy=false end end
 statusApi.getStatus(function(_,d)homeHw.sensors=d and d.activeSensors or 0;done()end,done)
 dataflashApi.getDataflashSummary(function(_,d)d=d or{};homeHw.flashSupported=d.supported or false;homeHw.flashReady=d.ready or false;homeHw.flashTotal=d.totalSize or 0;homeHw.flashUsed=d.usedSize or 0;done()end,done)
end
function drawHomeHwIcon(x,label,bit,icon)
 local active=bit32.band(homeHw.sensors or 0,bit32.lshift(1,bit))~=0;local c=active and'cyan'or'muted';local y=342;fill(x,y,54,46,active and'panel2'or'panel');box(x,y,54,46,active and'cyan'or'line');local function ln(x1,y1,x2,y2)if lcd.drawLine then lcd.drawLine(sx(x1),sy(y1),sx(x2),sy(y2),col(c))end end
 if icon=='gyro'then ln(x+17,y+15,x+26,y+7);ln(x+26,y+7,x+35,y+15);ln(x+35,y+15,x+26,y+23);ln(x+26,y+23,x+17,y+15)
 elseif icon=='accel'then ln(x+27,y+5,x+27,y+25);ln(x+17,y+20,x+37,y+20);ln(x+27,y+5,x+23,y+10);ln(x+27,y+5,x+31,y+10)
 elseif icon=='mag'then ln(x+27,y+5,x+36,y+24);ln(x+36,y+24,x+18,y+24);ln(x+18,y+24,x+27,y+5);txt(x+24,y+11,'N',c,true)
 elseif icon=='baro'then box(x+23,y+5,8,18,c);fill(x+20,y+20,14,7,c)
 else box(x+22,y+9,11,11,c);ln(x+17,y+5,x+22,y+10);ln(x+33,y+19,x+38,y+24);ln(x+17,y+24,x+22,y+19);ln(x+33,y+10,x+38,y+5)end;txt(x+5,y+30,label,c,true)
end
function drawHomeHardware()
 drawHomeHwIcon(20,'GYRO',5,'gyro');drawHomeHwIcon(78,'ACCEL',0,'accel');drawHomeHwIcon(136,'MAG',2,'mag');drawHomeHwIcon(194,'BARO',1,'baro');drawHomeHwIcon(252,'GPS',3,'gps')
 local x,y,w=320,342,460;fill(x,y,w,46,'panel');box(x,y,w,46,homeHw.flashSupported and'cyan'or'line');local total=homeHw.flashTotal or 0;local used=math.min(total,homeHw.flashUsed or 0);local free=math.max(0,total-used);local function mb(v)return string.format('%.1fMB',v/1048576)end;local label=homeHw.flashSupported and('DATAFLASH FREE '..mb(free)..' / '..mb(total))or'DATAFLASH NOT AVAILABLE';txt(x+12,y+6,label,homeHw.flashSupported and'cyan'or'muted',true);fill(x+12,y+29,434,7,'bg');if total>0 then fill(x+12,y+29,434*used/total,7,'orange')end;box(x+12,y+29,434,7,'line');add('homeDataflash',x,y,w,46,{kind='homeFlashHold'})
end
function drawHomeFlashConfirm()
 hit={};fill(90,105,620,270,'panel');box(90,105,620,270,'red');fill(90,105,620,44,'red');txt(118,118,'ERASE DATAFLASH?','text',true);txt(120,178,'All Blackbox logs stored in onboard flash will be deleted.','orange',true);txt(120,216,'This action cannot be undone. Keep the FC powered.','text');txt(120,250,homeFlashState~=''and homeFlashState or'Long press detected. Confirm erase.','muted');button('flashNo','CANCEL',175,306,190,46,true,{kind='homeFlashNo'},'cyan');button('flashYes','ERASE',435,306,190,46,false,{kind='homeFlashYes'},'red')
end
local function drawHome()
 header('',fcInfo.state)
 if rfLogo and lcd.drawBitmap then lcd.drawBitmap(rfLogo,sx(18),sy(58))else drawRotorflightLogo(20,62);txt(62,69,'ROTORFLIGHT','cyan',true)end
 fill(194,58,586,52,'panel');box(194,58,586,52,fcInfo.state=='CONNECTED'and'cyan'or'line')
 txt(208,65,'Aircraft: '..fcInfo.name,'cyan');txt(208,88,'FC: '..fcInfo.variant..' '..fcInfo.version..'   MSP: '..fcInfo.api,'muted')
 button('refresh','Refresh',650,64,116,38,false,{kind='refresh'})
 for i,a in ipairs(home)do local n=i-1;local cc=n%4;local rr=math.floor(n/4);local x=20+cc*184;local y=124+rr*96;local active=selected==i;drawRoundTile(x,y,176,80,active and'blue'or'panel',active and'cyan'or'line',active);local k=a[3]=='easy'and'setup'or(a[3]=='options'and'configuration'or(a[3]=='exit'and'failsafe'or a[3]));drawFullIcon(k,x+12,y+11,active and'cyan'or'muted');local title=a[1];if title=='PROFILE FAST LINK'then txt(x+50,y+8,'PROFILE',active and'cyan'or'text',true);txt(x+50,y+27,'FAST LINK',active and'cyan'or'text',true)elseif title=='RATES FAST LINK'then txt(x+50,y+8,'RATES',active and'cyan'or'text',true);txt(x+50,y+27,'FAST LINK',active and'cyan'or'text',true)else txt(x+50,y+15,title,active and'cyan'or'text',true)end;local sc=(a[2]=='COMING SOON'or a[2]=='BETA TEST')and'orange'or(a[2]=='UNDER REPAIR'and'red'or'muted');txt(x+50,y+54,a[2],sc,true);add('home'..i,x,y,176,80,{kind='open',index=i})end
 drawHomeHardware();footer('Roller: select   ENTER: open   RTN: close')
end


local function beginNumber(kind,index,value,min,max)
 numEdit={kind=kind,index=index,text=tostring(value or 0),original=value or 0,min=min or -32768,max=max or 65535,error=nil,mode=activationSource=='roller'and'dial'or'direct'};activationSource='touch';numFocus=1
end
local function beginScaledNumber(kind,index,raw,minRaw,maxRaw,scale,preserveSign)
 scale=scale or 1;local a=minRaw/scale;local b=maxRaw/scale;local lo=math.min(a,b);local hi=math.max(a,b);local shown=raw/scale
 if preserveSign then shown=math.abs(shown);lo=0;hi=math.max(math.abs(a),math.abs(b))end
 beginNumber(kind,index,shown,lo,hi);numEdit.scale=scale;numEdit.preserveSign=preserveSign;numEdit.rawSign=raw<0 and-1 or 1;numEdit.originalRaw=raw;numEdit.decimals=1;numEdit.original=shown;numEdit.text=string.format('%.1f',shown)
end
local function mixerConfigScale(key)
 if key=='swash_trim_roll'or key=='swash_trim_pitch'or key=='swash_trim_collective'or key=='tail_center_trim'or key=='swash_phase'or key=='tail_motor_idle'then return 10 end
 if key=='swash_geo_correction'then return 5 end;if key=='swash_pitch_limit'then return 1000/12 end;return 1
end
local function mixerInputScale(axis,key)
 if key=='rate'then return 10,true end;if key=='max'and(axis==1 or axis==4)then return 1000/12,false end
 if axis==3 and key=='min'then return-1000/24,false end;if axis==3 and key=='max'then return 1000/24,false end;return 1,false
end
function rfLiveEditorRaw(e,v)
 local raw=v;if e.scale then raw=v*e.scale;if e.preserveSign then raw=math.abs(raw)*(e.rawSign or 1)end elseif e.kind~='mixoverride'then raw=v end
 return raw>=0 and math.floor(raw+.5)or math.ceil(raw-.5)
end
function rfQueueMixerRaw(kind,index,raw)
 if kind=='mixconfig'then mixerConfig[index].value=raw;mixerLiveConfig=true
 elseif kind=='mixinput'then local c=string.find(index,':');local ix=tonumber(string.sub(index,1,c-1));local key=string.sub(index,c+1);mixerInputs[ix][key]=raw;mixerInputs[ix].dirty=true;mixerLiveInputs[ix]=true;if ix==1 and mixerInputs[2]then mixerInputs[2][key]=key=='rate'and(mixerInputs[2].rate<0 and-math.abs(raw)or math.abs(raw))or raw;mixerInputs[2].dirty=true;mixerLiveInputs[2]=true end end
 mixerState='LIVE ON FC / NOT SAVED'
end
function rfPreviewNumber(v)
 if not numEdit or(numEdit.kind~='mixconfig'and numEdit.kind~='mixinput')then return end;rfQueueMixerRaw(numEdit.kind,numEdit.index,rfLiveEditorRaw(numEdit,v));numEdit.liveChanged=true
end
function rfCancelNumber()
 if not numEdit then return end;local e=numEdit;if e.liveChanged and e.originalRaw~=nil then rfQueueMixerRaw(e.kind,e.index,e.originalRaw)end;numEdit=nil
end
function rfFlushMixerLive()
 if not rfReady or not rf2.mspQueue:isProcessed()then return end
 if mixerLiveConfig then mixerLiveConfig=false;mixerApi.write(mixerConfig);return end
 for i=1,4 do if mixerLiveInputs[i]and mixerInputs[i]then mixerLiveInputs[i]=nil;local d=mixerInputs[i];local q={i};rf2.mspHelper.writeU16(q,d.rate);rf2.mspHelper.writeU16(q,d.min);rf2.mspHelper.writeU16(q,d.max);rf2.mspQueue:add({command=171,payload=q});return end end
end
local function commitNumber()
 if not numEdit then return end;local v=tonumber(numEdit.text);if not v then numEdit.error='Enter a valid number';return end
 v=math.max(numEdit.min,math.min(numEdit.max,v));if numEdit.scale then local raw=v*numEdit.scale;if numEdit.preserveSign then raw=math.abs(raw)*(numEdit.rawSign or 1)end;v=raw>=0 and math.floor(raw+.5)or math.ceil(raw-.5)elseif numEdit.kind~='mixoverride'and not(numEdit.kind=='easyServo'and numEdit.decimals==1)then v=v>=0 and math.floor(v+.5)or math.ceil(v-.5)end
 if numEdit.kind=='govField'then govCommitKey(numEdit.index,v)
 elseif numEdit.kind=='pid'then local k=pidMap[numEdit.index];pidData[k].value=v;pidDirty=true;pidState='CHANGED / NOT SAVED'
 elseif numEdit.kind=='override'then sendOverride(numEdit.index,v,true)
 elseif numEdit.kind=='mixconfig'then rfQueueMixerRaw('mixconfig',numEdit.index,v);dirtyMixer()
 elseif numEdit.kind=='mixinput'then rfQueueMixerRaw('mixinput',numEdit.index,v);dirtyMixer()
 elseif numEdit.kind=='mixoverride'then sendMixerOverride(numEdit.index,v,true)
 elseif numEdit.kind=='motorGear'then rfGearZ[numEdit.index]=v;rfGearCalculate();applyMotorLive()
 elseif numEdit.kind=='motorRatio'then if numEdit.index==2 then rfMainN=v elseif numEdit.index==3 then rfMainD=v elseif numEdit.index==4 then rfTailN=v else rfTailD=v end;motorDirty=true;rfGearDisplay();applyMotorLive()
 elseif numEdit.kind=='motorPole'then rfMotorPages[3][6][2]=tostring(v);motorConfig.poles[1]=v;motorDirty=true;rfGearDisplay();applyMotorLive()
 elseif numEdit.kind=='motorField'then motorConfig[numEdit.index]=v;motorDirty=true;rfMotorRefreshRows();applyMotorLive()
 elseif numEdit.kind=='escField'then escSensorConfig[numEdit.index].value=v;motorDirty=true;rfRefreshEscRows();rfApplyEscLive()
 elseif numEdit.kind=='easy'then easyCommitNumber(numEdit.index,v)
 elseif numEdit.kind=='easyTrim'then easyTrimCommitNumber(numEdit.index,v)
 elseif numEdit.kind=='easyServo'then easyServo.commit(numEdit.index,v)
 elseif numEdit.kind=='config'then cfgCommit(numEdit.index,v)
 elseif numEdit.kind=='receiver'then rxCommit(numEdit.index,v)
 elseif numEdit.kind=='failsafe'then fsCommit(numEdit.index,v)
 elseif numEdit.kind=='power'then pwCommit(numEdit.index,v)
 elseif numEdit.kind=='gyro'then gyCommit(numEdit.index,v)
 elseif numEdit.kind=='advanced'then if advanced then advanced.commit(numEdit.index,v)end
  elseif numEdit.kind=='govField'then govConfig[numEdit.index].value=v;govDirty=true;govState='LIVE / NOT SAVED';govApi.write(govConfig)
 else local si=math.floor((numEdit.index-1)/8);local fi=(numEdit.index-1)%8+1;servoData[si][servoFields[fi]].value=v;servoState='CHANGED / NOT SAVED'end
 local auto=saveMode==2;local kind=numEdit.kind;numEdit=nil;if auto then if kind=='pid'then savePid()elseif kind=='servo'then saveServos()elseif kind=='mixconfig'or kind=='mixinput'then saveAllMixer()elseif kind=='govField'then govSave()end end
end
local function panelValue(v)v=math.max(numEdit.min,math.min(numEdit.max,v));numEdit.text=numEdit.decimals==1 and string.format('%.1f',v)or tostring(v);numEdit.error=nil;rfPreviewNumber(v)end
local function numberAction(a)
 local v=tonumber(numEdit.text)or 0;local fast=5
 if a=='min'then panelValue(numEdit.min)elseif a=='def'then panelValue(numEdit.original)elseif a=='sign'then panelValue(-v)elseif a=='max'then panelValue(numEdit.max)
 elseif a=='fastdec'then panelValue(v-fast)elseif a=='dec'then panelValue(v-1)elseif a=='inc'then panelValue(v+1)elseif a=='fastinc'then panelValue(v+fast)
 elseif a=='input'then numEdit.mode='direct';numEdit.text='' elseif a=='cancel'then rfCancelNumber() elseif a=='ok'then commitNumber()end
end

local function directAction(a)
 if a=='back'then numEdit.mode='panel';if numEdit.text==''then numEdit.text=tostring(numEdit.original)end
 elseif a=='restore'then panelValue(numEdit.original)
 elseif a=='min'then panelValue(numEdit.min)
 elseif a=='max'then panelValue(numEdit.max)
 elseif a=='inc01'then panelValue((tonumber(numEdit.text)or 0)+0.1)
 elseif a=='dec01'then panelValue((tonumber(numEdit.text)or 0)-0.1)
 elseif a=='inc'then panelValue((tonumber(numEdit.text)or 0)+1)
 elseif a=='dec'then panelValue((tonumber(numEdit.text)or 0)-1)
 elseif a=='cancel'then rfCancelNumber()
 elseif a=='fastinc10'then panelValue((tonumber(numEdit.text)or 0)+10)
 elseif a=='fastdec10'then panelValue((tonumber(numEdit.text)or 0)-10)
 elseif a=='clear'then numEdit.text=''
 elseif a=='delete'then numEdit.text=string.sub(numEdit.text,1,math.max(0,#numEdit.text-1))
 elseif a=='sign'then if string.sub(numEdit.text,1,1)=='-'then numEdit.text=string.sub(numEdit.text,2)else numEdit.text='-'..numEdit.text end
 elseif a=='dot'then if not string.find(numEdit.text,'.',1,true)then numEdit.text=(numEdit.text==''or numEdit.text=='-')and(numEdit.text..'0.')or(numEdit.text..'.')end
 elseif a=='ok'then commitNumber()
 else if numEdit.text=='0'then numEdit.text=a else numEdit.text=numEdit.text..a end end;if numEdit then numEdit.error=nil end
end
local function drawDirectKeypad()
 fill(120,45,560,425,'panel');box(120,45,560,425,'cyan');txt(145,58,'ROTORFLIGHT VALUE / KEYPAD','cyan',true)
 fill(145,88,510,48,'bg');box(145,88,510,48,numEdit.error and'red'or'line');txt(340,102,numEdit.text==''and'_'or numEdit.text,'text',true)
 local keys={{'1','1'},{'2','2'},{'3','3'},{'4','4'},{'5','5'},{'6','6'},{'7','7'},{'8','8'},{'9','9'},{'+/-','sign'},{'0','0'},{'.','dot'}}
 for i,k in ipairs(keys)do local row=math.floor((i-1)/3);local col=(i-1)%3;button('d'..i,k[1],145+col*108,146+row*46,96,38,numFocus==i,{kind='direct',value=k[2]},(k[2]=='sign'or k[2]=='dot')and'orange'or'cyan')end
 button('dup01','+0.1',481,146,82,42,numFocus==13,{kind='direct',value='inc01'},'orange');button('ddown01','-0.1',573,146,82,42,numFocus==14,{kind='direct',value='dec01'},'cyan')
 button('dup1','+1.0',481,196,82,42,numFocus==15,{kind='direct',value='inc'},'orange');button('ddown1','-1.0',573,196,82,42,numFocus==16,{kind='direct',value='dec'},'cyan')
 button('ddel','DELETE',481,246,174,76,numFocus==17,{kind='direct',value='delete'})
 button('dmin','MIN',145,370,96,38,numFocus==18,{kind='direct',value='min'});button('drestore','RESTORE',253,370,110,38,numFocus==19,{kind='direct',value='restore'},'cyan');button('dmax','MAX',375,370,96,38,numFocus==20,{kind='direct',value='max'})
 button('dminus10','-10.0',145,418,96,38,numFocus==21,{kind='direct',value='fastdec10'},'orange');button('dclear','CLEAR',253,418,110,38,numFocus==22,{kind='direct',value='clear'},'cyan');button('dplus10','+10.0',375,418,96,38,numFocus==23,{kind='direct',value='fastinc10'},'orange')
 button('dcancel','Cancel',481,370,82,86,numFocus==24,{kind='direct',value='cancel'});button('dok','OK',573,370,82,86,numFocus==25,{kind='direct',value='ok'},'orange')
end
local function drawDialEditor()
 fill(145,105,510,255,'panel');box(145,105,510,255,'cyan');txt(180,128,'ROTORFLIGHT VALUE / DIAL','cyan',true)
 fill(180,175,440,72,'bg');box(180,175,440,72,numEdit.error and'red'or'orange');txt(370,196,numEdit.text,'text',true)
 txt(185,270,'Turn roller: - / + 1','muted');txt(185,300,'ENTER: confirm     RTN: restore / cancel','muted')
 button('dialMin','MIN',180,320,100,34,false,{kind='direct',value='min'});button('dialRestore','RESTORE',290,320,140,34,false,{kind='direct',value='restore'},'cyan');button('dialMax','MAX',440,320,100,34,false,{kind='direct',value='max'});button('dialOk','OK',550,310,70,44,true,{kind='direct',value='ok'},'orange')
end
local function drawKeypad()
 if numEdit.mode=='direct'then drawDirectKeypad();return elseif numEdit.mode=='dial'then drawDialEditor();return end
 fill(105,72,590,365,'panel');box(105,72,590,365,'cyan');txt(130,90,'ROTORFLIGHT VALUE','cyan',true)
 fill(130,126,540,58,'bg');box(130,126,540,58,'line');txt(340,143,numEdit.text,'text',true)
 local keys={{'MIN','min'},{'DEF','def'},{'+/-','sign'},{'MAX','max'},{'<<','fastdec'},{'-','dec'},{'+','inc'},{'>>','fastinc'}}
 for i,k in ipairs(keys)do local row=math.floor((i-1)/4);local col=(i-1)%4;button('n'..i,k[1],130+col*135,204+row*67,120,52,numFocus==i,{kind='numaction',value=k[2]},i>=5 and'orange'or'cyan')end
 button('input','KEYPAD',130,350,165,52,numFocus==9,{kind='numaction',value='input'});button('cancel','Cancel',307,350,165,52,numFocus==10,{kind='numaction',value='cancel'});button('ok','OK',484,350,186,52,numFocus==11,{kind='numaction',value='ok'},'orange')
 txt(130,412,'DEF = value read when opened    << / >> = '..'5','muted')
end

rfMotorTab=1;rfMotorFocus=1;rfMotorScroll=1
rfMotorTabs={'THROTTLE','ESC TELEMETRY','RPM & GEAR RATIO','ROTOR SPEED','THROTTLE OVERRIDE','MOTOR #1'}
rfMotorPages={
 {{'Throttle Protocol (ESC)','CASTLE'},{'Update Frequency [Hz]','100'},{'Live Update','OFF'},{'Motor Off [us]','934'},{'Low Throttle [us]','950'},{'High Throttle [us]','1917'}},
 {{'Voltage Correction [%]','0.0'},{'Current Correction [%]','0.0'},{'Consumption Correction [%]','0.0'}},
 {},
 {{'Main Rotor','0 RPM'},{'Tail Rotor','0 RPM'}},
 {{'Throttle Override Enable','OFF'},{'Live Update','OFF'},{'Override Output [%]','0.0'},{'Rotor Speed','MAIN 0 RPM   |   TAIL 0 RPM'},{'RPM','0 RPM'},{'Voltage','0.00 V'},{'Current','0.00 A'},{'Temperature 1','0.0 C'},{'Temperature 2','0.0 C'}},
 {{'RPM','0 RPM'},{'Voltage','0.00 V'},{'Current','0.00 A'},{'Temperature 1','0.0 C'},{'Temperature 2','0.0 C'}}
}
rfGearModels={
 {'SAB Goblin 500 Sport',1,18,48,18,62,28,21},{'SAB Black Thunder 700',1,21,60,19,68,37,26},{'SAB Kraken 580',1,22,50,14,58,27,23},{'SAB Kraken 700',1,21,56,18,69,34,27},{'SAB Raw 580',1,22,50,14,58,27,23},{'SAB Raw 580 Nitro',1,26,50,14,58,27,23},{'SAB Raw 700',1,21,56,18,69,34,26},{'SAB Raw 700 Nitro',1,27,52,14,58,27,22},{'SAB Raw 700 Piuma',1,20,52,14,58,27,22},{'SAB ilGoblin 700',1,21,56,18,68,34,26},{'SAB ilGoblin 700 SUT',1,21,56,18,68,34,25},{'ALIGN TB40 Top Combo',1,21,40,13,46,25,22},{'ALIGN TB60 Top Combo',1,21,44,15,62,27,23},{'ALIGN TB60 Super Combo',1,21,44,15,62,28,23},{'ALIGN TB70 Top Combo',1,21,50,15,62,27,23},{'ALIGN TB70 Super Combo',1,21,50,15,62,28,23},{'KDS Agile A5',2,21,54,17,66,57,14},{'KDS Agile 7.2',2,21,54,20,66,57,12},{'KDS Agile A7',2,21,54,20,66,57,12},{'Align TN70',2,27,30,16,107,102,23},{'Gaui Hurricane',3,13,42,19,61,14,9,9},{'CUSTOM',0,12,120,0,0,0,1,0}
}
rfGearModel=10;rfGearZ={21,56,18,68,34,26,0};rfRpmSensor=true;rfMainN=378;rfMainD=3808;rfTailN=468;rfTailD=2312
motorConfig=nil;motorFeature=nil;escSensorConfig=nil;motorState='NOT READ';motorDirty=false;rfMotorLive=false
rfMotorOverrideOn=false;rfMotorOverridePct=0;rfMotorGaugeEdit=false;rfMotorDrag=false;rfMotorLastX=nil;rfMotorKeepAliveAt=-1000
rfMotorTelemetry={};rfMotorTelemetryAt=-1000
function rfRatioText(n,d)
 if not n or n==0 then return 'N/A'end;local v=d/n;if math.abs(v-math.floor(v+.5))<0.00005 then return '1 : '..tostring(math.floor(v+.5))end;local q=string.format('%.4f',v);q=string.gsub(q,'0+$','');q=string.gsub(q,'[.]$','');return '1 : '..q
end
function applyMotorLive()
 if not motorConfig or not motorApi then return end;motorConfig.mainRatio={rfMainN,rfMainD};motorConfig.tailRatio={rfTailN,rfTailD};motorApi.write(motorConfig)
 if motorFeature then local mask=2^30;local on=bit32.band(motorFeature.bitfield,mask)~=0;if rfRpmSensor and not on then motorFeature.bitfield=motorFeature.bitfield+mask elseif not rfRpmSensor and on then motorFeature.bitfield=motorFeature.bitfield-mask end;local q={};rf2.mspHelper.writeU32(q,motorFeature.bitfield);rf2.mspQueue:add({command=37,payload=q})end
 motorState='LIVE ON FC / NOT SAVED'
end
function rfGearDisplay()
 local m=rfGearModels[rfGearModel];local t=m[2];local p={{'RPM Sensor',rfRpmSensor and'ON'or'OFF'},{'Main Rotor Gear Ratio A',tostring(rfMainN)},{'Main Rotor Gear Ratio B',tostring(rfMainD)},{'Tail Rotor Gear Ratio A',tostring(rfTailN)},{'Tail Rotor Gear Ratio B',tostring(rfTailD)},{'Main Motor Pole Count',tostring(motorConfig and motorConfig.poles[1]or 10)},{'Aircraft Reference',m[1]}}
 if t~=0 then p[#p+1]={'Motor Pinion (T)',tostring(rfGearZ[1])};p[#p+1]={'Main Gear (T)',tostring(rfGearZ[2])};p[#p+1]={'Tail Pulley (T)',tostring(t==3 and rfGearZ[7]or rfGearZ[6])};p[#p+1]={'Calculated Main Ratio',rfRatioText(rfMainN,rfMainD)};p[#p+1]={'Calculated Tail Ratio',rfRatioText(rfTailN,rfTailD)};p[#p+1]={'Restore Aircraft Default','PRESS ENTER'}end
 rfMotorPages[3]=p;if motorConfig then motorConfig.mainRatio={rfMainN,rfMainD};motorConfig.tailRatio={rfTailN,rfTailD};motorConfig.poles[1]=tonumber(p[6][2])or 10 end
end
function rfGearCalculate()
 local z=rfGearZ;local t=rfGearModels[rfGearModel][2]
 if t==0 then rfMainN,rfMainD=z[1],z[2]
 else rfMainN,rfMainD=z[1]*z[3],z[2]*z[4];if t==1 then rfTailN,rfTailD=z[3]*z[6],z[4]*z[5]elseif t==2 then rfTailN,rfTailD=z[6],z[5]else rfTailN,rfTailD=z[5]*z[7],z[4]*z[6]end end
 motorDirty=true;motorState='CHANGED / PRESS SAVE';rfGearDisplay()
end
function rfGearLoad(i)local m=rfGearModels[i];rfGearModel=i;for n=1,7 do rfGearZ[n]=m[n+2]or 0 end;rfGearCalculate();applyMotorLive()end
function rfGearChoice()local q={};for i,m in ipairs(rfGearModels)do q[i]={m[1],i}end;openChoice('SELECT AIRCRAFT',q,rfGearModel,function(v)rfGearLoad(v)end)end
rfEscProtocols={'Disabled','BLHeli32','Hobbywing Platinum V4 / FlyFun V5','Hobbywing Platinum V5','Scorpion','Kontronik','OMPHobby','ZTW','APD','OpenYGE','FLYROTOR','Graupner','XDFLY','FrSky F.BUS'}
function rfRefreshEscRows()
 if not escSensorConfig then rfMotorPages[2]={{'Telemetry Protocol','READ FC','protocol'}};return end
 local c=escSensorConfig;local proto=c.protocol.value or 0;local p={{'Telemetry Protocol',rfEscProtocols[proto+1]or tostring(proto),'protocol'}}
 if proto>0 then p[#p+1]={'Half Duplex',(c.half_duplex.value or 0)>0 and'ON'or'OFF','half_duplex'};if c.pin_swap then p[#p+1]={'Pin Swap',(c.pin_swap.value or 0)>0 and'ON'or'OFF','pin_swap'}end;if c.voltage_correction then p[#p+1]={'Voltage Correction [%]',tostring(c.voltage_correction.value or 0),'voltage_correction'};p[#p+1]={'Current Correction [%]',tostring(c.current_correction.value or 0),'current_correction'};p[#p+1]={'Consumption Correction [%]',tostring(c.consumption_correction.value or 0),'consumption_correction'}end end
 if motorConfig and motorConfig.protocol==9 then p={};if c.voltage_correction then p={{'Voltage Correction [%]',tostring(c.voltage_correction.value or 0),'voltage_correction'},{'Current Correction [%]',tostring(c.current_correction.value or 0),'current_correction'},{'Consumption Correction [%]',tostring(c.consumption_correction.value or 0),'consumption_correction'}}end end
 rfMotorPages[2]=p
end
function rfApplyEscLive()if escSensorConfig and escSensorApi then escSensorApi.write(escSensorConfig);motorState='ESC TELEMETRY LIVE / NOT SAVED'end end
function rfMotorRefreshRows()
 if not motorConfig then return end;local names={[0]='PWM','ONESHOT125','ONESHOT42','MULTISHOT','BRUSHED','DSHOT150','DSHOT300','DSHOT600','PROSHOT','CASTLE','DISABLED'};local proto=motorConfig.protocol;local p={{'Throttle Protocol (ESC)',names[proto]or tostring(proto),'protocol'}};local dshot=proto>=5 and proto<=8;local enabled=proto~=10;if enabled and not dshot then p[#p+1]={'Update Frequency [Hz]',tostring(motorConfig.rate),'rate'};if proto~=0 and proto~=9 then p[#p+1]={'Unsynced PWM',motorConfig.unsynced>0 and'ON'or'OFF','unsynced'}end;p[#p+1]={'Live Update',rfMotorLive and'ON'or'OFF','live'};p[#p+1]={'Motor Off [us]',tostring(motorConfig.minCommand),'minCommand'};p[#p+1]={'Low Throttle [us]',tostring(motorConfig.minThrottle),'minThrottle'};p[#p+1]={'High Throttle [us]',tostring(motorConfig.maxThrottle),'maxThrottle'}end;rfMotorPages[1]=p;rfRefreshEscRows();rfGearDisplay()
end
function requestMotor()
 if not rfReady or not motorApi then return end;motorState='READING FC...';local gotM,gotF=false,false;local function done()if gotM and gotF then motorState=motorConfig and'CONNECTED / READY'or'READ ERROR'end end
 motorApi.read(function(_,d)motorConfig=d;gotM=true;if d then if(d.motorCount or 1)>1 then for i=10,14 do rfMotorPages[5][i]={'Motor #2 Monitor','LIVE'}end else for i=#rfMotorPages[5],10,-1 do rfMotorPages[5][i]=nil end end;rfGearModel=#rfGearModels;rfMainN,rfMainD=d.mainRatio[1],d.mainRatio[2];rfTailN,rfTailD=d.tailRatio[1],d.tailRatio[2];rfMotorRefreshRows()end;done()end,nil,motorConfig)
 featureApi.getFeatureConfig(function(_,d)motorFeature=d;rfRpmSensor=d and bit32.band(d.bitfield,2^30)~=0or false;gotF=true;rfGearDisplay();done()end,nil);escSensorConfig=escSensorApi.getDefaults();escSensorApi.read(function(_,d)escSensorConfig=d;rfRefreshEscRows()end,nil,escSensorConfig)
end
function saveMotor()
 if not motorConfig then motorState='READ FC FIRST';return end;motorState='SAVING...';motorApi.write(motorConfig)
 if motorFeature then local mask=2^30;local on=bit32.band(motorFeature.bitfield,2^30)~=0;if rfRpmSensor and not on then motorFeature.bitfield=motorFeature.bitfield+mask elseif not rfRpmSensor and on then motorFeature.bitfield=motorFeature.bitfield-mask end;local q={};rf2.mspHelper.writeU32(q,motorFeature.bitfield);rf2.mspQueue:add({command=37,payload=q})end
 if escSensorConfig then escSensorApi.write(escSensorConfig)end
 rf2.mspQueue:add({command=250,processReply=function()motorDirty=false;motorState='SAVED TO FC EEPROM'end,errorHandler=function()motorState='APPLIED / SAVE REQUIRES DISARM'end})
end
function rfRequestMotorTelemetry()
 if not rfReady then return end;rf2.mspQueue:add({command=139,processReply=function(_,buf)local count=rf2.mspHelper.readU8(buf);local d={};for i=1,count do d[i]={rpm=rf2.mspHelper.readU32(buf),error=rf2.mspHelper.readU16(buf),voltage=rf2.mspHelper.readU16(buf),current=rf2.mspHelper.readU16(buf),consumption=rf2.mspHelper.readU16(buf),temp1=rf2.mspHelper.readU16(buf),temp2=rf2.mspHelper.readU16(buf)}end;rfMotorTelemetry=d;local m=d[1]or{};local motorRpm=m.rpm or 0;local main=rfMainD>0 and math.floor(motorRpm*rfMainN/rfMainD+.5)or 0;local tail;if count>1 then tail=(d[2]and d[2].rpm)or 0 else tail=rfTailD>0 and math.floor(motorRpm*rfTailN/rfTailD+.5)or 0 end;rfMotorPages[4][1][2]=tostring(main)..' RPM';rfMotorPages[4][2][2]=tostring(tail)..' RPM';rfMotorPages[6][1][2]=tostring(motorRpm)..' RPM';rfMotorPages[6][2][2]=string.format('%.2f V',(m.voltage or 0)/1000);rfMotorPages[6][3][2]=string.format('%.2f A',(m.current or 0)/1000);rfMotorPages[6][4][2]=string.format('%.1f C',(m.temp1 or 0)/10);rfMotorPages[6][5][2]=string.format('%.1f C',(m.temp2 or 0)/10)end})
end
function rfMotor2Present()return motorConfig and(motorConfig.motorCount or 1)>1 end
function rfTlmText(m,key)local v=(m and m[key])or 0;if key=='rpm'then return tostring(v)..' RPM'elseif key=='voltage'then return string.format('%.2f V',v/1000)elseif key=='current'then return string.format('%.2f A',v/1000)else return string.format('%.1f C',v/10)end end
function rfSendMotorOverride(pct,on,quiet)
 pct=math.max(0,math.min(100,tonumber(pct)or 0));local raw=on and math.floor(pct*10+.5)or 0;local q={0};rf2.mspHelper.writeU16(q,raw);rf2.mspQueue:add({command=195,payload=q});rfMotorOverridePct=pct;rfMotorOverrideOn=on;rfMotorKeepAliveAt=getTime and getTime()or 0;rfMotorPages[5][1][2]=on and'ON'or'OFF';rfMotorPages[5][3][2]=string.format('%.1f',pct);if not quiet then motorState=on and'THROTTLE OVERRIDE ACTIVE'or'THROTTLE OVERRIDE OFF'end
end
function rfDrawOnOff(id,on,y,kind)
 button(id..'off','OFF',526,y,92,36,not on,{kind=kind,value=false},'cyan');button(id..'on','ON',628,y,92,36,on,{kind=kind,value=true},'cyan')
end
function rfDrawThrottleOverride()
 local maxRow=rfMotor2Present()and 14 or 9;local row=math.max(1,math.min(maxRow,rfMotorFocus-6));local section=row<=3 and 1 or(row<=6 and 2 or(row<=9 and 3 or 4));rfMotorScroll=section;local y=184
 fill(20,y,710,30,'panel');box(20,y,710,30,'orange');txt(34,y+6,'WARNING: THROTTLE OVERRIDE CAN SPOOL UP MOTOR','orange',true);y=y+35
 if section==1 then
  fill(20,y,710,38,'panel2');box(20,y,710,38,row==1 and'orange'or'line');txt(34,y+9,'Throttle Override Enable','text');rfDrawOnOff('motorOverride',rfMotorOverrideOn,y+1,'motorOverrideSet');y=y+42
  if not rfMotorOverrideOn then fill(20,y,710,94,'panel2');box(20,y,710,94,'line');txt(34,y+20,'Select ON to show Live Update, output slider and live motor data.','muted');txt(34,y+50,'Motor override output is disabled.','cyan',true);button('motorRead','READ FC',360,402,125,36,rfMotorFocus==8,{kind='motorControl',value='read'},'cyan');button('motorSave','SAVE FC',495,402,125,36,rfMotorFocus==9,{kind='motorControl',value='save'},'orange');button('motorBack','< BACK',650,402,130,36,rfMotorFocus==10,{kind='back'});footer('Turn Override ON to open the remaining controls.');return end
  fill(20,y,710,38,'panel2');box(20,y,710,38,row==2 and'orange'or'line');txt(34,y+9,'Live Update','text');rfDrawOnOff('overrideLive',rfMotorLive,y+1,'motorLiveSet');y=y+42
  fill(20,y,710,100,'panel2');box(20,y,710,100,row==3 and'orange'or'line');txt(34,y+7,'Motor #1  -  '..string.format('%.1f%%',rfMotorOverridePct),'cyan',true)
  button('motorOvl','<',34,y+35,42,36,false,{kind='motorOverrideStep',delta=-1},'cyan');fill(90,y+50,570,7,'line');if rfMotorGaugeEdit then box(84,y+29,582,43,'orange')end;local kx=90+math.floor(rfMotorOverridePct*570/100);fill(kx-6,y+36,12,31,'orange')
  for n=0,10 do local tx=90+math.floor(n*570/10);fill(tx,y+56,1,n%5==0 and 8 or 4,'muted');txt(tx-(n==10 and 14 or 5),y+72,tostring(n*10),'muted')end
  add('motorOvg',84,y+29,582,47,{kind='motorOverrideSlider'});button('motorOvr','>',674,y+35,42,36,false,{kind='motorOverrideStep',delta=1},'cyan')
 elseif section==2 then
  local rs=rfMotorPages[4];local m=rfMotorPages[6]
  fill(20,y,710,42,'panel2');box(20,y,710,42,row==4 and'orange'or'line');txt(34,y+11,'Rotor Speed','cyan',true);txt(250,y+11,'MAIN '..rs[1][2]..'   |   TAIL '..rs[2][2],'text');y=y+47
  for i=5,7 do local q=m[i-4];fill(20,y,710,42,'panel2');box(20,y,710,42,row==i and'orange'or'line');txt(34,y+11,q[1],'text');txt(570,y+11,q[2],'cyan');y=y+47 end
 elseif section==3 then
  local m=rfMotorPages[6];for i=8,9 do local q=m[i-4];fill(20,y,710,52,'panel2');box(20,y,710,52,row==i and'orange'or'line');txt(34,y+16,q[1],'text');txt(570,y+16,q[2],'cyan');y=y+57 end
  fill(20,y,710,48,'panel');box(20,y,710,48,'line');txt(34,y+9,'Motor #1 live monitor','cyan',true);txt(34,y+29,'RPM, voltage, current and temperatures update from FC telemetry.','muted')
 else
  local m=rfMotorTelemetry[2]or{};local q={{'RPM',rfTlmText(m,'rpm')},{'Voltage',rfTlmText(m,'voltage')},{'Current',rfTlmText(m,'current')},{'Temperature 1',rfTlmText(m,'temp1')},{'Temperature 2',rfTlmText(m,'temp2')}};for i=1,5 do local yy=y+(i-1)*38;fill(20,yy,710,34,'panel2');box(20,yy,710,34,row==i+9 and'orange'or'line');txt(34,yy+8,i==1 and'Motor #2  '..q[i][1]or q[i][1],i==1 and'cyan'or'text');txt(570,yy+8,q[i][2],'cyan')end
 end
 local pages=rfMotor2Present()and 4 or 3;txt(662,378,tostring(section)..' / '..tostring(pages),'muted');button('moup','^',738,184,42,42,false,{kind='motorOverrideScroll',delta=-1},'cyan');button('modown','v',738,340,42,42,false,{kind='motorOverrideScroll',delta=1},'cyan')
 button('motorRead','READ FC',360,402,125,36,rfMotorFocus==16,{kind='motorControl',value='read'},'cyan');button('motorSave','SAVE FC',495,402,125,36,rfMotorFocus==17,{kind='motorControl',value='save'},'orange');button('motorBack','< BACK',650,402,130,36,rfMotorFocus==18,{kind='back'});footer('Swipe or turn roller to view all override and live motor data.')
end
function rfMotorActivateRow(i)
 if rfMotorTab==1 then if not motorConfig then motorState='READ FC FIRST';return end;local r=rfMotorPages[1][i];local k=r and r[3];if k=='protocol'then local names={'PWM','ONESHOT125','ONESHOT42','MULTISHOT','BRUSHED','DSHOT150','DSHOT300','DSHOT600','PROSHOT','CASTLE','DISABLED'};local q={};for n,v in ipairs(names)do q[n]={v,n-1}end;openChoice('THROTTLE PROTOCOL',q,motorConfig.protocol+1,function(v)motorConfig.protocol=v;if v==9 and escSensorConfig then escSensorConfig.protocol.value=0 end;motorDirty=true;rfMotorRefreshRows();applyMotorLive();rfApplyEscLive()end)elseif k=='live'then rfMotorLive=not rfMotorLive;rfMotorRefreshRows()elseif k=='unsynced'then motorConfig.unsynced=motorConfig.unsynced>0 and 0 or 1;motorDirty=true;rfMotorRefreshRows();applyMotorLive()elseif k then beginNumber('motorField',k,motorConfig[k],k=='rate'and 50 or 50,k=='rate'and 8000 or 2250)end;return end
 if rfMotorTab==2 then if not escSensorConfig then motorState='READ FC FIRST';return end;local r=rfMotorPages[2][i];local k=r and r[3];if k=='protocol'then local q={};for n,v in ipairs(rfEscProtocols)do q[n]={v,n-1}end;openChoice('ESC TELEMETRY PROTOCOL',q,(escSensorConfig.protocol.value or 0)+1,function(v)escSensorConfig.protocol.value=v;motorDirty=true;rfRefreshEscRows();rfApplyEscLive()end)elseif k=='half_duplex'or k=='pin_swap'then escSensorConfig[k].value=escSensorConfig[k].value>0 and 0 or 1;motorDirty=true;rfRefreshEscRows();rfApplyEscLive()elseif k then beginNumber('escField',k,escSensorConfig[k].value,-100,125)end;return end
 if rfMotorTab==5 then if i==1 then rfSendMotorOverride(rfMotorOverridePct,not rfMotorOverrideOn)elseif i==2 then rfMotorLive=not rfMotorLive;rfMotorRefreshRows();rfMotorPages[5][2][2]=rfMotorLive and'ON'or'OFF' elseif i==3 then if rfMotorOverrideOn then rfMotorGaugeEdit=not rfMotorGaugeEdit else motorState='TURN OVERRIDE ON FIRST'end end;return end
 if rfMotorTab~=3 then return end;local t=rfGearModels[rfGearModel][2];if i==1 then openChoice('RPM SENSOR',{{'OFF',false},{'ON',true}},rfRpmSensor and 2 or 1,function(v)rfRpmSensor=v;motorDirty=true;rfGearDisplay();applyMotorLive()end)elseif i>=2 and i<=5 then beginNumber('motorRatio',i,tonumber(rfMotorPages[3][i][2]),1,65535)elseif i==6 then beginNumber('motorPole',6,tonumber(rfMotorPages[3][6][2])or 10,2,100)elseif i==7 then rfGearChoice()elseif t~=0 and i==8 then beginNumber('motorGear',1,rfGearZ[1],1,1000)elseif t~=0 and i==9 then beginNumber('motorGear',2,rfGearZ[2],1,1000)elseif t~=0 and i==10 then beginNumber('motorGear',t==3 and 7 or 6,rfGearZ[t==3 and 7 or 6],1,1000)elseif t~=0 and i==13 then rfGearLoad(rfGearModel)end
end
rfGearDisplay()
function rfMotorTopButton(i,x,y,w)
 local active=rfMotorTab==i;button('motab'..i,rfMotorTabs[i],x,y,w,34,active,{kind='motorTopTab',value=i},i==5 and'orange'or'cyan')
end
function rfDrawRpmGear()
 local p=rfMotorPages[3];local detail=rfGearModels[rfGearModel][2]~=0;local row=rfMotorFocus-6;local showDetail=detail and(row>7 or rfMotorScroll>1);local y=184
 if not showDetail then
  fill(20,y,710,42,'panel2');box(20,y,710,42,row==1 and'orange'or'line');txt(34,y+11,'RPM Sensor','text');rfDrawOnOff('rpmSensor',rfRpmSensor,y+3,'rpmSensorSet');y=y+46
  fill(20,y,710,36,'panel2');box(20,y,710,36,(row==2 or row==3)and'orange'or'line');txt(34,y+9,'Main Rotor Gear Ratio','text');txt(300,y+9,rfRatioText(rfMainN,rfMainD),'cyan');button('morow2',p[2][2],455,y+2,110,32,row==2,{kind='motorRow',value=2},'cyan');txt(574,y+9,':','muted');button('morow3',p[3][2],595,y+2,125,32,row==3,{kind='motorRow',value=3},'cyan');y=y+40
  fill(20,y,710,36,'panel2');box(20,y,710,36,(row==4 or row==5)and'orange'or'line');txt(34,y+9,'Tail Rotor Gear Ratio','text');txt(300,y+9,rfRatioText(rfTailN,rfTailD),'cyan');button('morow4',p[4][2],455,y+2,110,32,row==4,{kind='motorRow',value=4},'cyan');txt(574,y+9,':','muted');button('morow5',p[5][2],595,y+2,125,32,row==5,{kind='motorRow',value=5},'cyan');y=y+40
  fill(20,y,710,36,'panel2');box(20,y,710,36,row==6 and'orange'or'line');txt(34,y+9,'Main Motor Pole Count','text');button('morow6',p[6][2],570,y+2,150,32,row==6,{kind='motorRow',value=6},'cyan');y=y+40
  fill(20,y,710,36,'panel2');box(20,y,710,36,row==7 and'orange'or'line');txt(34,y+9,'Aircraft Reference','text');button('morow7',p[7][2],360,y+2,360,32,row==7,{kind='motorRow',value=7},'cyan')
 else local first=math.max(8,math.min(#p-3,row));local last=math.min(#p,first+3);for i=first,last do local r=p[i];fill(20,y,710,42,'panel2');box(20,y,710,42,row==i and'orange'or'line');txt(34,y+11,r[1],'text');button('morow'..i,r[2],500,y+3,220,36,row==i,{kind='motorRow',value=i},'cyan');y=y+47 end end
 if detail then button('moup','^',738,184,42,42,false,{kind='motorScroll',delta=-1},'cyan');button('modown','v',738,340,42,42,false,{kind='motorScroll',delta=1},'cyan')end
 button('motorRead','READ FC',360,402,125,36,rfMotorFocus==7+#p,{kind='motorControl',value='read'},'cyan');button('motorSave','SAVE FC',495,402,125,36,rfMotorFocus==8+#p,{kind='motorControl',value='save'},'orange');button('motorBack','< BACK',650,402,130,36,rfMotorFocus==9+#p,{kind='back'});footer('Ratio A : B is stored in FC. Calculated result is shown at left.')
end
function rfDrawMotor()
 header('MOTORS',motorState)
 rfMotorTopButton(1,20,96,245);rfMotorTopButton(2,277,96,245);rfMotorTopButton(3,534,96,246)
 rfMotorTopButton(4,20,138,245);rfMotorTopButton(5,277,138,245);rfMotorTopButton(6,534,138,246)
 if rfMotorTab==3 then rfDrawRpmGear();return elseif rfMotorTab==5 then rfDrawThrottleOverride();return end
 local rows=rfMotorPages[rfMotorTab];local y=184;local visible=4
 if rfMotorTab==1 then fill(20,y,710,34,'panel');box(20,y,710,34,'orange');txt(34,y+8,'WARNING: Incorrect throttle range can start the motor.','orange');y=y+42;visible=3
 elseif rfMotorTab==5 then fill(20,y,710,54,'panel');box(20,y,710,54,'orange');txt(34,y+8,'DANGER: THROTTLE OVERRIDE CAN SPOOL UP MOTOR','orange',true);txt(34,y+31,'Remove blades and secure the model before use.','muted');y=y+62;visible=3 end
 local rowFocus=rfMotorFocus-6;if rowFocus>=1 and rowFocus<=#rows then if rowFocus<rfMotorScroll then rfMotorScroll=rowFocus elseif rowFocus>=rfMotorScroll+visible then rfMotorScroll=rowFocus-visible+1 end end
 local last=math.min(#rows,rfMotorScroll+visible-1)
 for i=rfMotorScroll,last do local r=rows[i];local selected=rfMotorFocus==6+i;fill(20,y,710,42,'panel2');box(20,y,710,42,selected and'orange'or'line');txt(34,y+11,r[1],selected and'cyan'or'text');if rfMotorTab==1 and r[3]=='live'then rfDrawOnOff('liveUpdate',rfMotorLive,y+3,'motorLiveSet')elseif rfMotorTab==1 and r[3]=='unsynced'then rfDrawOnOff('unsyncedPwm',motorConfig and motorConfig.unsynced>0,y+3,'motorUnsyncedSet')elseif rfMotorTab==2 and(r[3]=='half_duplex'or r[3]=='pin_swap')then rfDrawOnOff('esc'..r[3],escSensorConfig and escSensorConfig[r[3]].value>0,y+3,'escToggleSet')else button('morow'..i,r[2],500,y+3,220,36,selected,{kind='motorRow',value=i},rfMotorTab==5 and'orange'or'cyan')end;y=y+47 end
 if #rows>visible then local maxScroll=math.max(1,#rows-visible+1);rfMotorScroll=math.max(1,math.min(maxScroll,rfMotorScroll));txt(650,389,rfMotorScroll..' / '..maxScroll,'muted');button('moup','^',738,184,42,42,false,{kind='motorScroll',delta=-1},'cyan');fill(752,232,8,100,'line');local thumbH=math.max(24,math.floor(100*visible/#rows));local thumbY=232+math.floor((100-thumbH)*(rfMotorScroll-1)/math.max(1,maxScroll-1));fill(748,thumbY,16,thumbH,'cyan');for pos=1,maxScroll do local py=232+math.floor((pos-1)*100/maxScroll);local ph=math.max(12,math.floor(100/maxScroll));add('motrack'..pos,738,py,42,ph,{kind='motorScrollTo',value=pos})end;button('modown','v',738,340,42,42,false,{kind='motorScroll',delta=1},'cyan')end
 button('motorRead','READ FC',360,402,125,36,rfMotorFocus==7+#rows,{kind='motorControl',value='read'},'cyan');button('motorSave','SAVE FC',495,402,125,36,rfMotorFocus==8+#rows,{kind='motorControl',value='save'},'orange');button('motorBack','< BACK',650,402,130,36,rfMotorFocus==9+#rows,{kind='back'});footer('Changes apply to FC RAM. SAVE writes configuration to EEPROM.')
end

function rfGovReadRxSetup()
 if not rfReady then return end
 rf2.mspQueue:add({command=44,processReply=function(_,b)b.offset=4;govRxMin=rf2.mspHelper.readU16(b);govRxMax=rf2.mspHelper.readU16(b)end})
 rf2.mspQueue:add({command=64,processReply=function(_,b)for i=1,8 do govRcMap[i]=rf2.mspHelper.readU8(b)end end})
 rf2.mspQueue:add({command=66,processReply=function(_,b)govRcCenter=rf2.mspHelper.readU16(b);govRcDeflection=rf2.mspHelper.readU16(b);b.offset=b.offset+2;govRcLow=rf2.mspHelper.readU16(b);govRcHigh=rf2.mspHelper.readU16(b)end})
end
function rfGovReadThrottle()
 if not rfReady then return end;rf2.mspQueue:add({command=114,processReply=function(_,b)local ch=(govRcMap[5]or 4);local o=ch*2+1;if b[o]and b[o+1]then govThrottlePwm=bit32.bor(b[o],bit32.lshift(b[o+1],8))end end});rf2.mspQueue:add({command=113,processReply=function(_,b)local o=7;if b[o]and b[o+1]then local v=bit32.bor(b[o],bit32.lshift(b[o+1],8));if v>=32768 then v=v-65536 end;govThrottleCommand=math.max(-1000,math.min(1000,v))end end})
end
function rfGovDrawThrottlePreview()
 local x,y,w,h=28,170,704,28;local mn=govRxMin or 1000;local mx=govRxMax or 2000;if mx<=mn then mx=mn+1000 end;local lo=(govRcLow or 0)>0 and govRcLow or(govRcCenter-govRcDeflection*.9);local hi=(govRcHigh or 0)>0 and govRcHigh or(govRcCenter+govRcDeflection*.9);local off=lo-5;local mode=govConfig and(govConfig.gov_mode.value or 0)or 0;local typ=govConfig and(govConfig.gov_throttle_type.value or 0)or 0
 local ranges;if mode==0 or(mode==1 and typ==0)then ranges={{mn,off,'OFF','red'},{off,mx,'RUN','green'}}elseif typ==2 then local idle=lo+(hi-lo)*.333;local auto=lo+(hi-lo)*.666;ranges={{mn,off,'OFF','red'},{off,idle,'IDLE','orange'},{idle,auto,'AUTO','purple'},{auto,mx,'RUN','green'}}else local auto=lo+(hi-lo)*((govConfig.gov_auto_throttle.value or 0)/1000);local hand=lo+(hi-lo)*((govConfig.gov_handover_throttle.value or 20)/100);ranges={{mn,off,'OFF','red'},{off,auto,'IDLE','orange'},{auto,hand,'AUTO','purple'},{hand,mx,'RUN','green'}}end
 fill(x,y,w,h,'panel2');for _,r in ipairs(ranges)do local a=math.max(0,math.min(1,(r[1]-mn)/(mx-mn)));local z=math.max(0,math.min(1,(r[2]-mn)/(mx-mn)));if z>a then fill(x+a*w,y,(z-a)*w,h,r[4]);txt(x+(a+z)*w/2-18,y+6,r[3],'text')end end;box(x,y,w,h,'line')
 local p=math.max(0,math.min(1,(govThrottlePwm-mn)/(mx-mn)));fill(x+p*w-2,y-12,4,h+24,'text');local pct=math.max(0,math.min(100,100*(govThrottlePwm-lo)/math.max(1,hi-lo)));txt(x-2,y-18,'0%','muted');txt(x+w-28,y-18,'100%','muted');txt(math.max(x,math.min(x+w-62,x+p*w-25)),y+h+10,govThrottlePwm<off and'OFF'or string.format('%.1f%%',pct),'cyan')
end
govTabs={'GENERAL','MOTOR RAMP','FILTERS','BYPASS CURVE','LIVE MONITOR'}
govRows={}
function govShown(d)local v=d and d.value;if v==nil then return 'N/A'end;local scale=d.scale or 1;if scale~=1 then return string.format('%.1f',v/scale)end;return tostring(v)end
function govRefresh()
 if not govConfig then govRows={{'READ FC FIRST','',''}};govVisibleTabs={1};return end
 local mode=govConfig.gov_mode.value or 0;local enabled=mode>0;local ramps=mode>1
 govVisibleTabs={1};if ramps then govVisibleTabs[#govVisibleTabs+1]=2 end;if enabled and govExpert then govVisibleTabs[#govVisibleTabs+1]=3 end;if enabled then govVisibleTabs[#govVisibleTabs+1]=4 end
 local allowed=false;for _,v in ipairs(govVisibleTabs)do if v==govTab then allowed=true end end;if not allowed then govTab=1;govFocus=1;govScroll=1 end
 if govTab==1 then local p={{'Governor Mode',govConfig.gov_mode.table[mode]or tostring(mode),'gov_mode'}};if enabled then p[#p+1]={'Throttle Type',govConfig.gov_throttle_type.table[govConfig.gov_throttle_type.value]or tostring(govConfig.gov_throttle_type.value),'gov_throttle_type'};p[#p+1]={'Idle Throttle [%]',govShown(govConfig.gov_idle_throttle),'gov_idle_throttle'};p[#p+1]={'Auto Throttle [%]',govShown(govConfig.gov_auto_throttle),'gov_auto_throttle'};if ramps then p[#p+1]={'Handover Throttle [%]',govShown(govConfig.gov_handover_throttle),'gov_handover_throttle'};p[#p+1]={'Autorotation Timeout [s]',govShown(govConfig.gov_autorotation_timeout),'gov_autorotation_timeout'};p[#p+1]={'Throttle Hold Timeout [s]',govShown(govConfig.gov_throttle_hold_timeout),'gov_throttle_hold_timeout'}end;p[#p+1]={'Expert Mode',govExpert and'ON'or'OFF','expert'}end;govRows=p
 elseif govTab==2 and ramps then govRows={{'Startup Time [s]',govShown(govConfig.gov_startup_time),'gov_startup_time'},{'Spoolup Time [s]',govShown(govConfig.gov_spoolup_time),'gov_spoolup_time'},{'Spooldown Time [s]',govShown(govConfig.gov_spooldown_time),'gov_spooldown_time'},{'Tracking Time [s]',govShown(govConfig.gov_tracking_time),'gov_tracking_time'},{'Recovery Time [s]',govShown(govConfig.gov_recovery_time),'gov_recovery_time'}}
 elseif govTab==3 and enabled and govExpert then govRows={{'Headspeed Cutoff [Hz]',govShown(govConfig.gov_rpm_filter),'gov_rpm_filter'},{'Battery Voltage Cutoff [Hz]',govShown(govConfig.gov_pwr_filter),'gov_pwr_filter'},{'TTA Bandwidth [Hz]',govShown(govConfig.gov_tta_filter),'gov_tta_filter'},{'Precomp Bandwidth [Hz]',govShown(govConfig.gov_ff_filter),'gov_ff_filter'},{'D-term Cutoff [Hz]',govShown(govConfig.gov_d_filter),'gov_d_filter'}}
 elseif govTab==4 and enabled then local p={{'Points',tostring(govCurvePoints),'points'}};for j=0,govCurvePoints-1 do local i=govCurvePoints==5 and j*2 or j;local input=-100+200*j/(govCurvePoints-1);p[#p+1]={tostring(j+1)..'.  Input '..tostring(math.floor(input+.5))..'%',govShown(govConfig.gov_bypass_throttle[i]),i}end;govRows=p else govRows={}end
end
function govRead()if not rfReady then return end;govState='READING FC...';rfGovReadRxSetup();govConfig=govApi.getDefaults();govApi.read(function(_,d)govConfig=d;local five=true;for i=1,7,2 do local a=govConfig.gov_bypass_throttle[i-1].value or 0;local b=govConfig.gov_bypass_throttle[i+1].value or 0;local m=govConfig.gov_bypass_throttle[i].value or 0;if math.floor((a+b)/2+.5)~=m then five=false end end;govCurvePoints=five and 5 or 9;govDirty=false;govState='CONNECTED / READY';govRefresh()end,nil,govConfig)end
function govLiveRead()
 if not rfReady or not govApi or govLiveReadBusy or govDirty or govCurveEdit or govCurveDrag~=nil or numEdit or choiceSelect then return end
 govLiveReadBusy=true
 local fresh=govApi.getDefaults()
 govApi.read(function(_,d)govConfig=d;govLiveReadBusy=false;govState='CONNECTED / LIVE';govRefresh()end,function()govLiveReadBusy=false;govState='LIVE READ RETRY'end,fresh)
end
function govSave()if not govConfig then return end;govState='SAVING...';govApi.write(govConfig);rf2.mspQueue:add({command=250,processReply=function()govDirty=false;govState='SAVED TO FC'end,errorHandler=function()govState='LIVE / SAVE AFTER DISARM'end})end
function govChoice(key,title)local d=govConfig[key];local q={};for i=d.min,d.max do q[#q+1]={d.table[i]or tostring(i),i}end;openChoice(title,q,(d.value or d.min)-d.min+1,function(v)d.value=v;govDirty=true;govState='LIVE / NOT SAVED';govApi.write(govConfig);govRefresh()end)end
function govEdit(row)local r=govRows[row];if not r or not govConfig then return end;local k=r[3];if k=='points'then openChoice('BYPASS CURVE POINTS',{{'5 POINTS',5},{'9 POINTS',9}},govCurvePoints==5 and 1 or 2,function(v)govCurvePoints=v;if v==5 then for i=1,7,2 do local a=govConfig.gov_bypass_throttle[i-1].value or 0;local b=govConfig.gov_bypass_throttle[i+1].value or 0;govConfig.gov_bypass_throttle[i].value=math.floor((a+b)/2+.5)end end;govDirty=true;govState='LIVE / NOT SAVED';govApi.write(govConfig);govRefresh()end);return elseif k=='expert'then govExpert=not govExpert;govRefresh();return elseif k=='gov_mode'or k=='gov_throttle_type'then govChoice(k,r[1])else local d=govTab==4 and govConfig.gov_bypass_throttle[k]or govConfig[k];if not d then return end;local scale=d.scale or 1;beginNumber('govField',govTab==4 and('bypass:'..k)or k,(d.value or 0)/scale,(d.min or 0)/scale,(d.max or 65535)/scale);numEdit.scale=scale;if scale~=1 then numEdit.decimals=1;numEdit.text=string.format('%.1f',(d.value or 0)/scale)end end end
function govCommitKey(key,v)if string.sub(tostring(key),1,7)=='bypass:'then local i=tonumber(string.sub(key,8));govConfig.gov_bypass_throttle[i].value=v else govConfig[key].value=v end;govDirty=true;govState='LIVE / NOT SAVED';govApi.write(govConfig);govRefresh()end
function govDrawCurve()
 local x,y,w,h=28,180,500,205;local n=govCurvePoints;local sel=math.max(0,math.min(n-1,govFocus-#govVisibleTabs-2));fill(x,y,w,h,'panel2');local idle=govConfig and govConfig.gov_idle_throttle and(govConfig.gov_idle_throttle.value or 0)/10 or 0;if idle>0 then local ih=math.min(h,h*idle/100);fill(x,y+h-ih,w,ih,'blue');txt(x+w-92,y+h-ih-18,'IDLE THROTTLE','muted')end;local bin=w/(n-1);local left=math.max(x,x+sel*bin-bin/2);local right=math.min(x+w,x+sel*bin+bin/2);fill(left,y,right-left,h,'greenShade');box(x,y,w,h,'line');for xx=x,x+w,12 do fill(xx,y+h/2,6,1,'line')end;for yy=y,y+h,12 do fill(x+w/2,yy,1,6,'line')end
 local lastX,lastY=nil,nil;local vals={};for j=0,n-1 do local i=n==5 and j*2 or j;local v=(govConfig.gov_bypass_throttle[i].value or 0)/2;vals[j+1]=v;local px=x+j*w/(n-1);local py=y+h-v*h/100;if lcd.drawLine and lastX then lcd.drawLine(sx(lastX),sy(lastY),sx(px),sy(py),col('red'))end;fill(px-6,py-6,12,12,j==sel and'cyan'or'red');add('govpt'..j,px-18,y,36,h,{kind='govPoint',value=j});lastX,lastY=px,py end
 local q=math.max(0,math.min(1,(govThrottleCommand+500)/1000));local z=q*(n-1);local i=math.floor(z);local f=z-i;local va=vals[i+1]or 0;local vb=vals[math.min(n,i+2)]or va;local out=va+(vb-va)*f;govCurveCurrent=out;local px=x+q*w;local py=y+h-out*h/100;for yy=y,y+h,10 do fill(px-1,yy,2,5,'red')end;for xx=x,x+w,10 do fill(xx,py-1,5,2,'red')end;fill(px-7,py-7,14,14,'green');txt(24,160,'100%','muted');txt(24,386,'0%','muted');txt(x-2,389,'-100','muted');txt(x+w/2-6,389,'0','muted');txt(x+w-30,389,'+100','muted')
 fill(545,180,225,205,'panel');box(545,180,225,205,'line');txt(557,188,'Points','text');button('govPoints',' '..tostring(n)..' ',680,182,78,30,false,{kind='govPoints'},'cyan');txt(557,223,'Throttle:','text');txt(680,223,string.format('%.1f%%',out),'cyan',true)
 for j=0,n-1 do local yy=252+j*14;local i=n==5 and j*2 or j;local active=j==sel;if active then fill(553,yy-1,205,14,'greenShade')end;txt(560,yy,tostring(j+1)..'.',active and'green'or'text');txt(620,yy,string.format('%5.1f%%',(govConfig.gov_bypass_throttle[i].value or 0)/2),active and'green'or'text');add('govvalue'..j,553,yy-3,205,18,{kind='govCurveKeypad',value=j})end
end
function drawGovernor()
 header('GOVERNOR',govState);local n=#govVisibleTabs;local tw=math.floor(750/n)-7;local accents={'cyan','orange','purple','green','cyan'};for pos,id in ipairs(govVisibleTabs)do local x=20+(pos-1)*(tw+7);local active=govTab==id;local ac=accents[id]or'cyan';fill(x,105,tw,42,active and'panel2'or'panel');box(x,105,tw,42,active and ac or'line');fill(x,105,7,42,ac);txt(x+16,117,govTabs[id],active and ac or'text');add('govtab'..id,x,105,tw,42,{kind='govTab',value=id,pos=pos})end
 if govTab==1 then rfGovDrawThrottlePreview()end;if govTab==4 and govConfig then govDrawCurve()
 elseif govTab==5 then local m=rfMotorTelemetry[1]or{};local motor=m.rpm or 0;local main=rfMainD>0 and math.floor(motor*rfMainN/rfMainD+.5)or 0;local tail=rfTailD>0 and math.floor(motor*rfTailN/rfTailD+.5)or 0;local rows={{'Governor Mode',govConfig and govConfig.gov_mode.table[govConfig.gov_mode.value]or'N/A'},{'Main Rotor',tostring(main)..' RPM'},{'Tail Rotor',tostring(tail)..' RPM'},{'Motor',tostring(motor)..' RPM'},{'FC Link',rfReady and'CONNECTED'or'OFFLINE'}};local y=184;for i,r in ipairs(rows)do fill(20,y,710,42,'panel2');box(20,y,710,42,'line');txt(34,y+11,r[1],'text');txt(530,y+11,r[2],i==1 and'orange'or'cyan');y=y+47 end
 else local y=govTab==1 and 244 or 184;local visible=govTab==1 and 3 or 4;local rowFocus=govFocus-5;if rowFocus>=1 and rowFocus<=#govRows then if rowFocus<govScroll then govScroll=rowFocus elseif rowFocus>=govScroll+visible then govScroll=rowFocus-visible+1 end end;for i=govScroll,math.min(#govRows,govScroll+visible-1)do local r=govRows[i];local sel=govFocus==n+i;fill(20,y,710,42,'panel2');box(20,y,710,42,sel and'orange'or'line');txt(34,y+11,r[1],sel and'cyan'or'text');button('govrow'..i,r[2],500,y+3,220,36,sel,{kind='govRow',value=i},'cyan');y=y+47 end;if #govRows>visible then local top=govTab==1 and 244 or 184;local trackTop=top+48;local trackH=92;local maxScroll=math.max(1,#govRows-visible+1);govScroll=math.max(1,math.min(maxScroll,govScroll));button('govup','^',738,top,42,42,false,{kind='govScroll',delta=-1},'cyan');fill(752,trackTop,8,trackH,'line');local thumbH=math.max(24,math.floor(trackH*visible/#govRows));local thumbY=trackTop+math.floor((trackH-thumbH)*(govScroll-1)/math.max(1,maxScroll-1));fill(748,thumbY,16,thumbH,'cyan');button('govdown','v',738,top+146,42,42,false,{kind='govScroll',delta=1},'cyan')end end
 button('govRead','READ FC',360,421,125,36,false,{kind='govControl',value='read'},'cyan');button('govSave','SAVE FC',495,421,125,36,false,{kind='govControl',value='save'},'orange');button('govBack','< BACK',650,421,130,36,false,{kind='back'});footer('Governor changes apply live. SAVE writes configuration to EEPROM.')
end

function statusFinish()
 statusLiveBusy=false;statusLive.state='LIVE'
end
function requestStatusLive()
 if not rfReady or statusLiveBusy or not rf2.mspQueue:isProcessed()then return end
 statusLiveBusy=true;statusLive.state='UPDATING';local pending=5
 local function done()pending=pending-1;if pending<=0 then statusFinish()end end
 statusApi.getStatus(function(_,d)d=d or{};statusLive.cpu=d.cpuLoad or 0;statusLive.load=d.realTimeLoad or 0;statusLive.flags=d.armingDisableFlags or 0;statusLive.profile=d.profile or 0;statusLive.motors=d.motorCount or 0;done()end,done)
 rf2.mspQueue:add({command=108,processReply=function(_,b)b.offset=1;statusLive.roll=rf2.mspHelper.readS16(b)/10;statusLive.pitch=-rf2.mspHelper.readS16(b)/10;statusLive.yaw=-rf2.mspHelper.readS16(b);done()end,errorHandler=done})
 rf2.mspQueue:add({command=105,processReply=function(_,b)b.offset=1;local q={};local n=math.min(16,math.floor(#b/2));for i=1,n do q[i]=rf2.mspHelper.readU16(b)end;for i=n+1,16 do q[i]=1500 end;statusLive.rx=q;done()end,errorHandler=done})
 rf2.mspQueue:add({command=110,processReply=function(_,b)local function u16(i)return(b[i]or 0)+(b[i+1]or 0)*256 end;statusLive.voltage=(b[1]or 0)/10;statusLive.mah=u16(2);statusLive.rssi=u16(4);local a=u16(6);if a>=32768 then a=a-65536 end;statusLive.current=a/100;done()end,errorHandler=done})
 rf2.mspQueue:add({command=109,processReply=function(_,b)local v=(b[1]or 0)+(b[2]or 0)*256+(b[3]or 0)*65536+(b[4]or 0)*16777216;if v>=2147483648 then v=v-4294967296 end;statusLive.altitude=v;done()end,errorHandler=done})
end
function statusCard(x,y,w,h,title,accent)
 fill(x,y,w,h,'panel2');box(x,y,w,h,'line');fill(x,y,w,26,accent or'panel');txt(x+10,y+6,title,'text',true)
end
function statusFlagNames(flags)
 local names={'NO GYRO','FAILSAFE','RX FAILSAFE','BAD RX RECOVERY','BOX FAILSAFE','GOVERNOR','RPM SIGNAL','THROTTLE','ANGLE','BOOT GRACE','NO PREARM','LOAD','CALIBRATING','CLI','CMS MENU','BST','MSP','PARALYZE','GPS','RESC','RPM FILTER','REBOOT REQUIRED','DSHOT BITBANG','ACC CALIBRATION','MOTOR PROTOCOL','OVERRIDE','ARM SWITCH'};local out={};for i=0,26 do if bit32.band(flags or 0,bit32.lshift(1,i))~=0 then out[#out+1]=names[i+1]end end;if #out==0 then return 'NONE',''end;local a,b='', '';for _,v in ipairs(out)do if #a+#v<29 then a=a..(a~=''and', 'or'')..v else b=b..(b~=''and', 'or'')..v end end;return a,b
end
function statusSetArming(enable)
 if not rfReady then statusLive.state='FC OFFLINE';return end
 rf2.mspQueue:add({command=99,payload={enable and 0 or 1},processReply=function()statusLive.state=enable and'ARMING ENABLED'or'ARMING DISABLED';statusLiveAt=-1000 end,errorHandler=function()statusLive.state='ARMING COMMAND ERROR'end})
end
function statusDotLine(x1,y1,x2,y2,color,size)
 local dx=x2-x1;local dy=y2-y1;local steps=math.max(1,math.floor(math.max(math.abs(dx),math.abs(dy))/3));for i=0,steps do local q=i/steps;fill(x1+dx*q,y1+dy*q,size or 4,size or 4,color)end
end
function statusAngleDelta(a,b)
 local d=(a or 0)-(b or 0);while d>180 do d=d-360 end;while d<-180 do d=d+360 end;return d
end
function drawStatusHeli(cx,cy,viewScale)
 local rr=(statusLive.roll or 0)*math.pi/180;local pr=-(statusLive.pitch or 0)*math.pi/180;local yr=-statusAngleDelta(statusLive.yaw,statusYawOffset)*math.pi/180;local cr,sr=math.cos(rr),math.sin(rr);local cp,sp=math.cos(pr),math.sin(pr);local viewYaw=math.pi-yr;local cyr,syr=math.cos(viewYaw),math.sin(viewYaw)
 local lines={}
 local function pt(x,y,z)local scale=viewScale or 1;x=(x+33)*scale;y=y*scale;z=z*scale;local y1=y*cr-z*sr;local z1=y*sr+z*cr;local x2=x*cp+z1*sp;local z2=-x*sp+z1*cp;local x3=x2*cyr-y1*syr;local y3=x2*syr+y1*cyr;return cx+y3*.72,cy-z2*.72,x3 end
 local function seg(a,b,color,size)local x1,y1,d1=pt(a[1],a[2],a[3]or 0);local x2,y2,d2=pt(b[1],b[2],b[3]or 0);lines[#lines+1]={x1,y1,x2,y2,color,size,(d1+d2)*.5}end
 seg({-125,0,0},{55,0,0},'text',5)
 seg({-48,-22,0},{36,-20,0},'cyan',6);seg({36,-20,0},{58,0,0},'cyan',6);seg({58,0,0},{36,20,0},'cyan',6);seg({36,20,0},{-48,22,0},'cyan',6);seg({-48,22,0},{-65,0,0},'cyan',6);seg({-65,0,0},{-48,-22,0},'cyan',6)
 seg({-20,-13,9},{31,-12,9},'blue',6);seg({31,-12,9},{46,0,9},'blue',6);seg({46,0,9},{31,12,9},'blue',6);seg({31,12,9},{-20,13,9},'blue',6)
 seg({-20,-13,9},{-48,-22,0},'purple',3);seg({-20,13,9},{-48,22,0},'purple',3);seg({31,-12,9},{36,-20,0},'purple',3);seg({31,12,9},{36,20,0},'purple',3);seg({46,0,9},{58,0,0},'orange',5)
 seg({0,0,9},{0,0,27},'red',6);local rp={102,0,27};for i=1,20 do local a=i*math.pi*2/20;local rn={math.cos(a)*102,math.sin(a)*102,27};seg(rp,rn,'red',2);rp=rn end;seg({-72,-72,27},{72,72,27},'red',5);seg({-72,72,27},{72,-72,27},'red',5)
 seg({-38,-22,-7},{-45,-32,-22},'text',4);seg({28,-22,-7},{38,-32,-22},'text',4);seg({-58,-32,-22},{57,-32,-22},'text',5);seg({-38,22,-7},{-45,32,-22},'text',4);seg({28,22,-7},{38,32,-22},'text',4);seg({-58,32,-22},{57,32,-22},'text',5)
 seg({-112,0,-2},{-126,0,24},'cyan',5);seg({-126,0,24},{-126,0,-5},'cyan',5);seg({-118,0,0},{-118,-34,0},'purple',4);local trp={-94,-34,0};for i=1,16 do local a=i*math.pi*2/16;local trn={-118+math.cos(a)*24,-34,math.sin(a)*24};seg(trp,trn,'orange',2);trp=trn end;seg({-135,-34,-17},{-101,-34,17},'orange',5);seg({-135,-34,17},{-101,-34,-17},'orange',5)
 table.sort(lines,function(a,b)return a[7]<b[7]end);for i=1,#lines do local l=lines[i];statusDotLine(l[1],l[2],l[3],l[4],l[5],l[6])end
end
function statusResetZ()
 statusYawOffset=statusLive.yaw or 0;statusLive.state='Z AXIS OFFSET RESET'
end
function drawStatus()
 header('STATUS',statusLive.state)
 statusCard(18,100,240,84,'INFO','cyan');txt(30,132,'Aircraft: '..fcInfo.name,'text');txt(30,153,'FC: '..fcInfo.variant..' '..fcInfo.version,'muted');txt(30,170,'MSP '..fcInfo.api..'  PROFILE P'..tostring((statusLive.profile or 0)+1),'muted')
 statusCard(18,190,240,92,'ARMING','orange');local f1,f2=statusFlagNames(statusLive.flags);local armEnabled=bit32.band(statusLive.flags or 0,65536)==0;txt(30,220,'Enable Arming','text');button('armOff','OFF',140,214,48,28,not armEnabled,{kind='statusArm',value=false},'orange');button('armOn','ON',194,214,48,28,armEnabled,{kind='statusArm',value=true},'cyan');txt(30,248,'Disable: '..f1,f1=='NONE'and'green'or'red');if f2~=''then txt(30,266,f2,'red')end
 statusCard(18,288,240,82,'BATTERY','green');txt(30,317,string.format('Voltage %.1f V',statusLive.voltage or 0),'cyan');txt(30,338,string.format('Current %.2f A',statusLive.current or 0),'text');txt(145,317,'Used '..tostring(statusLive.mah or 0)..' mAh','text');txt(145,338,'RSSI '..tostring(statusLive.rssi or 0),'muted')
 statusCard(266,100,170,270,'INSTRUMENTS','purple');txt(278,137,'Open a live gauge:','muted');button('inst1','ATTITUDE',278,168,146,48,false,{kind='statusInstrumentOpen',value=1},'cyan');button('inst2','HEADING',278,224,146,48,false,{kind='statusInstrumentOpen',value=2},'orange');button('inst3','ALTIMETER',278,280,146,48,false,{kind='statusInstrumentOpen',value=3},'green');button('attOpen','3D HELI >',278,334,146,28,false,{kind='statusAttitudeOpen'},'purple')
 statusCard(444,100,338,270,'RECEIVER','blue');local names={'AIL','ELE','RUD','COL','THR','AUX1','AUX2','AUX3','AUX4','AUX5','AUX6','AUX7','AUX8','AUX9','AUX10','AUX11'};statusRxScroll=math.max(1,math.min(10,statusRxScroll or 1));for row=1,7 do local i=statusRxScroll+row-1;local y=130+(row-1)*27;local v=statusLive.rx[i]or 1500;local q=math.max(0,math.min(1,(v-1000)/1000));local pct=(v-1500)/5;txt(454,y,names[i],'text');fill(506,y+2,112,13,'panel');fill(506,y+2,112*q,13,i<=5 and'cyan'or'green');box(506,y+2,112,13,'line');txt(624,y,tostring(v),'muted');txt(690,y,string.format('%+.1f%%',pct),pct==0 and'muted'or'cyan')end;button('rxUp','^',750,128,26,30,false,{kind='statusRxScroll',delta=-1},'cyan');fill(757,164,10,112,'line');local ry=164+math.floor(88*(statusRxScroll-1)/9);fill(753,ry,18,24,'cyan');button('rxDown','v',750,282,26,30,false,{kind='statusRxScroll',delta=1},'cyan');txt(454,326,'CH '..tostring(statusRxScroll)..'-'..tostring(statusRxScroll+6)..' / 16','muted');local rp=math.max(0,math.min(100,(statusLive.rssi or 0)/10.23));txt(454,347,'RSSI','text');fill(506,349,112,13,'panel');fill(506,349,112*rp/100,13,'orange');box(506,349,112,13,'line');txt(624,347,string.format('%.0f%%',rp),'muted')
 txt(278,382,'CPU '..tostring(statusLive.cpu or 0)..'%  REALTIME '..tostring(statusLive.load or 0)..'%  MOTORS '..tostring(statusLive.motors or 0),'muted');button('statusRefresh','REFRESH',500,408,130,36,false,{kind='statusRefresh'},'cyan');button('statusBack','< BACK',650,408,130,36,false,{kind='back'});footer('Live read-only status. Tap ATTITUDE OPEN for the large 3D view.')
end
function drawInstrumentCircle(cx,cy,r)
 for i=0,71 do local a=i*math.pi/36;fill(cx+math.cos(a)*r-2,cy+math.sin(a)*r-2,4,4,i%9==0 and'cyan'or'line')end
end
function drawStatusInstrument()
 local titles={'ATTITUDE INDICATOR','HEADING INDICATOR','ALTIMETER'};local notes={'Shows helicopter Roll and Pitch','Shows Yaw heading direction','Shows FC estimated altitude'};local id=statusInstrument or 1;header(titles[id],'LIVE');txt(30,104,notes[id],'muted');fill(20,128,760,250,'panel2');box(20,128,760,250,'line');local cx,cy=400,248;drawInstrumentCircle(cx,cy,104)
 if id==1 then local roll=(statusLive.roll or 0)*math.pi/180;local pitch=math.max(-70,math.min(70,(statusLive.pitch or 0)*2));local dx=92*math.cos(roll);local dy=92*math.sin(roll);statusDotLine(cx-dx,cy-dy+pitch,cx+dx,cy+dy+pitch,'orange',5);statusDotLine(cx-24,cy,cx+24,cy,'cyan',5);statusDotLine(cx,cy-10,cx,cy+10,'cyan',5);txt(310,345,string.format('ROLL %+.1f deg',statusLive.roll or 0),'cyan');txt(450,345,string.format('PITCH %+.1f deg',statusLive.pitch or 0),'orange')
 elseif id==2 then local a=statusAngleDelta(statusLive.yaw,statusYawOffset)*math.pi/180-math.pi/2;txt(cx-5,139,'N','orange',true);txt(cx+94,240,'E','text',true);txt(cx-5,344,'S','text',true);txt(cx-104,240,'W','text',true);statusDotLine(cx,cy,cx+math.cos(a)*82,cy+math.sin(a)*82,'orange',6);txt(342,345,string.format('HEADING %+.0f deg',statusAngleDelta(statusLive.yaw,statusYawOffset)),'cyan')
 else local alt=statusLive.altitude or 0;local a=(alt%1000)/1000*math.pi*2-math.pi/2;for i=0,9 do local q=i*math.pi/5-math.pi/2;txt(cx+math.cos(q)*78-5,cy+math.sin(q)*78-6,tostring(i),'muted')end;statusDotLine(cx,cy,cx+math.cos(a)*76,cy+math.sin(a)*76,'green',6);txt(338,345,string.format('ALTITUDE %.2f m',alt/100),'green',true)end
 button('instBack','< STATUS',600,397,180,42,false,{kind='statusInstrumentBack'},'cyan');footer('Live instrument data from Rotorflight FC.')
end
function drawStatusAttitude()
 header('ATTITUDE','LIVE')
 statusCard(20,100,760,286,'3D HELICOPTER ATTITUDE','purple');drawStatusHeli(400,250,1.35)
 fill(38,142,190,76,'panel');box(38,142,190,76,'line');txt(52,158,string.format('ROLL  %+.1f deg',statusLive.roll or 0),'cyan',true);txt(52,187,string.format('PITCH %+.1f deg',statusLive.pitch or 0),'orange',true);fill(610,142,150,48,'panel');box(610,142,150,48,'line');txt(625,158,string.format('YAW %+.0f deg',statusAngleDelta(statusLive.yaw,statusYawOffset)),'green',true)
 button('resetZ','RESET Z AXIS',390,390,190,42,false,{kind='statusResetZ'},'orange');button('attBack',attitudeBackPage=='configuration'and'< CONFIG'or(attitudeBackPage=='receiver'and'< RECEIVER'or(attitudeBackPage=='easyBoardMenu'and'< CLOSE'or'< STATUS')),600,390,180,42,false,{kind='statusAttitudeBack'},'cyan');footer('RESET Z: sets the current heading to 0 deg without reversing the model.')
end


-- Receiver: Rotorflight 2.3.0 vertical layout, RF 4.6 / MSP 12.9
rxSel=2;rxScroll=1;rxState='NOT READ';rxProtocolUnlocked=false;rxTelemetryUnlocked=false;rxWarning=nil;rxRows={};rxFeature=0
rxConfig={provider=9,inverted=0,half=0,pulseMin=885,pulseMax=2115,spi=0,spiId=0,spiCount=0,pinswap=0}
rxRc={center=1500,deflection=510,arm=0,minThrottle=0,maxThrottle=0,deadband=5,yawDeadband=5};rxMap={0,1,2,3,4,5,6,7};rxRssi={channel=0,scale=100,invert=0,offset=0}
rxTelem={inverted=0,half=0,mask=0,pinswap=0,crsfMode=0,rate=0,ratio=0,list={}};rxTelemView='SELECT';rxTelemGroupOpen=nil;rxAssignmentOpen=false;rxPreviewZero={0,0,0,0};rxReading=false
rxProtocols={{'None',0,-1},{'TBS CRSF',9,3},{'Futaba S.BUS',2,3},{'Futaba S.BUS2',15,3},{'FrSky F.PORT',12,3},{'FrSky F.PORT2',16,3},{'FrSky FBUS',17,3},{'Spektrum DSM/1024',0,3},{'Spektrum DSM/2048',1,3},{'Spektrum DSM/SRXL',10,3},{'Spektrum DSM/SRXL2',13,3},{'ImmersionRC GHOST',14,3},{'Graupner SUMD',3,3},{'Graupner SUMH',4,3},{'FlySky IBUS',7,3},{'FlySky IBUS2',19,3},{'JR XBUS Mode A',18,3},{'JR XBUS Mode B',5,3},{'JR XBUS/RJ01',6,3},{'Jeti EXBUS',8,3},{'CPPM',0,0},{'MSP',0,14}}
rxNames={'ROLL','PITCH','YAW','COLLECTIVE','THROTTLE','AUX1','AUX2','AUX3','AUX4','AUX5','AUX6','AUX7','AUX8','AUX9','AUX10','AUX11'}
rxPresets={{'ELRS',1},{'FrSky',2},{'Futaba / Hitec',3},{'Spektrum / Graupner / JR',4}}
rxPresetMaps={{0,1,3,2,5,4,6,7},{0,1,3,4,2,5,6,7},{0,1,3,5,2,4,6,7},{1,2,3,5,0,4,6,7}}

rxSensorGroups={
 {'BATTERY',{3,4,5,6,7,8}},
 {'VOLTAGE',{42,43,44,45}},
 {'CURRENT',{46,47,48,49}},
 {'TEMPERATURE',{50,51,52}},
 {'ESC1',{17,18,19,20,21,22,23,24,25,26,27,28}},
 {'ESC2',{30,31,32,33,36,41}},
 {'RPM',{60,61}},
 {'BARO',{58,59}},
 {'GYRO',{57,64,65,66,67,68,69,70,71}},
 {'GPS',{73,74,77,78,79,80,81,82}},
 {'STATUS',{88,89,90,91,92,93,99}},
 {'PROFILE',{95,96,97,98}},
 {'CONTROL',{10,11,12,13,14,15}},
 {'SYSTEM',{1,85,86,87}},
 {'DEBUG',{100,101,102,103,104,105,106,107}}
}
rxSensorConflicts={[64]={65,66,67},[65]={64},[66]={64},[67]={64},[68]={69,70,71},[69]={68},[70]={68},[71]={68},[10]={11,12,13,14},[11]={10},[12]={10},[13]={10},[14]={10}}
function rxSensorSelected(id)for i=1,40 do if(rxTelem.list[i]or 0)==id then return true,i end end;return false,nil end
function rxSensorCount(ids)local n=0;for _,id in ipairs(ids)do if rxSensorSelected(id)then n=n+1 end end;return n end
function rxSensorTotal()local n=0;for i=1,40 do if(rxTelem.list[i]or 0)>0 then n=n+1 end end;return n end
function rxSensorAllowed(id)local c=rxSensorConflicts[id];if not c then return true end;for _,x in ipairs(c)do if rxSensorSelected(x)then return false end end;return true end
function rxToggleSensor(id)local yes,pos=rxSensorSelected(id);if yes then table.remove(rxTelem.list,pos);rxTelem.list[40]=0 else if rxSensorTotal()>=40 then rxState='MAXIMUM 40 TELEMETRY SENSORS';return end;if not rxSensorAllowed(id)then rxState='CONFLICTING SENSOR IS ALREADY SELECTED';return end;local n=rxSensorTotal()+1;rxTelem.list[n]=id end;rxWriteTelem();rxState='TELEMETRY SENSOR LIVE / NOT SAVED';rxBuildRows()end

rxSensorNames={'NONE','HEARTBEAT','BATTERY','BATTERY VOLTAGE','BATTERY CURRENT','BATTERY CONSUMPTION','BATTERY CHARGE LEVEL','BATTERY CELL COUNT','BATTERY CELL VOLTAGE','BATTERY CELL VOLTAGES','CONTROL','PITCH CONTROL','ROLL CONTROL','YAW CONTROL','COLLECTIVE CONTROL','THROTTLE CONTROL','ESC1 DATA','ESC1 VOLTAGE','ESC1 CURRENT','ESC1 CAPACITY','ESC1 ERPM','ESC1 POWER','ESC1 THROTTLE','ESC1 TEMP1','ESC1 TEMP2','ESC1 BEC VOLTAGE','ESC1 BEC CURRENT','ESC1 STATUS','ESC1 MODEL','ESC2 DATA','ESC2 VOLTAGE','ESC2 CURRENT','ESC2 CAPACITY','ESC2 ERPM','ESC2 POWER','ESC2 THROTTLE','ESC2 TEMP1','ESC2 TEMP2','ESC2 BEC VOLTAGE','ESC2 BEC CURRENT','ESC2 STATUS','ESC2 MODEL','ESC VOLTAGE','BEC VOLTAGE','BUS VOLTAGE','MCU VOLTAGE','ESC CURRENT','BEC CURRENT','BUS CURRENT','MCU CURRENT','ESC TEMP','BEC TEMP','MCU TEMP','AIR TEMP','MOTOR TEMP','BATTERY TEMP','EXHAUST TEMP','HEADING','ALTITUDE','VARIOMETER','HEADSPEED','TAILSPEED','MOTOR RPM','TRANS RPM','ATTITUDE','ATTITUDE PITCH','ATTITUDE ROLL','ATTITUDE YAW','ACCEL','ACCEL X','ACCEL Y','ACCEL Z','GPS','GPS SATS','GPS PDOP','GPS HDOP','GPS VDOP','GPS COORD','GPS ALTITUDE','GPS HEADING','GPS GROUNDSPEED','GPS HOME DISTANCE','GPS HOME DIRECTION','GPS DATE TIME','LOAD','CPU LOAD','SYS LOAD','RT LOAD','MODEL ID','FLIGHT MODE','ARMING FLAGS','ARMING DISABLE FLAGS','RESCUE STATE','GOVERNOR STATE','GOVERNOR FLAGS','PID PROFILE','RATES PROFILE','BATTERY PROFILE','LED PROFILE','ADJFUNC','DEBUG 0','DEBUG 1','DEBUG 2','DEBUG 3','DEBUG 4','DEBUG 5','DEBUG 6','DEBUG 7','RPM','TEMP'}
function rxU32(b)local a=rf2.mspHelper.readU16(b);local c=rf2.mspHelper.readU16(b);return a+c*65536 end
function rxWriteU16(q,v)rf2.mspHelper.writeU16(q,v)end
function rxProtocolIndex()local bit=bit32.btest(rxFeature,bit32.lshift(1,3))and 3 or(bit32.btest(rxFeature,bit32.lshift(1,0))and 0 or(bit32.btest(rxFeature,bit32.lshift(1,14))and 14 or-1));for i,v in ipairs(rxProtocols)do if v[3]==bit and(bit~=3 or v[2]==rxConfig.provider)then return i end end;return 1 end
function rxAssigned(ch)for i=1,math.min(8,#rxMap)do if rxMap[i]==ch-1 then return i end end;return ch end
function rxRssiText()if bit32.btest(rxFeature,bit32.lshift(1,15))then return'ADC'elseif rxRssi.channel>5 then return'AUX'..(rxRssi.channel-5)else return'AUTO'end end
function rxBuildRows()local a={{'section','RECEIVER PROTOCOL','danger'}}
 if not rxProtocolUnlocked then a[#a+1]={'unlock','ALLOW PROTOCOL CHANGES','protocol'}else a[#a+1]={'choice','Protocol','protocol'};local p=rxProtocols[rxProtocolIndex()];if p and p[3]==3 then a[#a+1]={'toggle','Serial Inverted','rxInv'};a[#a+1]={'toggle','Serial Half Duplex','rxHalf'};a[#a+1]={'toggle','Serial Pin Swap','rxPin'}end end
 a[#a+1]={'section','CHANNEL RANGE'};a[#a+1]={'number','Stick Center','center',1400,1600};a[#a+1]={'number','Stick Deflection','deflection',200,700};a[#a+1]={'toggle','Automatic Throttle Range','autoThrottle'};if rxRc.minThrottle~=0 or rxRc.maxThrottle~=0 then a[#a+1]={'number','Zero Throttle','minThrottle',885,2115};a[#a+1]={'number','Full Throttle','maxThrottle',885,2115}end;a[#a+1]={'number','Cyclic Deadband','deadband',0,100};a[#a+1]={'number','Yaw Deadband','yawDeadband',0,100}
 a[#a+1]={'section','TELEMETRY','danger'};if not rxTelemetryUnlocked then a[#a+1]={'unlock','ALLOW TELEMETRY CHANGES','telemetry'}else a[#a+1]={'toggle','Enable Telemetry','telemEnable'};a[#a+1]={'toggle','Telemetry Inverted','telemInv'};a[#a+1]={'toggle','Telemetry Half Duplex','telemHalf'};a[#a+1]={'toggle','Telemetry Pin Swap','telemPin'};if rxConfig.provider==9 then a[#a+1]={'toggle','CRSF Custom Telemetry Mode','crsfMode'};a[#a+1]={'number','CRSF Telemetry Rate','rate',0,1000};a[#a+1]={'number','CRSF Telemetry Ratio','ratio',0,1000}end;a[#a+1]={'section','TELEMETRY SENSORS  '..rxSensorTotal()..' / 40'};a[#a+1]={'mode','SORT','SORT'};a[#a+1]={'mode','SELECT','SELECT'};if rxTelemView=='SELECT'then for gi,g in ipairs(rxSensorGroups)do a[#a+1]={'group',g[1],gi};if rxTelemGroupOpen==gi then for _,id in ipairs(g[2])do a[#a+1]={'toggle','  '..(rxSensorNames[id+1]or('SENSOR '..id)),'ts'..id}end end end else for i=1,40 do if(rxTelem.list[i]or 0)>0 then a[#a+1]={'sort',i..'. '..(rxSensorNames[(rxTelem.list[i]or 0)+1]or('SENSOR '..rxTelem.list[i])),'sort'..i}end end end end
 a[#a+1]={'assignheader','CHANNEL ASSIGNMENT',rxAssignmentOpen and'OPEN'or'HIDDEN'};if rxAssignmentOpen then a[#a+1]={'preset','SELECT PRESET','preset'};for i=1,16 do a[#a+1]={i<=8 and'channel'or'livechannel',tostring(i),i}end;a[#a+1]={'rssi','RSSI SOURCE','rssi'}end;a[#a+1]={'section','STICK PREVIEW'};a[#a+1]={'preview','OPEN STICK HELICOPTER >','preview'};a[#a+1]={'action','READ FC','read'};a[#a+1]={'action','SAVE & REBOOT','save'};a[#a+1]={'action','< BACK','back'};rxRows=a
end
function rxRead()if not rfReady or rxReading then return end;rxReading=true;rxState='READING FC...';local pending=7;local function done()pending=pending-1;if pending<=0 then rxReading=false;rxState='CONNECTED / READY';rxBuildRows()end end
 rf2.mspQueue:add({command=36,processReply=function(_,b)b.offset=1;rxFeature=rxU32(b);done()end,errorHandler=done})
 rf2.mspQueue:add({command=44,processReply=function(_,b)b.offset=1;rxConfig.provider=rf2.mspHelper.readU8(b);rxConfig.inverted=rf2.mspHelper.readU8(b);rxConfig.half=rf2.mspHelper.readU8(b);rxConfig.pulseMin=rf2.mspHelper.readU16(b);rxConfig.pulseMax=rf2.mspHelper.readU16(b);rxConfig.spi=rf2.mspHelper.readU8(b);rxConfig.spiId=rxU32(b);rxConfig.spiCount=rf2.mspHelper.readU8(b);if b.offset<=#b then rxConfig.pinswap=rf2.mspHelper.readU8(b)end;done()end,errorHandler=done})
 rf2.mspQueue:add({command=64,processReply=function(_,b)b.offset=1;rxMap={};while b.offset<=#b do rxMap[#rxMap+1]=rf2.mspHelper.readU8(b)end;done()end,errorHandler=done})
 rf2.mspQueue:add({command=66,processReply=function(_,b)b.offset=1;rxRc.center=rf2.mspHelper.readU16(b);rxRc.deflection=rf2.mspHelper.readU16(b);rxRc.arm=rf2.mspHelper.readU16(b);rxRc.minThrottle=rf2.mspHelper.readU16(b);rxRc.maxThrottle=rf2.mspHelper.readU16(b);rxRc.deadband=rf2.mspHelper.readU8(b);rxRc.yawDeadband=rf2.mspHelper.readU8(b);done()end,errorHandler=done})
 rf2.mspQueue:add({command=50,processReply=function(_,b)b.offset=1;rxRssi.channel=rf2.mspHelper.readU8(b);rxRssi.scale=rf2.mspHelper.readU8(b);rxRssi.invert=rf2.mspHelper.readU8(b);rxRssi.offset=rf2.mspHelper.readU8(b);done()end,errorHandler=done})
 rf2.mspQueue:add({command=73,processReply=function(_,b)b.offset=1;rxTelem.inverted=rf2.mspHelper.readU8(b);rxTelem.half=rf2.mspHelper.readU8(b);rxTelem.mask=rxU32(b);if b.offset<=#b then rxTelem.pinswap=rf2.mspHelper.readU8(b);rxTelem.crsfMode=rf2.mspHelper.readU8(b);rxTelem.rate=rf2.mspHelper.readU16(b);rxTelem.ratio=rf2.mspHelper.readU16(b);rxTelem.list={};for i=1,40 do local id=b.offset<=#b and rf2.mspHelper.readU8(b)or 0;if id>0 then rxTelem.list[#rxTelem.list+1]=id end end;for i=#rxTelem.list+1,40 do rxTelem.list[i]=0 end end;done()end,errorHandler=done})
 rf2.mspQueue:add({command=105,processReply=function(_,b)b.offset=1;for i=1,math.min(16,math.floor(#b/2))do statusLive.rx[i]=rf2.mspHelper.readU16(b)end;done()end,errorHandler=done})
end
function rxWrite(cmd,q,msg)rf2.mspQueue:add({command=cmd,payload=q,processReply=function()rxState=msg or'LIVE / NOT SAVED'end,errorHandler=function()rxState='WRITE FAILED'end})end
function rxWriteFeature()local q={};rf2.mspHelper.writeU32(q,rxFeature);rxWrite(37,q)end
function rxWriteConfig()local q={rxConfig.provider,rxConfig.inverted,rxConfig.half};rxWriteU16(q,rxConfig.pulseMin);rxWriteU16(q,rxConfig.pulseMax);q[#q+1]=rxConfig.spi;rf2.mspHelper.writeU32(q,rxConfig.spiId);q[#q+1]=rxConfig.spiCount;q[#q+1]=rxConfig.pinswap;rxWrite(45,q)end
function rxWriteRc()local q={};rxWriteU16(q,rxRc.center);rxWriteU16(q,rxRc.deflection);rxWriteU16(q,rxRc.arm);rxWriteU16(q,rxRc.minThrottle);rxWriteU16(q,rxRc.maxThrottle);q[#q+1]=rxRc.deadband;q[#q+1]=rxRc.yawDeadband;rxWrite(67,q)end
function rxWriteMap()local q={};for i=1,8 do q[i]=rxMap[i]or(i-1)end;rxWrite(65,q)end
function rxWriteRssi()rxWrite(51,{rxRssi.channel,rxRssi.scale,rxRssi.invert,rxRssi.offset})end
function rxWriteTelem()local q={rxTelem.inverted,rxTelem.half};rf2.mspHelper.writeU32(q,rxTelem.mask);q[#q+1]=rxTelem.pinswap;q[#q+1]=rxTelem.crsfMode;rxWriteU16(q,rxTelem.rate);rxWriteU16(q,rxTelem.ratio);for i=1,40 do q[#q+1]=rxTelem.list[i]or 0 end;rxWrite(74,q)end
function rxSave()rxState='SAVING EEPROM...';rf2.mspQueue:add({command=250,processReply=function()rxState='SAVED / REBOOTING';rf2.mspQueue:add({command=68,payload={0}})end,errorHandler=function()rxState='SAVE FAILED - DISARM FC'end})end
function rxValue(r)local k=r[3];if k=='protocol'then return rxProtocols[rxProtocolIndex()][1]elseif k=='rxInv'then return rxConfig.inverted~=0 elseif k=='rxHalf'then return rxConfig.half~=0 elseif k=='rxPin'then return rxConfig.pinswap~=0 elseif k=='autoThrottle'then return rxRc.minThrottle==0 and rxRc.maxThrottle==0 elseif k=='telemEnable'then return bit32.btest(rxFeature,bit32.lshift(1,10))elseif k=='telemInv'then return rxTelem.inverted~=0 elseif k=='telemHalf'then return rxTelem.half~=0 elseif k=='telemPin'then return rxTelem.pinswap~=0 elseif k=='crsfMode'then return rxTelem.crsfMode~=0 elseif k=='rate'then return rxTelem.rate elseif k=='ratio'then return rxTelem.ratio elseif k=='rssi'then return rxRssiText()elseif r[1]=='group'then local g=rxSensorGroups[r[3]];return rxSensorCount(g[2])..' / '..#g[2]..(rxTelemGroupOpen==r[3]and'  ^'or'  v')elseif string.sub(k or'',1,2)=='ts'then return rxSensorSelected(tonumber(string.sub(k,3)))elseif r[1]=='number'then return rxRc[k]or 0 elseif r[1]=='channel'or r[1]=='livechannel'then local i=r[3];local f=rxAssigned(i);local v=statusLive.rx[i]or 1500;return(rxNames[f]or('CH'..f))..'  '..v..'us' end;return'' end
function rxToggle(k)if k=='rxInv'then rxConfig.inverted=1-rxConfig.inverted;rxWriteConfig()elseif k=='rxHalf'then rxConfig.half=1-rxConfig.half;rxWriteConfig()elseif k=='rxPin'then rxConfig.pinswap=1-rxConfig.pinswap;rxWriteConfig()elseif k=='autoThrottle'then if rxRc.minThrottle==0 and rxRc.maxThrottle==0 then rxRc.minThrottle=1100;rxRc.maxThrottle=1900 else rxRc.minThrottle=0;rxRc.maxThrottle=0 end;rxWriteRc();rxBuildRows()elseif k=='telemEnable'then rxFeature=bit32.bxor(rxFeature,bit32.lshift(1,10));rxWriteFeature()elseif k=='telemInv'then rxTelem.inverted=1-rxTelem.inverted;rxWriteTelem()elseif k=='telemHalf'then rxTelem.half=1-rxTelem.half;rxWriteTelem()elseif k=='telemPin'then rxTelem.pinswap=1-rxTelem.pinswap;rxWriteTelem()elseif k=='crsfMode'then rxTelem.crsfMode=1-rxTelem.crsfMode;rxWriteTelem();rxBuildRows()elseif string.sub(k or'',1,2)=='ts'then rxToggleSensor(tonumber(string.sub(k,3)))end end
function rxCommit(k,v)if k=='rate'or k=='ratio'then rxTelem[k]=v;rxWriteTelem()else rxRc[k]=v;rxWriteRc()end;rxBuildRows()end
function rxChooseProtocol()local items={};for i,v in ipairs(rxProtocols)do items[i]={v[1],i}end;openChoice('SELECT RECEIVER PROTOCOL',items,rxProtocolIndex(),function(i)local v=rxProtocols[i];for _,bit in ipairs({0,3,13,14,25})do rxFeature=bit32.band(rxFeature,bit32.bnot(bit32.lshift(1,bit)))end;if v[3]>=0 then rxFeature=bit32.bor(rxFeature,bit32.lshift(1,v[3]))end;rxConfig.provider=v[2];rxWriteFeature();rxWriteConfig();rxBuildRows()end)end
function rxChooseChannel(ch)local items={};for i=1,8 do items[i]={rxNames[i],i}end;openChoice('ASSIGN CHANNEL '..ch,items,rxAssigned(ch),function(fn)local old=rxMap[fn];local other=nil;for i=1,8 do if rxMap[i]==ch-1 then other=i;break end end;if other then rxMap[other]=old end;rxMap[fn]=ch-1;rxWriteMap();rxBuildRows()end)end
function rxChoosePreset()openChoice('APPLY CHANNEL PRESET',rxPresets,1,function(i)for n=1,8 do rxMap[n]=rxPresetMaps[i][n]end;rxWriteMap();rxBuildRows()end)end
function rxChooseRssi()local items={{'AUTO',0},{'ADC',1}};for i=1,11 do items[#items+1]={'AUX'..i,i+5}end;openChoice('SELECT RSSI SOURCE',items,rxRssi.channel,function(v)if v==1 then rxFeature=bit32.bor(rxFeature,bit32.lshift(1,15));rxRssi.channel=0 else rxFeature=bit32.band(rxFeature,bit32.bnot(bit32.lshift(1,15)));rxRssi.channel=v end;rxWriteFeature();rxWriteRssi();rxBuildRows()end)end
function rxChooseSensor(slot)local items={};for i,n in ipairs(rxSensorNames)do items[i]={n,i-1}end;openChoice('SELECT TELEMETRY SENSOR '..slot,items,(rxTelem.list[slot]or 0)+1,function(v)rxTelem.list[slot]=v;rxWriteTelem();rxBuildRows()end)end
function rxSortSensor(slot)local items={{'MOVE UP',1},{'MOVE DOWN',2},{'REMOVE',3}};openChoice('SORT TELEMETRY SENSOR',items,1,function(v)if v==1 and slot>1 then rxTelem.list[slot],rxTelem.list[slot-1]=rxTelem.list[slot-1],rxTelem.list[slot]elseif v==2 and slot<40 then rxTelem.list[slot],rxTelem.list[slot+1]=rxTelem.list[slot+1],rxTelem.list[slot]elseif v==3 then table.remove(rxTelem.list,slot);rxTelem.list[40]=0 end;rxWriteTelem();rxBuildRows()end)end
function rxActivate(i)local r=rxRows[i];if not r or r[1]=='section'or r[1]=='livechannel'then return end;rxSel=i;if r[1]=='assignheader'then rxAssignmentOpen=not rxAssignmentOpen;rxBuildRows()elseif r[1]=='unlock'then rxWarning=r[3]elseif r[1]=='choice'then rxChooseProtocol()elseif r[1]=='toggle'then rxToggle(r[3])elseif r[1]=='number'then beginNumber('receiver',r[3],rxValue(r),r[4],r[5])elseif r[1]=='preset'then rxChoosePreset()elseif r[1]=='channel'then rxChooseChannel(r[3])elseif r[1]=='rssi'then rxChooseRssi()elseif r[1]=='group'then local gi=r[3];if rxTelemGroupOpen==gi then rxTelemGroupOpen=nil;rxState='TELEMETRY GROUP CLOSED'else rxTelemGroupOpen=gi;rxState='TELEMETRY GROUP OPEN' end;rxBuildRows()elseif r[1]=='sort'then rxSortSensor(tonumber(string.sub(r[3],5)))elseif r[1]=='mode'then rxTelemView=r[3];rxBuildRows()elseif r[1]=='preview'then page='receiverPreview'elseif r[3]=='read'then rxRead()elseif r[3]=='save'then rxSave()elseif r[3]=='back'then page='full' end end
function drawRxWarning()hit={};fill(80,95,640,290,'panel');box(80,95,640,290,'red');fill(80,95,640,46,'red');txt(105,109,'WARNING: CONNECTION MAY BE LOST','text',true);txt(112,165,rxWarning=='protocol'and'Changing receiver protocol can stop all receiver input.'or'Changing telemetry can disconnect this Lua script.','orange',true);txt(112,205,'Confirm before showing and enabling these settings.','text');button('rxWarnNo','CANCEL',180,310,180,46,false,{kind='rxWarnNo'},'cyan');button('rxWarnYes','ALLOW CHANGES',420,310,200,46,false,{kind='rxWarnYes'},'red')end
function rxJumpIndex(id)
 local fallback=1;for i,r in ipairs(rxRows)do if id==1 and r[1]=='section'and r[2]=='RECEIVER PROTOCOL'then return i elseif id==2 and r[1]=='section'and r[2]=='CHANNEL RANGE'then return i elseif id==3 and r[1]=='section'and r[2]=='TELEMETRY'then fallback=i;return i elseif id==4 and r[1]=='section'and string.sub(r[2],1,17)=='TELEMETRY SENSORS'then return i elseif id==5 and r[1]=='assignheader'then return i elseif id==6 and r[1]=='section'and r[2]=='STICK PREVIEW'then return i end end;if id==4 then return rxJumpIndex(3)end;return fallback
end
function rxJump(id)local i=rxJumpIndex(id);rxSel=i;rxScroll=i;rxQuickActive=id end
function rxQuickCurrent()local best=1;local pos=-1;for id=1,6 do local p=rxJumpIndex(id);if p<=rxScroll and p>=pos then best=id;pos=p end end;return best end
function drawRxQuickNav()local names={'PROTO','RANGE','TELEM','SENS','ASSIGN','VIEW'};local active=rxQuickCurrent();for i,n in ipairs(names)do local x=126+(i-1)*101;button('rxQuick'..i,n,x,62,94,34,active==i,{kind='rxQuick',value=i},(i==3 or i==4)and'orange'or'cyan')end end
function drawReceiver()rxBuildRows();header('RECEIVER',rxState);drawRxQuickNav();local visible=7;if rxSel<rxScroll then rxScroll=rxSel elseif rxSel>=rxScroll+visible then rxScroll=rxSel-visible+1 end;rxScroll=math.max(1,math.min(math.max(1,#rxRows-visible+1),rxScroll));local y=104
 for i=rxScroll,math.min(#rxRows,rxScroll+visible-1)do local r=rxRows[i];local sec=r[1]=='section';local danger=sec and r[3]=='danger';fill(20,y,720,40,sec and'panel2'or(rxSel==i and'panel2'or'panel'));box(20,y,720,40,danger and'red'or(rxSel==i and'cyan'or'line'));if sec then fill(20,y,8,40,danger and'red'or'purple');txt(42,y+12,r[2],danger and'red'or'cyan',true)else if r[1]~='assignheader'and r[1]~='channel'and r[1]~='livechannel'and r[1]~='rssi'then txt(34,y+12,r[2],rxSel==i and'cyan'or'text')end;local v=rxValue(r);if r[1]=='assignheader'then fill(20,y,8,40,'green');txt(42,y+12,r[2],'green',true);button('rxRow'..i,rxAssignmentOpen and'HIDE ^'or'SHOW v',590,y+5,132,30,rxSel==i,{kind='rxRow',index=i},'green') elseif r[1]=='channel'or r[1]=='livechannel'then local ch=r[3];local pwm=rxChannelPwm(ch);local cen=rxRc.center or 1500;local def=math.max(1,rxRc.deflection or 500);local pct=math.max(-100,math.min(100,(pwm-cen)*100/def));local q=(pct+100)/200;local fn=rxAssigned(ch);txt(34,y+12,tostring(ch),ch<=8 and'cyan'or'text',true);button('rxName'..i,rxNames[fn]or('AUX'..math.max(1,ch-5)),65,y+5,145,30,rxSel==i,{kind='rxRow',index=i},ch<=8 and'cyan'or'muted');fill(224,y+14,280,12,'bg');fill(224,y+14,280*q,12,ch<=5 and'cyan'or'green');fill(363,y+10,2,20,'orange');box(224,y+14,280,12,'line');txt(516,y+12,tostring(pwm)..' us','text');txt(640,y+12,string.format('%+.1f%%',pct),math.abs(pct)<.1 and'muted'or'cyan') elseif r[1]=='rssi'then local raw=statusLive.rssi or 0;local rp=math.max(0,math.min(100,raw>100 and raw/10.23 or raw));txt(34,y+12,r[2],rxSel==i and'cyan'or'text');button('rxRssi'..i,rxRssiText(),250,y+5,105,30,rxSel==i,{kind='rxRow',index=i},'cyan');fill(370,y+14,250,12,'bg');fill(370,y+14,250*rp/100,12,'orange');box(370,y+14,250,12,'line');txt(640,y+12,string.format('%.0f%%',rp),'orange',true) elseif r[1]=='toggle'then button('rxOff'..i,'OFF',590,y+5,62,30,not v,{kind='rxToggle',index=i},'orange');button('rxOn'..i,'ON',660,y+5,62,30,v,{kind='rxToggle',index=i},'cyan')else local label=(r[1]=='unlock'or r[1]=='action'or r[1]=='preview'or r[1]=='mode')and r[2]or tostring(v);button('rxRow'..i,fit(label,27),490,y+5,232,30,rxSel==i or(r[1]=='mode'and rxTelemView==r[3]),{kind='rxRow',index=i},r[1]=='unlock'and'red'or'cyan')end end;y=y+44 end
 button('rxUp','^',748,105,32,34,false,{kind='rxScroll',delta=-3},'cyan');fill(758,145,10,210,'line');local th=math.max(24,math.floor(210*visible/#rxRows));local ty=145+math.floor((210-th)*(rxScroll-1)/math.max(1,#rxRows-visible));fill(753,ty,20,th,'cyan');button('rxDown','v',748,364,32,34,false,{kind='rxScroll',delta=3},'cyan');footer('Assignment is hidden by default. Preset remaps live bars; CH 1-8 are editable.');if rxWarning then drawRxWarning()end
end

-- MSP_RC (105) contains function-ordered rcInput, not raw receiver channels.
function rxFunctionPwm(fn)return statusLive.rx[fn]or(fn==5 and 1000 or 1500)end
function rxChannelPwm(ch)return rxFunctionPwm(rxAssigned(ch))end
function rxStickPct(fn)local cen=rxRc.center or 1500;local def=math.max(1,rxRc.deflection or 500);return math.max(-100,math.min(100,(rxFunctionPwm(fn)-cen)*100/def))end
function drawReceiverPreview()
 header('RECEIVER STICK PREVIEW','LIVE')
 local rr,pp,yy,cc=rxStickPct(1)-(rxPreviewZero[1]or 0),rxStickPct(2)-(rxPreviewZero[2]or 0),rxStickPct(3)-(rxPreviewZero[3]or 0),rxStickPct(4)-(rxPreviewZero[4]or 0);local orr,opp,oy=statusLive.roll,statusLive.pitch,statusLive.yaw;statusLive.roll=rr*.28;statusLive.pitch=pp*.28;statusLive.yaw=(statusYawOffset or 0)+yy*.9;statusCard(20,100,760,286,'TRANSMITTER CONTROLLED HELICOPTER','green');drawStatusHeli(400,248,1.35);statusLive.roll,statusLive.pitch,statusLive.yaw=orr,opp,oy
 local vals={{'ROLL',rr,'cyan'},{'PITCH',pp,'orange'},{'YAW',yy,'green'},{'COL',cc,'purple'}};for i,v in ipairs(vals)do local x=36+(i-1)*185;txt(x,342,v[1]..' '..string.format('%+.0f%%',v[2]),v[3],true);fill(x,365,160,10,'bg');fill(x,365,160*(v[2]+100)/200,10,v[3]);fill(x+79,360,2,20,'text');box(x,365,160,10,'line')end
 button('rxPreviewReset','RESET',400,398,180,40,false,{kind='rxPreviewReset'},'orange');button('rxPreviewBack','< RECEIVER',600,398,180,40,false,{kind='rxPreviewBack'},'cyan');footer('RESET uses the current stick positions as the center reference.')
end

-- Failsafe: Rotorflight Configurator 2.3.0 layout, RF 4.6 / MSP 12.9
fsSel=1;fsScroll=1;fsState='NOT READ';fsRows={};fsData={};fsReading=false
fsNames={'ROLL','PITCH','YAW','COLLECTIVE','THROTTLE','AUX1','AUX2','AUX3','AUX4','AUX5','AUX6','AUX7','AUX8','AUX9','AUX10','AUX11'}
function fsBuildRows()local a={{'section','PULSE RANGE (EXPERT)'},{'number','Valid Pulse Minimum','pulseMin',750,2250},{'number','Valid Pulse Maximum','pulseMax',750,2250},{'section','CHANNEL FALLBACK'}};for i=1,math.max(16,#fsData)do a[#a+1]={'channel',fsNames[i]or('AUX'..(i-5)),i}end;a[#a+1]={'action','READ FC','read'};a[#a+1]={'action','SAVE & REBOOT','save'};a[#a+1]={'action','< BACK','back'};fsRows=a end
function fsRead()if not rfReady or fsReading then return end;fsReading=true;fsState='READING FC...';local pending=2;local function done()pending=pending-1;if pending<=0 then fsReading=false;fsState='CONNECTED / READY';fsBuildRows()end end
 rf2.mspQueue:add({command=44,processReply=function(_,b)b.offset=1;rxConfig.provider=rf2.mspHelper.readU8(b);rxConfig.inverted=rf2.mspHelper.readU8(b);rxConfig.half=rf2.mspHelper.readU8(b);rxConfig.pulseMin=rf2.mspHelper.readU16(b);rxConfig.pulseMax=rf2.mspHelper.readU16(b);rxConfig.spi=rf2.mspHelper.readU8(b);rxConfig.spiId=rxU32(b);rxConfig.spiCount=rf2.mspHelper.readU8(b);if b.offset<=#b then rxConfig.pinswap=rf2.mspHelper.readU8(b)end;done()end,errorHandler=done})
 rf2.mspQueue:add({command=77,processReply=function(_,b)b.offset=1;fsData={};while b.offset+2<=#b do fsData[#fsData+1]={mode=rf2.mspHelper.readU8(b),value=rf2.mspHelper.readU16(b)}end;for i=#fsData+1,16 do fsData[i]={mode=i<=5 and 0 or 1,value=1500}end;done()end,errorHandler=done})
end
function fsWriteChannel(i)local d=fsData[i];if not d then return end;local q={i-1,d.mode};rxWriteU16(q,d.value);rf2.mspQueue:add({command=78,payload=q,processReply=function()fsState='LIVE / NOT SAVED'end,errorHandler=function()fsState='WRITE FAILED'end})end
function fsCommit(k,v)if k=='pulseMin'then rxConfig.pulseMin=v;rxWriteConfig()elseif k=='pulseMax'then rxConfig.pulseMax=v;rxWriteConfig()else local i=tonumber(string.sub(k,4));if i and fsData[i]then fsData[i].value=v;fsWriteChannel(i)end end;fsBuildRows()end
function fsChooseMode(i)local d=fsData[i];if not d then return end;local items=i<=5 and{{'AUTO',0},{'HOLD',1},{'SET',2}}or{{'HOLD',1},{'SET',2}};local sel=1;for n,v in ipairs(items)do if v[2]==d.mode then sel=n end end;openChoice('FAILSAFE '..(fsNames[i]or('AUX'..i)),items,sel,function(v)d.mode=v;fsWriteChannel(i);fsState='LIVE / NOT SAVED';fsBuildRows()end)end
function fsActivate(i)local r=fsRows[i];if not r or r[1]=='section'then return end;fsSel=i;if r[1]=='number'then local v=r[3]=='pulseMin'and rxConfig.pulseMin or rxConfig.pulseMax;beginNumber('failsafe',r[3],v,r[4],r[5])elseif r[1]=='channel'then fsChooseMode(r[3])elseif r[3]=='read'then fsRead()elseif r[3]=='save'then fsState='SAVING EEPROM...';rf2.mspQueue:add({command=250,processReply=function()fsState='SAVED / REBOOTING';rf2.mspQueue:add({command=68,payload={0}})end,errorHandler=function()fsState='SAVE FAILED - DISARM FC'end})elseif r[3]=='back'then page='full'end end
function fsJump(id)local target=id==1 and'PULSE RANGE (EXPERT)'or'CHANNEL FALLBACK';for i,r in ipairs(fsRows)do if r[1]=='section'and r[2]==target then fsSel=i;fsScroll=i;return end end end
function drawFailsafe()fsBuildRows();header('FAILSAFE',fsState);button('fsQuick1','RANGE',390,62,160,34,fsScroll<4,{kind='fsQuick',value=1},'cyan');button('fsQuick2','FALLBACK',560,62,166,34,fsScroll>=4,{kind='fsQuick',value=2},'orange');local visible=7;if fsSel<fsScroll then fsScroll=fsSel elseif fsSel>=fsScroll+visible then fsScroll=fsSel-visible+1 end;fsScroll=math.max(1,math.min(math.max(1,#fsRows-visible+1),fsScroll));local y=104
 for i=fsScroll,math.min(#fsRows,fsScroll+visible-1)do local r=fsRows[i];local sec=r[1]=='section';fill(20,y,720,40,sec and'panel2'or(fsSel==i and'panel2'or'panel'));box(20,y,720,40,fsSel==i and'cyan'or'line');if sec then fill(20,y,8,40,r[2]=='CHANNEL FALLBACK'and'orange'or'cyan');txt(42,y+12,r[2],r[2]=='CHANNEL FALLBACK'and'orange'or'cyan',true)elseif r[1]=='channel'then local d=fsData[r[3]]or{mode=1,value=1500};txt(34,y+12,r[2],fsSel==i and'cyan'or'text');local mn=d.mode==0 and'AUTO'or(d.mode==1 and'HOLD'or'SET');button('fsMode'..i,mn,480,y+5,105,30,fsSel==i,{kind='fsRow',index=i},d.mode==2 and'orange'or'cyan');if d.mode==2 then button('fsSet'..i,tostring(d.value)..' us',595,y+5,127,30,false,{kind='fsSet',channel=r[3]},'orange')end else txt(34,y+12,r[2],fsSel==i and'cyan'or'text');local label=r[1]=='number'and tostring(r[3]=='pulseMin'and rxConfig.pulseMin or rxConfig.pulseMax)..' us'or r[2];button('fsRow'..i,label,520,y+5,202,30,fsSel==i,{kind='fsRow',index=i},r[3]=='save'and'orange'or'cyan')end;y=y+44 end
 button('fsUp','^',748,105,32,34,false,{kind='fsScroll',delta=-3},'cyan');fill(758,145,10,210,'line');local th=math.max(24,math.floor(210*visible/#fsRows));local ty=145+math.floor((210-th)*(fsScroll-1)/math.max(1,#fsRows-visible));fill(753,ty,20,th,'cyan');button('fsDown','v',748,364,32,34,false,{kind='fsScroll',delta=3},'cyan');footer('AUTO is available for flight controls. AUX channels use HOLD or SET. SET range: 875-2125 us.')
end

-- Power: Rotorflight Configurator 2.3.0, RF 4.6 / MSP 12.9
pwTab=1;pwSel=1;pwScroll=1;pwState='NOT READ';pwRows={};pwReading=false;pwLiveAt=-1000;pwLiveBusy=false
pwBat={capacity=0,cellCount=0,vSource=0,cSource=0,minCell=330,maxCell=435,fullCell=420,warnCell=350,lvc=0,mahWarn=0,capacities={0,0,0,0,0,0}}
pwLive={state=0,cells=0,capacity=0,mah=0,voltage=0,current=0,charge=0,profile=0};pwFuel={mode=0,voltageDrop=0,chargeDrop=0,sag=0};pwVolt={};pwCurr={}
pwTabs={'STATE','BATTERY','SMART FUEL','VOLTAGE','CURRENT'};pwSources={{'NONE',0},{'ADC',1},{'ESC',2},{'FBUS',3}};pwFuelSources={{'NONE',0},{'VOLTAGE',1},{'CURRENT',2},{'COMBINED',3}}
function pwS16(b)local v=rf2.mspHelper.readU16(b);return v>=32768 and v-65536 or v end
function pwU16(q,v)rxWriteU16(q,v<0 and v+65536 or v)end
function pwBuildRows()local a={};if pwTab==1 then a={{'live','Connection State','state'},{'live','Battery Voltage','voltage'},{'live','Battery Current','current'},{'live','Current Drawn','mah'},{'live','Charge Level','charge'},{'live','Cell Count','cells'},{'live','Battery Profile','profile'}}elseif pwTab==2 then a={{'choice','Voltage Meter Source','vSource'},{'choice','Current Meter Source','cSource'},{'number','Maximum Cell Voltage','maxCell',100,500},{'number','Full Cell Voltage','fullCell',100,500},{'number','Warning Cell Voltage','warnCell',100,500},{'number','Minimum Cell Voltage','minCell',100,500},{'number','Cell Count','cellCount',0,24},{'number','Capacity P1','cap1',0,20000},{'number','Capacity P2','cap2',0,20000},{'number','Capacity P3','cap3',0,20000},{'number','Capacity P4','cap4',0,20000},{'number','Capacity P5','cap5',0,20000},{'number','Capacity P6','cap6',0,20000},{'number','Low Voltage Cutoff','lvc',0,100},{'number','Capacity Warning','mahWarn',0,100}}elseif pwTab==3 then a={{'choice','SmartFuel Source','fuelMode'}};if pwFuel.mode==1 or pwFuel.mode==3 then a[#a+1]={'number','Voltage Drop Rate','voltageDrop',0,250};a[#a+1]={'number','Charge Drop Rate','chargeDrop',0,250};a[#a+1]={'number','Sag Compensation Gain','sag',0,100}end elseif pwTab==4 then for i,d in ipairs(pwVolt)do a[#a+1]={'section','VOLTAGE METER '..d.id};a[#a+1]={'number','Scale','vs'..i,0,65535};a[#a+1]={'number','Divider','vd'..i,1,65535}end elseif pwTab==5 then for i,d in ipairs(pwCurr)do a[#a+1]={'section','CURRENT METER '..d.id};a[#a+1]={'number','Scale','cs'..i,-16000,16000};a[#a+1]={'number','Offset','co'..i,-32000,32000}end end;a[#a+1]={'action','READ FC','read'};a[#a+1]={'action','SAVE','save'};a[#a+1]={'action','SAVE & REBOOT','reboot'};a[#a+1]={'action','< BACK','back'};pwRows=a end
function pwRead()if not rfReady or pwReading then return end;pwReading=true;pwState='READING FC...';local pending=4;local function done()pending=pending-1;if pending<=0 then pwReading=false;pwState='CONNECTED / READY';pwBuildRows()end end
 rf2.mspQueue:add({command=32,processReply=function(_,b)b.offset=1;pwBat.capacity=rf2.mspHelper.readU16(b);pwBat.cellCount=rf2.mspHelper.readU8(b);pwBat.vSource=rf2.mspHelper.readU8(b);pwBat.cSource=rf2.mspHelper.readU8(b);pwBat.minCell=rf2.mspHelper.readU16(b);pwBat.maxCell=rf2.mspHelper.readU16(b);pwBat.fullCell=rf2.mspHelper.readU16(b);pwBat.warnCell=rf2.mspHelper.readU16(b);pwBat.lvc=rf2.mspHelper.readU8(b);pwBat.mahWarn=rf2.mspHelper.readU8(b);pwBat.capacities={};for i=1,6 do pwBat.capacities[i]=b.offset+1<=#b and rf2.mspHelper.readU16(b)or(i==1 and pwBat.capacity or 0)end;done()end,errorHandler=done})
 rf2.mspQueue:add({command=0x4000,processReply=function(_,b)b.offset=1;pwFuel.mode=rf2.mspHelper.readU8(b);pwFuel.voltageDrop=rf2.mspHelper.readU8(b);pwFuel.chargeDrop=rf2.mspHelper.readU8(b);pwFuel.sag=rf2.mspHelper.readU8(b);done()end,errorHandler=done})
 rf2.mspQueue:add({command=56,processReply=function(_,b)b.offset=1;pwVolt={};local n=rf2.mspHelper.readU8(b);for i=1,n do local len=rf2.mspHelper.readU8(b);if len==7 then pwVolt[#pwVolt+1]={id=rf2.mspHelper.readU8(b),type=rf2.mspHelper.readU8(b),scale=rf2.mspHelper.readU16(b),divider=rf2.mspHelper.readU16(b),mult=rf2.mspHelper.readU8(b)}else for j=1,len do rf2.mspHelper.readU8(b)end end end;done()end,errorHandler=done})
 rf2.mspQueue:add({command=40,processReply=function(_,b)b.offset=1;pwCurr={};local n=rf2.mspHelper.readU8(b);for i=1,n do local len=rf2.mspHelper.readU8(b);if len==6 then pwCurr[#pwCurr+1]={id=rf2.mspHelper.readU8(b),type=rf2.mspHelper.readU8(b),scale=pwS16(b),offset=pwS16(b)}else for j=1,len do rf2.mspHelper.readU8(b)end end end;done()end,errorHandler=done});pwReadLive()
end
function pwReadLive()if not rfReady or pwLiveBusy then return end;pwLiveBusy=true;rf2.mspQueue:add({command=130,processReply=function(_,b)b.offset=1;pwLive.state=rf2.mspHelper.readU8(b);pwLive.cells=rf2.mspHelper.readU8(b);pwLive.capacity=rf2.mspHelper.readU16(b);pwLive.mah=rf2.mspHelper.readU16(b);pwLive.voltage=rf2.mspHelper.readU16(b);pwLive.current=rf2.mspHelper.readU16(b);pwLive.charge=rf2.mspHelper.readU8(b);if b.offset<=#b then pwLive.profile=rf2.mspHelper.readU8(b)end;pwLiveBusy=false end,errorHandler=function()pwLiveBusy=false end})end
function pwWriteBattery()local q={};rxWriteU16(q,pwBat.capacities[1]or pwBat.capacity);q[#q+1]=pwBat.cellCount;q[#q+1]=pwBat.vSource;q[#q+1]=pwBat.cSource;rxWriteU16(q,pwBat.minCell);rxWriteU16(q,pwBat.maxCell);rxWriteU16(q,pwBat.fullCell);rxWriteU16(q,pwBat.warnCell);q[#q+1]=pwBat.lvc;q[#q+1]=pwBat.mahWarn;for i=1,6 do rxWriteU16(q,pwBat.capacities[i]or 0)end;rxWrite(33,q,'POWER LIVE / NOT SAVED')end
function pwWriteFuel()rxWrite(0x4001,{pwFuel.mode,pwFuel.voltageDrop,pwFuel.chargeDrop,pwFuel.sag},'SMARTFUEL LIVE / NOT SAVED')end
function pwWriteMeter(kind,i)local d=kind=='v'and pwVolt[i]or pwCurr[i];if not d then return end;local q={d.id};if kind=='v'then rxWriteU16(q,d.scale);rxWriteU16(q,d.divider);q[#q+1]=d.mult;rxWrite(57,q,'VOLTAGE METER LIVE / NOT SAVED')else pwU16(q,d.scale);pwU16(q,d.offset);rxWrite(41,q,'CURRENT METER LIVE / NOT SAVED')end end
function pwValue(k)if k=='fuelMode'then return pwFuel.mode elseif string.sub(k,1,3)=='cap'then return pwBat.capacities[tonumber(string.sub(k,4))]or 0 elseif k=='voltageDrop'or k=='chargeDrop'or k=='sag'then return pwFuel[k]elseif string.sub(k,1,2)=='vs'then return pwVolt[tonumber(string.sub(k,3))].scale elseif string.sub(k,1,2)=='vd'then return pwVolt[tonumber(string.sub(k,3))].divider elseif string.sub(k,1,2)=='cs'then return pwCurr[tonumber(string.sub(k,3))].scale elseif string.sub(k,1,2)=='co'then return pwCurr[tonumber(string.sub(k,3))].offset else return pwBat[k]or 0 end end
function pwCommit(k,v)if string.sub(k,1,3)=='cap'then pwBat.capacities[tonumber(string.sub(k,4))]=v;pwWriteBattery()elseif k=='voltageDrop'or k=='chargeDrop'or k=='sag'then pwFuel[k]=v;pwWriteFuel()elseif string.sub(k,1,2)=='vs'or string.sub(k,1,2)=='vd'then local i=tonumber(string.sub(k,3));if string.sub(k,1,2)=='vs'then pwVolt[i].scale=v else pwVolt[i].divider=v end;pwWriteMeter('v',i)elseif string.sub(k,1,2)=='cs'or string.sub(k,1,2)=='co'then local i=tonumber(string.sub(k,3));if string.sub(k,1,2)=='cs'then pwCurr[i].scale=v else pwCurr[i].offset=v end;pwWriteMeter('c',i)else pwBat[k]=v;pwWriteBattery()end;pwBuildRows()end
function pwChoose(k)local items=k=='fuelMode'and pwFuelSources or pwSources;local cur=k=='fuelMode'and pwFuel.mode or pwBat[k];openChoice('SELECT '..string.upper(k),items,cur+1,function(v)if k=='fuelMode'then pwFuel.mode=v;pwWriteFuel()else pwBat[k]=v;pwWriteBattery()end;pwBuildRows()end)end
function pwActivate(i)local r=pwRows[i];if not r or r[1]=='section'or r[1]=='live'then return end;pwSel=i;if r[1]=='choice'then pwChoose(r[3])elseif r[1]=='number'then beginNumber('power',r[3],pwValue(r[3]),r[4],r[5])elseif r[3]=='read'then pwRead()elseif r[3]=='save'or r[3]=='reboot'then pwState='SAVING EEPROM...';rf2.mspQueue:add({command=250,processReply=function()pwState='SAVED TO FC';if r[3]=='reboot'then rf2.mspQueue:add({command=68,payload={0}})end end,errorHandler=function()pwState='SAVE FAILED - DISARM FC'end})elseif r[3]=='back'then page='full'end end
function pwLiveText(k)if k=='state'then return pwLive.state==0 and'DISCONNECTED'or'CONNECTED'elseif k=='voltage'then return string.format('%.2f V',pwLive.voltage/100)elseif k=='current'then return string.format('%.2f A',pwLive.current/100)elseif k=='mah'then return pwLive.mah..' mAh'elseif k=='charge'then return pwLive.charge..' %'elseif k=='cells'then return tostring(pwLive.cells)elseif k=='profile'then return 'P'..tostring((pwLive.profile or 0)+1)end end
function drawPower()pwBuildRows();header('POWER',pwState);for i,n in ipairs(pwTabs)do local x=170+(i-1)*112;button('pwTab'..i,n,x,62,105,34,pwTab==i,{kind='pwTab',value=i},i==1 and'green'or(i==2 and'orange'or'cyan'))end;local visible=7;if pwSel< pwScroll then pwScroll=pwSel elseif pwSel>=pwScroll+visible then pwScroll=pwSel-visible+1 end;pwScroll=math.max(1,math.min(math.max(1,#pwRows-visible+1),pwScroll));local y=104
 for i=pwScroll,math.min(#pwRows,pwScroll+visible-1)do local r=pwRows[i];local sec=r[1]=='section';fill(20,y,720,40,sec and'panel2'or(pwSel==i and'panel2'or'panel'));box(20,y,720,40,pwSel==i and'cyan'or'line');if sec then fill(20,y,8,40,'purple');txt(42,y+12,r[2],'cyan',true)else txt(34,y+12,r[2],pwSel==i and'cyan'or'text');local label;if r[1]=='live'then label=pwLiveText(r[3])elseif r[1]=='choice'then local v=pwValue(r[3]);label=(r[3]=='fuelMode'and pwFuelSources[v+1]or pwSources[v+1])[1]elseif r[1]=='number'then local v=pwValue(r[3]);label=(r[3]=='minCell'or r[3]=='maxCell'or r[3]=='fullCell'or r[3]=='warnCell')and string.format('%.2f V',v/100)or tostring(v)else label=r[2]end;button('pwRow'..i,label,500,y+5,222,30,pwSel==i,{kind='pwRow',index=i},(r[3]=='save'or r[3]=='reboot')and'orange'or'cyan')end;y=y+44 end
 button('pwUp','^',748,105,32,34,false,{kind='pwScroll',delta=-3},'cyan');fill(758,145,10,210,'line');local th=math.max(24,math.floor(210*visible/#pwRows));local ty=145+math.floor((210-th)*(pwScroll-1)/math.max(1,#pwRows-visible));fill(753,ty,20,th,'orange');button('pwDown','v',748,364,32,34,false,{kind='pwScroll',delta=3},'cyan');footer('Live values refresh automatically. Changes apply to FC; SAVE writes EEPROM.')
end


cfgRows={
 {'section','PERSONALIZATION'}, {'text','Aircraft Name','name'}, {'number','Model ID','model',0,99},
 {'section','FLIGHT STATISTICS'}, {'toggle','Enable Flight Statistics','statsEnable'}, {'number','Minimum Armed Time [s]','statsMin',0,99}, {'info','Flight Count / Time / Distance','statsInfo'}, {'action','Reset Flight Statistics','statsReset'},
 {'section','SYSTEM CONFIGURATION'}, {'info','Gyro Update Frequency','gyroRate'}, {'number','PID Loop Denominator','pidDenom',1,16}, {'toggle','Accelerometer','accOn'}, {'toggle','Barometer','baroOn'}, {'toggle','Magnetometer','magOn'},
 {'section','FEATURES'}, {'toggle','Telemetry','feature10'}, {'toggle','GPS','feature7'}, {'toggle','LED Strip','feature16'}, {'toggle','ESC Sensor','feature27'},
 {'section','SERIAL PORTS  ! LINK MAY DISCONNECT !'}, {'action','ALLOW SERIAL PORT CHANGES','serialUnlock'},
 {'section','ALIGNMENT & TRIM'}, {'action','ALIGNMENT & 3D HELICOPTER >','align3d'},
 {'action','READ FC','read'}, {'action','SAVE & REBOOT','save'}, {'action','< BACK','back'}
}
function cfgU32(b)local a=rf2.mspHelper.readU16(b);local c=rf2.mspHelper.readU16(b);return a+c*65536 end
function cfgRead()
 if not rfReady then cfgState='FC OFFLINE';return end;cfgState='READING FC...'
 nameApi.getModelName(function(_,v)cfgName=v or''end,nil)
 if rf2.apiVersion>=12.07 then pilotApi.read(function(_,v)cfgPilot=v end,nil,cfgPilot)end
 if rf2.apiVersion>=12.09 then statsApi.read(function(_,v)cfgStats=v end,nil,cfgStats)end
 accTrimApi.read(function(_,v)cfgAcc=v;if(page=='easyTrim'or page=='easyBoardMenu')and not easyTrimDirty and cfgAcc then easyTrimDraft={roll=cfgAcc.roll_trim.value or 0,pitch=cfgAcc.pitch_trim.value or 0};easyState='ACC TRIM LOADED'end end,nil,cfgAcc)
 rf2.mspQueue:add({command=36,processReply=function(_,b)b.offset=1;cfgFeature=cfgU32(b)end})
 rf2.mspQueue:add({command=90,processReply=function(_,b)b.offset=1;cfgAdvanced.gyro=rf2.mspHelper.readU8(b);cfgAdvanced.pid=rf2.mspHelper.readU8(b)end})
 rf2.mspQueue:add({command=96,processReply=function(_,b)b.offset=1;cfgSensor.acc=rf2.mspHelper.readU8(b);cfgSensor.baro=rf2.mspHelper.readU8(b);cfgSensor.mag=rf2.mspHelper.readU8(b);cfgSensor.gyro=rf2.mspHelper.readU8(b);cfgSensor.fsr=rf2.mspHelper.readU8(b);cfgSensor.move=rf2.mspHelper.readU8(b);cfgSensor.duration=rf2.mspHelper.readU16(b);cfgSensor.yaw=rf2.mspHelper.readU16(b);cfgSensor.overflow=rf2.mspHelper.readU8(b)end})
 rf2.mspQueue:add({command=126,processReply=function(_,b)b.offset=1;cfgSensorAlign.gyro1=rf2.mspHelper.readU8(b);cfgSensorAlign.gyro2=rf2.mspHelper.readU8(b);cfgSensorAlign.mag=rf2.mspHelper.readU8(b)end})
 rf2.mspQueue:add({command=38,processReply=function(_,b)b.offset=1;cfgAlign.roll=rf2.mspHelper.readS16(b);cfgAlign.pitch=rf2.mspHelper.readS16(b);cfgAlign.yaw=rf2.mspHelper.readS16(b);if(page=='easyAlign'or page=='easyBoardMenu')and not easyDirty then easyDraft={roll=cfgAlign.roll,pitch=cfgAlign.pitch,yaw=cfgAlign.yaw};easyFacing=math.floor(((cfgAlign.yaw or 0)%360+45)/90)%4;easyFlip=math.abs(cfgAlign.roll or 0)>=135;easyState='FC ALIGNMENT LOADED'end end})
 rf2.mspQueue:add({command=54,processReply=function(_,b)b.offset=1;cfgPorts={};while b.offset+8<=#b+1 do local q={id=rf2.mspHelper.readU8(b),mask=cfgU32(b),baud={}};for j=1,4 do q.baud[j]=rf2.mspHelper.readU8(b)end;cfgPorts[#cfgPorts+1]=q end;cfgState='CONNECTED / READY'end,errorHandler=function()cfgState='SERIAL READ ERROR'end})
end
function cfgWriteU32(q,v)rf2.mspHelper.writeU32(q,v)end
function cfgWriteGroup(g)
 if not rfReady then cfgState='FC OFFLINE';return end;local q={}
 if g=='pilot'and cfgPilot then pilotApi.write(cfgPilot)
 elseif g=='stats'and cfgStats then statsApi.write(cfgStats)
 elseif g=='accTrim'and cfgAcc then accTrimApi.write(cfgAcc)
 elseif g=='feature'then cfgWriteU32(q,cfgFeature);rf2.mspQueue:add({command=37,payload=q})
 elseif g=='advanced'then q={cfgAdvanced.gyro,cfgAdvanced.pid};rf2.mspQueue:add({command=91,payload=q})
 elseif g=='sensor'then q={cfgSensor.acc,cfgSensor.baro,cfgSensor.mag,cfgSensor.gyro,cfgSensor.fsr,cfgSensor.move};rf2.mspHelper.writeU16(q,cfgSensor.duration);rf2.mspHelper.writeU16(q,cfgSensor.yaw);q[#q+1]=cfgSensor.overflow;rf2.mspQueue:add({command=97,payload=q})
 elseif g=='align'then rf2.mspHelper.writeU16(q,cfgAlign.roll);rf2.mspHelper.writeU16(q,cfgAlign.pitch);rf2.mspHelper.writeU16(q,cfgAlign.yaw);rf2.mspQueue:add({command=39,payload=q})
 elseif g=='sensorAlign'then q={cfgSensorAlign.gyro1,cfgSensorAlign.gyro2,cfgSensorAlign.mag};rf2.mspQueue:add({command=220,payload=q})end
 cfgState='LIVE ON FC / NOT SAVED'
end
function cfgValue(key)
 if key=='name'then return cfgName~=''and cfgName or'N/A' elseif key=='model'then return cfgPilot and cfgPilot.model_id.value or'N/A'
 elseif key=='statsEnable'then return cfgStats and cfgStats.stats_min_armed_time_s.value>=0 elseif key=='statsMin'then return cfgStats and math.max(0,cfgStats.stats_min_armed_time_s.value)or 0
 elseif key=='statsInfo'then return cfgStats and(tostring(cfgStats.stats_total_flights.value)..' / '..tostring(cfgStats.stats_total_time_s.value)..'s / '..tostring(cfgStats.stats_total_dist_m.value)..'m')or'N/A'
 elseif key=='gyroRate'then return 'FC gyro sample rate' elseif key=='pidDenom'then return cfgAdvanced.pid
 elseif key=='accOn'then return cfgSensor.acc~=1 elseif key=='baroOn'then return cfgSensor.baro~=1 elseif key=='magOn'then return cfgSensor.mag~=1
 elseif string.sub(key,1,7)=='feature'then return bit32.btest(cfgFeature,tonumber(string.sub(key,8)))
 elseif string.sub(key,1,4)=='port'then local u=tonumber(string.sub(key,5));local q=nil;for _,p in ipairs(cfgPorts)do if p.id==u-1 then q=p;break end end;return q and(cfgPortFunctions[cfgPortFuncIndex(q.mask)][1]..'  /  '..cfgPortBaudText(q.mask,q.baud[cfgPortSlot(q.mask)]))or'Not detected'
 elseif key=='alignRoll'then return cfgAlign.roll elseif key=='alignPitch'then return cfgAlign.pitch elseif key=='alignYaw'then return cfgAlign.yaw elseif key=='gyro1Align'then return cfgSensorAlign.gyro1 elseif key=='gyro2Align'then return cfgSensorAlign.gyro2 elseif key=='magAlign'then return cfgSensorAlign.mag
 elseif key=='trimRoll'then return cfgAcc and cfgAcc.roll_trim.value or 0 elseif key=='trimPitch'then return cfgAcc and cfgAcc.pitch_trim.value or 0 end;return''
end
function cfgCommit(key,v)
 if key=='model'and cfgPilot then cfgPilot.model_id.value=v;cfgWriteGroup('pilot') elseif key=='statsMin'and cfgStats then cfgStats.stats_min_armed_time_s.value=v;cfgWriteGroup('stats')
 elseif key=='pidDenom'then cfgAdvanced.pid=v;cfgWriteGroup('advanced') elseif key=='alignRoll'then cfgAlign.roll=v;cfgWriteGroup('align') elseif key=='alignPitch'then cfgAlign.pitch=v;cfgWriteGroup('align') elseif key=='alignYaw'then cfgAlign.yaw=v;cfgWriteGroup('align')
 elseif key=='gyro1Align'then cfgSensorAlign.gyro1=v;cfgWriteGroup('sensorAlign') elseif key=='gyro2Align'then cfgSensorAlign.gyro2=v;cfgWriteGroup('sensorAlign') elseif key=='magAlign'then cfgSensorAlign.mag=v;cfgWriteGroup('sensorAlign') elseif key=='trimRoll'and cfgAcc then cfgAcc.roll_trim.value=v;cfgWriteGroup('accTrim') elseif key=='trimPitch'and cfgAcc then cfgAcc.pitch_trim.value=v;cfgWriteGroup('accTrim')end
end
function cfgToggle(key)
 if key=='statsEnable'and cfgStats then cfgStats.stats_min_armed_time_s.value=cfgStats.stats_min_armed_time_s.value>=0 and-1 or 15;cfgWriteGroup('stats')
 elseif key=='accOn'or key=='baroOn'or key=='magOn'then local k=key=='accOn'and'acc'or(key=='baroOn'and'baro'or'mag');cfgSensor[k]=cfgSensor[k]~=1 and 1 or 0;cfgWriteGroup('sensor')
 elseif string.sub(key,1,7)=='feature'then local n=tonumber(string.sub(key,8));cfgFeature=bit32.bxor(cfgFeature,bit32.lshift(1,n));cfgWriteGroup('feature')end
end
function cfgActivate(i)
 local r=cfgRows[i];if not r or r[1]=='section'or r[1]=='info'then return end;cfgSel=i
 if r[1]=='text'then cfgNameEdit={text=cfgName or'',original=cfgName or''};cfgNameFocus=1 elseif r[1]=='number'then beginNumber('config',r[3],cfgValue(r[3]),r[4],r[5]) elseif r[1]=='toggle'then cfgToggle(r[3]) elseif r[3]=='statsReset'and cfgStats then cfgStats.stats_total_flights.value=0;cfgStats.stats_total_time_s.value=0;cfgStats.stats_total_dist_m.value=0;cfgWriteGroup('stats')
 elseif r[3]=='serialUnlock'then cfgSerialConfirm=true elseif string.sub(r[3]or'',1,4)=='port'then cfgPortOpen(tonumber(string.sub(r[3],5))) elseif r[3]=='align3d'then page='configuration3d';cfg3dSel=1;cfg3dScroll=1;statusLiveAt=-1000;requestStatusLive() elseif r[3]=='read'then cfgRead() elseif r[3]=='save'then cfgSaveConfirm=true elseif r[3]=='back'then page='full' end
end
function cfgSaveReboot()
 cfgSaveConfirm=false;cfgState='SAVING EEPROM...';rf2.mspQueue:add({command=250,processReply=function()cfgState='SAVED / REBOOTING';rf2.mspQueue:add({command=68,payload={0}})end,errorHandler=function()cfgState='SAVE FAILED - DISARM FC'end})
end
function drawCfgConfirm()hit={};fill(100,110,600,250,'panel');box(100,110,600,250,'orange');fill(100,110,600,42,'orange');txt(125,123,'SAVE CONFIGURATION & REBOOT?','text',true);txt(135,185,'All live Configuration changes will be written to EEPROM.','text');txt(135,218,'The FC connection will close while the controller reboots.','muted');button('cfgNo','CANCEL',190,292,180,44,false,{kind='cfgSaveNo'},'cyan');button('cfgYes','SAVE & REBOOT',420,292,190,44,false,{kind='cfgSaveYes'},'orange')end
function drawConfiguration()
 header('CONFIGURATION',cfgState);local visible=7;if cfgSel<cfgScroll then cfgScroll=cfgSel elseif cfgSel>=cfgScroll+visible then cfgScroll=cfgSel-visible+1 end;cfgScroll=math.max(1,math.min(#cfgRows-visible+1,cfgScroll));local y=104
 for i=cfgScroll,math.min(#cfgRows,cfgScroll+visible-1)do local r=cfgRows[i];if r[1]=='section'then local danger=string.sub(r[2],1,12)=='SERIAL PORTS';fill(20,y,720,40,'panel2');fill(20,y,8,40,danger and'red'or'purple');box(20,y,720,40,danger and'red'or'line');txt(42,y+12,r[2],danger and'red'or'cyan',true)else fill(20,y,720,40,cfgSel==i and'panel2'or'panel');box(20,y,720,40,cfgSel==i and'cyan'or'line');txt(34,y+12,r[2],cfgSel==i and'cyan'or'text');local v=cfgValue(r[3]);if r[1]=='toggle'then button('cfgOff'..i,'OFF',590,y+5,62,30,not v,{kind='cfgToggle',index=i},'orange');button('cfgOn'..i,'ON',660,y+5,62,30,v,{kind='cfgToggle',index=i},'cyan')elseif r[1]=='number'or r[1]=='action'or r[1]=='serial'then button('cfgRow'..i,r[1]=='action'and r[2]or tostring(v),535,y+5,187,30,cfgSel==i,{kind='cfgRow',index=i},r[1]=='action'and'orange'or'cyan')else txt(475,y+12,tostring(v),'muted')end end;y=y+44 end
 button('cfgUp','^',748,105,32,34,false,{kind='cfgScroll',delta=-3},'cyan');fill(758,145,10,210,'line');local th=math.max(24,math.floor(210*visible/#cfgRows));local ty=145+math.floor((210-th)*(cfgScroll-1)/math.max(1,#cfgRows-visible));fill(753,ty,20,th,'cyan');button('cfgDown','v',748,364,32,34,false,{kind='cfgScroll',delta=3},'cyan');footer('Touch-drag or roller to scroll. Changes apply live; SAVE & REBOOT writes EEPROM.')
end

function cfgSerialUnlock()
 cfgSerialConfirm=false;if cfgSerialUnlocked then return end;cfgSerialUnlocked=true
 for i,r in ipairs(cfgRows)do if r[3]=='serialUnlock'then table.remove(cfgRows,i);local names={'S.BUS (UART1)','TELEM (UART2)','Port C (UART3)','Port A (UART4)','Int.Rx (UART5)','Port B (UART6)'};for n=6,1,-1 do table.insert(cfgRows,i,{'serial',names[n],'port'..n})end;cfgSel=i;cfgScroll=math.max(1,i-1);break end end
 cfgState='SERIAL EDITING ENABLED - LINK MAY DISCONNECT'
end
function drawCfgSerialConfirm()
 hit={};fill(80,95,640,290,'panel');box(80,95,640,290,'red');fill(80,95,640,46,'red');txt(105,109,'WARNING: SERIAL PORT CHANGES','text',true);txt(112,165,'Changing RX, telemetry or MSP port settings can immediately','orange',true);txt(112,195,'disconnect this Lua script from the flight controller.','orange',true);txt(112,235,'Show detected ports and allow editing?','text');button('serialNo','CANCEL',180,310,180,46,false,{kind='cfgSerialNo'},'cyan');button('serialYes','ALLOW CHANGES',420,310,200,46,false,{kind='cfgSerialYes'},'red')
end
cfgPortFunctions={{'Disabled',0},{'MSP',1},{'GPS',2},{'Serial RX',64},{'ESC Telemetry',1024},{'Blackbox',128},{'SBUS Output',262144},{'FBUS Output',524288},{'SmartPort Master',1048576},{'FrSky Telemetry',4},{'SmartPort Telemetry',32},{'IBUS Telemetry',4096},{'HoTT Telemetry',8},{'MAVLink Telemetry',512},{'LTM Telemetry',16}}
cfgBauds={'Auto','9600','19200','38400','57600','115200','230400','250000','400000','460800','500000','921600','1000000','1500000','2000000','2470000'}
function cfgPortType(mask)if mask==0 then return 0 elseif mask==1 then return 1 elseif mask==2 then return 2 elseif mask==128 then return 5 elseif mask==512 then return 4 elseif mask==4 or mask==8 or mask==16 or mask==32 or mask==4096 then return 3 else return 7 end end
function cfgPortBaudText(mask,code)local t=cfgPortType(mask);if t==0 then return'Disabled'elseif t==3 or t==7 then return'Auto'else return cfgBauds[(code or 0)+1]or'Auto'end end
function cfgPortBaudItems(mask)local t=cfgPortType(mask);local ids={};if t==1 then ids={2,3,4,5,6,7,8,10,11,12,13}elseif t==2 or t==4 then ids={1,2,3,4,5,6,7,10}elseif t==5 then ids={1,3,4,5,6,7,8,10,11,12,13,14,15,16}else return nil end;local a={};for _,i in ipairs(ids)do a[#a+1]={cfgBauds[i],i}end;return a end
function cfgPortSlot(mask)if mask==1 then return 1 elseif mask==2 then return 2 elseif mask==128 then return 4 elseif mask==4 or mask==8 or mask==16 or mask==32 or mask==512 or mask==4096 then return 3 else return 1 end end
function cfgPortFuncIndex(mask)for i,v in ipairs(cfgPortFunctions)do if v[2]==mask then return i end end;return 1 end
function cfgPortOpen(u)local q=nil;local pi=nil;for i,p in ipairs(cfgPorts)do if p.id==u-1 then q=p;pi=i;break end end;if not q then cfgState='UART'..u..' NOT DETECTED';return end;local slot=cfgPortSlot(q.mask);cfgPortEdit={index=pi,uart=u,func=cfgPortFuncIndex(q.mask),baud=(q.baud[slot]or 0)+1,focus=1,confirm=false}end
function cfgWritePorts()
 local q={};for _,p in ipairs(cfgPorts)do q[#q+1]=p.id;rf2.mspHelper.writeU32(q,p.mask);for j=1,4 do q[#q+1]=p.baud[j]or 0 end end
 rf2.mspQueue:add({command=55,payload=q,processReply=function()cfgState='SERIAL PORT LIVE / NOT SAVED'end,errorHandler=function()cfgState='SERIAL PORT WRITE FAILED'end})
end
function cfgPortApply()
 local e=cfgPortEdit;if not e then return end;local p=cfgPorts[e.index];p.mask=cfgPortFunctions[e.func][2];local slot=cfgPortSlot(p.mask);if cfgPortBaudItems(p.mask)then p.baud[slot]=e.baud-1 end;cfgPortEdit=nil;cfgWritePorts()
end
function cfgPortAction(a)
 local e=cfgPortEdit;if not e then return end
 if a=='func'then openChoice('SELECT PORT FUNCTION',cfgPortFunctions,e.func,function(v)for i,q in ipairs(cfgPortFunctions)do if q[2]==v then e.func=i;break end end;local items=cfgPortBaudItems(v);if items then local old=(cfgPorts[e.index].baud[cfgPortSlot(v)]or 0)+1;local found=false;for _,z in ipairs(items)do if z[2]==old then found=true;break end end;e.baud=found and old or items[1][2]else e.baud=1 end end)
 elseif a=='baud'then local mask=cfgPortFunctions[e.func][2];local items=cfgPortBaudItems(mask);if items then openChoice('SELECT BAUD RATE',items,e.baud,function(v)e.baud=v end)else cfgState='BAUD RATE IS '..string.upper(cfgPortBaudText(mask,0))end
 elseif a=='apply'then e.confirm=true elseif a=='yes'then cfgPortApply() elseif a=='no'then e.confirm=false elseif a=='cancel'then cfgPortEdit=nil;cfgState='SERIAL CHANGE CANCELLED'end
end
function drawCfgPortEditor()
 local e=cfgPortEdit;if not e then return end;hit={};fill(90,88,620,310,'panel');box(90,88,620,310,'cyan');fill(90,88,620,40,'purple');local p=cfgPorts[e.index];txt(115,101,'SERIAL PORT   UART'..tostring(e.uart)..'   [ID '..tostring(p.id)..']','text',true)
 if e.confirm then txt(125,164,'WARNING: changing this port can disconnect Lua telemetry.','orange',true);txt(125,205,'Apply the selected Function and Baud Rate to the FC?','text');button('portNo','CANCEL',180,292,180,44,false,{kind='cfgPortAction',value='no'},'cyan');button('portYes','APPLY',430,292,180,44,false,{kind='cfgPortAction',value='yes'},'orange');return end
 txt(125,158,'Function','text');button('portFunc',cfgPortFunctions[e.func][1],350,144,300,42,e.focus==1,{kind='cfgPortAction',value='func'},'cyan');txt(125,218,'Baud Rate','text');button('portBaud',cfgPortBaudText(cfgPortFunctions[e.func][2],e.baud-1),350,204,300,42,e.focus==2,{kind='cfgPortAction',value='baud'},'cyan');button('portApply','APPLY',350,292,140,44,e.focus==3,{kind='cfgPortAction',value='apply'},'orange');button('portCancel','CANCEL',510,292,140,44,e.focus==4,{kind='cfgPortAction',value='cancel'},'cyan');txt(125,354,'APPLY changes FC RAM. SAVE & REBOOT writes EEPROM.','muted')
end
cfgNameKeys={'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','0','1','2','3','4','5','6','7','8','9','SPACE','-','_','DEL','CLEAR','CANCEL','OK'}
function cfgNameAction(v)
 if not cfgNameEdit then return end
 if v=='CANCEL'then cfgNameEdit=nil;cfgState='NAME CHANGE CANCELLED'
 elseif v=='OK'then local n=cfgNameEdit.text;if #n<1 then cfgState='AIRCRAFT NAME CANNOT BE EMPTY'else cfgName=n;nameApi.setModelName(n);cfgNameEdit=nil;cfgState='NAME LIVE ON FC / NOT SAVED'end
 elseif v=='DEL'then cfgNameEdit.text=string.sub(cfgNameEdit.text,1,math.max(0,#cfgNameEdit.text-1))
 elseif v=='CLEAR'then cfgNameEdit.text=''
 else local c=v=='SPACE'and' 'or v;if #cfgNameEdit.text<32 then cfgNameEdit.text=cfgNameEdit.text..c end end
end
function drawCfgNameKeyboard()
 local e=cfgNameEdit;if not e then return end;hit={};fill(38,72,724,356,'panel');box(38,72,724,356,'cyan');fill(38,72,724,40,'purple');txt(58,84,'AIRCRAFT NAME  (MAX 32)','text',true);fill(62,122,676,40,'panel2');box(62,122,676,40,'cyan');txt(76,134,e.text..(#e.text<32 and'_'or''),'text',true)
 for i,k in ipairs(cfgNameKeys)do local x,y,w;if i<=36 then local q=i-1;x=62+(q%9)*73;y=172+math.floor(q/9)*45;w=66 else local q=i-37;x=62+q*95;y=356;w=88 end;button('nameKey'..i,k,x,y,w,38,cfgNameFocus==i,{kind='cfgNameKey',value=k},(k=='OK'and'green')or(k=='CANCEL'and'orange')or'cyan')end
 txt(62,405,'Roller: select   ENTER: input   RTN: cancel','muted')
end
cfg3dRows={{'Board Roll [deg]','alignRoll',-180,360},{'Board Pitch [deg]','alignPitch',-180,360},{'Board Yaw [deg]','alignYaw',-180,360},{'Gyro 1 Alignment','gyro1Align',0,8},{'Gyro 2 Alignment','gyro2Align',0,8},{'Magnetometer Alignment','magAlign',0,8},{'Accelerometer Roll Trim [0.1 deg]','trimRoll',-300,300},{'Accelerometer Pitch Trim [0.1 deg]','trimPitch',-300,300}}
cfg3dSel=1;cfg3dScroll=1
function cfg3dActivate(i)local r=cfg3dRows[i];if not r then return end;cfg3dSel=i;beginNumber('config',r[2],cfgValue(r[2]),r[3],r[4])end
function drawConfiguration3d()
 header('ALIGNMENT & 3D HELICOPTER',cfgState);statusCard(20,100,760,158,'LIVE ATTITUDE','purple');drawStatusHeli(400,188,0.82);txt(40,226,string.format('ROLL %+.1f  PITCH %+.1f',statusLive.roll or 0,statusLive.pitch or 0),'cyan');txt(610,226,string.format('YAW %+.0f',statusAngleDelta(statusLive.yaw,statusYawOffset)),'green')
 local visible=2;if cfg3dSel<cfg3dScroll then cfg3dScroll=cfg3dSel elseif cfg3dSel>=cfg3dScroll+visible then cfg3dScroll=cfg3dSel-visible+1 end;cfg3dScroll=math.max(1,math.min(#cfg3dRows-visible+1,cfg3dScroll));local y=270
 for i=cfg3dScroll,math.min(#cfg3dRows,cfg3dScroll+visible-1)do local r=cfg3dRows[i];fill(20,y,700,42,cfg3dSel==i and'panel2'or'panel');box(20,y,700,42,cfg3dSel==i and'cyan'or'line');txt(34,y+13,r[1],cfg3dSel==i and'cyan'or'text');button('cfg3dRow'..i,tostring(cfgValue(r[2])),540,y+5,165,32,cfg3dSel==i,{kind='cfg3dRow',index=i},'cyan');y=y+47 end
 button('cfg3dUp','^',738,270,42,36,false,{kind='cfg3dScroll',delta=-1},'cyan');fill(753,310,12,54,'line');local ty=310+math.floor(30*(cfg3dScroll-1)/math.max(1,#cfg3dRows-visible));fill(748,ty,22,24,'cyan');button('cfg3dDown','v',738,368,42,36,false,{kind='cfg3dScroll',delta=1},'cyan');button('cfg3dReset','RESET Z',420,411,160,34,false,{kind='statusResetZ'},'orange');button('cfg3dBack','< CONFIG',600,411,180,34,false,{kind='cfg3dBack'},'cyan');footer('Enter Board Roll/Pitch/Yaw while watching the live helicopter.')
end
setupRows={
 {'Calibrate Accelerometer','Place FC level and keep it completely still.','acc',true},
 {'Calibrate Magnetometer','Rotate aircraft 360 degrees on every axis.','mag',false},
 {'Reset Settings','Restore all FC settings to defaults and reboot.','reset',true},
 {'Save Settings','Write current settings to FC EEPROM.','save',true},
 {'Boot Loader / DFU','Restart FC in ROM bootloader / DFU mode.','dfu',true},
 {'Mass Storage Mode','Restart FC in USB mass-storage mode.','msc',true},
 {'System Reboot','Restart and reinitialize the flight controller.','reboot',true}
}
function setupSend(action)
 if not rfReady then setupState='FC OFFLINE';return end
 local command,payload,label
 if action=='acc'then command=205;label='ACCELEROMETER CALIBRATION STARTED'
 elseif action=='mag'then command=206;label='MAGNETOMETER CALIBRATION STARTED'
 elseif action=='reset'then command=208;payload={0};label='RESETTING SETTINGS / REBOOTING'
 elseif action=='save'then command=250;label='SETTINGS SAVED TO EEPROM'
 elseif action=='dfu'then command=68;payload={1};label='REBOOTING TO BOOTLOADER / DFU'
 elseif action=='msc'then command=68;payload={2};label='REBOOTING TO MASS STORAGE'
 elseif action=='reboot'then command=68;payload={0};label='REBOOTING FC'else return end
 setupState='SENDING...'
 rf2.mspQueue:add({command=command,payload=payload,processReply=function()setupState=label end,errorHandler=function()setupState='COMMAND FAILED - CHECK DISARM / FC SUPPORT'end})
 if command==68 then setupState=label end
end
function setupAsk(index)
 local r=setupRows[index];if not r or not r[4]then setupState='NOT AVAILABLE ON THIS FC';return end
 setupSel=index
 if r[3]=='save'then setupSend('save')else setupConfirm={index=index,yes=false}end
end
function drawSetupConfirm()
 local c=setupConfirm;if not c then return end;local r=setupRows[c.index];hit={};fill(95,105,610,270,'panel');box(95,105,610,270,'orange');fill(95,105,610,42,'orange');txt(118,118,'CONFIRM SETUP COMMAND','text',true);txt(125,172,r[1],'cyan',true);txt(125,210,r[2],'text');txt(125,246,(r[3]=='acc')and'DISARM. Keep the FC level and motionless.'or'DISARM before continuing.','orange',true);button('setupNo','CANCEL',190,306,180,44,not c.yes,{kind='setupConfirmNo'},'cyan');button('setupYes','CONTINUE',430,306,180,44,c.yes,{kind='setupConfirmYes'},'orange')
end
function easyNormalize(v)v=v%360;if v>180 then v=v-360 end;return v end
function easyPreset()
 easyDraft.yaw=easyFacing*90;easyDraft.roll=easyFlip and 180 or 0;easyDraft.pitch=0;easyDirty=true;easyState='PREVIEW / NOT SAVED'
end
function easyRotate(delta)easyFacing=(easyFacing+delta)%4;easyPreset()end
function easyFlipBoard()easyFlip=not easyFlip;easyPreset()end
function easyCommitNumber(key,v)easyDraft[key]=easyNormalize(v);if key=='yaw'then easyFacing=math.floor(((easyDraft.yaw%360)+45)/90)%4 elseif key=='roll'then easyFlip=math.abs(easyDraft.roll)>=135 end;easyDirty=true;easyState='CUSTOM / NOT SAVED'end
function easySave()
 if not rfReady then easyState='FC OFFLINE';easyConfirm=false;return end
 cfgAlign.roll=easyDraft.roll;cfgAlign.pitch=easyDraft.pitch;cfgAlign.yaw=easyDraft.yaw;easyConfirm=false;easyState='APPLYING ALIGNMENT...';cfgWriteGroup('align')
 rf2.mspQueue:add({command=250,processReply=function()easyDirty=false;easyState='SAVED TO FC'end,errorHandler=function()easyState='SAVE FAILED - DISARM FC'end})
end
function easyLine(x1,y1,x2,y2,c,w)if statusDotLine then statusDotLine(x1,y1,x2,y2,c,w or 3)elseif lcd.drawLine then lcd.drawLine(sx(x1),sy(y1),sx(x2),sy(y2),col(c))end end
function drawEasyHeli()
 local cx,cy=258,238
 -- clean top-view helicopter: rounded nose, circular main/tail rotors
 txt(cx-46,cy-153,'HELI FRONT','orange',true)
 local function easyCircle(ox,oy,rad,color,width)local px,py=ox+rad,oy;for i=1,32 do local a=i*math.pi*2/32;local nx,ny=ox+math.cos(a)*rad,oy+math.sin(a)*rad;easyLine(px,py,nx,ny,color,width or 2);px,py=nx,ny end end
 -- main rotor disc and mast
 easyCircle(cx,cy-30,74,'text',2);easyLine(cx-70,cy-30,cx+70,cy-30,'text',5);easyLine(cx,cy-100,cx,cy+40,'text',5);easyCircle(cx,cy-30,7,'cyan',3)
 -- rounded canopy and fuselage
 easyLine(cx-30,cy-80,cx-18,cy-96,'cyan',5);easyLine(cx-18,cy-96,cx,cy-103,'cyan',5);easyLine(cx,cy-103,cx+18,cy-96,'cyan',5);easyLine(cx+18,cy-96,cx+30,cy-80,'cyan',5)
 easyLine(cx-30,cy-80,cx-46,cy-48,'cyan',5);easyLine(cx-46,cy-48,cx-40,cy+46,'cyan',5);easyLine(cx-40,cy+46,cx,cy+68,'cyan',5);easyLine(cx,cy+68,cx+40,cy+46,'cyan',5);easyLine(cx+40,cy+46,cx+46,cy-48,'cyan',5);easyLine(cx+46,cy-48,cx+30,cy-80,'cyan',5)
 -- tail boom and tail rotor on rear-right side
 easyLine(cx,cy+68,cx,cy+121,'cyan',6);easyLine(cx,cy+116,cx+30,cy+116,'orange',4);easyLine(cx+30,cy+96,cx+30,cy+136,'orange',6)
 -- two clean skids viewed from above
 easyLine(cx-59,cy-45,cx-59,cy+62,'text',4);easyLine(cx+59,cy-45,cx+59,cy+62,'text',4);easyLine(cx-59,cy-18,cx-38,cy-8,'muted',3);easyLine(cx+59,cy-18,cx+38,cy-8,'muted',3);easyLine(cx-59,cy+40,cx-38,cy+32,'muted',3);easyLine(cx+59,cy+40,cx+38,cy+32,'muted',3)
 -- NEXUS-XR photo supplied by the user; orientation follows the FC yaw preset
 local bx,by=cx,cy-10;local vertical=easyFacing%2==0;local bw=vertical and 50 or 90;local bh=vertical and 90 or 50
 local bmps=easyFlip and easyNexusBackBmps or easyNexusBmps;local bmp=bmps and bmps[easyFacing+1];if bmp and lcd.drawBitmap then lcd.drawBitmap(bmp,sx(bx-bw/2),sy(by-bh/2))else fill(bx-bw/2,by-bh/2,bw,bh,easyFlip and'pid'or'blue');box(bx-bw/2,by-bh/2,bw,bh,easyFlip and'orange'or'cyan')end txt(168,342,easyFlip and'BOARD BOTTOM UP'or'BOARD TOP UP',easyFlip and'orange'or'green',true)
 if not easyFlip and easyFacing==0 then txt(126,363,'DEFAULT: ROLL 0  PITCH 0  YAW 0','cyan',true)end
end
function drawEasyConfirm()
 hit={};fill(105,116,590,242,'panel');box(105,116,590,242,'orange');fill(105,116,590,42,'orange');txt(128,129,'APPLY FC ALIGNMENT & SAVE?','text',true);txt(135,185,string.format('ROLL %d   PITCH %d   YAW %d',easyDraft.roll,easyDraft.pitch,easyDraft.yaw),'cyan',true);txt(135,222,'DISARM and remove main/tail blades before continuing.','orange');button('easyNo','CANCEL',190,292,180,44,false,{kind='easyNo'},'cyan');button('easyYes','APPLY & SAVE',420,292,190,44,false,{kind='easyYes'},'orange')
end
easySteps={'BOARD & SENSOR ALIGNMENT','RECEIVER SETUP','SERVO / SWASH SETUP'}
function drawEasy()
 header('EASY SETUP','SELECT STEP');txt(20,94,'GUIDED HELICOPTER SETUP','cyan',true)
 for i,name in ipairs(easySteps)do local x=20;local y=122+(i-1)*66;local w=760;local focus=easyMenuFocus==i;fill(x,y,w,54,focus and'panel2'or'panel');box(x,y,w,54,focus and'cyan'or'line');fill(x,y,8,54,i==1 and'cyan'or'green');txt(x+18,y+16,tostring(i)..'. '..name,focus and'cyan'or'text',true);txt(x+w-82,y+18,'OPEN >','green');add('easyStep'..i,x,y,w,54,{kind='easyStep',index=i})end
 button('easyMenuBack','< HOME',610,400,170,36,easyMenuFocus==#easySteps+1,{kind='easyMenuBack'},'cyan');footer('Step 3: SERVO CENTER TRIM / grouped override / selected Center apply.')
end
function drawEasyReceiver()
 header('EASY SETUP  2/12','RECEIVER CHECK / READ ONLY')
 local pi=rxProtocolIndex();local proto=(rxProtocols[pi]and rxProtocols[pi][1])or'UNKNOWN';local telem=bit32.btest(rxFeature,bit32.lshift(1,10));local linked=rfReady and statusLive.state~='WAITING FC';local sensors=rxSensorTotal();local lo=(rxRc.center or 1500)-(rxRc.deflection or 500);local hi=(rxRc.center or 1500)+(rxRc.deflection or 500)
 fill(20,94,760,70,'panel2');box(20,94,760,70,'line');txt(36,106,'PROTOCOL','muted');txt(36,130,proto,'cyan',true);txt(278,106,'TELEMETRY','muted');txt(278,130,telem and('ON / '..sensors..' SENSORS')or'OFF',telem and'green'or'orange',true);txt(570,106,'FC LINK','muted');txt(570,130,linked and'LIVE'or'WAIT',linked and'green'or'orange',true)
 fill(20,170,760,42,'panel');box(20,170,760,42,'line');txt(36,184,string.format('CENTER %d us',rxRc.center or 1500),'cyan',true);txt(262,184,string.format('EXPECTED %d - %d us',lo,hi),'text',true);txt(610,184,'RSSI '..rxRssiText(),'orange',true)
 txt(30,220,'INPUT','muted',true);txt(106,220,'ASSIGNMENT / LIVE RANGE','muted',true);txt(650,220,'PWM','muted',true)
 easyRxScroll=math.max(1,math.min(4,easyRxScroll or 1));for row=1,5 do local ch=easyRxScroll+row-1;local y=240+(row-1)*31;local pwm=rxChannelPwm(ch);local fn=rxAssigned(ch);local name=rxNames[fn]or('CH'..fn);local q=math.max(0,math.min(1,(pwm-lo)/math.max(1,hi-lo)));local centered=math.abs(pwm-(rxRc.center or 1500))<=math.max(10,rxRc.deadband or 5);fill(28,y,704,27,'panel');box(28,y,704,27,'line');txt(40,y+7,'CH'..ch,'cyan',true);txt(104,y+7,name,ch<=5 and'text'or'muted',true);fill(264,y+8,330,11,'bg');fill(264,y+8,330*q,11,ch<=5 and'cyan'or'green');fill(428,y+4,2,19,'orange');box(264,y+8,330,11,'line');txt(622,y+7,tostring(pwm)..' us',centered and'green'or'text',true)end
 button('easyRxUp','^',744,238,36,36,easyRxFocus==1,{kind='easyRxScroll',delta=-1},'cyan');button('easyRxDown','v',744,356,36,36,easyRxFocus==2,{kind='easyRxScroll',delta=1},'cyan');button('easyRxRefresh','REFRESH',430,405,165,36,easyRxFocus==3,{kind='easyRxRefresh'},'green');button('easyRxBack','< BACK',610,405,170,36,easyRxFocus==4,{kind='easyRxBack'},'cyan');footer('Move each stick. Confirm assignment, center and both endpoints. No FC values are changed.')
end
function easyCalStart()
 if not rfReady then easyCalState='FC OFFLINE';easyCalConfirm=false;return end
 easyCalConfirm=false;easyCalState='CALIBRATION STARTING...';rf2.mspQueue:add({command=205,processReply=function()easyCalState='STARTED - KEEP LEVEL AND STILL';statusLiveAt=-1000 end,errorHandler=function()easyCalState='FAILED - DISARM / CHECK FC'end})
end
function drawEasyCalConfirm()
 hit={};fill(92,96,616,286,'panel');box(92,96,616,286,'orange');fill(92,96,616,44,'orange');txt(118,109,'ACCELEROMETER CALIBRATION','text',true);txt(126,164,'1. DISARM the helicopter and remove blades.','orange',true);txt(126,196,'2. Place the helicopter on a truly level surface.','text');txt(126,226,'3. Keep the FC completely still until finished.','text');txt(126,258,'Start calibration now?','cyan',true);button('easyCalNo','CANCEL',185,316,185,44,false,{kind='easyCalNo'},'cyan');button('easyCalYes','START',430,316,185,44,false,{kind='easyCalYes'},'orange')
end
function drawEasyBoardMenu()
 header('EASY SETUP  1','BOARD & SENSOR ALIGNMENT');txt(20,88,'OPEN ONE SETTING AT A TIME','cyan',true)
 local rows={{'FC MOUNTING DIRECTION','Board orientation / cable connector reference','easyOpenAlign'},{'ACCELEROMETER CALIBRATION',easyCalState,'easyOpenCal'},{'ACCELEROMETER TRIM','Fine level correction after calibration','easyOpenTrim'},{'MOVEMENT CHECK','Move the gyro and verify the live 3D helicopter','easyOpenMovement'}}
 for i,r in ipairs(rows)do local y=106+(i-1)*63;fill(40,y,720,56,easyBoardFocus==i and'panel2'or'panel');box(40,y,720,56,easyBoardFocus==i and'cyan'or'line');fill(40,y,8,56,({'cyan','orange','green','purple'})[i]);txt(62,y+9,r[1],easyBoardFocus==i and'cyan'or'text',true);txt(62,y+32,r[2],'muted');button('easyBoardOpen'..i,i==2 and'CALIBRATE'or'OPEN >',620,y+8,120,40,easyBoardFocus==i,{kind=r[3]},({'cyan','orange','green','purple'})[i])end
 button('easyBoardClose','< CLOSE',610,382,170,40,easyBoardFocus==5,{kind='easyBoardClose'},'cyan');footer('Mount direction first. Calibrate level, then trim and verify movement.')
end
function easyTrimCommitNumber(key,v)easyTrimDraft[key]=v;easyTrimDirty=true;easyState='ACC TRIM / NOT SAVED'end
function easyTrimSave()
 if not rfReady or not cfgAcc then easyState='FC / ACC TRIM NOT READY';easyTrimConfirm=false;return end
 cfgAcc.roll_trim.value=easyTrimDraft.roll;cfgAcc.pitch_trim.value=easyTrimDraft.pitch;easyTrimConfirm=false;easyState='SAVING ACC TRIM...';accTrimApi.write(cfgAcc);rf2.mspQueue:add({command=250,processReply=function()easyTrimDirty=false;easyState='ACC TRIM SAVED TO FC'end,errorHandler=function()easyState='SAVE FAILED - DISARM FC'end})
end
function drawEasyTrimConfirm()
 hit={};fill(105,116,590,242,'panel');box(105,116,590,242,'orange');fill(105,116,590,42,'orange');txt(128,129,'APPLY ACCELEROMETER TRIM?','text',true);txt(150,185,string.format('ROLL %.1f deg   PITCH %.1f deg',easyTrimDraft.roll/10,easyTrimDraft.pitch/10),'cyan',true);txt(135,222,'Keep the helicopter level and completely still.','orange');button('easyTrimNo','CANCEL',190,292,180,44,false,{kind='easyTrimNo'},'cyan');button('easyTrimYes','APPLY & SAVE',420,292,190,44,false,{kind='easyTrimYes'},'orange')
end
function drawEasyTrim()
 header('EASY SETUP  1B',easyState);txt(20,94,'ACCELEROMETER TRIM','green',true)
 fill(30,122,740,130,'panel');box(30,122,740,130,'line');txt(48,136,'Place the helicopter on a truly level surface.','text',true);txt(48,159,'Use trim only after FC mounting direction is correct.','orange');txt(48,184,string.format('LIVE ROLL %+.1f deg',statusLive.roll or 0),'cyan',true);txt(470,184,string.format('LIVE PITCH %+.1f deg',statusLive.pitch or 0),'orange',true)
 local gx,gy=400,226;easyLine(gx-180,gy,gx+180,gy,'line',2);easyLine(gx,gy-32,gx,gy+18,'line',2);local px=math.max(-170,math.min(170,(statusLive.roll or 0)*5));local py=math.max(-28,math.min(16,(statusLive.pitch or 0)*2));fill(gx+px-6,gy+py-6,12,12,'green')
 local rows={{'ROLL TRIM [0.1 deg]','roll'},{'PITCH TRIM [0.1 deg]','pitch'}};for i,r in ipairs(rows)do local y=274+(i-1)*48;txt(60,y+10,r[1],'text');button('easyTrimVal'..i,string.format('%.1f deg',easyTrimDraft[r[2]]/10),520,y+3,210,36,easyTrimFocus==i,{kind='easyTrimValue',key=r[2]},'green')end
 button('easyTrimApply','APPLY & SAVE',400,386,180,40,easyTrimFocus==3,{kind='easyTrimApply'},'orange');button('easyTrimClose','< CLOSE',600,386,180,40,easyTrimFocus==4,{kind='easyTrimClose'},'cyan');footer('Accelerometer trim is separate from FC Roll/Pitch/Yaw mounting alignment.');if easyTrimConfirm then drawEasyTrimConfirm()end
end
function drawEasyAlignment()
 header('EASY SETUP  1/12    FC MOUNTING DIRECTION',easyState);drawEasyHeli()
 fill(430,104,350,244,'panel');box(430,104,350,244,'line')
 button('easyLeft','< ROTATE',448,120,102,36,easyFocus==1,{kind='easyRotate',delta=-1},'cyan');button('easyRight','ROTATE >',560,120,102,36,easyFocus==2,{kind='easyRotate',delta=1},'cyan');button('easyFlip','FLIP '..(easyFlip and'BOTTOM'or'TOP'),672,120,92,36,easyFocus==3,{kind='easyFlip'},'orange')
 local labels={{'ROLL',easyDraft.roll,'roll'},{'PITCH',easyDraft.pitch,'pitch'},{'YAW',easyDraft.yaw,'yaw'}};for i,r in ipairs(labels)do local y=166+(i-1)*45;txt(450,y+10,r[1]..' [deg]','text');button('easyAngle'..i,tostring(r[2]),620,y+4,140,34,easyFocus==i+3,{kind='easyAngle',key=r[3]},'cyan')end;txt(450,326,easyFlip and'BOARD BOTTOM UP'or'BOARD TOP UP',easyFlip and'orange'or'green',true);if not easyFlip and easyFacing==0 then txt(650,326,'R0 P0 Y0','cyan')end
 button('easyApply','APPLY & SAVE',430,368,170,42,easyFocus==7,{kind='easyApply'},'orange');button('easyBack','< BACK',610,368,170,42,easyFocus==8,{kind='easyBack'},'cyan');footer('Touch or roller: rotate/flip preview. APPLY & SAVE writes to FC.');if easyConfirm then drawEasyConfirm()end
end

function drawSetup()
 header('SETUP',setupState);local y=104
 for i,r in ipairs(setupRows)do local enabled=r[4];fill(20,y,760,38,setupSel==i and'panel2'or'panel');box(20,y,760,38,setupSel==i and'cyan'or'line');button('setupRow'..i,r[1],28,y+4,276,30,setupSel==i,{kind='setupRow',index=i},enabled and'cyan'or'muted');txt(320,y+10,r[2],enabled and'text'or'muted');y=y+42 end
 button('setupBack','< BACK',650,408,130,36,setupSel==8,{kind='back'},'cyan');footer('DISARM required. ENTER opens confirmation; Save Settings writes EEPROM directly.')
end

local function draw()
 hit={}
 if page=='home'then drawHome()
 elseif page=='full'then drawFullGrid()
 elseif page=='options'then drawOptions()
 elseif page=='easy'then drawEasy()
 elseif page=='easyBoardMenu'then drawEasyBoardMenu()
 elseif page=='easyReceiver'then drawEasyReceiver()
 elseif page=='easyServo'then easyServo.draw()
 elseif page=='easyAlign'then drawEasyAlignment()
 elseif page=='easyTrim'then drawEasyTrim()
 elseif page=='status'then drawStatus()
 elseif page=='setup'then drawSetup()
 elseif page=='configuration'then drawConfiguration()
 elseif page=='receiver'then drawReceiver()
 elseif page=='failsafe'then drawFailsafe()
 elseif page=='power'then drawPower()
 elseif page=='gyro'then drawGyro()
 elseif page=='rates'or page=='profiles'or page=='modes'or page=='adjustments'or page=='beeper'or page=='sensors'or page=='blackbox'then ensureAdvanced();advanced.draw(page)
 elseif page=='receiverPreview'then drawReceiverPreview()
 elseif page=='configuration3d'then drawConfiguration3d()
 elseif page=='statusAttitude'then drawStatusAttitude()
 elseif page=='statusInstrument'then drawStatusInstrument()
 elseif page=='profiles'then ensureAdvanced();advanced.draw(page)
 elseif page=='servos'then drawLiveServos()
 elseif page=='mixer'then drawMixerPage()
 elseif page=='motors'then rfDrawMotor()
 elseif page=='governor'then drawGovernor()
 elseif page=='planned'then header('PLANNED PAGE','NO FC WRITE');txt(40,150,'This page is reserved in the final setup order.','muted');button('back','< Back',650,411,130,40,false,{kind='back'});footer()
 else drawScreen(screens[page] or {title='PAGE',note='',rows={}})end
 if homeFlashConfirm then drawHomeFlashConfirm()elseif cfgNameEdit then drawCfgNameKeyboard()elseif rxWarning then drawRxWarning()elseif choiceSelect then drawChoice()elseif cfgSerialConfirm then drawCfgSerialConfirm()elseif cfgPortEdit then drawCfgPortEditor()elseif cfgSaveConfirm then drawCfgConfirm()elseif setupConfirm then drawSetupConfirm()elseif easyCalConfirm then drawEasyCalConfirm()elseif swashSelect~=nil then drawSwashSelect()elseif centerConfirm then drawCenterConfirm()elseif help then drawHelp()elseif numEdit then drawKeypad()end
end
local function findHit(x,y)if(getTime and getTime()or 0)<rfChoiceTouchGuard then return nil end;for i=#hit,1,-1 do local b=hit[i];if x>=b.x and x<b.x+b.w and y>=b.y and y<b.y+b.h then return b end end end
local function findHitId(id)for i=#hit,1,-1 do if hit[i].id==id then return hit[i],i end end end
local function activate(a)
 if a and a.kind=='easyServo'then easyServo.activate(a);return end
 if a and a.kind=='easyStep'and a.index==3 then ensureEasyServo();page='easyServo';easyMenuFocus=3;easyServo.open();return end
 if a and a.kind=='advanced'then ensureAdvanced();advanced.activate(a);return end
 if not a then return end
 if a.kind=='easyStep'then easyMenuFocus=a.index;if a.index==1 then page='easyBoardMenu';easyBoardFocus=1;easyDirty=false;easyTrimDirty=false;easyState='READING FC...';cfgRead()elseif a.index==2 then page='easyReceiver';easyRxFocus=1;easyRxScroll=1;easyRxState='READING FC...';rxProtocolUnlocked=false;rxTelemetryUnlocked=false;statusLiveAt=-1000;rxRead();requestStatusLive()end;return end
 if a.kind=='easyMenuBack'then page='home';selected=1;return end
 if a.kind=='easyRxScroll'then easyRxScroll=math.max(1,math.min(4,easyRxScroll+a.delta));return end
 if a.kind=='easyRxRefresh'then easyRxState='READING FC...';statusLiveAt=-1000;rxRead();requestStatusLive();return end
 if a.kind=='easyRxBack'then page='easy';easyMenuFocus=2;return end
 if a.kind=='easyOpenAlign'then page='easyAlign';easyFocus=1;return end
 if a.kind=='easyOpenCal'then easyCalConfirm=true;easyCalState='CONFIRM CALIBRATION';return end
 if a.kind=='easyCalNo'then easyCalConfirm=false;easyCalState='CALIBRATION CANCELLED';return end
 if a.kind=='easyCalYes'then easyCalStart();return end
 if easyCalConfirm then return end
 if a.kind=='easyOpenMovement'then easyBoardFocus=4;attitudeBackPage='easyBoardMenu';page='statusAttitude';statusLiveAt=-1000;requestStatusLive();return end
 if a.kind=='easyOpenTrim'then easyBoardFocus=3;page='easyTrim';easyTrimFocus=1;easyTrimDirty=false;easyState='READING ACC TRIM...';cfgRead();statusLiveAt=-1000;requestStatusLive();return end
 if a.kind=='easyBoardClose'then page='easy';easyMenuFocus=1;return end
 if a.kind=='easyTrimNo'then easyTrimConfirm=false;easyState='ACC TRIM SAVE CANCELLED';return end
 if a.kind=='easyTrimYes'then easyTrimSave();return end
 if easyTrimConfirm then return end
 if a.kind=='easyTrimValue'then beginNumber('easyTrim',a.key,easyTrimDraft[a.key],-300,300);return end
 if a.kind=='easyTrimApply'then easyTrimConfirm=true;return end
 if a.kind=='easyTrimClose'then page='easyBoardMenu';easyBoardFocus=3;return end
 if a.kind=='easyNo'then easyConfirm=false;easyState='SAVE CANCELLED';return end
 if a.kind=='easyYes'then easySave();return end
 if easyConfirm then return end
 if a.kind=='easyRotate'then easyRotate(a.delta);return end
 if a.kind=='easyFlip'then easyFlipBoard();return end
 if a.kind=='easyAngle'then beginNumber('easy',a.key,easyDraft[a.key],-180,360);return end
 if a.kind=='easyApply'then easyConfirm=true;return end
 if a.kind=='easyBack'then page='easyBoardMenu';easyBoardFocus=1;return end
 if a.kind=='homeFlashNo'then homeFlashConfirm=false;homeFlashState='ERASE CANCELLED';return end
 if a.kind=='homeFlashYes'then homeFlashConfirm=false;if not homeHw.flashSupported then homeFlashState='DATAFLASH NOT AVAILABLE';return end;homeFlashState='ERASING DATAFLASH...';homeHwBusy=true;dataflashApi.eraseDataflash(function()homeHwBusy=false;homeHwAt=-1000;homeFlashState='ERASE STARTED'end,nil);return end
 if homeFlashConfirm then return end
 if a.kind=='cfgSerialNo'then cfgSerialConfirm=false;cfgState='SERIAL EDIT CANCELLED';return end
 if a.kind=='cfgSerialYes'then cfgSerialUnlock();return end
 if cfgSerialConfirm then return end
 if a.kind=='cfgPortAction'then cfgPortAction(a.value);return end
 if cfgPortEdit then return end
 if a.kind=='cfgNameKey'then cfgNameAction(a.value);return end
 if cfgNameEdit then return end
 if a.kind=='cfgSaveNo'then cfgSaveConfirm=false;cfgState='SAVE CANCELLED';return end
 if a.kind=='cfgSaveYes'then cfgSaveReboot();return end
 if cfgSaveConfirm then return end
 if a.kind=='cfg3dRow'then cfg3dActivate(a.index);return end
 if a.kind=='cfg3dScroll'then cfg3dScroll=math.max(1,math.min(#cfg3dRows-1,cfg3dScroll+a.delta));cfg3dSel=cfg3dScroll;return end
 if a.kind=='cfg3dBack'then page='configuration';return end
 if a.kind=='cfgRow'then cfgActivate(a.index);return end
 if a.kind=='cfgToggle'then cfgSel=a.index;cfgActivate(a.index);return end
 if a.kind=='cfgScroll'then cfgScroll=math.max(1,math.min(#cfgRows-6,cfgScroll+a.delta));cfgSel=cfgScroll;return end
 if a.kind=='configAttitudeOpen'then attitudeBackPage='configuration';page='statusAttitude';return end
 if a.kind=='setupConfirmNo'then setupConfirm=nil;setupState='CANCELLED';return end
 if a.kind=='setupConfirmYes'then local i=setupConfirm and setupConfirm.index;setupConfirm=nil;if i then setupSend(setupRows[i][3])end;return end
 if setupConfirm then return end
 if a.kind=='setupRow'then setupAsk(a.index);return end
 if a.kind=='govCurveKeypad'then govEdit(a.value+2);return end
 if a.kind=='govPoints'then govEdit(1);return end
 if a.kind=='govTab'then govTab=a.value;govFocus=a.value;govScroll=1;govCurveEdit=false;govRefresh();return end
 if a.kind=='govRow'then govFocus=#govVisibleTabs+a.value;govEdit(a.value);return end
 if a.kind=='govPoint'then govFocus=#govVisibleTabs+2+a.value;govCurveEdit=true;return end
 if a.kind=='govScroll'then govScroll=math.max(1,math.min(math.max(1,#govRows-3),govScroll+a.delta));govFocus=#govVisibleTabs+govScroll;return end
 if a.kind=='govControl'then if a.value=='save'then govSave()else govRead()end;return end
 if a.kind=='motorLiveSet'then rfMotorLive=a.value;rfMotorRefreshRows();rfMotorPages[5][2][2]=rfMotorLive and'ON'or'OFF';return end
 if a.kind=='motorUnsyncedSet'then motorConfig.unsynced=a.value and 1 or 0;motorDirty=true;rfMotorRefreshRows();applyMotorLive();return end
 if a.kind=='escToggleSet'then local rows=rfMotorPages[2];local r=rows[rfMotorFocus-6];if r and escSensorConfig and escSensorConfig[r[3]]then escSensorConfig[r[3]].value=a.value and 1 or 0;motorDirty=true;rfRefreshEscRows();rfApplyEscLive()end;return end
 if a.kind=='rpmSensorSet'then rfRpmSensor=a.value;motorDirty=true;rfGearDisplay();applyMotorLive();return end
 if a.kind=='motorOverrideSet'then rfSendMotorOverride(rfMotorOverridePct,a.value);rfMotorGaugeEdit=false;return end
 if a.kind=='motorOverrideSlider'then if rfMotorOverrideOn then rfMotorGaugeEdit=not rfMotorGaugeEdit else motorState='TURN OVERRIDE ON FIRST'end;return end
 if a.kind=='motorOverrideStep'then if rfMotorOverrideOn then rfSendMotorOverride(rfMotorOverridePct+a.delta,true)else motorState='TURN OVERRIDE ON FIRST'end;return end
 if a.kind=='motorTopTab'then if rfMotorTab==5 and a.value~=5 and rfMotorOverrideOn then rfSendMotorOverride(0,false)end;rfMotorTab=a.value;rfMotorFocus=a.value;rfMotorScroll=1;return end
 if a.kind=='motorRow'then rfMotorFocus=6+a.value;rfMotorActivateRow(a.value);return end
 if a.kind=='motorControl'then if a.value=='save'then saveMotor()else requestMotor()end;return end
 if a.kind=='motorOverrideScroll'then local maxRow=rfMotor2Present()and 14 or 9;local row=math.max(1,math.min(maxRow,rfMotorFocus-6));row=math.max(1,math.min(maxRow,row+a.delta*3));rfMotorFocus=6+row;rfMotorScroll=row<=3 and 1 or(row<=6 and 2 or(row<=9 and 3 or 4));return end
 if a.kind=='motorScrollTo'then local rows=rfMotorPages[rfMotorTab];local visible=rfMotorTab==1 and 3 or 4;rfMotorScroll=math.max(1,math.min(math.max(1,#rows-visible+1),a.value));rfMotorFocus=6+rfMotorScroll;return end
 if a.kind=='motorScroll'then local rows=rfMotorPages[rfMotorTab];local visible=rfMotorTab==1 and 3 or 4;rfMotorScroll=math.max(1,math.min(math.max(1,#rows-visible+1),rfMotorScroll+a.delta));rfMotorFocus=6+rfMotorScroll;return end
 if a.kind=='gyTab'then gyTab=a.value;gySel=1;gyScroll=1;gyBuildRows();return end
 if a.kind=='gyScroll'then gyScroll=math.max(1,math.min(math.max(1,#gyRows-5),gyScroll+a.delta));gySel=gyScroll;return end
 if a.kind=='gyRow'then gyActivate(a.index);return end
 if a.kind=='gyRead'then gyRead();return end
 if a.kind=='gySave'then gySave();return end
 if a.kind=='pwTab'then pwTab=a.value;pwSel=1;pwScroll=1;pwBuildRows();return end
 if a.kind=='pwScroll'then pwScroll=math.max(1,math.min(math.max(1,#pwRows-6),pwScroll+a.delta));pwSel=pwScroll;return end
 if a.kind=='pwRow'then pwActivate(a.index);return end
 if a.kind=='fullScroll'then local list=page=='home'and home or full;local visible=7;scroll=math.max(1,math.min(math.max(1,#list-visible+1),scroll+a.delta));selected=math.max(scroll,math.min(#list,selected+a.delta));return end
 if a.kind=='fsQuick'then fsJump(a.value);return end
 if a.kind=='fsScroll'then fsScroll=math.max(1,math.min(math.max(1,#fsRows-6),fsScroll+a.delta));fsSel=fsScroll;return end
 if a.kind=='fsSet'then local d=fsData[a.channel];if d then beginNumber('failsafe','set'..a.channel,d.value,875,2125)end;return end
 if a.kind=='fsRow'then fsActivate(a.index);return end
 if a.kind=='rxQuick'then rxJump(a.value);return end
 if a.kind=='rxPreviewReset'then for i=1,4 do rxPreviewZero[i]=rxStickPct(i)end;return end
 if a.kind=='rxPreviewBack'then page='receiver';return end
 if a.kind=='rxWarnNo'then rxWarning=nil;rxState='CHANGE CANCELLED';return end
 if a.kind=='rxWarnYes'then if rxWarning=='protocol'then rxProtocolUnlocked=true else rxTelemetryUnlocked=true end;rxWarning=nil;rxBuildRows();return end
 if a.kind=='rxScroll'then rxScroll=math.max(1,math.min(math.max(1,#rxRows-6),rxScroll+a.delta));rxSel=rxScroll;return end
 if a.kind=='rxRow'or a.kind=='rxToggle'then rxActivate(a.index);return end
 if a.kind=='choiceStep'then if choiceSelect then choiceSelect.selected=math.max(1,math.min(#choiceSelect.items,choiceSelect.selected+a.delta*7))end;return end
 if a.kind=='choice'then choiceSelect.selected=a.value;chooseChoice();return end
 if a.kind=='swashChoice'then chooseSwash(a.value);return end
 if a.kind=='mixScroll'then mixerNav=math.max(1,math.min(mixerRowCount,mixerNav+a.delta));mixerSelectedId='mxr'..mixerNav;swipeMomentum=0;return end
 if a.kind=='mixScrollTo'then mixerScroll=math.max(1,math.min(math.max(1,mixerRowCount-3),a.value));mixerNav=mixerScroll;mixerSelectedId='mxr'..mixerNav;swipeMomentum=0;return end
 if a.kind=='mixerTopTab'then if mixerTab==6 or mixerTab==7 then disableMixerOverrides()end;mixerTab=a.value;mixerNav=1;mixerScroll=1;swipeMomentum=0;mixerSelectedId='mxt'..a.value;return end
 if a.kind=='noop'then return end
 if a.kind=='mixerMenuItem'then mixerMenuSel=a.value;mixerTab=a.value;mixerSub=1;mixerMenu=false;return end
 if a.kind=='mixerMenu'then if mixerTab==6 or mixerTab==7 then disableMixerOverrides()end;mixerMenu=true;return end
 if a.kind=='mixcycle'then if mixerTab==4 and a.delta==1 and mixerSub==1 then mixerSub=2 elseif mixerTab==4 and a.delta==-1 and mixerSub==2 then mixerSub=1 else if mixerTab==6 or mixerTab==7 then disableMixerOverrides()end;mixerTab=(mixerTab-1+a.delta)%7+1;mixerSub=a.delta<0 and mixerTab==4 and 2 or 1 end;return end
 if a.kind=='mixfield'then if a.fieldKind=='swash'then swashSelect=a.value elseif a.fieldKind=='enum'then openEnumChoice(a.index,a.index=='main_rotor_dir'and'SELECT MAIN ROTOR DIRECTION'or'SELECT TAIL ROTOR TYPE') elseif a.fieldKind=='dir'then openDirectionChoice(a.index,'SELECT CONTROL DIRECTION') elseif a.fieldKind=='config'then local d=mixerConfig[a.index];beginScaledNumber('mixconfig',a.index,d.value,d.min,d.max,mixerConfigScale(a.index),false) elseif a.fieldKind=='input'then local c=string.find(a.index,':');local ix=tonumber(string.sub(a.index,1,c-1));local key=string.sub(a.index,c+1);local scale,preserve=mixerInputScale(ix,key);beginScaledNumber('mixinput',ix..':'..key,a.value,a.min,a.max,scale,preserve)end;return end
 if a.kind=='mixOverrideSlider'then if not mixerOverrideOn[a.axis]then mixerGaugeEdit=nil;mixerState='TURN OVERRIDE ON FIRST';return end;if mixerGaugeEdit==a.axis then mixerGaugeEdit=nil else mixerGaugeEdit=a.axis end;return end
 if a.kind=='mixOverrideEnable'then sendMixerOverride(a.axis,0,not mixerOverrideOn[a.axis]);return end
 if a.kind=='mixOverrideStep'then if not mixerOverrideOn[a.axis]then mixerState='TURN OVERRIDE ON FIRST';return end;local lim=a.axis==3 and((mixerConfig and mixerConfig.tail_rotor_mode.value or 0)>0 and 125 or 60)or 18;sendMixerOverride(a.axis,math.max(-lim,math.min(lim,mixerOverrideAngle(a.axis)+a.delta)),true);return end
 if a.kind=='mixOverrideValue'then if not mixerOverrideOn[a.axis]then mixerState='TURN OVERRIDE ON FIRST';return end;beginNumber('mixoverride',a.axis,math.floor(mixerOverrideAngle(a.axis)*10+.5)/10,-a.limit,a.limit);numEdit.decimals=1;numEdit.text=string.format('%.1f',numEdit.original);return end
 if a.kind=='swashOpen'then if mixerConfig and mixerConfig.swash_type and mixerConfig.swash_type.value~=nil then swashSelect=mixerConfig.swash_type.value end;return end
 if a.kind=='mixerDirection'then openDirectionChoice(a.index,'SELECT CONTROL DIRECTION');return end
 if a.kind=='directionSave'then saveMixerInputs();return end
 if a.kind=='mixerControl'then if a.value=='save'then saveAllMixer()else requestMixerConfig()end;return end
 if choiceSelect or swashSelect~=nil then return end
 if a.kind=='centerNo'then centerConfirm=nil;servoState='CENTER CHANGE CANCELLED';return end
 if a.kind=='centerYes'then local si=centerConfirm and centerConfirm.index;centerConfirm=nil;if si~=nil then commitCenterFromOutput(si)end;return end
 if centerConfirm then return end
 if a.kind=='direct'then directAction(a.value);return end
 if a.kind=='numaction'then numberAction(a.value);return end
 if a.kind=='numkey'then if a.value=='DEL'then numEdit.text=string.sub(numEdit.text,1,math.max(0,#numEdit.text-1))elseif a.value=='-'then if string.sub(numEdit.text,1,1)=='-'then numEdit.text=string.sub(numEdit.text,2)else numEdit.text='-'..numEdit.text end else if numEdit.text=='0'then numEdit.text=a.value else numEdit.text=numEdit.text..a.value end end;numEdit.error=nil;return end
 if a.kind=='numcancel'then numEdit=nil;return end
 if a.kind=='numok'then commitNumber();return end
 if numEdit then return end
 if a.kind=='help'then help=not help;return end
 if a.kind=='statusInstrumentOpen'then statusInstrument=a.value;page='statusInstrument';return end
 if a.kind=='statusInstrumentBack'then page='status';return end
 if a.kind=='statusAttitudeOpen'then attitudeBackPage='status';page='statusAttitude';return end
 if a.kind=='statusAttitudeBack'then page=attitudeBackPage or'status';return end
 if a.kind=='statusResetZ'then statusResetZ();return end
 if a.kind=='statusRxScroll'then statusRxScroll=math.max(1,math.min(10,(statusRxScroll or 1)+a.delta));return end
 if a.kind=='statusArm'then statusSetArming(a.value);return end
 if a.kind=='statusRefresh'then statusLiveAt=-1000;requestInfo();requestStatusLive();return end
 if a.kind=='refresh'then requestInfo();return end
 if a.kind=='directionPass'then directionPass[a.index]=not directionPass[a.index];directionSel=a.index;return end
 if a.kind=='mixertab'then if mixerTab==6 or mixerTab==7 then disableMixerOverrides()end;mixerTab=a.value;directionSel=1;if mixerTab==2 and(mixerState=='NOT READ'or mixerState=='READ ERROR')then requestMixerConfig()end;return end
 if a.kind=='servo'then servoSel=a.index;servoTab=((servoSel-1)%8+1)<=4 and 1 or 2;local _,_,d=servoCell();if d and d.value~=nil then beginNumber('servo',servoSel,d.value,d.min,d.max)end;return end
 if a.kind=='servotab'then if servoTab==3 and a.value~=3 then disableOverrides()end;servoTab=a.value;local si=math.floor((servoSel-1)/8);if servoTab<3 then servoSel=si*8+(servoTab==1 and 1 or 5)end;servoEdit=false;return end
 if a.kind=='overrideEnable'then sendOverride(a.index,0,not overrideOn[a.index]);return end
 if a.kind=='setCenter'then askCenterFromOutput(a.index);return end
 if a.kind=='overrideStep'then local na=math.max(-90,math.min(90,(overrideAngle[a.index]or 0)+a.delta));sendOverride(a.index,na,true);return end
 if a.kind=='overrideAngle'then if overrideOn[a.index]then beginNumber('override',a.index,overrideAngle[a.index]or 0,-90,90)end;return end
 if a.kind=='overrideAllOff'then disableOverrides();servoState='ALL OVERRIDES OFF';return end
 if a.kind=='servoflag'then toggleServoFlag(a.index,a.mask);return end
 if a.kind=='servoctl'then if a.value=='save'then saveServos()else requestServos()end;return end
 if a.kind=='pid'then pidSel=a.index;local k=pidMap[pidSel];local d=pidData[k];if d and d.value~=nil then beginNumber('pid',pidSel,d.value,d.min,d.max)end;return end
 if a.kind=='delta'then changePid(a.value);return end
 if a.kind=='pidctl'then pidSel=a.index;if a.index==18 then savePid()elseif a.index==19 then requestPid()else selectProfile()end;return end
 if help then return end
 if a.kind=='back'then if page=='receiverPreview'then page='receiver' elseif page=='statusAttitude'or page=='statusInstrument'then page='status' elseif page=='mixer'then disableMixerOverrides();if mixerMenu then page='full'else mixerMenu=true end elseif page=='servos'then disableOverrides();page=rfEasyServoReturn and'easyServo'or'full';rfEasyServoReturn=false elseif page=='easyAlign'or page=='easyTrim'then page='easyBoardMenu';easyBoardFocus=1 elseif page=='easyBoardMenu'then page='easy';easyMenuFocus=1 elseif page=='full'or page=='options'or page=='easy'then page='home'else page='full'end;selected=1;scroll=1
 elseif a.kind=='open'then selected=a.index;local list=page=='home'and home or full;local target=list[selected][3];if target=='exit'then return 2 else if target=='profiles'or target=='profileGains'or target=='rateTable'then advBackTarget=page=='home'and'home'or'full'end;page=target=='profileGains'and'profiles'or(target=='rateTable'and'rates'or target);selected=1;scroll=1;if target=='configuration'then cfgSel=2;cfgScroll=1;cfgRead()elseif target=='status'then statusLiveAt=-1000;requestInfo();requestStatusLive()elseif target=='receiver'then rxSel=2;rxScroll=1;rxProtocolUnlocked=false;rxTelemetryUnlocked=false;rxWarning=nil;statusLiveAt=-1000;rxRead()elseif target=='failsafe'then fsSel=1;fsScroll=1;fsRead()elseif target=='power'then pwTab=1;pwSel=1;pwScroll=1;pwRead()elseif target=='gyro'then gyTab=1;gySel=1;gyScroll=1;gyRead()elseif target=='rates'or target=='modes'or target=='adjustments'or target=='beeper'or target=='sensors'or target=='blackbox'then ensureAdvanced();advanced.open(target)elseif target=='profiles'then ensureAdvanced();advanced.open(target)elseif target=='profileGains'then ensureAdvanced();advanced.openGain()elseif target=='rateTable'then ensureAdvanced();advanced.openRateTable()elseif target=='servos'then servoSel=1;servoEdit=false;servoTab=1;servoSelectedId='st1';requestServos()elseif target=='mixer'then mixerMenu=false;mixerNav=1;mixerScroll=1;mixerSelectedId='mxt1';mixerCursor=2;mixerTab=1;directionSel=1;directionPass={false,false,false};directionState='READING ATTITUDE...';directionAt=-1000;requestMixerConfig()elseif target=='motors'then rfMotorTab=1;rfMotorFocus=1;rfMotorScroll=1;requestMotor()elseif target=='governor'then govTab=1;govFocus=1;govScroll=1;govRead()end end
 elseif a.kind=='option'then selected=a.index;if selected==1 then saveMode=3-saveMode elseif selected==2 then armedLock=not armedLock end end
 return 0
end
local function maxItems()if page=='configuration'then return #cfgRows elseif page=='configuration3d'then return #cfg3dRows elseif page=='setup'then return 8 elseif page=='servos'then return 32 elseif page=='profiles'then return 20 elseif page=='easyAlign'then return 8 elseif page=='easyTrim'then return 4 elseif page=='easyBoardMenu'then return 5 elseif page=='easyReceiver'then return 4 elseif page=='easy'then return 3 elseif page=='home'then return #home elseif page=='full'then return #full elseif page=='options'then return 4 else return 0 end end
local function back()
 if page=='easyServo'and not help then easyServo.back();return 0 end
 if help then help=false;return 0 end
 if rxWarning then rxWarning=nil;rxState='CHANGE CANCELLED';return 0 end
 if homeFlashConfirm then homeFlashConfirm=false;homeFlashState='ERASE CANCELLED';return 0 end
 if cfgSerialConfirm then cfgSerialConfirm=false;cfgState='SERIAL EDIT CANCELLED';return 0 end
 if cfgPortEdit then cfgPortEdit=nil;cfgState='SERIAL CHANGE CANCELLED';return 0 end
 if cfgNameEdit then cfgNameEdit=nil;cfgState='NAME CHANGE CANCELLED';return 0 end
 if cfgSaveConfirm then cfgSaveConfirm=false;cfgState='SAVE CANCELLED';return 0 end
 if setupConfirm then setupConfirm=nil;setupState='CANCELLED';return 0 end
 if easyConfirm then easyConfirm=false;easyState='SAVE CANCELLED';return 0 end
 if easyTrimConfirm then easyTrimConfirm=false;easyState='ACC TRIM SAVE CANCELLED';return 0 end
 if easyCalConfirm then easyCalConfirm=false;easyCalState='CALIBRATION CANCELLED';return 0 end
 if page=='home'then return 2 elseif page=='easyAlign'or page=='easyTrim'then page='easyBoardMenu';easyBoardFocus=1 elseif page=='easyBoardMenu'then page='easy';easyMenuFocus=1 elseif page=='easyReceiver'then page='easy';easyMenuFocus=2 elseif page=='configuration3d'then page='configuration' elseif page=='statusAttitude'then page=attitudeBackPage or'status' elseif page=='statusInstrument'then page='status' elseif page=='mixer'then disableMixerOverrides();if mixerMenu then page='full'else mixerMenu=true end elseif page=='servos'then disableOverrides();page=rfEasyServoReturn and'easyServo'or'full';rfEasyServoReturn=false;servoEdit=false elseif page=='profiles'then page=advBackTarget or'full';pidEditing=false  elseif page=='easyAlign'or page=='easyTrim'then page='easyBoardMenu';easyBoardFocus=1 elseif page=='easyBoardMenu'then page='easy';easyMenuFocus=1 elseif page=='full'or page=='options'or page=='easy'then page='home'else page='full'end;selected=1;scroll=1;return 0
end
local function normalizeEvent(event)
 if (EVT_VIRTUAL_NEXT_REPT and event==EVT_VIRTUAL_NEXT_REPT)or(EVT_VIRTUAL_INC and event==EVT_VIRTUAL_INC)or(EVT_VIRTUAL_INC_REPT and event==EVT_VIRTUAL_INC_REPT)then return EVT_VIRTUAL_NEXT end
 if (EVT_VIRTUAL_PREV_REPT and event==EVT_VIRTUAL_PREV_REPT)or(EVT_VIRTUAL_DEC and event==EVT_VIRTUAL_DEC)or(EVT_VIRTUAL_DEC_REPT and event==EVT_VIRTUAL_DEC_REPT)then return EVT_VIRTUAL_PREV end
 return event
end
local function run(event,touch)
 if page=='easyServo'then easyServo.tick()end
 if advanced and(page=='rates'or page=='profiles'or page=='modes'or page=='adjustments'or page=='beeper'or page=='sensors'or page=='blackbox')then advanced.live()end
 if advanced and(page=='rates'or page=='profiles'or page=='modes'or page=='adjustments'or page=='beeper'or page=='sensors'or page=='blackbox')and not numEdit and not choiceSelect and not help then event=advanced.event(event)or event end
 if page=='home'and rfReady then local now=getTime and getTime()or 0;if now-homeHwAt>=100 and not homeHwBusy and rf2.mspQueue:isProcessed()then homeHwAt=now;requestHomeHardware()end end
  if(page=='status'or page=='receiver'or page=='receiverPreview'or page=='statusAttitude'or page=='statusInstrument'or page=='configuration3d'or page=='easyTrim'or page=='easyReceiver')and rfReady then local now=getTime and getTime()or 0;if now-statusLiveAt>=20 and not statusLiveBusy and rf2.mspQueue:isProcessed()then statusLiveAt=now;requestStatusLive()end end
 if page=='power'and rfReady then local now=getTime and getTime()or 0;if now-pwLiveAt>=20 and not pwLiveBusy and rf2.mspQueue:isProcessed()then pwLiveAt=now;pwReadLive()end end
 if page=='governor'and rfReady then local now=getTime and getTime()or 0;if now-govRxAt>=10 and rf2.mspQueue:isProcessed()then govRxAt=now;rfGovReadThrottle()end end
 if page=='governor'and rfReady and not govDirty and not govCurveEdit and govCurveDrag==nil and not numEdit and not choiceSelect then local now=getTime and getTime()or 0;if now-govLiveReadAt>=100 and rf2.mspQueue:isProcessed()then govLiveReadAt=now;govLiveRead()end end
 if page=='governor'and govTab==5 and rfReady then local now=getTime and getTime()or 0;if now-rfMotorTelemetryAt>=20 and rf2.mspQueue:isProcessed()then rfMotorTelemetryAt=now;rfRequestMotorTelemetry()end end
 if page=='motors'and rfMotorLive and(rfMotorTab==4 or rfMotorTab==5 or rfMotorTab==6)and rfReady then local now=getTime and getTime()or 0;if now-rfMotorTelemetryAt>=20 and rf2.mspQueue:isProcessed()then rfMotorTelemetryAt=now;rfRequestMotorTelemetry()end end
 if page=='motors'and rfMotorTab==5 and rfMotorOverrideOn and rfMotorOverridePct>0 and rfReady then local now=getTime and getTime()or 0;if now-rfMotorKeepAliveAt>=50 and rf2.mspQueue:isProcessed()then rfSendMotorOverride(rfMotorOverridePct,true,true)end end
 local fastRepeat=((EVT_VIRTUAL_NEXT_REPT and event==EVT_VIRTUAL_NEXT_REPT)or(EVT_VIRTUAL_PREV_REPT and event==EVT_VIRTUAL_PREV_REPT)or(EVT_VIRTUAL_INC_REPT and event==EVT_VIRTUAL_INC_REPT)or(EVT_VIRTUAL_DEC_REPT and event==EVT_VIRTUAL_DEC_REPT))and true or false
 local navStep=fastRepeat and 3 or 1;local valueStep=fastRepeat and 5 or 1
 event=normalizeEvent(event)
 if not rfReady and not pidError then initRF();if rfReady then rf2.mspQueue.maxRetries=3;requestInfo()end end
 if rfReady then rf2.mspQueue:processQueue();rfFlushMixerLive() end
 if page=='mixer'and swipeMomentum~=0 and not pageSwipe then local now=getTime and getTime()or 0;if now>=swipeNext then local dir=swipeMomentum>0 and 1 or-1;mixerNav=math.max(1,math.min(mixerRowCount,mixerNav+dir));mixerSelectedId='mxr'..mixerNav;swipeMomentum=swipeMomentum-dir;swipeNext=now+3 end end
 if page=='servos'and servoTab==3 and not help and not numEdit and not centerConfirm and overrideDrag==nil and not(type(touch)=='table'and((EVT_TOUCH_FIRST and event==EVT_TOUCH_FIRST)or(EVT_TOUCH_SLIDE and event==EVT_TOUCH_SLIDE)))then local now=getTime and getTime()or 0;if now-servoOutputAt>=20 and rf2.mspQueue:isProcessed()then servoOutputAt=now;requestServoOutput()end end
 if page=='mixer'and mixerTab==2 and not help then local now=getTime and getTime()or 0;if now-directionAt>=20 and rf2.mspQueue:isProcessed()then directionAt=now;requestDirectionAttitude()end end
 local n=maxItems()
 if choiceSelect then if event==EVT_VIRTUAL_EXIT then choiceSelect=nil;event=0 elseif event==EVT_VIRTUAL_NEXT then choiceSelect.selected=choiceSelect.selected%#choiceSelect.items+1;event=0 elseif event==EVT_VIRTUAL_PREV then choiceSelect.selected=(choiceSelect.selected-2)%#choiceSelect.items+1;event=0 elseif event==EVT_VIRTUAL_ENTER then chooseChoice();event=0 end end
 if swashSelect~=nil then if event==EVT_VIRTUAL_EXIT then swashSelect=nil;event=0 elseif event==EVT_VIRTUAL_NEXT then swashSelect=(swashSelect+1)%7;event=0 elseif event==EVT_VIRTUAL_PREV then swashSelect=(swashSelect+6)%7;event=0 elseif event==EVT_VIRTUAL_ENTER then chooseSwash(swashSelect);event=0 end end
 if easyCalConfirm then if event==EVT_VIRTUAL_EXIT then easyCalConfirm=false;easyCalState='CALIBRATION CANCELLED';event=0 elseif event==EVT_VIRTUAL_NEXT or event==EVT_VIRTUAL_PREV then event=0 elseif event==EVT_VIRTUAL_ENTER then easyCalStart();event=0 end end
 if setupConfirm then if event==EVT_VIRTUAL_EXIT then setupConfirm=nil;setupState='CANCELLED';event=0 elseif event==EVT_VIRTUAL_NEXT or event==EVT_VIRTUAL_PREV then setupConfirm.yes=not setupConfirm.yes;event=0 elseif event==EVT_VIRTUAL_ENTER then local i=setupConfirm.index;local yes=setupConfirm.yes;setupConfirm=nil;if yes then setupSend(setupRows[i][3])else setupState='CANCELLED'end;event=0 end end
 if centerConfirm and event==EVT_VIRTUAL_EXIT then centerConfirm=nil;event=0 end
 if numEdit then if event==EVT_VIRTUAL_EXIT then rfCancelNumber();event=0 elseif numEdit.mode=='dial'then local v=tonumber(numEdit.text)or numEdit.original;local step=numEdit.decimals==1 and(fastRepeat and 1 or 0.1)or valueStep;if event==EVT_VIRTUAL_NEXT then panelValue(v+step);event=0 elseif event==EVT_VIRTUAL_PREV then panelValue(v-step);event=0;event=0 elseif event==EVT_VIRTUAL_ENTER then commitNumber();event=0 end elseif numEdit.mode=='direct'then local actions={'1','2','3','4','5','6','7','8','9','sign','0','dot','inc01','dec01','inc','dec','delete','min','restore','max','fastdec10','clear','fastinc10','cancel','ok'};if event==EVT_VIRTUAL_NEXT then numFocus=numFocus%#actions+1;event=0 elseif event==EVT_VIRTUAL_PREV then numFocus=(numFocus-2)%#actions+1;event=0 elseif event==EVT_VIRTUAL_ENTER then directAction(actions[numFocus]);event=0 end elseif event==EVT_VIRTUAL_NEXT then numFocus=numFocus%11+1;event=0 elseif event==EVT_VIRTUAL_PREV then numFocus=(numFocus-2)%11+1;event=0 elseif event==EVT_VIRTUAL_ENTER then local actions={'min','def','sign','max','fastdec','dec','inc','fastinc','input','cancel','ok'};numberAction(actions[numFocus]);event=0 end end
  if page=='motors'and rfMotorTab==5 and rfMotorGaugeEdit and not help and not numEdit and not choiceSelect then if event==EVT_VIRTUAL_NEXT then rfSendMotorOverride(rfMotorOverridePct+1,true);event=0 elseif event==EVT_VIRTUAL_PREV then rfSendMotorOverride(rfMotorOverridePct-1,true);event=0 elseif event==EVT_VIRTUAL_ENTER then rfMotorGaugeEdit=false;event=0 end end
 if page=='easyServo'and not help and not numEdit and not choiceSelect then activationSource='roller';event=easyServo.event(event,touch);activationSource='touch'end
 if page=='easy'and not help then if event==EVT_VIRTUAL_NEXT then easyMenuFocus=easyMenuFocus%(#easySteps+1)+1;event=0 elseif event==EVT_VIRTUAL_PREV then easyMenuFocus=(easyMenuFocus-2)%(#easySteps+1)+1;event=0 elseif event==EVT_VIRTUAL_ENTER then if easyMenuFocus<=#easySteps then activate({kind='easyStep',index=easyMenuFocus})else page='home';selected=1 end;event=0 end end
 if page=='easyReceiver'and not help then if event==EVT_VIRTUAL_NEXT then easyRxFocus=easyRxFocus%4+1;event=0 elseif event==EVT_VIRTUAL_PREV then easyRxFocus=(easyRxFocus-2)%4+1;event=0 elseif event==EVT_VIRTUAL_ENTER then if easyRxFocus==1 then easyRxScroll=math.max(1,easyRxScroll-1)elseif easyRxFocus==2 then easyRxScroll=math.min(4,easyRxScroll+1)elseif easyRxFocus==3 then easyRxState='READING FC...';statusLiveAt=-1000;rxRead();requestStatusLive()else page='easy';easyMenuFocus=2 end;event=0 end end
 if page=='easyBoardMenu'and not easyCalConfirm and not help then if event==EVT_VIRTUAL_NEXT then easyBoardFocus=easyBoardFocus%5+1;event=0 elseif event==EVT_VIRTUAL_PREV then easyBoardFocus=(easyBoardFocus-2)%5+1;event=0 elseif event==EVT_VIRTUAL_ENTER then if easyBoardFocus==1 then page='easyAlign';easyFocus=1 elseif easyBoardFocus==2 then easyCalConfirm=true;easyCalState='CONFIRM CALIBRATION' elseif easyBoardFocus==3 then page='easyTrim';easyTrimFocus=1;easyTrimDirty=false;easyState='READING ACC TRIM...';cfgRead();statusLiveAt=-1000;requestStatusLive()elseif easyBoardFocus==4 then attitudeBackPage='easyBoardMenu';page='statusAttitude';statusLiveAt=-1000;requestStatusLive()else page='easy';easyMenuFocus=1 end;event=0 end end
 if page=='easyTrim'and not easyTrimConfirm and not help and not numEdit then if event==EVT_VIRTUAL_NEXT then easyTrimFocus=easyTrimFocus%4+1;event=0 elseif event==EVT_VIRTUAL_PREV then easyTrimFocus=(easyTrimFocus-2)%4+1;event=0 elseif event==EVT_VIRTUAL_ENTER then if easyTrimFocus<=2 then local k=easyTrimFocus==1 and'roll'or'pitch';activationSource='roller';beginNumber('easyTrim',k,easyTrimDraft[k],-300,300);activationSource='touch'elseif easyTrimFocus==3 then easyTrimConfirm=true else page='easyBoardMenu';easyBoardFocus=2 end;event=0 end end
 if page=='easyAlign'and not easyConfirm and not help and not numEdit then if event==EVT_VIRTUAL_NEXT then easyFocus=easyFocus%8+1;event=0 elseif event==EVT_VIRTUAL_PREV then easyFocus=(easyFocus-2)%8+1;event=0 elseif event==EVT_VIRTUAL_ENTER then if easyFocus==1 then easyRotate(-1)elseif easyFocus==2 then easyRotate(1)elseif easyFocus==3 then easyFlipBoard()elseif easyFocus<=6 then local k=({'roll','pitch','yaw'})[easyFocus-3];activationSource='roller';beginNumber('easy',k,easyDraft[k],-180,360);activationSource='touch'elseif easyFocus==7 then easyConfirm=true else page='home';selected=1 end;event=0 end end
  if page=='gyro'and not help and not numEdit and not choiceSelect then if event==EVT_VIRTUAL_NEXT then gySel=gySel%#gyRows+1;event=0 elseif event==EVT_VIRTUAL_PREV then gySel=(gySel-2)%#gyRows+1;event=0 elseif event==EVT_VIRTUAL_ENTER then activationSource='roller';gyActivate(gySel);activationSource='touch';event=0 end end
 if page=='power'and not help and not numEdit and not choiceSelect then if event==EVT_VIRTUAL_NEXT then pwSel=pwSel%#pwRows+1;event=0 elseif event==EVT_VIRTUAL_PREV then pwSel=(pwSel-2)%#pwRows+1;event=0 elseif event==EVT_VIRTUAL_ENTER then pwActivate(pwSel);event=0 end end
 if page=='failsafe'and not help and not numEdit and not choiceSelect then if event==EVT_VIRTUAL_NEXT then fsSel=fsSel%#fsRows+1;event=0 elseif event==EVT_VIRTUAL_PREV then fsSel=(fsSel-2)%#fsRows+1;event=0 elseif event==EVT_VIRTUAL_ENTER then fsActivate(fsSel);event=0 end end
 if page=='receiver'and not rxWarning and not help and not numEdit and not choiceSelect then if event==EVT_VIRTUAL_NEXT then rxSel=rxSel%#rxRows+1;event=0 elseif event==EVT_VIRTUAL_PREV then rxSel=(rxSel-2)%#rxRows+1;event=0 elseif event==EVT_VIRTUAL_ENTER then activationSource='roller';rxActivate(rxSel);activationSource='touch';event=0 end end
 if page=='status'and not help and not numEdit and not choiceSelect then if event==EVT_VIRTUAL_NEXT then statusRxScroll=math.min(10,(statusRxScroll or 1)+1);event=0 elseif event==EVT_VIRTUAL_PREV then statusRxScroll=math.max(1,(statusRxScroll or 1)-1);event=0 end end
 if page=='governor'and govTab==4 and govCurveEdit and not help and not numEdit and not choiceSelect then local j=math.max(0,math.min(govCurvePoints-1,govFocus-#govVisibleTabs-2));local i=govCurvePoints==5 and j*2 or j;local d=govConfig.gov_bypass_throttle[i];if event==EVT_VIRTUAL_NEXT or event==EVT_VIRTUAL_INC or event==EVT_VIRTUAL_NEXT_REPT or event==EVT_VIRTUAL_INC_REPT then d.value=math.min(200,(d.value or 0)+1);govDirty=true;govState='LIVE / NOT SAVED';govApi.write(govConfig);govRefresh();event=0 elseif event==EVT_VIRTUAL_PREV or event==EVT_VIRTUAL_DEC or event==EVT_VIRTUAL_PREV_REPT or event==EVT_VIRTUAL_DEC_REPT then d.value=math.max(0,(d.value or 0)-1);govDirty=true;govState='LIVE / NOT SAVED';govApi.write(govConfig);govRefresh();event=0 elseif event==EVT_VIRTUAL_ENTER or event==EVT_VIRTUAL_EXIT then govCurveEdit=false;event=0 end end
 if page=='governor'and not govCurveEdit and not help and not numEdit and not choiceSelect then local tabCount=#govVisibleTabs;local total=tabCount+#govRows+3;if event==EVT_VIRTUAL_NEXT then govFocus=govFocus%total+1;event=0 elseif event==EVT_VIRTUAL_PREV then govFocus=(govFocus-2)%total+1;event=0 elseif event==EVT_VIRTUAL_ENTER then if govFocus<=tabCount then govTab=govVisibleTabs[govFocus];govScroll=1;govRefresh()elseif govFocus<=tabCount+#govRows then local row=govFocus-tabCount;if govTab==4 and row>1 then govCurveEdit=true else activationSource='roller';govEdit(row)end elseif govFocus==tabCount+#govRows+1 then govRead()elseif govFocus==tabCount+#govRows+2 then govSave()else local r=back();draw();return r end;event=0 end end
 if page=='motors'and not help and not numEdit and not choiceSelect and not rfMotorGaugeEdit then local rows=rfMotorPages[rfMotorTab];local total=9+#rows;if event==EVT_VIRTUAL_NEXT then rfMotorFocus=rfMotorFocus%total+1;event=0 elseif event==EVT_VIRTUAL_PREV then rfMotorFocus=(rfMotorFocus-2)%total+1;event=0 elseif event==EVT_VIRTUAL_ENTER then if rfMotorFocus<=6 then rfMotorTab=rfMotorFocus;rfMotorScroll=1 elseif rfMotorFocus<=6+#rows then activationSource='touch';rfMotorActivateRow(rfMotorFocus-6)elseif rfMotorFocus==7+#rows then requestMotor()elseif rfMotorFocus==8+#rows then saveMotor()else local r=back();draw();return r end;event=0 end end
 if cfgPortEdit and not choiceSelect then if event==EVT_VIRTUAL_EXIT then cfgPortEdit=nil;cfgState='SERIAL CHANGE CANCELLED';event=0 elseif cfgPortEdit.confirm then if event==EVT_VIRTUAL_NEXT or event==EVT_VIRTUAL_PREV then cfgPortEdit.focus=cfgPortEdit.focus==3 and 4 or 3;event=0 elseif event==EVT_VIRTUAL_ENTER then cfgPortAction(cfgPortEdit.focus==3 and'yes'or'no');event=0 end elseif event==EVT_VIRTUAL_NEXT then cfgPortEdit.focus=cfgPortEdit.focus%4+1;event=0 elseif event==EVT_VIRTUAL_PREV then cfgPortEdit.focus=(cfgPortEdit.focus-2)%4+1;event=0 elseif event==EVT_VIRTUAL_ENTER then cfgPortAction(({'func','baud','apply','cancel'})[cfgPortEdit.focus]);event=0 end end
 if cfgNameEdit then if event==EVT_VIRTUAL_EXIT then cfgNameEdit=nil;cfgState='NAME CHANGE CANCELLED';event=0 elseif event==EVT_VIRTUAL_NEXT then cfgNameFocus=cfgNameFocus%#cfgNameKeys+1;event=0 elseif event==EVT_VIRTUAL_PREV then cfgNameFocus=(cfgNameFocus-2)%#cfgNameKeys+1;event=0 elseif event==EVT_VIRTUAL_ENTER then cfgNameAction(cfgNameKeys[cfgNameFocus]);event=0 end end
 if page=='configuration3d'and not numEdit and not help then if event==EVT_VIRTUAL_NEXT then cfg3dSel=cfg3dSel%#cfg3dRows+1;event=0 elseif event==EVT_VIRTUAL_PREV then cfg3dSel=(cfg3dSel-2)%#cfg3dRows+1;event=0 elseif event==EVT_VIRTUAL_ENTER then activationSource='roller';cfg3dActivate(cfg3dSel);activationSource='touch';event=0 end end
 if page=='configuration'and not numEdit and not cfgSerialConfirm and not cfgPortEdit and not cfgNameEdit and not cfgSaveConfirm and not help then if event==EVT_VIRTUAL_NEXT then cfgSel=cfgSel%#cfgRows+1;event=0 elseif event==EVT_VIRTUAL_PREV then cfgSel=(cfgSel-2)%#cfgRows+1;event=0 elseif event==EVT_VIRTUAL_ENTER then activationSource='roller';cfgActivate(cfgSel);activationSource='touch';event=0 end end
 if not setupConfirm and page=='setup' and not help then if event==EVT_VIRTUAL_NEXT then setupSel=setupSel%8+1;event=0 elseif event==EVT_VIRTUAL_PREV then setupSel=(setupSel-2)%8+1;event=0 elseif event==EVT_VIRTUAL_ENTER then if setupSel<=7 then setupAsk(setupSel)else local r=back();draw();return r end;event=0 end end
 if not numEdit and not centerConfirm and page=='servos' and not help then
  if event==EVT_VIRTUAL_NEXT then if servoEdit then changeServo(valueStep)else servoSel=(servoSel-1+navStep)%32+1;servoTab=((servoSel-1)%8+1)<=4 and 1 or 2 end
  elseif event==EVT_VIRTUAL_PREV then if servoEdit then changeServo(-valueStep)else servoSel=(servoSel-1-navStep)%32+1;servoTab=((servoSel-1)%8+1)<=4 and 1 or 2 end
  elseif event==EVT_VIRTUAL_ENTER then servoEdit=not servoEdit;if not servoEdit and saveMode==2 then saveServos()end end
  if event==EVT_VIRTUAL_NEXT or event==EVT_VIRTUAL_PREV or event==EVT_VIRTUAL_ENTER then event=0 end
 end
 if not numEdit and page=='profiles' and not help then
  if event==EVT_VIRTUAL_NEXT then if pidEditing then changePid(valueStep)else pidSel=(pidSel-1+navStep)%20+1 end
  elseif event==EVT_VIRTUAL_PREV then if pidEditing then changePid(-valueStep)else pidSel=(pidSel-1-navStep)%20+1 end
  elseif event==EVT_VIRTUAL_ENTER then if pidSel<=17 then pidEditing=not pidEditing;if not pidEditing and saveMode==2 then savePid()end elseif pidSel==18 then savePid()elseif pidSel==19 then requestPid()else selectProfile()end end
  if event==EVT_VIRTUAL_NEXT or event==EVT_VIRTUAL_PREV or event==EVT_VIRTUAL_ENTER then event=0 end
 end
 if page=='mixer'and mixerGaugeEdit and not help and not numEdit then local lim=mixerGaugeEdit==3 and((mixerConfig and mixerConfig.tail_rotor_mode.value or 0)>0 and 125 or 60)or 18;local step=fastRepeat and 1 or 0.1;if event==EVT_VIRTUAL_NEXT then sendMixerOverride(mixerGaugeEdit,math.min(lim,mixerOverrideAngle(mixerGaugeEdit)+step),true);event=0 elseif event==EVT_VIRTUAL_PREV then sendMixerOverride(mixerGaugeEdit,math.max(-lim,mixerOverrideAngle(mixerGaugeEdit)-step),true);event=0 elseif event==EVT_VIRTUAL_ENTER then mixerGaugeEdit=nil;event=0 end end
 if page=='mixer'and not help and not numEdit and not swashSelect and not choiceSelect then if event==EVT_VIRTUAL_NEXT then if mixerSelectedId and string.sub(mixerSelectedId,1,3)=='mxr'and mixerNav<mixerRowCount then mixerNav=math.min(mixerRowCount,mixerNav+navStep);mixerSelectedId='mxr'..mixerNav else mixerCursor=mixerCursor%#hit+1;local b=hit[mixerCursor];mixerSelectedId=b and b.id or nil;if b and string.sub(b.id,1,3)=='mxr'then mixerNav=tonumber(string.sub(b.id,4))or mixerNav end end;event=0 elseif event==EVT_VIRTUAL_PREV then if mixerSelectedId and string.sub(mixerSelectedId,1,3)=='mxr'and mixerNav>1 then mixerNav=math.max(1,mixerNav-navStep);mixerSelectedId='mxr'..mixerNav else mixerCursor=(mixerCursor-2)%#hit+1;local b=hit[mixerCursor];mixerSelectedId=b and b.id or nil;if b and string.sub(b.id,1,3)=='mxr'then mixerNav=tonumber(string.sub(b.id,4))or mixerNav end end;event=0 elseif event==EVT_VIRTUAL_ENTER then local b,ix=findHitId(mixerSelectedId);if not b then b=hit[mixerCursor]else mixerCursor=ix end;if b then activationSource='roller';activate(b.action);activationSource='touch'end;event=0 end end
 if page=='mixer'and mixerTab==2 and not help then if event==EVT_VIRTUAL_NEXT then directionSel=directionSel%8+1;event=0 elseif event==EVT_VIRTUAL_PREV then directionSel=(directionSel-2)%8+1;event=0 elseif event==EVT_VIRTUAL_ENTER then if directionSel<=3 then directionPass[directionSel]=not directionPass[directionSel];event=0 elseif directionSel<=6 then toggleDirection(directionSel-3);event=0 elseif directionSel==7 then saveMixerInputs();event=0 elseif directionSel==8 then local r=back();draw();return r else event=0 end end end
 if event==EVT_VIRTUAL_EXIT then local r=back();draw();return r end
 if not help and n>0 then
   if event==EVT_VIRTUAL_NEXT then selected=selected%n+1 end
   if event==EVT_VIRTUAL_PREV then selected=(selected-2)%n+1 end
   if event==EVT_VIRTUAL_ENTER then local list=page=='home'and home or full;if page=='options'then activate({kind='option',index=selected})else local r=activate({kind='open',index=selected});if r==2 then return 2 end end end
 elseif help and event==EVT_VIRTUAL_ENTER then help=false end
 if type(touch)=='table'and type(touch.x)=='number'and type(touch.y)=='number'then
   if EVT_TOUCH_FIRST and event==EVT_TOUCH_FIRST then local b=findHit(touch.x,touch.y);if b and b.action.kind=='homeFlashHold'then homeFlashHolding=true;homeFlashHoldAt=getTime and getTime()or 0;touchDown=b.id elseif choiceSelect or swashSelect~=nil then rfModalTouchAction=b and b.action or nil;if b then touchDown=b.id;if choiceSelect and b.action.kind=='choice'then choiceSelect.selected=b.action.value elseif swashSelect~=nil and b.action.kind=='swashChoice'then swashSelect=b.action.value end end elseif b and b.action.kind=='advancedRangeSlider'then advancedRangeDrag=b.action.slot;advanced.rangeTouch(advancedRangeDrag,math.max(0,math.min(1,(touch.x-sx(280))/sx(390))),true);touchDown=b.id elseif page=='motors'and rfMotorTab==5 and not numEdit and not choiceSelect and not help and touch.y>=sy(184)and touch.y<=sy(390)and(not b or b.action.kind~='motorOverrideSlider')then pageSwipe={y=touch.y,id=b and b.id or nil,action=b and b.action or nil,moved=false,lastStep=0,dir=0,lastAt=getTime and getTime()or 0,motor=true};touchDown='pageSwipe' elseif(page=='configuration'or page=='receiver'or page=='failsafe'or page=='power'or page=='gyro')and not numEdit and not cfgSaveConfirm and not rxWarning and not choiceSelect and not help and touch.y>=sy(100)and touch.y<=sy(400)then pageSwipe={y=touch.y,id=b and b.id or nil,action=b and b.action or nil,moved=false,lastStep=0,dir=0,lastAt=getTime and getTime()or 0,config=page=='configuration',receiver=page=='receiver',failsafe=page=='failsafe',power=page=='power',gyro=page=='gyro'};touchDown='pageSwipe' elseif page=='mixer'and not numEdit and not swashSelect and not choiceSelect and not centerConfirm and not help and touch.y>=sy(170)and touch.y<=sy(390)and(not b or b.action.kind~='mixOverrideSlider')then pageSwipe={y=touch.y,id=b and b.id or nil,action=b and b.action or nil,moved=false,lastStep=0,dir=0,lastAt=getTime and getTime()or 0};swipeMomentum=0;touchDown='pageSwipe' elseif b and b.action.kind=='govPoint'and page=='governor'and govTab==4 then local j=b.action.value;govCurveDrag=govCurvePoints==5 and j*2 or j;govFocus=#govVisibleTabs+2+j;govCurveEdit=false;local v=math.max(0,math.min(100,(sy(385)-touch.y)/math.max(1,sy(205))*100));govConfig.gov_bypass_throttle[govCurveDrag].value=math.floor(v*2+.5);govDirty=true;govState='LIVE / NOT SAVED';touchDown=b.id
 elseif b and b.action.kind=='motorOverrideSlider'then if rfMotorOverrideOn then rfMotorDrag=true;local q=math.max(0,math.min(1,(touch.x-sx(90))/sx(570)));rfSendMotorOverride(q*100,true);rfMotorLastX=touch.x;touchDown=b.id else motorState='TURN OVERRIDE ON FIRST';touchDown=nil end elseif b and b.action.kind=='mixOverrideSlider'then if not mixerOverrideOn[b.action.axis]then mixerState='TURN OVERRIDE ON FIRST';touchDown=nil else mixerDrag=b.action;local left=sx(300);local q=math.max(0,math.min(1,(touch.x-left)/sx(330)));local ang=-b.action.limit+q*b.action.limit*2;sendMixerOverride(b.action.axis,ang,true);mixerLastX=touch.x;touchDown=b.id end elseif b and b.action.kind=='overrideSlider'then overrideDrag=b.action.index;updateOverrideSlider(overrideDrag,touch.x,false);lastTouchId=b.id;lastTouchAt=getTime and getTime()or 0;touchDown=b.id elseif b then local r=activate(b.action);lastTouchId=b.id;lastTouchAt=getTime and getTime()or 0;touchDown=b.id;if r==2 then return 2 end end
   elseif EVT_TOUCH_SLIDE and event==EVT_TOUCH_SLIDE and advancedRangeDrag then advanced.rangeTouch(advancedRangeDrag,math.max(0,math.min(1,(touch.x-sx(280))/sx(390)))) elseif EVT_TOUCH_SLIDE and event==EVT_TOUCH_SLIDE and pageSwipe then local dy=touch.y-pageSwipe.y;local unit=math.max(6,sy(10));if math.abs(dy)>=unit then local steps=math.max(1,math.floor(math.abs(dy)/unit));local dir=dy<0 and 1 or-1;pageSwipe.moved=true;pageSwipe.lastStep=steps;pageSwipe.dir=dir;pageSwipe.lastAt=getTime and getTime()or 0;if pageSwipe.gyro then gySel=math.max(1,math.min(#gyRows,gySel+dir*steps));gyScroll=math.max(1,math.min(math.max(1,#gyRows-5),gyScroll+dir*steps))elseif pageSwipe.config then cfgSel=math.max(1,math.min(#cfgRows,cfgSel+dir*steps));cfgScroll=math.max(1,math.min(#cfgRows-6,cfgScroll+dir*steps))elseif pageSwipe.power then pwSel=math.max(1,math.min(#pwRows,pwSel+dir*steps));pwScroll=math.max(1,math.min(math.max(1,#pwRows-6),pwScroll+dir*steps)) elseif pageSwipe.failsafe then fsSel=math.max(1,math.min(#fsRows,fsSel+dir*steps));fsScroll=math.max(1,math.min(math.max(1,#fsRows-6),fsScroll+dir*steps)) elseif pageSwipe.receiver then rxSel=math.max(1,math.min(#rxRows,rxSel+dir*steps));rxScroll=math.max(1,math.min(math.max(1,#rxRows-6),rxScroll+dir*steps)) elseif pageSwipe.motor then local maxRow=rfMotor2Present()and 14 or 9;local row=math.max(1,math.min(maxRow,rfMotorFocus-6+dir*steps));rfMotorFocus=6+row;rfMotorScroll=row<=3 and 1 or(row<=6 and 2 or(row<=9 and 3 or 4))else mixerNav=math.max(1,math.min(mixerRowCount,mixerNav+dir*steps));mixerSelectedId='mxr'..mixerNav end;pageSwipe.y=touch.y end
   elseif EVT_TOUCH_SLIDE and event==EVT_TOUCH_SLIDE and govCurveDrag~=nil then local v=math.max(0,math.min(100,(sy(385)-touch.y)/math.max(1,sy(205))*100));govConfig.gov_bypass_throttle[govCurveDrag].value=math.floor(v*2+.5);govDirty=true;govState='LIVE / NOT SAVED'
 elseif EVT_TOUCH_SLIDE and event==EVT_TOUCH_SLIDE and rfMotorDrag then local q=math.max(0,math.min(1,(touch.x-sx(90))/sx(570)));rfSendMotorOverride(q*100,true);rfMotorLastX=touch.x
   elseif EVT_TOUCH_SLIDE and event==EVT_TOUCH_SLIDE and mixerDrag then local q=math.max(0,math.min(1,(touch.x-sx(300))/sx(330)));sendMixerOverride(mixerDrag.axis,-mixerDrag.limit+q*mixerDrag.limit*2,true);mixerLastX=touch.x
   elseif EVT_TOUCH_SLIDE and event==EVT_TOUCH_SLIDE and overrideDrag~=nil then updateOverrideSlider(overrideDrag,touch.x,false)
   elseif EVT_TOUCH_BREAK and event==EVT_TOUCH_BREAK then if homeFlashHolding then local now=getTime and getTime()or 0;local held=now-(homeFlashHoldAt or now);homeFlashHolding=false;homeFlashHoldAt=nil;touchDown=nil;if held>=80 and homeHw.flashSupported then homeFlashConfirm=true;homeFlashState=''elseif held>=80 then homeFlashState='DATAFLASH NOT AVAILABLE'end elseif advancedRangeDrag then advanced.rangeEnd();advancedRangeDrag=nil;touchDown=nil elseif rfModalTouchAction then local ma=rfModalTouchAction;rfModalTouchAction=nil;touchDown=nil;activationSource='touch';activate(ma) elseif pageSwipe then if not pageSwipe.moved then if pageSwipe.gyro then if pageSwipe.action then gyActivate(pageSwipe.action.index or gySel)end elseif pageSwipe.config then if pageSwipe.action then cfgActivate(pageSwipe.action.index or cfgSel)end elseif pageSwipe.power then if pageSwipe.action then pwActivate(pageSwipe.action.index or pwSel)end elseif pageSwipe.failsafe then if pageSwipe.action then if pageSwipe.action.kind=='fsSet'then local d=fsData[pageSwipe.action.channel];if d then beginNumber('failsafe','set'..pageSwipe.action.channel,d.value,875,2125)end else fsActivate(pageSwipe.action.index or fsSel)end end elseif pageSwipe.receiver then if pageSwipe.action then rxActivate(pageSwipe.action.index or rxSel)end elseif pageSwipe.id then mixerSelectedId=pageSwipe.id;local n=tonumber(string.match(pageSwipe.id,'mxr(%d+)'));if n then mixerNav=n end end;if pageSwipe.action and not pageSwipe.config and not pageSwipe.receiver and not pageSwipe.failsafe and not pageSwipe.power and not pageSwipe.gyro then activationSource='touch';activate(pageSwipe.action)end else local now=getTime and getTime()or 0;if now-pageSwipe.lastAt<=12 and pageSwipe.lastStep>1 then swipeMomentum=pageSwipe.dir*math.min(3,pageSwipe.lastStep-1);swipeNext=now+3 end end;pageSwipe=nil;touchDown=nil elseif govCurveDrag~=nil then govApi.write(govConfig);govRefresh();govCurveDrag=nil
 elseif rfMotorDrag then local q=math.max(0,math.min(1,((rfMotorLastX or touch.x)-sx(90))/sx(570)));rfSendMotorOverride(q*100,true);rfMotorDrag=false;rfMotorLastX=nil elseif mixerDrag then local q=math.max(0,math.min(1,((mixerLastX or touch.x)-sx(300))/sx(330)));sendMixerOverride(mixerDrag.axis,-mixerDrag.limit+q*mixerDrag.limit*2,true);mixerDrag=nil;mixerLastX=nil end;if overrideDrag~=nil then updateOverrideSlider(overrideDrag,overrideLastX or touch.x,true);overrideDrag=nil;overrideLastX=nil end;touchDown=nil
   elseif EVT_TOUCH_TAP and event==EVT_TOUCH_TAP then local b=findHit(touch.x,touch.y);if b and lastTouchId==b.id then lastTouchId=nil elseif b then local r=activate(b.action);lastTouchId=nil;if r==2 then return 2 end end end
 end
 draw();return 0
end
rfLogo=Bitmap and Bitmap.open and Bitmap.open('/SCRIPTS/RFLUASETUP/ASSETS/RFLOGO.png')or nil
easyNexusBmps=Bitmap and Bitmap.open and{Bitmap.open('/SCRIPTS/RFLUASETUP/ASSETS/NEXUSXR0.png'),Bitmap.open('/SCRIPTS/RFLUASETUP/ASSETS/NEXUSXR1.png'),Bitmap.open('/SCRIPTS/RFLUASETUP/ASSETS/NEXUSXR2.png'),Bitmap.open('/SCRIPTS/RFLUASETUP/ASSETS/NEXUSXR3.png')}or nil
easyNexusBackBmps=Bitmap and Bitmap.open and{Bitmap.open('/SCRIPTS/RFLUASETUP/ASSETS/NEXUSXRB0.png'),Bitmap.open('/SCRIPTS/RFLUASETUP/ASSETS/NEXUSXRB1.png'),Bitmap.open('/SCRIPTS/RFLUASETUP/ASSETS/NEXUSXRB2.png'),Bitmap.open('/SCRIPTS/RFLUASETUP/ASSETS/NEXUSXRB3.png')}or nil
advanced=nil
advHost={
 header=header,footer=footer,button=button,fill=fill,box=box,txt=txt,hit=function(id,x,y,w,h,a)add(id,x,y,w,h,a)end,line=function(x1,y1,x2,y2,c)if lcd.drawLine then lcd.drawLine(sx(x1),sy(y1),sx(x2),sy(y2),col(c))end end,
 choice=function(title,items,sel,cb)openChoice(title,items,sel,cb)end,
 number=function(key,value,min,max,scale)local shown=scale and value/scale or value;numEdit={kind='advanced',index=key,text=scale and string.format('%.1f',shown)or tostring(shown),original=shown,min=scale and min/scale or min,max=scale and max/scale or max,error=nil,mode=activationSource=='roller'and'dial'or'direct',scale=scale,decimals=scale and 1 or nil};activationSource='touch';numFocus=1 end,numberDial=function(key,value,min,max,scale)local shown=scale and value/scale or value;numEdit={kind='advanced',index=key,text=scale and string.format('%.1f',shown)or tostring(shown),original=shown,min=scale and min/scale or min,max=scale and max/scale or max,error=nil,mode='dial',scale=scale,decimals=scale and 1 or nil};numFocus=1 end,
 back=function()page=advBackTarget or'full';selected=1;scroll=1 end,
 autoSave=function()return saveMode==2 end,save=function(statecb)rf2.mspQueue:add({command=250,processReply=function()statecb('SAVED TO FC EEPROM')end,errorHandler=function()statecb('SAVE FAILED - DISARM FC')end})end
}
function ensureAdvanced()if type(advanced)=='table'then return end;local c=assert(loadScript('/SCRIPTS/RFLUASETUP/PAGESX/advanced.lua'));local factory=c();c=nil;advanced=factory(advHost);factory=nil;collectgarbage()end
easyServo=nil
rfEasyServoReturn=false
function ensureEasyServo()
 if easyServo then return end
 easyServo=assert(loadScript('/SCRIPTS/RFLUASETUP/PAGESX/centerTrim.lua'))()({
  header=header,footer=footer,fill=fill,box=box,txt=txt,button=button,line=function(x1,y1,x2,y2,c)statusDotLine(x1,y1,x2,y2,c,3)end,
  clearHits=function()hit={}end,
  coords=function(x,y)return x*800/(LCD_W or W),y*480/(LCD_H or H)end,
  ready=function()return rfReady end,servos=function()return servoApi end,mixer=function()return mixerApi end,
  override=sendOverride,
  disable=disableOverrides,
  fullOverride=function()rfEasyServoReturn=true;page='servos';servoTab=3;requestServos()end,
  fullServos=function()rfEasyServoReturn=true;page='servos';servoTab=1;servoSel=1;servoEdit=false;servoSelectedId='st1';requestServos()end,
  choice=openChoice,
  number=function(key,value,min,max)
   beginNumber('easyServo',key,value,min,max)
   if string.sub(key,1,3)=='in:'or string.sub(key,1,4)=='cfg:'or key=='angle'then numEdit.decimals=1;numEdit.text=string.format('%.1f',value)end
  end,
  back=function()page='easy';easyMenuFocus=3 end
 })
end
return {run=run}
































































































































