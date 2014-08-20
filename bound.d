#!/usr/bin/env rdmd-dev-module

/** Bounded Arithmetic Wrapper Type, similar to Ada Range Types but with
    auto-expension of value ranges which is more flexible and useful for
    detecting compile-time range index overflows.

    Copyright: Per Nordlöw 2014-.
    License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
    Authors: $(WEB Per Nordlöw)

    TODO: Make use of __traits(valueRange) at lionello:if-else-range when merged to DMD.
          - See: https://github.com/lionello/dmd/compare/if-else-range
          - See: http://forum.dlang.org/thread/lnrc8l$1254$1@digitalmars.com

    See also: http://stackoverflow.com/questions/18514806/ada-like-types-in-nimrod
    See also: https://bitbucket.org/davidstone/bounded_integer
    See also: http://forum.dlang.org/thread/xogeuqdwdjghkklzkfhl@forum.dlang.org#post-rksboytciisyezkapxkr:40forum.dlang.org
    See also: http://forum.dlang.org/thread/lxdtukwzlbmzebazusgb@forum.dlang.org#post-ymqdbvrwoupwjycpizdi:40forum.dlang.org

    TODO: Make this work wln(bound!(256, 257)(256));
    TODO: Implement overload for conditional operator p ? x1 : x2
    TODO: Implement variadic min, max, abs by looking at bounder_integer
    TODO: Propagate ranges in arithmetic (opUnary, opBinary, opOpAssign):
          - Integer: +,-,*,^^,/
          - FloatingPoint: +,-,*,/,^^,sqrt,

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
    mixin Proxy!_t;             // Limited acts as V (almost).
    invariant() {
    enforce(_t >= low && _t <= high);
    wln("fdsf");
    TODO: If these things take to long to evaluted at compile-time maybe we need
    to build it into the language for example using a new syntax either using
    - integer(range:low..high, step:1)
    - int(range:low..high, step:1)
    - num(range:low..high, step:1)
    TODO: Use
    V saveOp(string op, V)(V x, V y) pure @save @nogc if(isIntegral!V
    && (op=="+" || op=="-" || op=="<<" || op=="*"))
    {
    mixin("x "~op~"= y");
    static if(isSigned!V)
    {
    static if(op == "*")
    {
    asm naked { jnc opok; }
    }
    else
    {
    asm naked { jno opok; }
    }
    x = V.min;
    }
    else // unsigned
    {
    asm naked { jnc opok; }
    x = V.max;
    }
    opok:
    return x;
    }

    TODO: Reuse core.checkedint

 */
module bound;

import std.conv: to;
import std.traits: CommonType, isIntegral, isUnsigned, isSigned, isFloatingPoint, isNumeric;
import std.stdint: intmax_t;

version = print;

version(print) import std.stdio: wln = writeln;

/** Boundness Policy. */
enum Policy
{
    clamped,
    overflowed,
    throwed,
    modulo
}

// import std.exception;
// class BoundUnderflowException : Exception {
//     this(string msg) { super(msg); }
// }

/** Exception thrown when $(D Bound) values overflows or underflows. */
class BoundOverflowException : Exception
{
    this(string msg) { super(msg); }
}

