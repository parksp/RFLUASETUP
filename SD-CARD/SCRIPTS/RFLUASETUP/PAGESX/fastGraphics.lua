-- Cache only drawing commands: never controls, hitboxes, telemetry or FC writes.
return function(h)
 local unit={};for i=0,32 do local a=i*math.pi/16;unit[i+1]={math.cos(a),math.sin(a)}end
 local cache={};local names={'line','fill','box','txt','circle'}
 h.ellipse=function(x,y,rx,ry,c,t)
  t=t or 0
  if rx==ry and h.circle then h.circle(x,y,rx,c,false);return end
  local ca,sa=math.cos(t),math.sin(t);local px,py=x+rx*ca,y+rx*sa
  for i=2,#unit do local u=unit[i];local dx,dy=u[1]*rx,u[2]*ry;local nx,ny=x+dx*ca-dy*sa,y+dx*sa+dy*ca;h.line(px,py,nx,ny,c);px,py=nx,ny end
 end
 h.picture=function(id,key,draw)
  local entry=cache[id]
  if entry and entry.key==key then
   for i=1,#entry.commands do local q=entry.commands[i];h[q.name](table.unpack(q,1,q.n))end
   return
  end
  local commands,saved={},{};local depth=0
  for _,name in ipairs(names)do
   local f=h[name]
   if f then saved[name]=f;h[name]=function(...)
    if depth==0 then local q={...};q.n=select('#',...);q.name=name;commands[#commands+1]=q end
    depth=depth+1;f(...);depth=depth-1
   end end
  end
  local ok,err=pcall(draw)
  for name,f in pairs(saved)do h[name]=f end
  if not ok then error(err)end
  cache[id]={key=key,commands=commands}
 end
end
