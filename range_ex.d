#!/usr/bin/env rdmd-dev-module

/** Extensions to std.range.
    License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
*/

module range_ex;

import std.range: hasSlicing, isSomeString, isNarrowString, isInfinite;

/** Sliding Splitter.
    See also: http://forum.dlang.org/thread/dndicafxfubzmndehzux@forum.dlang.org
    See also: http://forum.dlang.org/thread/uzrbmjonrkixojzflbig@forum.dlang.org#epost-viwkavbmwouiquoqwntm:40forum.dlang.org

    TODO Should lower and upper operate on code units instead of code
    point if isNarrowString!Range. ?
*/
struct SlidingSplitter(Range) if (isSomeString!Range ||
                                  (hasSlicing!Range &&
                                   !isInfinite!Range))
{
    import std.range: isForwardRange;
    import std.typecons: Unqual, Tuple, tuple;
    alias R = Unqual!Range;

    this(R)(R data, size_t lower = 0)
    in { assert(lower <= data.length); }
    body
    {
        _data = data;
        static if (hasSlicing!Range) // TODO should we use isSomeString here instead?
        {
            _lower = lower;
            _upper = data.length;
        }
        else
        {
            while (lower)
            {
                popFront;
                --lower;
            }
        }
        _upper = data.length;
    }

    this(R)(R data, size_t lower, size_t upper)
    in { assert(lower <= upper + 1 || // the extra + 1 makes empty initialization (lower + 1 == upper) possible in for example opSlice below
                ((lower <= data.length) &&
                 (upper <= data.length))); }
    body
    {
        _data = data;
        _lower = lower;
        _upper = upper;
    }

    @property Tuple!(R, R) front()
    {
        return typeof(return)(_data[0 .. _lower],
                              _data[_lower .. $]);
    }

    @property Tuple!(R, R) back()
    {
        return typeof(return)(_data[0 .. _upper],
                              _data[_upper .. $]);
    }

    void popFront()
    {
        static if (isNarrowString!R)
        {
            if (_lower < _upper)
            {
                import std.utf: stride;
                _lower += stride(_data, _lower);
            }
            else                // when we can't decode beyond
            {
                ++_lower; // so just indicate we're beyond back
            }
        }
        else
        {
            ++_lower;
        }
    }

    void popBack()
    {
        static if (isNarrowString!R)
        {
            if (_lower < _upper)
            {
                import std.utf: strideBack;
                _upper -= strideBack(_data, _upper);
            }
            else                // when we can't decode beyond
            {
                --_upper; // so just indicate we're beyond front
            }
        }
        else
        {
            --_upper;
        }
    }

    static if (isForwardRange!R)
    {
        @property auto save()
        {
            import std.range: save;
            return typeof(this)(_data.save, _lower, _upper);
        }
    }

    @property bool empty() const
    {
        return _upper < _lower;
    }

    static if (hasSlicing!R)
    {
        Tuple!(R, R) opIndex(size_t i)
        in { assert(i < length); }
        body
        {
            return typeof(return)(_data[0 .. _lower + i],
                                  _data[_lower + i .. _upper]);
        }

        typeof(this) opSlice(size_t lower, size_t upper)
        {
            if (lower == upper)
            {
                return slidingSplitter(_data,
                                       _upper + 1, // defines empty intialization
                                       _upper);
            }
            else
            {
                return slidingSplitter(_data,
                                       _lower + lower,
                                       _lower + (upper - 1));
            }
        }

        // TODO Should length be provided if isNarrowString!Range?
        @property size_t length() const
        {
            return _upper - _lower + 1;
        }
    }

    private R _data;
    private ptrdiff_t _lower;
    private ptrdiff_t _upper;
}

auto slidingSplitter(R)(R data, size_t lower = 0)
{
    return SlidingSplitter!R(data, lower, data.length);
}

auto slidingSplitter(R)(R data, size_t lower, size_t upper)
{
    return SlidingSplitter!R(data, lower, upper);
}

unittest
{
    import std.typecons: tuple;
    import std.conv: to;

    auto x = [1, 2, 3];

    import std.range: isInputRange, isForwardRange, isBidirectionalRange, isRandomAccessRange;

    static assert(isInputRange!(SlidingSplitter!(typeof(x))));
    static assert(isForwardRange!(SlidingSplitter!(typeof(x))));
    // static assert(isBidirectionalRange!(SlidingSplitter!(typeof(x))));
    static assert(isRandomAccessRange!(SlidingSplitter!(typeof(x))));

    auto y = SlidingSplitter!(typeof(x))(x);

    for (size_t i; i < y.length; ++i)
    {
        assert(y[i] == tuple(x[0..i], x[i..3]));
    }

    assert(y.front == tuple([], x));
    assert(!y.empty);
    assert(x.length + 1 == y.length);

    assert(!y.empty); assert(y.front == tuple(x[0 .. 0], x[0 .. 3])); y.popFront;
    assert(!y.empty); assert(y.front == tuple(x[0 .. 1], x[1 .. 3])); y.popFront;
    assert(!y.empty); assert(y.front == tuple(x[0 .. 2], x[2 .. 3])); y.popFront;
    assert(!y.empty); assert(y.front == tuple(x[0 .. 3], x[3 .. 3])); y.popFront;

    y.popFront; assert(y.empty);
}

