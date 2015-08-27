src:
	../bin/lit -code main.lit
	mv lit.lua ../bin/lit
	chmod +x ../bin/lit

html:
	../bin/lit -html --out-dir=../gen/ *.lit

clean:
	rm -f *.html ../gen/*.html *.lua
