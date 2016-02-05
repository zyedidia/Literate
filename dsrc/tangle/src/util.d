// util.d
import std.stdio;
import parser;
import std.string;

// readall function
// Read from a file
string readall(File file) {
    string src = "";
    while (!file.eof) {
        src ~= file.readln();
    }
    file.close();
    return src;
}

// error function
void error(string file, int line, string message) {
    writeln(file, ":", line, ":error: ", message);
}

// warning function
void warn(string file, int line, string message) {
    writeln(file, ":", line, ":warning: ", message);
}

// leadingWS function
string leadingWS(string str) {
    auto firstChar = str.indexOf(strip(str)[0]);
    return str[0..firstChar];
}

// getCodeblocks function
void getCodeblocks(Program p, 
                   out Block[string] codeblocks,
                   out Block[string] rootCodeblocks) {
    Block[] tempCodeblocks;

    foreach (c; p.chapters) {
        foreach (s; c.sections) {
            foreach (b; s.blocks) {
                if (b.isCodeblock) {
                    if ((!b.name.endsWith("+=")) && (!b.name.endsWith(":="))) {
                        codeblocks[b.name] = b.dup();
                        if (matchAll(b.name, regex(".*\\.\\w+"))) {
                            rootCodeblocks[b.name] = b.dup();
                        }
                    } else {
                        tempCodeblocks ~= b.dup();
                    }
                }
            }
        }
    }

    // Now we go through every codeblock in tempCodeblocks and apply the += and :=
    foreach (b; tempCodeblocks) {
        if (b.name.endsWith("+=")) {
            auto index = b.name.length - 2;
            string name = strip(b.name[0..index]);
            if ((name in codeblocks) is null) {
                error(p.file, b.startLine, "Trying to add to {" ~ name ~ "} which does not exist");
            } else {
                codeblocks[name].lines ~= b.lines;
            }
        } else if (b.name.endsWith(":=")) {
            auto index = b.name.length - 2;
            string name = strip(b.name[0..index]);
            if ((name in codeblocks) is null) {
                error(p.file, b.startLine, "Trying to redefine {" ~ name ~ "} which does not exist");
            } else {
                codeblocks[name].lines = b.lines;
            }
        }
    }
}
