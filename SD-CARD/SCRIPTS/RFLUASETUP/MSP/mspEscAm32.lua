local motorDirection={
[0]="Normal",
"Reversed",
}

local timingAdvance={
[0]="0 " .. rf2.units.degrees,
"7.5 " .. rf2.units.degrees,
"15 " .. rf2.units.degrees,
"22.5 " .. rf2.units.degrees,
}

local onOff={
[0]="Off",
"On",
}

local protocol={
[0]="Auto",
"DShot 300-600",
"Servo 1-2ms",
"Serial",
"BF Safe Arming",
}

local brakeOnStop={
[0]="Off",
"Brake",
"Active",
}

local variablePwm={
[0]="Fixed",
"Variable",
"By RPM",
}

local lowVoltageCutoff={
[0]="Off",
"Cell based",
"Absolute",
}

local function clamp(value, min, max)
if value < min then return min end
if value > max then return max end
return value
end

local function normalizeTimingAdvance(raw)
if raw == nil then return 0, "legacy" end
if raw >= 10 and raw <= 42 then
return clamp(math.floor((raw - 10) / 8 + 0.5), 0, 3), "new"
end
return clamp(math.floor(raw + 0.5), 0, 3), "legacy"
end

local function encodeTimingAdvance(value, encoding)
value=clamp(math.floor((value or 0) + 0.5), 0, 3)
if encoding == "new" then
return 10 + value * 8
end
return value
end

local function normalizeMotorKv(raw)
if raw == nil then return nil end
return raw * 40 + 20
end

local function encodeMotorKv(value)
if value == nil then return nil end
return clamp(math.floor(((value - 20) / 40) + 0.5), 0, 255)
end

local function normalizeServoLow(raw)
if raw == nil then return nil end
return raw * 2 + 750
end

local function encodeServoLow(value)
if value == nil then return nil end
return clamp(math.floor(((value - 750) / 2) + 0.5), 0, 255)
end

local function normalizeServoHigh(raw)
if raw == nil then return nil end
return raw * 2 + 1750
end

local function encodeServoHigh(value)
if value == nil then return nil end
return clamp(math.floor(((value - 1750) / 2) + 0.5), 0, 255)
end

local function normalizeServoNeutral(raw)
if raw == nil then return nil end
return raw + 1374
end

local function encodeServoNeutral(value)
if value == nil then return nil end
return clamp(math.floor((value - 1374) + 0.5), 0, 255)
end

local function normalizeLowVoltageThreshold(raw)
if raw == nil then return nil end
return raw + 250
end

local function encodeLowVoltageThreshold(value)
if value == nil then return nil end
return clamp(math.floor((value - 250) + 0.5), 0, 255)
end

local function normalizeCurrentLimit(raw)
if raw == nil then return nil end
return raw * 2
end

local function encodeCurrentLimit(value)
if value == nil then return nil end
return clamp(math.floor((value / 2) + 0.5), 0, 255)
end

local function getFirmwareVersion(major, minor)
if not(major and minor) then return "UNKNOWN" end
return string.format("Firmware: %d.%d", major, minor)
end

