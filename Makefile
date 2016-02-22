release: dsrc/markdown/source lit
	@mkdir -p bin
	dub build --build=release
	@rm bin/tangle

debug: dsrc/markdown/source lit
	@mkdir -p bin
	dub build

bin/tangle:
	dub --root=dsrc/tangle build

lit: bin/tangle
	@mkdir -p source
	bin/tangle -odir source dsrc/*.lit

test: lit
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
