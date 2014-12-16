#!/usr/bin/env rdmd-dev-module

/** Extensions to std.range.
    License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
*/

module range_ex;

import std.range: hasSlicing, isSomeString, isNarrowString, isInfinite, ElementType;
import std.traits: hasUnsharedAliasing, hasElaborateDestructor, isArray, isScalarType;

enum hasPureCopy(T) = (isScalarType!T || // TODO remove?
                       (!hasUnsharedAliasing!T &&
                        !hasElaborateDestructor!T));

enum hasStealableElements(R) = (hasPureCopy!(ElementType!R)); // TODO recurse

/* template hasStealableElements(T...) */
/* { */
/*     import std.range: ElementType; */
/*     import std.typecons : Rebindable; */

/*     static if (is(ElementType!T)) */
/*     { */
/*         enum hasStealableElements = true; */
/*     } */
/*     else static if (is(T[0] R: Rebindable!R)) */
/*     { */
/*         enum hasStealableElements = hasStealableElements!R; */
/*     } */
/*     else */
/*     { */
/*         template unsharedDelegate(T) */
/*         { */
/*             enum bool unsharedDelegate = isDelegate!T */
/*             && !is(T == shared) */
/*             && !is(T == shared) */
/*             && !is(T == immutable) */
/*             && !is(FunctionTypeOf!T == shared) */
/*             && !is(FunctionTypeOf!T == immutable); */
/*         } */

/*         enum hasStealableElements = */
/*         hasRawUnsharedAliasing!(T[0]) || */
/*         anySatisfy!(unsharedDelegate, RepresentationTypeTuple!(T[0])) || */
/*         hasUnsharedObjects!(T[0]) || */
/*         hasStealableElements!(T[1..$]); */
/*     } */
/* } */

@safe @nogc pure nothrow unittest
{
    static assert(hasStealableElements!(int[]));

    import std.stdio: File;
    alias BL = File.ByLine!(char, char);
    static assert(!hasStealableElements!BL);
}

/** Steal front from $(D r) destructively and return it.
   See also: http://forum.dlang.org/thread/jkbhlezbcrufowxtthmy@forum.dlang.org#post-konhvblwbmpdrbeqhyuv:40forum.dlang.org
   See also: http://forum.dlang.org/thread/onibkzepudfisxtrigsi@forum.dlang.org#post-dafmzroxvaeejyxrkbon:40forum.dlang.org
*/
auto stealFront(R)(ref R r) if (hasStealableElements!R)
{
    import std.range: moveFront, popFront;
    /* scope(success) r.popFront; */
    /* return r.moveFront; */
    auto e = r.moveFront;
    r.popFront;
    return e;
}

@safe pure nothrow unittest
{
    auto x = [11, 22];
    assert(x.stealFront == 11); assert(x == [22]);
    assert(x.stealFront == 22); assert(x == []);
}

@safe pure nothrow unittest
{
    auto x = ["a", "b"];
    assert(x.stealFront == "a"); assert(x == ["b"]);
}

/** Steal back from $(D r) destructively and return it.
    See also: http://forum.dlang.org/thread/jkbhlezbcrufowxtthmy@forum.dlang.org#post-konhvblwbmpdrbeqhyuv:40forum.dlang.org
    See also: http://forum.dlang.org/thread/onibkzepudfisxtrigsi@forum.dlang.org#post-dafmzroxvaeejyxrkbon:40forum.dlang.org
*/
auto stealBack(R)(ref R r) if (hasStealableElements!R)
{
    import std.range: moveBack, popBack;
    /* scope(success) r.popBack; */
    /* return r.moveBack; */
    auto e = r.moveBack;
    r.popBack;
    return e;
}

@safe pure nothrow unittest
{
    auto x = [11, 22];
    assert(x.stealBack == 22); assert(x == [11]);
    assert(x.stealBack == 11); assert(x == []);
}

@safe pure nothrow unittest
{
    auto x = ["a", "b"];
    assert(x.stealBack == "b"); assert(x == ["a"]);
}

