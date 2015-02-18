#!/usr/bin/env rdmd-dev-module

/** Extensions to std.algorithm.
    Copyright: Per Nordlöw 2014-.
    License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
    Authors: $(WEB Per Nordlöw)
*/
module algorithm_ex;

/* version = print; */

import std.algorithm: reduce, min, max;
import std.typetuple: templateAnd, TypeTuple;
import std.traits: isArray, Unqual, isIntegral, CommonType, isIterable, isStaticArray, isFloatingPoint, arity, isSomeString, isSomeChar;
import std.range: ElementType, isInputRange, isForwardRange, isBidirectionalRange, isRandomAccessRange, hasSlicing, isNarrowString, hasLength, empty, front;
import traits_ex: isStruct, isClass, allSame;
import std.functional: unaryFun, binaryFun;

version(print) import dbg;
public import predicates;

// ==============================================================================================

auto typestringof(T)(in T a) { return T.stringof; }

import std.range: dropOne;
alias tail = dropOne;

// ==============================================================================================

/** Returns: First Argument (element of $(D a)) whose implicit conversion to
    bool is true.

    Similar to behaviour of Lisp's (or a...) and Python's a or ....

    TODO Why can't we make this lazy version @nogc and nothrow. This shouldn't
    be a problem, though, since qualifiers are inferred for templated functions.

    TODO Is inout Conversion!T the correct return value?

    TODO Special operator, say |||, for this?
*/
CommonType!T either(T...)(lazy T a) pure if (a.length >= 1)
{
    auto a0 = a[0]();           // evaluate only once
    static if (T.length == 1)
    {
        return a0;
    }
    else
    {
        return a0 ? a0 : either(a[1 .. $]); // recurse
    }
}
/** This overload enables, when possible, lvalue return. */
auto ref either(T...)(ref T a) pure if (a.length >= 1 && allSame!T)
{
    static if (T.length == 1)
    {
        return a[0];
    }
    else
    {
        return a[0] ? a[0] : either(a[1 .. $]); // recurse
    }
}
alias or = either;
unittest {
    immutable p = 1, q = 2;
    auto pq = either(p, q);
    assert(pq == 1);

    assert(either(3) == 3);
    assert(either(3, 4) == 3);
    assert(either(0, 4) == 4);
    assert(either(0, 0) == 0);
    assert(either("", "a") == "");
    string s = null;
    assert(either(s, "a") == "a");
    assert(either("a", "") == "a");
    immutable a2 = [1, 2];
    assert(either(a2) == a2);
    assert(either([0, 1], [1, 2]) == [0, 1]);
    assert(either([0, 1], [1]) == [0, 1]);
    assert(either("a", "b") == "a");

    int x = 1, y = 2;
    either(x, y) = 3;
    assert(x == 3);
    assert(y == 2);
}

// ==============================================================================================

/** Returns: Last Argument if all arguments implicitly bool-convert to true
    otherwise CommonType!T.init.

    Similar to behaviour of Lisp's (and a...) and Python's a and ....
    TODO Is inout Conversion!T the correct return value?
*/
CommonType!T every(T...)(lazy T a) /* @safe @nogc pure nothrow */ if (T.length >= 1)
{
    auto a0 = a[0]();           // evaluate only once
    static if (T.length == 1)
    {
        return a0;
    }
    else
    {
        return a0 ? every(a[1 .. $]) : CommonType!T.init; // recurse
    }
}

unittest
{
    assert(every(3) == 3);
    assert(every(3, 4) == 4);
    assert(every(0, 4) == 0);
    assert(every(0, 0) == 0);
    assert(every([0, 1], [1, 2]) == [1, 2]);
    assert(every([0, 1], [1]) == [1]);
    assert(every("a", "b") == "b");
    assert(every("", "b") == "b");
    assert(every(cast(string)null, "b") == cast(string)null);
}

version(none) // WARNING disabled because I don't see any use of this for.
{
    /** This overload enables, when possible, lvalue return.
    */
    auto ref every(T...)(ref T a) /* @safe @nogc pure nothrow */ if (T.length >= 1 && allSame!T)
    {
        static if (T.length == 1)
        {
            return a[0];
        }
        else
        {
            return a[0] ? every(a[1 .. $]) : a[0]; // recurse
        }
    }

    unittest
    {
        immutable p = 1, q = 2;
        assert(every(p, q) == 2);

        int x = 1, y = 2;
        every(x, y) = 3;
        assert(x == 1);
        assert(y == 3);
    }
}

alias and = every;

/** Evaluate all $(D parts) possibly digesting $(D whole).
    If all values of $(D parts) implicitly convert to bool true return the
    values as an array, otherwise restore whole and return null.
*/
CommonType!T[] tryEvery(S, T...)(ref S whole,
                                 lazy T parts) if (T.length >= 1)
{
    auto wholeBackup = whole;
    bool all = true;
    alias R = typeof(return);
    R results;
    foreach (result; parts) // evaluate each part
    {
        if (result)
        {
            results ~= result;
        }
        else
        {
            all = false;
            break;
        }
    }
    if (all)
    {
        return results;        // ok that whole has been changed in caller scope
    }
    else
    {
        whole = wholeBackup; // restore whole in caller scope if any failed
        return R.init;
    }
}

unittest
{
    auto whole = "xyz";
    import std.algorithm: skipOver;

    assert(whole.tryEvery(whole.skipOver('x'),
                          whole.skipOver('z')) == []); // failing match
    assert(whole == "xyz"); // should restore whole

    assert(whole.tryEvery(whole.skipOver('x'),
                          whole.skipOver('y'),
                          whole.skipOver('w')) == []); // failing match
    assert(whole == "xyz"); // should restore whole

    assert(whole.tryEvery(whole.skipOver('x'),
                          whole.skipOver('y')) == [true, true]); // successful match
    assert(whole == "z"); // should digest matching part
}

// ==============================================================================================

/** Returns: Minimum Element in $(D range). */
auto minElement(alias F = min, R)(in R range)
    @safe pure nothrow if (isInputRange!R)
{
    return reduce!F(ElementType!R.max, range);
}
alias smallest = minElement;
unittest { assert([1, 2, 3].minElement == 1); }

