#!/usr/bin/env rdmd

import std.algorithm : find, joiner;
import std.functional : not;
import std.stdio : write;

enum n = 0b1;

ubyte flags;

void main(string[] args) {
    args[1 .. $]
        .find!(not!option)()
        .joiner(" ")
        .write(flags & n ? "" : "\n");
}

bool option(string arg) {
    switch (arg) {
    case "-n":
        flags |= n;
        return true;
    default:
        return false;
    }
}
