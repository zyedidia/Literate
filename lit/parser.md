@code_type d .d
@comment_type // %s
@compiler make debug -C ..
@error_format .*/%f\(%l,%s\):%s: %m

@title Parser

# Introduction

This is an implementation of a literate programming system in D.
The goal is to be able to create books that one can read on a website,
with chapters, subchapters, and sections, and additionally to be able
to compile the code from the book into a working program.

Literate programming aims to make the source code of a program
understandable. The program can be structured in any way the
programmer likes, and the code should be explained.

The source code for a literate program will somewhat resemble
CWEB, but differ in many key ways which simplify the source code
and make it easier to read. Literate will use @ signs for commands
and markdown to style the prose.

# Directory Structure

A Literate program may be just a single file, but it should also be
possible to make a book out of it, with chapters and possibly multiple
programs in a single book. If the literate command line tool is run on
a single file, it should compile that file, if it is run on a directory,
it should search for the `Summary.md` file in the directory and create a
book.

What should the directory structure of a Literate book look like?
I try to mimic the [Gitbook](https://github.com/GitbookIO/gitbook) software
here. There will be a `Summary.md` file which links to each of the
different chapters in the book. An example `Summary.md` file might look
like this:

    @title Title of the book

    [Chapter 1](chapter1/intro.md)
        [Subchapter 1](chapter1/example1.md)
        [Subchapter 2](chapter1/example2.md)
    [Chapter 2](section2/intro.md)
        [Subchapter 1](chapter2/example1.md)

Sub chapters are denoted by tabs, and each chapter is linked to the correct
`.lit` file using Markdown link syntax.

# The Parser

As a first step, I'll make a parser for single chapters only, and leave having
multiple chapters and books for later.

The parser will have 2 main parts to it: the which represent the various structures
in a literate program, and the parse function.

## parser.d
```d
@{Imports}
@{Classes}
@{Parse functions}
```

I'll quickly list the imports here.

## Imports
```d
import globals;
import std.stdio;
import util;
import std.string: split, endsWith, startsWith, chomp, replace, strip;
import std.algorithm: canFind;
import std.regex: matchAll, matchFirst, regex, ctRegex, splitter;
import std.conv;
import std.path: extension;
import std.file;
import std.array;
```

# Classes

Now we have to define the classes used to represent a literate program. There
are 7 such classes:

```d
@{Line class}
@{Command class}
@{Block class}
@{Section class}
@{Chapter class}
@{Program class}
@{Change class}
```

## The Program Class

What is a literate program at the highest level? A program has multiple chapters,
it has a title, and it has various commands associated with it (although some of these
commands may be overwritten by chapters or even sections). It also has the file it
originally came from.

### Program class
```d
class Program {
    public string title;
    public Command[] commands;
    public Chapter[] chapters;
    public string file;
    public string text;

    this() {
        commands = [];
        chapters = [];
    }
}
```

## The Chapter class

A chapter is very similar to a program. It has a title, commands, sections, and also
an original file. In the case of a single file program (which is what we are focusing
on for the moment) the Program's file and the Chapter's file will be the same. A chapter
also has a minor number and a major number;

### Chapter class
```d
class Chapter {
    public string title;
    public Command[] commands;
    public Section[] sections;
    public string file;

    public int majorNum;
    public int minorNum;

    this() {
        commands = [];
        sections = [];
    }

    string num() {
        if (minorNum != 0) {
            return to!string(majorNum) ~ "." ~ to!string(minorNum);
        } else {
            return to!string(majorNum);
        }
    }
}
```

## The Section class

A section has a title, commands, a number, and a series of blocks, which can either be
blocks of code, or blocks of prose.

We also attribute a level to sections which allows us to appear our
sections be organized hierarchically. Six levels are supported at the
moment; in the final document these are translated to HTML tags `<h1>`
to `<h6>`.

Accordingly, the section number is an array of six numbers in fact. Two
support functions are needed to handle the number array seamlessly:

* First we need a function to convert this array to a string - the `numToString`
  class method does this for us. The only trick we need to consider here is not
  to include trailing zeros to our result string.

* Second, we need a function to increase the numbering according to the section's
  level. The `increaseSectionNum` function called during chapter parsing (i.e.
  in the `parseChapter` call) is responsible for this (for more details see the
  description of `parseChapter`).

### Section class

```d
class Section {
    public string title;
    public Command[] commands;
    public Block[] blocks;
    public int[6] num;
    public int level;

    this() {
        commands = [];
        blocks = [];
    }

    string numToString() {
        string numString;
        for(int i = 5; i >= 0; i--) {
            if (numString == "" && num[i] == 0) {
                continue;
            }
            numString = to!string(num[i]) ~ (numString == "" ? "" : ".") ~ numString;
        }
        return numString;
    }
}
```

## The Block Class

A block is more interesting. It can either be a block of code, or a block of prose, so
it has a boolean which represents what type it is. It also stores a start line. If it
is a code block, it also has a name. Finally, it stores an array of lines, and has a function
called `text()` which just returns the string of the text it contains. A block also contains
a `codeType` and a `commentString`.

### Block class
```d
class Block {
    public Line startLine;
    public string name;
    public bool isCodeblock;
    public bool isRootBlock;
    public Line[] lines;

    public string codeType;
    public string commentString;

    public Modifier[] modifiers;

    this() {
        lines = [];
        modifiers = [];
    }

    string text() {
        string text = "";
        foreach (line; lines) {
            text ~= line.text ~ "\n";
        }
        return text;
    }

    Block dup() {
        Block b = new Block();
        b.startLine = startLine;
        b.name = name;
        b.isCodeblock = isCodeblock;
        b.codeType = codeType;
        b.commentString = commentString;
        b.modifiers = modifiers;

        foreach (Line l; lines) {
            b.lines ~= l.dup();
        }

        return b;
    }
}
```

## The Command Class

A command is quite simple. It has a name, and any arguments that are passed.

### Command class
```d
class Command {
    public string name;
    public string args;
    public int lineNum;
    public string filename;
    this() {}
}
```

## The Line Class

A line is the lowest level. It stores the line number, the file the line is from, and the
text for the line itself.

### Line class

```d
class Line {
    public string file;
    public int lineNum;
    public string text;

    this(string text, string file, int lineNum) {
        this.text = text;
        this.file = file;
        this.lineNum = lineNum;
    }

    Line dup() {
        return new Line(text, file, lineNum);
    }
}
```

## The Change Class

The change class helps when parsing a change statement. It stores the file that is being changed,
what the text to search for is and what the text to replace it with is. These two things are arrays
because you can make multiple changes (search and replaces) to one file. In order to
keep track of the current change, an index is also stored.

### Change class
```d
class Change {
    public string filename;
    public string[] searchText;
    public string[] replaceText;
    public int index;

    this() {
        searchText = [];
        replaceText = [];
        index = 0;
    }
}
```

That's it for the classes. These 7 classes can be used to represent an entire literate program.
Now let's get to the actual parse function to turn a text file into a program.

## The Parse Function

Here we have two functions: `parseProgram` and `parseChapter`.

### Parse functions
```d
@{parseProgram function}
@{parseChapter function}
```

### parseProgram function

This function takes a literate book source and parses each chapter and returns the final program.

Here is an example book:

    @title Title of the book

    [Chapter 1](chapter1/intro.lit)
        [Subchapter 1](chapter1/example1.lit)
        [Subchapter 2](chapter1/example2.lit)
    [Chapter 2](section2/intro.lit)
        [Subchapter 1](chapter2/example1.lit)

#### parseProgram function
```d
Program parseProgram(Program p, string src) {
    string filename = p.file;
    bool hasChapters;

    string[] lines = src.split("\n");
    int lineNum;
    int majorNum;
    int minorNum;
    foreach (line; lines) {
        lineNum++;

        if (line.startsWith("@title")) {
            p.title = strip(line[6..$]);
        } else if (line.startsWith("@book")) {
            continue;
        } else if (auto matches = matchFirst(line, regex(r"\[(?P<chapterName>.*)\]\((?P<filepath>.*)\)"))) {
            if (matches["filepath"] == "") {
                error(filename, lineNum, "No filepath for " ~ matches["chapterName"]);
                continue;
            }
            if (leadingWS(line).length > 0) {
                minorNum++;
            } else {
                majorNum++;
                minorNum = 0;
            }
            Chapter c = new Chapter();
            c.file = matches["filepath"];
            c.title = matches["chapterName"];
            c.majorNum = majorNum;
            c.minorNum = minorNum;

            p.chapters ~= parseChapter(c, readall(File(matches["filepath"])));
            hasChapters = true;
        } else {
            p.text ~= line ~ "\n";
        }
    }

    return p;
}
```

### parseChapter function

The `parseChapter` function is the more complex one. It parses the source of a chapter.
Before doing any parsing, we resolve the `@include` statements by replacing them with
the contents of the file that was included. Then we loop through each line in the source
and parse it, provided that it is not a comment (starting with `//`);


#### parseChapter function
```d
Chapter parseChapter(Chapter chapter, string src) {
    @{Initialize some variables}
    @{Increase section number}

    string[] blocks = [];

    string include(string file) {
        if (file == filename) {
            error(filename, 1, "Recursive include");
            return "";
        }
        if (!exists(file)){
            error(filename, 1, "File " ~ file ~ " does not exist");
            return "";
        }
        return readall(File(file));
    }

    // Handle the @include statements
    /* src = std.regex.replaceAll!(match => include(match[1]))(src, regex(`\n@include (.*)`)); */
    string[] linesStr = src.split("\n");
    Line[] lines;
    foreach (lineNum, line; linesStr) {
        lines ~= new Line(line, filename, cast(int) lineNum+1);
    }

    for (int j = 0; j < lines.length; j++) {
        auto lineObj = lines[j];
        filename = lineObj.file;
        auto lineNum = lineObj.lineNum;
        auto line = lineObj.text;

        if (strip(line).startsWith("//") && !inCodeblock) {
            continue;
        }

        @{Parse the line}
    }
    @{Close the last section}

    return chapter;
}
```

### The Parse Function Setup

For the initial variables, it would be nice to move the value for `chapter.file` into a variable
called `filename`. Additionally, I'm going to need an array of all the possible commands that
are recognized.

#### Initialize some variables
```d
string filename = chapter.file;
string[] commands = ["@code_type", "@comment_type", "@compiler", "@error_format",
                     "@add_css", "@overwrite_css", "@colorscheme", "@include"];
```

I also need to keep track of the current section that is being parsed, and the current block that
is being parsed, because the parser is going through the file one line at a time. I'll also define
the current change being parsed.

#### Initialize some variables +=
```d
Section curSection;
int[6] sectionNum = [0, 0, 0, 0, 0, 0];
Block curBlock;
Change curChange;
```

Finally, I need 3 flags to keep track of if it is currently parsing a codeblock, a search block,
or a replace block.

#### Initialize some variables +=
```d
bool inCodeblock = false;
bool inSearchBlock = false;
bool inReplaceBlock = false;
```

### Parsing the Line

When parsing a line, we are either inside a code block, or inside a prose block, or we are transitioning
from one to the other. So we'll have an if statement to separate the two.

#### Parse the line
```d
if (!inCodeblock) {
    // This might be a change block
    @{Parse change block}
    @{Parse a command}
    @{Parse a title command}
    @{Parse a section definition}
    @{Parse the beginning of a code block}
    else if (curBlock !is null) {
        if (line.split().length > 1) {
            if (commands.canFind(line.split()[0])) {
                continue;
            }
        }
        @{Add the line to the list of lines}
    }
} else if (startsWith(line, "```")) {
    @{Begin a new prose block}
} else if (curBlock !is null) {
    @{Add the line to the list of lines}
}
```

Parsing a command and the title command are both fairly simple, so let's look at them first.

To parse a command we first make sure that there is the command name, and any arguments.
Then we check if the command is part of the list of commands we have. If it is, we
create a new command object, fill in the name and arguments, and add it to the chapter object.

We also do something special if it is a `@include` command. For these ones, we take the file
read it, and parse it as a chapter (using the `parseChapter` function). Then we add the
included chapter's sections to the current chapter's sections. In this case, we don't add
the `@include` command to the list of chapter commands.

#### Parse a command
```d
if (line.split().length > 1) {
    if (commands.canFind(line.split()[0])) {
        Command cmd = new Command();
        cmd.name = line.split()[0];
        auto index = cmd.name.length;
        cmd.args = strip(line[index..$]);
        cmd.lineNum = lineNum;
        cmd.filename = filename;
        if (cmd.args == "none") {
            cmd.args = "";
        }

        if (cmd.name == "@include") {
            Line[] includedLines;
            string fileSrc = readall(File(cmd.args));
            foreach (includedLineNum, includedLine; fileSrc.split("\n")) {
                auto includedLineObj = new Line(includedLine, cmd.args, cast(int) includedLineNum + 1);
                includedLines ~= includedLineObj;
            }
            if (includedLines.length > 0) {
                lines = lines[0 .. lineNum] ~ includedLines ~ lines[lineNum .. $];
            }
        }

        if (curSection is null) {
            chapter.commands ~= cmd;
        } else {
            curSection.commands ~= cmd;
        }
    }
}
```

Parsing an `@title` command is even simpler.

#### Parse a title command
```d
if (startsWith(line, "@title")) {
    chapter.title = strip(line[6..$]);
}
```

### Parsing a Section Definition

When a new section is created (using `#` .. `######`), we should add the current section to the list
of sections for the chapter, and then we should create a new section, which becomes the
current section.

