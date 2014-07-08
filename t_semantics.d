#!/usr/bin/env rdmd

import std.stdio;

void foo(ref const(int) x)
{
}

void main(string[] args)
{
    int x = 1;
    foo(x);
}
