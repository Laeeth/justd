#!/usr/bin/env rdmd-dev-module

/** Predicate extensions to std.algorithm.
    Copyright: Per Nordlöw 2014-.
    License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
    Authors: $(WEB Per Nordlöw)
   */
module predicates;

import std.traits: CommonType;

/** Return true if $(D x) is a equal to any of $(D y).
    TODO Make ys lazy if any of ys is a delegate.
 */
bool of(S, T...)(in S x, in T ys) pure if (ys.length >= 1 &&
                                           is(typeof({ return S.init ==
                                                       CommonType!(T).init; })))
{
    foreach (y; ys)
    {
        if (x == y)
        {
            return true;
        }
    }
    return false;
}

alias isEither = of;

@safe pure @nogc nothrow unittest
{
    assert(1.of(1, 2, 3));
    assert(!4.of(1, 2, 3));
}
