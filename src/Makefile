.PHONY: src

src: weave.lit tangle.lit literate.lit index.lit
	../bin/lit -code --out-dir=../gen weave.lit tangle.lit index.lit
	../bin/lit -code --out-dir=../bin literate.lit
	mv ../bin/lit ../bin/.lit.bak
	mv ../bin/lit.jl ../bin/lit
	chmod +x ../bin/lit

clean:
	rm -f *.jl
	rm -f *.html
	rm -f ../gen/*.html