local function getDefaults()
local d={}
d[0]=nil
d[1]=nil
d[2]=nil
d[3]=nil
d[4]=nil
d[5]=nil
d[6]=nil
d[7]=nil
d[8]=nil
d[9]=nil
d[10]=nil
d[11]=nil
d[12]=nil
d[13]=nil
d[14]=nil
d[15]=nil
d[16]=nil
d[17]=nil
d[18]=nil
d[19]="legacy"
d[20]={ min=0, max=#motorDirection, table=motorDirection }
d[21]={ min=0, max=#onOff, table=onOff }
d[22]={ min=0, max=#onOff, table=onOff }
d[23]={ min=0, max=#onOff, table=onOff }
d[24]={ min=0, max=#variablePwm, table=variablePwm }
d[25]={ min=0, max=#onOff, table=onOff }
d[26]={ min=0, max=#timingAdvance, table=timingAdvance }
d[27]={ min=8, max=144, unit=rf2.units.khz }
d[28]={ min=50, max=150, unit=rf2.units.percentage }
d[29]={ min=20, max=10220, unit=rf2.units.kv }
d[30]={ min=2, max=36 }
d[31]={ min=0, max=#brakeOnStop, table=brakeOnStop }
d[32]={ min=0, max=#onOff, table=onOff }
d[33]={ min=0, max=11 }
d[34]={ min=0, max=#onOff, table=onOff }
d[35]={ min=750, max=1250 }
d[36]={ min=1750, max=2250 }
d[37]={ min=1374, max=1630 }
d[38]={ min=0, max=100 }
d[39]={ min=0, max=#lowVoltageCutoff, table=lowVoltageCutoff }
d[40]={ min=250, max=350, scale=100, unit=rf2.units.volt }
d[41]={ min=0, max=#onOff, table=onOff }
d[42]={ min=0, max=#onOff, table=onOff }
d[43]={ min=5, max=25 }
d[44]={ min=0, max=10 }
d[45]={ min=0, max=10 }
d[46]={ min=70, max=141, unit=rf2.units.celsius }
d[47]={ min=0, max=404 }
d[48]={ min=1, max=10 }
d[49]={ min=0, max=#protocol, table=protocol }
d[50]={ min=0, max=#onOff, table=onOff }
return d
end

local function getEscParameters(callback, callbackParam, data)
data=data or getDefaults()
local message={
command=217, 
ignoreErrors=true,
retryDelay=1,
processReply=function(self, buf)
local signature=rf2.mspHelper.readU8(buf)
if signature ~= 194 then
return
end

data[0]=signature
data[1]=rf2.mspHelper.readU8(buf)
data[2]=rf2.mspHelper.readU8(buf)
data[3]=rf2.mspHelper.readU8(buf)
data[4]=rf2.mspHelper.readU8(buf)
data[5]=rf2.mspHelper.readU8(buf)
data[6]=rf2.mspHelper.readU8(buf)
data[7]=rf2.mspHelper.readU8(buf)
data[8]=rf2.mspHelper.readU8(buf)
data[9]=rf2.mspHelper.readU8(buf)
data[10]=rf2.mspHelper.readU8(buf)
data[11]=rf2.mspHelper.readU8(buf)
data[12]=rf2.mspHelper.readU8(buf)
data[13]=rf2.mspHelper.readU8(buf)
data[14]=rf2.mspHelper.readU8(buf)
data[15]=rf2.mspHelper.readU8(buf)
data[16]=rf2.mspHelper.readU8(buf)
data[17]=rf2.mspHelper.readU8(buf)
data[18]=rf2.mspHelper.readU8(buf)
data[20].value=rf2.mspHelper.readU8(buf)
data[21].value=rf2.mspHelper.readU8(buf)
data[22].value=rf2.mspHelper.readU8(buf)
data[23].value=rf2.mspHelper.readU8(buf)
data[24].value=rf2.mspHelper.readU8(buf)
data[25].value=rf2.mspHelper.readU8(buf)

local timingRaw=rf2.mspHelper.readU8(buf)
data[26].value, data[19]=normalizeTimingAdvance(timingRaw)

data[27].value=rf2.mspHelper.readU8(buf)
data[28].value=rf2.mspHelper.readU8(buf)
data[29].value=normalizeMotorKv(rf2.mspHelper.readU8(buf))
data[30].value=rf2.mspHelper.readU8(buf)
data[31].value=rf2.mspHelper.readU8(buf)
data[32].value=rf2.mspHelper.readU8(buf)
data[33].value=rf2.mspHelper.readU8(buf)
data[34].value=rf2.mspHelper.readU8(buf)
data[35].value=normalizeServoLow(rf2.mspHelper.readU8(buf))
data[36].value=normalizeServoHigh(rf2.mspHelper.readU8(buf))
data[37].value=normalizeServoNeutral(rf2.mspHelper.readU8(buf))
data[38].value=rf2.mspHelper.readU8(buf)
data[39].value=rf2.mspHelper.readU8(buf)
data[40].value=normalizeLowVoltageThreshold(rf2.mspHelper.readU8(buf))
data[41].value=rf2.mspHelper.readU8(buf)
data[42].value=rf2.mspHelper.readU8(buf)
data[43].value=rf2.mspHelper.readU8(buf)
data[44].value=rf2.mspHelper.readU8(buf)
data[45].value=rf2.mspHelper.readU8(buf)
data[46].value=rf2.mspHelper.readU8(buf)
data[47].value=normalizeCurrentLimit(rf2.mspHelper.readU8(buf))
data[48].value=rf2.mspHelper.readU8(buf)
data[49].value=rf2.mspHelper.readU8(buf)
data[50].value=rf2.mspHelper.readU8(buf)


data.firmwareVersion=getFirmwareVersion(data[5], data[6])

callback(callbackParam, data)
end,

}
rf2.mspQueue:add(message)
end

local function setEscParameters(data)
local message={
command=218, 
retryDelay=1,
postSendDelay=2,
payload={}
}

rf2.mspHelper.writeU8(message.payload, data[0])
rf2.mspHelper.writeU8(message.payload, data[1])
rf2.mspHelper.writeU8(message.payload, data[2])
rf2.mspHelper.writeU8(message.payload, data[3])
rf2.mspHelper.writeU8(message.payload, data[4])
rf2.mspHelper.writeU8(message.payload, data[5])
rf2.mspHelper.writeU8(message.payload, data[6])
rf2.mspHelper.writeU8(message.payload, data[7])
rf2.mspHelper.writeU8(message.payload, data[8])
rf2.mspHelper.writeU8(message.payload, data[9])
rf2.mspHelper.writeU8(message.payload, data[10])
rf2.mspHelper.writeU8(message.payload, data[11])
rf2.mspHelper.writeU8(message.payload, data[12])
rf2.mspHelper.writeU8(message.payload, data[13])
rf2.mspHelper.writeU8(message.payload, data[14])
rf2.mspHelper.writeU8(message.payload, data[15])
rf2.mspHelper.writeU8(message.payload, data[16])
rf2.mspHelper.writeU8(message.payload, data[17])
rf2.mspHelper.writeU8(message.payload, data[18])
rf2.mspHelper.writeU8(message.payload, data[20].value)
rf2.mspHelper.writeU8(message.payload, data[21].value)
rf2.mspHelper.writeU8(message.payload, data[22].value)
rf2.mspHelper.writeU8(message.payload, data[23].value)
rf2.mspHelper.writeU8(message.payload, data[24].value)
rf2.mspHelper.writeU8(message.payload, data[25].value)
rf2.mspHelper.writeU8(message.payload, encodeTimingAdvance(data[26].value, data[19]))
rf2.mspHelper.writeU8(message.payload, data[27].value)
rf2.mspHelper.writeU8(message.payload, data[28].value)
rf2.mspHelper.writeU8(message.payload, encodeMotorKv(data[29].value))
rf2.mspHelper.writeU8(message.payload, data[30].value)
rf2.mspHelper.writeU8(message.payload, data[31].value)
rf2.mspHelper.writeU8(message.payload, data[32].value)
rf2.mspHelper.writeU8(message.payload, data[33].value)
rf2.mspHelper.writeU8(message.payload, data[34].value)
rf2.mspHelper.writeU8(message.payload, encodeServoLow(data[35].value))
rf2.mspHelper.writeU8(message.payload, encodeServoHigh(data[36].value))
rf2.mspHelper.writeU8(message.payload, encodeServoNeutral(data[37].value))
rf2.mspHelper.writeU8(message.payload, data[38].value)
rf2.mspHelper.writeU8(message.payload, data[39].value)
rf2.mspHelper.writeU8(message.payload, encodeLowVoltageThreshold(data[40].value))
rf2.mspHelper.writeU8(message.payload, data[41].value)
rf2.mspHelper.writeU8(message.payload, data[42].value)
rf2.mspHelper.writeU8(message.payload, data[43].value)
rf2.mspHelper.writeU8(message.payload, data[44].value)
rf2.mspHelper.writeU8(message.payload, data[45].value)
rf2.mspHelper.writeU8(message.payload, data[46].value)
rf2.mspHelper.writeU8(message.payload, encodeCurrentLimit(data[47].value))
rf2.mspHelper.writeU8(message.payload, data[48].value)
rf2.mspHelper.writeU8(message.payload, data[49].value)
rf2.mspHelper.writeU8(message.payload, data[50].value)

rf2.mspQueue:add(message)
end

return {
read=getEscParameters,
write=setEscParameters,
getDefaults=getDefaults
}
