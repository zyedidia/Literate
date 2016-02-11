release:
	@if [ ! -s dsrc/markdown/source ]; then \
		if [ ! -s .git ]; then \
			git clone https://github.com/zyedidia/dmarkdown dsrc/markdown; \
		else \
			git submodule init; \
			git submodule update; \
		fi \
	fi;
	dub --root=dsrc/tangle build
	bin/tangle dsrc/*.lit
	@mkdir -p source
	@mv *.d source
	@mkdir -p bin
	dub build --build=release

debug:
	@if [ ! -s dsrc/markdown/source ]; then \
		if [ ! -s .git ]; then \
			git clone https://github.com/zyedidia/dmarkdown dsrc/markdown; \
		else \
			git submodule init; \
			git submodule update; \
		fi \
	fi;
	@if [ ! -s bin/tangle ]; then \
		dub --root=dsrc/tangle build; \
	fi;
	bin/tangle dsrc/*.lit
	@mkdir -p source
	@mv *.d source
	@mkdir -p bin
	dub build

clean:
	dub clean
	dub clean --root=dsrc/markdown
	dub clean --root=dsrc/tangle

clean-all:
	dub clean
	dub clean --root=dsrc/markdown
	dub clean --root=dsrc/tangle
	rm -rf bin source
