#!/usr/bin/env rdmd-dev-module

import std.stdio;
import std.conv: to;
import std.container: Array;
import msgpack;

static void stringArrayPackHandler(E)(ref Packer p,
                                      ref Array!E x)
{
    // p.put(192);
    p.packArray(x);
    /* foreach (e; x) */
    /*     p.pack(e); */
}

unittest
{
    registerPackHandler!(Array!string, stringArrayPackHandler);
    Array!string x = ["x", "y"];
    writeln(x.pack);
    writeln(["x", "y"].pack);
}
