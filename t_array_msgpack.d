#!/usr/bin/env rdmd-dev-module

import std.stdio;
import std.conv: to;
import msgpack;
import std.container;
import std.traits;

import backtrace.backtrace;

static void stringArrayPackHandler(E)(ref Packer p,
                                      ref Array!E x)
{
    p.beginArray(x.length);
    foreach (e; x)
        p.pack(e);
}

unittest
{
    import std.stdio: stderr;
    backtrace.backtrace.install(stderr);

    registerPackHandler!(Array!string, stringArrayPackHandler);

    Array!string x = ["x", "y"];
    writeln(x.pack);

    string[] y = ["x", "y"];
    writeln(y.pack);
}
