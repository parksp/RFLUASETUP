local template = rf2.executeScript(rf2.radio.template)
local margin = template.margin
local indent = template.indent
local lineSpacing = template.lineSpacing
local tableSpacing = template.tableSpacing
local sp = template.listSpacing.field
template = nil
local yMinLim = rf2.radio.yMinLimit
local x = margin
local y = yMinLim - lineSpacing
local function incY(val) y = y + val return y end
local labels = {}
local fields = {}
local profileSwitcher = rf2.executeScript("PAGES/helpers/profileSwitcher.lua")
local pidProfile = rf2.useApi("mspPidProfile").getDefaults()
collectgarbage()

fields[#fields + 1] = { t = "Current PID profile",     x = x,          y = incY(lineSpacing), sp = x + sp * 1.17, data = { value = nil, min = 0, max = 5, table = { [0] = "1", "2", "3", "4", "5", "6" } }, preEdit = profileSwitcher.startPidEditing, postEdit = profileSwitcher.endPidEditing }

incY(lineSpacing * 0.25)
if rf2.apiVersion < 12.09 then
    fields[#fields + 1] = { t = "Piro compensation",   x = x,          y = incY(lineSpacing), sp = x + sp, data = pidProfile[6] }
end
fields[#fields + 1] = { t = "I-term relax type",       x = x,          y = incY(lineSpacing), sp = x + sp, data = pidProfile[16] }
fields[#fields + 1] = { t = "Cutoff point R",          x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile[17] }
fields[#fields + 1] = { t = "Cutoff point P",          x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile[18] }
fields[#fields + 1] = { t = "Cutoff point Y",          x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile[19] }
labels[#labels + 1] = { t = "Error Decay Ground",      x = x,          y = incY(lineSpacing) }
fields[#fields + 1] = { t = "Time",                    x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile[1] }
labels[#labels + 1] = { t = "Error Decay Cyclic",      x = x,          y = incY(lineSpacing) }
fields[#fields + 1] = { t = "Time",                    x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile[2] }
fields[#fields + 1] = { t = "Limit",                   x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile[4] }
labels[#labels + 1] = { t = "Error Decay Yaw",         x = x,          y = incY(lineSpacing) }
fields[#fields + 1] = { t = "Time",                    x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile[3] }
fields[#fields + 1] = { t = "Limit",                   x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile[5] }
labels[#labels + 1] = { t = "Error Limit",             x = x,          y = incY(lineSpacing) }
fields[#fields + 1] = { t = "Roll",                    x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile[7] }
fields[#fields + 1] = { t = "Pitch",                   x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile[8] }
fields[#fields + 1] = { t = "Yaw",                     x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile[9] }
labels[#labels + 1] = { t = "HSI Offset Limit",        x = x,          y = incY(lineSpacing) }
fields[#fields + 1] = { t = "Roll",                    x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile[36] }
fields[#fields + 1] = { t = "Pitch",                   x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile[37] }

incY(lineSpacing * 0.25)
labels[#labels + 1] = { t = "PID Controller",          x = x,          y = incY(lineSpacing) }
fields[#fields + 1] = { t = "R bandwidth",             x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile[10] }
fields[#fields + 1] = { t = "P bandwidth",             x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile[11] }
fields[#fields + 1] = { t = "Y bandwidth",             x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile[12] }
fields[#fields + 1] = { t = "R D-term cutoff",         x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile[13] }
fields[#fields + 1] = { t = "P D-term cutoff",         x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile[14] }
fields[#fields + 1] = { t = "Y D-term cutoff",         x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile[15] }
fields[#fields + 1] = { t = "R B-term cutoff",         x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile[38] }
fields[#fields + 1] = { t = "P B-term cutoff",         x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile[39] }
fields[#fields + 1] = { t = "Y B-term cutoff",         x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile[40] }

local function receivedPidProfile(page, _)
    rf2.onPageReady(page)
end

return {
    read = function(self)
        self.profileSwitcher.getStatus(self)
        rf2.useApi("mspPidProfile").read(receivedPidProfile, self, pidProfile)
    end,
    write = function(self)
        if pidProfile[16].value then
            rf2.useApi("mspPidProfile").write(pidProfile)
            rf2.settingsSaved(true, false)
        end
    end,
    title       = "PID Controller Settings",
    labels      = labels,
    fields      = fields,
    profileSwitcher = profileSwitcher,

    timer = function(self)
        self.profileSwitcher.checkStatus(self)
    end,
}
