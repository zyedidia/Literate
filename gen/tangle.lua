-- Define the tangle function
comment_type = ""
function tangle(lines)
    local codeblocks = {} -- String => String
    local block_names = {} -- Number => String
    
    for line_num,line in pairs(lines) do
        line = chomp(line)
        if startswith(line, "@comment_type") then
            comment_type = strip(string.sub(line, 15, #line))
        elseif startswith(line, "---") and not string.match(line, "^---$") then
-- Get the block name
local block_name = strip(string.sub(line, 4, #line))

local add_to_block = false -- Whether or not this definition has a +=
if string.match(block_name, "+=") then
    local plus_index = block_name:match'^.*()%+'
    block_name = strip(string.sub(block_name, 1, plus_index-1))
    add_to_block = true
end
-- Get the code
local code = ""
while true do
    line_num = line_num + 1
    line = lines[line_num]
    if line == nil then break end
    if chomp(line) == "---" then break end
    code = code .. line
end
-- Add the code to the dict
if add_to_block then
    if codeblocks[block_name] ~= nil then
        codeblocks[block_name] = codeblocks[block_name] .. "\n" .. code
    else
        print(line_num .. ":Unknown block name: " .. block_name)
        os.exit()
    end
else
    block_names[#block_names + 1] = block_name
    codeblocks[block_name] = code
end
        end
    end

-- Write the code
for i,name in pairs(block_names) do
    if string.match(basename(name), "^.+%w%.%w+$") then
        if stdin then
            outstream = "STDOUT"
            print("\n---- " .. basename(name) .. " ----\n")
        else
            outstream = io.open(outdir .. "/" .. strip(name), "w")
        end
        write_code(name, codeblocks, outstream)
        if not stdin then
            outstream:close()
        end
    end
end
end
-- Define the write_code function
function write_code(block_name, codeblocks, outstream)
    local code = codeblocks[block_name]
    if code == nil then
        print("Unknown block name: " .. block_name)
        os.exit()
    end
    local lines = split(code, "\n")

    if comment_type ~= "" then
        if not string.match(block_name, "^.+%w%.%w+$") then
            write(outstream, comment_type .. " " .. block_name .. "\n")
        end
    end

    for line_num,line in pairs(lines) do
        if startswith(strip(line), "@{") then
            line = strip(line)
            write_code(string.sub(line, 3, line:find("}[^}]*$") - 1), codeblocks, outstream)
        else
            write(outstream, line .. "\n")
        end
    end
end
