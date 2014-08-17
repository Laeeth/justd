#!/usr/bin/env rdmd-dev

/** Executable Symbol Name Mangling and Demangling. */
module mangling;

import std.range: empty;

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

import std.typecons: tuple, Tuple, Nullable;
import dbg;

/** Instantiator for $(D Nullable).
    TODO: Add to Phobos.
*/
Nullable!T nullable(T)(T a)
{
    return typeof(return)(a);
}

/** Instantiator for $(D Nullable).
    TODO: Add to Phobos.
 */
Nullable!T nullable(T nullValue, T)(T a, T nullValue)
{
    return Nullable!nullValue(a);
}

version(none) unittest
{
    auto x = nullable!(int.max)(3);
}

/** Decode C++ Type at $(D sym).
    See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangling-type
*/
string decodeCxxType(ref string sym)
{
    const biType = sym.decodeCxxBuiltinType;
    if (!biType.isNull) { return biType.get; } // digest if match

    const funType = sym.decodeCxxFunctionType;
    if (!funType.isNull) { return funType.get; } // digest if match

    assert(false, "Unmatched encoding at " ~ sym);
}

/** Try to Decode C++ Operator at $(D rest).
    See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangling-operator
*/
Nullable!string decodeCxxOperator(ref string rest)
{
    typeof(return) type;
    enum n = 2;
    if (rest.length < n) { return type; }
    switch (rest[0..n])
    {
        case `nw`: type = `operator new`; break;
        case `na`: type = `operator new[]`; break;
        case `dl`: type = `operator delete`; break;
        case `da`: type = `operator delete[]`; break;
        case `ps`: type = `operator +`; break; // unary plus
        case `ng`: type = `operator -`; break; // unary minus

        case `ad`: type = `operator &`; break; // address of
        case `de`: type = `operator *`; break; // dereference

        case `co`: type = `operator ~`; break; // bitwise complement
        case `pl`: type = `operator +`; break; // plus
        case `mi`: type = `operator -`; break; // minus

        case `ml`: type = `operator *`; break; // multiplication
        case `dv`: type = `operator /`; break; // division
        case `rm`: type = `operator %`; break; // remainder

        case `an`: type = `operator &`; break; // bitwise and
        case `or`: type = `operator |`; break; // bitwise of

        case `eo`: type = `operator ^`; break;
        case `aS`: type = `operator =`; break;

        case `pL`: type = `operator +=`; break;
        case `mI`: type = `operator -=`; break;
        case `mL`: type = `operator *=`; break;
        case `dV`: type = `operator /=`; break;
        case `rM`: type = `operator %=`; break;

        case `aN`: type = `operator &=`; break;
        case `oR`: type = `operator |=`; break;
        case `eO`: type = `operator ^=`; break;

        case `ls`: type = `operator <<`; break;
        case `rs`: type = `operator >>`; break;
        case `lS`: type = `operator <<=`; break;
        case `rS`: type = `operator >>=`; break;

        case `eq`: type = `operator ==`; break;
        case `ne`: type = `operator !=`; break;
        case `lt`: type = `operator <`; break;
        case `gt`: type = `operator >`; break;
        case `le`: type = `operator <=`; break;
        case `ge`: type = `operator >=`; break;

        case `nt`: type = `operator !`; break;
        case `aa`: type = `operator &&`; break;
        case `oo`: type = `operator ||`; break;

        case `pp`: type = `operator ++`; break; // (postfix in <expression> context)
        case `mm`: type = `operator --`; break; // (postfix in <expression> context)

        case `cm`: type = `operator ,`; break;

        case `pm`: type = `operator ->*`; break;
        case `pt`: type = `operator ->`; break;

        case `cl`: type = `operator ()`; break;
        case `ix`: type = `operator []`; break;
        case `qu`: type = `operator ?`; break;
        case `cv`: type = `operator (<type>)`; break; // type-cast: TODO: Decode type
        case `li`: type = `operator "" <source-name>`; break;
            // TODO: case `v `: type = `operator <digit> <source-name>`; break;
        default:
            dln(`TODO: Handle `, rest);
    }
    if (!type.isNull) { rest = rest[n..$]; } // digest if match
    return type;
}

