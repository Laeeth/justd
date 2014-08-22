#!/usr/bin/env rdmd-dev-module

/** Bounded Arithmetic Wrapper Type, similar to Ada Range Types but with
    auto-expension of value ranges which is more flexible and useful for
    detecting compile-time range index overflows.

    Copyright: Per Nordlöw 2014-.
    License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
    Authors: $(WEB Per Nordlöw)

    TODO: Make use of __traits(valueRange) at lionello:if-else-range when merged to DMD.
          This removes in some more cases needs for bounds checking.
          - See: https://github.com/lionello/dmd/compare/if-else-range
          - See: http://forum.dlang.org/thread/lnrc8l$1254$1@digitalmars.com

    See also: http://stackoverflow.com/questions/18514806/ada-like-types-in-nimrod
    See also: https://bitbucket.org/davidstone/bounded_integer
    See also: http://forum.dlang.org/thread/xogeuqdwdjghkklzkfhl@forum.dlang.org#post-rksboytciisyezkapxkr:40forum.dlang.org
    See also: http://forum.dlang.org/thread/lxdtukwzlbmzebazusgb@forum.dlang.org#post-ymqdbvrwoupwjycpizdi:40forum.dlang.org

    TODO: Implement overload for conditional operator p ? x1 : x2
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
import std.exception: assertThrown;

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

/** Get Type that can contain the inclusive bound [low, high].
    If $(D packed) optimize storage for compactness otherwise for speed.
    If $(D signed) use a signed integer.
*/
template BoundsType(alias low,
                    alias high,
                    bool packed = true,
                    bool signed = false) if (isNumeric!(typeof(low)) &&
                                             isNumeric!(typeof(high)))
{
    static assert(low != high,
                  "low == high: use an enum instead");
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
        static if (signed &&
                   low < 0)    // negative
        {
            static if (packed)
            {
                static      if (low >= -0x80               && high <= 0x7f)               { alias BoundsType = byte; }
                else static if (low >= -0x8000             && high <= 0x7fff)             { alias BoundsType = short; }
                else static if (low >= -0x80000000         && high <= 0x7fffffff)         { alias BoundsType = int; }
                else static if (low >= -0x8000000000000000 && high <= 0x7fffffffffffffff) { alias BoundsType = long; }
                else { alias BoundsType = CommonType!(LowType, HighType); }
            }
            else
            {
                alias BoundsType = CommonType!(LowType, HighType);
            }
        }
        else                    // positive
        {
            static if (packed)
            {
                static      if (span <= 0xff)               { alias BoundsType = ubyte; }
                else static if (span <= 0xffff)             { alias BoundsType = ushort; }
                else static if (span <= 0xffffffff)         { alias BoundsType = uint; }
                else static if (span <= 0xffffffffffffffff) { alias BoundsType = ulong; }
                else { alias BoundsType = CommonType!(LowType, HighType); }
            }
            else
            {
                alias BoundsType = CommonType!(LowType, HighType);
            }
        }
    }
    else static if (isFloatingPoint!(LowType) &&
                    isFloatingPoint!(HighType))
    {
        alias BoundsType = CommonType!(LowType, HighType);
    }
}

unittest
{
    static assert(!__traits(compiles, { alias IBT = BoundsType!(0, 0); }));  // disallow
    static assert(!__traits(compiles, { alias IBT = BoundsType!(1, 0); })); // disallow

    // low < 0
    static assert(is(BoundsType!(-1, 0, true, true) == byte));
    static assert(is(BoundsType!(-1, 0, true, false) == ubyte));
    static assert(is(BoundsType!(-0xff, 0, true, false) == ubyte));
    static assert(is(BoundsType!(-0xff, 1, true, false) == ushort));

    static assert(is(BoundsType!(byte.min, byte.max, true, true) == byte));
    static assert(is(BoundsType!(byte.min, byte.max + 1, true, true) == short));

    static assert(is(BoundsType!(short.min, short.max, true, true) == short));
    static assert(is(BoundsType!(short.min, short.max + 1, true, true) == int));

    // low == 0
    static assert(is(BoundsType!(0, 0x1) == ubyte));
    static assert(is(BoundsType!(ubyte.min, ubyte.max) == ubyte));

    static assert(is(BoundsType!(ubyte.min, ubyte.max + 1) == ushort));
    static assert(is(BoundsType!(ushort.min, ushort.max) == ushort));

    static assert(is(BoundsType!(ushort.min, ushort.max + 1) == uint));
    static assert(is(BoundsType!(uint.min, uint.max) == uint));

    static assert(is(BoundsType!(uint.min, uint.max + 1UL) == ulong));
    static assert(is(BoundsType!(ulong.min, ulong.max) == ulong));

    // low > 0
    static assert(is(BoundsType!(ubyte.max, ubyte.max + ubyte.max) == ubyte));
    static assert(is(BoundsType!(ubyte.max, ubyte.max + 0x100) == ushort));
    static assert(is(BoundsType!(uint.max + 1UL, uint.max + 1UL + ubyte.max) == ubyte));
    static assert(!is(BoundsType!(uint.max + 1UL, uint.max + 1UL + ubyte.max + 1) == ubyte));

    // floating point
    static assert(is(BoundsType!(0.0, 10.0) == double));
}

