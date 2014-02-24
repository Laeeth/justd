#!/usr/bin/env rdmd-dev-module

/** Computer Science Units.
    Copyright: Per Nordlöw 2014-.
    License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
    Authors: $(WEB Per Nordlöw)
 */
module csunits;

import std.stdio, std.algorithm;

/** Prefix Multipliers.
    See also: http://searchstorage.techtarget.com/definition/Kilo-mega-giga-tera-peta-and-all-that
*/
enum prefixMultipliers {
    yocto = -24, // y
    zepto = -21, // z
    atto  = -18, // a
    femto = -15, // f
    pico  = -12, // p
    nano  =  -9, // n
    micro =  -6, // m
    milli =  -3, // m
    centi =  -2, // c
    deci  =  -1, // d
    none  =   0,
    deka  =   1, // D
    hecto =   2, // h
    kilo  =   3, // k
    mega  =   6, // M
    giga  =   9, // G
    tera  =  12, // T
    peta  =  15, // P
    exa   =  18, // E
    zetta =  21, // Z
    yotta =  24, // Y
}

/** Bytes (Count) Unit. */
struct Bytes(T = ulong) {
    /** Constructor Magic. */
    alias _value this;
    /* alias size_t T; */

    inout T value() @property inout @safe pure nothrow { return _value; }
    /**
       See also: http://searchstorage.techtarget.com/definition/Kilo-mega-giga-tera-peta-and-all-that
       See also: https://en.wikipedia.org/wiki/Exabyte
     */
    string toString() const @property @trusted /* pure nothrow */ {
        import std.traits: Unqual;
        immutable name = "Bytes"; // Unqual!(typeof(this)).stringof; // Unqual: "const(Bytes)" => "Bytes"
        import std.conv: to;
        if     (_value < 1024^^1) {
            return to!string(_value) ~ " " ~ name;
        } else if (_value < 1024^^2) {
            return to!string(cast(real)_value / 1024^^1) ~ " kilo" ~ name;
        } else if (_value < 1024^^3) {
            return to!string(cast(real)_value / 1024^^2) ~ " Mega" ~ name;
        } else if (_value < 1024^^4) {
            return to!string(cast(real)_value / 1024^^3) ~ " Giga" ~ name;
        } else if (_value < 1024^^5) {
            return to!string(cast(real)_value / 1024^^4) ~ " Tera" ~ name;
        } else if (_value < 1024^^6) {
            return to!string(cast(real)_value / 1024^^5) ~ " Peta" ~ name;
        } else if (_value < 1024^^7) {
            return to!string(cast(real)_value / 1024^^6) ~ " Exa" ~ name;
        } else if (_value < 1024^^8) {
            return to!string(cast(real)_value / 1024^^7) ~ " Zetta" ~ name;
        } else /* if (_value < 1024^^9) */ {
            return to!string(cast(real)_value / 1024^^8) ~ " Yotta" ~ name;
        /* } else { */
        /*     return to!string(_value) ~ " " ~ name; */
        }
    }

    T opUnary(string op, string file = __FILE__, int line = __LINE__)() {
        T tmp = void; mixin("tmp = " ~ op ~ " _value;"); return tmp; }
    T opBinary(string op, string file = __FILE__, int line = __LINE__)(T rhs) {
        T tmp = void; mixin("tmp = _value " ~ op ~ "rhs;"); return tmp; }
    T opOpAssign(string op, string file = __FILE__, int line = __LINE__)(T rhs) {
        mixin("_value = _value " ~ op ~ "rhs;"); return _value; }
    T opAssign(T rhs, string file = __FILE__, int line = __LINE__) {
        return _value = rhs; }
// private:
    T _value;
}

/** Instantiator for \c Bytes. Allows syntax 42.bytes. */
auto bytes(T)(T value) { return Bytes!T(value); }

unittest {
    immutable a = bytes(1);
    immutable b = bytes(1);
    immutable c = a + b;
    assert(c == 2);
    immutable d = a;
    assert(1.bytes == 1);
}

auto inPercent       (T)(T a) { return to!string(a * 1e2) ~ " \u0025"; }
auto inPerMille      (T)(T a) { return to!string(a * 1e3) ~ " \u2030"; }
auto inPerTenThousand(T)(T a) { return to!string(a * 1e4) ~ " \u2031"; }
auto inDegrees       (T)(T a) { return to!string(a      ) ~ " \u00B0"; }
/* unittest { */
/*     dln(0.79.inPercent); */
/*     dln(0.0079.inPerMille); */
/*     dln(0.000079.inPerTenThousand); */
/* } */
