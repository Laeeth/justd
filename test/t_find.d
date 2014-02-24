#!/usr/bin/env rdmd

module t_find;

/** \file t_find.d
 * \brief
 */

import std.stdio, std.algorithm;

void main(string[] args) {
    auto src = "alpha beta";
    auto key = "be";
    auto hit = src.find(key);
    writeln("hit-slice: ", hit[0..key.length]);
    writeln("hit-offset: ", hit.ptr - src.ptr);

    string[] keys;
    if (keys) { writeln("1"); } // should not print
    writeln(keys);

    keys ~= "alpha";
    if (keys) { writeln("2"); }
    writeln(keys);
}
