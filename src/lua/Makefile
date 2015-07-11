.PHONY: src

src: weave.lit tangle.lit literate.lit index.lit
	lua lit.lua -code *.lit

clean:
	rm -f *.html ../gen/*.html *.jl
