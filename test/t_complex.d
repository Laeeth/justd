#!/usr/bin/env rdmd-dev-module

import std.stdio, std.algorithm, std.traits, std.complex;

unittest
{
    double re;
    idouble im;
    alias C = CommonType!(double, idouble);
    C c;
    writeln(typeof(re).stringof, ",", typeof(im).stringof, ",", C.stringof);
    writeln(re + im);
}

unittest
{
    double re;
    idouble im;
    alias C = CommonType!(double, idouble);
    auto c = complex(3.0, 4.0);
    writeln(c);
    writeln(typeof(re).stringof, ",", typeof(im).stringof, ",", C.stringof);
}
