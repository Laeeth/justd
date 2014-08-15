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
    See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangling
    See also: https://gcc.gnu.org/onlinedocs/libstdc++/manual/ext_demangling.html
*/
Tuple!(Lang, string) demangleELF(in string sym,
                                 string separator = null) /* @safe pure nothrow @nogc */
{
    import std.algorithm: startsWith, findSplitAfter;
    const cxxHit = sym.findSplitAfter("_ZN"); // split into C++ prefix and rest

    string[] ids; // TODO: Turn this into a range that is returned

    import std.range: empty;
    if (!cxxHit[0].empty) // C++
    {
        string rest = cxxHit[1];
        import algorithm_ex: split, splitBefore;
        import std.algorithm: joiner;
        import std.conv: to;
        import std.ascii: isDigit;
        import std.array: array;
        import std.stdio;
        import std.range: take, drop;

        // symbols
        while (!rest.empty &&
               rest[0] != 'E')
        {
            const match = rest.splitBefore!(a => !a.isDigit);
            const digits = match[0];
            if (!digits.empty)     // digit prefix
            {
                rest = match[1];
                const num = to!int(digits);
                const id = rest[0..num]; // identifier, rest.take(num)
                rest = rest[num..$]; // rest.drop(num);
                ids ~= id;
            }
            else if (rest[0] != 'E') // end finalizer
            {
                version(unittest)
                {
                    assert(false, "Incomplete parsing at " ~ rest);
                }
                else
                {
                    writeln("Incomplete parsing");
                    break;
                }
            }
        }

        if (rest.startsWith("E"))
        {
            rest = rest[1..$];
        }

        // optional function arguments
        int argCount = 0;
        char[] args;
        if ((!rest.empty)) // if optional function arguments exist
        {
            args ~= `(`;
            bool isRef = false;
            while (!rest.empty)
            {
                string type;
                switch (rest[0])
                {
                case 'v':       // void
                    rest = rest[1..$];
                    type = "void";
                    if (isRef) { isRef = false; type ~= "&"; }
                    break;
                case 'R':       // reference
                    rest = rest[1..$];
                    isRef = true;
                    break;
                case 'S': // standard namespace: std::
                    rest = rest[1..$];
                    type ~= "std::";
                    switch (rest[0])
                    {
                    case 't': rest = rest[1..$]; type ~= "ostream"; break;

                    case 'a': rest = rest[1..$]; type ~= "allocator"; break;
                    case 'b': rest = rest[1..$]; type ~= "basic_string"; break;
                    case 's':
                        rest = rest[1..$];
                        type ~= "basic_string<char, std::char_traits<char>, std::allocator<char> >";
                        break;

                    case 'i': rest = rest[1..$]; type ~= "istream"; break;
                    case 'o': rest = rest[1..$]; type ~= "ostream"; break;
                    case 'd': rest = rest[1..$]; type ~= "iostream"; break;

                    default:
                        /* writeln("Cannot handle C++ standard prefix character: '", rest[0], "'"); */
                        rest = rest[1..$];
                        break;
                    }
                    if (isRef) { isRef = false; type ~= "&"; }
                    break;
                default:
                    /* writeln("Cannot handle character: '", rest[0], "'"); */
                    rest = rest[1..$];
                    break;
                }
                if (type)
                {
                    if (argCount >= 1)
                    {
                        args ~= ',';
                    }
                    args ~= type;
                    argCount += 1;
                }
            }
            args ~= `)`;
        }

        if (!separator)
            separator = "::"; // default C++ separator

        const qid = to!string(ids.joiner(separator)) ~ to!string(args); // qualified id
        if (!rest.empty)
            writeln("rest: ", rest);

        return tuple(Lang.cxx, qid);
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
    import assert_ex;
    assertEqual("_ZN9wikipedia7article8print_toERSo".demangleELF,
                tuple(Lang.cxx, "wikipedia::article::print_to(std::ostream&)"));
    assertEqual("_ZN9wikipedia7article6formatEv".demangleELF,
                tuple(Lang.cxx, "wikipedia::article::format(void)"));
    assertEqual("_ZN9wikipedia7article6formatE".demangleELF,
                tuple(Lang.cxx, "wikipedia::article::format"));
}
