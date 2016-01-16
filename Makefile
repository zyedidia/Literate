all:
	dub --root=dsrc/tangle build
	bin/tangle dsrc/*.lit
	@mkdir -p source
	@mv *.d source
	@mkdir -p bin
	dub build
