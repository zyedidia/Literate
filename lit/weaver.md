@code_type d .d
@comment_type // %s
@compiler make debug -C ..
@error_format .*/%f\(%l,%s\):%s: %m

@title Weaver

# Introduction

Here is an overview of the weave program. This file turns a literate source
file into one or more Markdown files. The Markdown files created contain proper
cross references, references to code blocks and can be converted into HTML, PDF
or any other output formats by e.g. `pandoc`.

## weaver.d
```d
@{Imports}

void weave(Program p) {
    @{Parse use locations}
    @{Run weaveChapter}
    if (isBook && !noOutput) {
@{Create the table of contents}
    }
}

@{WeaveChapter}
@{LinkLocations function}
```

# Parsing Codeblocks

Now we parse the codeblocks across all chapters in the program. We
have four arrays:

* defLocations: stores the section in which a codeblock is defined.
* redefLocations: stores the sections in which a codeblock is redefined.
* addLocations: stores the sections in which a codeblock is added to.
* useLocations: stores the sections in which a codeblock is used;

## Parse use locations
```d
string[string] defLocations;
string[][string] redefLocations;
string[][string] addLocations;
string[][string] useLocations;

foreach (chapter; p.chapters) {
    foreach (s; chapter.sections) {
        foreach (block; s.blocks) {
            if (block.isCodeblock) {
                if (block.modifiers.canFind(Modifier.noWeave)) {
                    defLocations[block.name] = "noWeave";
                    continue;
                }

                @{Check if it's a root block}

                if (block.modifiers.canFind(Modifier.additive)) {
                    if (block.name !in addLocations || !addLocations[block.name].canFind(s.numToString()))
                        addLocations[block.name] ~= chapter.num() ~ ":" ~ s.numToString();
                } else if (block.modifiers.canFind(Modifier.redef)) {
                    if (block.name !in redefLocations || !redefLocations[block.name].canFind(s.numToString()))
                        redefLocations[block.name] ~= chapter.num() ~ ":" ~ s.numToString();
                } else {
                    defLocations[block.name] = chapter.num() ~ ":" ~ s.numToString();
                }

                foreach (lineObj; block.lines) {
                    string line = strip(lineObj.text);
                    if (line.startsWith("@{") && line.endsWith("}")) {
                        useLocations[line[2..$ - 1]] ~= chapter.num() ~ ":" ~ s.numToString();
                    }
                }
            }
        }
    }
}
```

Here we simply loop through all the chapters in the program and get the Markdown for them.
If `noOutput` is false, we generate Markdown files in the `outDir`.

## Run weaveChapter
```d
foreach (c; p.chapters) {
    string output = weaveChapter(c, p, defLocations, redefLocations,
                                 addLocations, useLocations);
    if (!noOutput) {
        string dir = outDir;
        if (isBook) {
            dir = outDir ~ "/_book";
            if (!dir.exists()) {
                mkdir(dir);
            }
        }
        File f = File(dir ~ "/" ~ stripExtension(baseName(c.file)) ~ "- woven.md", "w");
        f.write(output);
        f.close();
    }
}
```

# Table of contents

If the program being compiled is a book, we should also write a table of contents file.
The question is whether we need this feature when we drop the html output
completely... (Robert)

## Create the table of contents
```d
string dir = outDir ~ "/_book";
File f = File(dir ~ "/" ~ p.title ~ "_contents.md", "w");

f.writeln("# " ~ p.title);
f.writeln(p.text);

foreach (c; p.chapters) {
    f.writeln(c.num() ~ "[" ~ stripExtension(baseName(c.file)) ~ "]" ~ c.title);
}

f.close();
```

# Root block check

We check if the block is a root code block. We check this using
a regex that basically checks if it the name has an extension. Additionally,
users can put the block name in quotes to force it to be a root block.

If the block name is in quotes, we have to make sure to remove those once
we're done.

## Check if it's a root block
```d
auto fileMatch = matchAll(block.name, regex(".*\\.\\w+"));
auto quoteMatch = matchAll(block.name, regex("^\".*\"$"));
if (fileMatch || quoteMatch) {
    block.isRootBlock = true;
    if (quoteMatch) {
        block.name = block.name[1..$-1];
    }
}
```

# WeaveChapter

This function weaves a single chapter.

## WeaveChapter
```d
string weaveChapter(Chapter c, Program p, string[string] defLocations,
                    string[][string] redefLocations, string[][string] addLocations,
                    string[][string] useLocations) {

    string output = "";
    @{Write the body}
    return output;
}
```

# Parse the Chapter

Now we write the body -- this is the meat of the weaver. First we write
a couple things at the beginning: making sure the `prettyprint` function is
called when the page loads, and writing out the title as an `h1`.

