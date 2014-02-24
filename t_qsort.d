#!/usr/bin/env rdmd-release

/**
  Task-Parallel Quicksort in D.
 */
import std.array;
import std.stdio;
import std.algorithm;
import std.parallelism;
import std.conv;
import std.exception;
import std.range;
import std.string;
import std.traits;

/** Python-Style Alias. */
string str(T)(T x) { return to!string(x); }

/** Nice Aliases. */
alias writeln wrln;
alias isOrdered = isSorted;

/** Evaluate exp n times like in Lisp. */
void dotimes(uint n, lazy void exp) { while (n--) exp(); }

/** Sorts an Array \p a using a \em Parallel Quick Sort Algorithm.
 *
 * The first partition
 * is done serially. Both recursion
 * branches are then executed in
 * parallel.
 * Timings for sorting an array of 1,000,000 doubles on
 * an
 * Athlon 64 X2 Dual Core Machine
 * This implementation: 176 milliseconds.
 * Equivalent serial implementation: 280 milliseconds void
 */
void parallelSort(T)(T[] a)
{
    // Sort small subarrays serially.
    if (a.length < 100) {       // todo: find this limits through benchmarks
        std.algorithm.sort(a);
        return;
    }

    // Partition the array.
    swap(a[$ / 2], a[$ - 1]);
    auto pivot = a[$ - 1];

    bool ltPivot(T elem) { return elem < pivot; } // less than pivot

    auto ge = partition!ltPivot(a[0..$ - 1]); // greater than or equal
    swap(a[$ - ge.length - 1], a[$ - 1]);

    auto less = a[0..$ - ge.length - 1]; // less than
    ge = a[$ - ge.length..$];

    // Execute both recursion branches in parallel.
    auto recurseTask = task!(parallelSort)(ge);
    taskPool.put(recurseTask);
    parallelSort(less);
    recurseTask.yieldForce;
}

void testSort(T, bool useStatic = false)(size_t n, bool show = false)
{
    // allocate
    static if (useStatic) {
        T a[n];
    } else {
        auto a = new T[n];
    }

    // sort
    std.algorithm.sort(a);
    parallelSort(a);
    assert(std.algorithm.isSorted(a)); // verify result

    // show result
    if (show) {
        writeln(a);
    }
}

void testAll(T)()
{
    for (size_t i = 2; i <= 15; i++) {
        testSort!T(i);
    }
    for (size_t i = 16; i <= 4096 * 64 * 4; i *= 2) {
        testSort!T(i);
    }
}

void main(string[] args)
{
    testAll!int();
    testAll!long();
    testAll!float();
    testAll!double();
    testAll!double();
}
