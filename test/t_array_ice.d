#!/usr/bin/env rdmd-unittest-module

unittest {
    const x = [1];
    assert(x[] + x[]);
}
