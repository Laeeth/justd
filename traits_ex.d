#!/usr/bin/env rdmd-dev-module

/** Various extensions to std.traits.
    Copyright: Per Nordlöw 2014-.
    License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
    Authors: $(WEB Per Nordlöw)
    See also: http://forum.dlang.org/thread/jbyixfbuefvdlttnyclu@forum.dlang.org#post-mailman.2199.1353742037.5162.digitalmars-d-learn:40puremagic.com
*/
module traits_ex;
import std.traits: isArray, isAssignable, ParameterTypeTuple, isStaticArray, isDynamicArray, isSomeString;
import std.range: ElementType, isForwardRange, isRandomAccessRange, isInputRange, isBidirectionalRange, isOutputRange, isIterable;

/** Returns: true iff $(D ptr) is handled by the garbage collector (GC). */
bool isGCPointer(void* ptr){
    import core.memory;
    return !!GC.addrOf(ptr);
}
alias inGC = isGCPointer;
alias isGCed = isGCPointer;

/** Returns: true iff all types $(D T) are the same. */
template allSame(T...)
{
    static if (T.length <= 1)
    {
        enum bool allSame = true;
    }
    else
    {
        enum bool allSame = is(T[0] == T[1]) && allSame!(T[1..$]);
    }
}

enum isIterableOf(R, E) = isIterable!R && is(ElementType!R == E);

unittest
{
    alias E = string;
    alias I = int;
    alias R = typeof(["a", "b"]);
    static assert(isIterableOf!(R, E));
    static assert(!isIterableOf!(R, I));
}

enum isRandomAccessRangeOf(R, E) = isRandomAccessRange!R && is(ElementType!R == E);
enum isForwardRangeOf(R, E) = isForwardRange!R && is(ElementType!R == E);
enum isInputRangeOf(R, E) = isInputRange!R && is(ElementType!R == E);
enum isBidirectionalRangeOf(R, E) = isBidirectionalRange!R && is(ElementType!R == E);
enum isOutputRangeOf(R, E) = isOutputRange!R && is(ElementType!R == E);
enum isArrayOf(R, E) = isArray!R && is(ElementType!R == E);
unittest
{
    alias R = typeof(["a", "b"]);
    static assert(isArrayOf!(R, string));
}

alias isSource = isForwardRange;
alias isSourceOf = isForwardRangeOf;
alias isSource = isOutputRange;
alias isSinkOf = isOutputRangeOf;
enum isSourceOfSomeString(R) = (isSource!R && isSomeString!(ElementType!R));

import std.functional: unaryFun, binaryFun;

/* TODO Do we need use of unaryFun and binaryFun here? */
alias isEven = unaryFun!(a => (a & 1) == 0); // Limit to Integers?
alias isOdd = unaryFun!(a => (a & 1) == 1); // Limit to Integers?
alias lessThan = binaryFun!((a, b) => a < b);
alias greaterThan = binaryFun!((a, b) => a > b);

enum isValueType(T) = !hasIndirections!T;

enum isString (T) = is(T == string);
enum isWString(T) = is(T == wstring);
enum isDString(T) = is(T == dstring);

enum isEnum(T) = is(T == enum);
unittest {
    interface I {}
    class A {}
    class B( T ) {}
    class C : B!int, I {}
    struct S {}
    enum E { X }
    static assert(!isEnum!A );
    static assert(!isEnum!( B!int ) );
    static assert(!isEnum!C );
    static assert(!isEnum!I );
    static assert(isEnum!E );
    static assert(!isEnum!int );
    static assert(!isEnum!( int* ) );
}

/* See also: http://d.puremagic.com/issues/show_bug.cgi?id=4427 */
enum isStruct(T) = is(T == struct);
unittest {
    interface I {}
    class A {}
    class B( T ) {}
    class C : B!int, I {}
    struct S {}
    static assert(!isStruct!A );
    static assert(!isStruct!( B!int ) );
    static assert(!isStruct!C );
    static assert(!isStruct!I );
    static assert(isStruct!S );
    static assert(!isStruct!int );
    static assert(!isStruct!( int* ) );
}

enum isClass(T) = is(T == class);
unittest {
    interface I {}
    class A {}
    class B( T ) {}
    class C : B!int, I {}
    struct S {}
    static assert(isClass!A );
    static assert(isClass!( B!int ) );
    static assert(isClass!C );
    static assert(!isClass!I );
    static assert(!isClass!S );
    static assert(!isClass!int );
    static assert(!isClass!( int* ) );
}

enum isInterface(T) = is(T == interface);
unittest {
    interface I {}
    class A {}
    class B( T ) {}
    class C : B!int, I {}
    struct S {}
    static assert(!isInterface!A );
    static assert(!isInterface!( B!int ) );
    static assert(!isInterface!C );
    static assert(isInterface!I );
    static assert(!isInterface!S );
    static assert(!isInterface!int );
    static assert(!isInterface!( int* ) );
}

template isType(T)       { enum isType = true; }
template isType(alias T) { enum isType = false; }

unittest {
    struct S { alias int foo; }
    static assert(isType!int );
    static assert(isType!float );
    static assert(isType!string );
    //static assert(isType!S ); // Bugzilla 4431
    static assert(isType!( S.foo ) );
    static assert(!isType!4 );
    static assert(!isType!"Hello world!" );
}

/** Note that NotNull!T is not isNullable :) */
alias isNullable(T) = isAssignable!(T, typeof(null));

template nameOf(alias a) { enum string nameOf = a.stringof; }
unittest {
    int var;
    assert(nameOf!var == var.stringof);
}

template Chainable()
{
    import std.range: chain;
    auto ref opCast(Range)(Range r)
    {
        return chain(this, r);
    }
}
unittest {
    mixin Chainable;
}

/** Check if Type $(D A) is an Instance of Template $(D B).
    See also: http://forum.dlang.org/thread/mailman.2901.1316118301.14074.digitalmars-d-learn@puremagic.com#post-zzdpfhsgfdgpszdbgbbt:40forum.dlang.org
    Deprecated by: http://dlang.org/phobos/std_traits.html#isInstanceOf
*/
enum IsA(alias B, A) = is(A == B!T, T);

/** See also: http://forum.dlang.org/thread/bug-6384-3@http.d.puremagic.com/issues/
    See also: http://forum.dlang.org/thread/jrqiiicmtpenzokfxvlz@forum.dlang.org */
enum isOpBinary(T, string op, U) = is(typeof(mixin("T.init" ~ op ~ "U.init")));

enum isComparable(T) = is(typeof({ return T.init <  T.init; }));
enum isEquable   (T) = is(typeof({ return T.init == T.init; }));
enum isNotEquable(T) = is(typeof({ return T.init != T.init; }));

version (unittest) {
    static assert(isComparable!int);
    static assert(isComparable!string);
    static assert(!isComparable!creal);
    static struct Foo {}
    static assert(!isComparable!Foo);
    static struct Bar { bool opCmp(Bar) { return true; } }
    static assert(isComparable!Bar);
}

enum areComparable(T, U) = is(typeof({ return T.init <  U.init; }));
enum areEquable   (T, U) = is(typeof({ return T.init == U.init; }));
enum areNotEquable(T, U) = is(typeof({ return T.init != U.init; }));

enum isValueType(T) = isStaticArray!T || isStruct!T;
/* See also: http://forum.dlang.org/thread/hsfkgcmkjgvrfuyjoujj@forum.dlang.org#post-hsfkgcmkjgvrfuyjoujj:40forum.dlang.org */
enum isReferenceType(T) = isDynamicArray!T || isSomeString!T;

enum hasValueSemantics(T) = !hasIndirections!T;

enum arityMin0(alias fun) = __traits(compiles, fun());

/** TODO Unite into a variadic.
    See also: http://forum.dlang.org/thread/bfjwbhkyehcloqcjzxck@forum.dlang.org#post-atjmewbffdzeixrviyoa:40forum.dlang.org
*/
enum isCallableWith(alias fun, T) = (is(typeof(fun(T.init))) ||
                                     is(typeof(T.init.fun))); // TODO Are both these needed?
unittest {
    auto sqr(T)(T x) { return x*x; }
    assert(isCallableWith!(sqr, int));
    assert(!isCallableWith!(sqr, string));
}

/* TODO Unite into a variadic.
   See also: http://forum.dlang.org/thread/bfjwbhkyehcloqcjzxck@forum.dlang.org#post-atjmewbffdzeixrviyoa:40forum.dlang.org
 */
enum isCallableWith(alias fun, T, U) = (is(typeof(fun(T.init,
                                                      U.init))) ||
                                        is(typeof(T.init.fun(U)))); // TODO Are both these needed?
unittest {
    auto sqr2(T)(T x, T y) { return x*x + y*y; }
    assert(isCallableWith!(sqr2, int, int));
    assert(!isCallableWith!(sqr2, int, string));
}

import std.traits: isInstanceOf;
import std.range: SortedRange;

/** Check if $(D T) is a Sorted Range.
    See also: http://forum.dlang.org/thread/lt1g3q$15fe$1@digitalmars.com
*/
alias isSortedRange(T) = isInstanceOf!(SortedRange, T); // TODO Or use: __traits(isSame, TemplateOf!R, SortedRange)

/** Check if Function $(D expr) is callable at compile-time.
    See also: http://forum.dlang.org/thread/owlwzvidwwpsrelpkbok@forum.dlang.org
*/
template isCTFEable(alias fun)
{
    template isCTFEable_aux(alias T)
    {
        enum isCTFEable_aux = T;
    }
    enum isCTFEable = __traits(compiles, isCTFEable_aux!(fun()));
}

template isCTFEable2(fun...)
{
    enum isCTFEable2 = true;
}

unittest {
    int fun1() { return 1; }
    auto fun1_N()
    {
        import std.array;
//would return Error: gc_malloc cannot be interpreted at compile time,
        /* because it has no available source code due to a bug */
            return [1].array;
    }
    int fun2(int x)
    {
        return 1;
    }
    auto fun2_N(int x){
        import std.array;
//same as fun1_N
        return [1].array;
    }

    int a1;
    enum a2=0;

    static assert(!isCTFEable!(()=>a1));
    static assert(isCTFEable!(()=>a2));

    static assert(isCTFEable!fun1);
    /* static assert(!isCTFEable!fun1_N); */

    static assert(isCTFEable!(()=>fun2(0)));
    /* static assert(!isCTFEable!(()=>fun2_N(0))); */
//NOTE:an alternate syntax which could be implemented would be: static
    /* assert(!isCTFEable!(fun2_N,0)); */
}

/** Check if the value of $(D expr) is known at compile-time.
    See also: http://forum.dlang.org/thread/owlwzvidwwpsrelpkbok@forum.dlang.org
*/
enum isCTEable(alias expr) = __traits(compiles, { enum id = expr; });

unittest {
    static assert(isCTEable!11);
    enum x = 11;
    static assert(isCTEable!x);
    auto y = 11;
    static assert(!isCTEable!y);
}

import std.traits: functionAttributes, FunctionAttribute, isCallable, ParameterTypeTuple;

/** Check if $(D fun) is a pure function. */
enum bool isPure(alias fun) = (isCallable!fun &&
                               (functionAttributes!fun &
                                FunctionAttribute.pure_));

/** Check if $(D fun) is a function purely callable with arguments T. */
enum bool isPurelyCallableWith(alias fun, T...) = (isPure!fun &&
                                                   is(T == ParameterTypeTuple!fun));

unittest {
    int foo(int x) @safe pure nothrow { return x; }
    static assert(isPure!foo);
    static assert(isPurelyCallableWith!(foo, int));
}

/** Persistently Call Function $(D fun) with arguments $(D args).

    Hash Id Build-Timestamp (Code-Id because we currently have stable way of hashing-algorithms) is Constructed from Data Structure:
    - Hierarchically Mangled Unqual!typeof(instance)
    - Use msgpack in combination with sha1Of or only sha1Of (with extended
    overloads for sha1Of) if available.

    Extend std.functional : memoize to accept pure functions that takes an
    immutable mmap as input. Create wrapper that converts file to immutable mmap
    and performs memoization on the pure function.

*/
auto persistentlyMemoizedCall(alias fun, T...)(T args) if (isPure!fun &&
                                                           isCallable!(fun, args))
{
    import std.functional: memoize;
    return fun(args);
}

/** Move std.uni.newLine?
    TODO What to do with Windows style endings?
    See also: https://en.wikipedia.org/wiki/Newline
*/
@safe pure nothrow @nogc
bool isNewline(C)(C c) if (isSomeChar!C)
{
    import std.ascii: newline; // TODO Probably not useful.
    static if (newline == "\n")
    {
        return (c == '\n' || c == '\r'); // optimized for systems with \n as default
    }
    else static if (newline == "\r")
    {
        return (c == '\r' || c == '\n'); // optimized for systems with \r as default
    }
    else
    {
        static assert(false, "Support Windows?");
    }
}

