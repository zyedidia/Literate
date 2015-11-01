import std.stdio;
import util;
import std.string: split, startsWith, chomp, replace, strip;
import std.algorithm: canFind;
import std.regex: matchAll, regex;

class Line {
    public string file;
    public int lineNum;
    public string text;

    this(string text, string file, int lineNum) {
        this.text = text;
        this.file = file;
        this.lineNum = lineNum;
    }
}

class Command {
    public string name;
    public string args;
    this() {}
}

class Block {
    public int startLine;
    public string name;
    public string type;
    public Line[] lines;
    this() {
        lines = [];
    }

    string text() {
        string text = "";
        foreach (line; lines) {
            text ~= line.text ~ "\n";
        }
        return text;
    }
}

class Section {
    public string title;
    public Block[] blocks;
    this() {
        blocks = [];
    }
}

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

class Program {
    public Command[] commands;
    public string title;
    public Section[] sections;
    public string file;

    this() {
        sections = [];
        commands = [];
    }
}

Program parse(File file, string filename) {
    string src = readall(file);
    return parse(src, filename);
}

Program parse(string src, string filename) {
    Program p = new Program();
    p.file = filename;
    Section curSection = new Section();
    Block curBlock = new Block();
    bool inCodeblock = false;
    bool inSearchBlock = false;
    bool inReplaceBlock = false;
    Change curChange;
    string[] lines = src.split("\n");

    string[] commands = ["@code_type", "@comment_type", "@compiler", "@error_format", "@add_css", "@overwrite_css", "@colorscheme", "@include"];

    int lineNum = 0;
    foreach(line; lines) {
        lineNum++;

        if (!inCodeblock) {
            if (startsWith(line, "@change") && !startsWith(line, "@change_end")) {
                curChange = new Change();
                curChange.filename = strip(line[7..$]);
                continue;
            } else if (startsWith(line, "@replace")) {
                curChange.searchText ~= "";
                curChange.replaceText ~= "";
                inReplaceBlock = false;
                inSearchBlock = true;
                continue;
            } else if (startsWith(line, "@with")) {
                inReplaceBlock = true;
                inSearchBlock = false;
                continue;
            } else if (startsWith(line, "@end")) {
                inReplaceBlock = false;
                inSearchBlock = false;
                curChange.index++;
                continue;
            } else if (startsWith(line, "@change_end")) {
                string text = readall(File(curChange.filename));
                for (int i = 0; i < curChange.index; i++) {
                    text = text.replace(curChange.searchText[i], curChange.replaceText[i]);
                }
                Program includedProgram = parse(text, curChange.filename);
                p.sections ~= includedProgram.sections;
                p.commands ~= includedProgram.commands;
                p.title = includedProgram.title;
                continue;
            }

            else if (inSearchBlock) {
                curChange.searchText[curChange.index] ~= line ~ "\n";
                continue;
            } else if (inReplaceBlock) {
                curChange.replaceText[curChange.index] ~= line ~ "\n";
                continue;
            }

            if (line.split().length > 1) {
                if (commands.canFind(line.split()[0])) {
                    Command cmd = new Command();
                    cmd.name = line.split()[0];
                    auto index = cmd.name.length;
                    cmd.args = strip(line[index..$]);

                    if (cmd.name == "@include") {
                        Program includedProgram = parse(File(cmd.args), cmd.args);
                        p.sections ~= includedProgram.sections;
                    }

                    p.commands ~= cmd;
                }
            }

            if (startsWith(line, "@title")) {
                p.title = strip(line[6..$]);
            } else if (startsWith(line, "@s")) {
                if (curSection.title !is null) {
                    p.sections ~= curSection;
                }
                curSection = new Section();
                curSection.title = strip(line[2..$]);
            } else if (matchAll(line, regex("^---.+"))) {
                if (curBlock.type !is null) {
                    curSection.blocks ~= curBlock;
                }
                curBlock = new Block();
                curBlock.startLine = lineNum;
                curBlock.type = "code";
                curBlock.name = strip(line[3..$]);
                inCodeblock = true;
            } else if (curBlock.type !is null) {
                curBlock.lines ~= new Line(line, filename, lineNum);
            }
        } else if (startsWith(line, "---")) {
            if (curBlock.type !is null) {
                curSection.blocks ~= curBlock;
            }
            curBlock = new Block();
            curBlock.startLine = lineNum;
            curBlock.type = "prose";
            inCodeblock = false;
        } else if (curBlock.type !is null) {
            curBlock.lines ~= new Line(line, filename, lineNum);
        }
    }
    if (curBlock.type == "prose") {
        curSection.blocks ~= curBlock;
    } else if (curBlock.type == "code"){
        writeln(filename, ":", lineNum - 1, ":error: {", curBlock.name, "} is never closed");
    }
    p.sections ~= curSection;

    return p;
}
