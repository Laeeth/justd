#!/usr/bin/env rdmd-unittest-module

/** \file t_splitterJoiner.d
 * \brief
 */

import all;

void main(string[] args)
{
    auto a = "a  b   c   d e";
    auto b = a.splitter.joiner(" ");
    auto c = b.array;
    pragma(msg, typeof(b));
    writeln(b);
}
