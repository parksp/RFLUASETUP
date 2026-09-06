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
    addField("Motor direction", escParameters[20])
    addField("Motor KV", escParameters[29])
    addField("Motor poles", escParameters[30])
    addField("Startup power", escParameters[28])
    addField("PWM frequency", escParameters[27])
    addField("Compl. PWM", escParameters[23])
    addField("Brake on stop", escParameters[31])
    addField("Brake strength", escParameters[44])
    addField("Running brake", escParameters[45])
    addField("Beep volume", escParameters[33])

    labels[#labels + 1] = { t = "Advanced", x = x, y = incY(lineSpacing * 1.5) }
    addField("Timing", escParameters[26])
    addField("Stuck rotor prot.", escParameters[25])
    addField("Sinusoidal startup", escParameters[22])
    addField("Sine mode power", escParameters[48])
    addField("Sine mode range", escParameters[43])
    addField("Bidir mode", escParameters[21])
    addField("Protocol", escParameters[49], 135)
    addField("Var. PWM freq", escParameters[24])
    addField("Stall protection", escParameters[32])
    addField("Telemetry interval", escParameters[34])
    addField("Auto advance", escParameters[50])

    labels[#labels + 1] = { t = "Limits", x = x, y = incY(lineSpacing * 1.5) }
    addField("Temperature limit", escParameters[46])
    addField("Current limit", escParameters[47])
    addField("Low volt. cutoff", escParameters[39])
    addField("Low volt. treshold", escParameters[40])
    addField("Servo low treshold", escParameters[35])
    addField("Servo high treshold", escParameters[36])
    addField("Servo neutral", escParameters[37])
    addField("Servo deadband", escParameters[38])
    addField("RC car reversing", escParameters[41])
    addField("Use Hall sensors", escParameters[42])

    return labels, fields
end

return buildForm(...)
