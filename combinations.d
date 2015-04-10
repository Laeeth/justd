#!/usr/bin/env rdmd-dev-module

module combinations;

import std.traits: Unqual;
import std.range: isRandomAccessRange, hasLength, ElementType;
import std.traits: isNarrowString;
import std.typecons: Tuple;

/**
   Given non-negative integers m and n, generate all size m combinations of the
   integers from 0 to n-1 in sorted order (each combination is sorted and the
   entire table is sorted).

   For example, 3 comb 5 is
   0 1 2
   0 1 3
   0 1 4
   0 2 3
   0 2 4
   0 3 4
   1 2 3
   1 2 4
   1 3 4
   2 3 4

   See also: http://rosettacode.org/wiki/Combinations
*/
struct Combinations(T, bool copy = true, bool useArray = true)
{
    import std.container: Array;

    static if (useArray)
        alias Indices = Array!size_t;
    else
        alias Indices = size_t[];

    Unqual!T[] pool, front;
    size_t r, n;
    bool empty = false;

    Indices indices;

    size_t len;
    bool lenComputed = false;

    this(T[] pool_, in size_t r_) // pure nothrow @safe
    {
        this.pool = pool_.dup;
        this.r = r_;
        this.n = pool.length;
        if (r > n)
            empty = true;

        indices.length = r;

        size_t i;

        i = 0;
        foreach (ref ini; indices[])
            ini = i++;

        front.length = r;

        i = 0;
        foreach (immutable idx; indices[])
            front[i++] = pool[idx];
    }

    @property size_t length() /*logic_const*/ // pure nothrow @nogc
    {
        static size_t binomial(size_t n, size_t k) // pure nothrow @safe @nogc
        in
        {
            assert(n > 0, "binomial: n must be > 0.");
        }
        body
        {
            if (k < 0 || k > n)
                return 0;
            if (k > (n / 2))
                k = n - k;
            size_t result = 1;
            foreach (size_t d; 1 .. k + 1) {
                result *= n;
                n--;
                result /= d;
            }
            return result;
        }

        if (!lenComputed)
        {
            // Set cache.
            len = binomial(n, r);
            lenComputed = true;
        }
        return len;
    }

    void popFront() // pure nothrow @safe
    {
        if (!empty)
        {
            bool broken = false;
            size_t pos = 0;
            foreach_reverse (immutable i; 0 .. r)
            {
                pos = i;
                if (indices[i] != i + n - r)
                {
                    broken = true;
                    break;
                }
            }
            if (!broken)
            {
                empty = true;
                return;
            }
            indices[pos]++;
            foreach (immutable j; pos + 1 .. r)
                indices[j] = indices[j - 1] + 1;
            static if (copy)
                front = new Unqual!T[front.length];

            size_t i = 0;
            foreach (immutable idx; indices[])
            {
                front[i] = pool[idx];
                i++;
            }
        }
    }
}

Combinations!(T, copy) combinations(bool copy = true, T)(T[] items, in size_t k)
in { assert(items.length, "combinations: items can't be empty."); }
body
{
    return typeof(return)(items, k);
}

unittest
{
    import std.algorithm: equal, map;
    // assert(equal([1, 2, 3, 4].combinations!false(2), [[3, 4], [3, 4], [3, 4], [3, 4], [3, 4], [3, 4]]));
    enum solution = [[1, 2],
                     [1, 3],
                     [1, 4],
                     [2, 3],
                     [2, 4],
                     [3, 4]];
    assert(equal([1, 2, 3, 4].combinations!true(2), solution));
    assert(equal([1, 2, 3, 4].combinations(2).map!(x => x), solution));
}

/**
   All Unordered Pairs (2-Element Subsets) of a Range.
   TODO Relax restrictions to ForwardRange
   See also: http://forum.dlang.org/thread/iqkybajwdzcvdytakgvw@forum.dlang.org#post-vhufbwsqbssyqwfxxbuu:40forum.dlang.org
   See also: https://issues.dlang.org/show_bug.cgi?id=6788
   See also: https://issues.dlang.org/show_bug.cgi?id=7128
*/
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
