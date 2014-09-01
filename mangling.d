#!/usr/bin/env rdmd-dev

/** ELF Symbol Name (De)Mangling.
    Copyright: Per Nordlöw 2014-.
    License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
    Authors: $(WEB Per Nordlöw)
    See also: https://mentorembedded.github.io/cxx-abi/abi.html

    TODO: Search for pattern "X> <Y" and assure that they all use
    return rest.tryEvery(X, Y).
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
import algorithm_ex: either, every, tryEvery, split, splitBefore, findPopBefore, findPopAfter;

/** Like $(D skipOver) but return $(D string) instead of $(D bool).

    Bool-conversion of returned value gives same result as rest.skipOver(lit).
 */
string skipLiteral(T)(ref string rest, T lit)
{
    return rest.skipOver(lit) ? "" : null;
}

/** Decode Unqualified C++ Type at $(D rest).
    See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangling-type
*/
string decodeCxxUnqualifiedType(ref string rest)
{
    return either(rest.decodeCxxBuiltinType(),
                  rest.decodeCxxSubstitution(),
                  rest.decodeCxxFunctionType());
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
    const cvQ = rest.decodeCxxCVQualifiers();
    switch (rest[0]) // TODO: Check for !rest.empty
    {
        case 'P': rest.popFront(); isPointer = true; break;
            // <ref-qualifier>: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.ref-qualifier
        case 'R': rest.popFront(); isRef = true; break;
        case 'O': rest.popFront(); isRVRef = true; break;
        case 'C': rest.popFront(); isComplexPair = true; break;
        case 'G': rest.popFront(); isImaginary = true; break;
        case 'U': rest.popFront();
            const sourceName = rest.decodeCxxSourceName() ~ rest.decodeCxxType();
            dln("Handle vendor extended type qualifier <source-name>", rest);
            break;
        default: break;
    }

    string type;

    // prefix qualifiers
    if (cvQ.isRestrict) { type ~= `restrict `; } // C99
    if (cvQ.isVolatile) { type ~= `volatile `; }
    if (cvQ.isConst)    { type ~= `const `; }

    type ~= either(rest.decodeCxxBuiltinType(),
                   rest.decodeCxxFunctionType(),
                   rest.decodeCxxClassEnumType(),
                   rest.decodeCxxArrayType(),
                   rest.decodeCxxPointerToMemberType(),
                   rest.decodeCxxTemplateTemplateParamAndArgs(),
                   rest.decodeCxxDecltype(),
                   rest.decodeCxxSubstitution());

    // suffix qualifiers
    if (isRef) { type ~= `&`; }
    if (isRVRef) { type ~= `&&`; }
    if (isPointer) { type = type ~ `*`; }

    return type;
}

/** See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.class-enum-type */
string decodeCxxClassEnumType(ref string rest)
{
    string type;
    string prefix;
    enum n = 2;
    if (rest.length >= n)
    {
        switch (rest[0..n])
        {
            case `Ts`: prefix = `struct `; break;
            case `Tu`: prefix = `union `; break;
            case `Te`: prefix = `enum `; break;
            default: break;
        }
        if (prefix)
        {
            rest.popFrontExactly(n);
        }
    }
    const name = rest.decodeCxxName();
    if (name)
    {
        type = prefix ~ name;
    }
    else
    {
        assert(!prefix); // if we faile to decode name prefix should not have existed either
    }
    return type;
}

string decodeCxxExpression(ref string rest)
{
    string exp;
    assert(false, "TODO");
}

/** See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.array-type */
string decodeCxxArrayType(ref string rest)
{
    string type;
    if (rest.skipOver('A'))
    {
        if (const num = rest.decodeCxxNumber())
        {
            assert(rest.skipOver('_'));
            type = rest.decodeCxxType() ~ `[]` ~ num ~ `[]`;
        }
        else
        {
            const dimensionExpression = rest.decodeCxxExpression();
            assert(rest.skipOver('_'));
            type = rest.decodeCxxType() ~ `[]` ~ dimensionExpression ~ `[]`;
        }
    }
    return type;
}

/** See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.pointer-to-member-type */
string decodeCxxPointerToMemberType(ref string rest)
{
    string type;
    if (rest.skipOver('M'))
    {
        type = (rest.decodeCxxType() ~ // <class type>
                rest.decodeCxxType() // <mmeber type>
            );
    }
    return type;
}

/** See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.template-param */
string decodeCxxTemplateParam(ref string rest)
{
    string param;
    if (rest.skipOver('T'))
    {
        if (rest.skipOver('_'))
        {
            param = `first template parameter`;
        }
        else
        {
            param = rest.decodeCxxNumber();
            assert(rest.skipOver('_'));
        }
    }
    return param;
}

string decodeCxxTemplateTemplateParamAndArgs(ref string rest)
{
    string value;
    if (const param = either(rest.decodeCxxTemplateParam(),
                             rest.decodeCxxSubstitution()))
    {
        auto args = rest.decodeCxxTemplateArgs();
        value = param ~ args.joiner(`, `).to!string;
    }
    return value;
}

/** See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.decltype */
string decodeCxxDecltype(ref string rest)
{
    string type;
    if (rest.skipOver(`Dt`) ||
        rest.skipOver(`DT`))
    {
        type = rest.decodeCxxExpression();
        assert(rest.skipOver('E'));
    }
    return type;
}

string decodeCxxDigit(ref string rest)
{
    auto digit = rest[0..1];
    rest.popFront();
    return digit;
}

/** Try to Decode C++ Operator at $(D rest).
    See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangling-operator
*/
string decodeCxxOperatorName(ref string rest)
{
    if (rest.skipOver('v'))     // vendor extended operator
    {
        return (rest.decodeCxxDigit() ~
                rest.decodeCxxSourceName());
    }

    string op;
    enum n = 2;
    const code = rest[0..n];
    switch (code)
    {
        case `nw`: op = `operator new`; break;
        case `na`: op = `operator new[]`; break;
        case `dl`: op = `operator delete`; break;
        case `da`: op = `operator delete[]`; break;
        case `ps`: op = `operator +`; break; // unary plus
        case `ng`: op = `operator -`; break; // unary minus

        case `ad`: op = `operator &`; break; // address of
        case `de`: op = `operator *`; break; // dereference

        case `co`: op = `operator ~`; break; // bitwise complement
        case `pl`: op = `operator +`; break; // plus
        case `mi`: op = `operator -`; break; // minus

        case `ml`: op = `operator *`; break; // multiplication
        case `dv`: op = `operator /`; break; // division
        case `rm`: op = `operator %`; break; // remainder

        case `an`: op = `operator &`; break; // bitwise and
        case `or`: op = `operator |`; break; // bitwise of

        case `eo`: op = `operator ^`; break;
        case `aS`: op = `operator =`; break;

        case `pL`: op = `operator +=`; break;
        case `mI`: op = `operator -=`; break;
        case `mL`: op = `operator *=`; break;
        case `dV`: op = `operator /=`; break;
        case `rM`: op = `operator %=`; break;

        case `aN`: op = `operator &=`; break;
        case `oR`: op = `operator |=`; break;
        case `eO`: op = `operator ^=`; break;

        case `ls`: op = `operator <<`; break;
        case `rs`: op = `operator >>`; break;
        case `lS`: op = `operator <<=`; break;
        case `rS`: op = `operator >>=`; break;

        case `eq`: op = `operator ==`; break;
        case `ne`: op = `operator !=`; break;
        case `lt`: op = `operator <`; break;
        case `gt`: op = `operator >`; break;
        case `le`: op = `operator <=`; break;
        case `ge`: op = `operator >=`; break;

        case `nt`: op = `operator !`; break;
        case `aa`: op = `operator &&`; break;
        case `oo`: op = `operator ||`; break;

        case `pp`: op = `operator ++`; break; // (postfix in <expression> context)
        case `mm`: op = `operator --`; break; // (postfix in <expression> context)

        case `cm`: op = `operator ,`; break;

        case `pm`: op = `operator ->*`; break;
        case `pt`: op = `operator ->`; break;

        case `cl`: op = `operator ()`; break;
        case `ix`: op = `operator []`; break;
        case `qu`: op = `operator ?`; break;
        case `cv`: op = `(cast)`; break;
        case `li`: op = `operator""`; break;
        default: break;
    }

    if (op)
    {
        rest.popFrontExactly(n); // digest it
    }

    switch (code)
    {
        case `cv`: op = "(" ~ rest.decodeCxxType() ~ ")"; break;
        case `li`: op = (`operator ""` ~ rest.decodeCxxSourceName()); break;
        default: break;
    }

    return op;
}

