#!/usr/bin/env rdmd

import std.stdio, std.algorithm, std.array;

void main(string[] args) {
    stdin.byLine(KeepTerminator.yes).
        map!(a => a.idup).
        array.
        sort.
        copy(stdout.lockingTextWriter());
}
