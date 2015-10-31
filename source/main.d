import parser;
import tangler;
import util;
import std.stdio;
import std.file;

bool codeOnly;
bool webOnly;
bool noOutput;
string outDir;

void main(in string[] args) {
    string[] files = [];

    for (int i = 1; i < args.length; i++) {
        string arg = args[i];

        if (arg == "--help" || arg == "-h") {
            writeln("Lit: Literate Programming System\n"
                    "\n"
                    "Usage: lit [options] <inputs>\n"
                    "\n"
                    "Options:\n"
                    "--help    -h          Show this help text"
                    "--code    -c          Only compile code files\n"
                    "--web     -w          Only compile HTML files\n"
                    "--no-output           Do not generate any output files\n"
                    "--out-dir -odir DIR   Put the generated files in DIR\n"
                   );
            return;
        } else if (arg == "--code" || arg == "-c") {
            codeOnly = true;
        } else if (arg == "--web" || arg == "-w") {
            webOnly = true;
        } else if (arg == "--no-output") {
            noOutput = true;
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

    if (files.length > 0) {
        foreach (filename; files) {
            if (!filename.exists()) {
                writeln("File ", filename, " does not exist!");
                continue;
            }
            File f = File(filename);
            Program p = parse(f, filename);
            tangle(p);
        }
    } else {
        Program p = parse(readall(), "stdin");
        tangle(p);
    }
}
