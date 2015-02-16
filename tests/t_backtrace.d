#!/usr/bin/env rdmd-dev

/* See also: https://github.com/yazd/backtrace-d */

import std.stdio, std.algorithm;
import backtrace.backtrace;

void f1() {
    f2();
}

void f2(uint i = 0) {
    if (i == 2) { printPrettyTrace(stderr); return; }
    f2(++i);
}

void e1() {
    e2();
}

void e2(uint i = 0) {
    if (i == 2) throw new Exception("Exception thrown");
    e2(++i);
}

void main() {
    backtrace.backtrace.install(stderr);
    f1();
    e1();
}
