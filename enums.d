#!/usr/bin/env rdmd

/** Extension to enumerations.

    Copyright: Per Nordlöw 2014-.
    License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
    Authors: $(WEB Per Nordlöw)

    TODO: Wrap EnumChain and UnionEnum in structs with
    - alias this _EnumChain and _EnumUnion and
    - that allow assignment from their parts and
    - members that convert to their parts.

    TODO: Alternatively: Implement implicit conversions between EnumChain,
    UnionEnum and their sources similar to Ada's subtype:
    - Assignment to UnionEnum, EnumChain from its parts is always nothrow.
    - Assignment from UnionEnum, EnumChain to its parts may throw.
    when opImplicitCast is ready for use.

    TODO: Move to std.typecons (Type Constructor) in Phobos when ready.
 */
module enums;

import std.typetuple: allSatisfy, staticMap;
import std.traits: EnumMembers, CommonType, OriginalType;
import std.stdio: writeln, writefln;
import std.conv: to;

/* Helpers */
private enum isEnum(T) = is(T == enum);
private alias CommonOriginalType(T...) = CommonType!(staticMap!(OriginalType, T));

/** Chain (Append, Concatenate) Member Names of Enumerations $(D E).
    All enumerator names of $(D E) must be unique.
    See also: http://forum.dlang.org/thread/f9vc6p$1b7k$1@digitalmars.com
*/
template EnumChain(E...) if (E.length >= 2 &&
                             allSatisfy!(isEnum, E) &&
                             is(CommonOriginalType!(E)))
{
    mixin({
            string r = "enum EnumChain { ";
            string[string] names;   // lookup: enumName[memberName]
            foreach (T; E) {
                import std.range: join;
                foreach (m; __traits(allMembers, T)) {
                    assert(m !in names,
                           "Enumerator " ~ T.stringof ~"."~m ~
                           " collides with " ~ names[m] ~"."~m);
                    names[m] = T.stringof;
                }
                r ~= [__traits(allMembers, T)].join(",") ~ ",";
            }
            return r ~ " }";
        }());
}

unittest
{
    enum E0 { a, b, c }
    enum E1 { e, f, g }
    enum E2 { h, i, j }
    alias E12 = EnumChain!(E0, E1);
    alias E123 = EnumChain!(E0, E1, E2);
    foreach (immutable e; [EnumMembers!E123])
        writefln("E123.%s: %d", e, e);
}

/** Unite (Join) Members (both their Names and Values) of Enumerations $(D E).
    All enumerator names and values of $(D E) must be unique.
 */
template UnionEnum(E...) if (E.length >= 2 &&
                             allSatisfy!(isEnum, E) &&
                             is(CommonOriginalType!(E)))
{
    mixin({
            string r = "enum UnionEnum { ";
            alias O = CommonOriginalType!E;
            string[string] names;   // lookup: enumName[memberName]
            string[O] values;
            foreach (ix, T; E) {
                foreach (m; EnumMembers!T) { // foreach member
                    // name
                    enum n = to!string(m);
                    assert(n !in names,
                           "Template argument E[" ~ to!string(ix)~
                           "]'s enumerator name " ~ T.stringof ~"."~n ~
                           " collides with " ~ names[n] ~"."~n);
                    names[n] = T.stringof;

                    // value
                    enum v = to!O(m);
                    assert(v !in values,
                           "Template argument E[" ~ to!string(ix)~
                           "]'s enumerator value " ~ T.stringof ~"."~n ~" == "~ to!string(v) ~
                           " collides with member value of " ~ values[v]);
                    values[v] = T.stringof;

                    r ~= to!string(n) ~ "=" ~ to!string(v) ~ ",";
                }
            }
            return r ~ " }";
        }());
}

/** Instance Wrapper for UnionEnum.
    Provides safe assignment from its sub enums and check run-time casts.
*/
struct EnumUnion(E...)
{
    alias OriginalType = CommonOriginalType!(E);
    alias U = UnionEnum!(E);    // Wrapped Type.
    alias _value this;
    /* TODO: Alternative to this set of static if? */
    static if (E.length >= 1) {
        void opAssign(E[0] e) { _value = cast(U)e; }
        E[0] opCast(T : E[0])() const @safe pure nothrow {
            bool match = false;
            foreach (m; EnumMembers!U) {
                if (m == _value) {
                    match = true;
                }
            }
            assert(match, "Cast failed");
            return cast(E[0])_value;
        }
    }
    static if (E.length >= 2) void opAssign(E[1] e) { _value = cast(U)e; }
    static if (E.length >= 3) void opAssign(E[2] e) { _value = cast(U)e; }
    static if (E.length >= 4) void opAssign(E[3] e) { _value = cast(U)e; }
    static if (E.length >= 5) void opAssign(E[4] e) { _value = cast(U)e; }
    static if (E.length >= 6) void opAssign(E[5] e) { _value = cast(U)e; }
    static if (E.length >= 7) void opAssign(E[6] e) { _value = cast(U)e; }
    static if (E.length >= 8) void opAssign(E[7] e) { _value = cast(U)e; }
    static if (E.length >= 9) void opAssign(E[8] e) { _value = cast(U)e; }
    private U _value;           // Instance.
}

unittest
{
    enum E0:ubyte  { a = 0, b = 3, c = 6 }
    enum E1:ushort { p = 1, q = 4, r = 7 }
    enum E2:uint   { x = 2, y = 5, z = 8 }

    EnumUnion!(E0, E1, E2) eu;
    alias EU = typeof(eu);
    static assert(is(EU.OriginalType == uint));

    foreach (immutable e; [EnumMembers!(typeof(eu._value))])
        writefln("E123.%s: %d", e, e);

    E0 e0 = E0.max;
    eu = e0;                    // checked at compile-time
    assert(eu == E0.max);
    writeln(eu);

    e0 = cast(E0)eu;            // checked at run-time

    enum Ex:uint { x = 2, y = 5, z = 8 }
    static assert(!__traits(compiles, { Ex ex = Ex.max; eu = ex; } ));

    /* check for compilation failures */
    enum D1 { a = 0, b = 3, c = 6 }
    static assert(!__traits(compiles, { alias ED = UnionEnum!(E0, D1); } ), "Should give name and value collision");
    enum D2 { a = 1, b = 4, c = 7 }
    static assert(!__traits(compiles, { alias ED = UnionEnum!(E0, D2); } ), "Should give name collision");
    enum D3 { x = 0, y = 3, z = 6 }
    static assert(!__traits(compiles, { alias ED = UnionEnum!(E0, D3); } ),  "Should give value collision");
}
