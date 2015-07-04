include("common.jl")

if html
	include("weave.jl")
end

if code
	include("tangle.jl")
end
