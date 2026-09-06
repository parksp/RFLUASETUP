local function rateApiVersion()
    return rf2.apiVersion or 12.09
end

local function getDefaults()
    local defaults = {}
    defaults.rates_type = {}
    defaults[0] = {}
    defaults[1] = {}
    defaults[2] = {}

    defaults[3] = {}
    defaults[4] = {}
    defaults[5] = {}

    defaults[6] = {}
    defaults[7] = {}
    defaults[8] = {}

    defaults[9] = {}
    defaults[10] = {}
    defaults[11] = {}

    defaults[12] = { min = 0, max = 250 }
    defaults[13] = { min = 0, max = 50000, scale = 0.1 }
    defaults[14] = { min = 0, max = 250 }
    defaults[15] = { min = 0, max = 50000, scale = 0.1 }
    defaults[16] = { min = 0, max = 250 }
    defaults[17] = { min = 0, max = 50000, scale = 0.1 }
    defaults[18] = { min = 0, max = 250 }
    defaults[19] = { min = 0, max = 50000, scale = 0.1 }

    if rateApiVersion() >= 12.08 then
        defaults[20] = { min = 0, max = 250 }
        defaults[21] = { min = 0, max = 250, unit = rf2.units.herz }
        defaults[22] = { min = 0, max = 250 }
        defaults[23] = { min = 0, max = 250, unit = rf2.units.herz }
        defaults[24] = { min = 0, max = 250 }
        defaults[25] = { min = 0, max = 250, unit = rf2.units.herz }
        defaults[26] = { min = 0, max = 250 }
        defaults[27] = { min = 0, max = 250, unit = rf2.units.herz }
        defaults[28] = { min = 0, max = 250 }
        defaults[29] = { min = 0, max = 250 }
        defaults[30] = { min = 0, max = 250, scale = 10, unit = rf2.units.herz }
    end

    if rateApiVersion() >= 12.09 then
        defaults[31] = { min = 0, max = 250, unit = rf2.units.percentage }
        defaults[32] = { min = 0, max = 1, table = { [0] = "Off", "On" } }
    end

    defaults.columnHeaders = { "", "", "", "", "", "" }

    return defaults
end

