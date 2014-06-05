#!/usr/bin/env rdmd-dev-module

/** Various extensions to std.traits.
    Copyright: Per Nordlöw 2014-.
    License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
    Authors: $(WEB Per Nordlöw)
    See also: http://forum.dlang.org/thread/jbyixfbuefvdlttnyclu@forum.dlang.org#post-mailman.2199.1353742037.5162.digitalmars-d-learn:40puremagic.com
*/
module traits_ex;
import std.traits: isArray, isAssignable, ParameterTypeTuple;
import std.range: ElementType;

/** Returns: true iff $(D ptr) is handled by the garbage collector (GC). */
bool isGCPointer(void* ptr){
    import core.memory;
    return !!GC.addrOf(ptr);
}
alias inGC = isGCPointer;

/** Returns: true iff all types T are the same. */
template allSame(T...) {
    static if (T.length <= 1) {
        enum bool allSame = true;
    } else {
        enum bool allSame = is(T[0] == T[1]) && allSame!(T[1..$]);
    }
}

enum isArrayOf(T, U) = isArray!T && is(ElementType!T == U); // version(2.064)
unittest {
    alias T = typeof(["a", "b"]);
    assert(isArrayOf!(T, string));
}

import std.functional: unaryFun, binaryFun;

alias isEven = unaryFun!(a => (a & 1) == 0); // Limit to Integers?
alias isOdd = unaryFun!(a => (a & 1) == 1); // Limit to Integers?
alias lessThan = binaryFun!((a, b) => a < b);
alias greaterThan = binaryFun!((a, b) => a > b);

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

template Chainable() {
    import std.range: chain;
    auto ref opCast(Range)(Range r) {
        return chain(this, r);
    }
}
unittest {
    mixin Chainable;
}

enum arityMin0(alias fun) = __traits(compiles, fun());

/** Check if Type $(D A) is an Instance of Template $(D B).
    See also: http://forum.dlang.org/thread/mailman.2901.1316118301.14074.digitalmars-d-learn@puremagic.com#post-zzdpfhsgfdgpszdbgbbt:40forum.dlang.org
    Deprecated by: http://dlang.org/phobos/std_traits.html#isInstanceOf
*/
enum IsA(alias B, A) = is(A == B!T, T);
