#!/usr/bin/env rdmd-dev-module

import std.algorithm.searching: canFind;

void main()
{
    auto x = [42];

    assert(!x.canFind(1));
    assert(!x.canFind!(a => a == 1));

    assert(x.canFind(42));
    assert(x.canFind!(a => a == 42));
    assert(x.canFind!"a == 42");
}
