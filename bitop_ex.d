#!/usr/bin/env rdmd-dev-module

/** Various extensions to core.bitop and std.bitmanip.
    Copyright: Per Nordlöw 2014-.
    License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
    Authors: $(WEB Per Nordlöw)
*/
module bitop_ex;

import std.traits: isIntegral;
import std.typetuple: allSatisfy;

/** Get an Unsigned Type of size as $(D T) if possible. */
template UnsignedOfSameSizeAs(T)
{
    enum nBits = 8*T.sizeof;
    static      if (nBits ==  8) alias UnsignedOfSameSizeAs = ubyte;
    else static if (nBits == 16) alias UnsignedOfSameSizeAs = ushort;
    else static if (nBits == 32) alias UnsignedOfSameSizeAs = uint;
    else static if (nBits == 64) alias UnsignedOfSameSizeAs = ulong;
    else static if (nBits == 128) alias UnsignedOfSameSizeAs = ucent;
    else {
        import std.conv: to;
        static assert(false, "No Unsigned type of size " ~ to!string(nBits) ~ " found");
    }
}

/** Returns: Zero Instance T with $(D bix):th Bit set. */
T makeBit(T, I...)(I bixs) @safe @nogc pure nothrow if (isIntegral!T &&
                                                        allSatisfy!(isIntegral, I))
    in { foreach (bix; bixs) { assert(0 <= bix && bix < 8*T.sizeof); } }
body {
    typeof(return) x;
    foreach (bix; bixs)
        x |= cast(T)((cast(T)1) << bix);
    return x;
}
alias btm = makeBit;
unittest {
    assert(makeBit!int(2) == 4);
    assert(makeBit!int(2, 3) == 12);
}

/** Returns: Check if all $(D bix):th Bits Of $(D a) are set. */
bool getBit(T, I...)(in T a, I bixs) @safe @nogc pure nothrow if (isIntegral!T &&
                                                                  allSatisfy!(isIntegral, I))
{
    return a & makeBit!T(bixs) ? true : false;
}
/** Returns: Check if all $(D bix):th Bits Of $(D a) are set. */
bool getBit(T, I)(in T a, I bix) @trusted @nogc pure nothrow if ((!(isIntegral!T)) &&
                                                                 allSatisfy!(isIntegral, I))
{
    return (*(cast(UnsignedOfSameSizeAs!T*)&a)).getBit(bix); // reuse integer variant
}
alias bt = getBit;
void testGetBit(T)() {
    const mn = T.min, mx = T.max;
    enum nBits = 8*T.sizeof;
    foreach (ix; 0..nBits-1) { assert(!mn.bt(ix)); }
    assert(mn.bt(nBits - 1));
    foreach (ix; 0..T.sizeof) { assert(mx.bt(ix)); }
}
unittest {
    testGetBit!byte;
    testGetBit!short;
    testGetBit!int;
    testGetBit!long;
}

/** Test and sets the $(D bix):th Bit Of $(D a) to one.
    Returns: A non-zero value if the bit was set, and a zero if it was clear.
*/
void setBit(T, I...)(ref T a, I bixs) @safe @nogc pure nothrow if (isIntegral!T &&
                                                                   allSatisfy!(isIntegral, I)) {
    a |= makeBit!T(bixs);
}
/** Returns: Check if all $(D bix):th Bits Of $(D a) are set. */
void setBit(T, I...)(ref T a, I bixs) @trusted @nogc pure nothrow if ((!(isIntegral!T)) &&
                                                                      allSatisfy!(isIntegral, I)) {
    alias U = UnsignedOfSameSizeAs!T;
    (*(cast(U*)&a)) |= makeBit!U(bixs); // reuse integer variant
}
alias bts = setBit;
unittest {
    alias T = int;
    enum nBits = 8*T.sizeof;
    T x = 0;
    x.bts(0); assert(x == 1);
    x.bts(1); assert(x == 3);
    x.bts(2); assert(x == 7);

    T b = 0;
    b.bts(nBits - 1);
    assert(b == T.min);
}
void testSetBit(T)() {
    enum nBits = 8*T.sizeof;
    T x = 0;
    x.bts(0);
    /* import dbg: dln; */
    /* dln(x); */
    /* dln(T.epsilon); */
}
unittest {
    testSetBit!float;
    testSetBit!double;
}

/* alias btc = complementBit; */
/* alias btr = resetBit; */
