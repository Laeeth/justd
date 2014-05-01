#!/usr/bin/env rdmd

import std.stdio: writeln;
import traits_ex: isEnum;
import std.typetuple: allSatisfy;

string enumsHelper(S...)(S s)
{
    typeof(return) r;
    foreach (i, e; s)
    {
        if (i >= 1)
            r ~= ", ";
        r ~= e;
    }
    return r;
}

/** Join/Chain/Concatenate/Unite Enums $(D E1), $(D E2), ... into $(D E).
    See also: http://forum.dlang.org/thread/f9vc6p$1b7k$1@digitalmars.com
*/
template join(string E, E1, E2) if (isEnum!E1 &&
                                    isEnum!E2)
{
    enum join = ("enum " ~ E ~ " { " ~
                 enumsHelper(__traits(allMembers, E1)) ~ "," ~
                 enumsHelper(__traits(allMembers, E2)) ~ " }");
}

template njoin(string E0, E1...) if (allSatisfy!(isEnum, E1))
{
    import std.algorithm: map;
    enum string njoin = "enum " ~ E0 ~ " { " ~ "" ~ " } ";
}

unittest
{
    enum E1 { A, B, C }
    enum E2 { E, F, G }
    mixin(join!("E12", E1, E2));
    E12 e12;
    writeln(e12.min, ",", e12.max);
}
