#!/usr/bin/env rdmd-dev-module

/** Extensions to std.range.
    License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
*/

module range_ex;

import std.range: hasSlicing, isSomeString, isNarrowString, isInfinite;

/** Sliding Splitter.
    See also: http://forum.dlang.org/thread/dndicafxfubzmndehzux@forum.dlang.org
    See also: http://forum.dlang.org/thread/uzrbmjonrkixojzflbig@forum.dlang.org#epost-viwkavbmwouiquoqwntm:40forum.dlang.org

    TODO Bidirectional support
    TODO Make beginIndex and endIndex operate on code units instead of code
    point if isNarrowString!Range.
*/
struct SlidingSplitter(bool reverse = false,
                       Range) if (isSomeString!Range ||
                                  (hasSlicing!Range &&
                                   !isInfinite!Range))
{
    import std.range: isForwardRange;
    import std.typecons: Unqual, Tuple, tuple;
    alias R = Unqual!Range;

    /** beginIndex is currently code unit not points */
    this(R)(R data, size_t beginIndex = 0)
    in { assert(beginIndex <= data.length); }
    body
    {
        _data = data;
        static if (hasSlicing!Range) // TODO should we use isSomeString here instead?
        {
            _beginIndex = beginIndex;
            _endIndex = data.length;
        }
        else
        {
            while (beginIndex)
            {
                popFront;
                --beginIndex;
            }
        }
        _endIndex = data.length;
    }

    /** beginIndex and endIndex are currently code units not points */
    this(R)(R data, size_t beginIndex, size_t endIndex)
    in { assert(beginIndex <= data.length);
         assert(endIndex <= data.length); }
    body
    {
        _data = data;
        _beginIndex = beginIndex;
        _endIndex = endIndex;
    }

    @property Tuple!(R, R) front()
    {
        import std.stdio;
        return typeof(return)(_data[0 .. _beginIndex],
                              _data[_beginIndex .. _endIndex]);
    }


    void popFront()
    {
        static if (isNarrowString!R)
        {
            if (_beginIndex < _data.length)
            {
                import std.utf: stride;
                _beginIndex += stride(_data, _beginIndex);
            }
            else                // when we can't decode beyond
            {
                ++_beginIndex; // so just indicate we're beyond end
            }
        }
        else
        {
            ++_beginIndex;
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
        return _data.length < _beginIndex;
    }

    static if (hasSlicing!R)
    {
        Tuple!(R, R) opIndex(size_t i)
        {
            return typeof(return)(_data[0 .. _beginIndex + i],
                                  _data[_beginIndex + i .. _endIndex]);
        }

        // TODO Should length be provided if isNarrowString!Range?
        @property size_t length() const
        {
            return _endIndex - _beginIndex;
        }
    }

    private R _data;
    private size_t _beginIndex;
    private size_t _endIndex;
}

auto slidingSplitter(R)(R data, size_t beginIndex = 0)
{
    return SlidingSplitter!(false, R)(data, beginIndex, data.length);
}

auto slidingReverseSplitter(R)(R data, size_t beginIndex = 0)
{
    return SlidingSplitter!(true, R)(data, beginIndex, data.length);
}

auto slidingSplitter(R)(R data, size_t beginIndex, size_t endIndex)
{
    return SlidingSplitter!(false, R)(data, beginIndex, endIndex);
}

auto slidingReverseSplitter(R)(R data, size_t beginIndex, size_t endIndex)
{
    return SlidingSplitter!(true, R)(data, beginIndex, endIndex);
}

unittest
{
    import std.typecons: tuple;
    import std.conv: to;

    auto x = [1, 2, 3];

    import std.range: isInputRange, isForwardRange, isBidirectionalRange, isRandomAccessRange;

    static assert(isInputRange!(SlidingSplitter!(false, typeof(x))));
    static assert(isForwardRange!(SlidingSplitter!(false, typeof(x))));
    // static assert(isBidirectionalRange!(SlidingSplitter!(typeof(x))));

    auto y = SlidingSplitter!(false, typeof(x))(x);

    assert(y[0] == tuple([], x));
    assert(y.front == tuple([], x));
    assert(!y.empty);
    assert(x.length == y.length);

    assert(!y.empty); assert(y.front == tuple([], [1, 2, 3])); y.popFront;
    assert(!y.empty); assert(y.front == tuple([1], [2, 3])); y.popFront;
    assert(!y.empty); assert(y.front == tuple([1, 2], [3])); y.popFront;
    assert(!y.empty); assert(y.front == tuple([1, 2, 3], [])); y.popFront;
    y.popFront; assert(y.empty);

    size_t beginIndex = 2;

    auto cname = slidingSplitter("Nordlöw", beginIndex);
    auto wname = slidingSplitter("Nordlöw".to!wstring, beginIndex);
    auto dname = slidingSplitter("Nordlöw".to!dstring, beginIndex);

    static assert(!__traits(compiles, { cname.length >= 0; } ));
    static assert(!__traits(compiles, { wname.length >= 0; } ));
    assert(dname.length);

    import std.algorithm: equal;

    foreach (ch; cname)
    {
        foreach (ix; siota!(0, ch.length)) // for each part in split
        {
            assert(equal(ch[ix], wname.front[ix]));
            assert(equal(ch[ix], dname.front[ix]));

        }
        wname.popFront;
        dname.popFront;
    }

    /* import std.stdio; */
    /* writefln("%(%s\n%)", cname); */
    /* writefln("%(%s\n%)", wname); */
    /* writefln("%(%s\n%)", dname); */
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
