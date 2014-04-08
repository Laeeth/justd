#!/usr/bin/env rdmd-dev-module

/* import std.stdio, std.algorithm, std.range, std.array; */

void main(string[] args)
{
    auto x = [1, 2, 3, 4]; // original

    auto a = x[0..$ / 2]; // first part
    auto b = x[$ / 2.. $]; // second part

    auto y = x[0..$]; // whole
    auto z = x[0..$ + 1]; // error
}
