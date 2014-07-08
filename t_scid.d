#!/usr/bin/env rdmd-dev

import std.stdio, std.algorithm, scid.matrix;
pragma(lib, "scid");

void main(string[] args) {
    auto denseMatrix = matrix!real(3, 4);
}
