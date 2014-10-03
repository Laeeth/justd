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

    this(R)(R data, size_t index = 0)
    {
        _data = data;
        _index = index;
    }

    static if (hasSlicing!R)
    {
        auto opIndex(size_t i)
        {
            return tuple(_data[0.._index + i],
                         _data[_index + i..$]);
        }

        Tuple!(R, R) front() { return typeof(return)(_data[0.._index],
                                                     _data[_index..$]); }

        size_t length() const { return _data.length - _index; }

        void popFront()
        {
            if (_index < _data.length)
            {
                static if (isNarrowString!R)
                {
                    import std.range: stride;
                    _index += stride(_data, _index);
                }
                else
                {
                    ++_index;
                }
            }
        }
    }

    static if (isForwardRange!R)
    {
        @property auto save()
        {
            import std.range: save;
            return typeof(this)(_data.save, _index);
        }
    }

    bool empty() const
    {
        static if (hasSlicing!R)
        {
            return length == 0;
        }
        else
        {
            return _data.length == _index; // TODO what to use here instead?
        }
    }

    private R _data;
    private size_t _index;
}

auto slidingSplitter(R)(R data)
{
    return SlidingSplitter!R(data);
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

    import std.range: moveFront;
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

    auto name = slidingSplitter("Nordlöw");
    assert(!name.empty);

    /* foreach (e; name) */
    /* { */
    /*     version(show) writeln(e); */
    /* } */

    /* version(show) writefln("%(%s\n%)", slidingSplitter("Nordlöw")); */
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
