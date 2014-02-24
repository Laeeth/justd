#!/usr/bin/env rdmd

module t_bench_cxx_d;

/** \file t_bench_cxx-d.d
 * \see http://stackoverflow.com/questions/5142366/how-fast-is-d-compared-to-c
 */

import std.stdio;
import std.datetime;
import std.random;

const long N = 20000;
const int size = 10;

alias int V;                    // Value Type
alias long R;                   // Result Type
alias V[] A;                    // Vector/Array Type
alias uint S;                   // Size Type

pure V scalar_product(const ref A x,
                      const ref A y) {
    V res = 0;
    auto siz = x.length;
    for (auto i = 0; i < siz; ++i)
        res += x[i] * y[i];
    return res;
}

int main() {
    auto tm_before = Clock.currTime();

    // 1. allocate and fill randomly many short vectors
    A[] xs;
    xs.length = N;
    for (int i = 0; i < N; ++i) {
        xs[i].length = size;
    }
    writefln("allocation: %s ", (Clock.currTime() - tm_before));
    tm_before = Clock.currTime();

    for (int i = 0; i < N; ++i)
        for (int j = 0; j < size; ++j)
            xs[i][j] = uniform(-1000, 1000);
    writefln("random: %s ", (Clock.currTime() - tm_before));
    tm_before = Clock.currTime();

    // 2. compute all pairwise scalar products:
    R avg = cast(R) 0;
    for (int i = 0; i < N; ++i)
        for (int j = 0; j < N; ++j)
            avg += scalar_product(xs[i], xs[j]);
    avg = avg / N*N;
    writefln("result: %d", avg);
    auto time = Clock.currTime() - tm_before;
    writefln("scalar products: %s ", time);

    return 0;
}
