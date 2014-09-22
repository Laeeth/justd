#!/usr/bin/env rdmd-dev-module

import std.stdio;
import std.conv: to;
import msgpack;

import rcstring;

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

import std.container: Array;
import backtrace.backtrace;

unittest
{
    import std.stdio: stderr;
    backtrace.backtrace.install(stderr);

    Array!string a;
    writeln(a.pack);

    string[] b;
    writeln(b.pack);

    string c;
    writeln(c.pack);

    a ~= "a";
    writeln(a.pack);
}
