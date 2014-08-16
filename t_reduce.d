#!/usr/bin/env rdmd-unittest

/** \file t_reduce.d
 * \brief
 */

import std.stdio, std.algorithm, std.range, std.traits;

void main(string args[])
{
    writeln(0.reduce!"a+b"([1, 2, 3]));
    // writeln([1, 2, 3].reduce!"a+b"(0));
}
