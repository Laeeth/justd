#!/usr/bin/env rdmd-dev-module

import std.stdio;
import std.conv: to;

unittest
{
    const x = "a";
    const y = x.to!string;
    assert(x.ptr == y.ptr);
}

unittest
{
    auto x = new char[1];
    const y = x.to!string;
    assert(x.ptr != y.ptr);
}
