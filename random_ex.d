#!/usr/bin/env rdmd-dev-module

/** Extensions to std.random.
    Copyright: Per Nordlöw 2014-.
    License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
    Authors: $(WEB Per Nordlöw)
 */
module random_ex;

import std.traits: isIntegral, isFloatingPoint, isNumeric, isIterable;
import std.range: isInputRange, ElementType;
import std.random: uniform;

/** Generate Random Contents in $(D x) in range [$(D low), $(D high)]. */
auto ref randInPlace(T)(ref T x,
                        T low = T.min,
                        T high = T.max) @trusted /* nothrow */ if (isIntegral!T)
{
    return x = uniform(low, high);
}

/** Generate Random Contents in $(D x) in range [$(D low), $(D high)]. */
auto ref randInPlace(T)(ref T x,
                        T low = 0 /* T.min_normal */,
                        T high = 1 /* T.max */) @trusted /* nothrow */ if (isFloatingPoint!T)
{
    return x = uniform(low, high);
}

/** Generate Random Contents in $(D x).
 */
auto ref randInPlace(T)(auto ref T x) @safe /* nothrow */ if (isIterable!T)
{
    foreach (ref elt; x)
    {
        import std.range: ElementType;
        static if (isInputRange!(ElementType!T))
            elt[].randInPlace;
        else
            elt.randInPlace;
    }
    return x;
}

alias randomize = randInPlace;

unittest
{
    int[64] x;
    auto y = x;
    x.randInPlace;
    y.randInPlace;
    assert(y != x);
}

/** Get Random Instance of Type $(D T).
 */
T randGet(T)() @safe
{
    T x;
    return x.randInPlace;
}

void test(T, size_t length)()
{
    T[length] x;
    x.randInPlace;
}

unittest
{
    enum n = 3;
    test!(byte, n);
    test!(byte[2], n);
    test!(byte[2][2], n);
    test!(short, n);
    test!(int, n);
    test!(long, n);
    test!(double, n);
}
