#!/usr/bin/env rdmd

import std.stdio, std.algorithm, std.bitmanip;

struct Bits(int N) if(N > 0 && N <= 32) {}

private struct Struct {
    @Bits!3 ubyte bits3;
    @Bits!1 ubyte bits1;
    @Bits!4 uint bits4;
    ubyte bits8; //no UDA necessary
}

void main(string[] args) {
    alias dln = writeln;
    dln(Struct.sizeof);
    immutable bf = bitfields!(uint, "x",
                              2,
                              int, "y",
                              3,
                              uint, "z",
                              2,
                              bool, "flag", 1);
    struct A {
        int a;
        mixin(bf);
    }
    A obj;
    obj.a = 11;
    obj.x = 2;
    obj.z = obj.x;
    dln(obj);
    dln(bf);
}
