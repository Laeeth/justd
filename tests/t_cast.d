#!/usr/bin/env rdmd

import std.stdio : writeln;
import backtrace.backtrace;

void main()
{
    import std.stdio: stderr;
    backtrace.backtrace.install(stderr);

    string null_string = null;
    writeln(null_string ? "true" : "false");

    string empty_string = "";
    writeln(empty_string ? "true" : "false");

    int[] empty_array;
    writeln(empty_array ? "true" : "false");

    foo();
}

void foo() @safe pure nothrow
{
    void[] void_array = new void[3];
    auto ubyte_array = cast(ubyte[])void_array;
    auto short_array = cast(short[])void_array;
}
