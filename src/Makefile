.PHONY: src

src: weave.lit tangle.lit literate.lit
	../bin/lit -code --out-dir=../gen weave.lit tangle.lit
	../bin/lit -code --out-dir=../bin literate.lit
	mv ../bin/lit ../bin/.lit.bak
	mv ../bin/lit.jl ../bin/lit
	chmod +x ../bin/lit
