#!/usr/bin/env rdmd-unittest-module

import std.stdio;

int main(string[] args)
{
    struct A { int x, y; }
    A a;
    foreach (e; a)  {
        writeln(e);
    }
    return 0;
}
