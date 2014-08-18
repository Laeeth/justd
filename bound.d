#!/usr/bin/env rdmd-dev-module

/** Bounded Arithmetic Wrapper Type, similar to Ada Range Types.

    Copyright: Per Nordlöw 2014-.
    License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
    Authors: $(WEB Per Nordlöw)

    See also: http://stackoverflow.com/questions/18514806/ada-like-types-in-nimrod
    See also: https://bitbucket.org/davidstone/bounded_integer
    See also: http://forum.dlang.org/thread/xogeuqdwdjghkklzkfhl@forum.dlang.org#post-rksboytciisyezkapxkr:40forum.dlang.org
    See also: http://forum.dlang.org/thread/lxdtukwzlbmzebazusgb@forum.dlang.org#post-ymqdbvrwoupwjycpizdi:40forum.dlang.org

    TODO: Make this work:
    wln(bound!(256, 257)(256));
    wln(bound!(256, 257)(257));

    TODO: Propagate ranges in arithmetic (opUnary, opBinary, opOpAssign):
    - Integer: +,-,*,^^,/
    - FloatingPoint: +,-,*,/,^^,sqrt,
    - and add intelligent warnings/errors when assignment and implicit cast is
    not allowed showing the range of the expression/inferred variable.

    TODO: Implicit conversions to unbounded integers?
    Not in https://bitbucket.org/davidstone/bounded_integer.
    const sb127 = saturated!byte(127);
    const byte b = sb127; // TODO: this shouldn't compile if this is banned

    TODO: Add static asserts using template-arguments?
    TODO: Do we need a specific underflow?
    TODO: Add this module to std.numeric

    TODO: Merge with limited

    TODO: Is this a good idea to use?:
    import std.typecons;
    mixin Proxy!_t;             // Limited acts as T (almost).
    invariant() {
    enforce(_t >= lower && _t <= upper);
    wln("fdsf");

    TODO: If these things take to long to evaluted at compile-time maybe we need
    to build it into the language for example using a new syntax either using
    - integer(range:low..high, step:1)
    - int(range:low..high, step:1)
    - num(range:low..high, step:1)

    TODO: Use
    T saveOp(string op, T)(T x, T y) pure @save @nogc if(isIntegral!T
    && (op=="+" || op=="-" || op=="<<" || op=="*"))
    {
    mixin("x "~op~"= y");
    static if(isSigned!T)
    {
    static if(op == "*")
    {
    asm naked { jnc opok; }
    }
    else
    {
    asm naked { jno opok; }
    }
    x = T.min;
    }
    else // unsigned
    {
    asm naked { jnc opok; }
    x = T.max;
    }
    opok:
    return x;
    }

    TODO: Reuse core.checkedint

 */
module bound;

import std.conv: to;
import std.traits: CommonType, isIntegral, isUnsigned, isFloatingPoint;

version = print;

// import std.exception;
// class BoundUnderflowException : Exception {
//     this(string msg) { super(msg); }
// }

/** Exception thrown when $(D Bound) values overflows or underflows. */
class BoundOverflowException : Exception
{
    this(string msg) { super(msg); }
}

