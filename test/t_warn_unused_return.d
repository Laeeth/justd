#!/usr/bin/env rdmd-dev

import std.stdio, std.algorithm;

@safe pure nothrow void strictVoidReturn(T)(T x)
{
}

@safe pure nothrow void nonstrictVoidReturn(T)(ref T x)
{
}

@safe pure void mayThrow()
{
    throw new Exception("Here!");
}

@safe pure nothrow T strictlyPure(T)(T x)
{
    // mayThrow();
    return x*x;
}

void main(string args[]) {
    alias wln = writeln;
    int x = 3;
    strictVoidReturn(x);
    nonstrictVoidReturn(x);
    strictlyPure(x);
    // int y = strictVoidReturn(x);
    /* mayThrow(); */
 }
