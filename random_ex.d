#!/usr/bin/env rdmd-dev-module

/** Extensions to std.random.
    Copyright: Per Nordlöw 2014-.
    License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
    Authors: $(WEB Per Nordlöw)
 */
module random_ex;

import std.traits: isIntegral, isFloatingPoint, isNumeric, isIterable, isStaticArray;
import std.range: isInputRange, ElementType, hasAssignableElements;
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
auto ref randInPlace(R)(R x) @safe if (hasAssignableElements!R)
{
    foreach (ref elt; x)
    {
        import std.range: ElementType;
        static if (isInputRange!(ElementType!R))
            elt[].randInPlace;
        else
            elt.randInPlace;
    }
    return x;
}

unittest
{
    auto x = new int[64];
    auto y = x.dup;
    x.randInPlace;
    y.randInPlace;
    assert(y != x);
}

/** Generate Random Contents in $(D x).
 */
auto ref randInPlace(T)(ref T x) @safe /* nothrow */ if (isStaticArray!T)
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

unittest
{
    int[64] x;
    auto y = x;
    x.randInPlace;
    y.randInPlace;
    assert(y != x);
}

alias randomize = randInPlace;

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
