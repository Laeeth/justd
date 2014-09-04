#!/usr/bin/env rdmd-unittest-module

/** \file t_repeat_replicate.d
 * \brief
 */

import std.stdio, std.algorithm, std.range;

unittest
{
    auto n = 10;
    string t1; t1 ~= '*'.repeat(n).array;
    string t2; t2 ~= "*".replicate(n);
    assert(t1 == t2);
    writeln(t1);
    writeln(t2);
}
