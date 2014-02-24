#!/usr/bin/env rdmd

import std.stdio: writeln;

void main(string[] args) {
    enum E {x, y, z}
    E e;
    e = cast(E)3;

    import dbg: dln;
    dln(e);
}
