#!/usr/bin/env rdmd-unittest-module

import std.stdio, std.algorithm;

/**
  See also: https://www.bountysource.com/issues/1325927-ctfe-copy-on-write-is-slow-and-causes-huge-memory-usage
  See also: https://issues.dlang.org/show_bug.cgi?id=6498
*/

T bug6498(T)(T x)
{
    T n = 0;
    while (n < x)
        ++n;
    return n;
}

void main(string args[])
{
    static assert(bug6498(10_000_000) == 10_000_000);
}
