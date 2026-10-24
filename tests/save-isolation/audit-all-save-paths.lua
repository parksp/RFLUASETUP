;(function()
 local function frameValue(p)return(p[1]or 0)+(p[2]or 0)*256+(p[3]or 0)*65536+(p[4]or 0)*16777216.0 end
 local function record(id,confirmed,detail)
  detail=detail:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n',' ')
  print('AUDIT_JSON '..string.format('{"id":"%s","confirmed":%s,"detail":"%s"}',id,tostring(confirmed),detail))
 end
 local reads={[36]=true,[44]=true,[64]=true,[66]=true,[50]=true,[73]=true,[105]=true,[77]=true,[32]=true,[16384]=true,[56]=true,[40]=true,[130]=true,[92]=true,[154]=true,[184]=true,[80]=true,[70]=true}
 local function capture(fn,failReads)
  Q.items={};fn();local frames={};local loops=0
  while #Q.items>0 do
   loops=loops+1;assert(loops<200,'audit queue loop')
   local m=table.remove(Q.items,1);frames[#frames+1]=m
   if failReads and reads[m.command]and m.errorHandler then m.errorHandler()end
  end
  return frames
 end
 local function find(frames,command)for _,m in ipairs(frames)do if m.command==command then return m end end end
 local function case(id,fn)local ok,err=pcall(fn);if not ok then record(id,false,'CASE ERROR: '..tostring(err))end end
 local expectedFeature=2^3+2^10
 case('F01',function()
  gyFeature=0;local frames=capture(function()gyToggle('dynfeature')end);local m=assert(find(frames,37));local bits=frameValue(m.payload)
  record('F01',bit32.band(bits,expectedFeature)~=expectedFeature,'Gyro feature toggle sent full stale mask='..bits..'; serial RX and telemetry bits absent')
 end)
 case('F02',function()
  cfgFeature=0;local frames=capture(function()cfgToggle('feature28')end);local m=assert(find(frames,37));local bits=frameValue(m.payload)
  record('F02',bit32.band(bits,expectedFeature)~=expectedFeature,'Configuration feature toggle sent full stale mask='..bits..'; serial RX and telemetry bits absent')
 end)
 case('F03',function()
  rxFeature=0;rxConfig.provider=9;rxTelemetryUnlocked=true
  local frames=capture(function()rxToggle('telemEnable')end);local m=assert(find(frames,37));rxFeature=frameValue(m.payload)
  record('F03',rxProtocolIndex()==1,'Receiver telemetry enable from stale mask produces protocol index='..rxProtocolIndex()..' (NONE) despite provider=9')
 end)
 case('F04',function()
  rxReading=false;capture(function()rxRead()end,true)
  record('F04',rxState=='CONNECTED / READY','All seven receiver reads failed; displayed state='..rxState)
 end)
 case('F05',function()
  rxConfig.provider=2;fsReading=false;capture(function()fsRead()end,true)
  local frames=capture(function()fsCommit('pulseMin',900)end);local m=assert(find(frames,45))
  record('F05',m.payload[1]==2 and fsState=='CONNECTED / READY','Failsafe failed-read pulse edit resent cached RX provider='..m.payload[1]..'; active provider could be CRSF=9')
 end)
 case('F06',function()
  pwReading=false;pwLiveBusy=false;capture(function()pwRead()end,true)
  local displayed=pwState;local frames=capture(function()pwWriteBattery()end);local m=assert(find(frames,33))
  record('F06',displayed=='CONNECTED / READY'and #m.payload>0,'All power reads failed; state='..displayed..'; battery writer still emitted '..#m.payload..' bytes from cached/default data')
 end)
 case('F07',function()
  gyBusy=false;capture(function()gyRead()end,true)
  record('F07',gyState=='CONNECTED / EXPERT','Feature/filter/three notch-axis reads failed; gyro state='..gyState)
 end)
 local make=assert(load(AUDIT_ADVANCED_SOURCE,'PAGESX/advanced.lua'))()
 local ui={header=function(_,state)AUDIT_ADVANCED_STATE=state end,footer=function()end,txt=function()end,button=function()end,fill=function()end,box=function()end,line=function()end,
  autoSave=function()return false end,save=function(cb)Q:add({command=250,processReply=function()if cb then cb('SAVED')end end})end,back=function()end,number=function()end,numberDial=function()end,choice=function()end}
 case('F08',function()
  local adv=make(ui);capture(function()adv.open('beeper')end,true)
  local frames=capture(function()adv.commit('tone',2)end);local m=assert(find(frames,185))
  record('F08',frameValue(m.payload)==0,'Beeper read failed; changing tone still sends default beep mask=0 and digital mask=0')
 end)
 case('F09',function()
  local adv=make(ui);capture(function()adv.open('blackbox')end,true);adv.draw('blackbox')
  local displayed=AUDIT_ADVANCED_STATE;local frames=capture(function()adv.commit('denom',32)end);local m=assert(find(frames,81))
  record('F09',displayed=='CONNECTED'and m.payload[1]==0,'Both Blackbox reads failed; state='..tostring(displayed)..'; denominator edit resends logging device=NONE')
 end)
 case('P01',function()
  local originalUse=rf2.useApi;local writes={tune=0,ctrl=0,rescue=0,gov=0,rates=0}
  local function api(name)
   return{getDefaults=function()local d={headspeed={value=2000,min=0,max=50000},rates_type={value=6,table={[6]='ROTORFLIGHT'}}};for i=0,50 do d[i]={value=10,min=0,max=1000}end;return d end,
    read=function(cb,param,d)cb(param,d)end,write=function()writes[name]=writes[name]+1 end}
  end
  local apis={mspPidTuning=api('tune'),mspPidProfile=api('ctrl'),mspRescueProfile=api('rescue'),mspGovernorProfile=api('gov'),mspRcTuning=api('rates'),mspStatus={getStatus=function(cb,param)cb(param,{profile=0,rateProfile=0})end}}
  rf2.useApi=function(name)return apis[name]or originalUse(name)end
  local adv=make(ui);adv.open('profiles');adv.commit('pt:0',20)
  local isolated=writes.tune==1 and writes.ctrl==0 and writes.rescue==0 and writes.gov==0
  adv.commit('pg:headspeed',2100);isolated=isolated and writes.tune==1 and writes.gov==1 and writes.ctrl==0 and writes.rescue==0
  local frames=capture(function()adv.activate({op='save'})end)
  isolated=isolated and #frames==1 and frames[1].command==250 and writes.tune==1 and writes.gov==1
  rf2.useApi=originalUse
  record('P01',isolated,'PID and profile headspeed edits call only their own API; SAVE sends EEPROM only, not other profile groups')
 end)
 Q.items={}
 print('PASS: audit probes completed; findings are reported separately, no application source changed by this audit')
end)()
