#!/usr/bin/env rdmd

/** Extension to enumerations.
    TODO: Move to std.typecons (Type Constructor) in Phobos when ready.
 */
module enums;

import traits_ex: isEnum;
import std.typetuple: allSatisfy;
import std.traits: EnumMembers;
import std.stdio: writefln;

/** Unite (Chain, Join) Member Names of Enumerations $(D E).
    See also: http://forum.dlang.org/thread/f9vc6p$1b7k$1@digitalmars.com
    Todo: Nice error messages for name collisions.
*/
template uniteMemberNames(E...) if (allSatisfy!(isEnum, E)) {
    mixin({
            string r = "enum uniteMemberNames { ";
            foreach (T; E) {
                import std.range: join;
                r ~= [__traits(allMembers, T)].join(",") ~ ",";
            }
            return r ~ " }";
        }());
}

unittest
{
    enum E1 { a, b, c }
    enum E2 { e, f, g }
    enum E3 { h, i, j}
    alias E1_ = uniteMemberNames!(E1);
    alias E12 = uniteMemberNames!(E1, E2);
    alias E123 = uniteMemberNames!(E1, E2, E3);
    foreach (immutable e; [EnumMembers!E123])
        writefln("E123.%s: %d", e, e);
}

/** Unite (Chain, Join) Members (both their Names and Values) of Enumerations $(D E).
    Todo: Nice error messages for value collisions.
*/
template uniteMembers(E...) if (allSatisfy!(isEnum, E)) {
    mixin({
            string r = "enum uniteMembers { ";
            foreach (T; E) {
                import std.range: map, join;
                import std.conv: to;
                r ~= [EnumMembers!T].map!(a =>
                                          (to!string(a) ~ "=" ~
                                           to!string(to!int(a)))).join(",") ~ ",";
            }
            return r ~ " }";
        }());
}

unittest
{
    enum E1 { a = 0, b, c }
    enum E2 { d = 10, e, f } // continue after E1
    enum E3 { g = 20, h, i } // continue after E2
    alias E = uniteMembers!(E1, E2, E3);
    foreach (immutable e; [EnumMembers!E])
        writefln("E.%s: %d", e, e);
}
