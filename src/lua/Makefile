.PHONY: src

src: weave.lit tangle.lit literate.lit index.lit
	lit -code *.lit

clean:
	rm -f *.lua *.html ../gen/*.html *.jl
