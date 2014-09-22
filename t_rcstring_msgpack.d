#!/usr/bin/env rdmd-dev-module

import std.stdio;
import std.conv: to;
import rcstring;
import msgpack;

void rcstringPackHandler(ref Packer p, ref RCString rcstring)
{
    writeln("Packing ", p);
    p.pack(rcstring.toString);
}

unittest
{
    registerPackHandler!(RCString, rcstringPackHandler);
    writeln(RCString("").pack);
}
