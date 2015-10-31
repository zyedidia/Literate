import std.file;
import std.stdio;
import std.string;

class Command {
    public string cmdName;
    public string cmd;
    this() {}
}

class Content {
    public int type;
    public string text;
    this() {}
}

class Section {
    public string name;
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

void parse(in string filename) {
    auto file = File(filename);

    auto source = "";
    Program p = new Program();

    while (!file.eof()) {
        auto line = file.readln();
        source ~= line;
        line = chomp(line);

        if (startsWith(line, "@title")) {
            auto index = line.indexOf("@title") + 6;
            p.title = strip(line[index..$]);
            writeln(p.title);
        }
    }

    file.close();
}

void main(in string[] args) {
    parse(args[1]);
}
