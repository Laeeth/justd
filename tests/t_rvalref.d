#!/usr/bin/env rdmd-dev-module

import std.stdio, std.algorithm, std.range, std.array;

void none(T)(in T x)
{
}

void inc(ref int x)
{
    x++;
}

class C
{
    this(int x) { this.x = x; }
    int x;
}

void main(string[] args)
{
    none(42);
    none("a");
    none(new C(42));
}
