#!/usr/bin/env rdmd-dev-module

/** See also: */
module maybe;

/** Optionally Defined Value of Type T.
    Todo: Handle Maybe!T = Maybe!U if isAssignable!(T, U)
 */
struct Maybe(T,
             bool packed = true,
             bool exceptional = false)
{
    @property string toString() @trusted const {
        import std.conv: to;
        return defined ? to!string(_value) : "undefined"; // TODO: Is "none" better?
    }

    import std.traits: isIntegral, isSigned, isUnsigned, isFloatingPoint;

    @safe pure nothrow {
        /** Check if $(D this) value is defined. */
        bool defined() @property @safe const pure nothrow {
            static if (!packed) {
                return _defined;
            } else static if (isIntegral!T && isSigned!T) {
                    return _value != T.min;
            } else static if (isIntegral!T && isUnsigned!T) {
                return _value != T.max;
            } else static if (isFloatingPoint!T) {
                return !(_value is T.nan);
            }
        }
        /** Check if $(D this) value is undefined. */
        bool undefined() @property @safe const pure nothrow { return defined; }

        static        if (!packed) {
            private T _value = T.min;
            private bool _defined = false;
        } else static if (isIntegral!T && isSigned!T) {
            private T _value = T.min;
            static T min() { return T.min + 1; }
            static T max() { return T.max; }
        } else static if (isIntegral!T && isUnsigned!T) {
            private T _value = T.max;
            static T min() { return T.min; }
            static T max() { return T.max - 1; }
        } else static if (isFloatingPoint!T) {
            private T _value = T.nan;
            /* } else static if (isComplex!T) { */
            /*     private T _value = T.nan; */
        } else {
            static assert(false, "T " ~ to!string(T.stringof) ~ " not supported");
        }
    }
    alias _value this;

}
alias Optional = Maybe;

auto ref maybe(T)(inout T x) @safe pure nothrow
{
    return Maybe!T(x);
}

unittest {
    import std.conv: to;
    import std.stdio: wln = writeln;

    Maybe!int x;
    assert(to!string(x) == "undefined");
    assert(!x.defined);
    x = 1;
    assert(x.defined);

    Maybe!ubyte ub; assert(!ub.defined);
    Maybe!byte sb;  assert(!sb.defined);

    Maybe!float f;  assert(f is float.nan); assert(!f.defined);
    Maybe!double d; assert(d is double.nan); assert(!d.defined);
    Maybe!real r;   assert(r is real.nan); assert(!r.defined);

    auto mi11 = maybe(11);
    auto mi2 = maybe!int(2);

    /* import std.complex; */
    /* Maybe!(Complex!float) f; */
}