/** Value of Type $(D T) bound inside Inclusive Range [lower, upper].

    If $(D optional) is true this stores one extra undefined state (similar to Haskell's Maybe).

    If $(D exceptional) is true range errors will throw a
    $(D BoundOverflowException), otherwise truncation plus warnings will issued.
*/
struct Bound(T,
             B = T, // bounds type
             B lower = B.min,
             B upper = B.max,
             bool optional = false,
             bool exceptional = true)
{
    /* Requirements */
    static assert(lower < upper,
                  "Requirement not fulfilled: lower < upper, lower = " ~
                  to!string(lower) ~ " and upper = " ~ to!string(upper));
    static if (optional) {
        static assert(upper + 1 == T.max,
                      "upper + 1 cannot equal T.max");
    }

    alias T type;    /** Nice type property. */

    /** Return true if this is a signed integer. */
    static bool isSigned() { return lower < 0; }
    /** Get Lower Inclusive Bound. */
    static auto min() @property @safe pure nothrow { return lower; }
    alias low = min;
    /** Get Upper Inclusive Bound. */
    static auto max() @property @safe pure nothrow { return optional ? upper - 1 : upper; }
    alias high = max;

    /** Constructor Magic. */
    alias _value this;

    inout auto ref value() @property @safe pure inout nothrow { return _value; }

    @property string toString(bool colorize = false) const @trusted
    {
        return (to!string(_value) ~
                " ∈ [" ~ to!string(min) ~
                ", " ~ to!string(max) ~
                "]" ~
                " ⟒ " ~
                T.stringof); // TODO: Use colorize flag
    }

    /** Check if this value is defined. */
    bool defined() @property @safe const pure nothrow { return optional ? _value != T.max : true; }

    static string check() @trusted pure
    {
        return q{
            asm { jo overflow; }
            if (value < min) goto overflow;
            if (value > max) goto overflow;
            goto ok;
          // underflow:
          //   immutable uMsg = "Underflow at " ~ file ~ ":" ~ to!string(line) ~ " (payload: " ~ to!string(value) ~ ")";
          //   if (exceptional) {
          //       throw new BoundUnderflowException(uMsg);
          //   } else {
          //       wln(uMsg);
          //   }
          overflow:
            immutable oMsg = "Overflow at " ~ file ~ ":" ~ to!string(line) ~
                " (payload: " ~ to!string(value) ~ ")";
            if (exceptional) {
                throw new BoundOverflowException(oMsg);
            } else {
                import std.stdio: wln = writeln;
                wln(oMsg);
            }
          ok: ;
        };
    }

    auto opUnary(string op, string file = __FILE__, int line = __LINE__)()
    {
        static      if (op == "+")
        {
            return this;
        }
        else static if (op == "-")
        {
            Bound!(T, -cast(int)T.max, -cast(int)T.min) tmp = void; // TODO: Needs fix
        }
        mixin("tmp._value = " ~ op ~ "_value " ~ ";");
        mixin(check());
        return tmp;
    }

    auto opBinary(string op, U,
                  string file = __FILE__,
                  int line = __LINE__)(U rhs)
    {
        alias TU = CommonType!(T, U.type);
        static if (is(U == Bound))
        {
            // do value range propagation
            static      if (op == "+")
            {
                enum min_ = min + U.min;
                enum max_ = max + U.max;
            }
            else static if (op == "-")
            {
                enum min_ = min - U.max; // min + min(-U.max)
                enum max_ = max - U.min; // max + max(-U.max)
            }
            else static if (op == "*")
            {
                import std.math: abs;
                static if (_value*rhs._value>= 0) // intuitive case
                {
                    enum min_ = abs(min)*abs(U.min);
                    enum max_ = abs(max)*abs(U.max);
                }
                else
                {
                    enum min_ = -abs(max)*abs(U.max);
                    enum max_ = -abs(min)*abs(U.min);
                }
            }
            /* else static if (op == "/") */
            /* { */
            /* } */
            else static if (op == "^^")  // TODO: Verify this case for integers and floats
            {
                import traits_ex: isEven;
                if (_value >= 0 ||
                    rhs._value >= 0 && rhs._value.isEven) // always positive if exponent is even
                {
                    enum min_ = min^^U.min;
                    enum max_ = max^^U.max;
                }
                else
                {
                    enum min_ = max^^U.max;
                    enum max_ = min^^U.min;
                }
            }
            else
            {
                static assert(false, "Unsupported binary operator " + op);
            }
            alias TU_ = CommonType!(typeof(min_), typeof(max_));

            mixin("const result = _value " ~ op ~ "rhs;");

            /* static assert(false, min_.stringof ~ "," ~ */
            /*               max_.stringof ~ "," ~ */
            /*               typeof(result).stringof ~ "," ~ */
            /*               TU_.stringof); */

            return bound!(min_, max_)(result);
            // return Bound!(TU_, TU_, min_, max_)(result);
        }
        else
        {
            CommonType!(T, U) tmp = void;
        }
        mixin("const tmp = _value " ~ op ~ "rhs;");
        mixin(check());
        return tmp;
    }

    auto opOpAssign(string op, U, string file = __FILE__, int line = __LINE__)(U rhs)
    {
        CommonType!(T, U) tmp = void;
        mixin("tmp = _value " ~ op ~ "rhs;");
        mixin(check());
        _value = cast(T)tmp;
        return _value;
    }

    auto opAssign(U)(U tmp, string file = __FILE__, int line = __LINE__)
    {
        mixin(check());
        _value = cast(T)tmp;
        return _value;
    }

    private T _value;                      ///< Payload.
}

