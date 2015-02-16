#!/usr/bin/env rdmd

import std.stdio: writeln;
import std.traits;

void main(string[] args)
{
    enum E { x = 3, y = 4, z = 5}
    E e;
    static assert(!__traits(compiles, {e = 3;}));

    int[E] x;
    x[E.x] = 3;
}
