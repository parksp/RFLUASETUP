local function getDefaults()
    local data = {}
    data[0] = { min = 0, max = 250 }
    data[1] = { min = 0, max = 250, scale = 10, unit = rf2.units.seconds }
    data[2] = { min = 0, max = 250, scale = 10, unit = rf2.units.seconds }
    data[3] = { min = 0, max = 250, scale = 10, unit = rf2.units.seconds }
    data[4] = { min = 0, max = 250, unit = rf2.units.degreesPerSecond }
    data[5] = { min = 0, max = 250, unit = rf2.units.degreesPerSecond }
    if rf2.apiVersion < 12.09 then
        data[6] = { min = 0, max = 1, table = { [0] = "OFF", "ON" } }
    end
    data[7] = { min = 0, max = 180, unit = rf2.units.degrees }
    data[8] = { min = 0, max = 180, unit = rf2.units.degrees }
    data[9] = { min = 0, max = 180, unit = rf2.units.degrees }
    data[10] = { min = 0, max = 250, unit = rf2.units.herz }
    data[11] = { min = 0, max = 250, unit = rf2.units.herz }
    data[12] = { min = 0, max = 250, unit = rf2.units.herz }
    data[13] = { min = 0, max = 250, unit = rf2.units.herz }
    data[14] = { min = 0, max = 250, unit = rf2.units.herz }
    data[15] = { min = 0, max = 250, unit = rf2.units.herz }
    data[16] = { min = 0, max = 2, table = { [0] = "OFF", "RP", "RPY" } }
    data[17] = { min = 1, max = 100, unit = rf2.units.herz }
    data[18] = { min = 1, max = 100, unit = rf2.units.herz }
    data[19] = { min = 1, max = 100, unit = rf2.units.herz }
    data[20] = { min = 25, max = 250 }
    data[21] = { min = 25, max = 250 }
    data[22] = { min = 0, max = 250, unit = rf2.units.herz }
    data[23] = { min = 0, max = 250 }
    data[24] = { min = 0, max = 250 }
    if rf2.apiVersion < 12.08 then
        data[25] = { min = 0, max = 250 }
        data[26] = { min = 0, max = 250 }
    end
    data[27] = { min = 0, max = 250 }
    data[28] = { min = 25, max = 255 }
    data[29] = { min = 10, max = 90, unit = rf2.units.degrees }
    data[30] = { min = 0, max = 200 }
    data[31] = { min = 0, max = 250 }
    data[32] = { min = 10, max = 80, unit = rf2.units.degrees }
    data[33] =  { min = 0, max = 250 }
    data[34] =  { min = 0, max = 200, unit = rf2.units.percentage }
    data[35] =  { min = 1, max = 250, scale = 10, unit = rf2.units.herz }
    data[36] = { min = 0, max = 180, unit = rf2.units.degrees }
    data[37] = { min = 0, max = 180, unit = rf2.units.degrees }
    data[38] = { min = 0, max = 250, unit = rf2.units.herz }
    data[39] = { min = 0, max = 250, unit = rf2.units.herz }
    data[40] = { min = 0, max = 250, unit = rf2.units.herz }
    if rf2.apiVersion >= 12.08 then
        data[41] = { min = 0, max = 250 }
        data[42] = { min = 0, max = 250, scale = 10, unit = rf2.units.herz }
    end
    return data
end

local function getPidProfile(callback, callbackParam, data)
    data = data or getDefaults()
    local message = {
        command = 94, -- MSP_PID_PROFILE
        processReply = function(self, buf)
            data[0].value = rf2.mspHelper.readU8(buf)
            data[1].value = rf2.mspHelper.readU8(buf)
            data[2].value = rf2.mspHelper.readU8(buf)
            data[3].value = rf2.mspHelper.readU8(buf)
            data[4].value = rf2.mspHelper.readU8(buf)
            data[5].value = rf2.mspHelper.readU8(buf)
            if rf2.apiVersion < 12.09 then
                data[6].value = rf2.mspHelper.readU8(buf)
            else
                buf.offset = buf.offset + 1
            end
            data[7].value = rf2.mspHelper.readU8(buf)
            data[8].value = rf2.mspHelper.readU8(buf)
            data[9].value = rf2.mspHelper.readU8(buf)
            data[10].value = rf2.mspHelper.readU8(buf)
            data[11].value = rf2.mspHelper.readU8(buf)
            data[12].value = rf2.mspHelper.readU8(buf)
            data[13].value = rf2.mspHelper.readU8(buf)
            data[14].value = rf2.mspHelper.readU8(buf)
            data[15].value = rf2.mspHelper.readU8(buf)
            data[16].value = rf2.mspHelper.readU8(buf)
            data[17].value = rf2.mspHelper.readU8(buf)
            data[18].value = rf2.mspHelper.readU8(buf)
            data[19].value = rf2.mspHelper.readU8(buf)
            data[20].value = rf2.mspHelper.readU8(buf)
            data[21].value = rf2.mspHelper.readU8(buf)
            data[22].value = rf2.mspHelper.readU8(buf)
            data[23].value = rf2.mspHelper.readU8(buf)
            data[24].value = rf2.mspHelper.readU8(buf)
            if rf2.apiVersion < 12.08 then
                data[25].value = rf2.mspHelper.readU8(buf)
                data[26].value = rf2.mspHelper.readU8(buf)
            else
                buf.offset = buf.offset + 2
            end
            data[27].value = rf2.mspHelper.readU8(buf)
            data[28].value = rf2.mspHelper.readU8(buf)
            data[29].value = rf2.mspHelper.readU8(buf)
            data[30].value = rf2.mspHelper.readU8(buf)
            data[31].value = rf2.mspHelper.readU8(buf)
            data[32].value = rf2.mspHelper.readU8(buf)
            data[33].value =  rf2.mspHelper.readU8(buf)
            data[34].value =  rf2.mspHelper.readU8(buf)
            data[35].value =  rf2.mspHelper.readU8(buf)
            data[36].value = rf2.mspHelper.readU8(buf)
            data[37].value = rf2.mspHelper.readU8(buf)
            data[38].value = rf2.mspHelper.readU8(buf)
            data[39].value = rf2.mspHelper.readU8(buf)
            data[40].value = rf2.mspHelper.readU8(buf)
            if rf2.apiVersion >= 12.08 then
                data[41].value = rf2.mspHelper.readU8(buf)
                data[42].value = rf2.mspHelper.readU8(buf)
            end
            callback(callbackParam, data)
        end,
        
    }
    rf2.mspQueue:add(message)
