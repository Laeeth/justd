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
                string[string] previousMembers;   // used to detect member collisions
            string r = "enum MemberNamesUnion { ";
            foreach (T; E) {
                import std.range: join;
                version(checkCollisions) {
                    foreach (member; __traits(allMembers, T)) {
                        assert(member !in previousMembers,
                               "Enumerator " ~ T.stringof ~"."~member ~
                               " collides with " ~ previousMembers[member] ~"."~member);
                        previousMembers[member] = T.stringof;
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
            version(checkCollisions)
                string[string] previousMembers;   // used to detect member collisions
            foreach (ix, T; E) {
                import std.conv: to;
                version(checkCollisions) {
                    foreach (member; __traits(allMembers, T)) {
                        assert(member !in previousMembers,
                               "Enumerator " ~ T.stringof ~"."~member ~
                               " collides with " ~ previousMembers[member] ~"."~member);
                        previousMembers[member] = T.stringof;
                    }
                    static if (ix >= 1) {
                        alias Ep = E[ix - 1]; // previous enumeration
                        static assert(Ep.max < T.min,
                                      "Members values of enums " ~ Ep.stringof ~
                                      " and " ~ T.stringof ~
                                      " overlap, " ~
                                      Ep.stringof ~ "." ~ to!string(Ep.max) ~ "==" ~ to!string(cast(int)(Ep.max)) ~ " >= " ~
                                      T.stringof  ~ "." ~ to!string(T.min)  ~ "==" ~ to!string(cast(int)(T.min)));
                    }
                }
                import std.range: map, join;
                r ~= [EnumMembers!T].map!(a =>
                                          (to!string(a) ~ "=" ~
                                           to!string(to!int(a)))).join(",") ~ ","; // TODO: add checking for collisions
            }
            return r ~ " }";
        }());
}

unittest
{
    enum E1 { a = 0, b, c }
    enum E2 { p = 10, q, r } // continue after E1
    enum E3 { x = 20, y, z } // continue after E2
    alias E = MembersUnion!(E1, E2, E3);
    foreach (immutable e; [EnumMembers!E])
        writefln("E.%s: %d", e, e);
}
