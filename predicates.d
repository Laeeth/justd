#!/usr/bin/env rdmd-dev-module

/** Predicate extensions to std.algorithm.
    Copyright: Per Nordlöw 2014-.
    License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
    Authors: $(WEB Per Nordlöw)
   */
module predicates;

import std.traits: CommonType;
import std.range: isIterable, ElementType;

/** Return true if $(D x) is a equal to any of $(D y).
    TODO Make ys lazy if any of ys is a delegate.
 */
bool of(S, T...)(in S x, in T ys) pure if (ys.length >= 1 &&
                                           is(typeof({ return S.init ==
                                                       CommonType!(T).init; })))
{
    foreach (y; ys)
        if (x == y)
            return true;
    return false;
}

@safe pure @nogc nothrow unittest
{
    assert(1.of(1, 2, 3));
    assert(!4.of(1, 2, 3));
}

/** Return true if $(D x) is a equal to any of $(D y).
*/
bool of(E, R)(E x, R ys) pure if (isIterable!R/*  && */
                                  /* is(E.init == ElementType!R.init) */)
{
    import std.range: isNarrowString;
    static if (isNarrowString!R)
    {
        import std.algorithm: canFind;
        return ys.canFind(x);
    }
    else
    {
        foreach (y; ys)
            if (x == y)
                return true;
        return false;
    }
}

@safe pure nothrow unittest
{
    assert(1.of([1, 2, 3]));
    assert(!4.of([1, 2, 3]));
}

@safe pure unittest
{
    assert('a'.of("abc"));
    assert(!'z'.of("abc"));
    assert('å'.of("åäö"));
}

alias isEither = of;
