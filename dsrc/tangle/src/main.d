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


// getLinenums function
Line[][string] getLinenums(Block[string] codeblocks, string blockName, 
                 string rootName, Line[][string] codeLinenums) {
    Block block = codeblocks[blockName];

    if (block.commentString != "") {
        codeLinenums[rootName] ~= new Line("comment", "", 0);
    }

    foreach (lineObj; block.lines) {
        string line = lineObj.text;
        string stripLine = strip(line);
        if (stripLine.startsWith("@{") && stripLine.endsWith("}")) {
            auto index = stripLine.length - 1;
            auto newBlockName = stripLine[2..index];
            getLinenums(codeblocks, newBlockName, rootName, codeLinenums);
        } else {
            codeLinenums[rootName] ~= lineObj;
        }
    }
    codeLinenums[rootName] ~= new Line("", "", 0);

    return codeLinenums;
}


void main(in string[] args) {
    string[] files = [];

    // Parse the arguments
    for (int i = 1; i < args.length; i++) {
        auto arg = args[i];
        if (arg == "--help" || arg == "-h") {
            writeln("Tangle: Tangler for Literate\n"
                    "\n"
                    "Usage: tangle [options] <inputs>\n"
                    "\n"
                    "Options:\n"
                    "--help    -h          Show this help text\n"
                    "--out-dir -odir DIR   Put the generated files in DIR\n"
                   );
            return;
        } else if (arg == "--out-dir" || arg == "-odir") {
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
    if (files.length > 0) {
        foreach (filename; files) {
            if (!filename.exists()) {
                writeln("File ", filename, " does not exist!");
                continue;
            }
            File f = File(filename);
            string fileSrc = readall(f);
    
            Program p = new Program();
            p.file = filename;
            Chapter c = new Chapter();
            c.file = filename;
            c.majorNum = 1; c.minorNum = 0;
    
            c = parseChapter(c, fileSrc);
            p.chapters ~= c;
    
            tangle(p);
    
        }
    }
    else {
        string stdinSrc = readall();
    
        Program p = new Program();
        p.file = "stdin";
        Chapter c = new Chapter();
        c.file = "stdin";
        c.majorNum = 1; c.minorNum = 0;
    
        c = parseChapter(c, stdinSrc);
        p.chapters ~= c;
    
        tangle(p);
    }

}

