#!/usr/bin/env rdmd-dev-module

// TODO: Support Compact Storage of zero-unbalanced integer ranges. For example 100,101,102,103 fits in two bits
// TODO: Add static asserts using template-arguments?
// TODO: Do we need a specific underflow?
// TODO: Add this module to std.numeric
// TODO: Merge with limited
   // See also: http://stackoverflow.com/questions/18514806/ada-like-types-in-nimrod

// TODO: Is this a good idea to use?:
/* import std.typecons; */
/* mixin Proxy!_t;             // Limited acts as T (almost). */
/* invariant() { */
/*     enforce(_t >= lower && _t <= upper); */
/*     wln("fdsf"); */
/* } */

/**
 * Bounded Arithmetic Wrapper Type.
 *
 * Similar Type Ada Range Types.
 */
module bound;

import std.conv: to;
import std.traits: CommonType, isIntegral, isUnsigned;

// import std.exception;
// class BoundUnderflowException : Exception {
//     this(string msg) { super(msg); }
// }

/** Exception thrown when $(D Bound) values overflows or underflows. */
class BoundOverflowException : Exception {
    this(string msg) { super(msg); }
}

/** Value of Type $(D T) bound inside Inclusive Range [lower, upper]. */
struct Bound(T,
             T lower = T.min,
             T upper = T.max,
             bool optional = false,
             bool exceptional = true)
{
    static if (optional) { static assert(upper + 1 == T.max, "upper + 1 canot equal T.max"); }

    alias T type;

    static T min() @property @safe pure nothrow { return lower; }
    static T max() @property @safe pure nothrow { return optional ? upper - 1 : upper; }

    /** Constructor Magic. */
    alias _value this;

    inout auto ref value() @property @safe pure inout nothrow { return _value; }
    @property string toString() const @trusted {
        return (to!string(_value) ~
                " ∈ [" ~ to!string(min) ~
                ", " ~ to!string(max) ~
                "]" ~
                " : " ~ T.stringof);
    }

    /** Check if this value is defined. */
    bool defined() @property @safe const pure nothrow { return optional ? _value != T.max : true; }

    static string check() @trusted pure {
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
            immutable oMsg = "Overflow at " ~ file ~ ":" ~ to!string(line) ~ " (payload: " ~ to!string(value) ~ ")";
            if (exceptional) {
                throw new BoundOverflowException(oMsg);
            } else {
                import std.stdio: wln = writeln;
                wln(oMsg);
            }
          ok: ;
        };
    }

    auto opUnary(string op, string file = __FILE__, int line = __LINE__)() {
        T tmp = void;
        mixin("tmp " ~ op ~ ";");
        mixin(check());
        return tmp;
    }

    auto opBinary(string op, U, string file = __FILE__, int line = __LINE__)(U rhs) {
        CommonType!(T, U) tmp = void;
        mixin("tmp = _value " ~ op ~ "rhs;");
        mixin(check());
        return tmp;
    }

    auto opOpAssign(string op, U, string file = __FILE__, int line = __LINE__)(U rhs) {
        CommonType!(T, U) tmp = void;
        mixin("tmp = _value " ~ op ~ "rhs;");
        mixin(check());
        _value = cast(T)tmp;
        return _value;
    }

    auto opAssign(U)(U tmp, string file = __FILE__, int line = __LINE__) {
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
                                                       typeof(max)) == void)) {
    alias typeof(min) min_t;
    alias typeof(max) max_t;
    alias C = CommonType!(min_t, max_t);
    static if (isIntegral!(min_t) &&
               isIntegral!(max_t)) {
        static if (min >= 0) {
            static if (packed) {
                static      if (max <= 0xff)               { auto bound(ubyte value = 0)  { return Bound!(ubyte,  min, max, optional, exceptional)(value); } }
                else static if (max <= 0xffff)             { auto bound(ushort value = 0) { return Bound!(ushort, min, max, optional, exceptional)(value); } }
                else static if (max <= 0xffffffff)         { auto bound(uint value = 0)   { return Bound!(uint,   min, max, optional, exceptional)(value); } }
                else static if (max <= 0xffffffffffffffff) { auto bound(ulong value = 0)  { return Bound!(ulong,  min, max, optional, exceptional)(value); } }
                else {
                    auto bound(CommonType!(min_t, max_t) value) { return Bound!(typeof(value), min, max, optional, exceptional)(value); } // TODO: Functionize this
                }
            } else {
                auto bound(CommonType!(min_t, max_t) value) { return Bound!(typeof(value), min, max, optional, exceptional)(value); } // TODO: Functionize this
            }
        } else {         // negative
            static if (packed) {
                static      if (min >= -0x80               && max <= 0x7f)               { auto bound(byte value = 0)  { return Bound!(byte,  min, max, optional, exceptional)(value); } }
                else static if (min >= -0x8000             && max <= 0x7fff)             { auto bound(short value = 0) { return Bound!(short, min, max, optional, exceptional)(value); } }
                else static if (min >= -0x80000000         && max <= 0x7fffffff)         { auto bound(int value = 0)   { return Bound!(int,   min, max, optional, exceptional)(value); } }
                else static if (min >= -0x8000000000000000 && max <= 0x7fffffffffffffff) { auto bound(long value = 0)  { return Bound!(long,  min, max, optional, exceptional)(value); } }
                else {
                    auto bound(C value = C.init) { return Bound!(typeof(value), min, max, optional, exceptional)(value); } // TODO: Functionize this
                }
            } else {
                auto bound(C value = C.init) { return Bound!(typeof(value), min, max, optional, exceptional)(value); } // TODO: Functionize this
            }
        }
    } else {
        auto bound(C value = C.init) { return Bound!(typeof(value), min, max, optional, exceptional)(value); } // TODO: Functionize this
    }
}

