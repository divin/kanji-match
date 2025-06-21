local color = {}

function color.rgb(r, g, b, a)
    a = a or 255
    return r / 255, g / 255, b / 255, a / 255
end

function color.rgbTable(r, g, b, a)
    a = a or 255
    return { r / 255, g / 255, b / 255, a / 255 }
end

return color
