local function printTable(tbl)
    assert(type(tbl) == "table", "Expected a table to print")

    for i, v in ipairs(tbl) do
        if type(v) == "table" then
            print("Index " .. i .. ":")
            printTable(v) -- Recursively print nested tables
        else
            print("Index " .. i .. ": " .. tostring(v))
        end
    end
end

return printTable
