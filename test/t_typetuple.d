#!/usr/bin/env rdmd-dev

module t_typetuple;

/** \file t_typetuple.d
 * \brief
 */

import std.stdio, std.algorithm;
// pragma(lib, "scid");

void main(string[] args)
{
    import std.typetuple;
    alias TypeTuple!(int, long, double) Types;
    foreach (T; Types)
        test!T();
}

unittest {

}
