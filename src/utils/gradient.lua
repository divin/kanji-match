local function createGradientMesh(width, height, topColor, bottomColor)
    local vertices = {
        { 0,     0,      0, 0, topColor[1],    topColor[2],    topColor[3],    topColor[4] or 1 },
        { width, 0,      1, 0, topColor[1],    topColor[2],    topColor[3],    topColor[4] or 1 },
        { width, height, 1, 1, bottomColor[1], bottomColor[2], bottomColor[3], bottomColor[4] or 1 },
        { 0,     height, 0, 1, bottomColor[1], bottomColor[2], bottomColor[3], bottomColor[4] or 1 }
    }

    local mesh = love.graphics.newMesh(vertices, "fan")
    return mesh
end

return createGradientMesh
