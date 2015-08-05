-- The startswith function
function startswith(str, start)
    return string.sub(str, 1, string.len(start)) == start
end

-- The split function
function split(pString, pPattern)
    local Table = {}  -- NOTE: use {n = 0} in Lua-5.0
    local fpat = "(.-)" .. pPattern
    local last_end = 1
    local s, e, cap = pString:find(fpat, 1)
    while s do
        if s ~= 1 or cap ~= "" then
            table.insert(Table,cap)
        end
        last_end = e+1
        s, e, cap = pString:find(fpat, last_end)
    end
    if last_end <= #pString then
        cap = pString:sub(last_end)
        table.insert(Table, cap)
    end
    return Table
end

-- The strip function
function strip(str)
    return str:gsub("^%s*(.-)%s*$", "%1")
end

-- The chomp function
function chomp(str)
    return str:gsub("\n$", "")
end

-- The literalize function
function literalize(str)
    return str:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", function(c) return "%" .. c end)
end


