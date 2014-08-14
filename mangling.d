#!/usr/bin/env rdmd-dev

/** Executable Symbol Name Mangling and Demangling. */
module mangling;

/** Mangled Language. */
enum Lang
{
    unknown,                    // Unknown: ?
    c,                          // C
    cxx,                        // C++
    d,                          // D
    java,                       // Java
}

/** TODO: How do I make this ? */
string toTag(Lang lang)
{
    final switch (lang)
    {
    case Lang.unknown: return "?";
    case Lang.c: return "C";
    case Lang.cxx: return "C++";
    case Lang.d: return "D";
    case Lang.java: return "Java";
    }
}

unittest
{
    assert(toTag(Lang.init) == `?`);
    assert(toTag(Lang.c) == `C`);
    assert(toTag(Lang.cxx) == `C++`);
    assert(toTag(Lang.d) == `D`);
    assert(toTag(Lang.java) == `Java`);
}

import std.typecons: tuple, Tuple;

/** Demangle Symbol $(D sym) and Detect Language.
    See also: https://en.wikipedia.org/wiki/Name_mangling
    See also: https://gcc.gnu.org/onlinedocs/libstdc++/manual/ext_demangling.html
*/
Tuple!(Lang, string) demangleELF(in string sym) /* @safe pure nothrow @nogc */
{
    import std.algorithm: startsWith, findSplitAfter;
    const cxxHit = sym.findSplitAfter("_ZN"); // split into C++ prefix and rest

    string[] ids; // TODO: Turn this into a range that is returned

    import std.range: empty;
    if (!cxxHit[0].empty) // C++
    {
        string rest = cxxHit[1];
        import algorithm_ex: findSplit, findSplitBefore;
        import std.algorithm: joiner;
        import std.conv: to;
        import std.ascii: isDigit;
        import std.array: array;
        import std.stdio;
        import std.range: take, drop;

        while (true)
        {
            const split = rest.findSplitBefore!(a => !a.isDigit);
            const digits = split[0];
            rest = split[1];
            if (!digits.empty)     // digit prefix
            {
                const num = to!int(digits);
                const id = rest[0..num]; // identifier, rest.take(num)
                rest = rest[num..$]; // rest.drop(num);
                ids ~= id;
            }
            else if (rest.startsWith("E")) // end finalizer
            {
                rest = rest[1..$];
                break;          // ok to quit
            }
            else
            {
                writeln("Incomplete parsing");
                break;
            }
        }
        writeln("ids: ", ids.joiner("."));
        if (!rest.empty)
            writeln("rest: ", rest);

        return tuple(Lang.cxx, cxxHit[1]);
    }
    else
    {
        import core.demangle: demangle;
        const symAsD = sym.demangle;
        import std.conv: to;
        if (symAsD != sym) // TODO: Why doesn't (symAsD is sym) work here?
            return tuple(Lang.d, to!string(symAsD));
        else
            return tuple(Lang.init, sym);
    }
}

unittest
{
    auto x = "_ZN9wikipedia7article6formatE".demangleELF();
    import std.stdio;
    writeln(x);
    assert(x == tuple(Lang.cxx, "wikipedia::article::format"));
}
