#!/usr/bin/env rdmd-dev-module

import msgpack;
import std.container;

unittest
{
     assert(Array!string(["x", "y"]).pack == ["x", "y"].pack);
}
