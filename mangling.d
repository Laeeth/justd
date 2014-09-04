#!/usr/bin/env rdmd-dev

/** ELF Symbol Name (De)Mangling.
    Copyright: Per Nordlöw 2014-.
    License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
    Authors: $(WEB Per Nordlöw)
    See also: https://mentorembedded.github.io/cxx-abi/abi.html

    TODO: Only check for emptyness before any optionals.

    TODO: Search for pattern "X> <Y" and assure that they all use
    return rest.tryEvery(X, Y).

    TODO: 1. Replace calls to decode ~ decode with separate decodes
    TODO: 2 : Replace calls to decode ~ decode with a sequence call.

    TODO: Detect recursion:
          See: http://forum.dlang.org/thread/edaduxaxmihvzkoudeqa@forum.dlang.org#post-edaduxaxmihvzkoudeqa:40forum.dlang.org
          See: http://code.dlang.org/packages/backtrace-d

    TODO: What role does _ZL have? See localFlag for details.
 */
module mangling;

import std.range: empty, popFront, popFrontExactly, take, drop, front, takeOne, moveFront, repeat, replicate, isInputRange;
import std.algorithm: startsWith, findSplitAfter, skipOver, joiner;
import std.typecons: tuple, Tuple;
import std.conv: to;
import std.ascii: isDigit;
import std.array: array;
import std.stdio;
import std.functional : unaryFun, binaryFun;

import algorithm_ex: either, every, tryEvery, split, splitBefore, findPopBefore, findPopAfter;
import languages;

version = show;
version(show)
{
    import dbg;
}

/** Safe Variant of $(D skipOver).
    Merge this into Phobos. */
static if (__VERSION__ >= 2067)
{
    unittest
    {
        auto s = "";
        assert(!s.skipOver('a'));
        assert(!s.skipOver("a"));
    }
    alias skipOverSafe = skipOver;
}
else
{
    bool skipOverSafe(alias pred = "a == b", R, E)(ref R r, E e)
        @safe pure if (is(typeof(binaryFun!pred(r.front, e))))
    {
        return (!r.empty) && skipOver!pred(r, e);
    }
}

/** Like $(D skipOver) but return $(D string) instead of $(D bool).
    Bool-conversion of returned value gives same result as rest.skipOver(lit).
*/
string skipLiteral(R, E)(ref R rest, E lit) if (isInputRange!R)
{
    return rest.skipOverSafe(lit) ? "" : null;
}

/** Decode Unqualified C++ Type at $(D rest).
    See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangling-type
*/
R decodeCxxUnqualifiedType(R)(ref R rest) if (isInputRange!R)
{
    version(show) dln("rest: ", rest);
    return either(rest.decodeCxxBuiltinType(),
                  rest.decodeCxxSubstitution(),
                  rest.decodeCxxFunctionType());
}

/** Decode C++ Type at $(D rest).
    See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangling-type
*/
R decodeCxxType(R)(ref R rest) if (isInputRange!R)
{
    version(show) dln("rest: ", rest);

    typeof(return) type;

    const packExpansion = rest.skipOver(`Dp`); // (C++11)

    // <ref-qualifier>)
    bool isRef = false;      // & ref-qualifier
    bool isRVRef = false;    // && ref-qualifier (C++11)
    bool isComplexPair = false;    // complex pair (C 2000)
    bool isImaginary = false;    // imaginary (C 2000)
    int pointerCount = 0;

    /* TODO: Order of these may vary. */
    const cvQ = rest.decodeCxxCVQualifiers();

    if (rest.empty) { return type; }

    switch (rest[0])
    {
        case 'P': rest.popFront(); pointerCount++; break;
            // <ref-qualifier>: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.ref-qualifier
        case 'R': rest.popFront(); isRef = true; break;
        case 'O': rest.popFront(); isRVRef = true; break;
        case 'C': rest.popFront(); isComplexPair = true; break;
        case 'G': rest.popFront(); isImaginary = true; break;
        case 'U': rest.popFront();
            const sourceName = rest.decodeCxxSourceName();
            type = sourceName ~ rest.decodeCxxType();
            dln("Handle vendor extended type qualifier <source-name>", rest);
            break;
        default: break;
    }

    // prefix qualifiers
    type ~= cvQ.to!R;

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
    type ~= '*'.repeat(pointerCount).array; // type ~= "*".replicate(pointerCount);

    return type;
}

/** See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.class-enum-type */
R decodeCxxClassEnumType(R)(ref R rest) if (isInputRange!R)
{
    version(show) dln("rest: ", rest);
    R type;
    R prefix;
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
        assert(!prefix); // if we failed to decode name prefix should not have existed either
    }
    return type;
}

R decodeCxxExpression(R)(ref R rest) if (isInputRange!R)
{
    version(show) dln("rest: ", rest);
    R exp;
    assert(false, "TODO");
}

/** See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.array-type */
R decodeCxxArrayType(R)(ref R rest) if (isInputRange!R)
{
    version(show) dln("rest: ", rest);
    R type;
    if (rest.skipOverSafe('A'))
    {
        if (const num = rest.decodeCxxNumber())
        {
            assert(rest.skipOverSafe('_'));
            type = rest.decodeCxxType() ~ `[]` ~ num ~ `[]`;
        }
        else
        {
            const dimensionExpression = rest.decodeCxxExpression();
            assert(rest.skipOverSafe('_'));
            type = rest.decodeCxxType() ~ `[]` ~ dimensionExpression ~ `[]`;
        }
    }
    return type;
}

/** See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.pointer-to-member-type */
R decodeCxxPointerToMemberType(R)(ref R rest) if (isInputRange!R)
{
    version(show) dln("rest: ", rest);
    R type;
    if (rest.skipOverSafe('M'))
    {
        const classType = rest.decodeCxxType(); // <class type>
        const memberType = rest.decodeCxxType(); // <mmeber type>
        type = classType ~ memberType;
    }
    return type;
}

/** See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.template-param */
R decodeCxxTemplateParam(R)(ref R rest) if (isInputRange!R)
{
    version(show) dln("rest: ", rest);
    R param;
    if (rest.skipOverSafe('T'))
    {
        if (rest.skipOverSafe('_'))
        {
            param = `first template parameter`;
        }
        else
        {
            param = rest.decodeCxxNumber();
            assert(rest.skipOverSafe('_'));
        }
    }
    return param;
}

R decodeCxxTemplateTemplateParamAndArgs(R)(ref R rest) if (isInputRange!R)
{
    version(show) dln("rest: ", rest);
    R value;
    if (const param = either(rest.decodeCxxTemplateParam(),
                             rest.decodeCxxSubstitution()))
    {
        auto args = rest.decodeCxxTemplateArgs();
        value = param ~ args.joiner(`, `).to!R;
    }
    return value;
}

/** See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.decltype */
R decodeCxxDecltype(R)(ref R rest) if (isInputRange!R)
{
    version(show) dln("rest: ", rest);
    R type;
    if (rest.skipOver(`Dt`) ||
        rest.skipOver(`DT`))
    {
        type = rest.decodeCxxExpression();
        assert(rest.skipOverSafe('E'));
    }
    return type;
}

R decodeCxxDigit(R)(ref R rest) if (isInputRange!R)
{
    version(show) dln("rest: ", rest);
    auto digit = rest[0..1];
    rest.popFront();
    return digit;
}

/** Try to Decode C++ Operator at $(D rest).
    See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangling-operator
*/
R decodeCxxOperatorName(R)(ref R rest) if (isInputRange!R)
{
    version(show) dln("rest: ", rest);

    if (rest.skipOverSafe('v'))     // vendor extended operator
    {
        const digit = rest.decodeCxxDigit();
        const sourceName = rest.decodeCxxSourceName();
        return digit ~ sourceName;
    }

    R op;
    enum n = 2;
    if (rest.length < n) { return typeof(return).init; }
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
        case `cv`: op = '(' ~ rest.decodeCxxType() ~ ')'; break;
        case `li`: op = (`operator ""` ~ rest.decodeCxxSourceName()); break;
        default: break;
    }

    return op;
}

/** Try to Decode C++ Builtin Type at $(D rest).
    See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.builtin-type
*/
R decodeCxxBuiltinType(R)(ref R rest) if (isInputRange!R)
{
    version(show) dln("rest: ", rest);
    R type;
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
R decodeCxxSubstitution(R)(ref R rest, R stdPrefix = `::std::`) if (isInputRange!R)
{
    version(show) dln("rest: ", rest);
    R type;
    if (rest.skipOverSafe('S'))
    {
        if (rest.front == '_') // See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.seq-id
        {
            type = "${PREVIOUS}";
            rest.popFront();
        }
        else if ('0' <= rest.front && rest.front <= '9' ||
                 'A' <= rest.front && rest.front <= 'Z') // See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.seq-id
        {
            type = "${PREVIOUS}" ~ rest.front.to!R;
            rest.popFront();
            assert(rest.skipOverSafe('_'));
        }
        else
        {
            type = stdPrefix;
            switch (rest.front)
            {
                case 't': rest.popFront(); type ~= `ostream`; break;
                case 'a': rest.popFront(); type ~= `allocator`; break;
                case 'b': rest.popFront(); type ~= `basic_string`; break;
                case 's': rest.popFront();
                    type ~= `basic_string<char, std::char_traits<char>, std::allocator<char> >`;
                    break;
                case 'i': rest.popFront(); type ~= `istream`; break;
                case 'o': rest.popFront(); type ~= `ostream`; break;
                case 'd': rest.popFront(); type ~= `iostream`; break;

                default:
                    dln(`Cannot handle C++ standard prefix character: '`, rest.front, `'`);
                    rest.popFront();
                    break;
            }
        }
    }
    return type;
}

/** Try to Decode C++ Function Type at $(D rest).
    See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.function-type
*/
R decodeCxxFunctionType(R)(ref R rest) if (isInputRange!R)
{
    version(show) dln("rest: ", rest);
    auto restLookAhead = rest; // needed for lookahead parsing of CV-qualifiers
    const cvQ = restLookAhead.decodeCxxCVQualifiers();
    R type;
    if (restLookAhead.skipOverSafe('F'))
    {
        rest = restLookAhead; // we have found it
        rest.skipOverSafe('Y'); // optional
        type = rest.decodeCxxBareFunctionType().to!R;
        const refQ = rest.decodeCxxRefQualifier();
        type ~= refQ.toCxxString;

    }
    return type;
}

struct CxxBareFunctionType(R) if (isInputRange!R)
{
    R[] types; // optional return and parameter types
    R toString() @safe pure
    {
        R value;
        if (!types.empty)
        {
            value = `(` ~ types.joiner(`, `).to!R ~ `)`;
        }
        return value;
    }
}

/** See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.bare-function-type */
CxxBareFunctionType!R decodeCxxBareFunctionType(R)(ref R rest) if (isInputRange!R)
{
    version(show) dln("rest: ", rest);
    typeof(return) bareFunctionType;

    /* TODO: This behaviour may not follow grammar. */
    if (const firstType = rest.decodeCxxType())
    {
        bareFunctionType.types ~= firstType;
    }

    while (!rest.empty)
    {
        auto type = rest.decodeCxxType();
        if (type)
        {
            bareFunctionType.types ~= type;
        }
        else
        {
            break;
        }
    }

    return bareFunctionType;
}

struct CXXCVQualifiers(R) if (isInputRange!R)
{
    bool isRestrict; // (C99)
    bool isVolatile; // volatile
    bool isConst; // const

    auto opCast(T : bool)()
    {
        return (isRestrict ||
                isVolatile ||
                isConst);
    }

    R toString() @safe pure nothrow const
    {
        R value;
        if (isRestrict) value ~= `restrict `;
        if (isVolatile) value ~= `volatile `;
        if (isConst)    value ~= `const `;
        return value;
    }
}

/** Decode <CV-qualifiers>
    See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.CV-qualifiers
*/
CXXCVQualifiers!R decodeCxxCVQualifiers(R)(ref R rest) if (isInputRange!R)
{
    version(show) dln("rest: ", rest);
    typeof(return) cvQ;
    if (rest.skipOverSafe('r')) { cvQ.isRestrict = true; }
    if (rest.skipOverSafe('V')) { cvQ.isVolatile = true; }
    if (rest.skipOverSafe('K')) { cvQ.isConst    = true; }
    return cvQ;
}

enum CxxRefQualifier
{
    none,
    normalRef,
    rvalueRef
}

/* See also: http://forum.dlang.org/thread/cvhapzsrhjdnpkdspavg@forum.dlang.org#post-cvhapzsrhjdnpkdspavg:40forum.dlang.org */
string toCxxString(CxxRefQualifier refQ) @safe pure nothrow
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
CxxRefQualifier decodeCxxRefQualifier(R)(ref R rest) if (isInputRange!R)
{
    version(show) dln("rest: ", rest);
    if (rest.skipOverSafe('R'))
    {
        return CxxRefQualifier.normalRef;
    }
    else if (rest.skipOverSafe('O'))
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
R decodeCxxSourceName(R)(ref R rest) if (isInputRange!R)
{
    version(show) dln("rest: ", rest);
    R id;
    const sign = rest.skipOverSafe('n'); // if negative number
    assert(!sign);
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
R decodeCxxNestedName(R)(ref R rest) if (isInputRange!R)
{
    version(show) dln("rest: ", rest);
    if (rest.skipOverSafe('N')) // nested name: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.nested-name
    {
        const cvQ = rest.decodeCxxCVQualifiers();
        const refQ = rest.decodeCxxRefQualifier();
        const prefix = rest.decodeCxxPrefix();
        const name = rest.decodeCxxUnqualifiedName();
        assert(rest.skipOverSafe('E'));
        auto ret = (cvQ.to!R ~
                    prefix ~
                    name ~
                    refQ.toCxxString);
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
R decodeCxxCtorDtorName(R)(ref R rest) if (isInputRange!R)
{
    version(show) dln("rest: ", rest);
    R name;
    enum n = 2;
    if (rest.length < n) { return typeof(return).init; }
    switch (rest[0..n])
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
R decodeCxxUnqualifiedName(R)(ref R rest) if (isInputRange!R)
{
    version(show) dln("rest: ", rest);
    return either(rest.decodeCxxOperatorName(),
                  rest.decodeCxxSourceName(),
                  rest.decodeCxxCtorDtorName(),
                  rest.decodeCxxUnnamedTypeName());
}

/** See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.unnamed-type-name */
R decodeCxxUnnamedTypeName(R)(ref R rest) if (isInputRange!R)
{
    version(show) dln("rest: ", rest);
    R type;
    if (rest.skipOver(`Ut`))
    {
        type = rest.decodeCxxNumber();
        assert(rest.skipOverSafe('_'));
    }
    return type;
}

/** See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.template-prefix
 */
R decodeCxxTemplatePrefix(R)(ref R rest) if (isInputRange!R)
{
    version(show) dln("rest: ", rest);
    // NOTE: Removed <prefix> because of recursion
    return either(rest.decodeCxxUnqualifiedName(),
                  rest.decodeCxxTemplateParam(),
                  rest.decodeCxxSubstitution());
}

/** See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.template-args */
R[] decodeCxxTemplateArgs(R)(ref R rest) if (isInputRange!R)
{
    version(show) dln("rest: ", rest);
    typeof(return) args;
    if (rest.skipOverSafe('I'))
    {
        args ~= rest.decodeCxxTemplateArg();
        while (!rest.empty)
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
        assert(rest.skipOverSafe('E'));
    }
    return args;
}

/** See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.mangled-name */
R decodeCxxMangledName(R)(ref R rest) if (isInputRange!R)
{
    version(show) dln("rest: ", rest);
    R name;
    if (rest.skipOver(`_Z`))
    {
        return rest.decodeCxxEncoding();
    }
    return name;
}

/** See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.expr-primary */
R decodeCxxExprPrimary(R)(ref R rest) if (isInputRange!R)
{
    version(show) dln("rest: ", rest);
    R expr;
    if (rest.skipOverSafe('L'))
    {
        expr = rest.decodeCxxMangledName();
        if (!expr)
        {
            auto number = rest.decodeCxxNumber();
            // TODO: Howto demangle <float>?
            // TODO: Howto demangle <float> _ <float> E
            expr = rest.decodeCxxType(); // <R>, <nullptr>, <pointer> type
            bool pointerType = rest.skipOverSafe('0'); // null pointer template argument
        }
        assert(rest.skipOverSafe('E'));
    }
    return expr;
}

/** See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.template-arg */
R decodeCxxTemplateArg(R)(ref R rest) if (isInputRange!R)
{
    version(show) dln("rest: ", rest);
    R arg;
    if (rest.skipOverSafe('X'))
    {
        arg = rest.decodeCxxExpression();
        assert(rest.skipOverSafe('E'));
    }
    else if (rest.skipOverSafe('J'))
    {
        R[] args;
        while (!rest.empty)
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
        arg = args.joiner(`, `).to!R;
        assert(rest.skipOverSafe('E'));
    }
    else
    {
        arg = either(rest.decodeCxxExprPrimary(),
                     rest.decodeCxxType());
    }
    return arg;
}

R decodeCxxTemplatePrefixAndArgs(R)(ref R rest) if (isInputRange!R)
{
    version(show) dln("rest: ", rest);
    auto restBackup = rest;
    if (const prefix = rest.decodeCxxTemplatePrefix())
    {
        auto args = rest.decodeCxxTemplateArgs();
        if (args)
        {
            return prefix ~ args.joiner(`, `).to!R;
        }
    }
    rest = restBackup; // restore upon failure
    return typeof(return).init;
}

/** See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.prefix */
R decodeCxxPrefix(R)(ref R rest, R scopeSeparator = "::") if (isInputRange!R)
{
    version(show) dln("rest: ", rest);
    typeof(return) prefix;
    for (size_t i = 0; !rest.empty; ++i) // NOTE: Turned self-recursion into iteration
    {
        if (const name = rest.decodeCxxUnqualifiedName())
        {
            if (i >= 1)
            {
                prefix ~= scopeSeparator;
            }
            prefix ~= name;
            continue;
        }
        else if (const name = rest.decodeCxxTemplatePrefixAndArgs())
        {
            prefix ~= name;
            continue;
        }
        else if (const templateParam = rest.decodeCxxTemplateParam())
        {
            prefix ~= templateParam;
            continue;
        }
        else if (const decltype = rest.decodeCxxDecltype())
        {
            prefix ~= decltype;
            continue;
        }
        else if (const subst = rest.decodeCxxSubstitution())
        {
            prefix ~= subst;
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
R decodeCxxUnscopedName(R)(ref R rest) if (isInputRange!R)
{
    version(show) dln("rest: ", rest);
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
R decodeCxxUnscopedTemplateName(R)(ref R rest) if (isInputRange!R)
{
    version(show) dln("rest: ", rest);
    return either(rest.decodeCxxSubstitution(), // faster backtracking with substitution
                  rest.decodeCxxUnscopedName());
}

/** See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.unscoped-template-name */
R decodeCxxUnscopedTemplateNameAndArgs(R)(ref R rest) if (isInputRange!R)
{
    version(show) dln("rest: ", rest);
    R nameAndArgs;
    if (const name = rest.decodeCxxUnscopedTemplateName())
    {
        nameAndArgs = name;
        if (auto args = rest.decodeCxxTemplateArgs())
        {
            nameAndArgs ~= args.joiner(`, `).to!R;
        }
    }
    return nameAndArgs;
}

/** See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.number */
R decodeCxxNumber(R)(ref R rest) if (isInputRange!R)
{
    version(show) dln("rest: ", rest);
    R number;
    const prefix = rest.skipOverSafe('n'); // optional prefix
    auto split = rest.splitBefore!(a => !a.isDigit());
    if (prefix || !split[0].empty) // if complete match
    {
        rest = split[1];
        number = split[0];
    }
    return number;
}

/** See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.discriminator */
R decodeCxxDescriminator(R)(ref R rest) if (isInputRange!R)
{
    version(show) dln("rest: ", rest);
    R descriminator;
    if (rest.skipOverSafe('_'))
    {
        if (rest.skipOverSafe('_'))            // number >= 10
        {
            descriminator = rest.decodeCxxNumber();
            assert(rest.skipOverSafe('_')); // suffix
        }
        else                    // number < 10
        {
            rest.skipOverSafe('n'); // optional prefix
            /* TODO: Merge these two into a variant of popFront() that returns
             the popped element. What is best out of:
             - General: rest.takeOne().to!R
             - Arrays only: rest[0..1]
             - Needs cast: rest.front
             and are we in need of a combined variant of front() and popFront()
             say takeFront() that may fail and requires a cast.
             */
            /* descriminator = rest[0..1]; // single digit */
            /* rest.popFront(); */
            descriminator = rest.moveFront.to!R;
        }
    }
    return descriminator;
}

/** See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.local-name */
R decodeCxxLocalName(R)(ref R rest) if (isInputRange!R)
{
    version(show) dln("rest: ", rest);
    if (rest.skipOverSafe('Z'))
    {
        const encoding = rest.decodeCxxEncoding();
        rest.skipOverSafe('E');
        const entityNameMaybe = either(rest.skipLiteral('s'), // NOTE: Literal first to speed up
                                       rest.decodeCxxName());
        const discriminator = rest.decodeCxxDescriminator(); // optional
        return (encoding ~
                entityNameMaybe ~
                discriminator.to!R); // TODO: Optional
    }
    return R.init;
}

/** See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.name */
R decodeCxxName(R)(ref R rest) if (isInputRange!R)
{
    version(show) dln("rest: ", rest);
    return either(rest.decodeCxxNestedName(),
                  rest.decodeCxxUnscopedName(),
                  rest.decodeCxxLocalName(), // TODO: order flipped
                  rest.decodeCxxUnscopedTemplateNameAndArgs()); // NOTE: order flipped
}

R decodeCxxNVOffset(R)(ref R rest) if (isInputRange!R)
{
    version(show) dln("rest: ", rest);
    return rest.decodeCxxNumber();
}

R decodeCxxVOffset(R)(ref R rest) if (isInputRange!R)
{
    version(show) dln("rest: ", rest);
    auto offset = rest.decodeCxxNumber();
    assert(rest.skipOverSafe('_'));
    return offset ~ rest.decodeCxxNumber();
}

/** See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.call-offset */
R decodeCxxCallOffset(R)(ref R rest) if (isInputRange!R)
{
    version(show) dln("rest: ", rest);
    typeof(return) offset;
    if (rest.skipOverSafe('h'))
    {
        offset = rest.decodeCxxNVOffset();
        assert(rest.skipOverSafe('_'));
    }
    else if (rest.skipOverSafe('v'))
    {
        offset = rest.decodeCxxVOffset();
        assert(rest.skipOverSafe('_'));
    }
    return offset;
}

/** See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.special-name */
R decodeCxxSpecialName(R)(ref R rest) if (isInputRange!R)
{
    version(show) dln("rest: ", rest);
    auto restBackup = rest;
    typeof(return) name;
    if (rest.skipOverSafe('S'))
    {
        switch (rest.moveFront)
        {
            case 'V': name = "virtual table: "; break;
            case 'T': name = "VTT structure: "; break;
            case 'I': name = "typeinfo structure: "; break;
            case 'S': name = "typeinfo name (null-terminated byte R): "; break;
            default:
                rest = restBackup; // restore
                return name;
        }
        name ~= rest.decodeCxxType();
    }
    else if (rest.skipOver(`GV`))
    {
        name = rest.decodeCxxName();
    }
    else if (rest.skipOverSafe('T'))
    {
        if (rest.skipOverSafe('c'))
        {
            name = rest.tryEvery(rest.decodeCxxCallOffset(),
                                 rest.decodeCxxCallOffset(),
                                 rest.decodeCxxEncoding()).joiner(` `).to!R;
        }
        else
        {
            name = rest.tryEvery(rest.decodeCxxCallOffset(),
                                 rest.decodeCxxEncoding()).joiner(` `).to!R;
        }
    }
    return name;
}

/* Decode C++ Symbol.
   See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.encoding
 */
R decodeCxxEncoding(R)(ref R rest,
                       R scopeSeparator = null) /* @safe pure nothrow @nogc */ if (isInputRange!R)
{
    version(show) dln("rest: ", rest);
    const localFlag = rest.skipOverSafe('L'); // TODO: What role does the L have in symbols starting with _ZL have?
    if (const name = rest.decodeCxxSpecialName())
    {
        return name;
    }
    else
    {
        const name = rest.decodeCxxName();
        auto type = rest.decodeCxxBareFunctionType();
        return name ~ type.to!R;
    }
}

/** Demangle Symbol $(D rest) and Detect Language.
    See also: https://en.wikipedia.org/wiki/Name_mangling
    See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangling
    See also: https://gcc.gnu.org/onlinedocs/libstdc++/manual/ext_demangling.html
*/
Tuple!(Lang, R) decodeSymbol(R)(R rest,
                                     R scopeSeparator = null) /* @safe pure nothrow @nogc */ if (isInputRange!R)
{
    version(show) dln("rest: ", rest);
    if (rest.empty)
    {
        return tuple(Lang.init, rest);
    }

    if (!rest.startsWith(`_`))
    {
        return tuple(Lang.c, rest); // assume C
    }

    // See also: https://mentorembedded.github.io/cxx-abi/abi.html#mangle.mangled-name
    if (rest.skipOver(`_Z`))
    {
        return tuple(Lang.cxx,
                     rest.decodeCxxEncoding());
    }
    else
    {
        import core.demangle: demangle;
        const symAsD = rest.demangle;
        import std.conv: to;
        if (symAsD != rest) // TODO: Why doesn't (symAsD is rest) work here?
            return tuple(Lang.d, symAsD.to!R);
        else
            return tuple(Lang.init, rest);
    }
}

import backtrace.backtrace;

unittest
{
    import assert_ex;
    backtrace.backtrace.install(stderr);

    assertEqual(`_Z1hi`.decodeSymbol(),
                tuple(Lang.cxx, `h(int)`));

    assertEqual(`_ZN9wikipedia7article6formatE`.decodeSymbol(),
                tuple(Lang.cxx, `wikipedia::article::format`));

    assertEqual(`_ZSt5state`.decodeSymbol(),
                tuple(Lang.cxx, `::std::state`));

    assertEqual(`_ZN9wikipedia7article8print_toERSo`.decodeSymbol(),
                tuple(Lang.cxx, `wikipedia::article::print_to(::std::ostream&)`));

    assertEqual(`_ZN9wikipedia7article8print_toEOSo`.decodeSymbol(),
                tuple(Lang.cxx, `wikipedia::article::print_to(::std::ostream&&)`));

    assertEqual(`_ZN9wikipedia7article6formatEv`.decodeSymbol(),
                tuple(Lang.cxx, `wikipedia::article::format(void)`));

    /* assertEqual(`_ZL10parse_archmPPKcS0_`.decodeSymbol(), */
    /*             tuple(Lang.cxx, `parse_arch(unsigned long, char const**, char const*)`)); */
}
