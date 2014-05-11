#!/usr/bin/env rdmd-dev-module

/** See also: http://forum.dlang.org/thread/lkevco$1ktt$1@digitalmars.com */

import std.stdio;

void foo(T)(T x) {
    writeln(typeof(x).stringof);
}

void main() {
    immutable a = [1, 2];
    writeln(typeof(a).stringof);
    foo(a);
    immutable y = 10;
    foo(y); // this should print int not immutable(int)
}
