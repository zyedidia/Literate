import std.string;
import std.stdio;
import parser;

void tangle(Program p) {
    Block[] tempCodeblocks = [];
    Block[string] rootCodeblocks;
    Block[string] codeblocks;

    foreach (s; p.sections) {
        foreach (b; s.blocks) {
            if (b.type == "code") {
                tempCodeblocks ~= b;

                if ((!b.name.endsWith("+=")) && (!b.name.endsWith(":="))) {
                    codeblocks[b.name] = b;
                    if (matchAll(b.name, regex(".*\\.\\w+"))) {
                        rootCodeblocks[b.name] = b;
                    }
                }
            }
        }
    }

    foreach (b; tempCodeblocks) {
        if (b.name.endsWith("+=")) {
            auto index = b.name.length - 2;
            string name = strip(b.name[0..index]);
            codeblocks[name].lines ~= b.lines;
        } else if (b.name.endsWith(":=")) {
            auto index = b.name.length - 2;
            string name = strip(b.name[0..index]);
            codeblocks[name].lines = b.lines;
        }
    }

    foreach (b; rootCodeblocks) {
        string filename = b.name;
        File f = File(filename, "w");

        string commentString = "";
        foreach (c; p.commands) {
            if (c.name == "@comment_type") {
                commentString = c.args;
            }
        }
        writeCode(codeblocks, filename, f, filename, "", commentString);
        f.close();
    }
}

void writeCode(Block[string] codeblocks, string blockName, File file, string filename, string whitespace, string commentString) {
    Block block = codeblocks[blockName];

    if (commentString != "") {
        file.writeln(whitespace ~ commentString.replace("%s", blockName));
    }

    foreach (lineObj; block.lines) {
        string line = lineObj.text;
        string stripLine = strip(line);
        if (stripLine.startsWith("@{") && stripLine.endsWith("}")) {
            auto firstChar = line.indexOf(stripLine[0]);
            string newWS = line[0..firstChar];
            auto index = stripLine.length - 1;
            auto newBlockName = stripLine[2..index];
            if ((newBlockName in codeblocks) !is null) {
                writeCode(codeblocks, newBlockName, file, filename, whitespace ~ newWS, commentString);
            } else {
                writeln(lineObj.file, ":", lineObj.lineNum, ":error:", newBlockName, " does not exist");
            }
        } else {
            file.writeln(whitespace ~ line);
        }
    }
    file.writeln();
}
