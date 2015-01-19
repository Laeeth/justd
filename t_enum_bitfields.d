#!/usr/bin/env rdmd

import std.stdio, std.bitmanip;

enum E2 { a, b, c, d }

void main(string[] args)
{
    immutable bf = bitfields!(uint, "x", 2,
                              int, "y", 2,
                              uint, "z", 2,
                              E2, "e2", 2);

    struct A
    {
        mixin(bf);
    }

    A obj;
    obj.x = 2;
    obj.y = 1;
    obj.z = obj.x;
    obj.e2 = E2.a;
}
