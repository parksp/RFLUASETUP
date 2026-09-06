local requestedSensorsById=...

local function decNil(data, pos)
return nil, pos
end

local function decU8(data, pos)
return data[pos], pos+1
end

local function decS8(data, pos)
local val,ptr=decU8(data,pos)
return val < 0x80 and val or val - 0x100, ptr
end

local function decU16(data, pos)
return bit32.lshift(data[pos],8) + data[pos+1], pos+2
end

local function decS16(data, pos)
local val,ptr=decU16(data,pos)
return val < 0x8000 and val or val - 0x10000, ptr
end

local function decU12U12(data, pos)
local a=bit32.lshift(bit32.extract(data[pos],0,4),8) + data[pos+1]
local b=bit32.lshift(bit32.extract(data[pos],4,4),8) + data[pos+2]
return a,b,pos+3
end

local function decS12S12(data, pos)
local a,b,ptr=decU12U12(data, pos)
return a < 0x0800 and a or a - 0x1000, b < 0x0800 and b or b - 0x1000, ptr
end

local function decU24(data, pos)
return bit32.lshift(data[pos],16) + bit32.lshift(data[pos+1],8) + data[pos+2], pos+3
end

local function decS24(data, pos)
local val,ptr=decU24(data,pos)
return val < 0x800000 and val or val - 0x1000000, ptr
end

local function decU32(data, pos)
return bit32.lshift(data[pos],24) + bit32.lshift(data[pos+1],16) + bit32.lshift(data[pos+2],8) + data[pos+3], pos+4
end

local function decS32(data, pos)
local val,ptr=decU32(data,pos)
return val < 0x80000000 and val or val - 0x100000000, ptr
end

local function decCellV(data, pos)
local val,ptr=decU8(data,pos)
return val > 0 and val + 200 or 0, ptr
end

local function decCells(data, pos)
local cnt,val,vol
cnt,pos=decU8(data,pos)
setTelemetryValue(0x1020, 0, 0, cnt, UNIT_RAW, 0, "Cel#")
for i=1, cnt
do
val,pos=decU8(data,pos)
val=val > 0 and val + 200 or 0
vol=bit32.lshift(cnt,24) + bit32.lshift(i-1, 16) + val
setTelemetryValue(0x102F, 0, 0, vol, UNIT_CELLS, 2, "Cels")
end
return nil, pos
end

local function decControl(data, pos)
local r,p,y,c
p,r,pos=decS12S12(data,pos)
y,c,pos=decS12S12(data,pos)
setTelemetryValue(0x1031, 0, 0, p, UNIT_DEGREE, 2, "CPtc")
setTelemetryValue(0x1032, 0, 0, r, UNIT_DEGREE, 2, "CRol")
setTelemetryValue(0x1033, 0, 0, 3*y, UNIT_DEGREE, 2, "CYaw")
setTelemetryValue(0x1034, 0, 0, c, UNIT_DEGREE, 2, "CCol")
return nil, pos
end

local function decAttitude(data, pos)
local p,r,y
p,pos=decS16(data,pos)
r,pos=decS16(data,pos)
y,pos=decS16(data,pos)
setTelemetryValue(0x1101, 0, 0, p, UNIT_DEGREE, 1, "Ptch")
setTelemetryValue(0x1102, 0, 0, r, UNIT_DEGREE, 1, "Roll")
setTelemetryValue(0x1103, 0, 0, y, UNIT_DEGREE, 1, "Yaw")
return nil, pos
end

local function decAccel(data, pos)
local x,y,z
x,pos=decS16(data,pos)
y,pos=decS16(data,pos)
z,pos=decS16(data,pos)
setTelemetryValue(0x1111, 0, 0, x, UNIT_G, 2, "AccX")
setTelemetryValue(0x1112, 0, 0, y, UNIT_G, 2, "AccY")
setTelemetryValue(0x1113, 0, 0, z, UNIT_G, 2, "AccZ")
return nil, pos
end

local function decLatLong(data, pos)
local UNIT_GPS_LONGITUDE=43
local UNIT_GPS_LATITUDE=44
local lat,lon
lat,pos=decS32(data,pos)
lon,pos=decS32(data,pos)
setTelemetryValue(0x1125, 0, 0, 0, UNIT_GPS, 0, "GPS")
setTelemetryValue(0x1125, 0, 0, lat/10, UNIT_GPS_LATITUDE)
setTelemetryValue(0x1125, 0, 0, lon/10, UNIT_GPS_LONGITUDE)
return nil, pos
end

local function decAdjFunc(data, pos)
local fun,val
fun,pos=decU16(data,pos)
val,pos=decS32(data,pos)
setTelemetryValue(0x1221, 0, 0, fun, UNIT_RAW, 0, "AdjF")
setTelemetryValue(0x1222, 0, 0, val, UNIT_RAW, 0, "AdjV")
return nil, pos
end

