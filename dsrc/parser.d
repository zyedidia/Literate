import std.file;
import std.stdio;
import std.string;
import std.algorithm;
import std.regex;

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

class Content {
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
    public Content[] content;
    this() {
        content = [];
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

Program parse(in string filename) {
    auto file = File(filename);

    auto source = "";
    Program p = new Program();
    Section curSection = new Section();
    Content curContent = new Content();

    string[] commands = ["@code_type", "@comment_type", "@compiler", "@error_format", "@add_css", "@overwrite_css", "@colorscheme", "@include"];

    int lineNum = 0;
    while (!file.eof()) {
        lineNum++;
        auto line = file.readln();
        source ~= line;
        line = chomp(line);

        if (line.split().length > 1) {
            if (commands.canFind(line.split()[0])) {
                Command cmd = new Command();
                cmd.name = line.split()[0];
                auto index = line.indexOf(cmd.name) + cmd.name.length;
                cmd.args = strip(line[index..$]);

                if (cmd.name == "@include") {
                    Program includedProgram = parse(cmd.args);
                    p.sections ~= includedProgram.sections;
                }

                p.commands ~= cmd;
            }
        }

        if (startsWith(line, "@title")) {
            auto index = line.indexOf("@title") + 6;
            p.title = strip(line[index..$]);
        }

        else if (startsWith(line, "@s")) {
            if (curSection.title !is null) {
                p.sections ~= curSection;
            }
            curSection = new Section();
            auto index = line.indexOf("@s") + 2;
            curSection.title = strip(line[index..$]);
        }

        else if (matchAll(line, regex("^--- .+"))) {
            if (curContent.type !is null) {
                curSection.content ~= curContent;
            }
            curContent = new Content();
            curContent.type = "code";
            curContent.name = strip(line[3..$]);
        }

        else if (startsWith(line, "---")) {
            if (curContent.type !is null) {
                curSection.content ~= curContent;
            }
            curContent = new Content();
            curContent.type = "prose";
        }

        else if (curContent.type !is null) {
            curContent.lines ~= new Line(line, filename, lineNum);
        }
    }

    writeln(p.title);
    foreach (cmd; p.commands) {
        writeln(cmd.name, " ", cmd.args);
    }
    foreach (s; p.sections) {
        foreach(c; s.content) {
            writeln(c.type);
            write(c.text());
        }
    }

    file.close();

    return p;
}

void main(in string[] args) {
    parse(args[1]);
}
