.PHONY: examples

examples: wc.lit hangman.lit
	../bin/lit wc.lit
	../bin/lit -noindex hangman.lit
	gcc wc.c -o wc

wc: wc.c

clean:
	rm -f *.html *.jl *.c *.pdf wc
