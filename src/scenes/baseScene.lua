-- scenes/base_scene.lua

local BaseScene = {}
BaseScene.__index = BaseScene

function BaseScene:new()
    local instance = setmetatable({}, BaseScene)
    return instance
end

-- Called once when the scene is first loaded or created.
-- Use this for one-time setup, loading assets specific to this scene.
function BaseScene:load(...)
    -- print("BaseScene:load")
end

-- Called when the scene becomes the active scene.
-- `...` can be arguments passed from SceneManager:switchTo()
-- Use this for setup that needs to run every time the scene is entered.
function BaseScene:enter(...)
    -- print("BaseScene:enter")
end

-- Called when the scene is no longer the active scene.
-- Use this for cleanup before switching to another scene.
function BaseScene:leave()
    -- print("BaseScene:leave")
end

-- Called every frame by LÖVE.
-- `dt` is the time since the last update in seconds.
function BaseScene:update(dt)
    -- print("BaseScene:update", dt)
end

-- Called every frame by LÖVE, after update.
-- Use this for all drawing operations.
function BaseScene:draw()
    -- print("BaseScene:draw")
end

-- LÖVE input callback.
function BaseScene:keypressed(key, scancode, isrepeat)
    -- print("BaseScene:keypressed", key, scancode, isrepeat)
end

-- LÖVE input callback.
function BaseScene:keyreleased(key, scancode)
    -- print("BaseScene:keyreleased", key, scancode)
end

-- LÖVE input callback.
function BaseScene:mousepressed(x, y, button, istouch, presses)
    -- print("BaseScene:mousepressed", x, y, button, istouch, presses)
end

-- LÖVE input callback.
function BaseScene:mousereleased(x, y, button, istouch, presses)
    -- print("BaseScene:mousereleased", x, y, button, istouch, presses)
end

-- LÖVE input callback.
function BaseScene:mousemoved(x, y, dx, dy, istouch)
    -- print("BaseScene:mousemoved", x, y, dx, dy, istouch)
end

-- LÖVE focus callback
function BaseScene:focus(f)
    -- print("BaseScene:focus", f)
end

-- LÖVE quit callback
function BaseScene:quit()
    -- print("BaseScene:quit")
    return false -- Return true to prevent quitting
end

return BaseScene
