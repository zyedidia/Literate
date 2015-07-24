#!/usr/bin/env lua
require "stringutil"
require "fileutil"

function contains(tbl, item)
    for key, value in pairs(tbl) do
        if value == item then return key end
    end
    return false
end

inputfiles = {}

for i=1,#arg do
    argument = arg[i]
    inputfiles[#inputfiles + 1] = argument
end

for i=1,#inputfiles do
    inputfile = inputfiles[i]
    lines = lines_from(inputfile)

    block_names = {}
    block_defs = {}

    for i=1,#lines do
        local line = lines[i]

        local block_name = string.match(line, "@<(.-)@>")

        if block_name then
            if not string.match(block_name, "%.%.%.") then
                if block_names[block_name] == nil then
                    block_names[#block_names + 1] = block_name
                end
            end
        end

    end
    for i=1,#lines do
        local line = lines[i]

        local block_name = string.match(line, "@<(.-)@>=")

        if block_name then
            if not string.match(block_name, "%.%.%.") then
                if not contains(block_defs, block_name) then
                    block_defs[#block_defs + 1] = block_name
                else
                    block_defs[#block_defs + 1] = block_name .. "+="
                end
            else
                for j=1,#block_names do
                    if startswith(block_names[j], block_name:gsub("...$", "")) then
                        block_name = block_names[j]
                        if not contains(block_defs, block_name) then
                            block_defs[#block_defs + 1] = block_name
                        else
                            block_defs[#block_defs + 1] = block_name .. " +="
                        end
                        break
                    end
                end
            end
        end
    end

    in_codeblock = false
    started = false

    out = ""

    out = out .."@code_type c c\n"
    out = out .."@title " .. name(inputfile) .. "\n"

    block_num = 0

    for i=1,#lines do
        local line = lines[i]

        if string.match(strip(line), "^@ ") or string.match(strip(line), "^@%*") then
            if in_codeblock then
                out = out .. "---\n\n"
            end
            in_codeblock = false
            if string.match(strip(line), "^@ ") then
                line = strip(line):gsub("^@ (.-)", "@s\n%1")
            else
                started = true
                line = strip(line):gsub("^@%*(.-)%.(.-)", "@s %1\n%2")
            end
            line = line .. "\n"
        end

        if string.match(line, "@<(.-)@>=") then
            in_codeblock = true
            block_num = block_num + 1
            line = line:gsub("@<(.-)@>=", "--- " .. block_defs[block_num])
        end

        if string.match(line, "@c") then
            in_codeblock = true
        end

        line = line:gsub("{\\sl (.-)}", "*%1*")
        line = line:gsub("{\\tt (.-)}", "%1")
        line = line:gsub("{\\it (.-)}", "*%1")
        line = line:gsub("\\/", "")
        if not in_codeblock then
            line = line:gsub("``(.-)''", "\"%1\"")
            line = line:gsub("`(.-)'", "'%1'")
            line = line:gsub("\\%.{(.-)}", "`%1`")
            line = line:gsub("\\(.-)/", "`%1`")
            line = line:gsub("|(.-)|", "`%1`")
        end
        line = line:gsub("@<(.-)@>;", "@{%1}")
        line = line:gsub("@<(.-)@>@;", "@{%1}")
        line = line:gsub("@<(.-)@>", "@{%1}")
        line = line:gsub("@c", "--- " .. name(inputfile) .. ".c")
        line = line:gsub("@/", "")
        line = line:gsub("@%+", " ")

        ::continue::

        if started then
            out = out .. line
        end
    end

    out = out:gsub("\n%-%-%-\n", "---\n")

    file = io.open(name(inputfile) .. ".lit", "w")
    write(file, out)
    file:close()
end
