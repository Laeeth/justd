#!/usr/bin/env rdmd-dev-module

/** Extensions to std.algorithm.sort.
    License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
*/

module sort_ex;

import std.traits: isAggregateType, isIntegral;
import std.range: ElementType, isRandomAccessRange;

template extractorFun(alias extractor)
{
    static if (is(typeof(extractor) : string))
    {
        auto ref extractorFun(T)(auto ref T a)
        {
            mixin("with (a) { return " ~ extractor ~ "; }");
        }
    }
    else static if (is(isIntegral!(typeof(extractor))))
    {
        auto ref extractorFun(T)(auto ref T a)
        {
            mixin("{ return " ~ a.tupleof[extractor] ~ "; }");
        }
    }
    else
    {
        alias extractorFun = extractor;
    }
}

/** Sort Random Access Range $(D R) of Aggregates on Value of Calls to $(D extractor).
    See also: http://forum.dlang.org/thread/nqwzojnlidlsmpunpqqy@forum.dlang.org#post-dmfvkbfhzigecnwglrur:40forum.dlang.org
 */
void sortBy(alias extractor, R)(R r) if (isRandomAccessRange!R &&
                                         isAggregateType!(ElementType!R))
{
    import std.algorithm: sort;
    import std.functional: unaryFun;
    r.sort!((a, b) => (extractorFun!extractor(a) <
                       extractorFun!extractor(b)));
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

    /* r.sortBy!0; */
    /* assert(r == [ X(0, 1, 2), */
    /*               X(1, 2, 1), */
    /*               X(2, 0, 0) ]); */
    /* r.sortBy!1; */
    /* assert(r == [ X(2, 0, 0), */
    /*               X(0, 1, 2), */
    /*               X(1, 2, 1)] ); */
    /* r.sortBy!2; */
    /* assert(r == [ X(2, 0, 0), */
    /*               X(1, 2, 1), */
    /*               X(0, 1, 2) ]); */
}
