#!/usr/bin/env rdmd

/** Extension to enumerations.
    TODO: Move to std.typecons (Type Constructor) in Phobos when ready.
 */
module enums;

import std.typetuple: allSatisfy;
import std.traits: EnumMembers, CommonType, OriginalType;
import std.stdio: writefln;

version = checkCollisions;

private enum isEnum(T) = is(T == enum);

/* TODO: CommonOriginalType(T...) = */

/** Unite (Chain, Join) Member Names of Enumerations $(D E).
    All enumerator names of $(D E) must be unique.
    See also: http://forum.dlang.org/thread/f9vc6p$1b7k$1@digitalmars.com
*/
template EnumChain(E...) if (allSatisfy!(isEnum, E))
{
    mixin({
            string r = "enum EnumChain { ";
            version(checkCollisions)
                string[string] names;   // lookup: enumName[memberName]
            foreach (T; E) {
                import std.range: join;
                version(checkCollisions) {
                    foreach (m; __traits(allMembers, T)) {
                        assert(m !in names,
                               "Enumerator " ~ T.stringof ~"."~m ~
                               " collides with " ~ names[m] ~"."~m);
                        names[m] = T.stringof;
                    }
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

/** Unite Members (both their Names and Values) of Enumerations $(D E).
    All enumerator names and values of $(D E) must be unique.
 */
template EnumUnion(E...) if (allSatisfy!(isEnum, E))
{
    mixin({
            string r = "enum EnumUnion { ";
            version(checkCollisions) {
                string[string] names;   // lookup: enumName[memberName]
                string[int] values;
            }
            foreach (ix, T; E) {
                import std.conv: to;
                version(checkCollisions) {
                    foreach (m; EnumMembers!T) { // foreach member
                        // name
                        enum n = to!string(m);
                        assert(n !in names,
                               "Enumerator name " ~ T.stringof ~"."~n ~
                               " collides with " ~ names[n] ~"."~n);
                        names[n] = T.stringof;

                        // value
                        enum v = to!int(m);    // value. TODO: Generalize to arbitrary enum type
                        assert(v !in values,
                               "Enumerator value of " ~ T.stringof ~"."~n ~" == "~ to!string(v) ~
                               " collides with member value of " ~ values[v]);
                        values[v] = T.stringof;

                        r ~= to!string(n) ~ "=" ~ to!string(v) ~ ",";
                    }
                }
            }
            return r ~ " }";
        }());
}

unittest
{
    enum E1 { a = 0, b = 3, c = 6 }
    enum E2 { p = 1, q = 4, r = 7 }
    enum E3 { x = 2, y = 5, z = 8 }
    alias E = EnumUnion!(E1, E2, E3);
    foreach (immutable e; [EnumMembers!E])
        writefln("E.%s: %d", e, e);

    enum D1 { a = 0, b = 3, c = 6 }
    enum D3 { x = 0, y = 3, z = 6 }
    static assert(!__traits(compiles, { alias ED = EnumUnion!(E1, D1); } ));
    static assert(!__traits(compiles, { alias ED = EnumUnion!(E1, D3); } ));
}
