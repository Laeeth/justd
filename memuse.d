#!/usr/bin/env rdmd-unittest-module

/** Memory Usage.
    Copyright: Per Nordlöw 2014-.
    License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
    Authors: $(WEB Per Nordlöw)
*/
module memuse;

import csunits;

/** Linear One-Dimensional Growth on index of type $(D D) with $(D ElementSize). */
struct Linear1D(D, size_t ElementSize) {}

/** Quadratic One-Dimensional Growth on index of type $(D D) with $(D ElementSize). */
struct Quadratic1D(D, size_t ElementSize) {}

/** Get Asymptotic Memory Usage of $(D x) in Bytes.
 */
template usageOf(T)
{
    import std.range: ElementType;
    import std.traits: isIntegral, isFloatingPoint, isNumeric, isIterable, isDynamicArray, isStaticArray, isArray, hasIndirections, isSomeString, isScalarType;
    static if (!hasIndirections!T)
    {
        enum usageOf = T.sizeof;
    }
    else static if (isDynamicArray!T &&
                    isScalarType!(ElementType!T))
    {
        alias usageOf = Linear1D!(size_t, ElementType!T.sizeof);
    }
    else
    {
        static assert(false, "Type " ~ T.stringof ~ "unsupported.");
    }
}

unittest
{
    import std.typecons: TypeTuple;
    foreach (T; TypeTuple!(byte, short, int, long,
                           ubyte, ushort, uint, ulong, char, wchar, dchar))
    {
        static assert(usageOf!T == T.sizeof);
    }

    struct S { int x, y; }
    static assert(usageOf!S == S.sizeof);

    foreach (T; TypeTuple!(byte, short, int, long))
    {
        static assert(is(usageOf!(T[]) ==
                         Linear1D!(size_t, T.sizeof)));
    }
}
