local onOff = {
    [0] = "Off",
    "On",
}

local startupPower = {
    [0] = "0.031",
    "0.047",
    "0.063",
    "0.094",
    "0.125",
    "0.188",
    "0.25",
    "0.38",
    "0.50",
    "0.75",
    "1.00",
    "1.25",
    "1.50",
}

local motorDirection = {
    [0] = "Normal",
    "Reversed",
    "Forward/Reverse (3D)",
    "Forward/Reverse (3D) Rev",
}

local commutationTiming = {
    [0] = "Low",
    "Medium Low",
    "Medium",
    "Medium High",
    "High",
}

local demagCompensation = {
    [0] = "Off",
    "Low",
    "High",
}

local beaconDelay = {
    [0] = "1 minute",
    "2 minutes",
    "5 minutes",
    "10 minutes",
    "Infinite",
}

local temperatureProtection = {
    [0] = "Disabled",
    "80 C",
    "90 C",
    "100 C",
    "110 C",
    "120 C",
    "130 C",
    "140 C",
}

local function clamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

local function normalizePpm(raw)
    if raw == nil then return nil end
    return raw * 4 + 1000
end

local function encodePpm(value)
    if value == nil then return nil end
    return clamp(math.floor(((value - 1000) / 4) + 0.5), 0, 255)
end

local function getFirmwareVersion(major, minor)
    if not(major and minor) then return "UNKNOWN" end
    return string.format("Firmware: %d.%d", major, minor)
end