/** Instantiator for \c Bound.
 * \see http://stackoverflow.com/questions/17502664/instantiator-function-for-bound-template-doesnt-compile
 */
template bound(alias min,
               alias max,
               bool optional = false,
               bool exceptional = true,
               bool packed = true) if (!is(CommonType!(typeof(min),
                                                       typeof(max)) == void))
{
    alias typeof(min) MinType;
    alias typeof(max) MaxType;

    alias C = CommonType!(MinType, MaxType);

    enum span = max - min;
    alias typeof(span) span_t;

    static if (isIntegral!(MinType) &&
               isIntegral!(MaxType))
    {
        static if (min >= 0) {
            static if (packed) {
                static      if (span <= 0xff)               { auto bound(ubyte value = 0)  { return Bound!(ubyte,  C, 0, span, optional, exceptional)(value); } }
                else static if (span <= 0xffff)             { auto bound(ushort value = 0) { return Bound!(ushort, C, 0, span, optional, exceptional)(value); } }
                else static if (span <= 0xffffffff)         { auto bound(uint value = 0)   { return Bound!(uint,   C, 0, span, optional, exceptional)(value); } }
                else static if (span <= 0xffffffffffffffff) { auto bound(ulong value = 0)  { return Bound!(ulong,  C, 0, span, optional, exceptional)(value); } }
                else {
                    auto bound(CommonType!(MinType, MaxType) value) { return Bound!(typeof(value), typeof(value), min, max, optional, exceptional)(value); } // TODO: Functionize this
                }
            } else {
                auto bound(CommonType!(MinType, MaxType) value) { return Bound!(typeof(value), min, max, optional, exceptional)(value); } // TODO: Functionize this
            }
        } else {         // negative
            static if (packed) {
                static      if (min >= -0x80               && max <= 0x7f)               { auto bound(byte value = 0)  { return Bound!(byte,  byte,  min, max, optional, exceptional)(value); } }
                else static if (min >= -0x8000             && max <= 0x7fff)             { auto bound(short value = 0) { return Bound!(short, short, min, max, optional, exceptional)(value); } }
                else static if (min >= -0x80000000         && max <= 0x7fffffff)         { auto bound(int value = 0)   { return Bound!(int,   int,   min, max, optional, exceptional)(value); } }
                else static if (min >= -0x8000000000000000 && max <= 0x7fffffffffffffff) { auto bound(long value = 0)  { return Bound!(long,  long,  min, max, optional, exceptional)(value); } }
                else {
                    auto bound(C value = C.init) { return Bound!(typeof(value), typeof(value), typeof(value), min, max, optional, exceptional)(value); } // TODO: Functionize this
                }
            } else {
                auto bound(C value = C.init) { return Bound!(typeof(value), typeof(value), typeof(value), min, max, optional, exceptional)(value); } // TODO: Functionize this
            }
        }
    } else static if (isFloatingPoint!C) {
        auto bound(C value = C.init) { return Bound!(typeof(value), typeof(value), min, max, optional, exceptional)(value); } // TODO: Functionize this
    } else {
        static assert(false, "Cannot handle type");
    }
}

