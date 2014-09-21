#!/usr/bin/env rdmd-dev-module

import std.conv: to;
import rcstring;
import msgpack;

auto typestringof(T)(T a) { return T.stringof; }

import dbg;

unittest
{
    dln(RCString("alpha").toString.pack);
    dln("alpha".pack);
}
