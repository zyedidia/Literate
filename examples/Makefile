.PHONY: examples

examples: wc.lit hangman.lit
	../bin/lit *.lit
	gcc wc.c -o wc

clean:
	rm -f *.html *.jl *.c *.pdf wc
