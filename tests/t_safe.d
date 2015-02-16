#!/usr/bin/env rdmd

module t_safe;

/** \file t_safe.d
 * \brief
 */

import std.stdio, std.algorithm;
// pragma(lib, "scid");

@safe auto foo() {
    int* x = null;
    return *x;                  // this should segfault
}

void main(string[] args)
{
    foo();
}