@safe pure nothrow @nogc
bool isNewline(S)(S s) if (isSomeString!S)
{
    import std.ascii: newline; // TODO Probably not useful.
    static if (newline == "\n")
    {
        return (s == '\n' || s == '\r'); // optimized for systems with \n as default
    }
    else static if (newline == "\r")
    {
        return (s == '\r' || s == '\n'); // optimized for systems with \r as default
    }
    else static if (newline == "\r\n")
    {
        return (s == "\r\n" || s == '\r' || s == '\n'); // optimized for systems with \r\n as default
    }
    else static if (newline == "\n\r")
    {
        return (s == "\n\r" || s == '\r' || s == '\n'); // optimized for systems with \n\r as default
    }
    else
    {
        static assert(false, "Support windows?");
    }
}

/** Dynamic Variant of $(D EnumMembers).
    See also: http://forum.dlang.org/thread/bspwlfypfishykezzocx@forum.dlang.org#post-dguqnroxbfewerepomwq:40forum.dlang.org
*/
auto enumMembers(T)()
{
    import std.traits: EnumMembers;
    import std.algorithm: sort, uniq;
    return [EnumMembers!T].sort().uniq;
}

/** Get Number of Bits Required to store an instance of $(D T).
    See also: http://forum.dlang.org/thread/okonqhnxzqlqtxijxsfg@forum.dlang.org
   */
template packedBitSizeOf(T) if (T.min != T.max) // at least two enumerators
{
    static if (is(T == enum))
    {
        import core.bitop: bsr;
        enum range = T.max - T.min;
        enum packedBitSizeOf = range.bsr + 1;
        // static      if (range ==  0) { enum packedBitSizeOf = 1; }
        // else static if (range ==  1) { enum packedBitSizeOf = 1; }
        // else static if (range ==  2) { enum packedBitSizeOf = 2; }
        // else static if (range ==  3) { enum packedBitSizeOf = 2; }
        // else static if (range ==  4) { enum packedBitSizeOf = 3; }
        // else static if (range ==  5) { enum packedBitSizeOf = 3; }
        // else static if (range ==  6) { enum packedBitSizeOf = 3; }
        // else static if (range ==  7) { enum packedBitSizeOf = 3; }
        // else static if (range ==  8) { enum packedBitSizeOf = 4; }
        // else static if (range ==  9) { enum packedBitSizeOf = 4; }
        // else static if (range == 10) { enum packedBitSizeOf = 4; }
        // else static if (range == 11) { enum packedBitSizeOf = 4; }
        // else static if (range == 12) { enum packedBitSizeOf = 4; }
        // else static if (range == 13) { enum packedBitSizeOf = 4; }
        // else static if (range == 14) { enum packedBitSizeOf = 4; }
        // else static if (range == 15) { enum packedBitSizeOf = 4; }
        // else { static assert(false, "Cannot handle enum " ~ T.stringof); }
    }
    else
    {
        enum packedBitSizeOf = 8*T.sizeof;
    }
}

unittest
{
    static assert(packedBitSizeOf!ubyte == 8);

    static assert(!__traits(compiles, { enum E1 { x } static assert(packedBitSizeOf!E1 == 1);}));
    enum E2 { x, y }
    static assert(packedBitSizeOf!E2 == 1);
    enum E3 { x, y, z }
    static assert(packedBitSizeOf!E3 == 2);
    enum E4 { x, y, z, w }
    static assert(packedBitSizeOf!E4 == 2);
    enum E5 { a, b, c, d, e }
    static assert(packedBitSizeOf!E5 == 3);
    enum E6 { a, b, c, d, e, f }
    static assert(packedBitSizeOf!E6 == 3);
    enum E7 { a, b, c, d, e, f, g }
    static assert(packedBitSizeOf!E7 == 3);
    enum E8 { a, b, c, d, e, f, g, h }
    static assert(packedBitSizeOf!E8 == 3);
    enum E9 { a, b, c, d, e, f, g, h, i }
    static assert(packedBitSizeOf!E9 == 4);
}
