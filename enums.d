#!/usr/bin/env rdmd

/** Extension to enumerations.
    TODO: Move to std.typecons (Type Constructor) in Phobos when ready.
 */
module enums;

import traits_ex: isEnum;
import std.typetuple: allSatisfy;
import std.traits: EnumMembers;
import std.stdio: writefln;

version = checkCollisions;

/** Unite (Chain, Join) Member Names of Enumerations $(D E).
    See also: http://forum.dlang.org/thread/f9vc6p$1b7k$1@digitalmars.com
*/
template MemberNamesUnion(E...) if (allSatisfy!(isEnum, E))
{
    mixin({
            version(checkCollisions)
                string[string] names;   // lookup: enumName[memberName]
            string r = "enum MemberNamesUnion { ";
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
    alias E1_ = MemberNamesUnion!(E1);
    alias E12 = MemberNamesUnion!(E1, E2);
    alias E123 = MemberNamesUnion!(E1, E2, E3);
    foreach (immutable e; [EnumMembers!E123])
        writefln("E123.%s: %d", e, e);
}

/** Unite (Chain, Join) Members (both their Names and Values) of Enumerations $(D E).
*/
template MembersUnion(E...) if (allSatisfy!(isEnum, E))
{
    mixin({
            string r = "enum MembersUnion { ";
            version(checkCollisions) {
                string[string] names;   // lookup: enumName[memberName]
                string[int] values;
            }
            foreach (ix, T; E) {
                import std.conv: to;
                /* TODO: Merge loops over EnumMembers */
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
    alias E = MembersUnion!(E1, E2, E3);
    foreach (immutable e; [EnumMembers!E])
        writefln("E.%s: %d", e, e);
}
