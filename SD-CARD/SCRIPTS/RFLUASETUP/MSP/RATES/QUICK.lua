local function setRateDefaults(data)
    data[0] =       { value = 180, min = 1, max = 255, scale = 100 }
    data[1] =        { value = 0,   min = 0, max = 100, scale = 100 }
    data[2] =         { value = 36,  min = 0, max = 100, scale = 0.1 }
    data[3] =      { value = 180, min = 1, max = 255, scale = 100 }
    data[4] =       { value = 0,   min = 0, max = 100, scale = 100 }
    data[5] =        { value = 36,  min = 0, max = 100, scale = 0.1 }
    data[6] =        { value = 180, min = 1, max = 255, scale = 100 }
    data[7] =         { value = 0,   min = 0, max = 100, scale = 100 }
    data[8] =          { value = 36,  min = 0, max = 100, scale = 0.1 }
    data[9] = { value = 250, min = 0, max = 255, scale = 100 }
    data[10] =  { value = 0,   min = 0, max = 100, scale = 100 }
    data[11] =   { value = 104, min = 0, max = 100, scale = 0.208 }

    data.columnHeaders = { "RC", "Rate", "Max", "Rate", "", "Expo" }

    return data
end

return setRateDefaults
