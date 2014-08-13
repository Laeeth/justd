#!/usr/bin/env rdmd-unittest-module

import std.stdio, std.algorithm, std.range, std.stdio, std.bitmanip;

void main(string args[])
{
    {
        float x = 1.23e10;
        auto y = *cast(FloatRep*)(&x);
        writeln(y.fraction, ", ",
                y.exponent, ", ",
                y.sign);
    }

    {
        double x = 1.23e10;
        auto y = *cast(DoubleRep*)(&x);
        writeln(y.fraction, ", ",
                y.exponent, ", ",
                y.sign);
    }
}