/** Type that can fit the inclusive bound [low, high].
    If $(D packed) optimize storage for compactness otherwise for speed.
*/
template InclusiveBoundsType(alias low,
                             alias high,
                             bool packed = true) if (isNumeric!(typeof(low)) &&
                                                     isNumeric!(typeof(high)))
{
    static assert(low < high,
                  "Requires low < high, low = " ~
                  to!string(low) ~ " and high = " ~ to!string(high));

    alias LowType = typeof(low);
    alias HighType = typeof(high);

    enum span = high - low;
    alias SpanType = typeof(span);

    static if (isIntegral!(LowType) &&
               isIntegral!(HighType))
    {
        static if (low >= 0)    // positive
        {
            static if (packed)
            {
                static      if (span <= 0xff)               { alias InclusiveBoundsType = ubyte; }
                else static if (span <= 0xffff)             { alias InclusiveBoundsType = ushort; }
                else static if (span <= 0xffffffff)         { alias InclusiveBoundsType = uint; }
                else static if (span <= 0xffffffffffffffff) { alias InclusiveBoundsType = ulong; }
                else { alias InclusiveBoundsType = CommonType!(LowType, HighType); }
            }
            else
            {
                alias InclusiveBoundsType = CommonType!(LowType, HighType);
            }
        }
        else                    // negative
        {
            static if (packed)
            {
                static      if (low >= -0x80               && high <= 0x7f)               { alias InclusiveBoundsType = byte; }
                else static if (low >= -0x8000             && high <= 0x7fff)             { alias InclusiveBoundsType = short; }
                else static if (low >= -0x80000000         && high <= 0x7fffffff)         { alias InclusiveBoundsType = int; }
                else static if (low >= -0x8000000000000000 && high <= 0x7fffffffffffffff) { alias InclusiveBoundsType = long; }
                else { alias InclusiveBoundsType = CommonType!(LowType, HighType); }
            }
            else
            {
                alias InclusiveBoundsType = CommonType!(LowType, HighType);
            }
        }
    }
    else static if (isFloatingPoint!(LowType) &&
                    isFloatingPoint!(HighType))
    {
        alias InclusiveBoundsType = CommonType!(LowType, HighType);
    }
}

unittest
{
    static assert(!__traits(compiles, { alias IBT = InclusiveBoundsType!(0, 0); }));
    static assert(!__traits(compiles, { alias IBT = InclusiveBoundsType!(1, 0); }));

    // high < 0
    static assert(is(InclusiveBoundsType!(-1, 0) == byte));

    static assert(is(InclusiveBoundsType!(-0x80, 0x7f) == byte));
    static assert(is(InclusiveBoundsType!(-0x80, 0x80) == short));

    static assert(is(InclusiveBoundsType!(-0x8000, 0x7fff) == short));
    static assert(is(InclusiveBoundsType!(-0x8000, 0x8000) == int));

    // low == 0
    static assert(is(InclusiveBoundsType!(0, 0x1)  == ubyte));
    static assert(is(InclusiveBoundsType!(0, 0xff) == ubyte));

    static assert(is(InclusiveBoundsType!(0, 0x100)  == ushort));
    static assert(is(InclusiveBoundsType!(0, 0xffff) == ushort));

    static assert(is(InclusiveBoundsType!(0, 0x1_0000)    == uint));
    static assert(is(InclusiveBoundsType!(0, 0xffff_ffff) == uint));

    static assert(is(InclusiveBoundsType!(0, 0x1_0000_0000)        == ulong));
    static assert(is(InclusiveBoundsType!(0, 0xffff_ffff_ffff_ffff) == ulong));

    // low > 0
    static assert(is(InclusiveBoundsType!(0xff, 0xff + 0xff) == ubyte));
    static assert(is(InclusiveBoundsType!(0xff, 0xff + 0x100) == ushort));
    static assert(is(InclusiveBoundsType!(0x1_0000_0000, 0x1_0000_0000 + 0xff) == ubyte));

    // floating point
    static assert(is(InclusiveBoundsType!(0.0, 10.0) == double));
}

