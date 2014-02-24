#!/usr/bin/env rdmd-dev-module

/** MathML.
    Copyright: Per Nordlöw 2014-.
    License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
    Authors: $(WEB Per Nordlöw)
*/
module mathml;

import rational: Rational;

/** Horizontal Alignment. */
enum HAlign { left, center, right }

/**
   Returns: MathML Representation of $(D x).
   See also: https://developer.mozilla.org/en-US/docs/Web/MathML/Element/mfrac
 */
string toMathML(T)(ref Rational!T x,
                   bool bevelled = false,
                   HAlign numalign = HAlign.center,
                   HAlign denomalign = HAlign.center,
                   string href = null) @safe pure {
    import std.conv: to;
    return (`<mfrac` ~
            (bevelled ? ` bevelled="true"` : ``) ~
            (numalign != HAlign.center ? ` numalign="` ~ to!string(numalign) ~ `"` : ``) ~
            (denomalign != HAlign.center ? ` denomalign="` ~ to!string(denomalign) ~ `"` : ``) ~
            `> <mi> `
            ~ to!string(x.numerator) ~ ` </mi> <mi> ` ~
            to!string(x.denominator) ~
            ` </mi> </mfrac>`);
}

unittest {
    alias Q = Rational;
    import dbg: dln;
    auto x = Q!ulong(11, 22);
    /* dln(x.toMathML); */
    /* dln(x.toMathML(true)); */
    /* dln(x.toMathML(true, HAlign.left, HAlign.left)); */
}