/** Sliding Splitter.
    See also: http://forum.dlang.org/thread/dndicafxfubzmndehzux@forum.dlang.org
    See also: http://forum.dlang.org/thread/uzrbmjonrkixojzflbig@forum.dlang.org#epost-viwkavbmwouiquoqwntm:40forum.dlang.org

    TODO Use size_t for _lower and _upper instead and reserve _upper =
    size_t.max for emptyness?

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

    static if (!isInfinite!R)
    {
        @property Tuple!(R, R) back()
        {
            return typeof(return)(_data[0 .. _upper],
                                  _data[_upper .. $]);
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
    }

    static if (isForwardRange!R)
    {
        @property auto save()
        {
            import std.range: save;
            return typeof(this)(_data.save, _lower, _upper);
        }
    }

    static if (isInfinite!R)
    {
        enum bool empty = false;  // propagate infiniteness
    }
    else
    {
        @property bool empty() const
        {
            return _upper < _lower;
        }
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

@safe pure nothrow unittest
{
    import std.typecons: tuple;
    import std.conv: to;

    auto x = [1, 2, 3];

    import std.range: isInputRange, isForwardRange, isBidirectionalRange, isRandomAccessRange;

    static assert(isInputRange!(SlidingSplitter!(typeof(x))));
    static assert(isForwardRange!(SlidingSplitter!(typeof(x))));
    // static assert(isBidirectionalRange!(SlidingSplitter!(typeof(x))));
    static assert(isRandomAccessRange!(SlidingSplitter!(typeof(x))));
    static assert(!isRandomAccessRange!(SlidingSplitter!string));
    static assert(!isRandomAccessRange!(SlidingSplitter!wstring));
    static assert(isRandomAccessRange!(SlidingSplitter!dstring));

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

@safe pure unittest                        // forwards
{
    import std.conv: to;

    size_t lower = 2;

    auto name = "Nordlöw";
    auto name8  = name.to! string.slidingSplitter(lower);
    auto name16 = name.to!wstring.slidingSplitter(lower);
    auto name32 = name.to!dstring.slidingSplitter(lower);

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

@safe pure unittest                        // backwards
{
    import std.conv: to;
    import std.range: retro;

    size_t lower = 2;

    auto name = "Nordlöw";
    auto name8  = name.to! string.slidingSplitter(lower).retro;
    auto name16 = name.to!wstring.slidingSplitter(lower).retro;
    auto name32 = name.to!dstring.slidingSplitter(lower).retro;

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

@safe pure nothrow unittest                        // radial
{
    auto x = [1, 2, 3];
    import std.range: radial;
    import std.typecons: tuple;
    auto s = x.slidingSplitter;
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

/* Iterate Associative Array $(D aa) by Key.
  See also: http://forum.dlang.org/thread/dxotcrutrlmszlidufcr@forum.dlang.org?page=2#post-fhkgitmifgnompkqiscd:40forum.dlang.org
*/
/* auto byPair(K,V)(V[K] aa) */
/* { */
/*     import std.algorithm: map; */
/*     import std.typecons: tuple; */
/*     return aa.byKey.map!(key => tuple(key, aa[key])); */
/* } */
/* alias byItem = byPair; */

/* unittest */
/* { */
/*     string[int] x; */
/*     x[0] = "a"; */
/*     import std.algorithm: equal; */
/*     assert(equal(x.Pair), [tuple(0, "a")]); */
/* } */

/* Return Array of Key-Value Pairs of Associative Array $(D aa).
   See also: http://forum.dlang.org/thread/dxotcrutrlmszlidufcr@forum.dlang.org?page=2#post-fhkgitmifgnompkqiscd:40forum.dlang.org
*/
auto pairs(Key, Value)(Value[Key] aa)
{
    import std.typecons: Tuple, tuple;
    Tuple!(Key,Value)[] arr;
    arr.reserve(aa.length);
    foreach (key; aa.byKey)
    {
        arr ~= tuple(key, aa[key]);
    }
    return arr;
}
alias items = pairs; // TODO Isn't this Python-style naming ax better name

unittest
{
    string[int] x;
    x[0] = "a";
    import std.typecons: tuple;
    assert(x.pairs == [tuple(0, "a")]);
}