/** Returns: Maximum Element in X. */
auto maxElement(alias F = max, R)(in R range)
    @safe pure nothrow if (isInputRange!R)
{
    return reduce!F(ElementType!R.min, range);
}
alias largest = maxElement;
unittest { assert([1, 2, 3].maxElement == 3); }

/** Returns: Minmum and Maximum Element in X. */
auto minmaxElement(alias F = min, alias G = max, R)(in R range)
    @safe pure nothrow if (isInputRange!R)
{
    import std.typecons: tuple;
    return reduce!(F, G)(tuple(Unqual!(ElementType!R).max,
                               Unqual!(ElementType!R).min), range);
}
unittest { assert([1, 2, 3].minmaxElement == tuple(1, 3)); }

// ==============================================================================================

import std.traits: isInstanceOf;
import std.typecons: Nullable;

/** Returns: true iff $(D a) has a value containing meaningful information.
 */
bool hasContents(T)(in T a) @safe @nogc pure nothrow
{
    static if (isInstanceOf!(Nullable, T))
        return !a.isNull;
    else static if (isArray!T || isSomeString!T)
        return cast(bool)a.length; // see: http://stackoverflow.com/questions/18563414/empty-string-should-implicit-convert-to-bool-true/18566334?noredirect=1#18566334
    else
        return cast(bool)a;
}

/** Reset $(D a) to its default value.
    See also: std.typecons.Nullable.nullify
 */
auto ref reset(T)(ref T a) @property @trusted pure nothrow
{
    static if (isInstanceOf!(Nullable, T))
        a.nullify();
    else
        return a = T.init;
}
unittest {
    int x = 42;
    x.reset;
    assert(x == x.init);
}

unittest
{
    import std.typecons: Nullable;
    auto n = Nullable!(size_t,
                       size_t.max)();
    import predicates: untouched;
    assert(n.untouched);
    n = 0;
    assert(!n.untouched);
    assert(n == 0);
    n.reset;
    assert(n.untouched);
}

// ==============================================================================================

import std.typecons: Tuple, tuple;

// ==============================================================================================

import std.algorithm: find;

/** Find $(D needles) In Order in $(D haystack). */
auto findInOrder(alias pred = "a == b",
                 alias finder = find,
                 R,
                 E...)(R haystack,
                       E needles) /* @trusted pure nothrow */
{
    import std.range: empty;
    auto hit = haystack; // reference
    foreach (needle; needles) // for every needle in order
    {
        hit = finder!pred(hit, needle);
        if (hit.empty)
        {
            break;
        }
    }
    return hit;
}
unittest
{
    import std.range: empty;
    assert("a b c".findInOrder("a", "b", "c"));
    assert("b a".findInOrder("a", "b").empty);
}

/** Returns: Slice Overlap of $(D a) and $(D b) in order given by arguments.
 */
inout(T[]) overlapInOrder(T)(inout(T[]) a,
                             inout(T[]) b) /* @trusted pure nothrow */
{
    if (a.ptr <= b.ptr &&       // if a-start lies at or before b-start
        b.ptr < a.ptr + a.length) // if b-start lies before b-end
    {
        import std.algorithm: min, max;
        const low = max(a.ptr, b.ptr) - a.ptr;
        const n = min(b.length,
                      (b.ptr - a.ptr + 1)); // overlap length
        return a[low..low + n];
    }
    else
    {
        return [];
    }
}

/** Returns: Slice Overlap of $(D a) and $(D b) in any order.
    Deprecated by: std.array.overlap
 */
inout(T[]) overlap(T)(inout(T[]) a,
                      inout(T[]) b) /* @safe pure nothrow */
{
    if (inout(T[]) ab = overlapInOrder(a, b))
    {
        return ab;
    }
    else if (inout(T[]) ba = overlapInOrder(b, a))
    {
        return ba;
    }
    else
    {
        return [];
    }
}

unittest
{
    auto x = [-11_111, 11, 22, 333_333];
    const y = [-22_222, 441, 555, 66];

    assert(!overlap(x, y));
    assert(!overlap(y, x));

    auto x01 = x[0..1];
    auto x12 = x[1..2];
    auto x23 = x[2..3];

    // sub-ranges should overlap completely
    assert(overlap(x, x12) == x12);
    assert(overlap(x, x01) == x01);
    assert(overlap(x, x23) == x23);
    // and commutate f(a,b) == f(b,a)
    assert(overlap(x01, x) == x01);
    assert(overlap(x12, x) == x12);
    assert(overlap(x23, x) == x23);
}

/** Helper for overlap().
    Copied from std.array with simplified return expression.
 */
bool overlaps(T)(const(T)[] r1, const(T)[] r2) @trusted pure nothrow
{
    alias U = inout(T);
    static U* max(U* a, U* b) nothrow { return a > b ? a : b; }
    static U* min(U* a, U* b) nothrow { return a < b ? a : b; }

    auto b = max(r1.ptr, r2.ptr);
    auto e = min(r1.ptr + r1.length,
                 r2.ptr + r2.length);
    return b < e;
}

/** Returns: If range is a palindrome larger than $(D minLength).
    See also: http://forum.dlang.org/thread/dlfeiszyweafpjiocplf@forum.dlang.org#post-vpzuaqxvtdpzpeuorxdl:40forum.dlang.org
    See also: https://stackoverflow.com/questions/21849580/equality-operator-in-favour-of-std-range-equal
*/
bool isPalindrome(R)(R range, size_t minLength = 0) if (isBidirectionalRange!(R))
{
    static if (hasLength!R)
    {
        if (range.length < minLength) { return false; }
    }
    size_t i = 0;
    while (!range.empty)
    {
        import std.range: front, back, popFront, popBack;
        if (range.front != range.back) return false;
        range.popFront(); i++;
        if (range.empty) break;
        range.popBack(); i++;
    }
    return i >= minLength;
}
unittest
{
    assert("dallassallad".isPalindrome);
    assert(!"ab".isPalindrome);
    assert("a".isPalindrome);
    assert("åäå".isPalindrome);
    assert("åäå".isPalindrome(3));
    assert(!"åäå".isPalindrome(4));
    assert("".isPalindrome);
    assert([1, 2, 2, 1].isPalindrome);
    assert(![1, 2, 2, 1].isPalindrome(5));
}
alias isSymmetric = isPalindrome;

