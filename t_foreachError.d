#!/usr/bin/env rdmd-unittest-module

import std.stdio, std.algorithm;

void main(string[] args)
{
    class C
    {
    }
    C x;
    foreach (e; x)
    {
    }
}
