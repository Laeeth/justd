#!/usr/bin/env rdmd

import std.stdio, std.algorithm, std.traits;

void main(string[] args) {
    alias CommonType!(int, long, short) X;
    assert(is(X == long));

    alias CommonType!(int, long, short, double) D;
    assert(is(D == double));

    alias CommonType!(int, long, short, float) F;
    assert(is(F == float));

    // int x = 0x0000_1111_2222_3333;
    int y = cast(ulong)0x0000_1111;

    alias CommonType!(int, char[], short) Y;
    assert(is(Y == void));
}
