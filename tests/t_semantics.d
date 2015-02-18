#!/usr/bin/env rdmd

void foo(ref const(int) x)
{
}

unittest
{
    import std.container: Array;
    auto x = Array!int ([1, 2, 3]);
    auto y = x;
    x ~= 4;
    assert(x == y); // assert reference semantics for Array
}

unittest
{
    string[int] x;
    auto y = x;
    x[0] = "zero";

    import std.stdio;
    writeln(x);
    writeln(y);

    assert(x == y);
}

void main(string[] args)
{
    int i = 1;
    foo(i);
}