Then we loop through each section in the chapter. At the beginning of each section,
we write the title, and an empty `a` link so that the section title can be linked to.
We also have to determine if the section title should be a `noheading` class. If the
section title is empty, then the class should be `noheading` which means that the prose
will be moved up a bit towards it -- otherwise it looks like there is too much empty space
between the title and the prose.

## Write the body
```d
foreach (s; c.sections) {
    output ~= c.num() ~ ":" ~ s.numToString() ~ s.numToString() ~ ". " ~ s.title ~ "\n";

    foreach (block; s.blocks) {
        if (!block.modifiers.canFind(Modifier.noWeave)) {
            if (!block.isCodeblock) {
                @{Weave a prose block}
            } else {
                @{Weave a code block}
            }
        }
    }

}
```

## Weave a prose block

Weaving a prose block is not very complicated. 


### Weave a prose block
```d
string md = "";

foreach (lineObj; block.lines) {
    auto l = lineObj.text;
    if (l.matchAll(regex(r"@\{.*?\}"))) {
        auto matches = l.matchAll(regex(r"@\{(.*?)\}"));
        foreach (m; matches) {
            auto def = "";
            auto defLocation = "";
            auto str = strip(m[1]);
            if (str !in defLocations) {
                error(lineObj.file, lineObj.lineNum, "{" ~ str ~ "} is never defined");
            } else if (defLocations[str] != "noWeave") {
                def = defLocations[str];
                defLocation = def;
                auto index = def.indexOf(":");
                string chapter = def[0..index];
                auto mdFile = getChapterMdFile(p.chapters, chapter);
                if (chapter == c.num()) {
                    defLocation = def[index + 1..$];
                }
                l = l.replaceAll(regex(r"@\{" ~ str ~ r"\}"), "`{" ~ str ~ ",`[`" ~ defLocation ~ "`](" ~ mdFile ~ "#" ~ def ~ ")`}`");
            }
        }
    }
    md ~= l ~ "\n";
}

```


Finally we add this html to the output and add a newline for good measure.

### Weave a prose block +=
```d
output ~= md ~ "\n";
```

## Weave a code block

### Weave a code block
```d
@{Write the title out}
@{Write the actual code}
@{Write the 'added to' links}
@{Write the 'redefined in' links}
@{Write the 'used in' links}
```

### The codeblock title

Here we create the title for the codeblock. For the title, we have to link
to the definition (which is usually the current block, but sometimes not
because of `+=`). We also need to make the title bold (`<strong>`) if it
is a root code block.

#### Write the title out
```d
@{Find the definition location}
@{Make the title bold if necessary}

output ~= "<span class=\"codeblock_name\">{" ~ name ~
          " <a href=\"" ~ htmlFile ~ "#" ~ def ~ "\">" ~ defLocation ~ "</a>}" ~ extra ~ "</span>\n";
```

To find the definition location we use the handy `defLocation` array that we made
earlier. The reason we have both the variables `def` and `defLocation` is because
the definition location might be in another chapter, in which case it should be
displayed as `chapterNum:sectionNum` but if it's in the current file, the `chapterNum`
can be removed. `def` gives us the real definition location, and `defLocation` is the
one that will be used -- it strips out the `chapterNum` if necessary.

#### Find the definition location
```d
string chapterNum;
string def;
string defLocation;
string htmlFile = "";
if (block.name !in defLocations) {
    error(block.startLine.file, block.startLine.lineNum, "{" ~ block.name ~ "} is never defined");
} else {
    def = defLocations[block.name];
    defLocation = def;
    auto index = def.indexOf(":");
    string chapter = def[0..index];
    htmlFile = getChapterHtmlFile(p.chapters, chapter);
    if (chapter == c.num()) {
        defLocation = def[index + 1..$];
    }
}
```

We also add the `+=` or `:=` if necessary. This needs to be the `extra` because
it goes outside the `{}` and is not really part of the name anymore.

#### Find the definition location +=
```d
string extra = "";
if (block.modifiers.canFind(Modifier.additive)) {
    extra = " +=";
} else if (block.modifiers.canFind(Modifier.redef)) {
    extra = " :=";
}
```

We simple put the title in in a strong tag if it is a root codeblock to make it bold.

#### Make the title bold if necessary
```d
string name;
if (block.isRootBlock) {
    name = "<strong>" ~ block.name ~ "</strong>";
} else {
    name = block.name;
}
```

### The actual code

At the beginning, we open the pre tag. If a codetype is defined, we tell the prettyprinter
to use that, otherwise, the pretty printer will try to figure out how to syntax highlight
on its own -- and it's pretty good at that.

#### Write the actual code
```d
if (block.codeType.split().length > 1) {
    if (block.codeType.split()[1].indexOf(".") == -1) {
        warn(block.startLine.file, 1, "@code_type extension must begin with a '.', for example: `@code_type c .c`");
    } else {
        output ~= "<pre class=\"prettyprint lang-" ~ block.codeType.split()[1][1..$] ~ "\">\n";
    }
} else {
    output ~= "<pre class=\"prettyprint\">\n";
}

foreach (lineObj; block.lines) {
    @{Write the line}
}
output ~= "</pre>\n";
```

