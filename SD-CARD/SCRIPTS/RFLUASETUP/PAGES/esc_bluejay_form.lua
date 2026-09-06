local template = rf2.executeScript(rf2.radio.template)
local indent = template.indent
local lineSpacing = template.lineSpacing
local sp = template.listSpacing.field
local yMinLim = rf2.radio.yMinLimit
local x = template.margin
local y = yMinLim - lineSpacing
template = nil

local labels = {}
local fields = {}

local function incY(val) y = y + val return y end

local function addField(text, data, w)
    if not data.hidden then
        fields[#fields + 1] = { t = text, x = x, y = incY(lineSpacing), sp = x + sp, w = w, data = data }
    end
end

local function buildForm(escParameters, escCount, selectedEsc, endEscEditing)
    y = yMinLim - lineSpacing

    if not escParameters then
        labels[1] = { t = "ESC not ready, waiting...", x = x, y = incY(lineSpacing) }
        fields[1] = { t = nil, x = 0, y = 0, data = nil, readOnly = true } -- dummy field since ui.lua expects at least one field
        return labels, fields
    end

    labels[1] = {
        t = escParameters.firmwareVersion,
        x = x,
        y = incY(lineSpacing)
    }

    fields[1] = {
        t = "ESC",
        x = x + indent,
        y = incY(lineSpacing),
        sp = x + sp,
        data = { value = selectedEsc, min = 0, max = escCount - 1, table = { [0] = "1", "2", "3", "4" } },
        postEdit = endEscEditing
    }

    labels[#labels + 1] = { t = "Basic", x = x, y = incY(lineSpacing) }
    addField("Min startup power", escParameters[6])
    addField("Max startup power", escParameters[9])
    addField("Temp protection", escParameters[29])
    addField("Motor timing", escParameters[19])
    addField("Demag compensation", escParameters[26])
    addField("RPM power prot", escParameters[11])
    addField("Beep strength", escParameters[22])
    addField("Beacon strength", escParameters[23])
    addField("Beacon delay", escParameters[24], 150)
    addField("Brake on stop", escParameters[32])
    addField("Max breaking strength", escParameters[17])
    addField("ESC power rating", escParameters[34])
    -- addField("Force EDT arm", escParameters[35]) -- different values between Bluejay 0.21 and 0.22
    addField("Motor direction", escParameters[13], 150)
    return labels, fields
end

return buildForm(...)
