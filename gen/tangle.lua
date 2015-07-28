
-- Define the tangle function
function tangle(lines)
    comment_type = ""
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
                if stdin then
                    code = code .. "\n"
                end
            end

            -- Add the code to the dict
            if add_to_block then
                if codeblocks[block_name] ~= nil then
                    codeblocks[block_name] = codeblocks[block_name] .. "\n" .. code
                else
                    print("Tangle error: line " .. line_num .. ": Unknown block name: " .. block_name)
                    os.exit()
                end
            else
                block_names[#block_names + 1] = block_name
                codeblocks[block_name] = code
            end
        end
    end


    -- Write the code
    found_file = false
    for i,name in pairs(block_names) do
        if string.match(basename(name), "^.+%w%.%w+$") then
            found_file = true
            if stdin then
                outstream = "STDOUT"
                print("\n---- " .. basename(name) .. " ----\n")
            else
                outstream = io.open(outdir .. "/" .. strip(name), "w")
            end
            write_code(name, "", codeblocks, outstream)
            if not stdin then
                outstream:close()
            end
        end
    end
    if not found_file then
        print("Tangle error: no file name found. Not writing any code file.")
    end
end

-- Define the write_code function
function write_code(block_name, leading_whitespace, codeblocks, outstream)
    local code = codeblocks[block_name]
    if code == nil then
        print("Tangle error: Unknown block name: " .. block_name)
        os.exit()
    end
    local lines = split(code, "\n")

    if comment_type ~= "" then
        if not string.match(block_name, "^.+%w%.%w+$") then
            comment = string.gsub(comment_type, "%%s", block_name)
            write(outstream, "\n" .. leading_whitespace .. comment .. "\n")
        end
    end

    for line_num,line in pairs(lines) do
        if startswith(strip(line), "@{") then
            myleading_whitespace = string.match(line, "^(.-)[^%s]")
            line = strip(line)
            write_code(string.sub(line, 3, line:find("}[^}]*$") - 1), leading_whitespace .. myleading_whitespace, codeblocks, outstream)
        else
            write(outstream, leading_whitespace .. line .. "\n")
        end
    end
end
