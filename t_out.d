#!/usr/bin/env rdmd

void foo(out int x)
{
    x = 13;
}

void main() {
    import std.stdio : writeln;
    int x = void;
    foo(x);
    writeln(x);
}
