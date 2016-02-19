release: dsrc/markdown/source build
	dub build --build=release

debug: dsrc/markdown/source build
	dub build

bin/tangle:
	dub --root=dsrc/tangle build

build: bin/tangle
	bin/tangle dsrc/*.lit
	@mkdir -p source
	@mv *.d source
	@mkdir -p bin

test: build
	dub test

dsrc/markdown/source:
	@if [ ! -s dsrc/markdown/source ]; then \
		if [ ! -s .git ]; then \
			git clone https://github.com/zyedidia/dmarkdown dsrc/markdown; \
		else \
			git submodule init; \
			git submodule update; \
		fi \
	fi;

clean:
	dub clean
	dub clean --root=dsrc/markdown
	dub clean --root=dsrc/tangle

clean-all:
	dub clean
	dub clean --root=dsrc/markdown
	dub clean --root=dsrc/tangle
	rm -rf bin source
