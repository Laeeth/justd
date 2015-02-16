#!/usr/bin/env rdmd-dev-module

import std.stdio, std.algorithm, std.range, std.array;

void main(string[] args)
{
    auto x = [1, 2, 3, 4];
    auto s = x[0..$/2];

    s[0] = -1;
    writeln("s: ", s);

    s ~= [0];
    writeln("s: ", s);

    s[1] = -2;
    writeln("s: ", s);

    writeln("x: ", x);
}
