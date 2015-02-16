#!/usr/bin/env rdmd-unittest-module

import std.stdio, std.algorithm;

class A
{
    int x;
}

unittest
{
    import std.typecons;
    auto rc1 = RefCounted!int(5);
    import dbg: dln;
    dln(rc1);
    /* This will no compile auto rcA = RefCounted!A(); */
 }
