local function setRateDefaults(data)
    data[0] = { value = 50, min = 2, max = 200, scale = 0.2 }
    data[1] = { value = 40, min = 0, max = 100, scale = 1 }
    data[2] = { value = 12, min = 0, max = 127, scale = 1 }
    data[3] = { value = 50 , min = 2, max = 200, scale = 0.2 }
    data[4] = { value = 40, min = 0, max = 100, scale = 1 }
    data[5] = { value = 12, min = 0, max = 127, scale = 1 }
    data[6] = { value = 80, min = 2, max = 200, scale = 0.2 }
    data[7] = { value = 50, min = 0, max = 100, scale = 1 }
    data[8] = { value = 12, min = 0, max = 127, scale = 1 }
    data[9] = { value = 100, min = 0, max = 200, scale = 8, mult = 2 }
    data[10] = { value = 0, min = 0, max = 100, scale = 1 }
    data[11] = { value = 12, min = 0, max = 127, scale = 1 }

    data.columnHeaders = { "", "Rate", "", "Shape", "", "Expo" }

    return data
end

return setRateDefaults
