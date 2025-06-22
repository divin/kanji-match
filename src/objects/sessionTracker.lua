local SessionTracker = {}
SessionTracker.__index = SessionTracker

-- Constructor
function SessionTracker:new(totalGroups, streakConfig)
    assert(type(totalGroups) == "number", "totalGroups must be a number")

    local instance = setmetatable({}, SessionTracker)

    -- Session statistics
    instance.totalGroups = totalGroups
    instance.completedGroups = 0
    instance.totalKanji = 0
    instance.correctMatches = 0
    instance.incorrectMatches = 0
    instance.maxStreak = 0
    instance.sessionStartTime = love.timer.getTime()
    instance.sessionTime = 0

    -- Streak tracking
    instance.streak = 0
    instance.streakConfig = streakConfig or {
        basePitch = 1.0,
        pitchIncrement = 0.15,
        maxPitch = 2.5,
        maxStreakDisplay = 10,
        resetOnMiss = true
    }

    return instance
end

-- Record a correct match
function SessionTracker:recordCorrectMatch()
    self.correctMatches = self.correctMatches + 1
    self.streak = self.streak + 1

    if self.streak > self.maxStreak then
        self.maxStreak = self.streak
    end
end

-- Record an incorrect match
function SessionTracker:recordIncorrectMatch()
    self.incorrectMatches = self.incorrectMatches + 1

    if self.streakConfig.resetOnMiss then
        self.streak = 0
    end
end

-- Add kanji to total count
function SessionTracker:addKanji(count)
    assert(type(count) == "number", "count must be a number")
    self.totalKanji = self.totalKanji + count
end

-- Mark a group as completed
function SessionTracker:completeGroup()
    self.completedGroups = self.completedGroups + 1
end

-- Get current streak
function SessionTracker:getStreak()
    return self.streak
end

-- Get streak-based audio pitch
function SessionTracker:getAudioPitch()
    return math.min(
        self.streakConfig.basePitch + (self.streak * self.streakConfig.pitchIncrement),
        self.streakConfig.maxPitch
    )
end

-- Check if streak should be displayed
function SessionTracker:shouldDisplayStreak()
    return self.streak > 0 and self.streak <= self.streakConfig.maxStreakDisplay
end

-- Check if streak is at high level (for special display)
function SessionTracker:isHighStreak()
    return self.streak > self.streakConfig.maxStreakDisplay
end

-- Get streak display color based on level
function SessionTracker:getStreakColor()
    if self:isHighStreak() then
        return { 1, 0.2, 0.2, 1 } -- Bright red for high streaks
    elseif self:shouldDisplayStreak() then
        -- Color based on streak level (yellow -> orange -> red)
        local intensity = math.min(self.streak / 5, 1)
        return { 1, 1 - intensity * 0.5, 1 - intensity, 1 }
    else
        return { 1, 1, 1, 1 } -- White default
    end
end

-- Get streak display text
function SessionTracker:getStreakText()
    if self:isHighStreak() then
        return "Streak: " .. self.streak .. "!"
    elseif self:shouldDisplayStreak() then
        return "Streak: " .. self.streak
    else
        return ""
    end
end

-- Finalize session (calculate final time)
function SessionTracker:finalizeSession()
    self.sessionTime = love.timer.getTime() - self.sessionStartTime
    self.completedGroups = self.totalGroups
end

-- Get all session statistics
function SessionTracker:getStats()
    return {
        totalGroups = self.totalGroups,
        completedGroups = self.completedGroups,
        totalKanji = self.totalKanji,
        correctMatches = self.correctMatches,
        incorrectMatches = self.incorrectMatches,
        maxStreak = self.maxStreak,
        sessionStartTime = self.sessionStartTime,
        sessionTime = self.sessionTime
    }
end

-- Reset streak (for manual reset)
function SessionTracker:resetStreak()
    self.streak = 0
end

-- Get base audio pitch (for resetting audio)
function SessionTracker:getBasePitch()
    return self.streakConfig.basePitch
end

return SessionTracker
