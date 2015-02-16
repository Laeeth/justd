#!/usr/bin/env rdmd

import std.stdio, std.bitmanip;

enum E2 { a, b, c, d, e }

immutable bf = bitfields!(uint, "x", 6,
                          E2, "e2", 2);

struct A { mixin(bf); }

void main(string[] args)
{
    A obj;
    obj.x = 2;
    obj.e2 = E2.a;

    import core.exception: AssertError;
    try
    {
        obj.e2 = E2.e;
        assert(false, "Exception not caught");
    }
    catch (core.exception.AssertError e) { /* ok to throw */ }
}
