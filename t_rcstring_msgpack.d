#!/usr/bin/env rdmd-dev-module

import std.conv: to;
import rcstring;
import msgpack;

auto typestringof(T)(T a) { return T.stringof; }

import dbg;

ubyte[] pack(bool withFieldName = false)(RCString s)
{
    auto packer = Packer(withFieldName);
    packer.pack(s.toString);
    return packer.stream.data;
}

unittest
{
    assert(RCString("alpha").pack ==
           msgpack.pack("alpha"));
}
