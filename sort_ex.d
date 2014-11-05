#!/usr/bin/env rdmd-dev-module

/** Extensions to std.algorith.sort.
    License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
*/

module sort_ex;

import std.traits: isAggregateType;
import std.range: ElementType, isRandomAccessRange;

/** Sort Random Access Range $(D R) of Aggregates on Values of Extractors members.
    See also: http://forum.dlang.org/thread/nqwzojnlidlsmpunpqqy@forum.dlang.org#post-dmfvkbfhzigecnwglrur:40forum.dlang.org
 */
void sortBy(E..., R)(R r) if (isRandomAccessRange!R &&
                              isAggregateType!(ElementType!R))
{
    import std.algorithm: sort;
    import std.functional: unaryFun;
    r.sort!();
}

unittest
{
    struct X { double x, y, z; }
    auto r = new X[3];
    r.sortBy!("x", "y");
}
