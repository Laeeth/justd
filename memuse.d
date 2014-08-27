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

import std.range: ElementType;
import std.traits: isIntegral, isFloatingPoint, isNumeric, isIterable, isDynamicArray, isStaticArray, isArray, hasIndirections, isSomeString, isScalarType;
import std.typecons: TypeTuple, Nullable;

/** Get Asymptotic Memory Usage of $(D x) in Bytes.
 */
template UsageOf(T)
{
    static if (!hasIndirections!T)
    {
        enum UsageOf = T.sizeof;
    }
    else static if (isDynamicArray!T &&
                    isScalarType!(ElementType!T))
    {
        alias UsageOf = Linear1D!(size_t, ElementType!T.sizeof);
    }
    else static if (isDynamicArray!T &&
                    isDynamicArray!(ElementType!T) &&
                    isScalarType!(ElementType!(ElementType!T)))
    {
        alias UsageOf = Quadratic1D!(size_t, ElementType!T.sizeof);
    }
    else
    {
        static assert(false, "Type " ~ T.stringof ~ "unsupported.");
    }

    /** Maybe Minimum Usage in bytes. */
    /* size_t min() { return 0; } */

    /** Maybe Maximum Usage in bytes. */
    /* Nullable!size_t max() { return 0; } */
}

unittest
{
    foreach (T; TypeTuple!(byte, short, int, long,
                           ubyte, ushort, uint, ulong, char, wchar, dchar))
    {
        static assert(UsageOf!T == T.sizeof);
    }

    struct S { int x, y; }
    static assert(UsageOf!S == S.sizeof);

    foreach (T; TypeTuple!(byte, short, int, long))
    {
        static assert(is(UsageOf!(T[]) ==
                         Linear1D!(size_t, T.sizeof)));
    }
}
