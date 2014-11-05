#!/usr/bin/env rdmd-dev-module

/** Extensions to std.algorithm.sort.
    License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
*/

module sort_ex;

import std.traits: isAggregateType;
import std.range: ElementType, isRandomAccessRange;

/** Sort Random Access Range $(D R) of Aggregates on Value of Calls to $(D extractor).
    See also: http://forum.dlang.org/thread/nqwzojnlidlsmpunpqqy@forum.dlang.org#post-dmfvkbfhzigecnwglrur:40forum.dlang.org
 */
void sortBy(alias extractor, R)(R r) if (isRandomAccessRange!R &&
                                         isAggregateType!(ElementType!R))
{
    import std.algorithm: sort;
    import std.functional: unaryFun;
    r.sort!((a, b) => (unaryFun!extractor(a) <
                       unaryFun!extractor(b)));
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

}
