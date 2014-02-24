#!/usr/bin/env rdmd

import std.stdio, std.algorithm;

void main(string[] args) {
    int[] a;
    int[] b;
    foreach (int i; a) {
        a = null; // error
        a.length += 10; // error
        a = b; // error
    }
    a = null; // ok
}
