#!/usr/bin/env rdmd-unittest-module

import std.stdio, std.algorithm, std.typecons, std.range, std.algorithm;

unittest
{
    bool x;
    enum v = __traits(valueRange, x ? 2 : 3);
    static assert(v[0] == 2);
    static assert(v[1] == 3);
}

unittest
{
    enum v = __traits(valueRange, false ? 2 : 3);
    static assert(v[0] == 3);
    static assert(v[1] == 3);
}

unittest
{
    enum v = __traits(valueRange, true ? 2 : 3);
    static assert(v[0] == 2);
    static assert(v[1] == 2);
}
