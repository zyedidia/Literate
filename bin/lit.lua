#!/usr/bin/env lua
gen = "../gen"
package.path = "../?.lua;" .. package.path

require "../gen/stringutil"
require "../gen/fileutil"

require "../gen/weave"
require "../gen/tangle"

require "../gen/index"

md = require("../gen/markdown")

-- Parse the arguments
html = false
code = false
outdir = "."
index = true

inputfiles = {}

for i=1,#arg do
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
if html then
    weave(lines, "STDOUT", ".", "none", false)
end

if code then
    tangle(lines)
end
else
-- Weave and/or tangle the input files
for num,file in pairs(inputfiles) do
    local lines = lines_from(file)
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
