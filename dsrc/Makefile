all:
	dub --root=tangle build
	../bin/tangle *.lit
	@mkdir -p ../source
	@mv *.d ../source
	@mkdir -p ../bin
	dub build --root=..
