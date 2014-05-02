#!/usr/bin/env rdmd

import traits_ex: isEnum;
import std.typetuple: allSatisfy;
import std.traits: EnumMembers;
import std.stdio: writefln;

/** Join/Chain/Concatenate/Unite Enumerations $(D E).
    See also: http://forum.dlang.org/thread/f9vc6p$1b7k$1@digitalmars.com
*/
template join(E...) if (allSatisfy!(isEnum, E)) {
    mixin({
            string r = "enum join { ";
            foreach (T; E) {
                import std.range: join;
                r ~= [__traits(allMembers, T), " "].join(",");
            }
            return r ~ "}";
        }());
}

unittest
{
    enum E1 { a, b, c }
    enum E2 { e, f, g }
    enum E3 { h, i, j}
    alias E1_ = join!(E1);
    alias E12 = join!(E1, E2);
    alias E123 = join!(E1, E2, E3);
    foreach (immutable e; [EnumMembers!E123])
        writefln("E123.%s: %d", e, e);
}

/** Unite Values of Enumerations $(D E).
 */
template unite(E...) if (allSatisfy!(isEnum, E)) {
    mixin({
            string r = "enum unite { ";
            foreach (T; E) {
                import std.range: join;
                r ~= [__traits(allMembers, T), " "].join(",");
            }
            return r ~ "}";
        }());
}

unittest
{
    enum E1 { a = 0, b, c }
    enum E2 { d = E1.max+9, e, f }
    alias E12 = unite!(E1, E2);
    foreach (immutable e; [EnumMembers!E12])
        writefln("E12.%s: %d", e, e);
}