/** Value of Type $(D V) bound inside Inclusive Range [low, high].

    If $(D optional) is true this stores one extra undefined state (similar to Haskell's Maybe).

    If $(D exceptional) is true range errors will throw a
    $(D BoundOverflowException), otherwise truncation plus warnings will issued.
*/
struct Bound(V,
             B = intmax_t, // bounds type: TODO: Use intmax_t only when V isIntegral and real when V isFloatingPoint
             B low = V.min,
             B high = V.max,
             bool optional = false,
             bool exceptional = true)
{
    /* Requirements */
    static assert(low < high,
                  "Requirement not fulfilled: low < high, low = " ~
                  to!string(low) ~ " and high = " ~ to!string(high));
    static if (optional)
    {
        static assert(high + 1 == V.max,
                      "high + 1 cannot equal V.max");
    }

    alias type = V;    /** Nice type property. */

    /** Get Low Inclusive Bound. */
    static auto min() @property @safe pure nothrow { return low; }

    /** Get High Inclusive Bound. */
    static auto max() @property @safe pure nothrow { return optional ? high - 1 : high; }

    /** Constructor Magic. */
    alias _value this;

    /** Construct from Integral $(D V) $(D a). */
    static if (isIntegral!V)
    {
        this(V a)
        {
            static if (isUnsigned!V)
            {
                static assert(V.max >= high - low,
                              "Unsigned value type V = " ~ V.stringof ~ " doesn't fit in inclusive bounds [" ~ to!string(low) ~ "," ~ to!string(high) ~ "]");
            }
            else static if (isSigned!V)
            {
                static assert(V.min <= low && high <= V.max,
                              "Unsigned value type V = " ~ V.stringof ~ " doesn't fit in inclusive bounds [" ~ to!string(low) ~ "," ~ to!string(high) ~ "]");
            }
            else
            {
                static assert(false, "Handle value type V = " ~ V.stringof);
            }
            this._value = a;
        }
    }
    else static if (isFloatingPoint!V &&
                    isFloatingPoint!B &&
                    V.sizeof >= B.sizeof) // internal value must fit bounds
    {
        this (V a)
        {
            this._value = a;
        }
    }

    /** Construct from $(D Bound) value $(D a). */
    this(U,
         C,
         alias lowRHS,
         alias highRHS)(Bound!(U, C, lowRHS, highRHS) a) if (low <= lowRHS &&
                                                             highRHS >= high)
    {
        /* TODO: Use this instead of template constraint? */
        /* static assert(low <= lowRHS && */
        /*               highRHS >= high, */
        /*               "Bounds of rhs isn't a subset of lhs."); */
        this._value = a._value;
    }

    inout auto ref value() @property @safe pure inout nothrow { return _value; }

    @property string toString() const @trusted
    {
        return (to!string(_value) ~
                " ∈ [" ~ to!string(min) ~
                ", " ~ to!string(max) ~
                "]" ~
                " ⟒ " ~
                V.stringof);
    }

    /** Check if this value is defined. */
    bool defined() @property @safe const pure nothrow { return optional ? _value != V.max : true; }

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
            Bound!(V, -cast(int)V.max, -cast(int)V.min) tmp = void; // TODO: Needs fix
        }
        mixin("tmp._value = " ~ op ~ "_value " ~ ";");
        mixin(check());
        return tmp;
    }

    auto opBinary(string op, U,
                  string file = __FILE__,
                  int line = __LINE__)(U rhs)
    {
        alias TU = CommonType!(V, U.type);
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
                    rhs._value >= 0 &&
                    rhs._value.isEven) // always positive if exponent is even
                {
                    enum min_ = min^^U.min;
                    enum max_ = max^^U.max;
                }
                else
                {
                    /* TODO: What to do here? */
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
            CommonType!(V, U) tmp = void;
        }
        mixin("const tmp = _value " ~ op ~ "rhs;");
        mixin(check());
        return tmp;
    }

    auto opOpAssign(string op, U, string file = __FILE__, int line = __LINE__)(U rhs)
    {
        CommonType!(V, U) tmp = void;
        mixin("tmp = _value " ~ op ~ "rhs;");
        mixin(check());
        _value = cast(V)tmp;
        return _value;
    }

    auto opAssign(U)(U tmp, string file = __FILE__, int line = __LINE__)
    {
        mixin(check());
        _value = cast(V)tmp;
        return _value;
    }

    private V _value;                      ///< Payload.
}

