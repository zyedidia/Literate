function section_for_linenum(linenum)

    -- Get the section number given a line number
    for i = 1,#section_linenums do
        if i == #section_linenums then
            return i
        end
        if linenum < section_linenums[i + 1] then
            return i
        end
    end
end

-- Sort a table
function pairsByKeys (t, f)
    local a = {}
    for n in pairs(t) do table.insert(a, n) end
    table.sort(a, f)
    local i = 0      -- iterator variable
    local iter = function ()   -- iterator function
        i = i + 1
        if a[i] == nil then return nil
        else return a[i], t[a[i]]
        end
    end
    return iter
end

function create_index(inputfile)
    if run("which ctags") == nil then
        print("You do not have ctags installed and it is required for making an index.")
        print("If you do not want to receive this message use the -noindex flag.")
        return ""
    end

    if run("ctags --list-languages") == nil then
        print("You have an old version of ctags installed, please update to exuberant or universal ctags if you want an index.")
        print("If you do not want to receive this message use the -noindex flag.")
        return ""
    end


    -- Run Ctags on the lit file
    local tangle_result = run("echo '" .. complete_source:gsub("'", "'\"'\"'") .. "' | lit -code > out.txt")
    local tags_str = run("ctags -x --" .. string.lower(codetype) .. "-kinds=+abcdefghijklmnopqrxtuvwxyzABCDEFGHIJKLMNOPQRXTUVWXYZ  --language-force=" .. string.lower(codetype) .. " out.txt 2>/dev/null")
    run("rm out.txt")
    
    if tags_str == "" then
        print(codetype .. " is not supported by your version of ctags.")
        print("Please use -noindex if you would not like to create an index.")
        return ""
    end
    
    local tags_arr = split(tags_str, "\n")
    local tags = {}
    
    for _,tag in pairs(tags_arr) do
        if tag ~= "" then
            local words = split(tag, "%s+")
    
            local line = tag:match("out.txt%s+([^%s].-)$")
    
            if code_lines[line] == nil then
                goto continue
            end
    
            local line_num = code_lines[line]
    
            local name = words[1]
            local tag_type = words[2]
            
            tags[#tags + 1] = {name, tag_type, line_num}
        end
        ::continue::
    end

    -- Create the HTML for the index
    local html = "<h3>Index</h3>\n"
    html = html .. "<h5>Identifiers Used</h5>\n"
    html = html .. "<ul class=\"two-col\">\n"
    
    for _,tag in pairs(tags) do
        local section_num = section_for_linenum(tag[3])
        html = html .. "<li><code>" .. tag[1] .. "</code>: <em>" .. tag[2] .. "</em> <a href=\"#" .. section_num .. "\">" .. section_num .. "</a></li>\n"
    end
    html = html .. "</ul>"
    
    html = html .. "<h5>Code Blocks</h5>\n"
    html = html .. "<ul class=\"two-col\">\n"
    
    -- Sort the block_locations dictionary so that the codeblocks come in order
    for name,locations in pairsByKeys(block_locations) do
        html = html .. "<li><code>" .. name .. "</code>"
        for i = 1,#locations do
            local location = locations[i]
            local p = ", "
            if i == 1 then
                p = " "
            end
            html = html .. p .. "<a href=\"#" .. location .. "\">" .. location .. "</a>"
        end
        html = html .. "</li>\n"
    end
    html = html .. "</ul>"
    return html
end
