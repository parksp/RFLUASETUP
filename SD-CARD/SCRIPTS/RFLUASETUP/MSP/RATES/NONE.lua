local function setRateDefaults(data)
    data[0] = { value = 0, min = 1, max = 0 }
    data[1] = { value = 0, min = 0, max = 0 }
    data[2] = { value = 0, min = 0, max = 0 }
    data[3] = { value = 0 , min = 1, max = 0 }
    data[4] = { value = 0, min = 0, max = 0 }
    data[5] = { value = 0, min = 0, max = 0 }
    data[6] = { value = 0, min = 1, max = 0 }
    data[7] = { value = 0, min = 0, max = 0 }
    data[8] = { value = 0, min = 0, max = 0 }
    data[9] = { value = 0, min = 0, max = 0 }
    data[10] = { value = 0, min = 0, max = 0 }
    data[11] = { value = 0, min = 0, max = 0 }

    data.columnHeaders = { "RC", "Rate", "", "Rate", "RC", "Expo" }

    return data
end

return setRateDefaults