/** Instantiator for \c Bound.
    Bounds $(D low) and $(D high) infer type of internal _value.
    If $(D packed) optimize storage for compactness otherwise for speed.
 * \see http://stackoverflow.com/questions/17502664/instantiator-function-for-bound-template-doesnt-compile
 */
template bound(alias low,
               alias high,
               bool optional = false,
               bool exceptional = true,
               bool packed = true) if (!is(CommonType!(typeof(low),
                                                       typeof(high)) == void))
{
    enum span = high - low;
    alias SpanType = typeof(span);
    alias LowType = typeof(low);
    alias HighType = typeof(high);

    static if (isIntegral!LowType &&
               isIntegral!HighType)
    {
        alias C = intmax_t;
    }
    else static if (isFloatingPoint!LowType &&
                    isFloatingPoint!HighType)
    {
        alias C = real; // TODO: This may give incorrect results because of
                        // round-off errors. One to fix is to adjust to max(value,low)  or min(value,high) if typeof(_value) != real
    }
    else
    {
        alias C = CommonType!(LowType, HighType); // TODO: Should this be allowed?
        static assert(false,
                      "Cannot mix Integral type " ~ LowType.stringof ~
                      " with FloatingPoint type" ~ HighType.stringof);
    }

    static if (isIntegral!(LowType) &&
               isIntegral!(HighType))
    {
        static if (low >= 0) {
            static if (packed) {
                static      if (span <= 0xff)               { auto bound(ubyte  value = 0) { return Bound!(ubyte,  C, low, high, optional, exceptional)(value); } }
                else static if (span <= 0xffff)             { auto bound(ushort value = 0) { return Bound!(ushort, C, low, high, optional, exceptional)(value); } }
                else static if (span <= 0xffffffff)         { auto bound(uint   value = 0) { return Bound!(uint,   C, low, high, optional, exceptional)(value); } }
                else static if (span <= 0xffffffffffffffff) { auto bound(ulong  value = 0) { return Bound!(ulong,  C, low, high, optional, exceptional)(value); } }
                else {
                    auto bound(CommonType!(LowType, HighType) value)
                    {
                        return Bound!(typeof(value), typeof(value), low, high, optional, exceptional)(value); // TODO: Functionize this
                    }
                }
            } else {
                auto bound(CommonType!(LowType, HighType) value) { return Bound!(typeof(value), low, high, optional, exceptional)(value); } // TODO: Functionize this
            }
        } else {         // negative
            static if (packed) {
                static      if (low >= -0x80               && high <= 0x7f)               { auto bound(byte  value = 0) { return Bound!(byte,  C, low, high, optional, exceptional)(value); } }
                else static if (low >= -0x8000             && high <= 0x7fff)             { auto bound(short value = 0) { return Bound!(short, C, low, high, optional, exceptional)(value); } }
                else static if (low >= -0x80000000         && high <= 0x7fffffff)         { auto bound(int   value = 0) { return Bound!(int,   C, low, high, optional, exceptional)(value); } }
                else static if (low >= -0x8000000000000000 && high <= 0x7fffffffffffffff) { auto bound(long  value = 0) { return Bound!(long,  C, low, high, optional, exceptional)(value); } }
                else {
                    auto bound(C value = C.init)
                    {
                        return Bound!(typeof(value), typeof(value), typeof(value), low, high, optional, exceptional)(value); // TODO: Functionize this
                    }
                }
            } else {
                auto bound(C value = C.init)
                {
                    return Bound!(typeof(value), typeof(value), typeof(value), low, high, optional, exceptional)(value); // TODO: Functionize this
                }
            }
        }
    }
    else static if (isFloatingPoint!C)
    {
        auto bound(C value = C.init)
        {
            return Bound!(typeof(value), typeof(value), low, high, optional, exceptional)(value); // TODO: Functionize this
        }
    }
    else
    {
        static assert(false, "Cannot handle type");
    }
}

