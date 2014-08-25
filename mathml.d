#!/usr/bin/env rdmd-dev-module

/** MathML.
    Copyright: Per Nordlöw 2014-.
    License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
    Authors: $(WEB Per Nordlöw)
*/
module mathml;

import rational: Rational; // TODO: Can we turn this dep into a duck type dep?
import std.traits: isScalarType, isFloatingPoint;

/** Horizontal Alignment. */
enum HAlign { left, center, right }

/** Generic case. */
string toMathML(T)(T x) @trusted /* pure nothrow */ if (isScalarType!T &&
                                                 !isFloatingPoint!T)
{
    import std.conv: to;
    return to!string(x);
}

enum MLang { HTML, MathML };

/** Floating-Point Case.
    See also: http://forum.dlang.org/thread/awkynfizwqjnbilgddbh@forum.dlang.org#post-awkynfizwqjnbilgddbh:40forum.dlang.org
    See also: https://developer.mozilla.org/en-US/docs/Web/MathML/Element/mn
    See also: https://developer.mozilla.org/en-US/docs/Web/MathML/Element/msup
 */
string toML(T)(T x,
               bool forceExponentPlusSign = false,
               MLang mlang = MLang.HTML) @trusted /* pure nothrow */ if (isFloatingPoint!T)
{
    import std.conv: to;
    import std.algorithm: findSplit;
    const parts = to!string(x).findSplit("e"); // TODO: Use std.bitmanip.FloatRep instead
    if (parts[2].length >= 1)
    {
        const mantissa = parts[0];
        const exponent = ((!forceExponentPlusSign &&
                           parts[2][0] == '+') ? // if leading plus
                          parts[2][1..$] : // skip plus
                          parts[2]); // otherwise whole
        final switch (mlang)
        {
            case MLang.HTML: return (mantissa ~ `&middot;` ~ `10` ~ `<msup">` ~ exponent ~ `</msup>`);
            case MLang.MathML: return (`<math>` ~ mantissa ~ `&middot;` ~
                                       `<msup>` ~
                                       `<mn>10</mn>` ~
                                       `<mn mathsize="80%">` ~ exponent ~ `</mn>`
                                       `</msup>` ~
                                       `</math>`);
        }
        /* NOTE: This doesn't work in Firefox. Why? */
        /* return (`<math>` ~ parts[0] ~ `&middot;` ~ */
        /*         `<apply><power/>` ~ */
        /*         `<ci>10</ci>` ~ */
        /*         `<cn>` ~ parts[2] ~ `</cn>` */
        /*         `</apply>` ~ */
        /*         `</math>`); */
    }
    else
    {
        return parts[0];
    }
}

auto toMathML(T)(T x,
                 bool forceExponentPlusSign = false) @trusted /* pure nothrow */ if (isFloatingPoint!T)
{
    return toML(x, forceExponentPlusSign, MLang.HTML);
}

auto toHTML(T)(T x,
               bool forceExponentPlusSign = false) @trusted /* pure nothrow */ if (isFloatingPoint!T)
{
    return toML(x, forceExponentPlusSign, MLang.MathML);
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
    /** dln(x.toMathML); */
    /** dln(x.toMathML(true)); */
    /** dln(x.toMathML(true, HAlign.left, HAlign.left)); */
}