unittest                        // forwards
{
    import std.conv: to;

    size_t lower = 2;

    auto name = "Nordlöw";
    auto name8 = slidingSplitter(name.to!string, lower);
    auto name16 = slidingSplitter(name.to!wstring, lower);
    auto name32 = slidingSplitter(name.to!dstring, lower);

    static assert(!__traits(compiles, { name8.length >= 0; } ));
    static assert(!__traits(compiles, { name16.length >= 0; } ));
    assert(name32.length);

    foreach (ch; name8)
    {
        foreach (ix; siota!(0, ch.length)) // for each part in split
        {
            import std.algorithm: equal;
            assert(equal(ch[ix], name16.front[ix]));
            assert(equal(ch[ix], name32.front[ix]));

        }
        name16.popFront;
        name32.popFront;
    }
}

unittest                        // backwards
{
    import std.conv: to;
    import std.range: retro;

    size_t lower = 2;

    auto name = "Nordlöw";
    auto name8 = slidingSplitter(name.to!string, lower).retro;
    auto name16 = slidingSplitter(name.to!wstring, lower).retro;
    auto name32 = slidingSplitter(name.to!dstring, lower).retro;

    foreach (ch; name8)
    {
        foreach (ix; siota!(0, ch.length)) // for each part in split
        {
            import std.algorithm: equal;
            assert(equal(ch[ix], name16.front[ix]));
            assert(equal(ch[ix], name32.front[ix]));
        }
        name16.popFront;
        name32.popFront;
    }
}

unittest                        // radial
{
    auto x = [1, 2, 3];
    import std.range: radial;
    import std.typecons: tuple;
    auto s = slidingSplitter(x);
    auto r = s.radial;
    assert(!r.empty); assert(r.front == tuple(x[0 .. 1], x[1 .. 3])); r.popFront;
    assert(!r.empty); assert(r.front == tuple(x[0 .. 2], x[2 .. 3])); r.popFront;
    assert(!r.empty); assert(r.front == tuple(x[0 .. 0], x[0 .. 3])); r.popFront;
    assert(!r.empty); assert(r.front == tuple(x[0 .. 3], x[3 .. 3])); r.popFront;
    assert(r.empty);
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

/* TODO Remove when new DMD is released */
static if (__VERSION__ < 2067)
{
    import std.typecons : Flag, No, Tuple, tuple, Yes;
    import std.range : ElementType, isInputRange, isOutputRange, hasLength, put;
    import std.traits : isFunctionPointer, isDelegate;

    auto tee(Flag!"pipeOnPop" pipeOnPop = Yes.pipeOnPop, R1, R2)(R1 inputRange, R2 outputRange)
    if (isInputRange!R1 && isOutputRange!(R2, typeof(inputRange.front)))
    {
        static struct Result
        {
            private R1 _input;
            private R2 _output;
            static if (!pipeOnPop)
            {
                private bool _frontAccessed;
            }

            static if (hasLength!R1)
            {
                @property length()
                {
                    return _input.length;
                }
            }

            static if (isInfinite!R1)
            {
                enum bool empty = false;
            }
            else
            {
                @property bool empty() { return _input.empty; }
            }

            void popFront()
            {
                assert(!_input.empty);
                static if (pipeOnPop)
                {
                    put(_output, _input.front);
                }
                else
                {
                    _frontAccessed = false;
                }
                _input.popFront();
            }

            @property auto ref front()
            {
                static if (!pipeOnPop)
                {
                    if (!_frontAccessed)
                    {
                        _frontAccessed = true;
                        put(_output, _input.front);
                    }
                }
                return _input.front;
            }
        }

        return Result(inputRange, outputRange);
    }

    /++
     Overload for taking a function or template lambda as an $(LREF OutputRange)
     +/
    auto tee(alias fun, Flag!"pipeOnPop" pipeOnPop = Yes.pipeOnPop, R1)(R1 inputRange)
    if (is(typeof(fun) == void) || isSomeFunction!fun)
    {
        /*
          Distinguish between function literals and template lambdas
          when using either as an $(LREF OutputRange). Since a template
          has no type, typeof(template) will always return void.
          If it's a template lambda, it's first necessary to instantiate
          it with $(D ElementType!R1).
        */
        static if (is(typeof(fun) == void))
            alias _fun = fun!(ElementType!R1);
        else
        alias _fun = fun;

        static if (isFunctionPointer!_fun || isDelegate!_fun)
        {
            return tee!pipeOnPop(inputRange, _fun);
        }
        else
        {
            return tee!pipeOnPop(inputRange, &_fun);
        }
    }

}
