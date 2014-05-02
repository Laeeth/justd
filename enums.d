#!/usr/bin/env rdmd

import traits_ex: isEnum;
import std.typetuple: allSatisfy;
import std.traits: EnumMembers;
import std.stdio: writefln;

/** Chain (Join) Member Names of Enumerations $(D E).
    See also: http://forum.dlang.org/thread/f9vc6p$1b7k$1@digitalmars.com
*/
template chainMemberNames(E...) if (allSatisfy!(isEnum, E)) {
    mixin({
            string r = "enum chainMemberNames { ";
            foreach (T; E) {
                import std.range: join;
                r ~= [__traits(allMembers, T), " "].join(",");
            }
            return r ~ "}";
        }());
}
alias chain = chainMemberNames;

unittest
{
    enum E1 { a, b, c }
    enum E2 { e, f, g }
    enum E3 { h, i, j}
    alias E1_ = chainMemberNames!(E1);
    alias E12 = chainMemberNames!(E1, E2);
    alias E123 = chainMemberNames!(E1, E2, E3);
    foreach (immutable e; [EnumMembers!E123])
        writefln("E123.%s: %d", e, e);
}

/** Unite Member Values of Enumerations $(D E).
 */
template uniteMemberValues(E...) if (allSatisfy!(isEnum, E)) {
    mixin({
            string r = "enum uniteMemberValues { ";
            foreach (T; E) {
                import std.range: join;
                r ~= [__traits(allMembers, T), " "].join(",");
            }
            return r ~ "}";
        }());
}
alias unite = uniteMemberValues;

unittest
{
    enum E1 { a = 0, b, c }
    enum E2 { d = E1.max+9, e, f }
    alias E12 = uniteMemberValues!(E1, E2);
    foreach (immutable e; [EnumMembers!E12])
        writefln("E12.%s: %d", e, e);
}
