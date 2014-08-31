#!/usr/bin/env rdmd-dev

/** Longest Common Subsequence, typically used as a base for writing diff/compare algorithms.
    Copyright: Per Nordlöw 2014-.
    License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
    Authors: $(WEB Per Nordlöw)
*/

module lcs;

import std.algorithm: empty, max;
import std.algorithm: reverse;
import std.traits: Unqual;

/** Longest Common Subsequence (LCS)
    See also: http://rosettacode.org/wiki/Longest_common_subsequence#Recursive_version
*/
T[] lcsR(T)(in T[] a, in T[] b) @safe pure nothrow
{
    if (a.empty || b.empty)
    {
        return null;            // undefined
    }
    if (a[0] == b[0])
    {
        return a[0] ~ lcsR(a[1 .. $],
                           b[1 .. $]);
    }
    const longest = (T[] x, T[] y) => x.length > y.length ? x : y;
    return longest(lcsR(a, b[1 .. $]),
                   lcsR(a[1 .. $], b));
}

/** Longest Common Subsequence (LCS).
    Faster dynamic programming version.
    http://rosettacode.org/wiki/Longest_common_subsequence#Faster_dynamic_programming_version
*/
T[] lcsDP(T)(in T[] a, in T[] b) @safe pure /* nothrow */
{
    auto L = new uint[][](a.length + 1, b.length + 1);

    foreach (immutable i; 0 .. a.length)
    {
        foreach (immutable j; 0 .. b.length)
        {
            L[i + 1][j + 1] = (a[i] == b[j]) ? (1 + L[i][j]) :
                max(L[i + 1][j], L[i][j + 1]);
        }
    }

    Unqual!T[] result;
    for (auto i = a.length, j = b.length; i > 0 && j > 0; )
    {
        if (a[i - 1] == b[j - 1])
        {
            result ~= a[i - 1];
            i--;
            j--;
        }
        else
        {
            if (L[i][j - 1] < L[i - 1][j])
                i--;
            else
                j--;
        }
    }

    result.reverse(); // Not nothrow.
    return result;
}

/** Longest Common Subsequence (LCS) using Hirschberg.
    Faster dynamic programming version.
    http://rosettacode.org/wiki/Longest_common_subsequence#Hirschberg_algorithm_version
*/

uint[] lensLCS(R)(R xs, R ys) pure nothrow @safe
{
    auto prev = new typeof(return)(1 + ys.length);
    auto curr = new typeof(return)(1 + ys.length);

    foreach (immutable x; xs)
    {
        import std.algorithm: swap;
        swap(curr, prev);
        size_t i = 0;
        foreach (immutable y; ys)
        {
            curr[i + 1] = (x == y) ? prev[i] + 1 : max(curr[i], prev[i + 1]);
            i++;
        }
    }

    return curr;
}

void calculateLCS(T)(in T[] xs, in T[] ys,
                     bool[] xs_in_lcs,
                     in size_t idx = 0)
    pure nothrow @safe
{
    immutable nx = xs.length;
    immutable ny = ys.length;

    if (nx == 0)
        return;

    if (nx == 1)
    {
        import std.algorithm: canFind;
        if (ys.canFind(xs[0]))
            xs_in_lcs[idx] = true;
    } else {
        immutable mid = nx / 2;
        const xb = xs[0.. mid];
        const xe = xs[mid .. $];
        immutable ll_b = lensLCS(xb, ys);

        import std.range: retro;
        const ll_e = lensLCS(xe.retro,
                             ys.retro); // retro is slow with dmd.

        //immutable k = iota(ny + 1)
        //              .reduce!(max!(j => ll_b[j] + ll_e[ny - j]));
        import std.range: iota;
        import std.algorithm: minPos;
        import std.typecons: tuple;
        immutable k = iota(ny + 1)
                      .minPos!((i, j) => tuple(ll_b[i] + ll_e[ny - i]) >
                                         tuple(ll_b[j] + ll_e[ny - j]))[0];

        calculateLCS(xb, ys[0 .. k], xs_in_lcs, idx);
        calculateLCS(xe, ys[k .. $], xs_in_lcs, idx + mid);
    }
}

const(T)[] lcs(T)(in T[] xs, in T[] ys) pure /*nothrow*/ @safe
{
    auto xs_in_lcs = new bool[xs.length];
    calculateLCS(xs, ys, xs_in_lcs);
    import std.range: zip, filter, map;
    import std.array: array;
    return zip(xs, xs_in_lcs).filter!q{ a[1] }.map!q{ a[0] }.array; // Not nothrow.
}

string lcs(in string s1,
           in string s2) pure /*nothrow*/ @safe
{
    import std.string: representation, assumeUTF;
    return lcs(s1.representation,
               s2.representation).assumeUTF;
}

unittest
{
    auto x = "thisisatest";
    auto y = "testing123testing";
    auto z = "tsitest";
    assert(z == lcsR(x, y));
    assert(z == lcsDP(x, y));
    assert(z == lcs(x, y));
    assert("" == lcs("", ""));
    assert("" == lcs(null, null));
}
