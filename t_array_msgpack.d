#!/usr/bin/env rdmd-dev-module

import std.stdio;
import std.conv: to;
import msgpack;
import std.container;
import std.traits;

import backtrace.backtrace;

unittest
{
    import std.stdio: stderr;
    backtrace.backtrace.install(stderr);

    /* registerPackHandler!(Array!string, arrayPackHandler); */

    Array!string x = ["x", "y"];
    writeln(x.pack);

    string[] y = ["x", "y"];
    writeln(y.pack);
}
