#!/usr/bin/env rdmd-dev-module

/** Extensions to std.algorithm.sort.
    License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
*/

module sort_ex;

import std.traits: isAggregateType, isIntegral, isSomeString, isArray;
import std.range: ElementType, isRandomAccessRange, isInputRange;

private template xtorFun(alias xtor)
{
    static if (is(typeof(xtor) : string))
    {
        auto ref xtorFun(T)(auto ref T a)
        {
            mixin("with (a) { return " ~ xtor ~ "; }");
        }
    }
    else static if (isIntegral!(typeof(xtor)))
    {
        auto ref xtorFun(T)(auto ref T a)
        {
            import std.conv: to;
            mixin("return a.tupleof[" ~ xtor.to!string ~ "];");
        }
    }
    else
    {
        alias xtorFun = xtor;
    }
}

/* private alias makePredicate(alias xtor) = (a, b) => (xtorFun!xtor(a) < xtorFun!xtor(b)); */

/* auto sortBy(xtors..., R)(R r) { */
/*     alias preds = staticMap!(makePredicate, xtors); */
/*     return r.sort!preds; */
/* } */

/** Sort Random Access Range $(D R) of Aggregates on Value of Calls to $(D xtor).
    See also: http://forum.dlang.org/thread/nqwzojnlidlsmpunpqqy@forum.dlang.org#post-dmfvkbfhzigecnwglrur:40forum.dlang.org
 */
void sortBy(alias xtor, R)(R r) if (isRandomAccessRange!R &&
                                    isAggregateType!(ElementType!R))
{
    import std.algorithm: sort;
    import std.functional: unaryFun;
    r.sort!((a, b) => (xtorFun!xtor(a) <
                       xtorFun!xtor(b)));
}

/** Reverse Sort Random Access Range $(D R) of Aggregates on Value of Calls to $(D xtor).
    See also: http://forum.dlang.org/thread/nqwzojnlidlsmpunpqqy@forum.dlang.org#post-dmfvkbfhzigecnwglrur:40forum.dlang.org
*/
void rsortBy(alias xtor, R)(R r) if (isRandomAccessRange!R &&
                                     isAggregateType!(ElementType!R))
{
    import std.algorithm: sort;
    import std.functional: unaryFun;
    r.sort!((a, b) => (xtorFun!xtor(a) >
                       xtorFun!xtor(b)));
}

@safe pure nothrow unittest
{
    static struct X { int x, y, z; }

    auto r = [ X(1, 2, 1),
               X(0, 1, 2),
               X(2, 0, 0) ];

    r.sortBy!(a => a.x);
    assert(r == [ X(0, 1, 2),
                  X(1, 2, 1),
                  X(2, 0, 0) ]);
    r.sortBy!(a => a.y);
    assert(r == [ X(2, 0, 0),
                  X(0, 1, 2),
                  X(1, 2, 1)] );
    r.sortBy!(a => a.z);
    assert(r == [ X(2, 0, 0),
                  X(1, 2, 1),
                  X(0, 1, 2) ]);

    r.sortBy!"x";
    assert(r == [ X(0, 1, 2),
                  X(1, 2, 1),
                  X(2, 0, 0) ]);
    r.sortBy!"y";
    assert(r == [ X(2, 0, 0),
                  X(0, 1, 2),
                  X(1, 2, 1)] );
    r.sortBy!"z";
    assert(r == [ X(2, 0, 0),
                  X(1, 2, 1),
                  X(0, 1, 2) ]);

    r.sortBy!0;
    assert(r == [ X(0, 1, 2),
                  X(1, 2, 1),
                  X(2, 0, 0) ]);
    r.sortBy!1;
    assert(r == [ X(2, 0, 0),
                  X(0, 1, 2),
                  X(1, 2, 1)] );
    r.sortBy!2;
    assert(r == [ X(2, 0, 0),
                  X(1, 2, 1),
                  X(0, 1, 2) ]);
}

/** Return a Sorted Copy of $(D r).
    See also: http://forum.dlang.org/thread/tnrvudehinmkvbifovwo@forum.dlang.org#post-tnrvudehinmkvbifovwo:40forum.dlang.org
 */
auto sorted(R)(R r) if (!(isArray!R))
{
    alias E = ElementType!R;
    import std.algorithm: sort, copy;
    import std.range: hasLength;
    static if (hasLength!R)
    {
        auto s = new E[r.length];
        r[].copy(s);
    }
    else
    {
        E[] s;
        foreach (const ref e; r[]) // TODO optimize?
        {
            s ~= e;
        }
    }
    s.sort;
    return s;
}

unittest
{
    import std.container: Array;
    auto x = Array!int(3, 2, 1);
    assert(x.sorted == [1, 2, 3]);
}

unittest
{
    import std.container: SList;
    auto x = SList!int(3, 2, 1);
    assert(x.sorted == [1, 2, 3]);
}

/** Return a Sorted Copy of $(D r).
    See also: http://forum.dlang.org/thread/tnrvudehinmkvbifovwo@forum.dlang.org#post-tnrvudehinmkvbifovwo:40forum.dlang.org
*/
auto sorted(R)(const R r) if (isArray!R)
{
    import std.algorithm: sort;
    auto s = r.dup;
    s.sort;
    return s;
}

@safe pure unittest
{
    import std.algorithm: sort;
    auto x = [3, 2, 1];
    auto y = x.dup; y.sort;
    assert(x.sorted == y);
}

@safe pure unittest
{
    import std.algorithm: sort;
    import std.array: array;
    auto x = "äaöbå";
    auto y = x.dup; y.sort;
    assert(x.sorted == y);
    assert(x.sorted != x);
}
