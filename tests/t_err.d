#!/usr/bin/env rdmd-dev

void main(string args[])
{
    import std.stdio;
    import backtrace.backtrace;
    backtrace.backtrace.install(stderr);
    ubyte[] x = [101, 120, 32, 83, 111, 102, 116, 119, 97, 114, 101, 32, 50, 48, 49, 49, 0, 88, 89, 90, 32, 0, 0, 0, 0, 0, 0, 181, 90, 0, 0, 188, 103, 0, 0, 146, 48, 109, 102, 116, 50, 0, 0, 0, 0, 4, 3, 9, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 2, 0, 0, 2, 36, 4, 29, 5, 218, 7, 105, 8, 217];
    import w3c;
    writeln((cast(string)x).encodeHTML);
}
