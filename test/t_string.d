#!/usr/bin/env rdmd-dev-module

unittest {
    import std.string;
    import std.range: front, retro;
    import std.stdio: wln = writeln;
    auto a = "åäö";
    wln("Variable a of type ", typeof(a).stringof,
        " has value ", a,
        " of length ", a.length,
        " with first 8-bit char ", a[0],
        " with front ", a.front,
        " in reverse ", a.retro);
}
