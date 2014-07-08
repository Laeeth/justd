#!/usr/bin/env rdmd

void main() {
    import std.stdio : writeln;

    string null_string = null;
    writeln(null_string ? "true" : "false");

    string empty_string = "";
    writeln(empty_string ? "true" : "false");

    int[] empty_array;
    writeln(empty_array ? "true" : "false");
}