/** Try to Decode C++ Builtin Type at $(D sym).
    See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.builtin-type
*/
Nullable!string decodeCxxBuiltinType(ref string rest)
{
    typeof(return) type;
    enum n = 1;
    if (rest.length < n) { return type; }
    switch (rest[0])
    {
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
            switch (rest[0])
            {
                case 'd': rest = rest[1..$]; type = `IEEE 754r decimal floating point (64 bits)`; break;
                case 'e': rest = rest[1..$]; type = `IEEE 754r decimal floating point (128 bits)`; break;
                case 'f': rest = rest[1..$]; type = `IEEE 754r decimal floating point (32 bits)`; break;
                case 'h': rest = rest[1..$]; type = `IEEE 754r half-precision floating point (16 bits)`; break;
                case 'i': rest = rest[1..$]; type = `char32_t`; break;
                case 's': rest = rest[1..$]; type = `char16_t`; break;
                case 'a': rest = rest[1..$]; type = `auto`; break;
                case 'c': rest = rest[1..$]; type = `decltype(auto)`; break;
                case 'n': rest = rest[1..$]; type = `std::nullptr_t`; break; // (i.e., decltype(nullptr))
                default: dln(`TODO: Handle `, rest);
            }
            break;

            /* TODO: */
            /* ::= u <source-name>	# vendor extended type */

        default:
            dln(`TODO: Handle `, rest);
            break;
    }

    return type;
}

/** Try to Decode C++ Function Type at $(D rest).
    See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.function-type
*/
Nullable!string decodeCxxFunctionType(ref string rest)
{
    typeof(return) type;
    dln("TODO");
    return type;
}

/** Demangle Symbol $(D sym) and Detect Language.
    See also: https://en.wikipedia.org/wiki/Name_mangling
    See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangling
    See also: https://gcc.gnu.org/onlinedocs/libstdc++/manual/ext_demangling.html
*/
Tuple!(Lang, string) demangleSymbol(in string sym,
                                    string separator = null) /* @safe pure nothrow @nogc */
{
    import std.algorithm: startsWith, findSplitAfter, skipOver;

    const cxxHit = sym.findSplitAfter(`_Z`); // split into C++ prefix and rest

    if (!cxxHit[0].empty) // C++
    {
        string[] ids; // TODO: Turn this into a range that is returned
        string rest = cxxHit[1];
        bool hasTerminator = false;

        import algorithm_ex: split, splitBefore;
        import std.algorithm: joiner;
        import std.conv: to;
        import std.ascii: isDigit;
        import std.array: array;
        import std.stdio;
        import std.range: take, drop, front;

        if (rest.skipOver('N')) // nested name: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.nested-name
        {
            hasTerminator = true;
        }
        else if (rest.skipOver('L'))
        {
            hasTerminator = false;
        }

        // symbols (function or variable name)
        while (!rest.empty &&
               (!hasTerminator ||
                rest[0] != 'E'))
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
                continue;
            }

            const op = rest.decodeCxxOperator;
            if (!op.isNull) { continue; }

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

        if (hasTerminator)
        {
            rest.skipOver('E');
        }

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
                auto type = rest.decodeCxxBuiltinType;

                switch (rest[0])
                {
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

    assertEqual(`_ZStL19piecewise_construct`.demangleSymbol,
                tuple(Lang.cxx, `std::piecewise_construct`));

    assertEqual(`_ZN9wikipedia7article8print_toERSo`.demangleSymbol,
                tuple(Lang.cxx, `wikipedia::article::print_to(std::ostream&)`));
    assertEqual(`_ZN9wikipedia7article8print_toEOSo`.demangleSymbol,
                tuple(Lang.cxx, `wikipedia::article::print_to(std::ostream&&)`));
    assertEqual(`_ZN9wikipedia7article6formatEv`.demangleSymbol,
                tuple(Lang.cxx, `wikipedia::article::format(void)`));
    assertEqual(`_ZN9wikipedia7article6formatE`.demangleSymbol,
                tuple(Lang.cxx, `wikipedia::article::format`));
}
