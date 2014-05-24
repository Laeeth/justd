#!/usr/bin/env rdmd-dev-module

/* import std.stdio, std.algorithm, std.range, std.array; */

void main(string[] args)
{
    import std.range;

    auto arr2 = iota(0, 512).array[0 .. 128];

    auto l = [1, 2, 3, 4][0 .. $/2]; // original
    auto x = [1, 2, 3, 4]; // original

    auto a = x[0 .. $/2]; // first part
    auto b = x[$/2 .. $]; // second part

    auto y = x[0 .. $]; // whole

    // TODO: This should give static error throw some common range propagation
    // of min/max of lower and upper bound relative to beginning and end of
    // slice
    auto z = x[0 .. $+1];
    auto z1 = x[-1 .. $];

    auto w = l.ptr[0 .. l.length];
}
