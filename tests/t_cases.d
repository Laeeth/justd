#!/usr/bin/env rdmd

import std.stdio, std.algorithm;

void main(string[] args) {
    immutable int x = 1;
    if (x == 1) {
        writeln("first");
    } else if (x == 1) {
        writeln("second");
    }
}
