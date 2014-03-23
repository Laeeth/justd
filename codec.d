#!/usr/bin/env rdmd-unittest-module

/** Codecs.
    Copyright: Per Nordlöw 2014-.
    License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
    Authors: $(WEB Per Nordlöw)
*/
module codec;

import std.typecons: Tuple;
import std.range: tuple, isInputRange, ElementType;
import algorithm_ex: forwardDifference;

/** Pack $(D r) using a forwardDifference.
    TODO: Can we tag this as nothrow when MapResult becomes nothrow?
*/
auto packForwardDifference(R)(R r) if (isInputRange!R)
{
    import std.range: front;
    return tuple(r.front, forwardDifference(r)); // TODO: Use named parts?
}

auto unpackForwardDifference(E, R)(Tuple!(E, R) x)
    if (isInputRange!R &&
        is(ElementType!R == typeof(E - E)))
{
    import std.array: array;

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

unittest {
    import std.range: front, dropOne;
    import std.exception: assertThrown, AssertError;

    assertThrown!AssertError([1].dropOne.packForwardDifference);

    auto x1 = [1];
    assert(x1 == x1.packForwardDifference.unpackForwardDifference);

    auto x2 = [1, 22];
    assert(x2 == x2.packForwardDifference.unpackForwardDifference);

    auto x3 = [1, -22, 333];
    assert(x3 == x3.packForwardDifference.unpackForwardDifference);

    auto x4 = [1, -333, 22, 1000, -1100];
    assert(x4 == x4.packForwardDifference.unpackForwardDifference);
}