/** Try to Decode C++ Builtin Type at $(D rest).
    See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.builtin-type
*/
string decodeCxxBuiltinType(ref string rest)
{
    string type;
    enum n = 1;
    if (rest.length < n) { return type; }
    switch (rest[0])
    {
        case 'v': rest.popFront(); type = `void`; break;
        case 'w': rest.popFront(); type = `wchar_t`; break;

        case 'b': rest.popFront(); type = `bool`; break;

        case 'c': rest.popFront(); type = `char`; break;
        case 'a': rest.popFront(); type = `signed char`; break;
        case 'h': rest.popFront(); type = `unsigned char`; break;

        case 's': rest.popFront(); type = `short`; break;
        case 't': rest.popFront(); type = `unsigned short`; break;

        case 'i': rest.popFront(); type = `int`; break;
        case 'j': rest.popFront(); type = `unsigned int`; break;

        case 'l': rest.popFront(); type = `long`; break;
        case 'm': rest.popFront(); type = `unsigned long`; break;

        case 'x': rest.popFront(); type = `long long`; break;  // __int64
        case 'y': rest.popFront(); type = `unsigned long long`; break; // __int64

        case 'n': rest.popFront(); type = `__int128`; break;
        case 'o': rest.popFront(); type = `unsigned __int128`; break;

        case 'f': rest.popFront(); type = `float`; break;
        case 'd': rest.popFront(); type = `double`; break;
        case 'e': rest.popFront(); type = `long double`; break; // __float80
        case 'g': rest.popFront(); type = `__float128`; break;

        case 'z': rest.popFront(); type = `...`; break; // ellipsis

        case 'D':
            rest.popFront();
            assert(!rest.empty); // need one more
            switch (rest[0])
            {
                case 'd': rest.popFront(); type = `IEEE 754r decimal floating point (64 bits)`; break;
                case 'e': rest.popFront(); type = `IEEE 754r decimal floating point (128 bits)`; break;
                case 'f': rest.popFront(); type = `IEEE 754r decimal floating point (32 bits)`; break;
                case 'h': rest.popFront(); type = `IEEE 754r half-precision floating point (16 bits)`; break;
                case 'i': rest.popFront(); type = `char32_t`; break;
                case 's': rest.popFront(); type = `char16_t`; break;
                case 'a': rest.popFront(); type = `auto`; break;
                case 'c': rest.popFront(); type = `decltype(auto)`; break;
                case 'n': rest.popFront(); type = `std::nullptr_t`; break; // (i.e., decltype(nullptr))
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
        string type;
        rest.popFront();
        type ~= `::std::`;
        switch (rest[0])
        {
            case 't': rest.popFront(); type ~= `ostream`; break;
            case 'a': rest.popFront(); type ~= `allocator`; break;
            case 'b': rest.popFront(); type ~= `basic_string`; break;
            case 's':
                rest.popFront();
                type ~= `basic_string<char, std::char_traits<char>, std::allocator<char> >`;
                break;
            case 'i': rest.popFront(); type ~= `istream`; break;
            case 'o': rest.popFront(); type ~= `ostream`; break;
            case 'd': rest.popFront(); type ~= `iostream`; break;
            default:
                dln(`Cannot handle C++ standard prefix character: '`, rest[0], `'`);
                rest.popFront();
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
    auto restLookAhead = rest; // needed for lookahead parsing of CV-qualifiers
    const cvQ = restLookAhead.decodeCxxCVQualifiers();
    string type;
    if (restLookAhead.skipOver('F'))
    {
        rest = restLookAhead; // we have found it
        rest.skipOver('Y'); // optional
        type = rest.decodeCxxBareFunctionType().to!string;
        const refQ = rest.decodeCxxRefQualifier();
        type ~= refQ.to!string;

    }
    return type;
}

struct CxxBareFunctionType
{
    string retType;
    string[] paramTypes;
    string toString() @safe pure
    {
        return retType ~ `(` ~ paramTypes.joiner(`, `).to!string ~ `)`;
    }
}

/** See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.bare-function-type */
CxxBareFunctionType decodeCxxBareFunctionType(ref string rest)
{
    typeof(return) funType;
    funType.retType = rest.decodeCxxType();
    while (true)
    {
        auto type = rest.decodeCxxType();
        if (type)
        {
            funType.paramTypes ~= type;
        }
        else
        {
            break;
        }
    }
    return funType;
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
    typeof(return) cvQ;
    if (rest.skipOver('r')) { cvQ.isRestrict = true; }
    if (rest.skipOver('V')) { cvQ.isVolatile = true; }
    if (rest.skipOver('K')) { cvQ.isConst = true; }
    return cvQ;
}

enum CxxRefQualifier
{
    none,
    normalRef,
    rvalueRef
}

string toString(CxxRefQualifier refQ) @safe pure nothrow
{
    final switch (refQ)
    {
        case CxxRefQualifier.none: return "";
        case CxxRefQualifier.normalRef: return "&";
        case CxxRefQualifier.rvalueRef: return "&&";
    }
}

/** Decode <ref-qualifier>
    See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.ref-qualifier
*/
CxxRefQualifier decodeCxxRefQualifier(ref string rest)
{
    if (rest.skipOver('R'))
    {
        return CxxRefQualifier.normalRef;
    }
    else if (rest.skipOver('O'))
    {
        return CxxRefQualifier.rvalueRef;
    }
    else
    {
        return CxxRefQualifier.none;
    }
}

/** Decode Identifier <source-name>.
    See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.source-name
*/
string decodeCxxSourceName(ref string rest)
{
    string id;
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

/** See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.nested-name
   Note: Second alternative
   <template-prefix> <template-args>
   in
   <nested-name>
   is redundant as it is included in <prefix> and is skipped here.
 */
string decodeCxxNestedName(ref string rest)
{
    if (rest.skipOver('N')) // nested name: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.nested-name
    {
        const cvQ = rest.decodeCxxCVQualifiers();
        const refQ = rest.decodeCxxRefQualifier();
        auto ret = (rest.decodeCxxPrefix() ~
                    rest.decodeCxxUnqualifiedName() ~
                    cvQ.to!string ~
                    refQ.to!string ~
                    rest.skipLiteral('E'));
        return ret;
    }
    return null;
}

/** TODO: Use this
    See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.ctor-dtor-name
 */
enum CtorDtorName
{
    completeObjectConstructor,
    baseObjectConstructor,
    completeObjectAllocatingConstructor,
    deletingDestructor,
    completeObjectDestructor,
    baseObjectDestructor
}

/** See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.ctor-dtor-name */
string decodeCxxCtorDtorName(ref string rest)
{
    string name;
    enum n = 2;
    const code = rest[0..n];
    switch (code)
    {
        case `C1`: name = `complete object constructor`; break;
        case `C2`: name = `base object constructor`; break;
        case `C3`: name = `complete object allocating constructor`; break;
        case `D0`: name = `deleting destructor`; break;
        case `D1`: name = `complete object destructor`; break;
        case `D2`: name = `base object destructor`; break;
        default: break;
    }
    if (name)
    {
        rest.popFrontExactly(n);
    }
    return name;
}

/** https://mentorembedded.github.io/cxx-abi/abi.html#mangle.unqualified-name */
string decodeCxxUnqualifiedName(ref string rest)
{
    return either(rest.decodeCxxOperatorName(),
                  rest.decodeCxxSourceName(),
                  rest.decodeCxxCtorDtorName(),
                  rest.decodeCxxUnnamedTypeName());
}

/** See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.unnamed-type-name */
string decodeCxxUnnamedTypeName(ref string rest)
{
    string type;
    if (rest.skipOver(`Ut`))
    {
        type = rest.decodeCxxNumber();
        assert(rest.skipOver('_'));
    }
    return type;
}

/** See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.template-prefix
 */
string decodeCxxTemplatePrefix(ref string rest)
{
    // NOTE: Removed <prefix> because of recursion
    return either(rest.decodeCxxUnqualifiedName(),
                  rest.decodeCxxTemplateParam(),
                  rest.decodeCxxSubstitution());
}

/** See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.template-args */
string[] decodeCxxTemplateArgs(ref string rest)
{
    typeof(return) args;
    if (rest.skipOver('I'))
    {
        args ~= rest.decodeCxxTemplateArg();
        while (true)
        {
            auto arg = rest.decodeCxxTemplateArg();
            if (arg)
            {
                args ~= arg;
            }
            else
            {
                break;
            }
        }
        assert(rest.skipOver('E'));
    }
    else
    {
    }
    return args;
}

/** See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.mangled-name */
string decodeCxxMangledName(ref string rest)
{
    string name;
    if (rest.skipOver(`_Z`))
    {
        return rest.decodeCxxEncoding();
    }
    return name;
}

/** See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.expr-primary */
string decodeCxxExprPrimary(ref string rest)
{
    string expr;
    if (rest.skipOver('L'))
    {
        expr = rest.decodeCxxMangledName();
        if (!expr)
        {
            auto number = rest.decodeCxxNumber();
            // TODO: Howto demangle <float>?
            // TODO: Howto demangle <float> _ <float> E
            expr = rest.decodeCxxType(); // <string>, <nullptr>, <pointer> type
            bool pointerType = rest.skipOver('0'); // null pointer template argument
        }
        assert(rest.skipOver('E'));
    }
    return expr;
}

/** See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.template-arg */
string decodeCxxTemplateArg(ref string rest)
{
    string arg;
    if (rest.skipOver('X'))
    {
        arg = rest.decodeCxxExpression();
        assert(rest.skipOver('E'));
    }
    else if (rest.skipOver('J'))
    {
        string[] args;
        while (true)
        {
            const subArg = rest.decodeCxxTemplateArg();
            if (subArg)
            {
                args ~= subArg;
            }
            else
            {
                break;
            }
        }
        arg = args.joiner(`, `).to!string;
        assert(rest.skipOver('E'));
    }
    else
    {
        arg = either(rest.decodeCxxExprPrimary(),
                     rest.decodeCxxType());
    }
    return arg;
}

string decodeCxxTemplatePrefixAndArgs(ref string rest)
{
    auto restBackup = rest;
    if (const prefix = rest.decodeCxxTemplatePrefix())
    {
        auto args = rest.decodeCxxTemplateArgs();
        if (args)
        {
            return prefix ~ args.joiner(`, `).to!string;
        }
    }
    rest = restBackup; // restore upon failure
    return typeof(return).init;
}

/** See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.prefix */
string decodeCxxPrefix(ref string rest)
{
    typeof(return) prefix;
    while (!rest.empty) // NOTE: Turned self-recursion into iteration
    {
        if (const unqualifiedName = rest.decodeCxxUnqualifiedName())
        {
            prefix ~= unqualifiedName;
            continue;
        }
        else if (const unqualifiedName = rest.decodeCxxTemplatePrefixAndArgs())
        {
            continue;
        }
        else if (const templateParam = rest.decodeCxxTemplateParam())
        {
            continue;
        }
        else if (const decltype = rest.decodeCxxDecltype())
        {
            continue;
        }
        else if (const subst = rest.decodeCxxSubstitution())
        {
            continue;
        }
        else
        {
            break;
        }
    }
    return prefix;
}

/** See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.unscoped-name */
string decodeCxxUnscopedName(ref string rest)
{
    auto restBackup = rest;
    const prefix = rest.skipOver(`St`) ? "::std::" : null;
    if (const name = rest.decodeCxxUnqualifiedName())
    {
        return prefix ~ name;
    }
    else
    {
        rest = restBackup; // restore
        return typeof(return).init;
    }
}

/** See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.unscoped-template-name */
string decodeCxxUnscopedTemplateName(ref string rest)
{
    return either(rest.decodeCxxSubstitution(), // faster backtracking with substitution
                  rest.decodeCxxUnscopedName());
}

/** See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.unscoped-template-name */
string decodeCxxUnscopedTemplateNameAndArgs(ref string rest)
{
    auto restBackup = rest;
    if (const name = rest.decodeCxxUnscopedTemplateName())
    {
        if (auto args = rest.decodeCxxTemplateArgs())
        {
            return name ~ args.joiner(`, `).to!string;
        }
    }
    return typeof(return).init;
}

/** See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.number */
string decodeCxxNumber(ref string rest)
{
    string number;
    const prefix = rest.skipOver('n'); // optional prefix
    auto split = rest.splitBefore!(a => !a.isDigit());
    if (prefix || !split[0].empty) // if complete match
    {
        rest = split[1];
        number = split[0];
    }
    return number;
}

/** See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.discriminator */
int decodeCxxDescriminator(ref string rest)
{
    if (rest.skipOver('_'))
    {
        if (rest.skipOver('_'))            // number >= 10
        {
            const number = rest.decodeCxxNumber();
            assert(rest.skipOver('_')); // suffix
        }
        else                    // number < 10
        {
            rest.skipOver('n'); // optional prefix
            const number = cast(int)(rest[0] - '0'); // single digit
        }
    }
    return -1;
}

/** See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.local-name */
string decodeCxxLocalName(ref string rest)
{
    if (rest.skipOver('Z'))
    {
        auto hit = rest.decodeCxxEncoding();
        rest.skipOver('E');
        return (either(rest.skipLiteral('s'), // NOTE: Literal first here to speed up parsing
                       rest.decodeCxxName()) ~
                rest.decodeCxxDescriminator().to!string); // TODO: Optional
    }
    return null;
}

/** See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.name */
string decodeCxxName(ref string rest)
{
    return either(rest.decodeCxxNestedName(),
                  rest.decodeCxxUnscopedName(),
                  rest.decodeCxxUnscopedTemplateNameAndArgs(),
                  rest.decodeCxxLocalName());
}

string decodeCxxNVOffset(ref string rest)
{
    return rest.decodeCxxNumber();
}

string decodeCxxVOffset(ref string rest)
{
    auto offset = rest.decodeCxxNumber();
    assert(rest.skipOver('_'));
    return offset ~ rest.decodeCxxNumber();
}

/** See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.call-offset */
string decodeCxxCallOffset(ref string rest)
{
    typeof(return) offset;
    if (rest.skipOver('h'))
    {
        offset = rest.decodeCxxNVOffset();
        assert(rest.skipOver('_'));
    }
    else if (rest.skipOver('v'))
    {
        offset = rest.decodeCxxVOffset();
        assert(rest.skipOver('_'));
    }
    return offset;
}

/** See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.special-name */
string decodeCxxSpecialName(ref string rest)
{
    typeof(return) name;
    if (rest.skipOver('S'))
    {
        const type = rest.front();
        final switch (type)
        {
            case 'V': name = "virtual table: "; break;
            case 'T': name = "VTT structure: "; break;
            case 'I': name = "typeinfo structure: "; break;
            case 'S': name = "typeinfo name (null-terminated byte string): "; break;
        }
        rest.popFront(); // TODO: Can we integrate this into front()?
        name ~= rest.decodeCxxType();
    }
    else if (rest.skipOver(`GV`))
    {
        name = rest.decodeCxxName();
    }
    else if (rest.skipOver('T'))
    {
        if (rest.skipOver('c'))
        {
            name = rest.tryEvery(rest.decodeCxxCallOffset(),
                                 rest.decodeCxxCallOffset(),
                                 rest.decodeCxxEncoding()).joiner(` `).to!string;
        }
        else
        {
            name = rest.tryEvery(rest.decodeCxxCallOffset(),
                                 rest.decodeCxxEncoding()).joiner(` `).to!string;
        }
    }
    return name;
}

/* Decode C++ Symbol.
   See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.encoding
 */
string decodeCxxEncoding(ref string rest,
                         string separator = null) /* @safe pure nothrow @nogc */
{
    if (const name = rest.decodeCxxSpecialName())
    {
        return name;
    }
    else
    {
        return (rest.decodeCxxName() ~
                rest.decodeCxxBareFunctionType().to!string);
    }
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
    auto cxxHit = rest.findSplitAfter(`_Z`); // split into C++ prefix and rest
    if (!cxxHit[0].empty) // C++
    {
        return tuple(Lang.cxx,
                     cxxHit[1].decodeCxxEncoding(separator));
    }
    else
    {
        import core.demangle: demangle;
        const symAsD = rest.demangle;
        import std.conv: to;
        if (symAsD != rest) // TODO: Why doesn't (symAsD is rest) work here?
            return tuple(Lang.d, symAsD.to!string);
        else
            return tuple(Lang.init, rest);
    }
}

import backtrace.backtrace;

unittest
{
    import assert_ex;
    backtrace.backtrace.install(stderr);

    assertEqual(`_ZN9wikipedia7article8print_toERSo`.decodeSymbol(),
                tuple(Lang.cxx, `wikipedia::article::print_to(::std::ostream&)`));

    assertEqual(`_ZN9wikipedia7article8print_toEOSo`.decodeSymbol(),
                tuple(Lang.cxx, `wikipedia::article::print_to(::std::ostream&&)`));

    assertEqual(`_ZN9wikipedia7article6formatEv`.decodeSymbol(),
                tuple(Lang.cxx, `wikipedia::article::format(void)`));

    assertEqual(`_ZN9wikipedia7article6formatE`.decodeSymbol(),
                tuple(Lang.cxx, `wikipedia::article::format`));

    assertEqual(`_ZSt5state`.decodeSymbol(),
                tuple(Lang.cxx, `::std::state`));

    /* assertEqual(`_ZNSt3_In4wardE`.decodeSymbol(), */
    /*             tuple(Lang.cxx, `::std::_In::ward`)); */

    /* assertEqual(`_ZStL19piecewise_construct`.decodeSymbol(), */
    /*             tuple(Lang.cxx, `std::piecewise_construct`)); */
}
