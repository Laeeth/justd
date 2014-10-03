#!/usr/bin/env rdmd-dev-module

/** Extensions to std.range.
    License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
*/

module range_ex;

import std.range: hasSlicing, isSomeString, isNarrowString, isInfinite;

/** Sliding Splitter.
    See also: http://forum.dlang.org/thread/dndicafxfubzmndehzux@forum.dlang.org
    See also: http://forum.dlang.org/thread/uzrbmjonrkixojzflbig@forum.dlang.org#post-viwkavbmwouiquoqwntm:40forum.dlang.org
*/
struct SlidingSplitter(Range) if (isSomeString!Range ||
                                  (hasSlicing!Range &&
                                   !isInfinite!Range))
{
    import std.range: isForwardRange;
    import std.typecons: Unqual;
    alias R = Unqual!Range;

    import std.typecons: Tuple, tuple;

    this(R)(R data, size_t beginIndex = 0)
    {
        _data = data;
        _beginIndex = beginIndex;
        _endIndex = data.length;
    }

    this(R)(R data, size_t beginIndex, size_t endIndex)
    {
        _data = data;
        _beginIndex = beginIndex;
        _endIndex = endIndex;
    }

    @property Tuple!(R, R) front() { return typeof(return)(_data[0 .. _beginIndex],
                                                           _data[_beginIndex .. $]); }


    void popFront()
    {
        static if (isNarrowString!R)
        {
            if (_beginIndex < _data.length)
            {
                import std.utf: stride;
                _beginIndex += stride(_data, _beginIndex);
            }
            else
            {
                ++_beginIndex;
            }
        }
        else
        {
            if (_beginIndex < _data.length)
            {
                ++_beginIndex;
            }
        }
    }

    static if (isForwardRange!R)
    {
        @property auto save()
        {
            import std.range: save;
            return typeof(this)(_data.save, _beginIndex);
        }
    }

    @property bool empty() const
    {
        static if (hasSlicing!R)
        {
            return length == 0;
        }
        else
        {
            return _data.length < _beginIndex;
        }
    }

    static if (hasSlicing!R)
    {
        Tuple!(R, R) opIndex(size_t i)
        {
            return typeof(return)(_data[0 .. _beginIndex + i],
                                  _data[_beginIndex + i .. $]);
        }

        @property size_t length() const { return _data.length - _beginIndex; }
    }

    private R _data;
    private size_t _beginIndex;
    private size_t _endIndex;
}

auto slidingSplitter(R)(R data, size_t beginIndex = 0)
{
    return SlidingSplitter!R(data, beginIndex, data.length);
}

auto slidingSplitter(R)(R data, size_t beginIndex, size_t endIndex)
{
    return SlidingSplitter!R(data, beginIndex, endIndex);
}

version = show;

unittest
{
    import std.typecons: tuple;
    version(show) import std.stdio;

    auto x = [1, 2, 3];
    auto y = SlidingSplitter!(typeof(x))(x);

    import std.range: isInputRange, isForwardRange, isBidirectionalRange, isRandomAccessRange;

    static assert(isInputRange!(SlidingSplitter!(typeof(x))));

    static assert(isForwardRange!(SlidingSplitter!(typeof(x))));
    // static assert(isBidirectionalRange!(SlidingSplitter!(typeof(x))));

    assert(y[0] == tuple([], x));
    assert(y.front == tuple([], x));
    assert(!y.empty);
    assert(x.length == y.length);

    assert(y.front == tuple([], [1, 2, 3])); y.popFront;
    assert(y.front == tuple([1], [2, 3])); y.popFront;
    assert(y.front == tuple([1, 2], [3])); y.popFront;

    assert(y.length == 0);
    assert(y.empty);

    auto z = slidingSplitter(x);

    size_t i;
    foreach (e; z)
    {
        version(show) writeln(i, ": ", e);
        ++i;
    }

    auto name = slidingSplitter("Nordlöw", 2);
    assert(!name.empty);
    version(show) writefln("%(%s\n%)", name);
}

/** Ring Buffer.
    See also: http://forum.dlang.org/thread/ltpaqk$2dav$1@digitalmars.com
    TODO inout
 */
struct RingBuffer(T)
{
    private T[] _data;
    private size_t _beginIndex;
    private size_t _length;

    auto opSlice() const
    {
	return cycle(_data[0 .. _length]).take(_length);
    }

    @property
    auto length() { return _length; }

    this(T[] data, size_t length = 0)
    {
        enforce(data.length, "empty ring buffer is prohibited");
        enforce(length <= data.length, "buffer length shall not be more
than buffer capacity");
        _data = data;
        _beginIndex = 0;
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
