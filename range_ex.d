#!/usr/bin/env rdmd-dev-module

/** Extensions to std.range.
    License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
*/

module range_ex;

import std.range: hasSlicing, isSomeString, isNarrowString, isInfinite;

/** Sliding Splitter.
    See also: http://forum.dlang.org/thread/dndicafxfubzmndehzux@forum.dlang.org
    See also: http://forum.dlang.org/thread/uzrbmjonrkixojzflbig@forum.dlang.org#epost-viwkavbmwouiquoqwntm:40forum.dlang.org

    TODO Should frontIndex and backIndex operate on code units instead of code
    point if isNarrowString!Range. ?
*/
struct SlidingSplitter(Range) if (isSomeString!Range ||
                                  (hasSlicing!Range &&
                                   !isInfinite!Range))
{
    import std.range: isForwardRange;
    import std.typecons: Unqual, Tuple, tuple;
    alias R = Unqual!Range;

    this(R)(R data, size_t frontIndex = 0)
    in { assert(frontIndex <= data.length); }
    body
    {
        _data = data;
        static if (hasSlicing!Range) // TODO should we use isSomeString here instead?
        {
            _frontIndex = frontIndex;
            _backIndex = data.length;
        }
        else
        {
            while (frontIndex)
            {
                popFront;
                --frontIndex;
            }
        }
        _backIndex = data.length;
    }

    this(R)(R data, size_t frontIndex, size_t backIndex)
    in { assert(frontIndex <= data.length);
         assert(backIndex <= data.length); }
    body
    {
        _data = data;
        _frontIndex = frontIndex;
        _backIndex = backIndex;
    }

    @property Tuple!(R, R) front()
    {
        return typeof(return)(_data[0 .. _frontIndex],
                              _data[_frontIndex .. $]);
    }

    @property Tuple!(R, R) back()
    {
        return typeof(return)(_data[0 .. _backIndex],
                              _data[_backIndex .. $]);
    }

    void popFront()
    {
        static if (isNarrowString!R)
        {
            if (_frontIndex < _backIndex)
            {
                import std.utf: stride;
                _frontIndex += stride(_data, _frontIndex);
            }
            else                // when we can't decode beyond
            {
                ++_frontIndex; // so just indicate we're beyond back
            }
        }
        else
        {
            ++_frontIndex;
        }
    }

    void popBack()
    {
        static if (isNarrowString!R)
        {
            if (_frontIndex < _backIndex)
            {
                import std.utf: strideBack;
                _backIndex -= strideBack(_data, _backIndex);
            }
            else                // when we can't decode beyond
            {
                --_backIndex; // so just indicate we're beyond front
            }
        }
        else
        {
            --_backIndex;
        }
    }

    static if (isForwardRange!R)
    {
        @property auto save()
        {
            import std.range: save;
            return typeof(this)(_data.save, _frontIndex);
        }
    }

    @property bool empty() const
    {
        return _backIndex < _frontIndex;
    }

    static if (hasSlicing!R)
    {
        Tuple!(R, R) opIndex(size_t i)
        {
            return typeof(return)(_data[0 .. _frontIndex + i],
                                  _data[_frontIndex + i .. _backIndex]);
        }

        // TODO Should length be provided if isNarrowString!Range?
        @property size_t length() const
        {
            return _backIndex - _frontIndex;
        }
    }

    private R _data;
    private ptrdiff_t _frontIndex;
    private ptrdiff_t _backIndex;
}

auto slidingSplitter(R)(R data, size_t frontIndex = 0)
{
    return SlidingSplitter!R(data, frontIndex, data.length);
}

auto slidingSplitter(R)(R data, size_t frontIndex, size_t backIndex)
{
    return SlidingSplitter!R(data, frontIndex, backIndex);
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

    auto y = SlidingSplitter!(typeof(x))(x);

    assert(y[0] == tuple([], x));
    assert(y.front == tuple([], x));
    assert(!y.empty);
    assert(x.length == y.length);

    assert(!y.empty); assert(y.front == tuple([], [1, 2, 3])); y.popFront;
    assert(!y.empty); assert(y.front == tuple([1], [2, 3])); y.popFront;
    assert(!y.empty); assert(y.front == tuple([1, 2], [3])); y.popFront;
    assert(!y.empty); assert(y.front == tuple([1, 2, 3], [])); y.popFront;
    y.popFront; assert(y.empty);
}

unittest                        // forwards
{
    import std.conv: to;

    size_t frontIndex = 2;

    auto name = "Nordlöw";
    auto name8 = slidingSplitter(name.to!string, frontIndex);
    auto name16 = slidingSplitter(name.to!wstring, frontIndex);
    auto name32 = slidingSplitter(name.to!dstring, frontIndex);

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

    size_t frontIndex = 2;

    auto name = "Nordlöw";
    auto name8 = slidingSplitter(name.to!string, frontIndex).retro;
    auto name16 = slidingSplitter(name.to!wstring, frontIndex).retro;
    auto name32 = slidingSplitter(name.to!dstring, frontIndex).retro;

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
