# Literate

[Website] (http://zbyedidia.webfactional.com/literate).

Literate (lit for short) is a computer programming system to create literate programs. It works with any programming language, generates HTML pages as output (which can be converted to PDF by using your browser's 'print to pdf'),
and generates readable code. The code that is generated is indented properly and is commented using the names of codeblocks that you choose.

The goal of this project is to create a modern literate programming system which keeps most, if not all of the features of Knuth and Levy's CWEB system, but simplifies the system and adds even more features.

Literate source code is readable whether you are looking at the `.lit` file, or the generated HTML.

You can view the main website about Literate [here] (http://zbyedidia.webfactional.com/literate) including complete [documentation] (http://zbyedidia.webfactional.com/literate/manual.php).

If you want to see what features I am working on, check out my [Todolist](src/TodoList.txt).

# Installation

### Unix
If you're on a Mac and you have brew installed, you can use brew to install literate:

```
$ brew tap zyedidia/literate
$ brew install literate
```

If you want the `HEAD` version, you can use:

```
$ brew install --HEAD literate
```

If you don't want to use brew, you can install it manually:

The compiler is made with Lua, so please make sure you have lua installed before running Literate. You can download it [here] (http://www.lua.org/download.html). You can also install it with brew, apt-get, and yum.
In addition, there is a script that comes in the zip called `install_lua.sh`. This will install lua for you into the directory of your choice. You can install lua locally
or you can install it to `/usr/local/bin`

Once you have it installed, add `path/to/Literate/bin` to your `$PATH`

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
* -pdf: Create an HTML file with the correct fonts for printing to pdf (I recommend Chrome for printing to pdf)
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
* Supports TeX equations with `$` notation.

### Inspired from CWEB
* Automatically generates hyperlinks between code sections
* Formatted output similar to CWEB
* Creates an index with identifiers used (You need to have exuberant or universal ctags installed to use this feature)
