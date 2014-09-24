#!/usr/bin/env rdmd-dev-module

import std.stdio;
import std.conv: to;
import msgpack;

import rcstring;

void rcstringPackHandler(ref Packer p,
                         const RCString rcstring) pure nothrow
{
    p.pack(rcstring.toString);
}

import backtrace.backtrace;

unittest
{
    import std.stdio: stderr;
    backtrace.backtrace.install(stderr);

    registerPackHandler!(RCString, rcstringPackHandler);

    writeln("RCString.pack: ", RCString("").pack);
    writeln(`"".pack: `, "".pack);
    assert(RCString("").pack == "".pack);

    writeln(`[""].pack: `, [""].pack);
    writeln("RCString[].pack: ", [RCString("")].pack);

    assert([RCString("")].pack == [""].pack);
}