unittest
{
    import std.stdio: wln = writeln;

    /* TODO: Activate this: */
    /* wln("diff: ", */
    /*     bound!(10, 20)(10) - */
    /*     bound!(0, 10)(10)); */
    /* wln("sum: ", */
    /*     bound!(0, 10)(3) + */
    /*     bound!(0, 10)(3)); */

    // infer unsigned types
    assert(bound!(0, 0x1)(0x1).type.stringof == "ubyte");
    assert(bound!(0, 0xff)(0xff).type.stringof == "ubyte");

    // assert(bound!(256, 257)(256).type.stringof == "ubyte");

    assert(bound!(0, 0x100)(0x100).type.stringof == "ushort"); // step over the line
    assert(bound!(0, 0xffff)(0xffff).type.stringof == "ushort");

    assert(bound!(0, 0x10000)(0x10000).type.stringof == "uint"); // step over the line
    assert(bound!(0, 0xffffffff)(0xffffffff).type.stringof == "uint");

    assert(bound!(0, 0x100000000)(0x100000000).type.stringof == "ulong"); // step over the line
    assert(bound!(0, 0x100000000)(0x100000000).type.stringof == "ulong");

    // default construction
    assert(bound!(0, 0x100000000).type.stringof == "ulong");

    // infer signed types
    assert(bound!(-1, 0)(0).type.stringof == "byte");
    assert(bound!(-0x80, 0x7f)(0).type.stringof == "byte");
    assert(bound!(-0x8000, 0x7fff)(0).type.stringof == "short");
    // import assert_ex: assertEqual;
    // assertEqual(bound!(-0x80000000, 0x7fffffff)(0).type.stringof, "int");
    // assert(bound!(-0x8000000000000000, 0x7fffffffffffffff)(0).type.stringof == "long");

    assert(bound!(0.0, 10.0)(1.0) ==
           Bound!(float, float, 0.0, 10.0)(1.0)
        );

    Bound!(int) afull; // int with full bound range
    Bound!(int, int, int.min, int.max) a;

    a = int.max;
    assert(a == int.max);
    assert(a.value == int.max);

    Bound!(int, int, int.min, int.max) b;
    b = int.min;
    assert(b == int.min);
    assert(b.value == int.min);

    import std.stdio: writefln;

    writefln("%s", a);          // %s means that a is cast using \c toString()

    a -= 5;
    assert(a == int.max - 5);
    writefln("%s", a);          // should work

    a += 5;
    writefln("%s", a);          // should workd

    import std.exception: assertThrown;
    assertThrown(a += 5);

    /* test print */
    auto x = bound!(0, 1)(1);
    x += 1;
    version(print) wln(bound!(0, 1)(1));
    version(print) wln(bound!(-1, 0)(0));
    version(print) wln(bound!(-129, 0)(0));

    // version(print) wln(bound!(0, 256)( - 1)); // Should give compiler error!

    version(print) wln(bound!(0, 2)(1));

    version(print) wln(bound!(0.0f, 2.0f)()); // nan float
    version(print) wln(bound!(0.0f, 2.0f)(1.0f)); // float
    version(print) wln(bound!(0.0f, 2.0f)(1.0)); // float

    version(print) wln(bound!(0.0, 2.0)());  // nan double
    version(print) wln(bound!(0.0, 2.0)(1.0));  // double
    version(print) wln(bound!(0.0, 2.0)(1.0f)); // double

    version(print) wln(bound!(0.0f, 2.0)(1.0)); // double
    version(print) wln(bound!(0.0, 2.0f)(1.0)); // double

    version(print) wln(bound!(0, 0x100 - 1)(0x100 - 1));
    version(print) wln(bound!(0, 0x100    )(0x100    ));
    version(print) wln(bound!(0, 0x10000 - 1)(0x10000 - 1));
    version(print) wln(bound!(0, 0x10000    )(0x10000    ));
    version(print) wln(bound!(0, 0x100000000 - 1)(0x100000000 - 1));
    version(print) wln(bound!(0, 0x100000000    )(0x100000000    ));
}

/** Return $(D x) with Automatic Packed Saturation. */
auto ref saturated(T, bool packed = true)(inout T x) // TODO: inout may be irrelevant here
{
    return bound!(T.min, T.max, false, packed)(x);
}

/** Return $(D x) with Automatic Packed Saturation. */
auto ref optional(T, bool packed = true)(inout T x) // TODO: inout may be irrelevant here
{
    return bound!(T.min, T.max, false, packed)(x);
}

unittest {
    const sb127 = saturated!byte(127);
    static assert(!__traits(compiles, { const sb128 = saturated!byte(128); }));
    static assert(!__traits(compiles, { saturated!byte bb = 127; }));
}

unittest {
    const sb127 = saturated!byte(127);
    auto sh128 = saturated!short(128);
    static assert(__traits(compiles, { sh128 = sb127; }));
    static assert(!__traits(compiles, { sh127 = sb128; }));
}

unittest {
    version(print) import std.stdio: wln = writeln;

    const ub = saturated!ubyte(11);
    version(print) wln(ub);
    assert(ub.sizeof == 1);

    const i = saturated!int(11);
    assert(i.sizeof == 4);

    const l = saturated!long(11);
    assert(l.sizeof == 8);

    immutable im = 255;
    const u = saturated!ubyte(im);
}
