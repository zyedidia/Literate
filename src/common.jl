include("lexer.jl")

dir = dirname(Base.source_path())

codetype = ""
title = ""
block_paragraphs = Dict{String, String}()

function name(file)
	file[1:search(file, '.')-1]
end

function firstpass(sourcefile)
	lexer = Lexer(IOBuffer(sourcefile), [' ', '\n', '@'])
	paragraphnum = 0

	while (t = advance(lexer)) != EOF
		if t == "@"
			t = advance(lexer)
			if t == "codetype"
				advance(lexer)
				global codetype = advance(lexer)
			elseif t == "title"
				while (t = advance(lexer)) != "\n"
					global title *= t
				end
			elseif t == "p"
				paragraphnum += 1
			end
		elseif t == "---"
			t = advanceline(lexer)
			if strip(t) == ""
				continue
			end
			block_name = strip(t)
			if contains(block_name, "+=")
				block_name = strip(block_name[1:search(block_name, "+")[1]-1])
			end
			if !haskey(block_paragraphs, block_name)
				block_paragraphs[block_name] = "$paragraphnum"
			elseif !contains(block_paragraphs[block_name], "$paragraphnum")
				block_paragraphs[block_name] *= ", $paragraphnum"
			end
		end
	end
end

if length(ARGS) < 1
	println("No inputs")
	exit()
end

html = false
code = false

for arg in ARGS
	if arg == "-html"
		html = true
	elseif arg == "-code"
		code = true
	end
end

if length(ARGS) < 2
	html = true
	code = true
end

inputfile = ARGS[length(ARGS)]
