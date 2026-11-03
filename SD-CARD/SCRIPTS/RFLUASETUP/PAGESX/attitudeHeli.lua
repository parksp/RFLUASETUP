-- Small solid helicopter mesh. Read-only: this module never accesses MSP.
-- Fixed model/command/projected tables are reused between radio refreshes.
return function(h)
 local M={updates=0}
 local points,objects,order={},{},{}
 local function point(x,y,z)local p={x,y,z,0,0,0};points[#points+1]=p;return p end
 local function object(kind,a,b,c,color)local o={kind,a,b,c,color,0};objects[#objects+1]=o;order[#order+1]=o end
 local function tri(a,b,c,color)object('t',a,b,c,color)end
 local function quad(a,b,c,d,color)tri(a,b,c,color);tri(a,c,d,color)end
 local function edge(a,b,color)object('l',a,b,nil,color or'text')end
 -- Nose, canopy shoulder and aft frame: recognisable solid silhouette.
 local n=point(62,0,0);local nt=point(45,0,22)
 local fl,fr=point(28,-24,3),point(28,24,3)
 local bl,br=point(-45,-19,0),point(-45,19,0)
 local tl,tr=point(-15,-15,31),point(-15,15,31)
 local low=point(-12,0,-19);local aft=point(-58,0,10)
 quad(n,fl,tl,nt,'orange');quad(n,nt,tr,fr,'orange')
 quad(fl,bl,aft,tl,'blue');quad(fr,tr,aft,br,'cyan')
 quad(tl,aft,tr,nt,'purple');quad(fl,n,fr,low,'muted')
 quad(bl,fl,low,aft,'line');quad(br,aft,low,fr,'panel')
 edge(fl,tl,'cyan');edge(fr,tr,'cyan');edge(tl,nt,'text');edge(tr,nt,'text')
 -- Glazed canopy panels.
 tri(point(37,-18,12),point(5,-16,29),point(32,-3,25),'panel')
 tri(point(37,18,12),point(32,3,25),point(5,16,29),'blue')
 -- Tapered boom, vertical fin and tail rotor.
 local bu,bd=point(-52,0,13),point(-52,0,4)
 local eu,ed=point(-160,0,13),point(-160,0,7)
 quad(bu,bd,ed,eu,'muted');edge(bu,eu,'cyan')
 tri(point(-153,0,10),point(-165,0,43),point(-174,0,12),'orange')
 tri(point(-160,-18,10),point(-139,0,10),point(-160,18,10),'blue')
 local th=point(-160,-13,18);edge(point(-160,0,18),th,'text')
 quad(point(-182,-13,17),point(-182,-13,20),point(-138,-13,20),point(-138,-13,17),'orange')
 quad(point(-162,-13,-4),point(-159,-13,-4),point(-159,-13,40),point(-162,-13,40),'orange')
 -- Landing gear has a near and a far rail; depth sorting handles both.
 for _,side in ipairs({-1,1})do
  local a,b=point(-55,side*34,-29),point(47,side*34,-29)
  edge(a,b,'text');edge(b,point(55,side*34,-23),'text')
  edge(point(-32,side*16,-8),point(-37,side*34,-29),'muted')
  edge(point(22,side*16,-8),point(29,side*34,-29),'muted')
 end
 -- Fixed blades, not a motor animation or a claim about actual rotor rotation.
 local hub=point(0,0,43);edge(point(0,0,20),hub,'text')
 quad(point(-122,-5,43),point(-122,2,43),point(122,5,43),point(122,-2,43),'text')
 quad(point(-5,-122,43),point(2,-122,43),point(5,122,43),point(-2,122,43),'muted')
 local last={};local function delta(a,b)local d=a-b;return(d+180)%360-180 end
 local function farther(a,b)return a[6]<b[6]end
 function M.draw(cx,cy,scale,roll,pitch,yaw,offset,viewYaw)
  roll,pitch,yaw,offset=roll or 0,pitch or 0,yaw or 0,offset or 0
  if last.cx~=cx or last.cy~=cy or last.scale~=scale or last.offset~=offset or last.viewYaw~=viewYaw or not last.roll or math.abs(roll-last.roll)>.3 or math.abs(pitch-last.pitch)>.3 or delta(yaw,last.yaw)~=0 then
   last.cx,last.cy,last.scale,last.offset,last.roll,last.pitch,last.yaw=cx,cy,scale,offset,roll,pitch,yaw
   last.viewYaw=viewYaw
   local r,p=roll*math.pi/180,-pitch*math.pi/180
   local v=(viewYaw or math.pi*.75)+delta(yaw,offset)*math.pi/180
   local cr,sr,cp,sp,cv,sv=math.cos(r),math.sin(r),math.cos(p),math.sin(p),math.cos(v),math.sin(v)
   local size=(scale or 1)*.54
   for i=1,#points do
    local q=points[i];local x,y,z=q[1]+35,q[2],q[3]
    local y1,z1=y*cr-z*sr,y*sr+z*cr
    local x2,z2=x*cp+z1*sp,-x*sp+z1*cp
    local depth,side=x2*cv-y1*sv,x2*sv+y1*cv
    q[4],q[5],q[6]=cx+side*size,cy-(z2-depth*.26)*size,depth
   end
   for i=1,#objects do local o=objects[i];o[6]=(o[2][6]+o[3][6]+(o[4]and o[4][6]or 0))/(o[4]and 3 or 2)end
   table.sort(order,farther);M.updates=M.updates+1
  end
  for i=1,#order do local o=order[i];local a,b,c=o[2],o[3],o[4]
   if o[1]=='t'and h.triangle then h.triangle(a[4],a[5],b[4],b[5],c[4],c[5],o[5])
   elseif o[1]=='t'then h.line(a[4],a[5],b[4],b[5],o[5]);h.line(b[4],b[5],c[4],c[5],o[5]);h.line(c[4],c[5],a[4],a[5],o[5])
   else h.line(a[4],a[5],b[4],b[5],o[5])end
  end
 end
 M.points=#points;M.primitives=#objects
 return M
end