/** Value of Type $(D V) bound inside Inclusive Range [low, high].

    If $(D optional) is true this stores one extra undefined state (similar to Haskell's Maybe).

    If $(D exceptional) is true range errors will throw a
    $(D BoundOverflowException), otherwise truncation plus warnings will issued.
*/
struct Bound(V,
             alias low,
             alias high,
             bool optional = false,
             bool exceptional = true,
             bool packed = true,
             bool signed = false)
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

    /** Get Low Inclusive Bound. */
    static auto min() @property @safe pure nothrow { return low; }

    /** Get High Inclusive Bound. */
    static auto max() @property @safe pure nothrow { return optional ? high - 1 : high; }

    /** Construct from unbounded value $(D rhs). */
    this(U, string file = __FILE__, int line = __LINE__)(U rhs) if (isIntegral!V && isIntegral!U ||
                                                                    isFloatingPoint!V && isFloatingPoint!U)
    {
        checkAssign!(U, file, line)(rhs);
        this._value = cast(V)(rhs - low);
    }
    /** Assigne from unbounded value $(D rhs). */
    auto opAssign(U, string file = __FILE__, int line = __LINE__)(U rhs) if (isIntegral!V && isIntegral!U ||
                                                                             isFloatingPoint!V && isFloatingPoint!U)
    {
        checkAssign!(U, file, line)(rhs);
        _value = rhs - low;
        return this;
    }

    /** Construct from $(D Bound) value $(D rhs). */
    this(U,
         alias low_,
         alias high_)(Bound!(U, low_, high_,
                             optional, exceptional, packed, signed) rhs) if (low <= low_ && high_ <= high)
    {
        // verified at compile-time
        this._value = rhs._value + (high - high_);
    }
    /** Assign from $(D Bound) value $(D rhs). */
    auto opAssign(U,
                  alias low_,
                  alias high_)(Bound!(U, low_, high_,
                                      optional, exceptional, packed, signed) rhs) if (low <= low_ && high_ <= high &&
                                                                                      !is(CommonType!(T, U) == void))
    {
        // verified at compile-time
        this._value = rhs._value + (high - high_);
        return this;
    }

    auto opOpAssign(string op, U, string file = __FILE__, int line = __LINE__)(U rhs) if (!is(CommonType!(T, U) == void))
    {
        CommonType!(V, U) tmp = void;
        mixin("tmp = _value " ~ op ~ "rhs;");
        mixin(check());
        _value = cast(V)tmp;
        return this;
    }

    inout auto ref value() @property @safe pure inout nothrow { return _value + this.min; }

    @property string toString() const @trusted
    {
        return (to!string(this.value) ~
                " ∈ [" ~ to!string(min) ~
                ", " ~ to!string(max) ~
                "]" ~
                " ⟒ " ~
                V.stringof);
    }

    /** Check if this value is defined. */
    bool defined() @property @safe const pure nothrow { return optional ? this.value != V.max : true; }

    /** Check that last operation was a success. */
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

    /** Check that assignment from $(D rhs) is ok. */
    void checkAssign(U, string file = __FILE__, int line = __LINE__)(U rhs)
    {
        if (rhs < min) goto overflow;
        if (rhs > max) goto overflow;
        goto ok;
    overflow:
        immutable oMsg = "Overflow at " ~ file ~ ":" ~ to!string(line) ~
            " (payload: " ~ to!string(rhs) ~ ")";
        if (exceptional) {
            throw new BoundOverflowException(oMsg);
        } else {
            import std.stdio: wln = writeln;
            wln(oMsg);
        }
    ok: ;
    }

    auto opUnary(string op, string file = __FILE__, int line = __LINE__)()
    {
        static      if (op == "+")
        {
            return this;
        }
        else static if (op == "-")
        {
            Bound!(-cast(int)V.max,
                   -cast(int)V.min) tmp = void; // TODO: Needs fix
        }
        mixin("tmp._value = " ~ op ~ "_value " ~ ";");
        mixin(check());
        return this;
    }

    auto opBinary(string op, U,
                  string file = __FILE__,
                  int line = __LINE__)(U rhs) if (!is(CommonType!(T, U) == void))
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
            // return Bound!(TU_, min_, max_)(result);
        }
        else
        {
            CommonType!(V, U) tmp = void;
        }
        mixin("const tmp = _value " ~ op ~ "rhs;");
        mixin(check());
        return this;
    }

    private V _value;                      ///< Payload.
}

