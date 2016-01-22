all:
	dub --root=dsrc/tangle build --build=release
	bin/tangle dsrc/*.lit
	@mkdir -p source
	@mv *.d source
	@mkdir -p bin
	dub build --build=release
