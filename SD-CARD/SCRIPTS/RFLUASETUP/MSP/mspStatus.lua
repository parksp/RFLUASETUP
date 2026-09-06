local function getStatus(callback, callbackParam)
    local message = {
        command = 101, -- MSP_STATUS
        processReply = function(self, buf)
            local status = {}
            --status.pidCycleTime = rf2.mspHelper.readU16(buf)
            --status.gyroCycleTime = rf2.mspHelper.readU16(buf)
            buf.offset = 5
            status.activeSensors = rf2.mspHelper.readU16(buf)
            buf.offset = 7
            status.flightModeFlags = rf2.mspHelper.readU32(buf)
            buf.offset = 12
            status.realTimeLoad = rf2.mspHelper.readU16(buf)
            --rf2.print("Real-time load: "..tostring(status.realTimeLoad))
            status.cpuLoad = rf2.mspHelper.readU16(buf)
            --rf2.print("CPU load: "..tostring(status.cpuLoad))
            buf.offset = 18
            status.armingDisableFlags = rf2.mspHelper.readU32(buf)
            --rf2.print("Arming disable flags: "..tostring(status.armingDisableFlags))
            buf.offset = 24
            status.profile = rf2.mspHelper.readU8(buf)
            --rf2.print("Profile: "..tostring(status.profile))
            --status.numProfiles = rf2.mspHelper.readU8(buf)
            buf.offset = 26
            status.rateProfile = rf2.mspHelper.readU8(buf)
            --status.numRateProfiles = rf2.mspHelper.readU8(buf)
            buf.offset = 28
            status.motorCount = rf2.mspHelper.readU8(buf)
            --rf2.print("Number of motors: "..tostring(status.motorCount))
            --status.servoCount = rf2.mspHelper.readU8(buf)
            --rf2.print("Number of servos: "..tostring(status.servoCount))
            callback(callbackParam, status)
        end,
        
    }

    rf2.mspQueue:add(message)
end

return {
    getStatus = getStatus
}
