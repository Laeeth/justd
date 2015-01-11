#!/usr/bin/env rdmd-dev-module

import std.algorithm, std.range, std.stdio;

void main(string[] args)
{
    long[] arr;

    const n = 3;

    iota(n).map!(a => arr ~= a);
    writeln(arr);

    writeln(iota(n).map!(a => arr ~= a));
    writeln(arr);
}
