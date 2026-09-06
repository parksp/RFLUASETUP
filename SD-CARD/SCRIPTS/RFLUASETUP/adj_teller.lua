

local adjustmentCollector
local timeLastChange=-1
local timeExitTool
local adjfuncIdChanged
local adjfuncValueChanged
local currentAdjfuncId
local currentAdjfuncValue

if not rf2 then assert(loadScript("rf2.lua"))() end

local adjfunctions={



id5 ={ wavs={ "pitch", "rate" } },
id6 ={ wavs={ "roll", "rate" } },
id7 ={ wavs={ "yaw", "rate" } },
id8 ={ wavs={ "pitch", "rc", "rate" } },
id9 ={ wavs={ "roll", "rc", "rate" } },
id10={ wavs={ "yaw", "rc", "rate" } },
id11={ wavs={ "pitch", "rc", "expo" } },
id12={ wavs={ "roll", "rc", "expo" } },
id13={ wavs={ "yaw", "rc", "expo" } },


id14={ wavs={ "pitch", "p", "gain" } },
id15={ wavs={ "pitch", "i", "gain" } },
id16={ wavs={ "pitch", "d", "gain" } },
id17={ wavs={ "pitch", "f", "gain" } },
id18={ wavs={ "roll", "p", "gain" } },
id19={ wavs={ "roll", "i", "gain" } },
id20={ wavs={ "roll", "d", "gain" } },
id21={ wavs={ "roll", "f", "gain" } },
id22={ wavs={ "yaw", "p", "gain" } },
id23={ wavs={ "yaw", "i", "gain" } },
id24={ wavs={ "yaw", "d", "gain" } },
id25={ wavs={ "yaw", "f", "gain" } },

id26={ wavs={ "yaw", "cw", "gain" } },
id27={ wavs={ "yaw", "ccw", "gain" } },
id28={ wavs={ "yaw", "cyclic", "ff" } },
id29={ wavs={ "yaw", "collective", "ff" } },
id30={ wavs={ "yaw", "collective", "dyn" } },
id31={ wavs={ "yaw", "collective", "decay" } },
id32={ wavs={ "pitch", "collective", "ff" } },


id33={ wavs={ "pitch", "gyro", "cutoff" } },
id34={ wavs={ "roll", "gyro", "cutoff" } },
id35={ wavs={ "yaw", "gyro", "cutoff" } },


id36={ wavs={ "pitch", "dterm", "cutoff" } },
id37={ wavs={ "roll", "dterm", "cutoff" } },
id38={ wavs={ "yaw", "dterm", "cutoff" } },


id39={ wavs={ "rescue", "climb", "collective" } },
id40={ wavs={ "rescue", "hover", "collective" } },
id41={ wavs={ "rescue", "hover", "alt" } },
id42={ wavs={ "rescue", "alt", "p", "gain" } },
id43={ wavs={ "rescue", "alt", "i", "gain" } },
id44={ wavs={ "rescue", "alt", "d", "gain" } },


id45={ wavs={ "angle", "level", "gain" } },
id46={ wavs={ "horizon", "level", "gain" } },
id47={ wavs={ "acro", "gain" } },


id48={ wavs={ "gov", "gain" } },
id49={ wavs={ "gov", "p", "gain" } },
id50={ wavs={ "gov", "i", "gain" } },
id51={ wavs={ "gov", "d", "gain" } },
id52={ wavs={ "gov", "f", "gain" } },
id53={ wavs={ "gov", "tta", "gain" } },
id54={ wavs={ "gov", "cyclic", "ff" } },
id55={ wavs={ "gov", "collective", "ff" } },


id56={ wavs={ "pitch", "b", "gain" } },
id57={ wavs={ "roll", "b", "gain" } },
id58={ wavs={ "yaw", "b", "gain" } },


id59={ wavs={ "pitch", "o", "gain" } },
id60={ wavs={ "roll", "o", "gain" } },


id61={ wavs={ "crossc", "gain" } },
id62={ wavs={ "crossc", "ratio" } },
id63={ wavs={ "crossc", "cutoff" } },


id64={ wavs={ "accpitchtrim" } },
id65={ wavs={ "accrolltrim" } },


id66={ wavs={ "ya-in-pr-ga" } },
id67={ wavs={ "ya-in-pr-cu" } },


id68={ wavs={ "pi-se-bo-ga" } },
id69={ wavs={ "ro-se-bo-ga" } },
id70={ wavs={ "ya-se-bo-ga" } },
id71={ wavs={ "co-se-bo-ga" } },


id72={ wavs={ "ya-dy-ce-ga" } },
id73={ wavs={ "ya-dy-de-ga" } },
id74={ wavs={ "ya-dy-de-fi" } },


id75={ wavs={ "ya-pr-cu" } },
}

local function getTelemetryId(name)
local field=getFieldInfo(name)
if field then
return field.id
else
return -1
end
end

local function showMessage(message)
local function drawTextMultiline(x, y, text, options)
local lineSpacing=(LCD_W < 320) and 10 or 25
for str in string.gmatch(text, "([^\n]+)") do
lcd.drawText(x, y, str, options)
y=y + lineSpacing
end
end

