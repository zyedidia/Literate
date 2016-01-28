# Literate

[Website] (http://zbyedidia.webfactional.com/literate).

Literate (lit for short) is a computer programming system to create literate programs. It works with any programming language, generates HTML pages as output (which can be converted to PDF by using your browser's 'print to pdf'),
and generates readable code. The code that is generated is indented properly and is commented using the names of codeblocks that you choose.

The goal of this project is to create a modern literate programming system which keeps most, if not all of the features of Knuth and Levy's CWEB system, but simplifies the system and adds even more features.

Literate source code is readable whether you are looking at the `.lit` file, or the generated HTML.

You can view the main website about Literate [here](http://zbyedidia.webfactional.com/literate) including a [manual](http://zbyedidia.webfactional.com/literate/manual.php) on how to use Literate.

If you like the project, make sure to leave a star :smile:

If you find any bugs in the software please report them here.

# Installation

### Mac

On Mac you can use brew to install Literate:

```
$ brew tap zyedidia/literate
$ brew install --HEAD literate
```

For now, Literate is head only.

### Building from Source
Literate is made with the [D programming language](http://dlang.org) so you must install [dmd](http://dlang.org/download.html#dmd) (D compiler) and [dub](https://code.dlang.org/download) (D package manager). Then you should download the zip or clone the repository and run the following commands:

```
$ cd Literate
$ make
```

You can find the binary in path/to/Literate/bin (you may want to add this to your path or move it to `/usr/local/bin`).

---

You might also want to go install the [Vim plugin](https://github.com/zyedidia/literate.vim) (it has syntax highlighting of the embedded code, linting with Neomake, and jumping to codeblock definitions). 
I'm sorry that no other editors are supported -- I don't know how to make plugins for other editors.

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

For more information see the [manual](http://zbyedidia.webfactional.com/literate/manual.php).

# Features
### In addition to those of CWEB
* Markdown based -- very easy to read and write Literate source.
* Generates readable and commented code in the target language (the generated code is usable by others)
* Reports syntax errors back from the compiler to the right line in the literate source
* Supports any language including syntax highlighting and pretty printing in HTML
* Compatible with Vim ([literate.vim] (https://github.com/zyedidia/literate.vim))
* Highly customizable (you can add your own HTML or CSS)
* Runs fast -- wc.lit compiled for me in 7ms for both code and HTML output
* Supports TeX equations with `$` notation.

### Inspired from CWEB
* Automatically generates hyperlinks between code sections
* Formatted output similar to CWEB
