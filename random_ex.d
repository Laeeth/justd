#!/usr/bin/env rdmd-dev-module

/** Extensions to std.random.
    Copyright: Per Nordlöw 2014-.
    License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
    Authors: $(WEB Per Nordlöw)
 */
module random_ex;

import std.traits: isIntegral, isFloatingPoint, isNumeric, isIterable, isStaticArray;
import std.range: isInputRange, ElementType, hasAssignableElements, isBoolean;
import std.random: uniform;

version = print;

version(print)
{
    import dbg;
}

/* nothrow: */

/** Generate Random Contents. */
auto ref randInPlace(E)(ref E x) @trusted if (isBoolean!E)
{
    return x = cast(bool)uniform(0, 2);
}

/** Generate Random Contents in $(D x) in range [$(D low), $(D high)]. */
auto ref randInPlace(E)(ref E x,
                        E low = E.min,
                        E high = E.max) @trusted if (isIntegral!E)
{
    return x = uniform(low, high);    // BUG: Never assigns the value E.max
}

/** Generate Random Contents in $(D x) in range [$(D low), $(D high)]. */
auto ref randInPlace(E)(ref E x,
                        E low = 0 /* E.min_normal */,
                        E high = 1 /* E.max */) @trusted if (isFloatingPoint!E)
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
    void testDynamic(T)()
    {
        auto x = new T[64];
        auto y = x.dup;
        x.randInPlace;
        y.randInPlace;
        assert(y != x);
    }
    testDynamic!bool;
    testDynamic!int;
    testDynamic!float;
}

/** Generate Random Contents in $(D x).
 */
auto ref randInPlace(T)(ref T x) @safe if (isStaticArray!T)
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
    void testStatic(T)()
    {
        T[64] x;
        auto y = x;
        x.randInPlace;
        y.randInPlace;
        assert(y != x);
    }
    testStatic!bool;
    testStatic!int;
    testStatic!float;
}

/** Generate Random Contents in members of $(D x).
 */
auto ref randInPlace(T)(ref T x) @safe if (is(T == struct))
{
    x.tupleof.randInPlace;
    return x;
}

unittest
{
    struct T { ubyte a, b; }
    T[64] x;
    auto y = x;
    x.randInPlace;
    version(print) dln(x);
    y.randInPlace;
    assert(y != x);
}

/** Generate Random Contents in members of $(D x).
 */
auto ref randInPlace(T)(T x) @safe if (is(T == class))
{
    x.tupleof.randInPlace;
    return x;
}

/* unittest */
/* { */
/*     class T { ubyte a, b; } */
/*     auto x = new T[64]; */
/*     auto y = x.dup; */
/*     x.randInPlace; */
/*     version(print) dln(x); */
/*     y.randInPlace; */
/*     assert(y != x); */
/* } */

alias randomize = randInPlace;

/** Get Random Instance of Type $(D T).
 */
T randomInstanceOf(T)() @safe
{
    T x = void;      // don't initialize because randInPlace fills in everything
    return x.randInPlace;
}

alias randOf = randomInstanceOf;

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
