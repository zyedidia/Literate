.PHONY: examples

examples: wc.lit hangman.lit
	../bin/lit *.lit
	gcc wc.c -o wc

clean:
	rm -f *.html *.css *.py *.c *.pdf *.txt wc a.out SomeFile
	rm -rf _book
