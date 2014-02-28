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

unittest {
    // Issue 5685: https://d.puremagic.com/issues/show_bug.cgi?id=5685
    int[2] foo = [1, 2];
    string[int[2]] aa;
    aa[foo] = "";
    writeln(aa);
    assert(foo in aa);  // OK
    assert(cast(int[2])[1, 2] in aa);  // OK
    // assert([1, 2] in aa);  // FAILS
}