/* ref Unqual!T unqual(T)(in T x) pure nothrow if isStuct!T { return cast(Unqual!T)x; } */
/* unittest { */
/*     const int x; */
/*     unqual(x) = 1; */
/* } */

enum Reduction
{
    forwardDifference,
    backwardDifference,
    sum,
}

/** Generalized Windowed Reduce.
    See also: https://stackoverflow.com/questions/21004944/forward-difference-algorithm
    See also: http://forum.dlang.org/thread/ujouqtqeehkegmtaxebg@forum.dlang.org#post-lczzsypupcfigttghkwx:40forum.dlang.org
    See also: http://rosettacode.org/wiki/Forward_difference#D
*/
auto ref windowedReduce(Reduction reduction = Reduction.forwardDifference, R)(R range)
    @safe pure nothrow if (isInputRange!R)
{
    import std.algorithm: map;
    import std.range: zip, dropOne;
    auto ref op(T)(T a, T b) @safe pure nothrow
    {
        static      if (reduction == Reduction.forwardDifference)  return b - a; // TODO final static switch
        else static if (reduction == Reduction.backwardDifference) return a - b;
        else static if (reduction == Reduction.sum)                return a + b;
    }
    return range.zip(range.dropOne).map!(a => op(a[0], a[1])); // a is a tuple here
}
// NOTE: Disabled for now because this solution cannot be made nothrow
/* auto ref windowedReduce(Reduction reduction = Reduction.forwardDifference, uint N = 0, R)(R range) */
/*     @safe pure /\* nothrow *\/ if (isInputRange!R) */
/* { */
/*     auto ref helper(R range) @safe pure /\* nothrow *\/ { */
/*         import std.algorithm: map; */
/*         import std.range: zip, dropOne; */
/*         //  Note: that a[0] and a[1] indexes Zip tuple */
/*         static if (reduction == Reduction.forwardDifference) */
/*             return range.zip(range.dropOne).map!(a => a[1] - a[0]); */
/*         static if (reduction == Reduction.backwardDifference) */
/*             return range.zip(range.dropOne).map!(a => a[0] - a[1]); */
/*         static if (reduction == Reduction.sum) */
/*             return range.zip(range.dropOne).map!(a => a[0] + a[1]); */
/*     } */
/*     static if (N != 0) { */
/*         return windowedReduce!(reduction, N - 1)(helper(range)); */
/*     } else { */
/*         return helper(range); */
/*     } */
/* } */

/* unittest { */
/*     import std.range: front; */
/*     dln([1].windowedReduce!(Reduction.forwardDifference)); */
/*     dln([1, 22].windowedReduce!(Reduction.forwardDifference)); */
/*     dln([1, 22, 333].windowedReduce!(Reduction.forwardDifference)); */
/* } */

unittest
{
    import std.datetime: Clock, SysTime, Duration;
    import std.algorithm: map;
    SysTime[] times;
    const n = 4;
    foreach (i; 0..n)
        times ~= Clock.currTime;
    version(print) dln(times);
    auto spans = times.windowedReduce!(Reduction.forwardDifference);
    version(print) dln(spans);
    // dln(*(cast(ulong*)&(spans.front)));
    version(print) dln(Duration.sizeof);
}

unittest
{
    immutable i = [1, 4, 9, 17];
    import std.algorithm: equal;
    assert(i.windowedReduce!(Reduction.forwardDifference).equal ([+3, +5, +8]));
    assert(i.windowedReduce!(Reduction.backwardDifference).equal([-3, -5, -8]));
    assert(i.windowedReduce!(Reduction.sum).equal ([+5, +13, +26]));
    assert([1].windowedReduce.empty);
    version(print) dln(i.windowedReduce!(Reduction.sum));
}

/* TODO Assert that ElementType!R only value semantics.  */
auto ref packBitParallelRunLengths(R)(in R x) if (isInputRange!R)
{
    import std.bitmanip: BitArray;
    import core.bitop: bt;
    alias E = ElementType!R; // element type
    enum nBits = 8*E.sizeof;

    BitArray[nBits] runs;

    // allocate runs
    foreach (ref run; runs)
    {
        run.length = x.length;
    }

    /* string toString() @property @trusted const { */
    /*     typeof(return) y; */
    /*     import std.conv: to; */
    /*     foreach (run; runs) { */
    /*         y ~= run.to!string ~ "\n"; */
    /*     } */
    /*     return y; */
    /* } */

    /* size_t[nBits] counts; */

    import bitset: BitSet;
    foreach (eltIx, elt; x)
    {
        /* BitSet!nBits bits; */
        foreach (bitIndex; 0..nBits)
        {
            import bitop_ex: getBit;
            runs[bitIndex][eltIx] = elt.getBit(bitIndex);
        }
    }
    return runs;
}
alias packBPRL = packBitParallelRunLengths;
unittest {
    /* import backtrace.backtrace; */
    /* import std.stdio: stderr; */
    /* backtrace.backtrace.install(stderr); */
    const x = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    const xPacked = x.packBitParallelRunLengths;
    version(print) dln(xPacked);
}

/** Compute Forward Difference of $(D range).

    TODO Is there a difference between whether R r is immutable, const or
    mutable?

    TODO If r contains only one element return empty range.

    See also: https://stackoverflow.com/questions/21004944/forward-difference-algorithm
    See also: http://forum.dlang.org/thread/ujouqtqeehkegmtaxebg@forum.dlang.org#post-lczzsypupcfigttghkwx:40forum.dlang.org
    See also: http://rosettacode.org/wiki/Forward_difference#D
*/
auto forwardDifference(R)(R r) if (isInputRange!R)
{
    import std.range: front, empty, popFront, dropOne;

    struct ForwardDifference
    {
        R _range;
        alias E = ElementType!R;                       // Input ElementType
        alias D = typeof(_range.front - _range.front); // Element Difference Type. TODO Use this as ElementType of range
        D _front;
        bool _initialized = false;

        this(R range) in { assert(!range.empty); }
        body
        {
            auto tmp = range;
            if (tmp.dropOne.empty) // TODO This may be an unneccesary cost but is practical to remove extra logic
                _range = R.init; // return empty range
            else
                _range = range; // store range internally (by reference)
        }

        @property:
        auto ref front()
        {
            if (!_initialized) { popFront(); }
            return _front;
        }
        auto ref moveFront()
        {
            popFront();
            return _front;
        }
        void popFront()
        {
            if (empty is false)
            {
                _initialized = true;
                E rf = _range.front;
                _range.popFront();
                if (_range.empty is false)
                {
                    _front = _range.front - rf;
                }
            }
        }
        bool empty()
        {
            return _range.empty;
        }
    }

    return ForwardDifference(r);
}

