#!/usr/bin/env lua
gen = arg[1]
package.path = gen .. "/?.lua;" .. package.path

require("stringutil")
require("fileutil")

require("weave")
require("tangle")

require("index")

md = require("markdown")


-- Parse the arguments
html = false
code = false
outdir = "."
index = true

inputfiles = {}

for i=2,#arg do
    argument = arg[i]
    if argument == "-h" then
        print("Usage: lit [-noindex] [-html] [-code] [--out-dir=dir] [file ...]")
        os.exit()
    elseif argument == "-html" then
        html = true
    elseif argument == "-code" then
        code = true
    elseif argument == "-noindex" then
        index = false
    elseif startswith(argument, "--out-dir=") then
        outdir = string.sub(argument, 11, #argument)
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
    lines = lines_from()

    -- Declare a few globals
    title = ""
    block_locations = {} -- String => (Number => Number)
    block_use_locations = {} -- String => (Number => Number)
    
    codetype = ""
    codetype_ext = ""
    
    code_lines = {} -- Number => Number
    section_linenums = {} -- Number => Number
    
    complete_source = ""
    for i=1,#lines do
        complete_source = complete_source .. lines[i] .. "\n"
    end
    
    stdin = true
    if html then
        weave(lines, "STDOUT", ".", "none", index)
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
    
        local lines = lines_from(file)
    
        complete_source = ""
        for i=1,#lines do
            complete_source = complete_source .. lines[i] .. "\n"
        end
    
        local source_dir = dirname(file)
        if source_dir == "" then
            source_dir = "."
        end
        if html then
            local outputstream = io.open(outdir .. "/" .. name(file) .. ".html", "w")
            weave(lines, outputstream, source_dir, file, index)
            outputstream:close()
        end
        if code then
            tangle(lines)
        end
    end
end

-- vim: set ft=lua:
