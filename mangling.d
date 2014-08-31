#!/usr/bin/env rdmd-dev

/** ELF Symbol Name (De)Mangling.
    Copyright: Per Nordlöw 2014-.
    License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
    Authors: $(WEB Per Nordlöw)
 */
module mangling;

import std.range: empty, popFront, popFrontExactly, take, drop, front;
import std.algorithm: startsWith, findSplitAfter, skipOver, joiner;
import std.typecons: tuple, Tuple;
import std.conv: to;
import std.ascii: isDigit;
import std.array: array;
import std.stdio;
import dbg;
import languages;
import algorithm_ex: either, split, splitBefore;

/** Decode Unqualified C++ Type at $(D rest).
    See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangling-type
*/
string decodeCxxUnqualifiedType(ref string rest)
{
    return either(rest.decodeCxxBuiltinType,
                  rest.decodeCxxSubstitution,
                  rest.decodeCxxFunctionType);
    /* if (const biType = rest.decodeCxxBuiltinType) */
    /* { */
    /*     return biType; */
    /* } */
    /* else if (const substType = rest.decodeCxxSubstitution) */
    /* { */
    /*     return substType; */
    /* } */
    /* else if (const funType = rest.decodeCxxFunctionType) */
    /* { */
    /*     return funType.get; */
    /* } */
    /* assert(false, "Handle " ~ rest); */
}

/** Decode C++ Type at $(D rest).
    See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangling-type
*/
string decodeCxxType(ref string rest)
{
    // <ref-qualifier>
    bool isRef = false;      // & ref-qualifier
    bool isRVRef = false;    // && ref-qualifier (C++11)
    bool isComplexPair = false;    // complex pair (C 2000)
    bool isImaginary = false;    // imaginary (C 2000)
    bool isPointer = false;

    /* TODO: Order of these may vary. */
    const cvq = rest.decodeCxxCVQualifiers;
    switch (rest[0]) // TODO: Check for !rest.empty
    {
        case 'P': rest.popFront; isPointer = true; break;
            // <ref-qualifier>: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.ref-qualifier
        case 'R': rest.popFront; isRef = true; break;
        case 'O': rest.popFront; isRVRef = true; break;
        case 'C': rest.popFront; isComplexPair = true; break;
        case 'G': rest.popFront; isImaginary = true; break;
        case 'U': rest.popFront;
            const sourceName = rest.decodeCxxSourceName;
            dln("Handle vendor extended type qualifier <source-name>", rest);
            break;
        default: break;
    }

    string type = null;

    // prefix qualifiers
    if (cvq.isRestrict) { type ~= `restrict `; } // C99
    if (cvq.isVolatile) { type ~= `volatile `; }
    if (cvq.isConst) { type ~= `const `; }

    type ~= rest.decodeCxxUnqualifiedType;

    // suffix qualifiers
    if (isRef) { type ~= `&`; }
    if (isRVRef) { type ~= `&&`; }
    if (isPointer) { type = type ~ `*`; }

    return type;
}

/** Try to Decode C++ Operator at $(D rest).
    See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangling-operator
*/
string decodeCxxOperator(ref string rest)
{
    string type = null;
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
        default: break;
    }
    if (type !is null) { rest.popFrontExactly(n); } // digest if match
    return type;
}

