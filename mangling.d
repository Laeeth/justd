#!/usr/bin/env rdmd-dev

module mangling;

/** Mangled Language. */
enum Lang
{
    unknown,                    // Unknown: ?
    c,                          // C
    cxx,                        // C++
    d,                          // D
}

import std.typecons: Tuple, tuple;

/** Demangle Symbol $(D sym) and Detect Language.
    See also: https://en.wikipedia.org/wiki/Name_mangling
    See also: https://gcc.gnu.org/onlinedocs/libstdc++/manual/ext_demangling.html
*/
Tuple!(Lang, string) demangleELF(in string sym)
{
    import std.string: startsWith, findSplitAfter;
    auto cxxHit = sym.findSplitAfter("_ZN"); // split into C++ prefix and rest
    import std.range: empty;
    if (!cxxHit[0].empty) // C++
    {
        return tuple(Lang.cxx, cxxHit[1]);
    }
    else
    {
        import core.demangle: demangle;
        auto symAsD = sym.demangle;
        import std.conv: to;
        if (symAsD != sym) // TODO: Why doesn't (symAsD is sym) work here?
            return tuple(Lang.d, to!string(symAsD));
        else
            return tuple(Lang.init, sym);
    }
}

unittest
{
}
