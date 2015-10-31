import std.stdio;

string readall(File file) {
    string src = "";
    while (!file.eof) {
        src ~= file.readln();
    }
    file.close();
    return src;
}

string readall() {
    string src = "";
    string line;
    while ((line = readln()) !is null) {
        src ~= line;
    }
    return src;
}
