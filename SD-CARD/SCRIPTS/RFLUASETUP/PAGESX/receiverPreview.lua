-- Read-only rate preview. The quaternion persists when sticks return to center.
-- Rates are a fixed visual reference (90 deg/s at full input), not FC tuning.
return function()
 local M={rotation={1,0,0,0,1,0,0,0,1,version=0},rate=90,frameMs=0}
 local w,x,y,z=1,0,0,0
 local last=nil
 local function matrix()
  local a=M.rotation
  a[1]=1-2*(y*y+z*z);a[2]=2*(x*y-z*w);a[3]=2*(x*z+y*w)
  a[4]=2*(x*y+z*w);a[5]=1-2*(x*x+z*z);a[6]=2*(y*z-x*w)
  a[7]=2*(x*z-y*w);a[8]=2*(y*z+x*w);a[9]=1-2*(x*x+y*y)
  a.version=a.version+1
 end
 function M.reset(now)
  w,x,y,z=1,0,0,0;last=now;M.frameMs=0;matrix()
 end
 function M.update(roll,pitch,yaw,now,fresh)
  local dt=last and now-last or 0;last=now
  M.frameMs=math.max(0,math.floor(dt*1000+.5))
  -- A slow LCD refresh must not skip every update indefinitely. Advance only a
  -- bounded step on a delayed frame; stale telemetry still holds the pose.
  if not fresh or dt<=0 then return M.rotation end
  dt=math.min(dt,.1)
  local scale=M.rate*math.pi/180/100
  local r=math.max(-100,math.min(100,roll))*scale
  local p=math.max(-100,math.min(100,pitch))*scale
  local v=-math.max(-100,math.min(100,yaw))*scale
  local speed=math.sqrt(r*r+p*p+v*v)
  if speed==0 then return M.rotation end
  local a=speed*dt*.5;local k=math.sin(a)/speed
  local dw,dx,dy,dz=math.cos(a),r*k,p*k,v*k
  local nw=w*dw-x*dx-y*dy-z*dz
  local nx=w*dx+x*dw+y*dz-z*dy
  local ny=w*dy-x*dz+y*dw+z*dx
  local nz=w*dz+x*dy-y*dx+z*dw
  local n=math.sqrt(nw*nw+nx*nx+ny*ny+nz*nz)
  w,x,y,z=nw/n,nx/n,ny/n,nz/n;matrix()
  return M.rotation
 end
 return M
end
