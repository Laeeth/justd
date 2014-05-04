#!/usr/bin/env rdmd

/** Extension to enumerations.
    TODO: Move to std.typecons (Type Constructor) in Phobos when ready.
    TODO: Implement implicit conversions between EnumChain, EnumUnion and their
    sources similar to Ada's subtype:
    - Assignment to EnumUnion, EnumChain from its parts is always nothrow.
    - Assignment from EnumUnion, EnumChain to its parts may throw.
    when opImplicitCast is ready for use.
 */
module enums;

import std.typetuple: allSatisfy, staticMap;
import std.traits: EnumMembers, CommonType, OriginalType;
import std.stdio: writeln, writefln;
import std.conv: to;

version = checkCollisions;

/* Helpers */
private enum isEnum(T) = is(T == enum);
private alias CommonOriginalType(T...) = CommonType!(staticMap!(OriginalType, T));

/** Chain (Append, Concatenate) Member Names of Enumerations $(D E).
    All enumerator names of $(D E) must be unique.
    See also: http://forum.dlang.org/thread/f9vc6p$1b7k$1@digitalmars.com
*/
template EnumChain(E...) if (allSatisfy!(isEnum, E) &&
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
    enum E1 { a, b, c }
    enum E2 { e, f, g }
    enum E3 { h, i, j }
    alias E1_ = EnumChain!(E1);
    alias E12 = EnumChain!(E1, E2);
    alias E123 = EnumChain!(E1, E2, E3);
    foreach (immutable e; [EnumMembers!E123])
        writefln("E123.%s: %d", e, e);
}

/** Unite (Join) Members (both their Names and Values) of Enumerations $(D E).
    All enumerator names and values of $(D E) must be unique.
 */
template EnumUnion(E...) if (allSatisfy!(isEnum, E) &&
                             is(CommonOriginalType!(E)))
{
    mixin({
            string r = "enum EnumUnion { ";
            alias O = CommonOriginalType!E;
            string[string] names;   // lookup: enumName[memberName]
            string[O] values;
            foreach (ix, T; E) {
                foreach (m; EnumMembers!T) { // foreach member
                    // name
                    enum n = to!string(m);
                    assert(n !in names,
                           "Enumerator name " ~ T.stringof ~"."~n ~
                           " collides with " ~ names[n] ~"."~n);
                    names[n] = T.stringof;

                    // value
                    enum v = to!O(m);
                    assert(v !in values,
                           "Enumerator value of " ~ T.stringof ~"."~n ~" == "~ to!string(v) ~
                           " collides with member value of " ~ values[v]);
                    values[v] = T.stringof;

                    r ~= to!string(n) ~ "=" ~ to!string(v) ~ ",";
                }
            }
            return r ~ " }";
        }());
}

unittest
{
    enum E1:ubyte { a = 0, b = 3, c = 6 }
    enum E2:ushort { p = 1, q = 4, r = 7 }
    enum E3:uint { x = 2, y = 5, z = 8 }
    alias E = EnumUnion!(E1, E2, E3);
    /* writeln((OriginalType!E).stringof); */
    foreach (immutable e; [EnumMembers!E])
        writefln("E.%s: %s", e, to!(OriginalType!E)(e));

    enum D1 { a = 0, b = 3, c = 6 }
    enum D3 { x = 0, y = 3, z = 6 }
    static assert(!__traits(compiles, { alias ED = EnumUnion!(E1, D1); } ));
    static assert(!__traits(compiles, { alias ED = EnumUnion!(E1, D3); } ));
}