unittest {
    import msgpack;
    import std.array: array;

    auto x = [long.max, 0, 1];
    auto y = x.forwardDifference;

    version(print) dln(y);
    version(print) dln(y.pack);
    version(print) dln(y.array.pack);
}

// ==============================================================================================

import std.traits: isCallable, ReturnType, arity, ParameterTypeTuple;
import traits_ex: arityMin0;

/** Create Range of Elements Generated by $(D fun).

    Use for example to generate random instances of return value of fun.

    TODO I believe we need arityMin, arityMax trait here
*/
auto apply(alias fun, N)(N n) if (isCallable!fun &&
                                  arityMin0!fun &&
                                  !is(ReturnType!fun == void) &&
                                  isIntegral!N)
{
    import std.range: iota;
    import std.algorithm: map;
    return n.iota.map!(n => fun);
}

unittest {
    import std.datetime: Clock, SysTime, Duration;
    import std.algorithm: map;
    import msgpack;
    import std.array: array;
    const n = 3;
    auto times = n.apply!(Clock.currTime).array;
    version(print) dln(times);
    auto spans = times.forwardDifference;
    version(print) dln(spans);
}

// ==============================================================================================

/** In Place Ordering (in Sorted Order) of all Elements $(D t).
    See also: https://stackoverflow.com/questions/21102646/in-place-ordering-of-elements/
    See also: http://forum.dlang.org/thread/eweortsmcmibppmvtriw@forum.dlang.org#post-eweortsmcmibppmvtriw:40forum.dlang.org
*/
void orderInPlace(T...)(ref T t) @trusted /* nothrow */
{
    import std.algorithm: sort, swap;
    static if (t.length == 2)
    {
        if (t[0] > t[1])
        {
            swap(t[0], t[1]);
        }
    }
    else
    {                           // generic version
        T[0][T.length] buffer;      // static buffer to capture elements
        foreach (idx, a; t)
            buffer[idx] = a;
        auto sorted = sort(buffer[]);
        foreach (idx, a; t)
            t[idx] = sorted[idx];
    }
}
unittest {
    auto x = 2, y = 1;
    orderInPlace(x, y);
    assert(x == 1);
    assert(y == 2);
}
unittest {
    auto x = 3, y = 1, z = 2;
    orderInPlace(x, y, z);
    assert(x == 1);
    assert(y == 2);
    assert(z == 3);
}

// ==============================================================================================

import std.algorithm: SwapStrategy;

/** Allow Static Arrays to be sorted without [].
    See also: http://forum.dlang.org/thread/jhzurojjnlkatjdgcfhg@forum.dlang.org
*/
template sort(alias less = "a < b", SwapStrategy ss = SwapStrategy.unstable)
{
    import std.algorithm: stdSort = sort;
    auto sort(Arr)(ref Arr arr) if (isStaticArray!Arr)
    {
        return stdSort!(less, ss)(arr[]);
    }
    auto sort(Range)(Range r) if (!isStaticArray!Range)
    {
        return stdSort!(less, ss)(r);
    }
}
unittest
{
    int[5] a = [ 9, 5, 1, 7, 3 ];
    int[]  b = [ 4, 2, 1, 6, 3 ];
    sort(a);
    sort(b);
}

/** Stable Variant of Quick Sort.
    See also: http://forum.dlang.org/thread/gjuvmrypvxeebvztszpr@forum.dlang.org
*/
auto ref stableSort(T)(auto ref T a) pure if (isRandomAccessRange!T)
{
    if (a.length >= 2)
    {
        import std.algorithm: partition3, sort;
        auto parts = partition3(a, a[$ / 2]); // mid element as pivot
        parts[0].sort();
        parts[2].sort();
    }
    return a;
}

unittest
{
    import random_ex: randInPlace;
    const n = 2^^16;
    auto a = new int[n];
    a.randInPlace;
    auto b = a.dup;
    a[].stableSort;
    import std.algorithm: sort;
    sort(b);
    assert(a == b);
}

// ==============================================================================================

/** Execute Expression $(D exp) the same way $(D n) times. */
void doTimes(uint n, lazy void expression)
{
    while (n--) expression();
}
alias loop = doTimes;
alias doN = doTimes;

/** Execute Expression $(D exp) $(I inline) the same way $(D n) times. */
void doTimes(uint n)(lazy void expression) // TOREVIEW: Should we use delegate instead?
{
    import range_ex: siota;
    foreach (i; siota(0, n)) expression();
}

// ==============================================================================================

/** Execute Expression $(D action) the same way $(D n) times. */
void times(alias action, N)(N n) if (isCallable!action &&
                                     isIntegral!N &&
                                     arity!action <= 1)
{
    static if (arity!action == 1 && // if one argument and
               isIntegral!(ParameterTypeTuple!action[0])) // its an integer
    {
        foreach (i; 0 .. n)
            action(i); // use it as action input
    }
    else
    {
        foreach (i; 0 .. n)
            action();
    }
}

unittest
{
    enum n = 10;
    int sum = 0;
    10.times!({ sum++; });
    assert(sum == n);
}

// ==============================================================================================

private string genNaryFun(string fun, V...)() @safe pure
{
    string code;
    import std.string: format;
    foreach (n, v; V)
        code ~= "alias values[%d] %s;".format(n, cast(char)('a'+n));
    code ~= "return " ~ fun ~ ";";
    return code;
}
template naryFun(string fun)
{
    auto naryFun(V...)(V values)
    {
        mixin(genNaryFun!(fun, V));
    }
}
unittest {
    alias test = naryFun!"a + b + c";
    assert(test(1, 2, 3) == 6);
}

