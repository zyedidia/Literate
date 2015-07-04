include("common.jl")

function tangle(sourcefile)
	out = open("$(name(inputfile)).$codetype", "w")

	codeblocks = Dict{String, String}()

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
				codeblocks[block_name] = code
			end
		end
	end
	close(lexer)

	write_code("root", codeblocks, out)

	close(out)
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
