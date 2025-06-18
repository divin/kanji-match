--- Shuffles the elements of a given table in-place using the Fisher-Yates algorithm.
--- The function modifies the input table directly.
--- @param tbl table # The table to be shuffled. It is expected to have an array-like part (integer keys from 1 to n).
--- @return table # The input table, now with its elements shuffled.
local function shuffleTable(tbl)
    assert(type(tbl) == "table", "Expected a table to shuffle")
    math.randomseed(os.time())

    local n = #tbl                -- Get the number of elements in the array part
    if n == 0 then return tbl end -- Nothing to shuffle

    for i = n, 2, -1 do
        -- Pick an index j from 1 to i (inclusive)
        local j = math.random(i)
        -- Swap tbl[i] with tbl[j]
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end

    return tbl
end

return shuffleTable
