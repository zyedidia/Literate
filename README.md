# Literate

Literate (lit for short) is a computer programming system to create literate programs. It works with any language, and can generate HTML pages as output, that can also be converted to pdfs using [wkhtmltopdf] (http://wkhtmltopdf.org/).

The goal of this project is to create a modern literate programming system which keeps most, if not all of the features of Knuth and Levy's CWEB system, but simplifies the system and adds even more features.

You can view the main website about Literate [here] (cs12students.dce.harvard.edu/~zyedidia/project) including complete [documentation] (cs12students.dce.harvard.edu/~zyedidia/project/manual.php).

# Installation

The compiler is made with Lua. When you download the repository, run `./install.sh platform` where platform one of the following supported platforms: `aix` `bsd` `c89` `generic` `linux` `macosx` `mingw` `posix` `solaris` and a local version of lua will be installed and used for Lit.

For example:

```
$ git clone https://github.com/zyedidia/Literate
$ cd Literate
$ ./install.sh macosx
```

In addition, if you would like an index to be generated, you must have exuberant or [universal ctags] (https://github.com/universal-ctags/ctags) installed. You can find instructions for installing with homebrew [here] (https://github.com/universal-ctags/homebrew-universal-ctags).

# Usage

Add `path/to/Literate/bin` to your PATH and then you can generate html and/or code from `.lit` files.

```
$ lit [-html] [-code] examples/wc.lit
```

# Features
### In addition to those of CWEB
* Markdown based -- very easy to read and write Literate source.
* Generates readable code in the target language
* Supports any language including syntax highlighting and pretty printing in HTML
* Compatible with Vim ([literate.vim] (https://github.com/zyedidia/literate.vim))
* Highly customizable

### Inspired from CWEB
* Automatically generates hyperlinks between code sections
* Formatted output similar to CWEB
* Creates an index with identifiers used (You need to have exuberant or universal ctags installed to use this feature)
