#!/usr/bin/env rdmd-unittest-module

import std.stdio, std.algorithm;

void main(string args[]) {
    alias T = float;
    T a = 1.0;
    T b = +100_000_000;
    T c = -100_000_000;
    import dbg:dln;
    dln((a + b) + c);
    dln(a + (b + c));
}
