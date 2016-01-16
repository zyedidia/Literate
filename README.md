# Literate

[Website] (http://zbyedidia.webfactional.com/literate).

Literate (lit for short) is a computer programming system to create literate programs. It works with any programming language, generates HTML pages as output (which can be converted to PDF by using your browser's 'print to pdf'),
and generates readable code. The code that is generated is indented properly and is commented using the names of codeblocks that you choose.

The goal of this project is to create a modern literate programming system which keeps most, if not all of the features of Knuth and Levy's CWEB system, but simplifies the system and adds even more features.

Literate source code is readable whether you are looking at the `.lit` file, or the generated HTML.

You can view the main website about Literate [here] (http://zbyedidia.webfactional.com/literate) including complete [documentation] (http://zbyedidia.webfactional.com/literate/manual.php).

If you like the project, make sure to leave a star :smile:

# Installation

### Building from Source
Literate is made with the [D programming language](http://dlang.org) so you must install dmd (D compiler) and dub (D package manager). Then you should download the zip or clone the repository and run the following commands:

$ cd Literate/dsrc
$ make

You can find the binary in path/to/Literate/bin (you may want to add this to your path).

# Usage

Add `path/to/Literate/bin` to your PATH and then you can generate html and/or code from `.lit` files.

```
$ lit examples/wc.lit
```

Additional command line flags are:

* --weave -w: Only generate HTML output
* --tangle -t: Only generate code output
* --out-dir -odir DIR: Put the output files in the specified directory
* --no-output: Do not generate any files, only show errors
* --compiler: Run the `@compiler` command

# Features
### In addition to those of CWEB
* Markdown based -- very easy to read and write Literate source.
* Generates readable and commented code in the target language (the generated code is usable by others)
* Supports any language including syntax highlighting and pretty printing in HTML
* Compatible with Vim ([literate.vim] (https://github.com/zyedidia/literate.vim))
* Highly customizable (you can add your own HTML or CSS)
* Runs fast -- wc.lit compiled for me in 7ms for both code and HTML output
* Supports TeX equations with `$` notation.

### Inspired from CWEB
* Automatically generates hyperlinks between code sections
* Formatted output similar to CWEB