Now we loop through each line. The only complicated thing here is if the line is
a codeblock use. Then we have to link to the correct definition location.

Also we escape all ampersands and greater than and less than signs before writing them.

#### Write the line
```d
string line = lineObj.text;
string strippedLine = strip(line);
if (strippedLine.startsWith("@{") && strippedLine.endsWith("}")) {
    @{Link a used codeblock}
} else {
    output ~= line.replace("&", "&amp;").replace(">", "&gt;").replace("<", "&lt;") ~ "\n";
}
```

For linking the used codeblock, it's pretty much the same deal as before. We
reuse the `def` and `defLocation` variables. We also write the final html as
a span with the `nocode` class, that way it won't be syntax highlighted by the
pretty printer.

#### Link a used codeblock
```d
def = "";
defLocation = "";
if (strip(strippedLine[2..$ - 1]) !in defLocations) {
    error(lineObj.file, lineObj.lineNum, "{" ~ strip(strippedLine[2..$ - 1]) ~ "} is never defined");
} else if (defLocations[strip(strippedLine[2..$ - 1])] != "noWeave") {
    def = defLocations[strippedLine[2..$ - 1]];
    defLocation = def;
    auto index = def.indexOf(":");
    string chapter = def[0..index];
    htmlFile = getChapterHtmlFile(p.chapters, chapter);
    if (chapter == c.num()) {
        defLocation = def[index + 1..$];
    }
    def = ", <a href=\"" ~ htmlFile ~ "#" ~ def ~ "\">" ~ defLocation ~ "</a>";
}
output ~= "<span class=\"nocode pln\">" ~ leadingWS(line) ~ "{" ~ strippedLine[2..$ - 1] ~ def ~ "}</span>\n";
```

### Add links to other sections

Writing the links is pretty similar to figuring out where a codeblock
was defined because we have access to the `sectionLocations` array (which is
`addLocations`, `useLocations`, or `redefLocations`). Then we just
have a few if statements to figure out the grammar -- where to put the `and`
and whether to have plurals and whatnot.

#### LinkLocations function
```d
T[] noDupes(T)(in T[] s) {
    import std.algorithm: canFind;
    T[] result;
    foreach (T c; s)
        if (!result.canFind(c))
            result ~= c;
    return result;
}

string linkLocations(string text, string[][string] sectionLocations, Program p, Chapter c, Section s, parser.Block block) {
    if (block.name in sectionLocations) {
        string[] locations = dup(sectionLocations[block.name]).noDupes;

        if (locations.canFind(c.num() ~ ":" ~ s.numToString())) {
            locations = remove(locations, locations.countUntil(c.num() ~ ":" ~ s.numToString()));
        }

        if (locations.length > 0) {
            string seealso = "<p class=\"seealso\">" ~ text;

            if (locations.length > 1) {
                seealso ~= "s ";
            } else {
                seealso ~= " ";
            }

            foreach (i; 0 .. locations.length) {
                string loc = locations[i];
                string locName = loc;
                auto index = loc.indexOf(":");
                string chapter = loc[0..index];
                string htmlFile = getChapterHtmlFile(p.chapters, chapter);
                if (chapter == c.num()) {
                    locName = loc[index + 1..$];
                }
                loc = "<a href=\"" ~ htmlFile ~ "#" ~ loc ~ "\">" ~ locName ~ "</a>";
                if (i == 0) {
                    seealso ~= loc;
                } else if (i == locations.length - 1) {
                    seealso ~= " and " ~ loc;
                } else {
                    seealso ~= ", " ~ loc;
                }
            }
            seealso ~= "</p>";
            return seealso;
        }
    }
    return "";
}
```

### See also links

Writing the 'added to' links is pretty similar to figuring out where a codeblock
was defined because we have access to the `addLocations` array. Then we just
have a few if statements to figure out the grammar -- where to put the `and`
and whether to have plurals and whatnot.

#### Write the 'added to' links
```d
output ~= linkLocations("Added to in section", addLocations, p, c, s, block) ~ "\n";
```

### Also used in links

This is pretty much the same as the 'added to' links except we use the
`useLocations` array.

#### Write the 'used in' links
```d
output ~= linkLocations("Used in section", useLocations, p, c, s, block) ~ "\n";
```

### Redefined in links

#### Write the 'redefined in' links
```d
output ~= linkLocations("Redefined in section", redefLocations, p, c, s, block) ~ "\n";
```

# Imports
```d
import globals;
import std.process;
import std.file;
import std.conv;
import std.algorithm;
import std.regex;
import std.path;
import std.stdio;
import std.string;
import parser;
import util;
import dmarkdown;
```
