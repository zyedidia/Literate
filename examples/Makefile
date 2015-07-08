.PHONY: examples

examples: wc.lit hangman.lit
	../bin/lit *.lit
	gcc wc.c -o wc

wc: wc.c

clean:
	rm -f *.html
	rm -f *.jl
	rm -f *.c
	rm -f *.pdf
	rm -f wc