local function getDefaults()
    local d = {}
    d[0] = nil
    d[1] = nil
    d[2] = nil
    d[3] = nil
    d[4] = nil
    d[5] = nil
    d[6] = nil
    d[7] = nil
    d[8] = nil
    d[9] = nil
    d[10] = nil
    d[11] = { min = 0, max = #startupPower, table = startupPower }
    d[12] = nil
    d[13] = { min = 0, max = #motorDirection, table = motorDirection }
    d[14] = nil
    d[15] = nil
    d[16] = { min = 0, max = #onOff, table = onOff }
    d[17] = nil
    d[18] = nil
    d[19] = nil
    d[20] = nil
    d[21] = nil
    d[22] = { min = 0, max = #commutationTiming, table = commutationTiming }
    d[23] = nil
    d[24] = nil
    d[25] = nil
    d[26] = { min = 1000, max = 1500, mult = 4 }
    d[27] = { min = 1504, max = 2020, mult = 4 }
    d[28] = { min = 1, max = 255 }
    d[29] = { min = 1, max = 255 }
    d[30] = { min = 0, max = #beaconDelay, table = beaconDelay }
    d[31] = nil
    d[32] = { min = 0, max = #demagCompensation, table = demagCompensation }
    d[33] = nil
    d[34] = { min = 1000, max = 2020, mult = 4 }
    d[35] = nil
    d[36] = { min = 0, max = #temperatureProtection, table = temperatureProtection }
    d[37] = { min = 0, max = #onOff, table = onOff }
    d[38] = nil
    d[39] = nil
    d[40] = { min = 0, max = #onOff, table = onOff }
    d[41] = nil
    d[42] = nil
    d[43] = nil
    d[44] = nil
    d[45] = nil
    d[46] = nil
    d[47] = nil
    d[48] = nil
    return d
end

local function getEscParameters(callback, callbackParam, data)
    data = data or getDefaults()
    local message = {
        command = 217, -- MSP_ESC_PARAMETERS
        ignoreErrors = true, -- it usually works after a few errors (?)
        processReply = function(self, buf)
            local signature = rf2.mspHelper.readU8(buf)
            if signature ~= 193 then
                return
            end

            data[0] = signature
            data[1] = rf2.mspHelper.readU8(buf)
            data[2] = rf2.mspHelper.readU8(buf)
            if data[2] ~= 16 then
                return
            end
            data[3] = rf2.mspHelper.readU8(buf)
            data[4] = rf2.mspHelper.readU8(buf)
            data[5] = rf2.mspHelper.readU8(buf)
            data[6] = rf2.mspHelper.readU8(buf)
            data[7] = rf2.mspHelper.readU8(buf)
            data[8] = rf2.mspHelper.readU8(buf)
            data[9] = rf2.mspHelper.readU8(buf)
            data[10] = rf2.mspHelper.readU8(buf)
            data[11].value = rf2.mspHelper.readU8(buf) - 1
            data[12] = rf2.mspHelper.readU8(buf)
            data[13].value = rf2.mspHelper.readU8(buf) - 1
            data[14] = rf2.mspHelper.readU8(buf)
            data[15] = rf2.mspHelper.readU16(buf)
            data[16].value = rf2.mspHelper.readU8(buf)
            data[17] = rf2.mspHelper.readU8(buf)
            data[18] = rf2.mspHelper.readU8(buf)
            data[19] = rf2.mspHelper.readU8(buf)
            data[20] = rf2.mspHelper.readU8(buf)
            data[21] = rf2.mspHelper.readU8(buf)
            data[22].value = rf2.mspHelper.readU8(buf) - 1
            data[23] = rf2.mspHelper.readU8(buf)
            data[24] = rf2.mspHelper.readU8(buf)
            data[25] = rf2.mspHelper.readU8(buf)
            data[26].value = normalizePpm(rf2.mspHelper.readU8(buf))
            data[27].value = normalizePpm(rf2.mspHelper.readU8(buf))
            data[28].value = rf2.mspHelper.readU8(buf)
            data[29].value = rf2.mspHelper.readU8(buf)
            data[30].value = rf2.mspHelper.readU8(buf) - 1
            data[31] = rf2.mspHelper.readU8(buf)
            data[32].value = rf2.mspHelper.readU8(buf) - 1
            data[33] = rf2.mspHelper.readU8(buf)
            data[34].value = normalizePpm(rf2.mspHelper.readU8(buf))
            data[35] = rf2.mspHelper.readU8(buf)
            data[36].value = rf2.mspHelper.readU8(buf)
            data[37].value = rf2.mspHelper.readU8(buf)
            data[38] = rf2.mspHelper.readU8(buf)
            data[39] = rf2.mspHelper.readU8(buf)
            data[40].value = rf2.mspHelper.readU8(buf)
            data[41] = rf2.mspHelper.readU8(buf)
            data[42] = rf2.mspHelper.readU8(buf)
            data[43] = rf2.mspHelper.readU16(buf)
            data[44] = rf2.mspHelper.readU32(buf)
            data[45] = rf2.mspHelper.readU32(buf)
            data[46] = rf2.mspHelper.readU32(buf)
            data[47] = rf2.mspHelper.readU32(buf)
            data[48] = rf2.mspHelper.readU32(buf)

            -- Derived fields
            data.firmwareVersion = getFirmwareVersion(data[2], data[3])

            callback(callbackParam, data)
        end,

        
    }
    rf2.mspQueue:add(message)
end

local function setEscParameters(data)
    local message = {
        command = 218, -- MSP_SET_ESC_PARAMETERS
        retryDelay = 2,
        postSendDelay = 2,
        payload = {}
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
    rf2.mspHelper.writeU8(message.payload, data[11].value + 1)
    rf2.mspHelper.writeU8(message.payload, data[12])
    rf2.mspHelper.writeU8(message.payload, data[13].value + 1)
    rf2.mspHelper.writeU8(message.payload, data[14])
    rf2.mspHelper.writeU16(message.payload, data[15])
    rf2.mspHelper.writeU8(message.payload, data[16].value)
    rf2.mspHelper.writeU8(message.payload, data[17])
    rf2.mspHelper.writeU8(message.payload, data[18])
    rf2.mspHelper.writeU8(message.payload, data[19])
    rf2.mspHelper.writeU8(message.payload, data[20])
    rf2.mspHelper.writeU8(message.payload, data[21])
    rf2.mspHelper.writeU8(message.payload, data[22].value + 1)
    rf2.mspHelper.writeU8(message.payload, data[23])
    rf2.mspHelper.writeU8(message.payload, data[24])
    rf2.mspHelper.writeU8(message.payload, data[25])
    rf2.mspHelper.writeU8(message.payload, encodePpm(data[26].value))
    rf2.mspHelper.writeU8(message.payload, encodePpm(data[27].value))
    rf2.mspHelper.writeU8(message.payload, data[28].value)
    rf2.mspHelper.writeU8(message.payload, data[29].value)
    rf2.mspHelper.writeU8(message.payload, data[30].value + 1)
    rf2.mspHelper.writeU8(message.payload, data[31])
    rf2.mspHelper.writeU8(message.payload, data[32].value + 1)
    rf2.mspHelper.writeU8(message.payload, data[33])
    rf2.mspHelper.writeU8(message.payload, encodePpm(data[34].value))
    rf2.mspHelper.writeU8(message.payload, data[35])
    rf2.mspHelper.writeU8(message.payload, data[36].value)
    rf2.mspHelper.writeU8(message.payload, data[37].value)
    rf2.mspHelper.writeU8(message.payload, data[38])
    rf2.mspHelper.writeU8(message.payload, data[39])
    rf2.mspHelper.writeU8(message.payload, data[40].value)
    rf2.mspHelper.writeU8(message.payload, data[41])
    rf2.mspHelper.writeU8(message.payload, data[42])
    rf2.mspHelper.writeU16(message.payload, data[43])
    rf2.mspHelper.writeU32(message.payload, data[44])
    rf2.mspHelper.writeU32(message.payload, data[45])
    rf2.mspHelper.writeU32(message.payload, data[46])
    rf2.mspHelper.writeU32(message.payload, data[47])
    rf2.mspHelper.writeU32(message.payload, data[48])

    rf2.mspQueue:add(message)
end

return {
    read = getEscParameters,
    write = setEscParameters,
    getDefaults = getDefaults
}









