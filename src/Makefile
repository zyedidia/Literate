src:
	../bin/lit -code --out-dir=../gen/ *.lit
	mv ../gen/lit.lua ../bin/
	mv ../bin/lit ../bin/.lit.bak
	mv ../bin/lit.lua ../bin/lit
	chmod +x ../bin/lit

html:
	../bin/lit -html --out-dir=../gen/ *.lit

clean:
	rm -f *.html ../gen/*.html *.lua
