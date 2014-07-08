#!/usr/bin/env rdmd-dev

import std.stdio, std.range, std.algorithm;

void main(string[] args) {
    immutable a = [5,1,2,3,4,1];
    writeln(countUntil(retro(a), 5));
    writeln(a.retro.countUntil(5));
}