local function getRateDefaults(data, rates_type)
    data.rates_type = { value = rates_type, min = 0, table = { [0] = "NONE", "BETAFL", "RACEFL", "KISS", "ACTUAL", "QUICK" } }
    if rateApiVersion() >= 12.09 then
        data.rates_type.table[#data.rates_type.table + 1] = "ROTORFL"
    end
    data.rates_type.max = #data.rates_type.table
    local rateName = data.rates_type.table[rates_type]
    --rf2.print("rateName: " .. rateName)
    local setRateDefaults = rf2.executeScript("MSP/RATES/" .. rateName)
    setRateDefaults(data)
    setRateDefaults = nil
    collectgarbage()
    return data
end

local function getRcTuning(callback, callbackParam, data)
    data = data or getDefaults()
    local message = {
        command = 111, -- MSP_RC_TUNING
        processReply = function(self, buf)
            local rates_type = rf2.mspHelper.readU8(buf)
            local data = getRateDefaults(data, rates_type)
            data.rates_type.value = rates_type
            data[0].value = rf2.mspHelper.readU8(buf)
            data[1].value = rf2.mspHelper.readU8(buf)
            data[2].value = rf2.mspHelper.readU8(buf)
            data[12].value = rf2.mspHelper.readU8(buf)
            data[13].value = rf2.mspHelper.readU16(buf)
            data[3].value = rf2.mspHelper.readU8(buf)
            data[4].value = rf2.mspHelper.readU8(buf)
            data[5].value = rf2.mspHelper.readU8(buf)
            data[14].value = rf2.mspHelper.readU8(buf)
            data[15].value = rf2.mspHelper.readU16(buf)
            data[6].value = rf2.mspHelper.readU8(buf)
            data[7].value = rf2.mspHelper.readU8(buf)
            data[8].value = rf2.mspHelper.readU8(buf)
            data[16].value = rf2.mspHelper.readU8(buf)
            data[17].value = rf2.mspHelper.readU16(buf)
            data[9].value = rf2.mspHelper.readU8(buf)
            data[10].value = rf2.mspHelper.readU8(buf)
            data[11].value = rf2.mspHelper.readU8(buf)
            data[18].value = rf2.mspHelper.readU8(buf)
            data[19].value = rf2.mspHelper.readU16(buf)
            if rateApiVersion() >= 12.08 then
                data[20].value = rf2.mspHelper.readU8(buf)
                data[21].value = rf2.mspHelper.readU8(buf)
                data[22].value = rf2.mspHelper.readU8(buf)
                data[23].value = rf2.mspHelper.readU8(buf)
                data[24].value = rf2.mspHelper.readU8(buf)
                data[25].value = rf2.mspHelper.readU8(buf)
                data[26].value = rf2.mspHelper.readU8(buf)
                data[27].value = rf2.mspHelper.readU8(buf)
                data[28].value = rf2.mspHelper.readU8(buf)
                data[29].value = rf2.mspHelper.readU8(buf)
                data[30].value = rf2.mspHelper.readU8(buf)
            end
            if rateApiVersion() >= 12.09 then
                data[31].value = rf2.mspHelper.readU8(buf)
                data[32].value = rf2.mspHelper.readU8(buf)
            end
            callback(callbackParam, data)
        end,
        
    }
    rf2.mspQueue:add(message)
end

local function setRcTuning(data)
    local message = {
        command = 204, -- MSP_SET_RC_TUNING
        payload = {},
        
    }
    rf2.mspHelper.writeU8(message.payload, data.rates_type.value)
    rf2.mspHelper.writeU8(message.payload, data[0].value)
    rf2.mspHelper.writeU8(message.payload, data[1].value)
    rf2.mspHelper.writeU8(message.payload, data[2].value)
    rf2.mspHelper.writeU8(message.payload, data[12].value)
    rf2.mspHelper.writeU16(message.payload, data[13].value)
    rf2.mspHelper.writeU8(message.payload, data[3].value)
    rf2.mspHelper.writeU8(message.payload, data[4].value)
    rf2.mspHelper.writeU8(message.payload, data[5].value)
    rf2.mspHelper.writeU8(message.payload, data[14].value)
    rf2.mspHelper.writeU16(message.payload, data[15].value)
    rf2.mspHelper.writeU8(message.payload, data[6].value)
    rf2.mspHelper.writeU8(message.payload, data[7].value)
    rf2.mspHelper.writeU8(message.payload, data[8].value)
    rf2.mspHelper.writeU8(message.payload, data[16].value)
    rf2.mspHelper.writeU16(message.payload, data[17].value)
    rf2.mspHelper.writeU8(message.payload, data[9].value)
    rf2.mspHelper.writeU8(message.payload, data[10].value)
    rf2.mspHelper.writeU8(message.payload, data[11].value)
    rf2.mspHelper.writeU8(message.payload, data[18].value)
    rf2.mspHelper.writeU16(message.payload, data[19].value)
    if rateApiVersion() >= 12.08 then
        rf2.mspHelper.writeU8(message.payload, data[20].value)
        rf2.mspHelper.writeU8(message.payload, data[21].value)
        rf2.mspHelper.writeU8(message.payload, data[22].value)
        rf2.mspHelper.writeU8(message.payload, data[23].value)
        rf2.mspHelper.writeU8(message.payload, data[24].value)
        rf2.mspHelper.writeU8(message.payload, data[25].value)
        rf2.mspHelper.writeU8(message.payload, data[26].value)
        rf2.mspHelper.writeU8(message.payload, data[27].value)
        rf2.mspHelper.writeU8(message.payload, data[28].value)
        rf2.mspHelper.writeU8(message.payload, data[29].value)
        rf2.mspHelper.writeU8(message.payload, data[30].value)
    end
    if rateApiVersion() >= 12.09 then
        rf2.mspHelper.writeU8(message.payload, data[31].value)
        rf2.mspHelper.writeU8(message.payload, data[32].value)
    end
    rf2.mspQueue:add(message)
end

return {
    read = getRcTuning,
    write = setRcTuning,
    getDefaults = getDefaults,
    getRateDefaults = getRateDefaults,
}
