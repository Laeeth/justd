#!/usr/bin/env rdmd-dev-module

void f(int[] x)
{
    x ~= 13;
}

void g(ref int[] x)
{
    x ~= 13;
}

import std.stdio: writeln;

unittest
{
    int[] y;
    f(y);
    writeln(y);
    g(y);
    writeln(y);
}

unittest
{
    import std.container: Array;

    alias E = int; // element type
    alias K = string; // key type
    alias A = Array!E; // array type

    A[K] x;

    // x["a"] = A.init; // this line prevents RangeError
    x["a"] ~= 42; // this triggers RangeError

    writeln(x);
}
