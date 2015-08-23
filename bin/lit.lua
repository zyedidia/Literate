gen = arg[1]
package.path = gen .. "/?.lua;" .. package.path

require("stringutil")
require("fileutil")

require("weave")
require("tangle")

require("index")

md = require("markdown")

-- Function to identify the os
if package.config:sub(1, 1) == "/" then
    function os.name()
        return "Unix"
    end
elseif package.config:sub(1, 1) == "\\" then
    function os.name()
        return "Windows"
    end
end

-- Function to resolve @include statements
function resolve_includes(source, source_dir, cur_filename)
    local newSource = ""
    local lines = split(source, "\n")

    for i=1,#lines do
        local line = lines[i]

        if startswith(line, "@include") then
            local filename = basename(strip(line:sub(10)))
            if strip(filename) == "" then
                print(cur_filename .. ":error:No filename given to @change")
                os.exit()
            end
            local filetype = filename:match(".*%.(.*)")
            local file = source_dir .. "/" .. strip(line:sub(10))
            if not file_exists(file) then
                print(cur_filename .. ":error:" .. i .. ":Included file ".. file .. " does not exist.")
                os.exit()
            end

            if filetype == "lit" then
                newSource = newSource .. resolve_includes(readall(file), source_dir, file)
            end
        elseif startswith(line, "@change") and not startswith(line, "@change_end") then
            local filename = basename(strip(line:sub(9)))
            if strip(filename) == "" then
                print(cur_filename .. ":error:No filename given to @change")
                os.exit()
            end

            local filetype = filename:match(".*%.(.*)")
            local file = source_dir .. "/" .. strip(line:sub(9))
            if not file_exists(file) then
                print(cur_filename .. ":error:" .. i .. ":Changed file ".. file .. " does not exist.")
                os.exit()
            end

            local search_text = ""
            local replace_text = ""
            local in_search_text = false
            local in_replace_text = false

            local file_source = readall(file)

            while strip(line) ~= "@change_end" do
                if i == #lines + 1 then
                    print(cur_filename .. ":error:Reached end of file with no @change_end")
                    exit()
                end
                i = i + 1
                line = lines[i]

                if startswith(strip(line), "@replace") then
                    in_replace_text = false
                    in_search_text = true
                    i = i + 1
                    line = lines[i]
                elseif startswith(strip(line), "@with") then
                    in_search_text = false
                    in_replace_text = true
                    i = i + 1
                    line = lines[i]
                elseif startswith(strip(line), "@end") then
                    in_search_text = false
                    in_replace_text = false

                    search_text = literalize(chomp(search_text))
                    replace_text = chomp(replace_text)

                    if filetype == "lit" then
                        file_source = file_source:gsub(search_text, replace_text)
                        search_text = ""
                        replace_text = ""
                    end 
                end

                if in_search_text then
                    search_text = search_text .. line .. "\n"
                elseif in_replace_text then
                    replace_text = replace_text .. line .. "\n"
                end
            end

            newSource = newSource .. resolve_includes(file_source, source_dir, file)

            if i >= #lines then
                break
            end
        end

        newSource = newSource .. line .. "\n"
    end

    return newSource
end


-- Parse the arguments
html = false
code = false
outdir = "."
index = true
generate_files = true

inputfiles = {}

for i=2,#arg do
    argument = arg[i]
    if argument == "-h" then
        print("Usage: lit [-noindex] [-html] [-code] [--out-dir=dir] [--no-output] [file ...]")
        os.exit()
    elseif argument == "-html" then
        html = true
    elseif argument == "-code" then
        code = true
    elseif argument == "-noindex" then
        index = false
    elseif startswith(argument, "--out-dir=") then
        outdir = string.sub(argument, 11, #argument)
    elseif startswith(argument, "--no-output") then
        generate_files = false
    else
        inputfiles[#inputfiles + 1] = argument
    end
end

if not html and not code then
    html = true
    code = true
end

if #inputfiles == 0 then
    -- Use STDIN and STDOUT
    -- Declare a few globals
    title = ""
    block_locations = {} -- String => (Number => Number)
    block_use_locations = {} -- String => (Number => Number)
    
    codetype = ""
    codetype_ext = ""
    
    code_lines = {} -- Number => Number
    section_linenums = {} -- Number => Number

    local source_dir = "."
    
    complete_source = readall()
    complete_source = resolve_includes(complete_source, source_dir, "none")
    local lines = split(complete_source, "\n")
    
    inputfilename = "none"
    
    stdin = true
    if html then
        local output = weave(lines, ".", index)
        if generate_files then
            write("STDOUT", output)
        end
    end
    
    if code then
        tangle(lines)
    end

else
    -- Weave and/or tangle the input files
    for num,file in pairs(inputfiles) do
        -- Declare a few globals
        title = ""
        block_locations = {} -- String => (Number => Number)
        block_use_locations = {} -- String => (Number => Number)
        
        codetype = ""
        codetype_ext = ""
        
        code_lines = {} -- Number => Number
        section_linenums = {} -- Number => Number

    
        inputfilename = file
    
        local source_dir = dirname(file)
        if source_dir == "" then
            source_dir = "."
        end
    
        complete_source = readall(file)
        complete_source = resolve_includes(complete_source, source_dir, file)
        local lines = split(complete_source, "\n")
    
        if html then
            local output = weave(lines, source_dir, index)
            if generate_files then
                local outputstream = io.open(outdir .. "/" .. name(file) .. ".html", "w")
                write(outputstream, output)
                outputstream:close()
            end
        end
        if code then
            tangle(lines)
        end
    end

end

