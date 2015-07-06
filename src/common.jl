include("lexer.jl")

dir = dirname(Base.source_path())

title = ""
block_locations = Dict{String, String}()
block_use_locations = Dict{String, String}()

function name(file)
	basename(file[1:search(file, '.')-1])
end

function firstpass(sourcefile)
	lexer = Lexer(IOBuffer(sourcefile), [' ', '\n', '@'])
	paragraphnum = 0
	in_codeblock = false

	while (t = advance(lexer)) != EOF
		if t == "@"
			t = advance(lexer)
			if t == "title"
				while (t = advance(lexer)) != "\n"
					global title *= t
				end
			elseif t == "s"
				paragraphnum += 1
			elseif in_codeblock
				restline = t * chomp(advanceline(lexer))
				block_name = restline[2:end-1]
				if !haskey(block_use_locations, block_name)
					block_use_locations[block_name] = "$paragraphnum"
				elseif !contains(block_use_locations[block_name], "$paragraphnum")
					block_use_locations[block_name] *= ", $paragraphnum"
				end
			end
		elseif t == "---"
			t = strip(advanceline(lexer))
			in_codeblock = true
			if t == ""
				in_codeblock = false
				continue
			end
			block_name = t
			if contains(block_name, "+=")
				block_name = strip(block_name[1:search(block_name, "+")[1]-1])
			end
			if !haskey(block_locations, block_name)
				block_locations[block_name] = "$paragraphnum"
			elseif !contains(block_locations[block_name], "$paragraphnum")
				block_locations[block_name] *= ", $paragraphnum"
			end
		end
	end
end

html = false
code = false

inputfiles = String[]
for arg in ARGS
	if arg == "-h"
		println("Usage: lit [-html] [-code] [file ...]")
		exit()
	elseif arg == "-html"
		html = true
	elseif arg == "-code"
		code = true
	else
		push!(inputfiles, arg)
	end
end

if !html && !code
	html = true
	code = true
end
