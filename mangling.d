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
    case Lang.unknown: return `?`;
    case Lang.c: return `C`;
    case Lang.cxx: return `C++`;
    case Lang.d: return `D`;
    case Lang.java: return `Java`;
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
import dbg;

/** Demangle Symbol $(D sym) and Detect Language.
    See also: https://en.wikipedia.org/wiki/Name_mangling
    See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangling
    See also: https://gcc.gnu.org/onlinedocs/libstdc++/manual/ext_demangling.html
*/
Tuple!(Lang, string) demangleELF(in string sym,
                                 string separator = null) /* @safe pure nothrow @nogc */
{
    import std.algorithm: startsWith, findSplitAfter, skipOver;
    import std.range: empty;

    const cxxHit = sym.findSplitAfter(`_Z`); // split into C++ prefix and rest

    if (!cxxHit[0].empty) // C++
    {
        string[] ids; // TODO: Turn this into a range that is returned
        string rest = cxxHit[1];
        import algorithm_ex: split, splitBefore;
        import std.algorithm: joiner;
        import std.conv: to;
        import std.ascii: isDigit;
        import std.array: array;
        import std.stdio;
        import std.range: take, drop;

        if (rest.skipOver('N'))
        {
            // TODO: What differs _ZN from _Z?
        }

        // symbols (function or variable name)
        while (!rest.empty &&
               rest[0] != 'E') // TODO: functionize
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
            else if (rest.length >= 2)
            {
                // https://mentorembedded.github.io/cxx-abi/abi.html#mangling-operator
                const op = rest[0..2]; // operator code
                switch (op)
                {
                case `nw`: ids ~= `operator new`; break;
                case `na`: ids ~= `operator new[]`; break;
                case `dl`: ids ~= `operator delete`; break;
                case `da`: ids ~= `operator delete[]`; break;
                case `ps`: ids ~= `operator +`; break; // unary plus
                case `ng`: ids ~= `operator -`; break; // unary minus

                case `ad`: ids ~= `operator &`; break; // address of
                case `de`: ids ~= `operator *`; break; // dereference

                case `co`: ids ~= `operator ~`; break; // bitwise complement
                case `pl`: ids ~= `operator +`; break; // plus
                case `mi`: ids ~= `operator -`; break; // minus

                case `ml`: ids ~= `operator *`; break; // multiplication
                case `dv`: ids ~= `operator /`; break; // division
                case `rm`: ids ~= `operator %`; break; // remainder

                case `an`: ids ~= `operator &`; break; // bitwise and
                case `or`: ids ~= `operator |`; break; // bitwise of

                case `eo`: ids ~= `operator ^`; break;
                case `aS`: ids ~= `operator =`; break;

                case `pL`: ids ~= `operator +=`; break;
                case `mI`: ids ~= `operator -=`; break;
                case `mL`: ids ~= `operator *=`; break;
                case `dV`: ids ~= `operator /=`; break;
                case `rM`: ids ~= `operator %=`; break;

                case `aN`: ids ~= `operator &=`; break;
                case `oR`: ids ~= `operator |=`; break;
                case `eO`: ids ~= `operator ^=`; break;

                case `ls`: ids ~= `operator <<`; break;
                case `rs`: ids ~= `operator >>`; break;
                case `lS`: ids ~= `operator <<=`; break;
                case `rS`: ids ~= `operator >>=`; break;

                case `eq`: ids ~= `operator ==`; break;
                case `ne`: ids ~= `operator !=`; break;
                case `lt`: ids ~= `operator <`; break;
                case `gt`: ids ~= `operator >`; break;
                case `le`: ids ~= `operator <=`; break;
                case `ge`: ids ~= `operator >=`; break;

                case `nt`: ids ~= `operator !`; break;
                case `aa`: ids ~= `operator &&`; break;
                case `oo`: ids ~= `operator ||`; break;

                case `pp`: ids ~= `operator ++`; break; // (postfix in <expression> context)
                case `mm`: ids ~= `operator --`; break; // (postfix in <expression> context)

                case `cm`: ids ~= `operator ,`; break;

                case `pm`: ids ~= `operator ->*`; break;
                case `pt`: ids ~= `operator ->`; break;

                case `cl`: ids ~= `operator ()`; break;
                case `ix`: ids ~= `operator []`; break;
                case `qu`: ids ~= `operator ?`; break;
                case `cv`: ids ~= `operator (<type>)`; break; // type-cast: TODO: Decode type
                case `li`: ids ~= `operator "" <source-name>`; break;
                case `v `: ids ~= `operator <digit> <source-name>`; break;
                default: dln(`Handle last `, op, ` of whole `, sym);
                }
                rest = rest[2..$];
            }
            else
            {
                version(unittest)
                {
                    assert(false, `Incomplete parsing at ` ~ rest);
                }
                else
                {
                    dln(`Incomplete parsing`);
                    break;
                }
            }
        }

        rest.skipOver('E');

        // optional function arguments
        int argCount = 0;
        char[] args;
        if ((!rest.empty)) // if optional function arguments exist
        {
            args ~= `(`;

            // <ref-qualifier>
            bool isRef = false;      // & ref-qualifier
            bool isRVRef = false;    // && ref-qualifier

            // <CV-qualifiers>
            bool isRestrict = false; // restrict
            bool isConst = false; // const
            bool isVolatile = false; // volatile

            while (!rest.empty)
            {
                string type;
                switch (rest[0])
                {
                    // <builtin-type>: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.builtin-type
                case 'v': rest = rest[1..$]; type = `void`; break;
                case 'w': rest = rest[1..$]; type = `wchar_t`; break;

                case 'b': rest = rest[1..$]; type = `bool`; break;

                case 'c': rest = rest[1..$]; type = `char`; break;
                case 'a': rest = rest[1..$]; type = `signed char`; break;
                case 'h': rest = rest[1..$]; type = `unsigned char`; break;

                case 's': rest = rest[1..$]; type = `short`; break;
                case 't': rest = rest[1..$]; type = `unsigned short`; break;

                case 'i': rest = rest[1..$]; type = `int`; break;
                case 'j': rest = rest[1..$]; type = `unsigned int`; break;

                case 'l': rest = rest[1..$]; type = `long`; break;
                case 'm': rest = rest[1..$]; type = `unsigned long`; break;

                case 'x': rest = rest[1..$]; type = `long long`; break;  // __int64
                case 'y': rest = rest[1..$]; type = `unsigned long long`; break; // __int64

                case 'n': rest = rest[1..$]; type = `__int128`; break;
                case 'o': rest = rest[1..$]; type = `unsigned __int128`; break;

                case 'f': rest = rest[1..$]; type = `float`; break;
                case 'd': rest = rest[1..$]; type = `double`; break;
                case 'e': rest = rest[1..$]; type = `long double`; break; // __float80
                case 'g': rest = rest[1..$]; type = `__float128`; break;

                case 'z': rest = rest[1..$]; type = `...`; break; // ellipsis

                case 'D':
                    rest = rest[1..$];
                    assert(!rest.empty); // need one more
                    final switch(rest[0])
                    {
                        /* TODO: */
                        /* ::= d # IEEE 754r decimal floating point (64 bits) */
                        /* ::= e # IEEE 754r decimal floating point (128 bits) */
                        /* ::= f # IEEE 754r decimal floating point (32 bits) */
                        /* ::= h # IEEE 754r half-precision floating point (16 bits) */
                        /* ::= i # char32_t */
                        /* ::= s # char16_t */
                        /* ::= a # auto */
                        /* ::= c # decltype(auto) */
                        /* ::= n # std::nullptr_t (i.e., decltype(nullptr)) */
                    }
                    break;

                    /* TODO: */
                    /* ::= u <source-name>	# vendor extended type */

                    // <CV-qualifiers>: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.CV-qualifiers
                case 'r': rest = rest[1..$]; isRestrict = true; break;
                case 'V': rest = rest[1..$]; isVolatile = true; break;
                case 'K': rest = rest[1..$]; isConst = true; break;

                    // <ref-qualifier>: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.ref-qualifier
                case 'R': rest = rest[1..$]; isRef = true; break;
                case 'O': rest = rest[1..$]; isRVRef = true; break;

                case 'S': // standard namespace: std::
                    rest = rest[1..$];
                    type ~= `std::`;
                    switch (rest[0])
                    {
                    case 't': rest = rest[1..$]; type ~= `ostream`; break;

                    case 'a': rest = rest[1..$]; type ~= `allocator`; break;
                    case 'b': rest = rest[1..$]; type ~= `basic_string`; break;
                    case 's':
                        rest = rest[1..$];
                        type ~= `basic_string<char, std::char_traits<char>, std::allocator<char> >`;
                        break;

                    case 'i': rest = rest[1..$]; type ~= `istream`; break;
                    case 'o': rest = rest[1..$]; type ~= `ostream`; break;
                    case 'd': rest = rest[1..$]; type ~= `iostream`; break;

                    default:
                        /* dln(`Cannot handle C++ standard prefix character: '`, rest[0], `'`); */
                        rest = rest[1..$];
                        break;
                    }
                    break;
                default:
                    /* dln(`Cannot handle character: '`, rest[0], `'`, ` in "`, rest, `"`); */
                    rest = rest[1..$];
                    break;
                }

                if (type)
                {
                    if (argCount >= 1)
                    {
                        args ~= ',';
                    }

                    if (isRestrict) { isRestrict = false; type = `restrict ` ~ type; } // C99
                    if (isVolatile) { isVolatile = false; type = `volatile ` ~ type; }
                    if (isConst) { isConst = false; type = `const ` ~ type; }

                    if (isRef) { isRef = false; type ~= `&`; }
                    if (isRVRef) { isRVRef = false; type ~= `&&`; }

                    args ~= type;
                    argCount += 1;
                }
            }
            args ~= `)`;
        }

        if (!separator)
            separator = `::`; // default C++ separator

        const qid = to!string(ids.joiner(separator)) ~ to!string(args); // qualified id
        if (!rest.empty)
            dln(`rest: `, rest);

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
    assertEqual(`_ZN9wikipedia7article8print_toERSo`.demangleELF,
                tuple(Lang.cxx, `wikipedia::article::print_to(std::ostream&)`));
    assertEqual(`_ZN9wikipedia7article8print_toEOSo`.demangleELF,
                tuple(Lang.cxx, `wikipedia::article::print_to(std::ostream&&)`));
    assertEqual(`_ZN9wikipedia7article6formatEv`.demangleELF,
                tuple(Lang.cxx, `wikipedia::article::format(void)`));
    assertEqual(`_ZN9wikipedia7article6formatE`.demangleELF,
                tuple(Lang.cxx, `wikipedia::article::format`));
}