unittest {
    // infer unsigned types
    assert(bound!(0, 0x1)(0x1).type.stringof == "ubyte");
    assert(bound!(0, 0xff)(0xff).type.stringof == "ubyte");

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
           Bound!(float, 0.0, 10.0)(1.0)
        );

    Bound!(int) afull; // int with full bound range
    Bound!(int, int.min, int.max) a;

    a = int.max;
    assert(a == int.max);
    assert(a.value == int.max);

    Bound!(int, int.min, int.max) b;
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
    import std.stdio: wln = writeln;
    auto x = bound!(0, 1)(1);
    x += 1;
    wln(bound!(0, 1)(1));
    wln(bound!(-1, 0)(0));
    wln(bound!(-129, 0)(0));

    // wln(bound!(0, 256)( - 1)); // Should give compiler error!

    wln(bound!(0, 2)(1));

    wln(bound!(0.0f, 2.0f)()); // nan float
    wln(bound!(0.0f, 2.0f)(1.0f)); // float
    wln(bound!(0.0f, 2.0f)(1.0)); // float

    wln(bound!(0.0, 2.0)());  // nan double
    wln(bound!(0.0, 2.0)(1.0));  // double
    wln(bound!(0.0, 2.0)(1.0f)); // double

    wln(bound!(0.0f, 2.0)(1.0)); // double
    wln(bound!(0.0, 2.0f)(1.0)); // double

    wln(bound!(0, 0x100 - 1)(0x100 - 1));
    wln(bound!(0, 0x100    )(0x100    ));
    wln(bound!(0, 0x10000 - 1)(0x10000 - 1));
    wln(bound!(0, 0x10000    )(0x10000    ));
    wln(bound!(0, 0x100000000 - 1)(0x100000000 - 1));
    wln(bound!(0, 0x100000000    )(0x100000000    ));
}

/** Return $(D x) with Automatic Packed Saturation. */
auto ref saturated(T, bool packed = true)(inout T x) // TODO: inout may be inrelevant here
{
    return bound!(T.min, T.max, false, packed)(x);
}

/** Return $(D x) with Automatic Packed Saturation. */
auto ref optional(T, bool packed = true)(inout T x) // TODO: inout may be inrelevant here
{
    return bound!(T.min, T.max, false, packed)(x);
}

unittest {
    import std.stdio: wln = writeln;

    const ub = saturated!ubyte(11);
    wln(ub);
    assert(ub.sizeof == 1);

    const i = saturated!int(11);
    assert(i.sizeof == 4);

    const l = saturated!long(11);
    assert(l.sizeof == 8);

    immutable im = 255;
    const u = saturated!ubyte(im);
}
