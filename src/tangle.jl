include("common.jl")

function tangle(sourcefile)

	codeblocks = Dict{String, String}()
	names = String[]

	lexer = Lexer(sourcefile, [' ', '\n'])
	while (t = advance(lexer)) != EOF
		if t == "---"
			t = advanceline(lexer)
			if strip(t) == ""
				continue
			end
			block_name = lowercase(strip(t))

			add_to_block = false
			if contains(block_name, "+=")
				block_name = strip(block_name[1:search(block_name, "+")[1]-1])
				add_to_block = true
			end
			code = ""
			while true
				c = advance(lexer)
				strip(c) == "---" && break
				code *= c
			end
			if add_to_block
				codeblocks[block_name] *= code
			else
				push!(names, block_name)
				codeblocks[block_name] = code
			end
		end
	end
	close(lexer)

	for name in names
		if endswith(name, ".$codetype")
			out = open("$name", "w")
			write_code("$name", codeblocks, out)
			close(out)
		end
	end
end

function write_code(blockname, codeblocks, out)
	blockname = lowercase(blockname)
	code = codeblocks[blockname]
	lines = split(code, "\n")

	for line in lines
		if startswith(strip(line), "@<")
			line = strip(line)
			write_code(line[3:end-1], codeblocks, out)
		else
			write(out, "$line\n")
		end
	end
end

sourcefile = readall(inputfile)
firstpass(sourcefile)
tangle(sourcefile)