#### Parse a section definition
```d
else if (line.startsWith("#")) {
    if (curBlock !is null && !curBlock.isCodeblock) {
        if (strip(curBlock.text()) != "") {
            curSection.blocks ~= curBlock;
        }
    } else if (curBlock !is null && curBlock.isCodeblock) {
        error(curBlock.startLine.file, curBlock.startLine.lineNum, "Unclosed block {" ~ curBlock.name ~ "}");
    }
    // Make sure the section exists
    if (curSection !is null) {
        chapter.sections ~= curSection;
    }
    int hashMarkCounter = 0;
    while (line.startsWith("#")) {
        hashMarkCounter++;
        line.popFront();
    }
    if (hashMarkCounter > 6) {
        error(filename, lineNum, "Too many hashmarks");
    }
    curSection = new Section();
    curSection.title = strip(line);
    curSection.level = hashMarkCounter - 1;
    curSection.commands = chapter.commands ~ curSection.commands;
    increaseSectionNum(curSection.level);
    curSection.num = sectionNum;

    curBlock = new Block();
    curBlock.isCodeblock = false;
}
```

Section number increase - since we support six levels of sections to have a
hierarchical structure even inside a chapter - depends on the section's level.
When we increase the number of a certain level, all lower levels need to be
zeroed out. The `increaseSectionNum` function does this job for us.

