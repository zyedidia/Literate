all:
	/usr/local/bin/lit -code *.lit
	@mv *.d ../source
	mkdir -p ../bin
	dub build --root=..
