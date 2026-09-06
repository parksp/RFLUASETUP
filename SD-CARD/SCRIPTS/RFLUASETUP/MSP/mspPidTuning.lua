local function getDefaults()
    local defaults = {}
    defaults[0] = { min = 0, max = 1000 }
    defaults[1] = { min = 0, max = 1000 }
    defaults[2] = { min = 0, max = 1000 }
    defaults[3] = { min = 0, max = 1000 }
    defaults[4] = { min = 0, max = 1000 }
    defaults[5] = { min = 0, max = 1000 }
    defaults[6] = { min = 0, max = 1000 }
    defaults[7] = { min = 0, max = 1000 }
    defaults[8] = { min = 0, max = 1000 }
    defaults[9] = { min = 0, max = 1000 }
    defaults[10] = { min = 0, max = 1000 }
    defaults[11] = { min = 0, max = 1000 }
    defaults[12] = { min = 0, max = 1000 }
    defaults[13] = { min = 0, max = 1000 }
    defaults[14] = { min = 0, max = 1000 }
    defaults[15] = { min = 0, max = 1000 }
    defaults[16] = { min = 0, max = 1000 }
    return defaults
end

local function getPidTuning(callback, callbackParam, data)
    data = data or getDefaults()
    local message = {
        command = 112, -- MSP_PID_TUNING
        processReply = function(self, buf)
            data[0].value = rf2.mspHelper.readU16(buf)
            data[1].value = rf2.mspHelper.readU16(buf)
            data[2].value = rf2.mspHelper.readU16(buf)
            data[3].value = rf2.mspHelper.readU16(buf)
            data[4].value = rf2.mspHelper.readU16(buf)
            data[5].value = rf2.mspHelper.readU16(buf)
            data[6].value = rf2.mspHelper.readU16(buf)
            data[7].value = rf2.mspHelper.readU16(buf)
            data[8].value = rf2.mspHelper.readU16(buf)
            data[9].value = rf2.mspHelper.readU16(buf)
            data[10].value = rf2.mspHelper.readU16(buf)
            data[11].value = rf2.mspHelper.readU16(buf)
            data[12].value = rf2.mspHelper.readU16(buf)
            data[13].value = rf2.mspHelper.readU16(buf)
            data[14].value = rf2.mspHelper.readU16(buf)
            data[15].value = rf2.mspHelper.readU16(buf)
            data[16].value = rf2.mspHelper.readU16(buf)
            callback(callbackParam, data)
        end,
        
    }
    rf2.mspQueue:add(message)
end

local function setPidTuning(data)
    local message = {
        command = 202, -- MSP_SET_PID_TUNING
        payload = {},
        
    }
    rf2.mspHelper.writeU16(message.payload, data[0].value)
    rf2.mspHelper.writeU16(message.payload, data[1].value)
    rf2.mspHelper.writeU16(message.payload, data[2].value)
    rf2.mspHelper.writeU16(message.payload, data[3].value)
    rf2.mspHelper.writeU16(message.payload, data[4].value)
    rf2.mspHelper.writeU16(message.payload, data[5].value)
    rf2.mspHelper.writeU16(message.payload, data[6].value)
    rf2.mspHelper.writeU16(message.payload, data[7].value)
    rf2.mspHelper.writeU16(message.payload, data[8].value)
    rf2.mspHelper.writeU16(message.payload, data[9].value)
    rf2.mspHelper.writeU16(message.payload, data[10].value)
    rf2.mspHelper.writeU16(message.payload, data[11].value)
    rf2.mspHelper.writeU16(message.payload, data[12].value)
    rf2.mspHelper.writeU16(message.payload, data[13].value)
    rf2.mspHelper.writeU16(message.payload, data[14].value)
    rf2.mspHelper.writeU16(message.payload, data[15].value)
    rf2.mspHelper.writeU16(message.payload, data[16].value)
    rf2.mspQueue:add(message)
end

return {
    read = getPidTuning,
    write = setPidTuning,
    getDefaults = getDefaults
}
