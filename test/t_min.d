#!/usr/bin/env rdmd

module t_min;

import std.algorithm, std.range;

auto min(R)(R range) if (isInputRange!R && is(typeof(range.front < range.front) == bool)) {
    auto result = range.front;
    range.popFront();
    foreach (e; range) {
        if (e < result) result = e;
    }
    return result;
}

void main(string[] args) {
    auto m = min([ 1, 5, 2, 0, 7, 9 ]);
}
