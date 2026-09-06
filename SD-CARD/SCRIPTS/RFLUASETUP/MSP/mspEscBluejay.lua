local onOff = {
    [0] = "Off",
    "On",
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

local rampupPower = {
    [0] = "Off",
    "1x (More protection)",
    "2x",
    "3x",
    "4x",
    "5x",
    "6x",
    "7x",
    "8x",
    "9x",
    "10x",
    "11x",
    "12x",
    "13x (Less protection)"
}

local edtOnOff = {
    [100] = "Off",
    [1] = "On",
}

local powerRating = { [0] = "1S", "2S+"}

local function clamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

local function getFirmwareVersion(major, minor)
    if not(major and minor) then return "UNKNOWN" end
    return string.format("Firmware: %d.%d", major, minor)
end

local function normalizeStartupPowerMin(raw)
    if raw == nil then return nil end
    return math.floor((raw * 1000 / 2047) + 1000 + 0.5)
end

local function encodeStartupPowerMin(value)
    if value == nil then return nil end
    return clamp(math.floor(((value - 1000) * 2047) / 1000 + 0.5), 0, 255)
end

local function normalizeStartupPowerMax(raw)
    if raw == nil then return nil end
    return math.floor((raw * 1000 / 250) + 1000 + 0.5)
end

local function encodeStartupPowerMax(value)
    if value == nil then return nil end
    return clamp(math.floor(((value - 1000) * 250) / 1000 + 0.5), 0, 255)
end

local function getDefaults()
    local d = {}
	d[0] = nil
	d[1] = nil
	d[2] = nil
	d[3] = nil
	d[4] = nil
	d[5] = nil
	d[6] = { min = 1000, max = 1125, mult = 5 }
	d[7] = nil
	d[8] = nil
	d[9] = { min = 1004, max = 1300, mult = 4 }
	d[10] = nil
	d[11] = { min = 0, max = 255, table = rampupPower }
	d[12] = nil
	d[13] = { min = 0, max = #motorDirection, table = motorDirection }
	d[14] = nil
	d[15] = nil
	d[16] = nil
	d[17] = { min = 0, max = 255 }
	d[18] = nil
	d[19] = { min = 0, max = #commutationTiming, table = commutationTiming }
	d[20] = nil
	d[21] = nil
	d[22] = { min = 1, max = 255 }
	d[23] = { min = 1, max = 255 }
	d[24] = { min = 0, max = #beaconDelay, table = beaconDelay }
	d[25] = nil
	d[26] = { min = 0, max = #demagCompensation, table = demagCompensation }
	d[27] = nil
	d[28] = nil
	d[29] = { min = 0, max = #temperatureProtection, table = temperatureProtection }
	d[30] = { min = 0, max = #onOff, table = onOff }
	d[31] = nil
	d[32] = { min = 0, max = #onOff, table = onOff }
	d[33] = nil
	d[34] = { min = 0, max = #powerRating, table = powerRating }
	d[35] = { min = 0, max = #onOff, table = edtOnOff }
	d[36] = nil
	d[37] = nil
	d[38] = nil
	d[39] = nil
	d[40] = nil
	d[41] = nil
    return d
end

local function getEscParameters(callback, callbackParam, data)
    data = data or getDefaults()
    local message = {
        command = 217, -- MSP_ESC_PARAMETERS
        ignoreErrors = true, -- it usually works after a few errors (?)
        retryDelay = 0, -- fast retry
        processReply = function(self, buf)
            local signature = rf2.mspHelper.readU8(buf)
            if signature ~= 193 then
                return
            end

            data[0] = signature
            data[1] = rf2.mspHelper.readU8(buf)
            data[2] = rf2.mspHelper.readU8(buf)
            if data[2] ~= 0 then
                return
            end
            data[3] = rf2.mspHelper.readU8(buf)
            data[4] = rf2.mspHelper.readU8(buf)
            data[5] = rf2.mspHelper.readU8(buf)
            data[6].value = normalizeStartupPowerMin(rf2.mspHelper.readU8(buf))
            data[7] = rf2.mspHelper.readU8(buf)
            data[8] = rf2.mspHelper.readU8(buf)
            data[9].value = normalizeStartupPowerMax(rf2.mspHelper.readU8(buf))
            data[10] = rf2.mspHelper.readU8(buf)
            data[11].value = rf2.mspHelper.readU8(buf)
            data[12] = rf2.mspHelper.readU8(buf)
            data[13].value = rf2.mspHelper.readU8(buf) - 1
            data[14] = rf2.mspHelper.readU8(buf)
            data[15] = rf2.mspHelper.readU16(buf)
            data[16] = rf2.mspHelper.readU8(buf)
            data[17].value = rf2.mspHelper.readU8(buf)
            data[18] = rf2.mspHelper.readU32(buf)
            data[19].value = rf2.mspHelper.readU8(buf) - 1
            data[20] = rf2.mspHelper.readU32(buf)
            data[21] = rf2.mspHelper.readU8(buf)
            data[22].value = rf2.mspHelper.readU8(buf)
            data[23].value = rf2.mspHelper.readU8(buf)
            data[24].value = rf2.mspHelper.readU8(buf) - 1
            data[25] = rf2.mspHelper.readU8(buf)
            data[26].value = rf2.mspHelper.readU8(buf) - 1
            data[27] = rf2.mspHelper.readU16(buf)
            data[28] = rf2.mspHelper.readU8(buf)
            data[29].value = rf2.mspHelper.readU8(buf)
            data[30].value = rf2.mspHelper.readU8(buf) - 1
            data[31] = rf2.mspHelper.readU16(buf)
            data[32].value = rf2.mspHelper.readU8(buf)
            data[33] = rf2.mspHelper.readU8(buf)
            data[34].value = rf2.mspHelper.readU8(buf) - 1
            data[35].value = rf2.mspHelper.readU8(buf)
            data[36] = rf2.mspHelper.readU8(buf)
            data[37] = rf2.mspHelper.readU32(buf)
            data[38] = rf2.mspHelper.readU32(buf)
            data[39] = rf2.mspHelper.readU32(buf)
            data[40] = rf2.mspHelper.readU32(buf)
            data[41] = rf2.mspHelper.readU32(buf)

            -- Derived fields
            data.firmwareVersion = getFirmwareVersion(data[2], data[3])

            callback(callbackParam, data)
        end,

        
        --simulatorResponseBluejay022 = { 193, 0, 0, 22, 209, 255, 51, 0, 0, 5, 255, 9, 24, 1, 255, 85, 170, 255, 255, 255, 255, 255, 255, 4, 255, 255, 255, 255, 255, 40, 80, 4, 255, 2, 255, 255, 255, 0, 1, 255, 255, 0, 0, 2, 0, 170, 85, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
    }
    rf2.mspQueue:add(message)
end

local function setEscParameters(data)
    local message = {
        command = 218, -- MSP_SET_ESC_PARAMETERS
        retryDelay = 1,
        postSendDelay = 2,
        payload = {}
    }

    rf2.mspHelper.writeU8(message.payload, data[0])
    rf2.mspHelper.writeU8(message.payload, data[1])
    rf2.mspHelper.writeU8(message.payload, data[2])
    rf2.mspHelper.writeU8(message.payload, data[3])
    rf2.mspHelper.writeU8(message.payload, data[4])
    rf2.mspHelper.writeU8(message.payload, data[5])
    rf2.mspHelper.writeU8(message.payload, encodeStartupPowerMin(data[6].value))
    rf2.mspHelper.writeU8(message.payload, data[7])
    rf2.mspHelper.writeU8(message.payload, data[8])
    rf2.mspHelper.writeU8(message.payload, encodeStartupPowerMax(data[9].value))
    rf2.mspHelper.writeU8(message.payload, data[10])
    rf2.mspHelper.writeU8(message.payload, data[11].value)
    rf2.mspHelper.writeU8(message.payload, data[12])
    rf2.mspHelper.writeU8(message.payload, data[13].value + 1)
    rf2.mspHelper.writeU8(message.payload, data[14])
    rf2.mspHelper.writeU16(message.payload, data[15])
    rf2.mspHelper.writeU8(message.payload, data[16])
    rf2.mspHelper.writeU8(message.payload, data[17].value)
    rf2.mspHelper.writeU32(message.payload, data[18])
    rf2.mspHelper.writeU8(message.payload, data[19].value + 1)
    rf2.mspHelper.writeU32(message.payload, data[20])
    rf2.mspHelper.writeU8(message.payload, data[21])
    rf2.mspHelper.writeU8(message.payload, data[22].value)
    rf2.mspHelper.writeU8(message.payload, data[23].value)
    rf2.mspHelper.writeU8(message.payload, data[24].value + 1)
    rf2.mspHelper.writeU8(message.payload, data[25])
    rf2.mspHelper.writeU8(message.payload, data[26].value + 1)
    rf2.mspHelper.writeU16(message.payload, data[27])
    rf2.mspHelper.writeU8(message.payload, data[28])
    rf2.mspHelper.writeU8(message.payload, data[29].value)
    rf2.mspHelper.writeU8(message.payload, data[30].value)
    rf2.mspHelper.writeU16(message.payload, data[31])
    rf2.mspHelper.writeU8(message.payload, data[32].value)
    rf2.mspHelper.writeU8(message.payload, data[33])
    rf2.mspHelper.writeU8(message.payload, data[34].value + 1)
    rf2.mspHelper.writeU8(message.payload, data[35].value)
    rf2.mspHelper.writeU8(message.payload, data[36])
    rf2.mspHelper.writeU32(message.payload, data[37])
    rf2.mspHelper.writeU32(message.payload, data[38])
    rf2.mspHelper.writeU32(message.payload, data[39])
    rf2.mspHelper.writeU32(message.payload, data[40])
    rf2.mspHelper.writeU32(message.payload, data[41])

    rf2.mspQueue:add(message)
end

return {
    read = getEscParameters,
    write = setEscParameters,
    getDefaults = getDefaults
}









