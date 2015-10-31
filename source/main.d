import parser;
import tangler;
import std.stdio;

void main(in string[] args) {
    if (args.length < 2) {
        writeln("No input file!");
        return;
    }
    File f = File(args[1]);
    Program p = parse(f, args[1]);
    tangle(p);
}
