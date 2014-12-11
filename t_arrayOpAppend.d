#!/usr/bin/env rdmd-dev-module

import std.stdio, std.algorithm, std.range;

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