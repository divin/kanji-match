local Confetti = require("objects.confetti")

local ConfettiCannon = {}
ConfettiCannon.__index = ConfettiCannon

-- Constructor
function ConfettiCannon:new(minConfettis, maxConfettis, minSpeed, maxSpeed, margin, randomnessRange)
    local instance = setmetatable({}, ConfettiCannon)

    -- Confetti particles storage
    instance.confetti = {}

    -- Confetti colors
    instance.colors = {
        { 1,   0.2, 0.2 }, -- Red
        { 0.2, 1,   0.2 }, -- Green
        { 0.2, 0.2, 1 },   -- Blue
        { 1,   1,   0.2 }, -- Yellow
        { 1,   0.2, 1 },   -- Magenta
        { 0.2, 1,   1 },   -- Cyan
        { 1,   0.6, 0.2 }, -- Orange
        { 0.6, 0.2, 1 },   -- Purple
    }

    -- Confetti shapes
    instance.shapes = { "rectangle", "circle", "triangle" }

    -- Configuration parameters as direct attributes
    instance.minConfettis = minConfettis or 25
    instance.maxConfettis = maxConfettis or 75
    instance.minSpeed = minSpeed or 200
    instance.maxSpeed = maxSpeed or 500
    instance.margin = margin or 0
    instance.randomnessRange = randomnessRange or 100

    return instance
end

-- Shoot confetti from a specific direction
function ConfettiCannon:shoot(direction)
    assert(type(direction) == "string", "Direction must be a string")

    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    -- Determine cannon position and angle range
    local x, y, minAngle, maxAngle = self:_getCannonParameters(direction, screenWidth, screenHeight)

    -- Create multiple confetti particles
    local confettiCount = math.random(self.minConfettis, self.maxConfettis)
    for i = 1, confettiCount do
        local color = self.colors[math.random(#self.colors)]
        local shape = self.shapes[math.random(#self.shapes)]

        -- Calculate launch velocity
        local angle = math.random(minAngle, maxAngle)
        angle = math.rad(angle)

        local speed = math.random(self.minSpeed, self.maxSpeed)
        local vx = math.cos(angle) * speed
        local vy = -math.sin(angle) * speed

        -- Adjust direction based on cannon side
        if direction == "upper-right" or direction == "lower-right" then
            vx = -vx
        end

        -- Add some randomness
        vx = vx + (math.random() - 0.5) * self.randomnessRange
        vy = vy + (math.random() - 0.5) * self.randomnessRange

        local confettiPiece = Confetti:new(x, y, vx, vy, color, shape)
        table.insert(self.confetti, confettiPiece)
    end
end

-- Shoot confetti celebration (from all corners)
function ConfettiCannon:celebrate()
    self:shoot("upper-left")
    self:shoot("upper-right")
    self:shoot("lower-left")
    self:shoot("lower-right")
end

-- Update all confetti particles
function ConfettiCannon:update(dt)
    assert(type(dt) == "number", "Delta time must be a number")

    -- Update all confetti particles and remove dead ones
    for i = #self.confetti, 1, -1 do
        local piece = self.confetti[i]
        if not piece:update(dt) then
            table.remove(self.confetti, i)
        end
    end
end

-- Draw all confetti particles
function ConfettiCannon:draw()
    for _, piece in ipairs(self.confetti) do
        piece:draw()
    end
end

-- Clear all confetti particles
function ConfettiCannon:clear()
    self.confetti = {}
end

-- Get the number of active confetti particles
function ConfettiCannon:getCount()
    return #self.confetti
end

-- Private method to get cannon parameters based on direction
function ConfettiCannon:_getCannonParameters(direction, screenWidth, screenHeight)
    local x = self.margin
    local y = self.margin
    local minAngle = 15
    local maxAngle = 60

    if direction == "upper-left" then
        x = self.margin
        y = self.margin
        minAngle = 315
        maxAngle = 360
    elseif direction == "upper-right" then
        x = screenWidth - self.margin
        y = self.margin
        minAngle = 315
        maxAngle = 360
    elseif direction == "lower-right" then
        x = screenWidth - self.margin
        y = screenHeight - self.margin
        minAngle = 15
        maxAngle = 60
    elseif direction == "lower-left" then
        x = self.margin
        y = screenHeight - self.margin
        minAngle = 15
        maxAngle = 60
    else
        error("Invalid direction: " ..
            tostring(direction) .. ". Must be one of: upper-left, upper-right, lower-left, lower-right")
    end

    return x, y, minAngle, maxAngle
end

return ConfettiCannon
