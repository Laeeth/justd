#!/usr/bin/env rdmd-dev-module

/**
   All Unordered Pairs (2-Element Subsets) of a Range.
   TODO Relax restrictions to ForwardRange
   See also: http://forum.dlang.org/thread/iqkybajwdzcvdytakgvw@forum.dlang.org#post-vhufbwsqbssyqwfxxbuu:40forum.dlang.org
   See also: https://issues.dlang.org/show_bug.cgi?id=6788
   See also: https://issues.dlang.org/show_bug.cgi?id=7128
*/
module combinations;

import std.range: isRandomAccessRange, hasLength, ElementType;
import std.traits: isNarrowString;
import std.typecons: Tuple;

struct Pairwise(Range)
{
    import std.range: ForeachType;
    import std.traits: Unqual;

    alias R = Unqual!Range;
    alias E = ForeachType!R;
    alias Pair = Tuple!(E, E);

    this(Range r_)
    {
        this._input = r_;
        j = 1;
    }

    @property bool empty()
    {
        return j >= _input.length;
    }

    @property Pair front()
    {
        return Pair(_input[i], _input[j]);
    }

    void popFront()
    {
        if (j >= _input.length - 1)
        {
            i++;
            j = i + 1;
        }
        else
        {
            j++;
        }
    }

private:
    R _input;
    size_t i, j;
}

Pairwise!Range pairwise(Range)(Range r) if (isRandomAccessRange!Range &&
                                            hasLength!Range &&
                                            !isNarrowString!Range)
{
    return typeof(return)(r);
}

Pairwise!(ElementType!Range[]) pairwise(Range)(Range r) if (!(isRandomAccessRange!Range &&
                                                              hasLength!Range &&
                                                              !isNarrowString!Range))
{
    // TODO remove .array when ForwardRange supported has been added
    import std.array: array;
    return r.array.pairwise;
}

unittest
{
    import std.algorithm: equal, filter;
    import std.stdio: writeln;

    assert((new int[0]).pairwise.empty);
    assert([1].pairwise.empty);

    alias T = Tuple!(int, int);
    assert(equal([1, 2].pairwise,
                 [T(1, 2)]));
    assert(equal([1, 2, 3].pairwise,
                 [T(1, 2), T(1, 3), T(2, 3)]));
    assert(equal([1, 2, 3, 4].pairwise,
                 [T(1, 2), T(1, 3), T(1, 4),
                  T(2, 3), T(2, 4), T(3, 4)]));

    assert([1, 2, 3, 4].filter!"a < 4".pairwise ==
           [1, 2, 3].pairwise);
}