/** Try to Decode C++ Builtin Type at $(D rest).
    See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.builtin-type
*/
string decodeCxxBuiltinType(ref string rest)
{
    string type = null;
    enum n = 1;
    if (rest.length < n) { return type; }
    switch (rest[0])
    {
        case 'v': rest.popFront; type = `void`; break;
        case 'w': rest.popFront; type = `wchar_t`; break;

        case 'b': rest.popFront; type = `bool`; break;

        case 'c': rest.popFront; type = `char`; break;
        case 'a': rest.popFront; type = `signed char`; break;
        case 'h': rest.popFront; type = `unsigned char`; break;

        case 's': rest.popFront; type = `short`; break;
        case 't': rest.popFront; type = `unsigned short`; break;

        case 'i': rest.popFront; type = `int`; break;
        case 'j': rest.popFront; type = `unsigned int`; break;

        case 'l': rest.popFront; type = `long`; break;
        case 'm': rest.popFront; type = `unsigned long`; break;

        case 'x': rest.popFront; type = `long long`; break;  // __int64
        case 'y': rest.popFront; type = `unsigned long long`; break; // __int64

        case 'n': rest.popFront; type = `__int128`; break;
        case 'o': rest.popFront; type = `unsigned __int128`; break;

        case 'f': rest.popFront; type = `float`; break;
        case 'd': rest.popFront; type = `double`; break;
        case 'e': rest.popFront; type = `long double`; break; // __float80
        case 'g': rest.popFront; type = `__float128`; break;

        case 'z': rest.popFront; type = `...`; break; // ellipsis

        case 'D':
            rest.popFront;
            assert(!rest.empty); // need one more
            switch (rest[0])
            {
                case 'd': rest.popFront; type = `IEEE 754r decimal floating point (64 bits)`; break;
                case 'e': rest.popFront; type = `IEEE 754r decimal floating point (128 bits)`; break;
                case 'f': rest.popFront; type = `IEEE 754r decimal floating point (32 bits)`; break;
                case 'h': rest.popFront; type = `IEEE 754r half-precision floating point (16 bits)`; break;
                case 'i': rest.popFront; type = `char32_t`; break;
                case 's': rest.popFront; type = `char16_t`; break;
                case 'a': rest.popFront; type = `auto`; break;
                case 'c': rest.popFront; type = `decltype(auto)`; break;
                case 'n': rest.popFront; type = `std::nullptr_t`; break; // (i.e., decltype(nullptr))
                default: dln(`TODO: Handle `, rest);
            }
            break;

            /* TODO: */
            /* ::= u <source-name>	# vendor extended type */

        default:
            break;
    }

    return type;
}

/** Decode C++ Substitution Type at $(D rest).
    See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.substitution
*/
string decodeCxxSubstitution(ref string rest)
{
    if (rest.startsWith('S'))
    {
        string type = null;
        rest.popFront;
        type ~= `::std::`;
        switch (rest[0])
        {
            case 't': rest.popFront; type ~= `ostream`; break;
            case 'a': rest.popFront; type ~= `allocator`; break;
            case 'b': rest.popFront; type ~= `basic_string`; break;
            case 's':
                rest.popFront;
                type ~= `basic_string<char, std::char_traits<char>, std::allocator<char> >`;
                break;
            case 'i': rest.popFront; type ~= `istream`; break;
            case 'o': rest.popFront; type ~= `ostream`; break;
            case 'd': rest.popFront; type ~= `iostream`; break;
            default:
                dln(`Cannot handle C++ standard prefix character: '`, rest[0], `'`);
                rest.popFront;
                break;
        }
        return type;
    }
    return null;
}

/** Try to Decode C++ Function Type at $(D rest).
    See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.function-type
*/
string decodeCxxFunctionType(ref string rest)
{
    string type = null;
    dln("TODO");
    return type;
}

struct CXXCVQualifiers
{
    bool isRestrict; // (C99)
    bool isVolatile; // volatile
    bool isConst; // const
}

/** Decode <CV-qualifiers>
    See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.CV-qualifiers
*/
CXXCVQualifiers decodeCxxCVQualifiers(ref string rest)
{
    CXXCVQualifiers cvq;
    if (rest.startsWith('r')) { rest.popFront; cvq.isRestrict = true; }
    if (rest.startsWith('V')) { rest.popFront; cvq.isVolatile = true; }
    if (rest.startsWith('K')) { rest.popFront; cvq.isConst = true; }
    return cvq;
}

