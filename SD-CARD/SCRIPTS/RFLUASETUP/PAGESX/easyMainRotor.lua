-- Illustrated Main Rotor settings. Selection is a draft; only Save writes the FC.
return function(h)
 local M={}
 local tab,focus,modal=1,1,nil
 local ready,busy,dirty=false,false,false
 local state='READING FC...'
 local cfg,inputs,edit={},{},{}
 local controls={}
 local titles={'SWASH TYPE','MAIN ROTOR DIRECTION','AILERON DIRECTION','ELEVATOR DIRECTION','COLLECTIVE DIRECTION'}
 local names={'NONE','DIRECT / PASSTHROUGH','CCPM 120','CCPM 135','CCPM 140','FPM 90 L','FPM 90 V'}
 local axes={[3]=1,[4]=2,[5]=4}
 local function fail(s)busy=false;state=s or'FC ERROR / RETRY'end
 local function queue(cmd,payload,ok)rf2.mspQueue:add({command=cmd,payload=payload,processReply=ok,errorHandler=function()fail('FC ERROR / RETRY')end})end
 local function read(done)
  h.mixer().read(function(_,c)
   queue(170,nil,function(_,b)
    if #b<30 or #b%6~=0 then fail('INPUT READ ERROR');return end
    b.offset=1;local t={};for i=0,#b/6-1 do t[i]={rate=rf2.mspHelper.readS16(b),min=rf2.mspHelper.readS16(b),max=rf2.mspHelper.readS16(b)}end
    done(c,t)
   end)
  end,nil,nil,function()fail('MIXER READ ERROR')end)
 end
 local function release(done)
  local function nextAxis(i)
   if i==5 then done();return end
   local p={i};rf2.mspHelper.writeU16(p,2501);queue(191,p,function()nextAxis(i+1)end)
  end
  nextAxis(1)
 end
 local function changed(key,value)edit[key]=value;dirty=true;state='DRAFT / APPLY & SAVE TO TEST'end
 local function loadFC()
  busy=true;ready=false;state='READING FC...'
  read(function(c,t)cfg=c;inputs=t;edit={};ready=true;busy=false;dirty=false;state='FC VALUES / OVERRIDE OFF'end)
 end
 function M.open()
  tab=1;focus=1;modal=nil;edit={};dirty=false;ready=false;busy=true;state='STOPPING MIXER OVERRIDE...'
  if not h.ready()then fail('NO FC LINK / REOPEN');return end
  release(loadFC)
 end
 local function save()
  modal=nil;busy=true;state='CHECKING DISARM...'
  if not h.ready()then fail('NO FC LINK');return end
  queue(101,nil,function(_,b)
   if #b<10 then fail('STATUS READ ERROR');return end
   if b[7]%2~=0 then fail('DISARM FC FIRST');return end
   release(function()
    -- Read fresh blocks so unrelated Mixer fields and all input limits survive.
    read(function(c,t)
     for _,key in ipairs({'swash_type','main_rotor_dir'})do if edit[key]~=nil then c[key].value=edit[key]end end
     local list={};for _,axis in ipairs({1,2,4})do
      if edit[axis]~=nil then
       if not t[axis]or t[axis].rate==0 then fail('ZERO CALIBRATION / CHECK FULL SETUP');return end
       t[axis].rate=math.abs(t[axis].rate)*edit[axis];list[#list+1]=axis
      end
     end
     state='SAVING FC...'
     local function verify()
      read(function(got,gi)
       for _,key in ipairs({'swash_type','main_rotor_dir'})do if edit[key]~=nil and got[key].value~=edit[key]then fail('VERIFY FAILED / RETRY SAVE');return end end
       for _,axis in ipairs(list)do local a,z=gi[axis],t[axis];if not a or a.rate~=z.rate or a.min~=z.min or a.max~=z.max then fail('VERIFY FAILED / RETRY SAVE');return end end
       cfg=got;inputs=gi;edit={};dirty=false;busy=false;ready=true;state='SAVED / VERIFIED'
      end)
     end
     local function writeInput(n)
      local axis=list[n];if not axis then queue(250,nil,verify);return end
      local p={axis};for _,k in ipairs({'rate','min','max'})do rf2.mspHelper.writeU16(p,t[axis][k])end
      queue(171,p,function()writeInput(n+1)end)
     end
     if edit.swash_type~=nil or edit.main_rotor_dir~=nil then h.mixer().write(c,function()writeInput(1)end,function()fail('CONFIG WRITE ERROR / RETRY SAVE')end)else writeInput(1)end
    end)
   end)
  end)
 end
 local function value(key)if edit[key]~=nil then return edit[key]end;if type(key)=='number'then local d=inputs[key];return d and(d.rate<0 and -1 or 1)end;return cfg[key]and cfg[key].value end
 local function line(x,y,x2,y2,c)h.line(x,y,x2,y2,c or'text')end
 local function ellipse(x,y,rx,ry,c)
  local px,py=x+rx,y;for i=1,32 do local a=i*math.pi/16;local nx,ny=x+math.cos(a)*rx,y+math.sin(a)*ry;line(px,py,nx,ny,c);px,py=nx,ny end
 end
 local function arrow(x,y,x2,y2,c)
  line(x,y,x2,y2,c);local a=math.atan(y2-y,x2-x);for _,d in ipairs({-.55,.55})do line(x2,y2,x2-13*math.cos(a+d),y2-13*math.sin(a+d),c)end
 end
 local function btn(id,label,x,y,w,hh,key,v,selected)
  local a={kind='easyMainRotor',key=key,value=v};controls[#controls+1]=a
  h.button(id,label,x,y,w,hh,selected or focus==#controls,a,selected and'orange'or'cyan')
 end
 local function swash(x,y,v)
  ellipse(x,y,40,30,'cyan');ellipse(x,y,4,4,'orange')
  if v==0 then line(x-30,y-23,x+30,y+23,'muted');line(x-30,y+23,x+30,y-23,'muted');return end
  if v==1 then h.txt(x-24,y+9,'DIRECT','muted');return end
  -- Conceptual link locations only: no servo-number or installation claims.
  local angles=v==2 and{-90,30,150}or v==3 and{-90,45,135}or v==4 and{-90,50,130}or v==5 and{-90,0}or{-135,-45}
  for _,a in ipairs(angles)do local r=a*math.pi/180;local xx,yy=x+math.cos(r)*40,y+math.sin(r)*30;line(x,y,xx,yy,'muted');h.fill(xx-4,yy-4,8,8,'orange')end
  arrow(x,y-37,x,y-51,'green')
 end
 local function rotor(x,y,ccw)
  -- Helicopter outline viewed from above: nose at top, tail below.
  line(x-16,y-48,x,y-61,'text');line(x,y-61,x+16,y-48,'text');line(x-16,y-48,x-21,y+30,'text');line(x+16,y-48,x+21,y+30,'text');line(x-21,y+30,x,y+46,'text');line(x+21,y+30,x,y+46,'text');line(x,y+46,x,y+76,'text');line(x-16,y+69,x+16,y+69,'text')
  ellipse(x,y,65,65,'muted');line(x-58,y,x+58,y,'cyan');line(x,y-58,x,y+58,'cyan');ellipse(x,y,7,7,'orange')
  local dir=ccw and -1 or 1;local px,py=x+80,y
  for i=1,22 do local a=dir*i*math.pi/16;local nx,ny=x+80*math.cos(a),y+80*math.sin(a);line(px,py,nx,ny,'orange');if i==22 then arrow(px,py,nx,ny,'orange')end;px,py=nx,ny end
 end
 local function tiltedSwash(x,y,slope)
  local px,py=x+78,y+slope*78
  for i=1,32 do local a=i*math.pi/16;local dx=math.cos(a)*78;local nx,ny=x+dx,y+math.sin(a)*15+slope*dx;line(px,py,nx,ny,'green');px,py=nx,ny end
  ellipse(x,y,7,6,'cyan');line(x-55,y+slope*(-55)+10,x-55,275,'cyan');line(x+55,y+slope*55+10,x+55,275,'cyan');line(x-69,276,x+69,276,'muted')
 end
 local function helicopter(x,y,degrees,side)
  -- Rotate the complete airframe, including mast and skids, as one object.
  local a=degrees*math.pi/180;local ca,sa=math.cos(a),math.sin(a)
  local function segment(x1,y1,x2,y2,c)
   line(x+x1*ca-y1*sa,y+x1*sa+y1*ca,x+x2*ca-y2*sa,y+x2*sa+y2*ca,c)
  end
  local function outline(points,c)
   for i=1,#points do local p,q=points[i],points[i%#points+1];segment(p[1],p[2],q[1],q[2],c)end
  end
  if not side then
   -- Broad rotor blades, central mast, rear fuselage, tail fin and two skids.
   outline({{-86,-31},{-8,-31},{-8,-25},{-86,-25}},'text');outline({{8,-31},{86,-31},{86,-25},{8,-25}},'text')
   segment(-8,-28,8,-28,'orange');segment(0,-28,0,-11,'text')
   outline({{-11,-11},{-24,-1},{-27,15},{-20,28},{20,28},{27,15},{24,-1},{11,-11}},'cyan')
   outline({{-10,-6},{-18,1},{-18,9},{18,9},{18,1},{10,-6}},'muted')
   segment(-21,18,-43,33,'text');segment(21,18,43,33,'text');segment(-50,33,-31,33,'text');segment(31,33,50,33,'text')
   outline({{-4,3},{-4,31},{4,31},{4,3}},'orange');segment(-29,21,29,21,'orange')
   segment(4,16,33,16,'orange');segment(33,4,33,28,'orange');segment(28,8,38,24,'orange')
  else
   -- Side view: rounded canopy at the nose, long boom, visible tail rotor.
   outline({{-52,-18},{-68,-11},{-75,4},{-72,17},{-53,24},{-23,24},{-7,13},{-11,-11},{-24,-18}},'cyan')
   outline({{-55,-13},{-66,-6},{-66,6},{-43,6},{-29,-13}},'muted')
   outline({{-9,1},{83,6},{83,12},{-9,12}},'cyan');segment(78,-15,87,23,'orange');segment(65,8,94,8,'orange')
   segment(75,-2,86,19,'text');segment(75,19,86,-2,'text')
   segment(-41,-19,-41,-36,'text');outline({{-103,-39},{25,-39},{25,-33},{-103,-33}},'text')
   segment(-60,23,-60,34,'text');segment(-19,22,-19,34,'text');segment(-80,34,-2,34,'text');segment(-80,34,-84,29,'text')
  end
 end
 local function diagram(axis)
  h.fill(24,154,358,156,'panel2');h.box(24,154,358,156,'line');h.fill(402,154,374,156,'panel2');h.box(402,154,374,156,'line')
  h.txt(38,165,axis==4 and'TX COLLECTIVE UP'or'MOVE THE HELICOPTER','muted');h.txt(416,165,'EXPECTED SWASH MOVEMENT','green')
  if axis==1 then
   h.txt(40,190,'LEFT','muted');h.txt(315,190,'RIGHT','orange');line(100,233,292,233,'muted');helicopter(202,238,18,false)
   arrow(324,211,324,263,'orange');h.txt(40,285,'TAIL VIEW: LOWER THE RIGHT SIDE','cyan')
   h.txt(435,190,'LEFT','green');h.txt(698,190,'RIGHT','muted');line(589,210,589,275,'muted');tiltedSwash(589,239,-.25);arrow(469,220,469,263,'green');h.txt(435,285,'SWASH: LEFT SIDE DOWN','green')
  elseif axis==2 then
   h.txt(42,190,'NOSE','orange');h.txt(312,190,'TAIL','muted');line(105,237,297,237,'muted');helicopter(218,235,-14,true);arrow(71,214,71,268,'orange');h.txt(42,285,'SIDE VIEW: LOWER THE NOSE','cyan')
   h.txt(420,190,'FRONT','orange');h.txt(697,190,'TAIL','green');line(589,210,589,277,'muted');tiltedSwash(589,238,.24);arrow(709,220,709,264,'green');h.txt(425,285,'SWASH: TAIL SIDE DOWN / TILT BACK','green')
  else
   h.box(116,210,134,63,'muted');line(183,219,183,266,'muted');arrow(183,260,183,215,'orange');h.txt(54,284,'INCREASE COLLECTIVE PITCH','cyan')
   line(589,195,589,278,'muted');ellipse(589,264,65,13,'muted');ellipse(589,224,65,13,'green');arrow(509,262,509,223,'green');arrow(669,262,669,223,'green');h.txt(423,284,'LEVEL SWASH / POSITIVE BLADE PITCH','green')
  end
 end
 function M.draw()
  controls={};h.header('SERVO / SWASH 3 / MAIN ROTOR DIRECTION',busy and'WAIT...'or(dirty and'DRAFT'or'FC VALUES'))
  for i,n in ipairs({'SWASH','ROTOR','AILERON','ELEVATOR','COLLECTIVE'})do btn('emtab'..i,n,20+(i-1)*153,94,148,36,'tab',i,tab==i)end
  if not ready then h.txt(30,190,state,'orange',true)
  elseif tab==1 then
   for i=0,6 do local x=20+(i%4)*193;local y=145+math.floor(i/4)*115;local v=value('swash_type');btn('ems'..i,'',x,y,185,108,'swash',i,v==i);swash(x+92,y+49,i);h.txt(x+9,y+85,names[i+1],v==i and'orange'or'text')end
   h.txt(603,278,'TOP VIEW','cyan');h.txt(603,301,'FRONT = ARROW','muted');h.txt(603,325,'SCHEMATIC','muted');h.txt(26,384,'Choose the linkage layout specified by the helicopter manufacturer.','muted')
  elseif tab==2 then
   for i=0,1 do local x=35+i*385;btn('emrot'..i,'',x,150,350,226,'rotor',i,value('main_rotor_dir')==i);rotor(x+175,248,i==1);h.txt(x+37,345,i==0 and'CLOCKWISE (CW)'or'COUNTERCLOCKWISE (CCW)','text',true)end
   h.txt(30,384,'Rotation direction viewed from ABOVE the main rotor.','cyan')
  else
   local axis=axes[tab];diagram(axis)
   h.txt(28,322,axis==4 and'Collective uses the TX stick; do not tilt the helicopter for this check.'or'Keep sticks centered. Tilt the aircraft and observe the opposite correction.','muted')
   btn('emnormal','NORMAL',200,350,185,38,'direction',1,value(axis)==1);btn('emreverse','REVERSE',405,350,185,38,'direction',-1,value(axis)==-1)
  end
  btn('emsave','APPLY & SAVE',410,405,185,36,'save');btn('emback','< BACK',610,405,170,36,'back')
  h.txt(24,417,state,'orange')
  h.footer('DISARM / motor power disconnected. Drawings are guides, not live measurements.')
  if modal then
   controls={};h.clearHits();h.fill(105,130,590,240,'panel');h.box(105,130,590,240,'orange');h.txt(130,151,modal=='save'and'APPLY MAIN ROTOR SETTINGS?'or'DISCARD UNSAVED CHANGES?','orange',true)
   h.txt(130,193,modal=='save'and'Changes may move the servos. Disconnect motor power.'or'Return to Easy Setup without saving the draft.','text');h.txt(130,227,'Override stays OFF. Verify physical direction after saving.','muted')
   btn('emcancel','CANCEL',150,292,200,45,'cancel');btn('emconfirm',modal=='save'and'APPLY & SAVE'or'DISCARD',425,292,225,45,'confirm')
  end
 end
 function M.back()if busy then state='WAIT FOR FC...';return end;if modal then modal=nil elseif dirty then modal='leave';focus=1 else h.back()end end
 function M.activate(a)
  if busy then return end
  local k=a.key
  if k=='back'then M.back();return elseif k=='cancel'then modal=nil;return elseif k=='confirm'then if modal=='save'then save()else modal=nil;dirty=false;h.back()end;return end
  if modal then return end
  if k=='tab'then tab=a.value;focus=1;return end
  if not ready then return end
  if k=='swash'then changed('swash_type',a.value)elseif k=='rotor'then changed('main_rotor_dir',a.value)elseif k=='direction'then local axis=axes[tab];if inputs[axis].rate==0 then state='ZERO CALIBRATION / CHECK FULL SETUP'else changed(axis,a.value)end elseif k=='save'then if dirty then modal='save';focus=1 else state='NO CHANGES'end end
 end
 function M.event(e)
  if e==EVT_VIRTUAL_NEXT then focus=focus%math.max(1,#controls)+1;return 0 elseif e==EVT_VIRTUAL_PREV then focus=(focus-2)%math.max(1,#controls)+1;return 0 elseif e==EVT_VIRTUAL_ENTER then if controls[focus]then M.activate(controls[focus])end;return 0 end;return e
 end
 return M
end
