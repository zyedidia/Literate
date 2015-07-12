-- The run function
function run(cmd)
    local handle = io.popen(cmd)
    local result = handle:read("*a")
    handle:close()
    return result
end
-- The write function
function write(output, str)
    if output == "stdout" then
        io.write(str)
    else
        output:write(str)
    end
end
-- The file_exists function
function file_exists(file)
    local f = io.open(file, "rb")
    if f then f:close() end
    return f ~= nil
end
-- The lines_from function
function lines_from(file)
    if file ~= nil then
        if not file_exists(file) then 
            print(file, " does not exist!")
            return {}
        end
    end
    lines = {}
    if file ~= nil then
        for line in io.lines(file, "*L") do 
            lines[#lines + 1] = line
        end
    else
        for line in io.lines() do 
            lines[#lines + 1] = line
        end
    end
    return lines
end
-- The readall function
function readall(file)
    local f = io.open(file, "rb")
    if f == nil then
        print(file .. " could not be opened")
        return ""
    end
    local content = f:read("*all")
    f:close()
    return content
end
-- The readdir function
function readdir(dir)
    files = run("ls")
    return split(files, "\n")
end
-- The dirname function
function dirname(path)
    if path:match(".-/.-") then
        local name = string.gsub(path, "(.*/)(.*)", "%1")
        return name
    else
        return ''
    end
end
-- The basename function
function basename(path)
    return string.gsub(path, "(.*/)(.*)", "%2")
end
-- The name function
function name(path)
    local filename = basename(path)
    return filename:match"(.*)%..*"
end
