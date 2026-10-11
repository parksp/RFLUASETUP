-- Prefer indexed bulk replies. For links rejecting MSP170, use isolated,
-- single-attempt MSP174 reads, separated by STATUS replies and checked twice.
local M={}
local mode=nil
local function request(cmd,payload,ok,fail,options)
 local msg={command=cmd,payload=payload,processReply=ok,errorHandler=function()fail('INPUT READ FAILED / MSP '..cmd)end}
 for k,v in pairs(options or{})do msg[k]=v end
 rf2.mspQueue:add(msg)
end
local function decode(b,offset)
 b.offset=offset or 1
 local rate=rf2.mspHelper.readS16(b)
 local lo=rf2.mspHelper.readS16(b)
 local hi=rf2.mspHelper.readS16(b)
 if lo>hi then return nil end
 return{rate=rate,min=lo,max=hi}
end
function M.read(done,fail,send,ids)
 send=send or request;ids=ids or{1,2,3,4}
 local report=fail
 fail=function(err)mode=nil;report(err)end
 local options={maxAttempts=1,replyTimeout=3,isolateReply=true}
 local function singles()
  local result={}
  local function nextAxis(n)
   local axis=ids[n]
   if not axis then mode='single';done(result);return end
   local first=nil
   local function one(pass)
    -- A distinct command separates successive replies that lack an axis ID.
    send(101,nil,function(_,status)
     if #status<10 then fail('INPUT STATUS READ FAILED');return end
     send(174,{axis},function(_,b)
      if #b~=6 then fail('INPUT SIZE ERROR / AXIS '..axis);return end
      local value=decode(b)
      if not value then fail('INPUT LIMIT ERROR / AXIS '..axis);return end
      if pass==1 then first=value;one(2);return end
      if value.rate~=first.rate or value.min~=first.min or value.max~=first.max then
       fail('INPUT UNSTABLE / AXIS '..axis..' / REOPEN');return
      end
      result[axis]=value;nextAxis(n+1)
     end,fail,options)
    end,fail,options)
   end
   one(1)
  end
  nextAxis(1)
 end
 if mode=='single'then singles();return end
 -- A rejected/short bulk reply falls back; malformed limits remain an error.
 send(170,nil,function(_,b)
  if #b<30 or #b%6~=0 then singles();return end
  local result={}
  for i=0,#b/6-1 do
   result[i]=decode(b,i*6+1)
   if not result[i]then fail('INPUT LIMIT ERROR / MSP 170');return end
  end
  for _,i in ipairs(ids)do if not result[i]then fail('INPUT MISSING / AXIS '..i);return end end
  mode='bulk';done(result)
 end,function()singles()end,options)
end
return M
