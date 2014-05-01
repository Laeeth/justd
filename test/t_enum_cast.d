#!/usr/bin/env rdmd

import std.stdio: writeln;
import std.traits;

void main(string[] args)
{
    enum E {x, y, z}
    E e;
    e = cast(E)3;
    writeln(e);
}
