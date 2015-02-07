#!/usr/bin/env rdmd-unittest-module

/** \file t_splitterJoiner.d
 * \brief
 */

import all;

void main(string[] args)
{
    auto a = "a  b   c   d e";
    pragma(msg, typeof(a));
    writeln("a: ", a);

    auto b = a.splitter.joiner(" ");
    pragma(msg, typeof(b));
    writeln("b: ", b);

    auto c = b.array;
    pragma(msg, typeof(c));
    writeln("c: ", c);
}
