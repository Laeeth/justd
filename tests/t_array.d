#!/usr/bin/env rdmd-dev-module

import std.stdio, std.algorithm, std.range;

unittest
{
    alias wln = writeln;

    auto x = cast(int[])[];

    auto x2 = new int(3);

    wln(x.sizeof);

    if (x) {
        wln("Here!");
    } else {
        wln("There!");
    }

    int[2] xx;
    auto xc = xx;
    xc[0] = 1;
    wln(xx);
    wln(xc);
    int[2] xx_;

    auto hit = x.find(1);
    if (hit) {
        wln("Hit: ", hit);
    } else {
        wln("No hit");
    }
    int[2] z;                   // arrays are zero initialized

    wln(z);

    assert([].ptr == null);
    assert("ab"[$..$] == []);
    auto p = "ab"[$..$].ptr;
    wln(p);
    assert(p != null);

    auto w = [1, 2];
    assert(w[0..0]);
    assert(w[$..$]);
    assert(![]);

    auto s = [1, 2, 3];
    wln(s.stripLeft(1));

    int[] ns;
    assert(!ns);
    assert(s[0..0]);
    assert(s[$..$]);
}
