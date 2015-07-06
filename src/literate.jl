include("common.jl")

if length(inputfiles) == 0
	if html
		include("weave.jl")
		weave(STDIN, STDOUT)
	end

	if code
		include("tangle.jl")
		tangle(STDIN)
	end
else
	if html
		include("weave.jl")
		for file in inputfiles
			inputstream = open(file)
			outputstream = open("$(name(file)).html", "w")
			weave(inputstream, outputstream)
			close(inputstream)
			close(outputstream)
		end
	end

	if code
		include("tangle.jl")
		for file in inputfiles
			inputstream = open(file)
			tangle(inputstream)
			close(inputstream)
		end
	end
end
