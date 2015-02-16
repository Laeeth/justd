#!/usr/bin/env rdmd-unittest-module

import std.stdio, std.algorithm;

void main(string[] args)
{
    {
        int  x = [1, 2, 3].map!"a*2";
    }
    {
        int[] x = [1, 2, 3].map!"a*2";
    }
}
