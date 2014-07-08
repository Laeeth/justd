#!/usr/bin/env rdmd-unittest-module

import std.math;

void main(string[] args) {
    import dbg;
    const maxBits = 20;
    foreach (bits; 0..maxBits + 1) {
        string[int] map;
        foreach (ix; 0..2^^bits) {
            map[ix] = "a";
        }
        import std.datetime: benchmark;
        auto len() { return map.length; }
        enum times = 10;
        auto marks = benchmark!(len)(times);
        import std.stdio: wfln = writefln;
        wfln("map of length %s run %s times took %s Milliseconds", len, times, marks[0].msecs);
    }
}
