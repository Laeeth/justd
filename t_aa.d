#!/usr/bin/rdmd

void f(int[string] x)
{
    x["one"] = 1;
}

void main(string[] args)
{
    import std.stdio;
    int[string] x;
    writeln(x);
    f(x);
    writeln(x);
}
