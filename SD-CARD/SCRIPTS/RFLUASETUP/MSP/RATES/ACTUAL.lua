local function setRateDefaults(data)
    data[0] = { value = 36, min = 1, max = 200, scale = 0.1 }
    data[1] = { value = 0, min = 0, max = 100, scale = 100 }
    data[2] = { value = 36, min = 0, max = 200, scale = 0.1 }
    data[3] = { value = 36 , min = 1, max = 200, scale = 0.1 }
    data[4] = { value = 0, min = 0, max = 100, scale = 100 }
    data[5] = { value = 36, min = 0, max = 200, scale = 0.1 }
    data[6] = { value = 36, min = 1, max = 200, scale = 0.1 }
    data[7] = { value = 0, min = 0, max = 100, scale = 100 }
    data[8] = { value = 36, min = 0, max = 200, scale = 0.1 }
    data[9] = { value = 48, min = 0, max = 100, scale = 4 }
    data[10] = { value = 0, min = 0, max = 100, scale = 100 }
    data[11] = { value = 48, min = 0, max = 100, scale = 4 }

    data.columnHeaders = { (LCD_W < 320) and "Centr" or "Center", "Sens", "Max", "Rate", "", "Expo" }

    return data
end

return setRateDefaults