import std.typetuple : allSatisfy;

/** Zip $(D ranges) together with operation $(D fun).
    TODO Remove when Issue 8715 is fixed providing zipWith
*/
auto zipWith(alias fun, Ranges...)(Ranges ranges) @safe pure nothrow if (Ranges.length >= 2 &&
									 allSatisfy!(isInputRange, Ranges))
{
    import std.range: zip;
    import std.algorithm: map;
    static if (ranges.length < 2)
        static assert(false, "Need at least 2 range arguments.");
    else static if (ranges.length == 2)
        return zip(ranges).map!(a => binaryFun!fun(a.expand));
    else
        return zip(ranges).map!(a => naryFun!fun(a.expand));
    // return zip(ranges).map!(a => fun(a.expand));
}
unittest {
    auto x = [1, 2, 3];
    import std.array: array;
    assert(zipWith!"a+b"(x, x).array == [2, 4, 6]);
    assert(zipWith!((a, b) => a + b)(x, x).array == [2, 4, 6]);
    assert(zipWith!"a+b+c"(x, x, x).array == [3, 6, 9]);
}

auto zipWith(fun, StoppingPolicy, Ranges...)(StoppingPolicy sp, Ranges ranges)
    @safe pure nothrow if (Ranges.length && allSatisfy!(isInputRange, Ranges))
{
    return zip(sp, ranges).map!fun;
}

/** Pair */
alias Pair(T, U) = Tuple!(T, U);
/** Instantiator for \c Pair. */
auto pair(T, U)(in T t, in U u) { return Pair!(T, U)(t, u); }

/** Triple */
alias Triple(T, U, V) = Tuple!(T, U, V);
/** Instantiator for \c Triple. */
auto triple(T, U, V)(in T t, in U u, in V v) { return Triple!(T, U, V)(t, u, v); }

/** Limit/Span (Min,Max) Pair.
    Todo: Decide on either Span, MinMax or Limits
    See also: https://stackoverflow.com/questions/21241878/generic-span-type-in-phobos
*/
struct Limits(T)
{
    import std.algorithm: min, max;

    @property @safe pure:

    /** Expand Limits to include $(D a). */
    auto ref include(in T a) nothrow {
        _lims[0] = min(_lims[0], a);
        _lims[1] = max(_lims[1], a);
        return this;
    }
    alias expand = include;

    auto ref reset() nothrow {
        _lims[0] = T.max;
        _lims[1] = T.min;
    }

    string toString() const {
        import std.conv: to;
        return ("[" ~ to!string(_lims[0]) ~
                "..." ~ to!string(_lims[1]) ~ "]") ;
    }

    auto _lims = tuple(T.max, T.min);

    alias _lims this;
}

auto limits(T)() { return Limits!T(); }
unittest {
    /* import std.file: SysTime; */
    /* SysTime st; */
    Limits!int x;
    x.expand(-10);
    x.expand(10);
    assert(x[0] == -10);
    assert(x[1] == +10);
    version(print) dln(x);
}

/* import rational: Rational; */

/* template getTypeString(T) { */
/*     static if (is(T == Rational)) */
/*         string getTypeString(T)() @safe pure nothrow { */
/*             return x"211A"; */
/*         } */
/* } */
/* unittest { */
/*     import rational: Rational; */
/*     dln(getTypeString!Rational); */
/* } */

/** Check if $(D a) and $(D b) are colinear. */
bool areColinear(T)(T a, T b) @safe pure nothrow
{
    // a and b are colinear if a.x / a.y == b.x / b.y
    // We can avoid the division by multiplying out.
    return a.x * b.y == a.y * b.x;
}

/* /\** TODO Remove when each is standard in Phobos. *\/ */
/* void each(R)(R range, delegate x) @safe pure /\* nothrow *\/ if (isInputRange!R) { */
/*     foreach (ref elt; range) { */
/*         x(elt); */
/*     } */
/* } */
/* unittest { */
/*     version(print) [1, 2, 3, 4].each(a => dln(a)); */
/* } */

// ==============================================================================================

/** Returns: min(max(x, min_val), max_val),
    Results are undefined if min_val > max_val.
*/
static if (__VERSION__ < 2067)
{
    auto clamp(T, TLow, THigh)(T x, TLow lower, THigh upper)
        @safe pure nothrow
        in { assert(lower <= upper, "lower > upper"); }
    body
    {
        import std.algorithm : min, max;
        return min(max(x, lower), upper);
    }

    unittest {
        assert((-1).clamp(0, 2) == 0);
        assert(0.clamp(0, 2) == 0);
        assert(1.clamp(0, 2) == 1);
        assert(2.clamp(0, 2) == 2);
        assert(3.clamp(0, 2) == 2);
    }
}

// ==============================================================================================

enum isIntLike(T) = is(typeof({T t = 0; t = t+t;})); // More if needed

/** $(LUCKY Fibonacci) Numbers (Infinite Range).
    See also: http://forum.dlang.org/thread/dqlrfoxzsppylcgljyyf@forum.dlang.org#post-mailman.1072.1350619455.5162.digitalmars-d-learn:40puremagic.com
*/
auto fibonacci(T = int)() if (isIntLike!T)
{
    struct Fibonacci
    {
        T a, b;
        T front() { return b; }
        void popFront()
        {
            T c = a+b;
            a = b;
            b = c;
        }
        bool empty() const { return false; }
    }
    return Fibonacci(0, 1);
}

unittest
{
    import std.range: take;
    import std.algorithm: equal;
    assert(fibonacci.take(10).equal([1, 1, 2, 3, 5, 8, 13, 21, 34, 55]));
}

/** Expand Static $(D array) into a parameter arguments (TypeTuple!).
    See also: http://forum.dlang.org/thread/hwellpcaomwbpnpofzlx@forum.dlang.org?page=1
*/
template expand(alias array, size_t idx = 0) if (isStaticArray!(typeof(array)))
{
    @property ref delay() { return array[idx]; }
    static if (idx + 1 < array.length)
    {
        alias expand = TypeTuple!(delay, expand!(array, idx + 1));
    }
    else
    {
        alias expand = delay;
    }
}