#### Increase section number
```d
void increaseSectionNum(int level) {
    if (level > 5) {
        throw new Exception("Levels higher than 5 are not supported in 'increaseSectionNum'");
    }
    for (int i = 5; i > level; i--) {
        sectionNum[i] = 0;
    }
    sectionNum[level]++;
}
```

### Parse the Start of a Codeblock

Codeblocks always begin with three backticks, so we can use a pproper regex to represent this.
Once a new codeblock starts, the old one must be appended to the current section's list of
blocks, and the current codeblock must be reset.

#### Parse the beginning of a code block
```d
else if (matchAll(line, regex("^```.+"))) {
    if (curSection is null) {
        error(chapter.file, lineNum, "You must define a section with # before writing a code block");
        continue;
    }

    if (curBlock !is null) {
        curSection.blocks ~= curBlock;
    }
    curBlock = new Block();
    curBlock.startLine = lineObj;
    curBlock.isCodeblock = true;
    curBlock.name = curSection.title;

    @{Parse Modifiers}

    if (blocks.canFind(curBlock.name)) {
        if (!curBlock.modifiers.canFind(Modifier.redef) && !curBlock.modifiers.canFind(Modifier.additive)) {
            error(filename, lineNum, "Redefinition of {" ~ curBlock.name ~ "}, use ':=' to redefine");
        }
    } else {
        blocks ~= curBlock.name;
    }

    foreach (cmd; curSection.commands) {
        if (cmd.name == "@code_type") {
            curBlock.codeType = cmd.args;
        } else if (cmd.name == "@comment_type") {
            if (curBlock.name.endsWith(" noComment")) {
                curBlock.name = curBlock.name[0..$-10];
                curBlock.commentString = "";
            } else {
                curBlock.commentString = cmd.args;
            }
        }
    }

    inCodeblock = true;
}
```

### Check for and extract modifiers.

Modifier format for a code block: `--- Block Name --- noWeave +=`.
The `checkForModifiers` ugliness is due to lack of `(?|...)` and friends.

First half matches for expressions *with* modifiers:

1. `(?P<namea>\S.*)` : Keep taking from the first non-whitespace character ...
2. `[ \t]-{3}[ \t]` : Until it matches ` --- `
3. `(?P<modifiers>.+)` : Matches everything after the separator.

Second half matches for no modifiers: Ether `Block name` and with a floating separator `Block Name ---`.

1. `|(?P<nameb>\S.*?)` : Same thing as #1 but stores it in `nameb`
2. `[ \t]*?` : Checks for any amount of whitespace (Including none.)
3. `(-{1,}$` : Checks for any floating `-` and verifies that nothing else is there untill end of line.
4. `|$))` : Or just checks that there is nothing but the end of the line after the whitespace.

Returns ether `namea` and `modifiers` or just `nameb`.

#### Parse Modifiers
```d
auto checkForModifiers = ctRegex!(`(?P<namea>\S.*)[ \t]-{3}[ \t](?P<modifiers>.+)|(?P<nameb>\S.*?)[ \t]*?(-{1,}$|$)`);
auto splitOnSpace = ctRegex!(r"(\s+)");
auto modMatch = matchFirst(curBlock.name, checkForModifiers);

