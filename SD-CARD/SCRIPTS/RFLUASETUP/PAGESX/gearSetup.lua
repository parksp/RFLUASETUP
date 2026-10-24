-- Exact integer gear products, separate preview/apply and explicit host FC save.
return function(h)
 local M={active=false};local z,model,brand,notice,page,focus={},nil,'',nil,1,1
 local kv,cells,voltageMode,customV=0,6,2,2520
 local governorMargin,loadedRPMFactor=15,90
 local remembered={};local currentKey;local manual=false;local published=nil
 local function clip(s,n)
  if #s<=n then return s end
  local start=n
  while start>0 and s:byte(start)>=128 and s:byte(start)<=191 do start=start-1 end
  local b=s:byte(start)or 0
  local width=b>=240 and 4 or(b>=224 and 3 or(b>=192 and 2 or 1))
  if start+width-1>n then n=start-1 end
  return string.sub(s,1,n)
 end
 local function gcd(a,b)while b~=0 do a,b=b,a%b end;return a end
 local function pair(a,b)local g=gcd(a,b);return a/g,b/g end
 local function independent()return model and (model[8]=='independent_tail'or model[8]=='independent_direct')end
 local function directMain()return model and(model[8]=='direct'or model[8]=='independent_direct')end
 local function ratios()
  if published then
   if published[1]==0 then return nil,'SELECT A DOCUMENTED GEAR OPTION'end
   for i=1,(independent()and 2 or 4)do if not published[i] or published[i]<1 or published[i]>65535 or published[i]%1~=0 then return nil,'INVALID PUBLISHED RATIO' end end
   if independent()then return {published[1],published[2]}end
   return {published[1],published[2],published[3],published[4]}
  end
  for i=1,(independent() and 4 or 8) do if not z[i]or z[i]<1 or z[i]>1000 or z[i]%1~=0 then return nil,'ENTER ALL FITTED GEAR TEETH'end end
  local mn,md=pair(z[1]*z[3],z[2]*z[4]);if independent()then if math.max(mn,md)>65535 then return nil,'RATIO EXCEEDS FC INTEGER RANGE'end;return {mn,md}end
  local tn,td=pair(z[6]*z[8],z[5]*z[7])
  if math.max(mn,md,tn,td)>65535 then return nil,'RATIO EXCEEDS FC INTEGER RANGE'end
  return {mn,md,tn,td}
 end
 local function packV()return voltageMode==3 and customV/100 or cells*(voltageMode==1 and 3.7 or 4.2)end
 local function setTooth(i,v)
  if published or(independent()and i>=5)or(directMain() and i<=4)then return end
  z[i]=v
  for _,link in ipairs(model[9]or{})do
   if i==link[1]then z[link[2]]=v elseif i==link[2]then z[link[1]]=v end
  end
 end
 function M.open(b,m,motorKV)
  brand,model=b,m;currentKey=b..':'..m[6];manual=m[3]==0;z={}
  if remembered[currentKey]then published=remembered[currentKey].published else published=m[10]end
  local src=remembered[currentKey]or m[5]or{0,0,1,1,0,0,1,1}
  for i=1,8 do z[i]=src[i]end
  if motorKV and motorKV>0 then kv=motorKV end
  notice=nil;page=1;focus=1;M.active=true
 end
 function M.set(i,v)
  notice=nil
  if i<=8 then setTooth(i,v)elseif i==9 then kv=v elseif i==10 then cells=v elseif i==11 then customV=v elseif i==12 then governorMargin=v elseif i==13 then loadedRPMFactor=v end
 end
 function M.values()
  local r,err=ratios();if not r then return nil,err end
  if model[8]=='engine'then return nil,'ENGINE DRIVE: KV ESTIMATE NOT APPLICABLE'end
  if loadedRPMFactor<1 or loadedRPMFactor>100 or loadedRPMFactor%1~=0 then return nil,'LOAD FACTOR MUST BE 1 TO 100%'end
  if governorMargin<0 or governorMargin>50 or governorMargin%1~=0 then return nil,'GOV RESERVE MUST BE 0 TO 50%'end
  local motor=kv*packV();local main=motor*r[1]/r[2];local tail;if not independent()then tail=main*r[4]/r[3]end
  local loaded=main*loadedRPMFactor/100;local governed=loaded*(1-governorMargin/100)
  return {mainN=r[1],mainD=r[2],tailN=r[3],tailD=r[4],voltage=packV(),motorRPM=motor,mainRPM=main,tailRPM=tail,kv=kv,cells=cells,independentTail=independent(),loadedMainRPM=loaded,governedMainRPM=governed,governedTailRPM=tail and tail*loadedRPMFactor/100*(1-governorMargin/100)or nil,loadedRPMFactor=loadedRPMFactor,governorMargin=governorMargin}
 end
 function M.action(a,i)
  notice=nil
  if a=='back'then M.active=false
  elseif a=='page'then page=i;focus=i
  elseif a=='edit'then
   if (published and i<=8)or(independent()and i>=5 and i<=8)or(directMain()and i<=4)then return end
   if i==12 then h.number(i,governorMargin,0,50)
   elseif i==13 then h.number(i,loadedRPMFactor,1,100)
   else
    local v=i<=8 and z[i]or(i==9 and kv or(i==10 and cells or customV))
    h.number(i,v,i<=8 and 1 or(i==9 and 1 or(i==10 and 1 or 100)),i<=8 and 1000 or(i==9 and 10000 or(i==10 and 24 or 15000)))
   end
  elseif a=='voltage'then h.choice('BATTERY VOLTAGE',{{'LiPo nominal 3.7 V / cell',1},{'LiPo full 4.2 V / cell',2},{'Custom pack voltage',3}},voltageMode,function(v)voltageMode=v end)
  elseif a=='cells'then local rows={};for n=1,24 do rows[#rows+1]={n..'S',n}end;h.choice('BATTERY CELLS',rows,cells,function(v)cells=v end)
  elseif a=='manual'then published=nil;z=directMain()and{1,1,1,1,0,0,1,1}or{0,0,1,1,0,0,1,1};notice='ENTER ALL FITTED GEAR TEETH'
  elseif a=='reset'then published=model[10];local src=model[5]or{0,0,1,1,0,0,1,1};for n=1,8 do z[n]=src[n]end
  elseif a=='options'then
   local rows={{'Restore documented default',0}}
   for n,o in ipairs(model[7]or{})do rows[#rows+1]={o[1],n}end
   h.choice('DOCUMENTED GEAR OPTIONS',rows,1,function(v)
    if v==0 then M.action('reset')else local opt=model[7][v];published=opt[3];local src=opt[2]or{0,0,1,1,0,0,1,1};for n=1,8 do z[n]=src[n]end end
   end)
  elseif a=='apply'then
   local r,err=ratios();if not r then notice=err;return end
   local ok,msg=h.apply(r[1],r[2],r[3],r[4],brand..' '..model[1]);if not ok then notice=msg;return end
   remembered[currentKey]={published=published};for n=1,8 do remembered[currentKey][n]=z[n]end;M.active=false
  end
 end
 local actions={}
 local function btn(id,label,x,y,w,action,index,color)
  actions[#actions+1]={action,index};h.button('gs'..id,label,x,y,w,32,focus==#actions,{kind='gearSetup',value=action,index=index},color or'cyan')
 end
 function M.event(e)
  if e==EVT_VIRTUAL_EXIT then M.active=false;return true end
  if e==EVT_VIRTUAL_NEXT then focus=focus%math.max(1,#actions)+1;return true
  elseif e==EVT_VIRTUAL_PREV then focus=(focus-2)%math.max(1,#actions)+1;return true
  elseif e==EVT_VIRTUAL_ENTER then local a=actions[focus];if a then M.action(a[1],a[2])end;return true end
  return false
 end
 local function rpm(n)return tostring(math.floor(n+.5))..' RPM'end
 function M.draw()
  actions={};h.header('GEAR / BATTERY / RPM',notice and string.sub(notice,1,22)or'MODEL CONFIGURATION')
  h.txt(24,92,clip(brand..' '..model[1],67),'cyan')
  btn('main','MAIN GEARS',24,117,180,'page',1);btn('tail','TAIL GEARS',216,117,180,'page',2);btn('rpm','BATTERY / RPM',408,117,180,'page',3);btn('gov','GOV ESTIMATE',600,117,176,'page',4)
  if page<=2 and published then
   local r,err=ratios()
   h.txt(28,170,'DOCUMENTED DRIVE RATIOS','orange',true)
   if r then
    h.txt(28,218,string.format('Main rotor: %.6g : 1',r[2]/r[1]),'cyan',true)
    if independent()then h.txt(28,260,'INDEPENDENT TAIL MOTOR / NO FIXED RATIO','cyan',true)
    else h.txt(28,260,string.format('Tail rotor: %.6g x main',r[4]/r[3]),'cyan',true)end
   else h.txt(28,218,err,'orange')end
   h.txt(28,310,'Documented ratio values; these fields are not gear tooth counts.','muted')
   h.txt(28,343,'Custom gearing requires all fitted teeth.','muted')
   btn('manual','ENTER GEARS',550,343,215,'manual')
  elseif page==2 and independent()then
   h.txt(28,175,'INDEPENDENT TAIL MOTOR','cyan',true)
   h.txt(28,227,'Tail speed is controlled by its own motor.','text')
   h.txt(28,270,'There is no fixed tail / main rotor gear ratio.','muted')
   h.txt(28,313,'APPLY MAIN RATIO leaves the tail fields unchanged.','orange')
  elseif page==1 and directMain()then
   h.txt(28,175,'DIRECT DRIVE: MAIN RATIO 1 : 1','cyan',true)
   h.txt(28,227,'The motor shaft drives the main rotor directly.','text')
   h.txt(28,270,'No motor pinion or main reduction gear is fitted.','muted')
   h.txt(28,313,independent()and'Tail motor is independent. APPLY changes main ratio only.'or'Use TAIL GEARS to adjust the fitted belt pulleys.','orange')
  elseif page<=2 then
   local offset=page==1 and 0 or 4
   local labels=page==1 and{'Motor / driver','Stage 1 driven','Stage 2 driver','Main gear'}or{'Main / auto gear','Counter gear','Front pulley','Tail pulley'}
   local xs={104,298,492,686}
   local function line(x,y,x2,y2,color)if h.line then h.line(x,y,x2,y2,color or'cyan')end end
   local function gear(x,y,r)
    for n=0,47 do local a=n*math.pi/24;local b=(n+1)*math.pi/24;local r1=n%4<2 and r or r-5;local r2=(n+1)%4<2 and r or r-5;line(x+math.cos(a)*r1,y+math.sin(a)*r1,x+math.cos(b)*r2,y+math.sin(b)*r2)end
    line(x-6,y,x+6,y);line(x,y-6,x,y+6)
   end
   for n=1,4 do local i=n+offset;h.txt(xs[n]-78,165,labels[n],'text');gear(xs[n],225,n%2==1 and 28 or 38);btn('z'..i,z[i]>0 and tostring(z[i])..' T'or'ENTER T',xs[n]-78,275,156,'edit',i)end
   line(140,225,254,225);line(336,225,452,225,'muted');line(526,225,642,225)
   h.txt(174,202,'DRIVES','muted');h.txt(359,202,'SHAFT','muted');h.txt(565,202,'DRIVES','muted')
   h.txt(28,318,'Single stage: set stage 2 to 1 / 1. Drawings are schematic.','muted')
   local r=ratios()
   if r then
    if page==1 then h.txt(28,344,string.format('Main: (%d / %d) x (%d / %d) = %.6f : 1',z[2],z[1],z[4],z[3],r[2]/r[1]),'cyan')
    else h.txt(28,344,string.format('Tail: (%d / %d) x (%d / %d) = %.6f x main',z[5],z[6],z[7],z[8],r[4]/r[3]),'cyan')end
   else h.txt(28,344,'Enter every fitted tooth count before APPLY.','orange')end
   h.txt(28,372,'Use the actual drive stages; no fixed tail ratio for a tail motor.','muted')
  elseif model[8]=='engine'then
   h.txt(28,185,'ENGINE / NITRO DRIVE','orange',true)
   h.txt(28,235,'Main and tail gearing can be applied normally.','text')
   h.txt(28,275,'Electric motor KV / battery RPM prediction does not apply.','muted')
  elseif page==4 then
   h.txt(28,164,'RPM REFERENCE FOR MANUAL PROFILE SETUP','orange',true)
   h.txt(28,208,'Loaded RPM factor (planning assumption)','text');btn('load','LOAD '..loadedRPMFactor..'%',550,200,215,'edit',13)
   h.txt(28,246,'Governor reserve (planning allowance)','text');btn('margin','RESERVE '..governorMargin..'%',550,238,215,'edit',12)
   local v,err=M.values()
   if not v or kv<=0 then h.txt(28,290,kv<=0 and'Enter KV and battery voltage on BATTERY / RPM.'or err,'orange')
   else
    h.txt(28,284,string.format('%.2f V: no-load main %s',packV(),rpm(v.mainRPM)),'text')
    h.txt(28,315,'Gov max estimate: '..rpm(v.governedMainRPM),'cyan',true)
    h.txt(28,346,string.format('No-load x %d%% load x %d%% remaining',loadedRPMFactor,100-governorMargin),'text')
   end
   h.txt(28,375,'Factors are assumptions, not ESC duty or measured motor efficiency.','muted')
  else
   h.txt(28,164,'Motor KV (from motor selection / editable)','text');btn('kv',kv>0 and tostring(kv)..' KV'or'ENTER KV',550,157,215,'edit',9)
   h.txt(28,202,'Battery cells / voltage basis','text');btn('cells',cells..'S',375,195,100,'cells');btn('voltage',voltageMode==1 and'NOMINAL 3.7V'or(voltageMode==2 and'FULL 4.2V'or'CUSTOM PACK'),490,195,275,'voltage')
   h.txt(28,240,string.format('Pack voltage: %.2f V',packV()),'text');if voltageMode==3 then btn('custom','EDIT VOLTAGE',550,233,215,'edit',11)end
   local v,err=M.values()
   if not v or kv<=0 then h.txt(28,284,kv<=0 and'Select a motor or enter KV to estimate RPM.'or err,'orange')
   else h.txt(28,280,'No-load main: '..rpm(v.mainRPM),'text');h.txt(28,310,'Gov max estimate: '..rpm(v.governedMainRPM),'cyan',true);h.txt(28,340,independent()and'Tail RPM: independent motor / no fixed ratio'or('Tail at estimate: '..rpm(v.governedTailRPM)),'cyan')end
   h.txt(28,371,string.format('Assumed load %d%% / reserve %d%%. Voltage basis shown above.',loadedRPMFactor,governorMargin),'muted')
  end
  local options=model[7]and#model[7]>0
  if page<=2 then
   btn('reset',options and'GEAR OPTIONS'or'RESET GEARS',24,402,190,options and'options'or'reset');btn('apply',independent()and'APPLY MAIN RATIO'or'APPLY RATIOS',230,402,300,'apply',nil,'orange')
  else
   btn('estimate',page==3 and'ESTIMATE INPUTS'or'BATTERY / RPM',24,402,190,'page',page==3 and 4 or 3);btn('gears','< BACK TO GEARS',230,402,300,'page',1)
  end
  btn('back','< BACK',550,402,215,'back')
  if page<=2 then h.footer('Changes are previewed here. APPLY fills fields; SAVE FC stores them.')
  else h.footer('REFERENCE ONLY. Use realistic loaded voltage; set PROFILE 1 / 2 / 3 RPM manually.')end
 end
 return M
end
