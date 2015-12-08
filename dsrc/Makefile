all:
	../bin/tangle *.lit
	@mv *.d ../source
	mkdir -p ../bin
	dub build --root=..
