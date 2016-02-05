release:
	dub --root=dsrc/tangle build --build=release
	bin/tangle dsrc/*.lit
	@mkdir -p source
	@mv *.d source
	@mkdir -p bin
	dub build --build=release

debug:
	dub --root=dsrc/tangle build
	bin/tangle dsrc/*.lit
	@mkdir -p source
	@mv *.d source
	@mkdir -p bin
	dub build
