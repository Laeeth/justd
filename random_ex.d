#!/usr/bin/env rdmd-dev-module

/** Generate Randomized Instances.

    Copyright: Per Nordlöw 2014-.
    License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
    Authors: $(WEB Per Nordlöw)

    See also: http://forum.dlang.org/thread/byonwfghdqgcirdjyboh@forum.dlang.org

    TODO: Tags as nothrow when std.random gets there.

    TODO: How to handle possibly null reference (class, dynamic types) types?
    Answer relates to how to randomize empty/null variable length structures
    (arrays, strings, etc).
    - Maybe some kind of length randomization?
 */
module random_ex;

import std.traits: isIntegral, isFloatingPoint, isNumeric, isIterable, isStaticArray, hasIndirections;
import std.range: isInputRange, ElementType, hasAssignableElements, isBoolean;
import std.random: uniform;

version(unittest) private enum testLength = 64;

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
    foreach (ref e; x)
    {
        e.randInPlace;
    }
    return x;
}

unittest
{
    void testDynamic(T)()
    {
        auto x = new T[testLength];
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
    foreach (ref e; x)
    {
        e.randInPlace;
    }
    return x;
}

unittest
{
    void testStatic(T)()
    {
        T[testLength] x;
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
    foreach (ref e; x.tupleof)
    {
        e.randInPlace;
    }
    return x;
}

unittest
{
    struct T { ubyte a, b, c, d; }
    T[testLength] x;
    auto y = x;
    x.randInPlace;
    y.randInPlace;
    assert(y != x);
}

/** Generate Random Contents in members of $(D x).
 */
auto ref randInPlace(T)(T x) @safe if (is(T == class))
{
    foreach (ref e; x.tupleof)
    {
        e.randInPlace;
    }
    return x;
}

unittest
{
    void testClass(E)()
    {
        class T { E a, b; }
        auto x = new T;
        auto y = new T;
        x.randInPlace;
        y.randInPlace;
        assert(y != x);
    }
    testClass!bool;
    testClass!int;
    testClass!float;
}

/** Get New Randomized Instance of Type $(D T).
 */
T randomInstanceOf(T)() @safe
{
    /* TODO: recursively only void-initialize parts of T that are POD, not
     reference types */
    static if (hasIndirections!T)
        T x;
    else
        /* don't init - randInPlace below fills in everything safely */
        T x = void;
    return x.randInPlace;
}

alias randomize = randInPlace;
alias randomized = randomInstanceOf;
