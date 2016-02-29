# Literate

## What is Literate programming?

Literate programming is a style of programming invented by Donald Knuth, where the main idea is that a program's source code is made primarily to be read and understood by other people, and secondarily to be executed by the computer.

This frees the programmer from the structure of a program imposed by the computer and means that the programmer can develop programs in the order of the flow of their thoughts.

A Literate program generally consists of explanation of the code in a natural language such as English, interspersed with snippets of code to be executed. This means that Literate programs are very easy to understand and share, as all the code is well explained.

---

Literate is a tool for creating literate programs.

The goal of this project is to create a literate programming tool which keeps most, if not all of the features of Knuth and Levy's original CWEB system, but simplifies the system and adds even more features.

You can view the main website about Literate [here](http://literate.zbyedidia.webfactional.com) including a [manual](http://literate.zbyedidia.webfactional.com/manual.php) on how to use Literate.

If you like the project, make sure to leave a star :smile:

## Features

* Supports any language including syntax highlighting and pretty printing in HTML
* Markdown based -- very easy to read and write Literate source.
* Reports syntax errors back from the compiler to the right line in the literate source
* Generates readable and commented code in the target language (the generated code is usable by others)
* Supports TeX equations with `$` notation.
* Literate source code is readable whether you are looking at the `.lit` file, or the generated HTML.
* Highly customizable (you can add your own HTML or CSS)
* Runs fast -- wc.lit compiled for me in 7ms for both code and HTML output
* Automatically generates hyperlinks between code sections
* Formatted output similar to CWEB
* Compatible with Vim ([literate.vim] (https://github.com/zyedidia/literate.vim))

## Example

Here is a trivial example of a literate program saved in the file `hello.lit`.

```
@title Hello world in C

@s Introduction

This is an example hello world C program.
We can define codeblocks with `---`

--- hello.c
@{Includes}

int main() {
    @{Print a string}
    return 0;
}
---

Now we can define the `Includes` codeblock:

--- Includes
#include <stdio.h>
---

Finally, our program needs to print "hello world"

--- Print a string
printf("hello world\n");
---
```

To compile this code simply run

`$ lit hello.lit`

Which generates [hello.c](http://literate.zbyedidia.webfactional.com/examples/hello.c) and [hello.html](http://literate.zbyedidia.webfactional.com/examples/hello.html).

You can also find this program in `examples/hello.lit`.

For a full example of a literate program, please see [`examples/wc.lit`](https://github.com/zyedidia/Literate/blob/master/examples/wc.lit) which
is a literate implementation of the `wc` (word count) program found on Unix systems.
You can find the compiled html [here](http://literate.zbyedidia.webfactional.com/examples/wc.html).

## Installation

### Prebuilt binaries

| Download |
| --- |
| [Mac OS X](http://literate.zbyedidia.webfactional.com/binaries/literate-osx.tar.gz) |
| [64 bit Linux](http://literate.zbyedidia.webfactional.com/binaries/literate-linux64.tar.gz) |
| [32 bit Linux](http://literate.zbyedidia.webfactional.com/binaries/literate-linux32.tar.gz) |
| [Arm Linux](http://literate.zbyedidia.webfactional.com/binaries/literate-linux-arm.tar.gz) |

### Building from Source

#### Mac

On Mac you can use brew to build Literate from source:

```
$ brew tap zyedidia/literate
$ brew install --HEAD literate
```

For now, Literate is head only.

---

Literate is made with the [D programming language](http://dlang.org) so you must install [dmd](http://dlang.org/download.html#dmd) (D compiler) and [dub](https://code.dlang.org/download) (D package manager). Then you should download the zip or clone the repository and run the following commands:

```
$ cd Literate
$ make
```

You can find the binary in path/to/Literate/bin (you may want to add this to your path or move it to `/usr/local/bin`).

### The Vim Plugin

You might also want to go install the [Vim plugin](https://github.com/zyedidia/literate.vim) (it has syntax highlighting of the embedded code, linting with Neomake, and jumping to codeblock definitions). 
I'm sorry that no other editors are supported -- I don't know how to make plugins for other editors.

## Usage

```
Lit: Literate Programming System

Usage: lit [options] <inputs>

Options:
--help    -h          Show this help text
--tangle  -t          Only compile code files
--weave   -w          Only compile HTML files
--no-output           Do not generate any output files
--out-dir -odir DIR   Put the generated files in DIR
--compiler            Report compiler errors (needs @compiler to be defined)
```

For more information see the [manual](http://literate.zbyedidia.webfactional.com/manual.php).

## Contributing

Literate is written in Literate D and you can find the source code in the `lit` directory. You can also read the source code compiled by Literate [here](http://literate.zbyedidia.webfactional.com/literate-source).
I am happy to accept pull requests, and if you find any bugs, please report them. Thanks!