/** Decode Identifier <source-name>.
    See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.source-name
*/
string decodeCxxSourceName(ref string rest)
{
    string id = null;
    const match = rest.splitBefore!(a => !a.isDigit);
    const digits = match[0];
    rest = match[1];
    if (!digits.empty)     // digit prefix
    {
        // TODO: Functionize these three lines
        const num = digits.to!uint;
        id = rest[0..num]; // identifier, rest.take(num)
        rest = rest[num..$]; // rest.drop(num);
    }
    return id;
}

/* Decode C++ Symbol.

   See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.encoding
 */
Tuple!(Lang, string) decodeCxxSymbol(string rest,
                                     string separator = null) /* @safe pure nothrow @nogc */
{
    string[] ids; // TODO: Turn this into a range that is returned
    bool hasTerminator = false;

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
        if (const sourceName = rest.decodeCxxSourceName)
        {
            ids ~= sourceName;
            continue;
        }

        if (const op = rest.decodeCxxOperator)
        {
            ids ~= op;
            continue;
        }

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
    char[] argTypes; // argument types
    while (!rest.empty) // while optional function arguments exist
    {
        const argType = rest.decodeCxxType;
        if (argCount >= 1) { argTypes ~= `, `; }
        argTypes ~= argType;
        argCount += 1;
    }

    if (!separator)
        separator = `::`; // default C++ separator

    auto qid = to!string(ids.joiner(separator)); // qualified id
    if (!argTypes.empty)
    {
        qid ~= `(` ~ to!string(argTypes) ~ `)`;
    }

    if (!rest.empty)
        dln(`rest: `, rest);

    return tuple(Lang.cxx, qid);
}


/** Demangle Symbol $(D rest) and Detect Language.
    See also: https://en.wikipedia.org/wiki/Name_mangling
    See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangling
    See also: https://gcc.gnu.org/onlinedocs/libstdc++/manual/ext_demangling.html
*/
Tuple!(Lang, string) decodeSymbol(string rest,
                                  string separator = null) /* @safe pure nothrow @nogc */
{
    if (rest.empty)
    {
        return tuple(Lang.init, rest);
    }

    if (!rest.startsWith(`_`))
    {
        return tuple(Lang.c, rest); // assume C
    }

    // See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.mangled-name
    const cxxHit = rest.findSplitAfter(`_Z`); // split into C++ prefix and rest
    if (!cxxHit[0].empty) // C++
    {
        return decodeCxxSymbol(cxxHit[1], separator);
    }
    else
    {
        import core.demangle: demangle;
        const symAsD = rest.demangle;
        import std.conv: to;
        if (symAsD != rest) // TODO: Why doesn't (symAsD is rest) work here?
            return tuple(Lang.d, to!string(symAsD));
        else
            return tuple(Lang.init, rest);
    }
}

import backtrace.backtrace;

unittest
{
    import assert_ex;
    backtrace.backtrace.install(stderr);

    assertEqual(`_ZN9wikipedia7article8print_toERSo`.decodeSymbol,
                tuple(Lang.cxx, `wikipedia::article::print_to(::std::ostream&)`));

    assertEqual(`_ZN9wikipedia7article8print_toEOSo`.decodeSymbol,
                tuple(Lang.cxx, `wikipedia::article::print_to(::std::ostream&&)`));

    assertEqual(`_ZN9wikipedia7article6formatEv`.decodeSymbol,
                tuple(Lang.cxx, `wikipedia::article::format(void)`));

    assertEqual(`_ZN9wikipedia7article6formatE`.decodeSymbol,
                tuple(Lang.cxx, `wikipedia::article::format`));

    assertEqual(`_ZSt5state`.decodeSymbol,
                tuple(Lang.cxx, `::std::state`));

    /* assertEqual(`_ZNSt3_In4wardE`.decodeSymbol, */
    /*             tuple(Lang.cxx, `::std::_In::ward`)); */

    /* assertEqual(`_ZStL19piecewise_construct`.decodeSymbol, */
    /*             tuple(Lang.cxx, `std::piecewise_construct`)); */
}
