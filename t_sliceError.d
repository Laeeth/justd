#!/usr/bin/env rdmd-unittest-module

import std.stdio, std.algorithm;

void main(string[] args)
{
    int[] arr1 = [1, 2, 3].map!"a*2";
}