unittest
{
    static void foo(int a, int b, int c)
    {
        import std.stdio: writefln;
        version(print) writefln("a: %s, b: %s, c: %s", a, b, c);
    }
    int[3] arr = [1, 2, 3];
    foo(expand!arr);
}

/** Python Style To-String-Conversion Alias. */
string str(T)(in T a) @safe pure
{
    import std.conv: to;
    return to!string(a);
}

/** Python Style Length Alias. */
auto len(T)(in T a) @safe @nogc pure nothrow
{
    return a.length;
}

unittest
{
    import std.algorithm: map;
    import std.array: array;
    assert(([42].map!str).array == ["42"]);
}

import std.range: InputRange, OutputRange;
alias Source = InputRange; // nicer alias
alias Sink = OutputRange; // nicer alias

/* belongs to std.range */
import std.range: cycle, retro;
import std.functional: compose;
alias retroCycle = compose!(cycle, retro);

import std.traits: isAggregateType, hasMember;

/** Generic Member Setter.
    See also: http://forum.dlang.org/thread/fdjkijrtduraaajlxxne@forum.dlang.org
*/
auto ref T set(string member, T, U)(auto ref T a, in U value) if (isAggregateType!T &&
                                                                  hasMember!(T, member))
{
    __traits(getMember, a, member) = value;
    return a;
}

unittest
{
    class C { int x, y, z, w; }
    auto c = new C().set!`x`(11).set!`w`(44);
    assert(c.x == 11);
    assert(c.w == 44);
}

// ==============================================================================================

/* Check if $(D part) is part of $(D whole).
   See also: http://forum.dlang.org/thread/ls9dbk$jkq$1@digitalmars.com
   TODO Standardize name and remove alises.
   TODO Use partOf if generalized to InputRange.
 */
bool sliceOf(T)(in T[] part,
                in T[] whole)
{
    return (whole.ptr <= part.ptr &&
            part.ptr + part.length <=
            whole.ptr + whole.length);
}
alias containedIn = sliceOf;
alias partOf = sliceOf;
alias coveredBy = sliceOf;
alias includedIn = sliceOf;

/* See also: http://forum.dlang.org/thread/cjpplpzdzebfxhyqtskw@forum.dlang.org#post-cjpplpzdzebfxhyqtskw:40forum.dlang.org */
auto dropWhile(alias pred = "a == b", R, E)(R range, E element) if (isInputRange!R &&
                                                                    is (typeof(binaryFun!pred(range.front, element)) : bool))
{
    import std.algorithm: find;
    alias predFun = binaryFun!pred;
    return range.find!(a => !predFun(a, element));
}
alias dropAllOf = dropWhile;
alias stripFront = dropWhile;
alias lstrip = dropWhile;       // Python style

unittest
{
    assert([1, 2, 3].dropWhile(1) == [2, 3]);
    assert([1, 1, 1, 2, 3].dropWhile(1) == [2, 3]);
    assert([1, 2, 3].dropWhile(2) == [1, 2, 3]);
    assert("aabc".dropWhile('a') == "bc"); // TODO Remove restriction on cast to dchar
}

/* See also: http://forum.dlang.org/thread/cjpplpzdzebfxhyqtskw@forum.dlang.org#post-cjpplpzdzebfxhyqtskw:40forum.dlang.org */
auto takeWhile(alias pred = "a == b", R, E)(R range, E element) if (isInputRange!R &&
                                                                    is (typeof(binaryFun!pred(range.front, element)) : bool))
{
    import std.algorithm: until;
    alias predFun = binaryFun!pred;
    return range.until!(a => !predFun(a, element));
}
alias takeAllOf = takeWhile;

unittest
{
    import std.algorithm: equal;
    assert(equal([1, 1, 2, 3].takeWhile(1),
                 [1, 1]));
}

/** Simpler Variant of Phobos' split. */
auto split(alias pred, R)(R haystack) if (isForwardRange!R)
{
    static if (isSomeString!R ||
               isRandomAccessRange!R)
    {
        auto balance = find!pred(haystack);
        immutable pos1 = haystack.length - balance.length;
        immutable pos2 = balance.empty ? pos1 : pos1 + 1;
        return tuple(haystack[0 .. pos1],
                     haystack[pos1 .. pos2],
                     haystack[pos2 .. haystack.length]);
    }
    else
    {
        auto original = haystack.save;
        auto h = haystack.save;
        size_t pos1, pos2;
        while (!h.empty)
        {
            if (unaryFun!pred(h.front))
            {
                h.popFront();
                ++pos2;
            }
            else
            {
                haystack.popFront();
                h = haystack.save;
                pos2 = ++pos1;
            }
        }
        return tuple(takeExactly(original, pos1),
                     takeExactly(haystack, pos2 - pos1),
                     h);
    }
}

unittest
{
    import std.algorithm: equal;
    import std.ascii: isDigit;
    assert("aa1bb".split!(a => a.isDigit) == tuple("aa", "1", "bb"));
    assert("aa1".split!(a => a.isDigit) == tuple("aa", "1", ""));
    assert("1bb".split!(a => a.isDigit) == tuple("", "1", "bb"));
}

/** Simpler Variant of Phobos' splitBefore. */
auto splitBefore(alias pred, R)(R haystack) if (isForwardRange!R)
{
    static if (isSomeString!R ||
               sRandomAccessRange!R)
    {
        auto balance = find!pred(haystack);
        immutable pos = haystack.length - balance.length;
        return tuple(haystack[0 .. pos],
                     haystack[pos .. haystack.length]);
    }
    else
    {
        auto original = haystack.save;
        auto h = haystack.save;
        size_t pos;
        while (!h.empty)
        {
            if (unaryFun!pred(h.front))
            {
                h.popFront();
            }
            else
            {
                haystack.popFront();
                h = haystack.save;
                ++pos;
            }
        }
        return tuple(takeExactly(original, pos),
                     haystack);
    }
}

