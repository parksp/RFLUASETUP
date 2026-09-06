local function setRateDefaults(data)
    data[0] = { value = 36, min = 1, max = 200, scale = 0.1 }
    data[1] = { value = 0, min = 0, max = 100 }
    data[2] = { value = 0, min = 0, max = 255 }
    data[3] = { value = 36, min = 1, max = 200, scale = 0.1 }
    data[4] = { value = 0, min = 0, max = 100 }
    data[5] = { value = 0, min = 0, max = 255 }
    data[6] = { value = 36, min = 1, max = 200, scale = 0.1 }
    data[7] = { value = 0, min = 0, max = 100 }
    data[8] = { value = 0, min = 0, max = 255 }
    data[9] = { value = 50, min = 1, max = 200, scale = 4 }
    data[10] = { value = 0, min = 0, max = 100 }
    data[11] = { value = 0, min = 0, max = 255 }

    data.columnHeaders = { "", "Rate", "", "Acro+", "", "Expo" }

    return data
end

return setRateDefaults
