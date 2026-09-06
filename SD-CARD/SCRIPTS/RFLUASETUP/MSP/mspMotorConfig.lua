local function u16(a,i)return (a[i]or 0)+(a[i+1]or 0)*256 end
local function put16(a,i,v)v=math.floor(v or 0);a[i]=v%256;a[i+1]=math.floor(v/256)%256 end
local function read(callback,param,data)
 data=data or{}
 rf2.mspQueue:add({command=131,processReply=function(_,buf)
  data.raw={};for i=1,29 do data.raw[i]=rf2.mspHelper.readU8(buf)end
  local r=data.raw;data.minThrottle=u16(r,1);data.maxThrottle=u16(r,3);data.minCommand=u16(r,5);data.motorCount=r[7];data.useDshotTelemetry=r[9];data.protocol=r[10];data.rate=u16(r,11);data.unsynced=r[13];data.poles={r[14],r[15],r[16],r[17]};data.rpmLpf={r[18],r[19],r[20],r[21]};data.mainRatio={u16(r,22),u16(r,24)};data.tailRatio={u16(r,26),u16(r,28)};callback(param,data)
 end,errorHandler=function()if callback then callback(param,nil)end end})
end
local function write(data)
 local r={};for i=1,29 do r[i]=data.raw[i]end
 put16(r,1,data.minThrottle);put16(r,3,data.maxThrottle);put16(r,5,data.minCommand);r[9]=data.useDshotTelemetry;r[10]=data.protocol;put16(r,11,data.rate);r[14]=data.poles[1];put16(r,22,data.mainRatio[1]);put16(r,24,data.mainRatio[2]);put16(r,26,data.tailRatio[1]);put16(r,28,data.tailRatio[2])
 local payload={};for i=1,29 do if i~=7 then payload[#payload+1]=r[i]end end
 rf2.mspQueue:add({command=222,payload=payload})
end
return{read=read,write=write}
