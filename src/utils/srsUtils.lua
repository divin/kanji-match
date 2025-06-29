local srsUtils = {}

--- Utility functions for SRS (Spaced Repetition System) management in a kanji learning application.
--- @param kanjiData table A table containing kanji data, where each entry is a group of kanji.
--- @param srsStates table A table containing the SRS states for each kanji character.
--- @param settings table Optional settings for the SRS, such as `groupsPerLesson`.
function srsUtils.getDueGroups(kanjiData, srsStates, settings)
    local osTime = os.time()
    assert(osTime, "Failed to get system time")
    local currentTime = osTime / (24 * 60 * 60) -- Current time in days since epoch
    local dueGroups = {}

    assert(kanjiData, "Kanji data is nil when getting due groups")
    for groupIndex, group in ipairs(kanjiData) do
        assert(group, "Group is nil at index " .. groupIndex)
        local earliestDueDate = math.huge
        local hasNewKanji = false

        -- Find the earliest due date (worst performing) kanji in this group
        for _, kanji in ipairs(group) do
            local state = srsStates[kanji.character]
            if state == nil then
                -- New kanji, group is immediately due
                hasNewKanji = true
                earliestDueDate = currentTime
                break
            else
                local dueDate = state.lastReviewed + state.interval
                if dueDate < earliestDueDate then
                    earliestDueDate = dueDate
                end
            end
        end

        -- If the worst performing kanji in the group is due, include the entire group
        if hasNewKanji or currentTime >= earliestDueDate then
            table.insert(dueGroups, {
                groupIndex = groupIndex,
                group = group,
                earliestDueDate = earliestDueDate,
                hasNewKanji = hasNewKanji
            })
        end
    end

    -- Sort groups: due groups (not hasNewKanji) first, then new groups, both by earliest due date
    table.sort(dueGroups, function(a, b)
        if not a.hasNewKanji and b.hasNewKanji then
            return true
        elseif a.hasNewKanji and not b.hasNewKanji then
            return false
        else
            return a.earliestDueDate < b.earliestDueDate
        end
    end)

    -- Limit to groupsPerLesson setting
    local limitedGroups = {}
    local maxGroups = (settings and settings.groupsPerLesson) or 5

    -- Validate groupsPerLesson setting if provided
    if maxGroups then
        assert(type(maxGroups) == "number", "groupsPerLesson must be a number")
        assert(maxGroups >= 0, "groupsPerLesson must be non-negative")
    end

    -- Ensure at least 1 group is shown if any are available
    if maxGroups < 1 and #dueGroups > 0 then
        maxGroups = 1
    end
    for i = 1, math.min(#dueGroups, maxGroups) do
        table.insert(limitedGroups, dueGroups[i])
    end

    return limitedGroups, #dueGroups
end

return srsUtils
