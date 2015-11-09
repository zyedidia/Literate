all:
	lit -t *.lit
	@mv *.d ../source
	mkdir -p ../bin
	dub build --root=..
