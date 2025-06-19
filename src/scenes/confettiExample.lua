local BaseScene = require("scenes.baseScene")

-- Create a new scene object, inheriting from BaseScene
local ConfettiScene = BaseScene:new()
ConfettiScene.__index = ConfettiScene -- For proper method lookup if methods are added after new()

-- Confetti particle class
local Confetti = {}
Confetti.__index = Confetti

function Confetti:new(x, y, vx, vy, color, shape)
    local obj = {
        x = x,
        y = y,
        vx = vx,       -- velocity x
        vy = vy,       -- velocity y
        color = color,
        shape = shape, -- "rectangle", "circle", "triangle"
        rotation = math.random() * math.pi * 2,
        rotationSpeed = (math.random() - 0.5) * 10,
        size = math.random(4, 12),
        gravity = 300,
        life = 1.0,
        fadeSpeed = 0.3,
        wind = (math.random() - 0.5) * 50
    }
    setmetatable(obj, Confetti)
    return obj
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
end

-- Called once when the scene is first loaded.
function ConfettiScene:load()
    self.confetti = {}
    self.colors = {
        { 1,   0.2, 0.2 }, -- Red
        { 0.2, 1,   0.2 }, -- Green
        { 0.2, 0.2, 1 },   -- Blue
        { 1,   1,   0.2 }, -- Yellow
        { 1,   0.2, 1 },   -- Magenta
        { 0.2, 1,   1 },   -- Cyan
        { 1,   0.6, 0.2 }, -- Orange
        { 0.6, 0.2, 1 },   -- Purple
    }
    self.shapes = { "rectangle", "circle", "triangle" }

    self.titleFont = love.graphics.newFont(32)
    self.instructionFont = love.graphics.newFont(18)
end

function ConfettiScene:shootConfetti(fromLeft)
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    -- Determine cannon position
    local margin = 15
    local cannonX = fromLeft and margin or (screenWidth - margin)
    local cannonY = screenHeight - margin

    -- Create multiple confetti particles
    local minConfettis = 25
    local maxConfettis = 75
    for i = 1, math.random(minConfettis, maxConfettis) do
        local color = self.colors[math.random(#self.colors)]
        local shape = self.shapes[math.random(#self.shapes)]

        -- Calculate launch velocity
        local minAngle = 30
        local maxAngle = 60
        local angle = fromLeft and math.random(minAngle, maxAngle) or math.random(minAngle, maxAngle)
        angle = math.rad(angle)

        local minSpeed = 200
        local maxSpeed = 500
        local speed = math.random(minSpeed, maxSpeed)
        local vx = math.cos(angle) * speed
        local vy = -math.sin(angle) * speed

        -- Adjust direction based on cannon side
        if not fromLeft then
            vx = -vx
        end

        -- Add some randomness
        vx = vx + (math.random() - 0.5) * 100
        vy = vy + (math.random() - 0.5) * 100

        local confettiPiece = Confetti:new(cannonX, cannonY, vx, vy, color, shape)
        table.insert(self.confetti, confettiPiece)
    end
end

function ConfettiScene:update(dt)
    -- Update all confetti particles
    for i = #self.confetti, 1, -1 do
        local piece = self.confetti[i]
        if not piece:update(dt) then
            table.remove(self.confetti, i)
        end
    end
end

-- Called every frame to draw the scene.
function ConfettiScene:draw()
    -- Draw confetti count
    local countText = "Active confetti: " .. #self.confetti
    love.graphics.print(countText, 20, 20)

    -- Draw all confetti
    for _, piece in ipairs(self.confetti) do
        piece:draw()
    end

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

-- Example of overriding a specific input callback
function ConfettiScene:keypressed(key, scancode, isrepeat)
    if key == "space" then
        -- Shoot confetti from both corners
        self:shootConfetti(true)  -- Left cannon
        self:shootConfetti(false) -- Right cannon
    elseif key == "c" then
        -- Clear all confetti
        self.confetti = {}
    elseif key == "escape" then
        -- Switch back to main scene if needed
        if SCENE_MANAGER then
            SCENE_MANAGER:switchTo("InitialScene")
        end
    end
end

function ConfettiScene:keyreleased(key, scancode)
end

-- Return the scene object so it can be registered by the SceneManager
return ConfettiScene
