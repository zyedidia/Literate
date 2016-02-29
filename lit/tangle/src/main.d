// main.d
// Imports
import parser;
import tangler;
import util;
import std.stdio;
import std.file;
import std.string;
import std.process;
import std.regex;
import std.conv;

// Globals
bool tangleOnly = true;
string outDir = "."; // Default is current directory

// Modifiers
enum Modifier {
    noWeave,
    noTangle,
    additive, //+=
    redef // :=
}

void main(in string[] args) {
    string[] files = [];
    // Parse the arguments
    for (int i = 1; i < args.length; i++) {
        auto arg = args[i];
        if (arg == "--out-dir" || arg == "-odir") {
            if (i == args.length - 1) {
                writeln("No output directory provided.");
                return;
            }
            outDir = args[++i];
        } else {
            files ~= arg;
        }
    }

    // Run Literate
    foreach (filename; files) {
        if (!filename.exists()) {
            writeln("File ", filename, " does not exist!");
            continue;
        }
        File f = File(filename);
        string fileSrc = readall(f);

        Program p;
        p = new Program();
        p.file = filename;
        Chapter c = new Chapter();
        c.file = filename;
        c.majorNum = 1; c.minorNum = 0;

        c = parseChapter(c, fileSrc);
        p.chapters ~= c;

        tangle(p);
    }
}
