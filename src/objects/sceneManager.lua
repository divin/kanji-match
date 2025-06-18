local SceneManager = {}
SceneManager.__index = SceneManager
SceneManager.currentScene = nil
SceneManager.scenes = {} -- To store all available scenes

-- Function to switch to a new scene
function SceneManager:switchTo(sceneName, ...)
    if self.scenes[sceneName] then
        local targetScene = self.scenes[sceneName]

        -- Call load on the target scene if it hasn't been loaded yet.
        -- We use a flag `_isLoaded` on the scene object itself.
        if not targetScene._isLoaded then
            if targetScene.load then
                targetScene:load(...)    -- Pass arguments to load
            end
            targetScene._isLoaded = true -- Mark as loaded
        end

        -- Leave current scene if there is one
        if self.currentScene and self.currentScene.leave then
            self.currentScene:leave()
        end

        -- Set and enter new scene
        self.currentScene = targetScene
        if self.currentScene.enter then
            self.currentScene:enter(...) -- Pass arguments to enter
        end
    else
        print("Error: Scene '" .. sceneName .. "' not found.")
    end
end

-- Function to register a scene
function SceneManager:register(sceneName, sceneTable)
    self.scenes[sceneName] = sceneTable
end

return SceneManager