// matchFirst returns unmatched groups as empty strings

if (modMatch["namea"] != "") {
    curBlock.name = modMatch["namea"];
} else if (modMatch["nameb"] != ""){
    curBlock.name = modMatch["nameb"];
    // Check for old syntax.
    if (curBlock.name.endsWith("+=")) {
        curBlock.modifiers ~= Modifier.additive;
        curBlock.name = strip(curBlock.name[0..$-2]);
    } else if (curBlock.name.endsWith(":=")) {
        curBlock.modifiers ~= Modifier.redef;
        curBlock.name = strip(curBlock.name[0..$-2]);
    }
} else {
    error(filename, lineNum, "Something went wrong with: " ~ curBlock.name);
}

if (modMatch["modifiers"]) {
    foreach (m; splitter(modMatch["modifiers"], splitOnSpace)) {
        switch(m) {
            case "+=":
                curBlock.modifiers ~= Modifier.additive;
                break;
            case ":=":
                curBlock.modifiers ~= Modifier.redef;
                break;
            case "noWeave":
                curBlock.modifiers ~= Modifier.noWeave;
                break;
            case "noTangle":
                curBlock.modifiers ~= Modifier.noTangle;
                break;
            default:
                error(filename, lineNum, "Invalid modifier: " ~ m);
                break;
        }
    }

}
```

### Parse the End of a Codeblock

Codeblocks end with just a three backticks. When a codeblock ends, we do the same as when it begins,
except the new block we create is a block of prose as opposed to code.

#### Begin a new prose block
```d
if (curBlock !is null) {
    curSection.blocks ~= curBlock;
}
curBlock = new Block();
curBlock.startLine = lineObj;
curBlock.isCodeblock = false;
inCodeblock = false;
```

### Add the current line

Finally, if the current line is nothing interesting, we just add it to the current block's
list of lines.

#### Add the line to the list of lines
```d
curBlock.lines ~= new Line(line, filename, lineNum);
```

Now we're done parsing the line.

### Closing the last section

When the end of the file is reached, the last section has not been closed and added to the
chapter yet, so we should do that. Additionally, if the last block is a prose block, it should
be closed and added to the section first. If the last block is a code block, it should have been
closed with three backticks. If it wasn't we'll throw an error.

#### Close the last section
```d
if (curBlock !is null) {
    if (!curBlock.isCodeblock) {
        curSection.blocks ~= curBlock;
    } else {
        writeln(filename, ":", lines.length - 1, ":error: {", curBlock.name, "} is never closed");
    }
}
if (curSection !is null) {
    chapter.sections ~= curSection;
}
```

### Parsing the change block

Parsing a change block is somewhat complex. Change blocks look like this:

    @change file.lit

    Some comments here...

    @replace
    replace this text
    @with
    with this text
    @end

    More comments ...

    @replace
    ...
    @with
    ...
    @end

    ...

    @change_end

You can make multiple changes on one file. We've got two nice flags for keeping track of
which kind of block we are in: replaceText or searchText.

#### Parse change block
```d
// Start a change block
if (startsWith(line, "@change") && !startsWith(line, "@change_end")) {
    curChange = new Change();
    curChange.filename = strip(line[7..$]);
    continue;
} else if (startsWith(line, "@replace")) {
    // Begin the search block
    curChange.searchText ~= "";
    curChange.replaceText ~= "";
    inReplaceBlock = false;
    inSearchBlock = true;
    continue;
} else if (startsWith(line, "@with")) {
    // Begin the replace block and end the search block
    inReplaceBlock = true;
    inSearchBlock = false;
    continue;
} else if (startsWith(line, "@end")) {
    // End the replace block
    inReplaceBlock = false;
    inSearchBlock = false;
    // Increment the number of changes
    curChange.index++;
    continue;
} else if (startsWith(line, "@change_end")) {
    // Apply all the changes
    string text = readall(File(curChange.filename));
    foreach (i; 0 .. curChange.index) {
        text = text.replace(curChange.searchText[i], curChange.replaceText[i]);
    }
    Chapter c = new Chapter();
    c.file = curChange.filename;
    // We can ignore these, but they need to be initialized
    c.title = "";
    c.majorNum = -1;
    c.minorNum = -1;
    Chapter includedChapter = parseChapter(c, text);
    // Overwrite the current file's title and add to the commands and sections
    chapter.sections ~= includedChapter.sections;
    chapter.commands ~= includedChapter.commands;
    chapter.title = includedChapter.title;
    continue;
}

// Just add the line to the search or replace text depending
else if (inSearchBlock) {
    curChange.searchText[curChange.index] ~= line ~ "\n";
    continue;
} else if (inReplaceBlock) {
    curChange.replaceText[curChange.index] ~= line ~ "\n";
    continue;
}
```
