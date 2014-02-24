#!/usr/bin/env rdmd-unittest-module

import std.stdio, std.algorithm;
import dbg;

void main(string[] args) {
    dln(char.sizeof);
    dln(wchar.sizeof);
    dln(dchar.sizeof);
}
