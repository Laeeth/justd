#!/usr/bin/env rdmd

import std.stdio: writeln;
import traits_ex: isEnum;
import std.typetuple: allSatisfy;

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
    writeln(E123.min, ",", E123.max);
}
