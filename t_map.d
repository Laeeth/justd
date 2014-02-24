#!/usr/bin/env rdmd-dev-module

import std.stdio, std.algorithm;

unittest {
    string[int] x = [0:"b", 1:"a"];
    x[2] = "c";
    auto y = x.values.map!("a~a");
    writeln(y);
}

unittest {
    string[int] x = [0:"b", 1:"a"];
    const xd = x.dup;
    auto y = x;
    x[2] = "c";
    writeln(y);
    writeln(xd);
}

unittest {
    const(uint[ubyte]) x;
    writeln(x.sizeof);
    // uint[ubyte] y = x;
    string[string][] xx;
}