end

local function setPidProfile(data)
    local message = {
        command = 95, -- MSP_SET_PID_PROFILE
        payload = {},
        
    }
    rf2.mspHelper.writeU8(message.payload, data[0].value)
    rf2.mspHelper.writeU8(message.payload, data[1].value)
    rf2.mspHelper.writeU8(message.payload, data[2].value)
    rf2.mspHelper.writeU8(message.payload, data[3].value)
    rf2.mspHelper.writeU8(message.payload, data[4].value)
    rf2.mspHelper.writeU8(message.payload, data[5].value)
    if rf2.apiVersion < 12.09 then
        rf2.mspHelper.writeU8(message.payload, data[6].value)
    else
        rf2.mspHelper.writeU8(message.payload, 0)
    end
    rf2.mspHelper.writeU8(message.payload, data[7].value)
    rf2.mspHelper.writeU8(message.payload, data[8].value)
    rf2.mspHelper.writeU8(message.payload, data[9].value)
    rf2.mspHelper.writeU8(message.payload, data[10].value)
    rf2.mspHelper.writeU8(message.payload, data[11].value)
    rf2.mspHelper.writeU8(message.payload, data[12].value)
    rf2.mspHelper.writeU8(message.payload, data[13].value)
    rf2.mspHelper.writeU8(message.payload, data[14].value)
    rf2.mspHelper.writeU8(message.payload, data[15].value)
    rf2.mspHelper.writeU8(message.payload, data[16].value)
    rf2.mspHelper.writeU8(message.payload, data[17].value)
    rf2.mspHelper.writeU8(message.payload, data[18].value)
    rf2.mspHelper.writeU8(message.payload, data[19].value)
    rf2.mspHelper.writeU8(message.payload, data[20].value)
    rf2.mspHelper.writeU8(message.payload, data[21].value)
    rf2.mspHelper.writeU8(message.payload, data[22].value)
    rf2.mspHelper.writeU8(message.payload, data[23].value)
    rf2.mspHelper.writeU8(message.payload, data[24].value)
    if rf2.apiVersion < 12.08 then
        rf2.mspHelper.writeU8(message.payload, data[25].value)
        rf2.mspHelper.writeU8(message.payload, data[26].value)
    else
        rf2.mspHelper.writeU8(message.payload, 0)
        rf2.mspHelper.writeU8(message.payload, 0)
    end
    rf2.mspHelper.writeU8(message.payload, data[27].value)
    rf2.mspHelper.writeU8(message.payload, data[28].value)
    rf2.mspHelper.writeU8(message.payload, data[29].value)
    rf2.mspHelper.writeU8(message.payload, data[30].value)
    rf2.mspHelper.writeU8(message.payload, data[31].value)
    rf2.mspHelper.writeU8(message.payload, data[32].value)
    rf2.mspHelper.writeU8(message.payload, data[33].value)
    rf2.mspHelper.writeU8(message.payload, data[34].value)
    rf2.mspHelper.writeU8(message.payload, data[35].value)
    rf2.mspHelper.writeU8(message.payload, data[36].value)
    rf2.mspHelper.writeU8(message.payload, data[37].value)
    rf2.mspHelper.writeU8(message.payload, data[38].value)
    rf2.mspHelper.writeU8(message.payload, data[39].value)
    rf2.mspHelper.writeU8(message.payload, data[40].value)
    if rf2.apiVersion >= 12.08 then
        rf2.mspHelper.writeU8(message.payload, data[41].value)
        rf2.mspHelper.writeU8(message.payload, data[42].value)
    end
    rf2.mspQueue:add(message)
end

return {
    read = getPidProfile,
    write = setPidProfile,
    getDefaults = getDefaults
}
