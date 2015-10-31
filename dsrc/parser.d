import std.file;
import std.stdio;
import std.string;
import std.algorithm;
import std.regex;
import std.array;

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

    this() {
        sections = [];
        commands = [];
    }
}

string readall(File file) {
    string src = "";
    while (!file.eof) {
        src ~= file.readln();
    }
    file.close();
    return src;
}

Program parse(File file, string filename="") {
    string src = readall(file);
    return parse(src, filename);
}

Program parse(string src, string filename="") {
    Program p = new Program();
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
                Program includedProgram = parse(text);
                p.sections ~= includedProgram.sections;
            }

            else if (inSearchBlock) {
                writeln("Search: " ~ line);
                curChange.searchText[curChange.index] ~= line ~ "\n";
                continue;
            } else if (inReplaceBlock) {
                writeln("Replace: " ~ line);
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
                        Program includedProgram = parse(cmd.args);
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
            curBlock.type = "prose";
            inCodeblock = false;
        } else if (curBlock.type !is null) {
            curBlock.lines ~= new Line(line, filename, lineNum);
        }
    }

    writeln(p.title);
    foreach (cmd; p.commands) {
        writeln(cmd.name, " ", cmd.args);
    }
    foreach (s; p.sections) {
        foreach(b; s.blocks) {
            writeln(b.type);
            write(b.text());
        }
    }

    return p;
}

void main(in string[] args) {
    File f = File(args[1]);
    parse(f);
}
