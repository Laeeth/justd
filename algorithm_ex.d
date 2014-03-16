#!/usr/bin/env rdmd-dev-module

/** Extensions to std.algorithm.
    Copyright: Per Nordlöw 2014-.
    License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
    Authors: $(WEB Per Nordlöw)
 */
module algorithm_ex;

import std.algorithm: reduce, min, max;
import std.typetuple: templateAnd, TypeTuple;
import std.traits: isArray, Unqual, isIntegral, CommonType, isIterable, isStaticArray, isFloatingPoint;
import std.range: ElementType, isInputRange, isBidirectionalRange;
import dbg;
import traits_ex: isStruct, isClass, allSame;

/* version = print; */

// ==============================================================================================

/** Static Iota.
    TODO: Make use of staticIota when it gets available in Phobos.
*/
template siota(size_t from, size_t to) { alias siotaImpl!(to-1, from) siota; }
private template siotaImpl(size_t to, size_t now) {
    static if (now >= to) { alias TypeTuple!(now) siotaImpl; }
    else                  { alias TypeTuple!(now, siotaImpl!(to, now+1)) siotaImpl; }
}

// ==============================================================================================

string typestringof(T)(T a) @safe pure nothrow { return T.stringof; }

// ==============================================================================================

/** Returns: First Argument (element of $(D a)) whose implicit conversion to
    bool is true.

    Similar to behaviour of Lisps (or a...).
    TODO: Is inout Conversion!T the correct return value?
*/
CommonType!T either(T...)(T a) @safe pure nothrow if (a.length >= 1)
{
    static if (T.length == 1) {
        return a[0];
    } else {
        return a[0] ? a[0] : either(a[1 .. $]); // recurse
    }
}
/** This overload enables, when possible, lvalue return. */
auto ref either(T...)(ref T a) @safe pure nothrow if (a.length >= 1 && allSame!T)
{
    static if (T.length == 1) {
        return a[0];
    } else {
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

/** Returns: Last Argument if all arguments implicitly bool-convert to true.
    Similar to behaviour of Lisps (and a...).
    TODO: Is inout Conversion!T the correct return value?
*/
CommonType!T every(T...)(T a) @safe pure nothrow if (a.length >= 1) {
    static if (T.length == 1) {
        return a[0];
    } else {
        return a[0] ? every(a[1 .. $]) : a[0]; // recurse
    }
}
/** This overload enables, when possible, lvalue return. */
auto ref every(T...)(ref T a) @safe pure nothrow if (a.length >= 1 && allSame!T) {
    static if (T.length == 1) {
        return a[0];
    } else {
        return a[0] ? every(a[1 .. $]) : a[0]; // recurse
    }
}
alias and = every;
unittest {
    immutable p = 1, q = 2;
    assert(every(p, q) == 2);

    assert(every(3) == 3);
    assert(every(3, 4) == 4);
    assert(every(0, 4) == 0);
    assert(every(0, 0) == 0);
    assert(every([0, 1], [1, 2]) == [1, 2]);
    assert(every([0, 1], [1]) == [1]);
    assert(every("a", "b") == "b");
    assert(every("", "b") == "b");
    assert(every(cast(string)null, "b") == cast(string)null);

    int x = 1, y = 2;
    every(x, y) = 3;
    assert(x == 1);
    assert(y == 3);
}

// ==============================================================================================

/** Returns: Minimum Element in $(D range). TODO: Add to Phobos? */
auto minElement(alias F = min, R)(in R range)
    @safe pure nothrow if (isInputRange!R)
{
    alias E = ElementType!R;
    return reduce!F(E.max, range);
}
alias smallest = minElement;
unittest { assert([1, 2, 3].minElement == 1); }

/** Returns: Maximum Element in X. TODO: Add to Phobos? */
auto maxElement(alias F = max, R)(in R range)
    @safe pure nothrow if (isInputRange!R)
{
    alias E = ElementType!R;
    return reduce!F(E.min, range);
}
alias largest = maxElement;
unittest { assert([1, 2, 3].maxElement == 3); }

// ==============================================================================================

/** Returns: true if all elements in range are equal (or range is empty).
    http://stackoverflow.com/questions/19258556/equality-of-all-elements-in-a-range/19292822?noredirect=1#19292822 */
bool allEqual(R)(R range) @safe pure nothrow if (isInputRange!R) {
    import std.algorithm: findAdjacent;
    import std.range: empty;
    return range.findAdjacent!("a != b").empty;
}
unittest { assert([11, 11].allEqual); }
unittest { assert(![11, 12].allEqual); }
unittest { int[] x; assert(x.allEqual); }

bool allEqualTo(R, E)(R range, E element) @safe pure nothrow if (isInputRange!R) {
    import std.algorithm: all;
    return range.all!(a => a == element);
}
unittest { assert([42, 42].allEqualTo(42)); }

// ==============================================================================================

/** Check if all Elements of $(D x) are zero. */
bool allZero(T, bool useStatic = true)(in T x) @safe pure nothrow { // TODO: Extend to support struct's and classes's'
    static        if (isStruct!T || isClass!T) {
        foreach (const ref elt; x.tupleof) {
            if (!elt.allZero) { return false; }
        }
        return true;
    } else static        if (useStatic && isStaticArray!T) {
        foreach (ix; siota!(0, x.length)) {
            if (!x[ix].allZero) { return false; } // make use of siota?
        }
        return true;
    } else static if (isIterable!T) {
        foreach (const ref elt; x) {
            if (!elt.allZero) { return false; }
        }
        return true;
    } else {
        return x == 0;
    }
}
alias zeroed = allZero;
unittest {
    ubyte[20] d;
    assert(d.allZero);     // note that [] is needed here

    ubyte[2][2] zeros = [ [0, 0],
                          [0, 0] ];
    assert(zeros.allZero);

    ubyte[2][2] one = [ [0, 1],
                        [0, 0] ];
    assert(!one.allZero);

    ubyte[2][2] ones = [ [1, 1],
                         [1, 1] ];
    assert(!ones.allZero);

    ubyte[2][2][2] zeros3d = [ [ [0, 0],
                                 [0, 0] ],
                               [ [0, 0],
                                 [0, 0] ] ];
    assert(zeros3d.allZero);

    ubyte[2][2][2] ones3d = [ [ [1, 1],
                                [1, 1] ],
                              [ [1, 1],
                                [1, 1] ] ];
    assert(!ones3d.allZero);
}

unittest {
    struct Vec { real x, y; }
    const v0 = Vec(0, 0);
    assert(v0.zeroed);
    const v1 = Vec(1, 1);
    assert(!v1.zeroed);
}

unittest {
    class Vec {
        this(real x, real y) { this.x = x; this.y = y; }
        real x, y;
    }
    const v0 = new Vec(0, 0);
    assert(v0.zeroed);
    const v1 = new Vec(1, 1);
    assert(!v1.zeroed);
}

// ==============================================================================================

/** Returns: true iff $(D a) has a value containing meaning information. */
bool hasContents(T)(T a) @safe pure nothrow {
    static if (isArray!T || isSomeString!T) {
        return cast(bool)a.length; // see: http://stackoverflow.com/questions/18563414/empty-string-should-implicit-convert-to-bool-true/18566334?noredirect=1#18566334
    } else {
        return cast(bool)a;
    }
}

/** Returns: true if $(D a) is set to the default value of its type $(D T),
    false otherwise. */
bool defaulted(T)(T x) @safe pure nothrow { return x == T.init; }
alias untouched = defaulted;

import rational: Rational;

/** Reset $(D a) to its default value. */
auto ref reset(T)(ref T a) @property @trusted pure nothrow { return a = T.init; }
unittest {
    int x = 42;
    x.reset;
    assert(x == x.init);
}

// ==============================================================================================

/** Returns: Number of Default-Initialized (Zero) Elements in $(D x) at
    recursion depth $(D depth).
*/
Rational!ulong sparseness(T)(in T x, int depth = -1) @safe pure nothrow {
    alias R = typeof(return); // rational shorthand
    static if (isIterable!T) {
        import std.range: empty;
        immutable isEmpty = x.empty;
        if (isEmpty || depth == 0) {
            return R(isEmpty, 1);
        } else {
            immutable nextDepth = (depth == -1 ? depth : depth - 1);
            ulong nums, denoms;
            foreach (const ref elt; x) {
                auto sub = elt.sparseness(nextDepth);
                nums += sub.numerator;
                denoms += sub.denominator;
            }
            return R(nums, denoms);
        }
    } else static if (isFloatingPoint!T) {
        return R(x == 0, 1); // explicit zero because T.init is nan here
    } else {
        return R(x.defaulted, 1);
    }
}
unittest {
    assert(1.sparseness == 0);
    assert(0.sparseness == 1);
    assert(0.0.sparseness == 1);
    assert(0.1.sparseness == 0);
    assert(0.0f.sparseness == 1);
    assert(0.1f.sparseness == 0);
    alias Q = Rational!ulong;
    { immutable ubyte[3]    x  = [1, 2, 3];    assert(x[].sparseness == Q(0, 3)); }
    { immutable float[3]    x  = [1, 2, 3];    assert(x[].sparseness == Q(0, 3)); }
    { immutable ubyte[2][2] x  = [0, 1, 0, 1]; assert(x[].sparseness == Q(2, 4)); }
    immutable ubyte[2][2] x22z = [0, 0, 0, 0]; assert(x22z[].sparseness == Q(4, 4));
    assert("".sparseness == 1); // TODO: Is this correct?
    assert(null.sparseness == 1);
}

/** Returns: Number of Non-Zero Elements in $(D range). */
auto denseness(T)(in T x, int recurseDepth = -1) @safe pure nothrow {
    return 1 - x.sparseness(recurseDepth);
}
unittest {
    immutable float[3] f = [1, 2, 3];
    alias Q = Rational!ulong;
    assert(f[].denseness == Q(3, 3));
    assert(f.denseness == Q(3, 3));
}

// ==============================================================================================

bool isSymbol(T)(T a) @safe pure nothrow {
    import std.ascii: isAlpha;
    return a.isAlpha || a == '_';
}

enum FindContext { inWord, inSymbol,
                   asWord, asSymbol }

bool isSymbolASCII(string rest, ptrdiff_t off, size_t end) @safe pure nothrow
in {
    assert(end <= rest.length);
} body {
    import std.ascii: isAlphaNum;
    return ((off == 0 || // either beginning of line
             !rest[off - 1].isAlphaNum &&
             rest[off - 1] != '_') &&
            (end == rest.length || // either end of line
             !rest[end].isAlphaNum &&
             rest[end] != '_'));
}
unittest {
    assert(isSymbolASCII("alpha", 0, 5));
    assert(isSymbolASCII(" alpha ", 1, 6));
    assert(!isSymbolASCII("driver", 0, 5));
    assert(!isSymbolASCII("a_word", 0, 1));
    assert(!isSymbolASCII("first_a_word", 6, 7));
}

// ==============================================================================================

bool isWordASCII(string rest, ptrdiff_t off, size_t end) @safe pure nothrow
in {
    assert(end <= rest.length);
} body {
    import std.ascii: isAlphaNum;
    return ((off == 0 || // either beginning of line
             !rest[off - 1].isAlphaNum) &&
            (end == rest.length || // either end of line
             !rest[end].isAlphaNum));
}
unittest {
    assert(isSymbolASCII("alpha", 0, 5));
    assert(isSymbolASCII(" alpha ", 1, 6));
    assert(!isSymbolASCII("driver", 0, 5));
    assert(isWordASCII("a_word", 0, 1));
    assert(isWordASCII("first_a_word", 6, 7));
    assert(isWordASCII("first_a", 6, 7));
}

import std.typecons: Tuple, tuple;
import std.string: CaseSensitive;

// ==============================================================================================

// Parameterize on isAlpha and isSymbol.

/** Find $(D needle) as Word or Symbol Acronym at $(D haystackOffset) in $(D haystack).
 */
Tuple!(R, ptrdiff_t[]) findAcronymAt(alias pred = "a == b", R, E)(R haystack, E needle,
                                                                  FindContext ctx = FindContext.inWord,
                                                                  CaseSensitive cs = CaseSensitive.yes,
                                                                  size_t haystackOffset = 0) @safe pure {
    import std.ascii: isAlpha;
    import std.algorithm: find;
    import std.range: empty;

    auto aOffs = new ptrdiff_t[needle.length]; // acronym hit offsets

    auto rest = haystack[haystackOffset..$];
    while (needle.length <= rest.length) { // for each new try at finding the needle at remainding part of haystack
        /* debug dln(needle, ", ", rest); */

        // find first character
        size_t nIx = 0;         // needle index
        rest = rest.find!pred(needle[nIx]); // reuse std.algorithm: find!
        if (rest.empty) { return tuple(rest, ptrdiff_t[].init); } // degenerate case
        aOffs[nIx++] = rest.ptr - haystack.ptr; // store hit offset and advance acronym
        rest = rest[1 .. $];
        const ix0 = aOffs[0];

        // check context before point
        final switch (ctx) {
        case FindContext.inWord:   break; // TODO: find word characters before point and set start offset
        case FindContext.inSymbol: break; // TODO: find symbol characters before point and set start offset
        case FindContext.asWord:
            if (ix0 >= 1 && haystack[ix0-1].isAlpha) { goto miss; } // quit if not word start
            break;
        case FindContext.asSymbol:
            if (ix0 >= 1 && haystack[ix0-1].isSymbol) { goto miss; } // quit if not symbol stat
            break;
        }

        while (rest) {          // while elements left in haystack

            // Check elements in between
            ptrdiff_t hit = -1;
            import std.algorithm: countUntil;
            import std.functional: binaryFun;
            final switch (ctx) {
            case FindContext.inWord:
            case FindContext.asWord:
                hit = rest.countUntil!(x => (binaryFun!pred(x, needle[nIx])) || !x.isAlpha); break;
            case FindContext.inSymbol:
            case FindContext.asSymbol:
                hit = rest.countUntil!(x => (binaryFun!pred(x, needle[nIx])) || !x.isSymbol); break;
            }
            if (hit == -1) { goto miss; } // no hit this time

            // Check if hit
            if (hit == rest.length || // if we searched till the end
                rest[hit] != needle[nIx]) { // acronym letter not found
                rest = haystack[aOffs[0]+1 .. $]; // try beyond hit
                goto miss;      // no hit this time
            }

            aOffs[nIx++] = (rest.ptr - haystack.ptr) + hit; // store hit offset and advance acronym
            if (nIx == needle.length) { // if complete acronym found
                return tuple(haystack[aOffs[0] .. aOffs[$-1] + 1], aOffs) ; // return its length
            }
            rest = rest[hit+1 .. $]; // advance in source beyound hit
        }
        miss:
        continue;
    }
    return tuple(R.init, ptrdiff_t[].init); // no hit
}
unittest {
    assert("size_t".findAcronymAt("sz_t", FindContext.inWord)[0] == "size_t");
    assert("size_t".findAcronymAt("sz_t", FindContext.inSymbol)[0] == "size_t");
    assert("åäö_ab".findAcronymAt("ab")[0] == "ab");
    assert("fopen".findAcronymAt("fpn")[0] == "fopen");
    assert("fopen_".findAcronymAt("fpn")[0] == "fopen");
    assert("_fopen".findAcronymAt("fpn", FindContext.inWord)[0] == "fopen");
    assert("_fopen".findAcronymAt("fpn", FindContext.inSymbol)[0] == "fopen");
    assert("f_open".findAcronymAt("fpn", FindContext.inWord)[0] == []);
    assert("f_open".findAcronymAt("fpn", FindContext.inSymbol)[0] == "f_open");
}

import std.algorithm: find;

/** Find $(D needles) In Order in $(D haystack). */
auto findInOrder(alias pred = "a == b",
                 alias finder = find, R, E...)(R haystack, E needles) @trusted pure nothrow {
    import std.range: empty;
    auto hit = haystack; // reference
    foreach (needle; needles) { // for every needle in order
        hit = finder!pred(hit, needle);
        if (hit.empty) {
            break;
        }
    }
    return hit;
}
unittest {
    import std.range: empty;
    assert("a b c".findInOrder("a", "b", "c"));
    assert("b a".findInOrder("a", "b").empty);
}

/** Returns: Slice Overlap of $(D a) and $(D b) in order given by arguments. */
inout(T[]) overlapInOrder(T)(inout(T[]) a,
                             inout(T[]) b) @trusted pure nothrow {
    if (a.ptr <= b.ptr &&       // if a-start lies at or before b-start
        b.ptr < a.ptr + a.length) { // if b-start lies before b-end
        import std.algorithm: min, max;
        const low = max(a.ptr, b.ptr) - a.ptr;
        const n = min(b.length,
                      (b.ptr - a.ptr + 1)); // overlap length
        return a[low..low + n];
    } else {
        return [];
    }
}

/** Returns: Slice Overlap of $(D a) and $(D b) in any order. */
inout(T[]) overlap(T)(inout(T[]) a,
                      inout(T[]) b) @safe pure nothrow {
    if        (inout(T[]) ab = overlapInOrder(a, b)) {
        return ab;
    } else if (inout(T[]) ba = overlapInOrder(b, a)) {
        return ba;
    } else {
        return [];
    }
}
unittest {
    auto x = [-11111, 11, 22, 333333];
    auto y = [-22222, 441, 555, 66];

    assert(!overlap(x, y));
    assert(!overlap(y, x));

    auto x01 = x[0..1];
    auto x12 = x[1..2];
    auto x23 = x[2..3];
    auto x34 = x[3..4];

    // sub-ranges should overlap completely
    assert(overlap(x, x12) == x12);
    assert(overlap(x, x01) == x01);
    assert(overlap(x, x23) == x23);
    // and commutate f(a,b) == f(b,a)
    assert(overlap(x01, x) == x01);
    assert(overlap(x12, x) == x12);
    assert(overlap(x23, x) == x23);
}

/** Returns: If range is a palindrome.
    See also: https://stackoverflow.com/questions/21849580/equality-operator-in-favour-of-std-range-equal
    */
bool isPalindrome(R)(R range) @safe pure /* nothrow */ if (isBidirectionalRange!(R)) {
    import std.range: retro;
    import std.algorithm: equal;
    return range.retro.equal(range);
}
unittest {
    assert(isPalindrome("dallassallad"));
    assert(!isPalindrome("ab"));
    assert(isPalindrome("a"));
    assert(isPalindrome(""));
}

/* ref Unqual!T unqual(T)(in T x) pure nothrow if isStuct!T { return cast(Unqual!T)x; } */
/* unittest { */
/*     const int x; */
/*     unqual(x) = 1; */
/* } */

enum Reduction {
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
    auto ref op(T)(T a, T b) @safe pure nothrow {
        static      if (reduction == Reduction.forwardDifference)  return b - a; // TODO: final static switch
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

unittest {
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

unittest {
    immutable i = [1, 4, 9, 17];
    assert(i.windowedReduce!(Reduction.forwardDifference).equal ([+3, +5, +8]));
    assert(i.windowedReduce!(Reduction.backwardDifference).equal([-3, -5, -8]));
    assert(i.windowedReduce!(Reduction.sum).equal ([+5, +13, +26]));
    assert([1].windowedReduce.empty);
    version(print) dln(i.windowedReduce!(Reduction.sum));
}

/* TODO: Assert that ElementType!R only value semantics.  */
auto ref packBitParallelRunLengths(R)(in R x) if (isInputRange!R)
{
    import std.bitmanip: BitArray, bt;
    alias E = ElementType!R; // element type
    enum nBits = 8*E.sizeof;

    BitArray[nBits] runs;

    // allocate runs
    foreach (ref run; runs) {
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

    size_t[nBits] counts;

    import bitset: BitSet;
    foreach (eltIx, elt; x) {
        BitSet!nBits bits;
        foreach (bitIndex; 0..nBits) {
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
    // dln(xPacked);
}

/** Compute Forward Difference of $(D range).

    TODO: Is there a difference between whether R r is immutable, const or
    mutable?

    See also: https://stackoverflow.com/questions/21004944/forward-difference-algorithm
    See also: http://forum.dlang.org/thread/ujouqtqeehkegmtaxebg@forum.dlang.org#post-lczzsypupcfigttghkwx:40forum.dlang.org
    See also: http://rosettacode.org/wiki/Forward_difference#D
*/
auto forwardDifference(R)(R r)
    pure nothrow if (isInputRange!R)
{
    import std.range: front, empty, popFront;

    struct ForwardDifference
    {
        R _range;
        alias E = ElementType!R;
        typeof(_range.front - _range.front) _front;
        bool _initialized = false;

        /* @safe nothrow: */

        this(R range) pure {
            this._range = range;
        }

        @property:

        auto ref front() {
            if (!_initialized) { popFront(); }
            return _front;
        }

        auto ref moveFront() {
            popFront();
            return _front;
        }

        void popFront() {
            if (empty is false) {
                _initialized = true;
                E rf = _range.front;
                _range.popFront();
                if (_range.empty is false)
                {
                    _front = _range.front - rf;
                }
            }
        }

        bool empty() { return _range.empty; }
    }

    return ForwardDifference(r);
}

import std.algorithm: equal;

/** Pack $(D r) using a forwardDifference. */
auto packForwardDifference(R)(R r) /* @safe */ pure /* nothrow */ if (isInputRange!R)
{
    import std.range: front;
    return tuple(r.front, forwardDifference(r));
}

unittest {
    // source
    auto x = [int.min, 1, 4, 9, 17, int.max];

    import std.array: array;
    import std.traits: Unqual;
    import std.range: ElementType;

    // difference
    alias E = Unqual!(ElementType!(typeof(x)));
    auto d = x[0] ~ x[].forwardDifference.array;

    // restored source
    auto y = new E[x.length];
    y[0] = x[0];
    foreach (ix; 0..x.length - 1) {
        y[ix + 1] = y[ix] + d[ix + 1];
    }

    assert(x[] == y[]);
}

import std.traits: isCallable, ReturnType, arity, ParameterTypeTuple;
import traits_ex: arityMin0;

/** Create Range of Elements Generated by $(D fun).

    Use for example to generate random instances of return value of fun.

    TODO: I believe we need arityMin, arityMax trait here
 */
auto apply(alias fun, N)(N n) if (isCallable!fun &&
                                  arityMin0!fun &&
                                  !is(ReturnType!fun == void) &&
                                  isIntegral!N)
{
    import std.range: iota, map;
    return n.iota.map!(n => fun);
}

unittest {
    import std.datetime: Clock, SysTime, Duration;
    import std.algorithm: map;
    import msgpack;
    import std.array: array;

    const n = 3;
    auto times = n.apply!(Clock.currTime).array;
    dln(times);

    auto spans = times.forwardDifference;
    dln(spans);
}

// ==============================================================================================

/** In Place Ordering (in Sorted Order) of all Elements $(D t).
    See also: https://stackoverflow.com/questions/21102646/in-place-ordering-of-elements/
    See also: http://forum.dlang.org/thread/eweortsmcmibppmvtriw@forum.dlang.org#post-eweortsmcmibppmvtriw:40forum.dlang.org
*/
void orderInPlace(T...)(ref T t) @trusted /* nothrow */ {
    import std.algorithm: sort, swap;
    static if (t.length == 2) {
        if (t[0] > t[1]) {
            swap(t[0], t[1]);
        }
    }
    else {                      // generic version
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
    auto sort(Arr)(ref Arr arr) if (isStaticArray!Arr) {
        return stdSort!(less, ss)(arr[]);
    }
    auto sort(Range)(Range r) if (!isStaticArray!Range) {
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

// ==============================================================================================

/** Execute Expression $(D exp) the same way $(D n) times. */
void dotimes(uint n, lazy void expression) { while (n--) expression(); }
alias loop = dotimes;

/** Execute Expression $(D exp) $(I inline) the same way $(D n) times. */
void static_dotimes(uint n)(lazy void expression) { // TOREVIEW: Should we use delegate instead?
    foreach (i; siota(0, n)) expression();
}

private string genNaryFun(string fun, V...)() @safe pure {
    string code;
    import std.format: format;
    foreach (n, v; V)
        code ~= "alias values[%d] %s;".format(n, cast(char)('a'+n));
    code ~= "return " ~ fun ~ ";";
    return code;
}
template naryFun(string fun) {
    auto naryFun(V...)(V values) {
        mixin(genNaryFun!(fun, V));
    }
}
unittest {
    alias naryFun!"a + b + c" test;
    assert(test(1, 2, 3) == 6);
}

import std.typetuple : allSatisfy;

/** Zip $(D ranges) together with operation $(D fun).
   TODO: Remove when Issue 8715 is fixed providing zipWith
 */
auto zipWith(alias fun, Ranges...)(Ranges ranges) @safe pure nothrow if (Ranges.length >= 2 &&
									 allSatisfy!(isInputRange, Ranges)) {
    import std.range: zip;
    import std.algorithm: map;
    import std.functional: binaryFun;
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

alias Pair(T, U) = Tuple!(T, U);

/** Instantiator for \c Pair. */
auto pair(T, U)(in T t, in U u) { return Pair!(T, U)(t, u); }

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
    /* dln(x); */
}

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

bool areColinear(T)(T a, T b) @safe pure nothrow
{
    // a and b are colinear if a.x / a.y == b.x / b.y
    // We can avoid the division by multiplying out.
    return a.x * b.y == a.y * b.x;
}

/* /\** TODO: Remove when each is standard in Phobos. *\/ */
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
auto clamp(T, TLow, THigh)(T x, TLow lower, THigh upper) @safe pure nothrow
in {
    assert(lower <= upper, "lower > upper");
}
body {
    import std.algorithm : min, max;
    return min(max(x, lower), upper);
}

alias saturate = clamp;

unittest {
    assert((-1).clamp(0, 2) == 0);
    assert(0.clamp(0, 2) == 0);
    assert(1.clamp(0, 2) == 1);
    assert(2.clamp(0, 2) == 2);
    assert(3.clamp(0, 2) == 2);
}

// ==============================================================================================

template isIntLike(T) {
    enum isIntLike = is(typeof({
		T t = 0;
		t = t+t;
		// More if needed
            }));
}

/** $(LUCKY Fibonacci) Numbers (Infinite Range).
    See also: http://forum.dlang.org/thread/dqlrfoxzsppylcgljyyf@forum.dlang.org#post-mailman.1072.1350619455.5162.digitalmars-d-learn:40puremagic.com
 */
auto fibonacci(T = int)() if (isIntLike!T)
{
    struct Fibonacci {
        T a, b;
        T front() { return b; }
        bool empty() { return false; }
        void popFront() {
            T c = a+b;
            a = b;
            b = c;
        }
    }
    return Fibonacci(0, 1);
}

unittest
{
    import dbg:dln;
    import std.range: take, equal;
    assert(fibonacci.take(10).equal([1, 1, 2, 3, 5, 8, 13, 21, 34, 55]));
}
