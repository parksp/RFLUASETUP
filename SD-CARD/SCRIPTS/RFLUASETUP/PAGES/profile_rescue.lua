local template = rf2.executeScript(rf2.radio.template)
local margin = template.margin
local indent = template.indent
local lineSpacing = template.lineSpacing
local tableSpacing = template.tableSpacing
local sp = template.listSpacing.field
local yMinLim = rf2.radio.yMinLimit
local x = margin
local y = yMinLim - lineSpacing
local function incY(val) y = y + val return y end
local labels = {}
local fields = {}
local profileSwitcher = rf2.executeScript("PAGES/helpers/profileSwitcher.lua")
local rescueProfile = rf2.useApi("mspRescueProfile").getDefaults()

fields[#fields + 1] = { t = "Current PID profile", x = x,          y = incY(lineSpacing), sp = x + sp * 1.17, data = { value = nil, min = 0, max = 5, table = { [0] = "1", "2", "3", "4", "5", "6" } }, preEdit = profileSwitcher.startPidEditing, postEdit = profileSwitcher.endPidEditing }

incY(lineSpacing * 0.25)
--fields[#fields + 1] = { t = "Enable rescue",     x = x,          y = incY(lineSpacing), sp = x + sp, min = 0, max = 2,     vals = { 1 }, table = { [0] = "Off", "On", "Alt hold" } }
fields[#fields + 1] = { t = "Enable rescue",       x = x,          y = incY(lineSpacing), sp = x + sp, min = 0, data = rescueProfile.mode }

incY(lineSpacing * 0.25)
labels[#labels + 1] = { t = "Stage 1: Pull-Up",    x = x,          y = incY(lineSpacing) }
fields[#fields + 1] = { t = "Pull-up collective",  x = x + indent, y = incY(lineSpacing), sp = x + sp, data = rescueProfile.pull_up_collective }
fields[#fields + 1] = { t = "Pull-up time",        x = x + indent, y = incY(lineSpacing), sp = x + sp, data = rescueProfile.pull_up_time }
fields[#fields + 1] = { t = "Flip to upright",     x = x + indent, y = incY(lineSpacing), sp = x + sp, data = rescueProfile.flip_mode }
fields[#fields + 1] = { t = "Flip fail time",      x = x + indent, y = incY(lineSpacing), sp = x + sp, data = rescueProfile.flip_time }
fields[#fields + 1] = { t = "Flip gain",           x = x + indent, y = incY(lineSpacing), sp = x + sp, data = rescueProfile.flip_gain }

incY(lineSpacing * 0.25)
labels[#labels + 1] = { t = "Stage 2: Climb",      x = x,          y = incY(lineSpacing) }
fields[#fields + 1] = { t = "Climb collective",    x = x + indent, y = incY(lineSpacing), sp = x + sp, data = rescueProfile.climb_collective }
fields[#fields + 1] = { t = "Climb time",          x = x + indent, y = incY(lineSpacing), sp = x + sp, data = rescueProfile.climb_time }

incY(lineSpacing * 0.25)
labels[#labels + 1] = { t = "Stage 3: Hover",      x = x,          y = incY(lineSpacing) }
fields[#fields + 1] = { t = "Hover collective",    x = x + indent, y = incY(lineSpacing), sp = x + sp, data = rescueProfile.hover_collective }

incY(lineSpacing * 0.25)
fields[#fields + 1] = { t = "Exit time",           x = x,          y = incY(lineSpacing), sp = x + sp, data = rescueProfile.exit_time }
fields[#fields + 1] = { t = "Leveling gain",       x = x,          y = incY(lineSpacing), sp = x + sp, data = rescueProfile.level_gain }
fields[#fields + 1] = { t = "Max leveling rate",   x = x,          y = incY(lineSpacing), sp = x + sp, data = rescueProfile.max_setpoint_rate }
fields[#fields + 1] = { t = "Max leveling accel",  x = x,          y = incY(lineSpacing), sp = x + sp, data = rescueProfile.max_setpoint_accel }
--[[
labels[#labels + 1] = { t = "Altitude hold",       x = x,          y = incY(lineSpacing) }
fields[#fields + 1] = { t = "Hover altitude",      x = x + indent, y = incY(lineSpacing), sp = x + sp, data = rescueProfile.hover_altitude }
fields[#fields + 1] = { t = "P-gain",              x = x + indent, y = incY(lineSpacing), sp = x + sp, data = rescueProfile.alt_p_gain }
fields[#fields + 1] = { t = "I-gain",              x = x + indent, y = incY(lineSpacing), sp = x + sp, data = rescueProfile.alt_i_gain }
fields[#fields + 1] = { t = "D-gain",              x = x + indent, y = incY(lineSpacing), sp = x + sp, data = rescueProfile.alt_d_gain }
fields[#fields + 1] = { t = "Max collective",      x = x + indent, y = incY(lineSpacing), sp = x + sp, data = rescueProfile.max_collective }
--]]

local function receivedRescueProfile(page, _)
    rf2.onPageReady(page)
end

return {
    read = function(self)
        self.profileSwitcher.getStatus(self)
        rf2.useApi("mspRescueProfile").read(receivedRescueProfile, self, rescueProfile)
    end,
    write = function(self)
        if rescueProfile.mode.value then
            rf2.useApi("mspRescueProfile").write(rescueProfile)
            rf2.settingsSaved(true, false)
        end
    end,
    title       = "Profile - Rescue",
    labels      = labels,
    fields      = fields,
    profileSwitcher = profileSwitcher,

    timer = function(self)
        self.profileSwitcher.checkStatus(self)
    end
}