local sensorsById={

[0]={ [0]=0x1000, "NONE", UNIT_RAW, 0, decNil },

[1]={ [0]=0x1001, "BEAT", UNIT_RAW, 0, decU16 },


[3]={ [0]=0x1011, "Vbat", UNIT_VOLTS, 2, decU16 },

[4]={ [0]=0x1012, "Curr", UNIT_AMPS, 2, decU16 },

[5]={ [0]=0x1013, "Capa", UNIT_MAH, 0, decU16 },

[6]={ [0]=0x1014, "Bat%", UNIT_PERCENT, 0, decU8 },


[7]={ [0]=0x1020, "Cel#", UNIT_RAW, 0, decU8 },

[8]={ [0]=0x1021, "Vcel", UNIT_VOLTS, 2, decCellV },

[9]={ [0]=0x102F, "Cels", UNIT_VOLTS, 2, decCells },


[10]={ [0]=0x1030, "Ctrl", UNIT_RAW, 0, decControl },

[11]={ [0]=0x1031, "CPtc", UNIT_DEGREE, 1, decS16 },

[12]={ [0]=0x1032, "CRol", UNIT_DEGREE, 1, decS16 },

[13]={ [0]=0x1033, "CYaw", UNIT_DEGREE, 1, decS16 },

[14]={ [0]=0x1034, "CCol", UNIT_DEGREE, 1, decS16 },

[15]={ [0]=0x1035, "Thr", UNIT_PERCENT, 0, decS8 },


[17]={ [0]=0x1041, "EscV", UNIT_VOLTS, 2, decU16 },

[18]={ [0]=0x1042, "EscI", UNIT_AMPS, 2, decU16 },

[19]={ [0]=0x1043, "EscC", UNIT_MAH, 0, decU16 },

[20]={ [0]=0x1044, "EscR", UNIT_RPMS, 0, decU24 },

[21]={ [0]=0x1045, "EscP", UNIT_PERCENT, 1, decU16 },

[22]={ [0]=0x1046, "Esc%", UNIT_PERCENT, 1, decU16 },

[23]={ [0]=0x1047, "EscT", UNIT_CELSIUS, 0, decU8 },

[24]={ [0]=0x1048, "BecT", UNIT_CELSIUS, 0, decU8 },

[25]={ [0]=0x1049, "BecV", UNIT_VOLTS, 2, decU16 },

[26]={ [0]=0x104A, "BecI", UNIT_AMPS, 2, decU16 },

[27]={ [0]=0x104E, "EscF", UNIT_RAW, 0, decU32 },

[28]={ [0]=0x104F, "Esc#", UNIT_RAW, 0, decU8 },


[30]={ [0]=0x1051, "Es2V", UNIT_VOLTS, 2, decU16 },

[31]={ [0]=0x1052, "Es2I", UNIT_AMPS, 2, decU16 },

[32]={ [0]=0x1053, "Es2C", UNIT_MAH, 0, decU16 },

[33]={ [0]=0x1054, "Es2R", UNIT_RPMS, 0, decU24 },

[36]={ [0]=0x1057, "Es2T", UNIT_CELSIUS, 0, nil },

[41]={ [0]=0x105F, "Es2#", UNIT_RAW, 0, decU8 },


[42]={ [0]=0x1080, "Vesc", UNIT_VOLTS, 2, decU16 },

[43]={ [0]=0x1081, "Vbec", UNIT_VOLTS, 2, decU16 },

[44]={ [0]=0x1082, "Vbus", UNIT_VOLTS, 2, decU16 },

[45]={ [0]=0x1083, "Vmcu", UNIT_VOLTS, 2, decU16 },


[46]={ [0]=0x1090, "Iesc", UNIT_AMPS, 2, decU16 },

[47]={ [0]=0x1091, "Ibec", UNIT_AMPS, 2, decU16 },

[48]={ [0]=0x1092, "Ibus", UNIT_AMPS, 2, decU16 },

[49]={ [0]=0x1093, "Imcu", UNIT_AMPS, 2, decU16 },


[50]={ [0]=0x10A0, "Tesc", UNIT_CELSIUS, 0, decU8 },

[51]={ [0]=0x10A1, "Tbec", UNIT_CELSIUS, 0, decU8 },

[52]={ [0]=0x10A3, "Tmcu", UNIT_CELSIUS, 0, decU8 },


[57]={ [0]=0x10B1, "Hdg", UNIT_DEGREE, 1, decS16 },

[58]={ [0]=0x10B2, "Alt", UNIT_METERS, 2, decS24 },

[59]={ [0]=0x10B3, "Var", UNIT_METERS_PER_SECOND, 2, decS16 },


[60]={ [0]=0x10C0, "Hspd", UNIT_RPMS, 0, decU16 },

[61]={ [0]=0x10C1, "Tspd", UNIT_RPMS, 0, decU16 },


[64]={ [0]=0x1100, "Attd", UNIT_DEGREE, 1, decAttitude },

[65]={ [0]=0x1101, "Ptch", UNIT_DEGREE, 0, decS16 },

[66]={ [0]=0x1102, "Roll", UNIT_DEGREE, 0, decS16 },

[67]={ [0]=0x1103, "Yaw", UNIT_DEGREE, 0, decS16 },


[68]={ [0]=0x1110, "Accl", UNIT_G, 2, decAccel },

[69]={ [0]=0x1111, "AccX", UNIT_G, 1, decS16 },

[70]={ [0]=0x1112, "AccY", UNIT_G, 1, decS16 },

[71]={ [0]=0x1113, "AccZ", UNIT_G, 1, decS16 },


[73]={ [0]=0x1121, "Sats", UNIT_RAW, 0, decU8 },

[74]={ [0]=0x1122, "PDOP", UNIT_RAW, 0, decU8 },

[75]={ [0]=0x1123, "HDOP", UNIT_RAW, 0, decU8 },

[76]={ [0]=0x1124, "VDOP", UNIT_RAW, 0, decU8 },

[77]={ [0]=0x1125, "GPS", UNIT_RAW, 0, decLatLong },

[78]={ [0]=0x1126, "GAlt", UNIT_METERS, 1, decS16 },

[79]={ [0]=0x1127, "GHdg", UNIT_DEGREE, 1, decS16 },

[80]={ [0]=0x1128, "GSpd", UNIT_METERS_PER_SECOND, 2, decU16 },

[81]={ [0]=0x1129, "GDis", UNIT_METERS, 1, decU16 },

[82]={ [0]=0x112A, "GDir", UNIT_METERS, 1, decU16 },


[85]={ [0]=0x1141, "CPU%", UNIT_PERCENT, 0, decU8 },

[86]={ [0]=0x1142, "SYS%", UNIT_PERCENT, 0, decU8 },

[87]={ [0]=0x1143, "RT%", UNIT_PERCENT, 0, decU8 },


[88]={ [0]=0x1200, "MDL#", UNIT_RAW, 0, decU8 },

[89]={ [0]=0x1201, "Mode", UNIT_RAW, 0, decU16 },

[90]={ [0]=0x1202, "ARM", UNIT_RAW, 0, decU8 },

[91]={ [0]=0x1203, "ARMD", UNIT_RAW, 0, decU32 },

[92]={ [0]=0x1204, "Resc", UNIT_RAW, 0, decU8 },

[93]={ [0]=0x1205, "Gov", UNIT_RAW, 0, decU8 },


[95]={ [0]=0x1211, "PID#", UNIT_RAW, 0, decU8 },

[96]={ [0]=0x1212, "RTE#", UNIT_RAW, 0, decU8 },

[97]={ [0]=0x1214, "BAT#", UNIT_RAW, 0, decU8 },

[98]={ [0]=0x1213, "LED#", UNIT_RAW, 0, decU8 },


[99]={ [0]=0x1220, "ADJ", UNIT_RAW, 0, decAdjFunc },


[100]={[0]=0xDB00, "DBG0", UNIT_RAW, 0, decS32 },
[101]={[0]=0xDB01, "DBG1", UNIT_RAW, 0, decS32 },
[102]={[0]=0xDB02, "DBG2", UNIT_RAW, 0, decS32 },
[103]={[0]=0xDB03, "DBG3", UNIT_RAW, 0, decS32 },
[104]={[0]=0xDB04, "DBG4", UNIT_RAW, 0, decS32 },
[105]={[0]=0xDB05, "DBG5", UNIT_RAW, 0, decS32 },
[106]={[0]=0xDB06, "DBG6", UNIT_RAW, 0, decS32 },
[107]={[0]=0xDB07, "DBG7", UNIT_RAW, 0, decS32 },
}

local function initializeSensors(ids)
local data={ 0, 0, 0, 0, 0, 0, 0, 0 }
setTelemetryValue(0xEE01, 0, 0, 0, UNIT_RAW, 0, "*Cnt")
setTelemetryValue(0xEE02, 0, 0, 0, UNIT_RAW, 0, "*Skp")

for i=1, #ids do
local id=ids[i]
if id ~= 0 and sensorsById[id] ~= nil then
local sensor=sensorsById[id]
local ptr=1
local val=(sensor[4])(data, ptr)
if val then
setTelemetryValue(sensor[0], 0, 0, 0, sensor[2], sensor[3], sensor[1])
end
end
end
end

local function getSensorsBySid(ids)







local result={}
for i=1, #ids do
local id=ids[i]
if id ~= 0 and sensorsById[id] ~= nil then
local sensor=sensorsById[id]
result[sensor[0]]={ sensor[1], sensor[2], sensor[3], sensor[4] }
end
end
return result
end

initializeSensors(requestedSensorsById)
return getSensorsBySid(requestedSensorsById)
