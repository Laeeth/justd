#!/usr/bin/env rdmd-dev-module

import msgpack;
import std.container;

unittest
{
    Array!string x = ["x", "y"];
    string[] y = ["x", "y"];
    assert(x.pack == y.pack);
}
