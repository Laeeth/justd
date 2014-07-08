#!/usr/bin/env rdmd-dev-module

import std.stdio, std.algorithm, std.range;

int main(string[] args)
{
    auto x = cast(int[])[];

    auto x2 = new int(3);

    writeln(x.sizeof);

    if (x) {
        writeln("Here!");
    } else {
        writeln("There!");
    }

    int xx[2];
    auto xc = xx;
    xc[0] = 1;
    writeln(xx);
    writeln(xc);
    int[2] xx_;

    auto hit = x.find(1);
    if (hit) {
        writeln("Hit: ", hit);
    } else {
        writeln("No hit");
    }
    int[2] z;                   // arrays are zero initialized

    writeln(z);

    assert([].ptr == null);
    assert("ab"[$..$] == []);
    auto p = "ab"[$..$].ptr;
    writeln(p);
    assert(p != null);

    auto w = [1, 2];
    assert(w[0..0]);
    assert(w[$..$]);
    assert(![]);

    return 0;
}
