dir = dirname(Base.source_path())   # This variable holds the directory that the common.jl file is in.

block_locations = Dict{String, Array{Int, 1}}()
block_use_locations = Dict{String, Array{Int, 1}}()

function name(path)
    basename(file[1:search(file, '.')[1]-1])
end

function get_locations()
    lines = readlines(IOBuffer(source))
    sectionnum = 0   # Which section is currently being parsed
    in_codeblock = false   # Whether we are parsing a codeblock or not

    for line_num = 1:length(lines)
        line = lines[line_num] |> chomp # Use chomp to remove the \n
if startswith(line, "@s")
    sectionnum += 1

elseif startswith(line, "---")
    in_codeblock = true
    if ismatch(line, r"^---$")
        in_codeblock = false
        continue
    end
block_name = line[4:end] |> strip # Remove the 
if !haskey(block_locations, block_name) # If this block has not been defined in the dict yet
    block_locations[block_name] = [paragraphnum] # Create a new slot for it and add the current paragraph num
elseif !(paragraphnum in block_locations[block_name]) # If the current paragraph num isn't already in the array
    push!(block_locations[block_name], paragraphnum) # Add it
end


elseif in_codeblock && startswith(line, "@{")
    block_name = line[3:end-1] # Substring to just get the block name

    # Pretty much the same as before
    if !haskey(block_use_locations, block_name)
        block_use_locations[block_name] = [paragraphnum]
    elseif !(paragraphnum in block_use_locations[block_name])
        push!(block_use_locations[block_name], paragraphnum)
    end
end

    end
end


