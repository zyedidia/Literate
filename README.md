# Literate

[Website] (http://zbyedidia.webfactional.com/literate).

Literate (lit for short) is a computer programming system to create literate programs. It works with any programming language, generates HTML pages as output ([which can be converted to PDF](http://http://wkhtmltopdf.org/)),
and generates readable code. The code that is generated is indented properly and is commented using the names of codeblocks that you choose.

The goal of this project is to create a modern literate programming system which keeps most, if not all of the features of Knuth and Levy's CWEB system, but simplifies the system and adds even more features.

Literate source code is readable whether you are looking at the `.lit` file, or the generated HTML.

You can view the main website about Literate [here] (http://zbyedidia.webfactional.com/literate) including complete [documentation] (http://zbyedidia.webfactional.com/literate/manual.php).

If you want to see what features I am working on, check out my [Todolist](src/TodoList.txt).

# Installation

### Unix
The compiler is made with Lua. When you download the repository, run `./install.sh platform` where platform one of the following supported platforms: `linux` `macosx` `aix` `bsd` `c89` `generic` `posix` `solaris` and a local version of lua will be installed and used for Lit.

For example:

```
$ git clone https://github.com/zyedidia/Literate
$ cd Literate
$ ./install.sh macosx
```

Then make sure you add `path/to/Literate/bin` to your PATH.

In addition, if you would like an index to be generated, you must have exuberant or [universal ctags] (https://github.com/universal-ctags/ctags) installed. You can find instructions for installing with homebrew [here] (https://github.com/universal-ctags/homebrew-universal-ctags).

### Windows
Download the zip, or clone the repository, and just add path\to\Literate\bin to your
PATH. Index generation with ctags does not work with Windows yet.

# Usage

Add `path/to/Literate/bin` to your PATH and then you can generate html and/or code from `.lit` files.

```
$ lit examples/wc.lit
```

Additional command line flags are:

* -html: Only generate HTML output
* -code: Only generate code output
* -noindex: Do not create an index
* --out-dir=dir: Put the output files in the specified directory
* --no-output: Do not generate any files, only show errors

# Features
### In addition to those of CWEB
* Markdown based -- very easy to read and write Literate source.
* Generates readable and commented code in the target language (the generated code is usable by others)
* Supports any language including syntax highlighting and pretty printing in HTML
* Compatible with Vim ([literate.vim] (https://github.com/zyedidia/literate.vim))
* Highly customizable (you can add your own HTML or CSS)
* Runs fast -- wc.lit compiled for me in 82ms for both code and HTML output and 10ms for just code output
* Supports tex equations with `$` notation.

### Inspired from CWEB
* Automatically generates hyperlinks between code sections
* Formatted output similar to CWEB
* Creates an index with identifiers used (You need to have exuberant or universal ctags installed to use this feature)
