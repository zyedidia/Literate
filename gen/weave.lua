-- Define the contains function
function contains(tbl, item)
    for key, value in pairs(tbl) do
        if value == item then return key end
    end
    return false
end

function contains_str(tbl, str)
for key, value in pairs(tbl) do
    if string.lower(value) == string.lower(str) then return key end
end
return false
end

-- Define the get_locations function
function get_locations(lines)
    local sectionnum = 0   -- Which section is currently being parsed
    local in_codeblock = false   -- Whether we are parsing a codeblock or not

    for line_num,line in pairs(lines) do
        line = chomp(line) -- Use chomp to remove the \n

        if startswith(line, "@title") then
            -- Initialize the title variable
            title = strip(string.sub(line, 7, #line))

        elseif startswith(line, "@s") then
            section_linenums[#section_linenums + 1] = line_num
            sectionnum = sectionnum + 1
        elseif startswith(line, "---") then
            -- A codeblock has been defined
            in_codeblock = true
            if string.match(line, "^%-%-%-$") then
                in_codeblock = false
                goto continue
            end
            -- Get the block name
            local block_name = strip(string.sub(line, 4, #line)) -- Remove the '---'
            
            if string.match(block_name, "+=") then
                local plus_index = block_name:match'^.*()%+' -- Get the index of the "+" (the [end] is to get the last occurrence)
                block_name = strip(string.sub(block_name, 1, plus_index-1)) -- Remove the "+=" and strip any whitespace
            end

            -- Add the locations to the dict
            if block_locations[block_name] == nil then -- If this block has not been defined in the dict yet
                block_locations[block_name] = {sectionnum} -- Create a new slot for it and add the current section num
            elseif block_locations[block_name][sectionnum] == nil then -- If the current section num isn't already in the array
                block_locations[block_name][#block_locations[block_name] + 1] = sectionnum -- Add it
            end


        elseif in_codeblock and startswith(strip(line), "@{") then
            -- A codeblock has been used
            line = strip(line)
            local block_name = string.sub(line, 3, #line - 1) -- Substring to just get the block name
            
            -- Pretty much the same as before
            if block_use_locations[block_name] == nil then
                block_use_locations[block_name] = {sectionnum}
            elseif block_use_locations[block_name][sectionnum] == nil then
                block_use_locations[block_name][#block_use_locations[block_name] + 1] = sectionnum
            end

        end
        ::continue::
    end
end

-- Define the write_markdown function
function write_markdown(markdown, out)
    if markdown ~= "" then
        local html = markdown
        html = string.gsub(html, "<", "&lt;")
        html = string.gsub(html, ">", "&gt;")
        html = string.gsub(html, "\"", "&quot;")
        html = md.markdown(markdown)
        write(out, html .. "\n")
    end
end

-- Define the weave function
function weave(lines, outputstream, source_dir, inputfilename, has_index)
    local out = outputstream

    get_locations(lines)

    -- Set up html
    local start_codeblock = "<pre class=\"prettyprint\">\n"
    local end_codeblock = "</pre>\n"
    
    local scripts = [[<script src="https://cdn.rawgit.com/google/code-prettify/master/loader/run_prettify.js"></script>
                 <script src='https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML'></script>
                 <script type="text/x-mathjax-config"> MathJax.Hub.Config({tex2jax: {inlineMath: ]] .. "[['$','$']]}}); </script>\n"
    
    -- Get the CSS
    local css = ""
    local files = readdir(source_dir) -- All the files in the current directory
    
    if contains(files, "default.css") then
        css = readall(source_dir .. "/default.css") -- Read the user's default.css
    else
        css = readall(gen .. "/default.css") -- Use the default css
    end
    
    if contains(files, "colorscheme.css") then
        css = css .. readall(source_dir .. "/colorscheme.css") -- Read the user's colorscheme.css
    else
        css = css .. readall(gen .. "/colorscheme.css") -- Use the default colorscheme
    end
    
    if contains(files, "additions.css") then
        css = css .. readall(source_dir .. "/additions.css") -- Read the user's additions.css
    end

    
    local base_html = [[<!doctype html>
                   <html>
                   <head>
                   <meta charset="utf-8">
                   <title> ]] .. title .. [[ </title>
                   ]] .. scripts .. [[
                   <style>
                   ]] .. css .. [[
                   </style>
                   </head>
                   <body>]]
    
    write(out, base_html)

    -- Set up variables
    local sectionnum = 0 -- Which section number we are currently parsing
    local in_codeblock = false -- Whether or not we are parsing a some code
    local in_prose = false -- Whether or not we are parsing prose
    local markdown = "" -- This variable holds the current markdown that needs to be transformed to html
    
    local cur_codeblock_name = "" -- The name of the current codeblock begin parsed


    for line_num,line in pairs(lines) do
        line = chomp(line)

        if startswith(line, "@code_type") then
            local command = split(line, " ")
            codetype = command[2]
            codetype_ext = string.sub(command[3], 2, #command[3])
            goto continue
        elseif startswith(line, "@comment_type") then
            goto continue
        end

        -- Parse the line
        if line == "" then
            -- This was a blank line
            if in_codeblock then
                write(out, "\n")
            else
                markdown = markdown .. "\n" -- Tell markdown this was a blank line
            end
            goto continue
        end
        
        if string.match(line, "^%-%-%-.+$") then -- Codeblock began
            -- Begin codeblock
            -- A code block just began
            in_prose = false
            in_codeblock = true
            -- Write the current markdown
            write_markdown(markdown, out)
            -- Reset the markdown
            markdown = ""
            
            write(out, "<div class=\"codeblock\">\n")
            local name = strip(string.sub(line, 4, #line)) -- The codeblock name
            
            local adding = false -- Whether or not this block is a +=
            
            if string.match(name, "+=") then
                local plus_index = name:match'^.*()%+'
                name = strip(string.sub(name, 1, plus_index-1))
                adding = true
            end
            
            cur_codeblock_name = name
            file = string.match(name, "^.+%w%.%w+$") -- Whether or not this name is a file name
            
            if block_locations[name] == nil then
                print("Weave error: line " .. line_num .. ": Unknown block name " .. name)
                os.exit()
            end
            
            local definition_location = block_locations[name][1]
            
            local output = name .. " <a href=\"#" .. definition_location .. "\">" .. definition_location .. "</a>" -- Add the link to the definition location
            local plus = ""
            if adding then
                plus = "+"
            end
            output = "{" .. output .. "} " .. plus .. "≡" -- Add the = or +=
            
            if file then
                output = "<b>" .. output .. "</b>" -- If the name is a file, make it bold
            end
            
            write(out, "<p class=\"notp\"><span class=\"codeblock_name\">" .. output .. "</span></p>\n")
            -- We can now begin pretty printing the code that comes next
            write(out, start_codeblock)

        elseif string.match(line, "^%-%-%-$") then -- Codeblock ended
            -- End codeblock
            -- A code block just ended
            in_prose = true
            in_codeblock = false
            
            -- First start by ending the pretty printing
            write(out, end_codeblock)
            -- This was stored when the code block began
            local name = cur_codeblock_name
            
            -- Write any "see also" links
            local locations = block_locations[name]
            if block_locations[name] == nil then
                print("Weave error: line " .. line_num .. ": Unknown block name " .. name)
                os.exit()
            end
            
            if #locations > 1 then
                local links = "" -- This will hold the html for the links
                local loopnum = 0
                for i = 2,#locations do
                    local location = locations[i]
                    if location ~= sectionnum then
                        loopnum = loopnum + 1
                        local punc = "" -- We might need a comma or 'and'
                        if loopnum > 1 and loopnum < #locations-1 then
                            punc = ","
                        elseif loopnum == #locations-1 and loopnum > 1 then
                            punc = " and"
                        end
                        links = links .. punc .. " <a href=\"#" .. location .. "\">" .. location .. "</a>"
                    end
                end
                if loopnum > 0 then
                    local plural = ""
                    if loopnum > 1 then
                        plural = "s"
                    end
                    write(out, "<p class=\"seealso\">See also section" .. plural .. links .. ".</p>\n")
                end
            end

            -- Write any "used in" links
            -- Top level codeblocks such as files are never used, so we have to check here
            if block_use_locations[name] ~= nil then
                local locations = block_use_locations[name]
                local plural = ""
                if #locations > 1 then
                    plural = "s"
                end
                local output = "<p class=\"seealso\">This code is used in section" .. plural
                for i = 1,#locations do
                    local location = locations[i]
                    local punc = ""
                    if i > 1 and i < #locations then
                        punc = ","
                    elseif i == #locations and i ~= 1 then
                        punc = " and"
                    end
                    output = output .. punc .. " <a href=\"#" .. location .. "\">" .. location .. "</a>"
                end
                output = output .. ".</p>\n"
                write(out, output)
            end

            -- Close the "codeblock" div
            write(out, "</div>\n")

        elseif startswith(line, "@s") and not in_codeblock then -- Section began
            -- Create a new section
            if sectionnum > 1 then
                -- Every section is part of a div. Here we close the last one, and open a new one
                write(out, "</div>")
            end
            if sectionnum > 0 then
                write(out, "<div class=\"section\">\n")
            end
            
            -- Write the markdown. It is possible that the last section had no code and was only prose.
            write_markdown(markdown, out)
            -- Reset the markdown
            markdown = ""
            
            in_section = true
            sectionnum = sectionnum + 1
            heading_title = strip(string.sub(line, 3, #line))
            local class = ""
            if heading_title == "" then
                class = "class=\"noheading\""
            end
            write(out, "<p class=\"notp\" id=\"" .. sectionnum .. "\"></p><h4 ".. class .. ">" .. sectionnum .. ". ".. heading_title .. "</h4>\n")

        elseif startswith(line, "@title") and not in_codeblock then -- Title created
            -- Create the title
            local title = strip(string.sub(line, 7, #line))
            write(out, "<h1>" .. title .. "</h1>\n")

        elseif startswith(line, "@include_html") and not in_codeblock then -- Inline the html given
            print("yes")
            -- Inline the html in the specified file
            file = source_dir .. "/" .. line:sub(15)
            if not file_exists(file) then
                print("Weave error: line " .. line_num .. ": Included file ".. file .. " does not exist.")
                exit()
            end
            write(out, readall(file))
            goto continue

        else
            if in_codeblock then
                -- Write out the line of code
                code_lines[line:gsub("%s+", " ")] = line_num
                line = string.gsub(line, "&", "&amp;")
                line = string.gsub(line, "<", "&lt;")
                line = string.gsub(line, ">", "&gt;")
                -- Link any sections in the line
                while string.match(line, "@{.*}") do
                    if not startswith(strip(line), "@{") and in_codeblock then
                        break
                    end
                    local m = string.match(line, "@{.*}")
                    local name = string.sub(m, 3, #m - 1) -- Get the name in curly brackets
                    if block_locations[name] == nil then
                        print("Weave error: line " .. line_num .. ": Unknown block name " .. name)
                        os.exit()
                    end
                    local location = block_locations[name][1]
                
                    if in_codeblock then
                        local anchor = " <a href=\"#" .. location .. "\">" .. location .. "</a>"
                        local links = "<span class=\"nocode\">{" .. name .. anchor .. "}</span>" -- The nocode is so that this is not pretty printed
                        line = string.gsub(line, literalize(m), links)
                    else
                        local anchor = " [" .. location .. "](#" .. location .. ")"
                        local links = "{`" .. name .. "`" .. anchor .. "}"
                        line = string.gsub(line, literalize(m), links)
                    end
                end

                write(out, line .. "\n")

            else
                -- Add the line to the markdown
                -- Link any sections in the line
                while string.match(line, "@{.*}") do
                    if not startswith(strip(line), "@{") and in_codeblock then
                        break
                    end
                    local m = string.match(line, "@{.*}")
                    local name = string.sub(m, 3, #m - 1) -- Get the name in curly brackets
                    if block_locations[name] == nil then
                        print("Weave error: line " .. line_num .. ": Unknown block name " .. name)
                        os.exit()
                    end
                    local location = block_locations[name][1]
                
                    if in_codeblock then
                        local anchor = " <a href=\"#" .. location .. "\">" .. location .. "</a>"
                        local links = "<span class=\"nocode\">{" .. name .. anchor .. "}</span>" -- The nocode is so that this is not pretty printed
                        line = string.gsub(line, literalize(m), links)
                    else
                        local anchor = " [" .. location .. "](#" .. location .. ")"
                        local links = "{`" .. name .. "`" .. anchor .. "}"
                        line = string.gsub(line, literalize(m), links)
                    end
                end

                markdown = markdown .. line .. "\n"

            end
        end

        ::continue::
    end

    -- Clean up
    write_markdown(markdown, out)
    -- Close the last section's div
    write(out, "</div>")
    
    if has_index then
        write(out, create_index(inputfilename))
    end
    
    write(out, "</body>\n</html>\n")

end