unittest
{
    import std.algorithm: equal;
    import std.ascii: isDigit;
    assert("11ab".splitBefore!(a => !a.isDigit) == tuple("11", "ab"));
    assert("ab".splitBefore!(a => !a.isDigit) == tuple("", "ab"));
}

auto splitAfter(alias pred, R)(R haystack) if (isForwardRange!R)
{
    static if (isSomeString!R || isRandomAccessRange!R)
    {
        auto balance = find!pred(haystack);
        immutable pos = balance.empty ? 0 : haystack.length - balance.length + 1;
        return tuple(haystack[0 .. pos], haystack[pos .. haystack.length]);
    }
    else
    {
        static assert(false, "How to implement this?");
        /* auto original = haystack.save; */
        /* auto h = haystack.save; */
        /* size_t pos1, pos2; */
        /* while (!n.empty) */
        /* { */
        /*     if (h.empty) */
        /*     { */
        /*         // Failed search */
        /*         return tuple(takeExactly(original, 0), original); */
        /*     } */
        /*     if (binaryFun!pred(h.front, n.front)) */
        /*     { */
        /*         h.popFront(); */
        /*         n.popFront(); */
        /*         ++pos2; */
        /*     } */
        /*     else */
        /*     { */
        /*         haystack.popFront(); */
        /*         n = needle.save; */
        /*         h = haystack.save; */
        /*         pos2 = ++pos1; */
        /*     } */
        /* } */
        /* return tuple(takeExactly(original, pos2), h); */
    }
}

unittest
{
    import std.algorithm: equal;
    import std.ascii: isDigit;
    assert("aa1bb".splitAfter!(a => a.isDigit) == tuple("aa1", "bb"));
    assert("aa1".splitAfter!(a => a.isDigit) == tuple("aa1", ""));
}

auto moveUntil(alias pred, R)(ref R r) if (isInputRange!R)
{
    auto split = r.splitBefore!pred;
    r = split[1];
    return split[0];
}

unittest
{
    auto r = "xxx111";
    auto id = r.moveUntil!(a => a == '1');
    assert(id == "xxx");
    assert(r == "111");
}

auto moveWhile(alias pred, R)(ref R r) if (isInputRange!R)
{
    return r.moveUntil!(a => !pred(a));
}

unittest
{
    auto r = "xxx111";
    auto id = r.moveWhile!(a => a == 'x');
    assert(id == "xxx");
    assert(r == "111");
}

/** Variant of $(D findSplitBefore) that destructively pops everthing up to, not
    including, $(D needle) from $(D haystack).
*/
auto findPopBefore(alias pred = "a == b", R1, R2)(ref R1 haystack,
                                                  R2 needle) if (isForwardRange!R1 &&
                                                                 isForwardRange!R2)
{
    if (haystack.empty || needle.empty)
    {
        return R1.init; // TODO correct?
    }
    import std.algorithm: findSplitBefore;
    auto split = findSplitBefore!pred(haystack, needle);
    if (split[0].empty) // TODO If which case are empty and what return value should they lead to?
    {
        return R1.init; // TODO correct?
    }
    else
    {
        haystack = split[1];
        return split[0];
    }
}

unittest
{
    auto haystack = "xy";
    auto needle = "z";
    auto pop = haystack.findPopBefore(needle);
}

unittest
{
    auto haystack = "xyz";
    auto needle = "y";
    auto pop = haystack.findPopBefore(needle);
    assert(pop == "x");
    assert(haystack == "yz");
}

/** Variant of $(D findSplitAfter) that destructively pops everthing up to,
    including, $(D needle) from $(D haystack).
*/
auto findPopAfter(alias pred = "a == b", R1, R2)(ref R1 haystack,
                                                 R2 needle) if (isForwardRange!R1 &&
                                                                isForwardRange!R2)
{
    if (haystack.empty || needle.empty)
    {
        return R1.init; // TODO correct?
    }
    import std.algorithm: findSplitAfter;
    auto split = findSplitAfter!pred(haystack, needle);
    if (split[0].empty)
    {
        return R1.init; // TODO correct?
    }
    else
    {
        haystack = split[1];
        return split[0];
    }
}

unittest
{
    auto source = "xyz";
    auto haystack = source;
    auto needle = "y";
    auto pop = haystack.findPopAfter(needle);
    assert(pop == "xy");
    assert(haystack == "z");
}

unittest
{
    auto source = "xy";
    auto haystack = source;
    auto needle = "z";
    auto pop = haystack.findPopAfter(needle);
    assert(pop is null);
    assert(!pop);
    assert(haystack == source);
}

/** Find First Occurrence any of $(D needles) in $(D haystack).
    Like to std.algorithm.find but takes an array of needles as argument instead
    of a variadic list of key needle arguments.
   Return found range plus index into needles starting at 1 upon.
 */
Tuple!(R, size_t) findFirstOfAnyInOrder(alias pred = "a == b", R)(R haystack, const R[] needles)
{
    import std.algorithm: find;
    switch (needles.length)
    {
        case 1:
            auto hit = haystack.find(needles[0]);
            return tuple(hit, hit.empty ? 0UL : 1UL);
        case 2:
            return haystack.find(needles[0],
                                 needles[1]);
        case 3:
            return haystack.find(needles[0],
                                 needles[1],
                                 needles[2]);
        case 4:
            return haystack.find(needles[0],
                                 needles[1],
                                 needles[2],
                                 needles[3]);
        case 5:
            return haystack.find(needles[0],
                                 needles[1],
                                 needles[2],
                                 needles[3],
                                 needles[4]);
        case 6:
            return haystack.find(needles[0],
                                 needles[1],
                                 needles[2],
                                 needles[3],
                                 needles[4],
                                 needles[5]);
        case 7:
            return haystack.find(needles[0],
                                 needles[1],
                                 needles[2],
                                 needles[3],
                                 needles[4],
                                 needles[5],
                                 needles[6]);
        case 8:
            return haystack.find(needles[0],
                                 needles[1],
                                 needles[2],
                                 needles[3],
                                 needles[4],
                                 needles[5],
                                 needles[6],
                                 needles[7]);
        default:
            import std.conv: to;
            assert(false, "Too many keys " ~ needles.length.to!string);
    }
}