// enum matchingBounds(alias low, alias high) = (!is(CommonType!(typeof(low), typeof(high)) == void));

/** Instantiator for \c Bound.
    Bounds $(D low) and $(D high) infer type of internal _value.
    If $(D packed) optimize storage for compactness otherwise for speed.
 * \see http://stackoverflow.com/questions/17502664/instantiator-function-for-bound-template-doesnt-compile
 */
template bound(alias low,
               alias high,
               bool optional = false,
               bool exceptional = true,
               bool packed = true,
               bool signed = false) if (!is(CommonType!(typeof(low),
                                                        typeof(high)) == void))
{
    enum span = high - low;
    alias SpanType = typeof(span);
    alias LowType = typeof(low);
    alias HighType = typeof(high);

    alias V = BoundsType!(low, high, packed, signed); // ValueType
    alias C = CommonType!(typeof(low),
                          typeof(high));

    auto bound()
    {
        return Bound!(V, low, high, optional, exceptional, packed, signed)(V.init);
    }
    auto bound(V)(V value = V.init)
    {
        return Bound!(V, low, high, optional, exceptional, packed, signed)(value);
    }
}

unittest
{
    // verify construction overflows
    assertThrown(2.bound!(0, 1));
    assertThrown(255.bound!(0, 1));
    assertThrown(256.bound!(0, 1));

    // verify assignment overflows
    auto b1 = 1.bound!(0, 1);
    assertThrown(b1 = 2);
    assertThrown(b1 = -1);
    assertThrown(b1 = 256);
    assertThrown(b1 = -255);

    Bound!(int, int.min, int.max) a;

    a = int.max;
    assert(a.value == int.max);

    Bound!(int, int.min, int.max) b;
    b = int.min;
    assert(b.value == int.min);

    import std.stdio: writefln;

    writefln("%s", a);          // %s means that a is cast using \c toString()

    a -= 5;
    assert(a.value == int.max - 5);
    writefln("%s", a);          // should work

    a += 5;
    writefln("%s", a);          // should workd

    assertThrown(a += 5);

    /* test print */
    auto x = bound!(0, 1)(1);
    x += 1;
    version(print) wln(bound!(0, 1)(1));
    version(print) wln(bound!(-1, 0)(0));
    version(print) wln(bound!(-129, 0)(0));

    // version(print) wln(bound!(0, 256)( - 1)); // Should give compiler error!

    version(print) wln(bound!(0, 2)());

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
auto ref saturated(V,
                   bool optional = false,
                   bool packed = true)(V x) // TODO: inout may be irrelevant here
{
    return bound!(V.min, V.max, optional, false, packed)(x);
}

/** Return $(D x) with Automatic Packed Saturation.
    If $(D packed) optimize storage for compactness otherwise for speed.
*/
auto ref optional(V, bool packed = true)(V x) // TODO: inout may be irrelevant here
{
    return bound!(V.min, V.max, true, false, packed)(x);
}

unittest {
    const sb127 = saturated!byte(127);
    static assert(!__traits(compiles, { const sb128 = saturated!byte(128); }));
    static assert(!__traits(compiles, { saturated!byte bb = 127; }));
}

unittest {
    const sb127 = saturated!byte(127);
    auto sh128 = saturated!short(128);
    sh128 = sb127;
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
auto min(V1, alias low1, alias high1,
         V2, alias low2, alias high2,
         bool optional = false,
         bool exceptional = true,
         bool packed = true,
         bool signed = false)(Bound!(V1, low1, high1,
                                     optional, exceptional, packed, signed) a1,
                              Bound!(V2, low2, high2,
                                     optional, exceptional, packed, signed) a2)
{
    import std.algorithm: min;
    enum lowMin = min(low1, low2);
    enum highMin = min(high1, high2);
    return (cast(BoundsType!(lowMin, highMin))min(a1.value, a2.value)).bound!(lowMin, highMin);
}

/** Calculate Maximum.
    TODO: variadic.
*/
auto max(V1, alias low1, alias high1,
         V2, alias low2, alias high2,
         bool optional = false,
         bool exceptional = true,
         bool packed = true,
         bool signed = false)(Bound!(V1, low1, high1,
                                     optional, exceptional, packed, signed) a1,
                              Bound!(V2, low2, high2,
                                     optional, exceptional, packed, signed) a2)
{
    import std.algorithm: max;
    enum lowMax = max(low1, low2);
    enum highMax = max(high1, high2);
    return (cast(BoundsType!(lowMax, highMax))max(a1.value, a2.value)).bound!(lowMax, highMax);
}

unittest
{
    auto a = 11.bound!(0, 17);
    auto b = 11.bound!(5, 22);
    auto abMin = min(a, b);
    static assert(is(typeof(abMin) == Bound!(ubyte, 0, 17)));
    auto abMax = max(a, b);
    static assert(is(typeof(abMax) == Bound!(ubyte, 5, 22)));
}

/** Calculate Absolute Value of $(D a). */
auto abs(V,
         alias low,
         alias high,
         bool optional = false,
         bool exceptional = true,
         bool packed = true,
         bool signed = false)(Bound!(V, low, high,
                                     optional, exceptional, packed, signed) a)
{
    static if (low >= 0 && high >= 0) // all positive
    {
        enum low_ = low;
        enum high_ = high;
    }
    else static if (low < 0 && high < 0) // all negative
    {
        enum low_ = -high;
        enum high_ = -low;
    }
    else static if (low < 0 && high >= 0) // negative and positive
    {
        import std.algorithm: max;
        enum low_ = 0;
        enum high_ = max(-low, high);
    }
    else
    {
        static assert("This shouldn't happen!");
    }
    import std.math: abs;
    return Bound!(BoundsType!(low_, high_),
                  low_, high_,
                  optional, exceptional, packed, signed)(a.value.abs - low_);
}

unittest
{
    static assert(is(typeof(abs(0.bound!(-3, +3))) == Bound!(ubyte, 0, 3)));
    static assert(is(typeof(abs(0.bound!(-3, -1))) == Bound!(ubyte, 1, 3)));
    static assert(is(typeof(abs(0.bound!(-3, +0))) == Bound!(ubyte, 0, 3)));
    static assert(is(typeof(abs(0.bound!(+0, +3))) == Bound!(ubyte, 0, 3)));
    static assert(is(typeof(abs(0.bound!(+1, +3))) == Bound!(ubyte, 1, 3)));
    static assert(is(typeof(abs(0.bound!(-255, 255))) == Bound!(ubyte, 0, 255)));
    static assert(is(typeof(abs(0.bound!(-256, 255))) == Bound!(ushort, 0, 256)));
    static assert(is(typeof(abs(0.bound!(-255, 256))) == Bound!(ushort, 0, 256)));
    static assert(is(typeof(abs(10000.bound!(10000, 10000+255))) == Bound!(ubyte, 10000, 10000+255)));
}

unittest
{
    auto x01 = 0.bound!(0, 1);
    auto x02 = 0.bound!(0, 2);
    static assert( __traits(compiles, { x02 = x01; })); // ok within range
    static assert(!__traits(compiles, { x01 = x02; })); // should fail
}

/** TODO: Can D do better than C++ here?
    Does this automatically deduce to CommonType and if so do we need to declare it?
    Or does it suffice to constructors?
 */
version(none)
{
    auto doIt(ubyte x)
    {
        if (x >= 0)
        {
            return x.bound!(0, 2);
        }
        else
        {
            return x.bound!(0, 1);
        }
    }

    unittest
    {
        auto x = 0.doIt;
    }
}
