// parser.d
// Imports
import std.stdio;
import util;
import main;
import std.string: split, endsWith, startsWith, chomp, replace, strip;
import std.algorithm: canFind;
import std.regex;
import std.conv;
import std.path: extension;
import std.file;

// Classes
// Line class
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

// Command class
class Command {
    public string name;
    public string args;
    this() {}
}

// Block class
class Block {
    public int startLine;
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

// Section class
class Section {
    public string title;
    public Command[] commands;
    public Block[] blocks;
    public int num;

    this() {
        commands = [];
        blocks = [];
    }
}

// Chapter class
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

// Program class
class Program {
    public string title;
    public Command[] commands;
    public Chapter[] chapters;
    public string file;

    this() {
        commands = [];
        chapters = [];
    }
}

// Change class
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


// Parse functions
// parseProgram function
Program parseProgram(Program p, string src) {
    string filename = p.file;

    string[] lines = src.split("\n");
    int lineNum;
    int majorNum;
    int minorNum;
    foreach (line; lines) {
        lineNum++;

        if (line.startsWith("@title")) {
            p.title = strip(line[6..$]);
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
        }
    }

    return p;
}

// parseChapter function
Chapter parseChapter(Chapter chapter, string src) {
    // Initialize some variables
    string filename = chapter.file;
    string[] commands = ["@code_type", "@comment_type", "@compiler", "@error_format", 
                         "@add_css", "@overwrite_css", "@colorscheme", "@include"];
    Section curSection;
    int sectionNum = 0;
    Block curBlock;
    Change curChange;
    bool inCodeblock = false;
    bool inSearchBlock = false;
    bool inReplaceBlock = false;


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
    src = replaceAll!(match => include(match[1]))(src, regex(`\n@include (.*)`));
    string[] lines = src.split("\n");

    int lineNum = 0;
    foreach (line; lines) {
        lineNum++;

        if (strip(line).startsWith("//") && !inCodeblock) {
            continue;
        }

        // Parse the line
        if (!inCodeblock) {
            // This might be a change block
            // Parse change block
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

            // Parse a command
            if (line.split().length > 1) {
                if (commands.canFind(line.split()[0])) {
                    Command cmd = new Command();
                    cmd.name = line.split()[0];
                    auto index = cmd.name.length;
                    cmd.args = strip(line[index..$]);
                    if (cmd.args == "none") {
                        cmd.args = "";
                    }
            
                    if (curSection is null) {
                        chapter.commands ~= cmd;
                    } else {
                        curSection.commands ~= cmd;
                    }
                }
            }

            // Parse a title command
            if (startsWith(line, "@title")) {
                chapter.title = strip(line[6..$]);
            }

            // Parse a section definition
            else if (startsWith(line, "@s")) {
                if (curBlock !is null && !curBlock.isCodeblock) {
                    if (strip(curBlock.text()) != "") {
                        curSection.blocks ~= curBlock;
                    }
                } else if (curBlock !is null && curBlock.isCodeblock) {
                    error(chapter.file, curBlock.startLine, "Unclosed block {" ~ curBlock.name ~ "}");
                }
                // Make sure the section exists
                if (curSection !is null) {
                    chapter.sections ~= curSection;
                }
                curSection = new Section();
                curSection.title = strip(line[2..$]);
                curSection.commands = chapter.commands ~ curSection.commands;
                curSection.num = ++sectionNum;
            
                curBlock = new Block();
                curBlock.isCodeblock = false;
            }

            // Parse the beginning of a code block
            else if (matchAll(line, regex("^---.+"))) {
                if (curSection is null) {
                    error(chapter.file, lineNum, "You must define a section with @s before writing a code block");
                    continue;
                }
            
                if (curBlock !is null) {
                    curSection.blocks ~= curBlock;
                }
                curBlock = new Block();
                curBlock.startLine = lineNum;
                curBlock.isCodeblock = true;
                curBlock.name = strip(line[3..$]);
            
                // Parse Modifiers
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

            
                foreach (cmd; curSection.commands) {
                    if (cmd.name == "@code_type") {
                        curBlock.codeType = cmd.args;
                    } else if (cmd.name == "@comment_type") {
                        curBlock.commentString = cmd.args;
                    }
                }
            
                inCodeblock = true;
            }

            else if (curBlock !is null) {
                if (line.split().length > 1) {
                    if (commands.canFind(line.split()[0])) {
                        continue;
                    }
                }
                // Add the line to the list of lines
                curBlock.lines ~= new Line(line, filename, lineNum);

            }
        } else if (startsWith(line, "---")) {
            // Begin a new prose block
            if (curBlock !is null) {
                curSection.blocks ~= curBlock;
            }
            curBlock = new Block();
            curBlock.startLine = lineNum;
            curBlock.isCodeblock = false;
            inCodeblock = false;

        } else if (curBlock !is null) {
            // Add the line to the list of lines
            curBlock.lines ~= new Line(line, filename, lineNum);

        }

    }
    // Close the last section
    if (curBlock !is null) {
        if (!curBlock.isCodeblock) {
            curSection.blocks ~= curBlock;
        } else {
            writeln(filename, ":", lineNum - 1, ":error: {", curBlock.name, "} is never closed");
        }
    }
    if (curSection !is null) {
        chapter.sections ~= curSection;
    }


    return chapter;
}
