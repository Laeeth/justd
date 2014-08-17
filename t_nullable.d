#!/usr/bin/env rdmd-unittest-module

import std.stdio, std.algorithm;
import algorithm_ex;

void main(string args[])
{
    import std.typecons;
    import dbg;
    auto n = Nullable!(size_t,
                       size_t.max)();
    n = 0;
    dln(n);
    dln(n.untouched);
    auto m = Nullable!(size_t)();
}
