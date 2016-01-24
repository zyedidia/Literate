all:
	dub --root=dsrc/tangle build --build=release
	bin/tangle dsrc/*.lit
	@mkdir -p source
	@mv *.d source
	@mkdir -p bin
	dub build --build=release

not-release:
	dub --root=dsrc/tangle build
	bin/tangle dsrc/*.lit
	@mkdir -p source
	@mv *.d source
	@mkdir -p bin
	dub build
