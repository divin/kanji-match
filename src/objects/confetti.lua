local Confetti = {}
Confetti.__index = Confetti

function Confetti:new(x, y, vx, vy, color, shape)
    local instance = setmetatable({}, Confetti)
    instance.x = x or 0
    instance.y = y or 0
    instance.vx = vx or 0                 -- velocity x
    instance.vy = vy or 0                 -- velocity y
    instance.color = color or { 1, 1, 1 } -- Default to white if no color is provided
    instance.shape = shape or "rectangle" -- Default shape is rectangle
    instance.rotation = math.random() * math.pi * 2
    instance.rotationSpeed = (math.random() - 0.5) * 10
    instance.size = math.random(4, 12)
    instance.gravity = 300
    instance.life = 1.0
    instance.fadeSpeed = 0.5
    instance.wind = (math.random() - 0.5) * 50
    return instance
end

function Confetti:update(dt)
    -- Apply physics
    self.vy = self.vy + self.gravity * dt
    self.vx = self.vx + self.wind * dt * 0.1

    -- Update position
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt

    -- Update rotation
    self.rotation = self.rotation + self.rotationSpeed * dt

    -- Fade out over time
    self.life = self.life - self.fadeSpeed * dt

    -- Add some air resistance
    self.vx = self.vx * (1 - dt * 0.5)

    return self.life > 0 and self.y < love.graphics.getHeight() + 50
end

function Confetti:draw()
    if self.life <= 0 then return end

    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.rotation)

    -- Set color with alpha based on life
    local r, g, b = unpack(self.color)
    love.graphics.setColor(r, g, b, self.life)

    if self.shape == "rectangle" then
        love.graphics.rectangle("fill", -self.size / 2, -self.size / 2, self.size, self.size)
    elseif self.shape == "circle" then
        love.graphics.circle("fill", 0, 0, self.size / 2)
    elseif self.shape == "triangle" then
        love.graphics.polygon("fill",
            0, -self.size / 2,
            -self.size / 2, self.size / 2,
            self.size / 2, self.size / 2
        )
    end

    love.graphics.pop()

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

return Confetti
