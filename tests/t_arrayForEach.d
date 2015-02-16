#!/usr/bin/env rdmd-dev-module

unittest
{
    import std.algorithm.iteration: filter;
    import std.container: Array;

    Array!int a;
    foreach (e; a[].filter!"true") {}
}
