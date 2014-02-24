#!/usr/bin/env rdmd

module staticarray;

/** \file staticarray.d
 * \brief
 */

import std.stdio, std.algorithm;

struct StaticArray(T, size_t N)
{
    this() {
        if (n <= N)
            _a = _a10[0..n];
        else
            _a = new T[n];
    }

    ~this() {
        if (_a != _a10) delete _a;
    }

private:
    T[N] _a10;
    T[] _a;
}

unittest {
    StaticArray!(int, 10) tmp(n);
    int[] a = tmp[];
}