lcd.clear()
drawTextMultiline(1, 1, message, 0)
end


local function showValue(label, value)
lcd.clear()
lcd.drawText(1, 1, label, 0)
local y=(LCD_W < 320) and 10 or 25
lcd.drawText(1, y, tostring(value), DBLSIZE)
end


local sportAdjustmentsCollector={}
sportAdjustmentsCollector.__index=sportAdjustmentsCollector

function sportAdjustmentsCollector:new(idSensorName, valueSensorName)
local self=setmetatable({}, sportAdjustmentsCollector)
self.adjfuncId=0
self.adjfuncValue=0
self.adjfuncIdSensorId=getTelemetryId(idSensorName)
if self.adjfuncIdSensorId == -1 then
self.initFailedMessage="No "..idSensorName.." sensor found"
return self
end
self.adjfuncValueSensorId=getTelemetryId(valueSensorName)
if self.adjfuncValueSensorId == -1 then
self.initFailedMessage="No "..valueSensorName.." sensor found"
return self
end

function self:getAdjfuncIdAndValue()
self.adjfuncId=getValue(self.adjfuncIdSensorId)
self.adjfuncValue=getValue(self.adjfuncValueSensorId)
return self.adjfuncId, self.adjfuncValue
end
return self
end

local crsfAdjustmentsCollector={}
crsfAdjustmentsCollector.__index=crsfAdjustmentsCollector

function crsfAdjustmentsCollector:new()
local self=setmetatable({}, crsfAdjustmentsCollector)
self.adjfuncId=0
self.adjfuncValue=0

self.adjfuncIdSensorId=getTelemetryId("AdjF")
self.adjfuncValueSensorId=getTelemetryId("AdjV")
if self.adjfuncIdSensorId == -1 or self.adjfuncValueSensorId == -1 then
self.flightmodeSensorId=getTelemetryId("FM")
if self.flightmodeSensorId == -1 then
self.initFailedMessage="No sensors found. The\nadjustment teller needs\n- an FM sensor (RF2) or\n- AdjF and AdjV (RF2.1+)"
return self
end
end

function self:getAdjfuncIdAndValue()
if self.flightmodeSensorId then
local fm=getValue(self.flightmodeSensorId)
local startIndex, _=string.find(fm, ":")
if startIndex and startIndex > 1 then
self.adjfuncId=string.sub(fm, 1, startIndex-1)
self.adjfuncValue=string.sub(fm, startIndex+1)
end
else
local adjfuncId=getValue(self.adjfuncIdSensorId)
if adjfuncId ~= 0 then self.adjfuncId=adjfuncId end
local adjfuncValue=getValue(self.adjfuncValueSensorId)
if adjfuncValue ~= 0 then self.adjfuncValue=adjfuncValue end
end
return self.adjfuncId, self.adjfuncValue
end
return self
end

local function init()
timeLastChange=0
adjfuncIdChanged=false
adjfuncValueChanged=false

if rf2.runningInSimulator then
adjustmentCollector=sportAdjustmentsCollector:new("Tmp1", "Tmp2")
elseif sportTelemetryPush() ~= nil then
adjustmentCollector=sportAdjustmentsCollector:new("5110", "5111")
else
adjustmentCollector=crsfAdjustmentsCollector:new()
end

if adjustmentCollector.initFailedMessage then
showMessage(adjustmentCollector.initFailedMessage)
timeExitTool=rf2.clock() + 5
return
end

currentAdjfuncId, currentAdjfuncValue=adjustmentCollector:getAdjfuncIdAndValue()

showMessage("Waiting for adjustment...")
end

local function run()
if timeLastChange == -1 then init() end

if timeExitTool then

if rf2.clock() > timeExitTool then return 2 end
return 0
end

if timeLastChange and rf2.clock() - timeLastChange > 1 then
timeLastChange=nil

if adjfuncIdChanged then
local adjfunction=adjfunctions["id"..currentAdjfuncId]
if adjfunction ~= nil then

for i=1, #adjfunction.wavs do
local value=adjfunction.wavs[i]
playFile(rf2.baseDir.."SOUNDS/"..value..".wav")
end
end
end

if adjfuncValueChanged or adjfuncIdChanged then
playNumber(currentAdjfuncValue, 0, 0)
end

adjfuncIdChanged=false
adjfuncValueChanged=false
end

local invalidate=false

local newAdjfuncId, newAdjfuncValue=adjustmentCollector:getAdjfuncIdAndValue()
if newAdjfuncId ~= currentAdjfuncId then
currentAdjfuncId=newAdjfuncId
adjfuncIdChanged=true
invalidate=true
end
if newAdjfuncValue ~= currentAdjfuncValue then
currentAdjfuncValue=newAdjfuncValue
adjfuncValueChanged=true
invalidate=true
end

if invalidate then
timeLastChange=rf2.clock()

local adjfunction=adjfunctions["id"..currentAdjfuncId]
if adjfunction ~= nil then
showValue(adjfunction.name, currentAdjfuncValue)
else
showValue("Unknown adjfunc "..currentAdjfuncId, currentAdjfuncValue)
end

end

return 0
end

return { run=run }
