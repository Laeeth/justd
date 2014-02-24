#!/usr/bin/env rdmd

module t_static_analysis;

/** \file t_static-analysis.d
 * \brief
 */

import std.stdio;

void main(string[] args) {
    char x[2];
    x[2] = 1;
    immutable i = 2;
    x[i] = 2;
    x[i - 1] = 2;
    x[i + 1] = 2;

    // nullptr dereference
    const char* p = null;
    auto p_ = *p;
}
