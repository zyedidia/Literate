# Define the tangle function
comment_type = ""
function tangle(lines)
    codeblocks = Dict{String, String}()
    block_names = String[]
    
    for line_num = 1:length(lines)
        line = lines[line_num] |> chomp

        if startswith(line, "@comment_type")
            global comment_type = strip(line[15:end])
        elseif startswith(line, "---") && !ismatch(r"^---$", line)
# Get the block name
block_name = line[4:end] |> strip

add_to_block = false # Whether or not this definition has a +=
if contains(block_name, "+=")
    plus_index = search(block_name, "+")[end]
    block_name = block_name[1:plus_index-1] |> strip
    add_to_block = true
end

# Get the code
code = ""
while true
    line = lines[line_num += 1]
    chomp(line) == "---" && break
    code *= line
end

# Add the code to the dict
if add_to_block
    codeblocks[block_name] *= "\n$code"
else
    push!(block_names, block_name)
    codeblocks[block_name] = code
end

        end
    end

# Write the code
for name in block_names
    if ismatch(r"^.+\w\.\w+$", basename(name))
        outstream = open("$outdir/$(strip(name))", "w")
        write_code("$name", codeblocks, outstream)
        close(outstream)
    end
end

end

# Define the write_code function
function write_code(block_name, codeblocks, outstream)
    code = codeblocks[block_name]
    lines = split(code, "\n")

    if comment_type != ""
        if !ismatch(r"^.+\w\.\w+$", block_name)
            write(outstream, "$comment_type $block_name\n")
        end
    end

    for line in lines
        if startswith(strip(line), "@{")
            line = strip(line)
            write_code(line[3:end-1], codeblocks, outstream)
        else
            write(outstream, "$line\n")
        end
    end
end


