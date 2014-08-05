#!/usr/bin/env rdmd-dev-module

/** MathML.
    Copyright: Per Nordlöw 2014-.
    License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
    Authors: $(WEB Per Nordlöw)
*/
module mathml;

import rational: Rational;
import std.traits: isScalarType;

/** Horizontal Alignment. */
enum HAlign { left, center, right }

/* Generic case. */
string toMathML(T)(T x) @trusted /* pure */ if (isScalarType!T)
{
    import std.conv: to;
    return to!string(x);
}

/**
   Returns: MathML Representation of $(D x).
   See also: https://developer.mozilla.org/en-US/docs/Web/MathML/Element/mfrac
 */
string toMathML(T)(Rational!T x,
                   bool bevelled = false,
                   HAlign numalign = HAlign.center,
                   HAlign denomalign = HAlign.center,
                   string href = null) @safe pure
{
    import std.conv: to;
    return (`<math><mfrac` ~
            (bevelled ? ` bevelled="true"` : ``) ~
            (numalign != HAlign.center ? ` numalign="` ~ to!string(numalign) ~ `"` : ``) ~
            (denomalign != HAlign.center ? ` denomalign="` ~ to!string(denomalign) ~ `"` : ``) ~
            `><mi>`
            ~ to!string(x.numerator) ~ `</mi><mi>` ~
            to!string(x.denominator) ~
            `</mi></mfrac></math>`);
}

unittest {
    alias Q = Rational;
    import dbg: dln;
    auto x = Q!ulong(11, 22);
    /* dln(x.toMathML); */
    /* dln(x.toMathML(true)); */
    /* dln(x.toMathML(true, HAlign.left, HAlign.left)); */
}
