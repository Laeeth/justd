#!/usr/bin/env rdmd-unittest-module

/** Codecs.
    Copyright: Per Nordlöw 2014-.
    License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
    Authors: $(WEB Per Nordlöw)
*/
module codec;

import std.typecons: Tuple;
import std.range: front, tuple, isInputRange, ElementType;
import algorithm_ex: forwardDifference;
import std.array: array;

/** Packing of $(D r) using a forwardDifference.
 */
struct ForwardDifferencePack(R) if (isInputRange!R)
{
    this(R r)
    {
        _front = r.front;
        _diff = r.forwardDifference.array; // TODO: Can we make msgpack pack r.forwardDifference without .array?
    }
private:
    typeof(R.init.front) _front; // First element
    typeof(R.init.forwardDifference.array) _diff; // The Difference
}

/** Instantiator for $(D ForwardDifferencePack).
 */
auto packForwardDifference(R)(R r) if (isInputRange!R)
{
    return ForwardDifferencePack!R(r); // TODO: Use named parts?
}

/** Pack $(D r) using a forwardDifference.
*/
auto packForwardDifference_alt(R)(R r) if (isInputRange!R)
{
    return tuple(r.front,
                 r.forwardDifference); // TODO: Use named parts?
}

auto unpackForwardDifference(E, R)(Tuple!(E, R) x)
    if (isInputRange!R &&
        is(ElementType!R == typeof(E - E)))
{
    /* TODO: Extract as ForwardSum */
    auto diffs = x[1]; // differences
    immutable n = diffs.array.length;
    auto y = new E[1 + n]; // TODO: Remove array and keep extra length argument in forwardDifference
    y[0] = x[0];
    auto a = diffs.array;
    foreach (ix; 0..n) {
        y[ix + 1] = y[ix] + a[ix];
    }
    return y;
}

unittest
{
    import std.range: dropOne;
    import std.exception: assertThrown, AssertError;
    import msgpack;
    import dbg: dln;

    assertThrown!AssertError([1].dropOne.packForwardDifference_alt);

    auto x = [1, int.min, 22, 0, int.max, -1100];

    // in memory pack and unpack
    auto pfd = x.packForwardDifference_alt;
    /* dln(pfd.pack); */
    assert(x == pfd.unpackForwardDifference);

    auto fdp = x.packForwardDifference;
    alias FDP = typeof(fdp);
    auto raw = fdp.pack;
    auto raw2 = raw.dup;
    /* dln(raw); */

    FDP fdp_;                   // restored
    raw.unpack(fdp_);           // restore it
    assert(fdp == fdp_);

    auto fdp__ = raw2.unpack!FDP; // restore it (alternatively)
    assert(fdp == fdp__);
}
