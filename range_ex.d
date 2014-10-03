#!/usr/bin/env rdmd-dev-module

/** Extensions to std.algorithm.
    License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
*/

module range_ex;

/** Sliding Splitter.
    See also: http://forum.dlang.org/thread/dndicafxfubzmndehzux@forum.dlang.org
*/
struct SlidingSplitter(R)
{
    import std.range: isRandomAccessRange;
    import std.typecons: Tuple, tuple;

    this(R)(R data)
    {
        _data = data;
    }

    static if (isRandomAccessRange!R)
    {
        auto opSlice() const
        {
            // TODO what should we return here?
            return tuple(_data[0.._index],
                         _data[_index..$]);
        }

        Tuple!(R, R) front() { return typeof(return)(_data[0.._index],
                                                     _data[_index..$]); }

        size_t length() const { return _data.length - _index; }
    }

    auto ref moveFront()
    {
        popFront();
        return front;
    }

    void popFront()
    {
        if (_index < _data.length)
        {
            _index++;
        }
    }

    bool empty() const { return length == 0; }

    private R _data;
    private size_t _index;
}

auto ref slidingSplitter(R)(R data)
{
    return SlidingSplitter!R(data);
}

unittest
{
    import std.typecons: tuple;

    auto x = [1, 2, 3];
    auto y = SlidingSplitter!(int[])(x);

    assert(y.front == tuple([], x));
    assert(!y.empty);
    assert(x.length == y.length);

    assert(y.moveFront == tuple([1], [2, 3]));
    assert(y.moveFront == tuple([1, 2], [3]));
    assert(y.moveFront == tuple([1, 2, 3], []));

    assert(y.empty);

    auto z = slidingSplitter(x);
    foreach (i, e; z)
    {
        import std.stdio;
        writeln(i, ": ", e);
    }
}

/** Ring Buffer.
    See also: http://forum.dlang.org/thread/ltpaqk$2dav$1@digitalmars.com
    TODO inout
 */
struct RingBuffer(T)
{
    private T[] _data;
    private size_t _index;
    private size_t _length;

    auto opSlice() const
    {
	return cycle(_data[0.._length]).take(_length);
    }

    @property
    auto length() { return _length; }

    this(T[] data, size_t length = 0)
    {
        enforce(data.length, "empty ring buffer is prohibited");
        enforce(length <= data.length, "buffer length shall not be more
than buffer capacity");
        _data = data;
        _index = 0;
        _length = length;
    }
}

/** Static Iota.
    TODO Make use of staticIota when it gets available in Phobos.
*/
template siota(size_t from, size_t to) { alias siota = siotaImpl!(to-1, from); }
private template siotaImpl(size_t to, size_t now)
{
    import std.typetuple: TypeTuple;
    static if (now >= to) { alias siotaImpl = TypeTuple!(now); }
    else                  { alias siotaImpl = TypeTuple!(now, siotaImpl!(to, now+1)); }
}
