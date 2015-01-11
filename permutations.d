#!/usr/bin/env rdmd-dev-module

module permutations;

import std.traits: isMutable;

/** Permutations of
    See also: http://rosettacode.org/wiki/Permutations#D
   */
struct Permutations(bool doCopy = false, T) if (isMutable!T)
{
    private immutable size_t num;
    private T[] items;
    private uint[31] indexes;
    private ulong tot;

    this (T[] items) pure nothrow @safe @nogc
    in
    {
        import std.conv: text;
        static enum string L = indexes.length.text;
        assert(items.length >= 0 && items.length <= indexes.length,
               "Permutations: items.length must be >= 0 && < " ~ L);
    }
    body
    {
        static ulong factorial(in size_t n) pure nothrow @safe @nogc
        {
            ulong result = 1;
            foreach (immutable i; 2 .. n + 1)
            {
                result *= i;
            }
            return result;
        }

        this.num = items.length;
        this.items = items;
        foreach (immutable i; 0 .. cast(typeof(indexes[0]))this.num)
        {
            this.indexes[i] = i;
        }
        this.tot = factorial(this.num);
    }

    @property T[] front() pure nothrow @safe
    {
        static if (doCopy)
        {
            return items.dup;
        }
        else
        {
            return items;
        }
    }

    @property bool empty() const pure nothrow @safe @nogc
    {
        return tot == 0;
    }

    @property size_t length() const pure nothrow @safe @nogc
    {
        // Not cached to keep the function pure.
        typeof(return) result = 1;
        foreach (immutable x; 1 .. items.length + 1)
        {
            result *= x;
        }
        return result;
    }

    void popFront() pure nothrow @safe @nogc
    {
        tot--;
        if (tot > 0)
        {
            size_t j = num - 2;

            while (indexes[j] > indexes[j + 1])
            {
                j--;
            }
            size_t k = num - 1;
            while (indexes[j] > indexes[k])
            {
                k--;
            }

            import std.algorithm: swap;

            swap(indexes[k], indexes[j]);
            swap(items[k], items[j]);

            size_t r = num - 1;
            size_t s = j + 1;
            while (r > s)
            {
                swap(indexes[s], indexes[r]);
                swap(items[s], items[r]);
                r--;
                s++;
            }
        }
    }
}

Permutations!(doCopy,T) permutationsInPlace(bool doCopy = false, T)(T[] items) if (isMutable!T)
{
    return Permutations!(doCopy, T)(items);
}

unittest
{
    import std.algorithm: equal;
    auto x = [1, 2, 3];
    auto y = [1, 2, 3];
    assert(equal(permutationsInPlace(y),
                 [[1, 2, 3],
                  [1, 3, 2],
                  [2, 1, 3],
                  [2, 3, 1],
                  [3, 1, 2],
                  [3, 2, 1]]));
    assert(x != y);
}

Permutations!(doCopy,T) permutations(bool doCopy = false, T)(T[] items) if (isMutable!T)
{
    return Permutations!(doCopy, T)(items.dup);
}

@safe pure nothrow unittest
{
    import std.algorithm: equal;
    auto x = [1, 2, 3];
    auto y = x;
    assert(equal(permutations(y),
                 [[1, 2, 3],
                  [1, 3, 2],
                  [2, 1, 3],
                  [2, 3, 1],
                  [3, 1, 2],
                  [3, 2, 1]]));
    assert(x == y);
}

@safe pure nothrow unittest
{
    import std.algorithm: equal;
    auto x = [`1`, `2`, `3`];
    auto y = x;
    assert(equal(permutations(y),
                 [[`1`, `2`, `3`],
                  [`1`, `3`, `2`],
                  [`2`, `1`, `3`],
                  [`2`, `3`, `1`],
                  [`3`, `1`, `2`],
                  [`3`, `2`, `1`]]));
    assert(x == y);
}

@safe pure nothrow unittest
{
    import std.algorithm: equal;
    auto x = ['1', '2', '3'];
    auto y = x;
    assert(equal(permutations(y),
                 [['1', '2', '3'],
                  ['1', '3', '2'],
                  ['2', '1', '3'],
                  ['2', '3', '1'],
                  ['3', '1', '2'],
                  ['3', '2', '1']]));
    assert(x == y);
}

struct CartesianPower(bool doCopy = true, T)
{
    T[] items;
    ulong repeat;
    T[] row;
    ulong i, maxN;

    this(T[] items_, in uint repeat_, T[] buffer) pure nothrow @safe @nogc
    {
        this.items = items_;
        this.repeat = repeat_;
        row = buffer[0 .. repeat];
        row[] = items[0];
        maxN = items.length ^^ repeat;
    }

    static if (doCopy)
    {
        @property T[] front() pure nothrow @safe @nogc
        {
            return row.dup;
        }
    }
    else
    {
        @property T[] front() pure nothrow @safe @nogc
        {
            return row;
        }
    }

    @property bool empty() pure nothrow @safe @nogc
    {
        return i >= maxN;
    }

    void popFront() pure nothrow @safe @nogc
    {
        i++;
        if (empty)
            return;
        ulong n = i;
        size_t count = repeat - 1;
        while (n)
        {
            row[count] = items[n % items.length];
            count--;
            n /= items.length;
        }
    }
}

auto cartesianPower(bool doCopy = true, T)(T[] items, in uint
                                                       repeat)
    pure nothrow @safe {
    return CartesianPower!(doCopy, T)(items, repeat, new
                                      T[repeat]);
}

auto cartesianPower(bool doCopy = true, T)(T[] items, in uint
                                                       repeat, T[] buffer)
    pure nothrow @safe @nogc {
    if (buffer.length >= repeat) {
        return CartesianPower!(doCopy, T)(items, repeat, buffer);
    } else {
        // Is this correct in presence of chaining?
        static immutable err = new Error("buffer.length <
repeat");
        throw err;
    }
}

@nogc unittest
{
    import core.stdc.stdio;
    int[3] items = [10, 20, 30];
    int[4] buf;
    foreach (p; cartesianPower!false(items, 4, buf))
    {
        printf("(%d, %d, %d, %d)\n", p[0], p[1], p[2], p[3]);
    }
}