unittest
{
    /* TODO: Activate this: */
    /* wln("diff: ", */
    /*     bound!(10, 20)(10) - */
    /*     bound!(0, 10)(10)); */
    /* wln("sum: ", */
    /*     bound!(0, 10)(3) + */
    /*     bound!(0, 10)(3)); */

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

/** Return $(D x) with Automatic Packed Saturation.
    If $(D packed) optimize storage for compactness otherwise for speed.
 */
auto ref saturated(V, bool packed = true)(inout V x) // TODO: inout may be irrelevant here
{
    return bound!(V.min, V.max, false, packed)(x);
}

/** Return $(D x) with Automatic Packed Saturation.
    If $(D packed) optimize storage for compactness otherwise for speed.
*/
auto ref optional(V, bool packed = true)(inout V x) // TODO: inout may be irrelevant here
{
    return bound!(V.min, V.max, false, packed)(x);
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
    const ub = saturated!ubyte(11);
    version(print) wln(ub);
    assert(ub.sizeof == 1);

    const i = saturated!int(11);
    assert(i.sizeof == 4);

    const l = saturated!long(11);
    assert(l.sizeof == 8);
}

/** Calculate Minimum.
    TODO: variadic.
*/
version(none)
{
    auto min(T1, intmax_t low1 = T1.min, intmax_t high1 = T1.min,
             T2, intmax_t low2 = T2.min, intmax_t high2 = T2.min)(Bound!(T1, intmax_t, low1, high1) a1,
                                                                  Bound!(T2, intmax_t, low2, high1) a2)
    {
        import std.algorithm: min;
        return min(a1 + a2).bound!(min(low1, low2),
                                   min(high1, high2));
    }

    unittest
    {
        auto a = 11.bound!(0, 17);
        auto b = 11.bound!(0, 22);
        auto abMax = min(a, b);
    }
}

/** Calculate Absolute Value of $(D a). */
auto abs(V,
         intmax_t low,
         intmax_t high)(Bound!(V, intmax_t, low, high) a)
{
    static if (low >= 0 && high >= 0) // all positive
    {
        enum lowA = low;
        enum highA = high;
    }
    else static if (low < 0 && high < 0) // all negative
    {
        enum lowA = -high;
        enum highA = -low;
    }
    else static if (low < 0 && high >= 0) // negative and positive
    {
        import std.algorithm: max;
        enum lowA = 0;
        enum highA = max(-low, high);
    }
    else
    {
        static assert("This shouldn't happen!");
    }
    import std.math: abs;
    return a.value.abs.bound!(lowA, highA);
}

unittest
{
    static assert(is(typeof(abs(0.bound!(-3, +3))) == Bound!(ubyte, long, 0L, 3L)));
    static assert(is(typeof(abs(0.bound!(-3, -1))) == Bound!(ubyte, long, 1L, 3L)));
    static assert(is(typeof(abs(0.bound!(-3, +0))) == Bound!(ubyte, long, 0L, 3L)));
    static assert(is(typeof(abs(0.bound!(+0, +3))) == Bound!(ubyte, long, 0L, 3L)));
    static assert(is(typeof(abs(0.bound!(+1, +3))) == Bound!(ubyte, long, 1L, 3L)));
}

unittest
{
    auto x01 = 0.bound!(0, 1);
    auto x02 = 0.bound!(0, 2);
    static assert( __traits(compiles, { x02 = x01; })); // ok within range
    /* static assert(!__traits(compiles, { x01 = x02; })); // should fail */
    typeof(x02) x02_ = x01; // ok within range
    typeof(x01) x01_ = x02; // should fail
}

/** TODO: Can D do better than C++ here?
    Does this automatically deduce to CommonType and if so do we need to declare it?
    Or does it suffice to constructors?
 */
/* auto doIt(ubyte x) */
/* { */
/*     if (x >= 0) */
/*     { */
/*         return x.bound!(0, 2); */
/*     } */
/*     else */
/*     { */
/*         return x.bound!(0, 1); */
/*     } */
/* } */

/* unittest */
/* { */
/*     auto x = 0.doIt; */
/* } */
