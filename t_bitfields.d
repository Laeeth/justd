#!/usr/bin/env rdmd

import std.stdio, std.algorithm, std.bitmanip;

struct Bits(int N) if(N > 0 && N <= 32) {}

private struct S
{
    @Bits!3 ubyte bits3;
    @Bits!1 ubyte bits1;
    @Bits!4 uint bits4;
    ubyte bits8; //no UDA necessary
}

enum E2 { a, b, c, d }

void main(string[] args)
{
    writeln("S.sizeof: ", S.sizeof);

    immutable bf = bitfields!(uint, "x", 2,
                              int, "y", 2,
                              uint, "z", 2,
                              E2, "e2", 2);

    struct A
    {
        int a;
        mixin(bf);
    }


    A obj;
    obj.a = 11;
    obj.x = 2;
    obj.z = obj.x;

    writeln(obj);
    writeln(bf);
}