unittest
{
    assert("abc".findFirstOfAnyInOrder(["x"]) == tuple("", 0UL));
    assert("abc".findFirstOfAnyInOrder(["a"]) == tuple("abc", 1UL));
    assert("abc".findFirstOfAnyInOrder(["c"]) == tuple("c", 1UL));
    assert("abc".findFirstOfAnyInOrder(["a", "b"]) == tuple("abc", 1UL));
    assert("abc".findFirstOfAnyInOrder(["a", "b"]) == tuple("abc", 1UL));
    assert("abc".findFirstOfAnyInOrder(["x", "b"]) == tuple("bc", 2UL));
}

Tuple!(R, size_t)[] findAllOfAnyInOrder(alias pred = "a == b", R)(R haystack, R[] needles)
{
    // TODO Return some clever lazy range that calls each possible haystack.findFirstOfAnyInOrder(needles);
    return typeof(return).init;
}

/** Return true if all arguments $(D args) are strictly ordered,
    that is args[0] < args[1] < args[2] < ... .
    See also: http://forum.dlang.org/thread/wzsdhzycwqyrvqmmttix@forum.dlang.org?page=2#post-vprvhifglfegnlvzqmjj:40forum.dlang.org
*/
bool areStrictlyOrdered(T...)(T args)
{
    static assert(args.length >= 2,
                  "Only sense in calling this function with 2 arguments.");
    foreach (i, arg; args[1..$])
    {
        if (args[i] >= arg)
        {
            return false;
        }
    }
    return true;
}

unittest
{
    static assert(!__traits(compiles, areStrictlyOrdered()));
    static assert(!__traits(compiles, areStrictlyOrdered(1)));
    assert(areStrictlyOrdered(1, 2, 3));
    assert(!areStrictlyOrdered(1, 3, 2));
    assert(!areStrictlyOrdered(1, 2, 2));
    assert(areStrictlyOrdered('a', 'b', 'c'));
}

/** Return true if all arguments $(D args) are unstrictly ordered,
    that is args[0] <= args[1] <= args[2] <= ... .
    See also: http://forum.dlang.org/thread/wzsdhzycwqyrvqmmttix@forum.dlang.org?page=2#post-vprvhifglfegnlvzqmjj:40forum.dlang.org
*/
bool areUnstrictlyOrdered(T...)(T args)
{
    static assert(args.length >= 2,
                  "Only sense in calling this function with 2 arguments.");
    foreach (i, arg; args[1..$])
    {
        if (args[i] > arg)
        {
            return false;
        }
    }
    return true;
}

unittest
{
    static assert(!__traits(compiles, areUnstrictlyOrdered()));
    static assert(!__traits(compiles, areUnstrictlyOrdered(1)));
    assert(areUnstrictlyOrdered(1, 2, 2, 3));
    assert(!areUnstrictlyOrdered(1, 3, 2));
    assert(areUnstrictlyOrdered('a', 'b', 'c'));
}

import core.checkedint: addu, subu, mulu;

alias sadd = addu;
alias ssub = subu;
alias smul = mulu;

/** Append Arguments $(args) to $(D data).
    TODO Add support for other Random Access Ranges such as std.container.Array
    See also: http://forum.dlang.org/thread/mevnosveagdiswkxtbrv@forum.dlang.org?page=1
 */
ref R append(R, Args...)(ref R data,
                         auto ref Args args) if (args.length >= 1
                                                 //  && isRandomAccessRange!R
                             )
{
    alias T = ElementType!R;

    import std.traits: isAssignable;
    enum isElementType(E) = isAssignable!(T, E);

    import std.typetuple : allSatisfy;

    static if (args.length == 1)
    {
        data ~= args[0];     // inlined
    }
    else static if (allSatisfy!(isElementType, Args))
    {
        data.length += args.length;
        foreach (i, arg; args)
        {
            data[$ - args.length + i] = arg;
        }
    }
    else
    {
        static size_t estimateLength(Args args)
        {
            size_t result;
            import std.traits: isArray;
            foreach (arg; args)
            {
                alias A = typeof(arg);
                static if (isArray!A &&
                           is(T == ElementType!A) &&
                           hasLength!A)
                {
                    result += arg.length;
                }
                else
                {
                    result += 1;
                }
            }
            // import std.stdio;
            // writeln(args, " : ", result);
            return result;
        }

        import std.range: appender;
        auto app = appender!(R)(data);

        app.reserve(data.length + estimateLength(args));

        foreach (arg; args)
        {
            app.put(arg);
        }
        data = app.data;
    }

    return data;
}

unittest
{
    int[] data;
    import std.range: only, iota;

    data.append(-1, 0, only(1, 2, 3), iota(4, 9));
    assert(data == [-1, 0, 1, 2, 3, 4, 5, 6, 7, 8]);

    data.append(9, 10);
    assert(data == [-1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);

    data.append([11, 12], [13, 14]);
    assert(data == [-1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]);

    // int[3] d;
    // data.append(d, d);

    static assert(!__traits(compiles, { data.append(); }));
}

unittest
{
    import std.container: Array;
    import std.algorithm: equal;

    Array!int data;

    data.append(-1);
    assert(equal(data[], [-1]));

    static assert(!__traits(compiles, { data.append(); }));
}

static if (__VERSION__ >= 2067)
{
    import std.algorithm: aggregate;
}
else
{
    template aggregate(funcs...)
    {

        import std.algorithm.comparison : max, min;
        import std.algorithm.iteration: map, reduce;
        auto aggregate(RoR)(RoR ror)
        {
            return ror.map!(reduce!funcs);
        }
    }

    unittest
    {
        import std.algorithm.iteration;
        import std.algorithm.comparison: equal;
        import std.typecons: tuple;
        assert(equal([293, 453, 600, 929, 339, 812, 222, 680, 529, 768].groupBy!(a => a & 1)
                                                                       .aggregate!(max,min),
                     [tuple(453, 293),
                      tuple(600, 600),
                      tuple(929, 339),
                      tuple(812, 222),
                      tuple(529, 529),
                      tuple(768, 768)]));
    }
}
