// tangler.d
import std.string;
import std.stdio;
import parser;
import main;
import util;

void tangle(Program p) {
    // tangle function
    Block[string] rootCodeblocks;
    Block[string] codeblocks;
    
    getCodeblocks(p, codeblocks, rootCodeblocks);
    if (rootCodeblocks.length == 0) {
        warn(p.file, 0, "No file codeblocks, not writing any code");
    }
    foreach (b; rootCodeblocks) {
        string filename = b.name;
        File f;
        f = File(outDir ~ "/" ~ filename, "w");
    
        writeCode(codeblocks, b.name, f, filename, "");
        f.close();
    }

}

// writeCode function
void writeCode(Block[string] codeblocks, string blockName, File file, string filename, string whitespace) {
    Block block = codeblocks[blockName];

    if (block.commentString != "") {
        file.writeln(whitespace ~ block.commentString.replace("%s", blockName));
    }

    foreach (lineObj; block.lines) {
        string line = lineObj.text;
        string stripLine = strip(line);
        if (stripLine.startsWith("@{") && stripLine.endsWith("}")) {
            string newWS = leadingWS(line);
            auto index = stripLine.length - 1;
            auto newBlockName = stripLine[2..index];
            if (newBlockName == blockName) {
                error(lineObj.file, lineObj.lineNum, "{" ~ blockName ~ "} refers to itself");
                return;
            }
            if ((newBlockName in codeblocks) !is null) {
                writeCode(codeblocks, newBlockName, file, filename, whitespace ~ newWS);
            } else {
                error(lineObj.file, lineObj.lineNum, "{" ~ newBlockName ~ "} does not exist");
            }
        } else {
            file.writeln(whitespace ~ line);
        }
    }
    file.writeln();
}


