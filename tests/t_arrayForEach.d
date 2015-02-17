#!/usr/bin/env rdmd-dev-module

unittest
{
    import std.algorithm.iteration: filter;
    import std.container: Array;

    Array!int a;
    foreach (e; a[].filter!"true") {}

    a ~= 1;
    a ~= 3;
    a ~= 2;
    a ~= 4;

    import std.algorithm.sorting: partialSort;
    a[].partialSort(0);
    import std.stdio;
    writeln(a[]);
}
