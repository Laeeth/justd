#!/usr/bin/env rdmd-dev-module

   /** Extensions to std.algorithm.
       Copyright: Per Nordlöw 2014-.
       License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
       Authors: $(WEB Per Nordlöw)
   */
module algorithm_ex;

import std.algorithm: reduce, min, max;
import std.typetuple: templateAnd, TypeTuple;
import std.traits: isArray, Unqual, isIntegral, CommonType, isIterable, isStaticArray, isFloatingPoint, arity, isSomeString;
import std.range: ElementType, isInputRange, isForwardRange, isBidirectionalRange, isRandomAccessRange, hasSlicing, empty;
import dbg;
import traits_ex: isStruct, isClass, allSame;

/* version = print; */

// ==============================================================================================

/** Static Iota.
    TODO: Make use of staticIota when it gets available in Phobos.
*/
template siota(size_t from, size_t to) { alias siota = siotaImpl!(to-1, from); }
private template siotaImpl(size_t to, size_t now)
{
    static if (now >= to) { alias siotaImpl = TypeTuple!(now); }
    else                  { alias siotaImpl = TypeTuple!(now, siotaImpl!(to, now+1)); }
}

// ==============================================================================================

string typestringof(T)(in T a) @safe @nogc pure nothrow { return T.stringof; }

import std.range: dropOne;
alias tail = dropOne;

// ==============================================================================================

/** Returns: First Argument (element of $(D a)) whose implicit conversion to
    bool is true.

    Similar to behaviour of Lisps (or a...).
    TODO: Is inout Conversion!T the correct return value?
*/
CommonType!T either(T...)(T a) @safe @nogc pure nothrow if (a.length >= 1)
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
/** This overload enables, when possible, lvalue return. */
auto ref either(T...)(ref T a) @safe @nogc pure nothrow if (a.length >= 1 && allSame!T)
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

/** Returns: Last Argument if all arguments implicitly bool-convert to true.
    Similar to behaviour of Lisps (and a...).
    TODO: Is inout Conversion!T the correct return value?
*/
CommonType!T every(T...)(T a) @safe @nogc pure nothrow if (a.length >= 1)
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
/** This overload enables, when possible, lvalue return.
    TODO: Only last argument needs to be an l-value.
*/
auto ref every(T...)(ref T a) @safe @nogc pure nothrow if (a.length >= 1 && allSame!T)
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

/** Returns: true iff all elements in range are equal (or range is empty).
    http://stackoverflow.com/questions/19258556/equality-of-all-elements-in-a-range/19292822?noredirect=1#19292822

    Possible alternatives or aliases: allElementsEqual, haveEqualElements
*/
bool allEqual(R)(R range) @safe /* @nogc */ pure nothrow if (isInputRange!R)
{
    import std.algorithm: findAdjacent;
    import std.range: empty;
    return range.findAdjacent!("a != b").empty;
}
unittest { assert([11, 11].allEqual); }
unittest { assert(![11, 12].allEqual); }
unittest { int[] x; assert(x.allEqual); }

/* See also: http://forum.dlang.org/thread/febepworacvbapkpozjl@forum.dlang.org#post-gbqvablzsbdowqoijxpn:40forum.dlang.org */
/* import std.range: InputRange; */
/* bool allEqual_(T)(InputRange!T range) @safe pure nothrow */
/* { */
/*     import std.algorithm: findAdjacent; */
/*     import std.range: empty; */
/*     return range.findAdjacent!("a != b").empty; */
/* } */
/* unittest { assert([11, 11].allEqual_); } */
/* unittest { assert(![11, 12].allEqual_); } */
/* unittest { int[] x; assert(x.allEqual_); } */

/** Returns: true iff all elements in range are equal (or range is empty) to $(D element).

    Possible alternatives or aliases: allElementsEqualTo
*/
bool allEqualTo(R, E)(R range, E element) @safe pure nothrow if (isInputRange!R &&
                                                                 is(ElementType!R == E))
{
    import std.algorithm: all;
    return range.all!(a => a == element);
}
unittest { assert([42, 42].allEqualTo(42)); }

// ==============================================================================================

/** Check if all Elements of $(D x) are zero. */
bool allZero(T, bool useStatic = true)(in T x) @safe @nogc pure nothrow // TODO: Extend to support struct's and classes's'
{
    static if (isStruct!T || isClass!T)
    {
        foreach (const ref elt; x.tupleof)
        {
            if (!elt.allZero) { return false; }
        }
        return true;
    }
    else static if (useStatic && isStaticArray!T)
    {
        foreach (ix; siota!(0, x.length))
        {
            if (!x[ix].allZero) { return false; } // make use of siota?
        }
        return true;
    }
    else static if (isIterable!T)
    {
        foreach (const ref elt; x)
        {
            if (!elt.allZero) { return false; }
        }
        return true;
    }
    else
    {
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

/** Returns: true iff $(D a) is set to the default/initial value of its type $(D T).
 */
bool defaulted(T)(in T a) @safe pure nothrow @nogc
{
    static if (isInstanceOf!(Nullable, T))
        return a.isNull;
    else
        return a == T.init;
}
alias untouched = defaulted;
alias inited = defaulted;

import rational: Rational;

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
    assert(n.untouched);
    n = 0;
    assert(!n.untouched);
    assert(n == 0);
    n.reset;
    assert(n.untouched);
}

// ==============================================================================================

/** Returns: Number of Default-Initialized (Zero) Elements in $(D x) at
    recursion depth $(D depth).
*/
Rational!ulong sparseness(T)(in T x, int depth = -1) @safe @nogc pure nothrow
{
    alias R = typeof(return); // rational shorthand
    static if (isIterable!T)
    {
        import std.range: empty;
        immutable isEmpty = x.empty;
        if (isEmpty || depth == 0)
        {
            return R(isEmpty, 1);
        }
        else
        {
            immutable nextDepth = (depth == -1 ? depth : depth - 1);
            ulong nums, denoms;
            foreach (const ref elt; x)
            {
                auto sub = elt.sparseness(nextDepth);
                nums += sub.numerator;
                denoms += sub.denominator;
            }
            return R(nums, denoms);
        }
    }
    else static if (isFloatingPoint!T)
    {
        return R(x == 0, 1); // explicit zero because T.init is nan here
    }
    else
    {
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
auto denseness(T)(in T x, int recurseDepth = -1) @safe @nogc pure nothrow
{
    return 1 - x.sparseness(recurseDepth);
}
unittest {
    immutable float[3] f = [1, 2, 3];
    alias Q = Rational!ulong;
    assert(f[].denseness == Q(3, 3));
    assert(f.denseness == Q(3, 3));
}

// ==============================================================================================

bool isSymbol(T)(in T a) @safe @nogc pure nothrow
{
    import std.ascii: isAlpha;
    return a.isAlpha || a == '_';
}

enum FindContext { inWord, inSymbol,
                   asWord, asSymbol }

bool isSymbolASCII(string rest, ptrdiff_t off, size_t end) @safe @nogc pure nothrow
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

bool isWordASCII(string rest, ptrdiff_t off, size_t end) @safe @nogc pure nothrow
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
    TODO: Make it compatible (specialized) for InputRange or BidirectionalRange.
 */
Tuple!(R, ptrdiff_t[]) findAcronymAt(alias pred = "a == b",
                                     R,
                                     E)(R haystack,
                                        E needle,
                                        FindContext ctx = FindContext.inWord,
                                        CaseSensitive cs = CaseSensitive.yes, // TODO: Use this
                                        size_t haystackOffset = 0) @safe pure
{
    import std.ascii: isAlpha;
    import std.algorithm: find;
    import std.range: empty;

    auto aOffs = new ptrdiff_t[needle.length]; // acronym hit offsets

    auto rest = haystack[haystackOffset..$];
    while (needle.length <= rest.length) // for each new try at finding the needle at remainding part of haystack
    {
        /* debug dln(needle, ", ", rest); */

        // find first character
        size_t nIx = 0;         // needle index
        rest = rest.find!pred(needle[nIx]); // reuse std.algorithm: find!
        if (rest.empty) { return tuple(rest, ptrdiff_t[].init); } // degenerate case
        aOffs[nIx++] = rest.ptr - haystack.ptr; // store hit offset and advance acronym
        rest = rest[1 .. $];
        const ix0 = aOffs[0];

        // check context before point
        final switch (ctx)
        {
        case FindContext.inWord:   break; // TODO: find word characters before point and set start offset
        case FindContext.inSymbol: break; // TODO: find symbol characters before point and set start offset
        case FindContext.asWord:
            if (ix0 >= 1 && haystack[ix0-1].isAlpha) { goto miss; } // quit if not word start
            break;
        case FindContext.asSymbol:
            if (ix0 >= 1 && haystack[ix0-1].isSymbol) { goto miss; } // quit if not symbol stat
            break;
        }

        while (rest)            // while elements left in haystack
        {

            // Check elements in between
            ptrdiff_t hit = -1;
            import std.algorithm: countUntil;
            import std.functional: binaryFun;
            final switch (ctx)
            {
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
                rest[hit] != needle[nIx]) // acronym letter not found
            {
                rest = haystack[aOffs[0]+1 .. $]; // try beyond hit
                goto miss;      // no hit this time
            }

            aOffs[nIx++] = (rest.ptr - haystack.ptr) + hit; // store hit offset and advance acronym
            if (nIx == needle.length) // if complete acronym found
            {
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
                 alias finder = find,
                 R,
                 E...)(R haystack,
                       E needles) @trusted pure nothrow
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
unittest {
    import std.range: empty;
    assert("a b c".findInOrder("a", "b", "c"));
    assert("b a".findInOrder("a", "b").empty);
}

/** Returns: Slice Overlap of $(D a) and $(D b) in order given by arguments.
 */
inout(T[]) overlapInOrder(T)(inout(T[]) a,
                             inout(T[]) b) @trusted pure nothrow
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
                      inout(T[]) b) @safe pure nothrow
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
unittest {
    auto x = [-11_111, 11, 22, 333_333];
    auto y = [-22_222, 441, 555, 66];

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
    auto e = min(r1.ptr + r1.length, r2.ptr + r2.length);
    return b < e;
}

/** Returns: If range is a palindrome.
    See also: https://stackoverflow.com/questions/21849580/equality-operator-in-favour-of-std-range-equal
*/
bool isPalindrome(R)(in R range) @safe pure /* nothrow */ if (isBidirectionalRange!(R))
{
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

/* unittest { */
/*     import std.range: front; */
/*     dln([1].windowedReduce!(Reduction.forwardDifference)); */
/*     dln([1, 22].windowedReduce!(Reduction.forwardDifference)); */
/*     dln([1, 22, 333].windowedReduce!(Reduction.forwardDifference)); */
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
    import std.algorithm: equal;
    assert(i.windowedReduce!(Reduction.forwardDifference).equal ([+3, +5, +8]));
    assert(i.windowedReduce!(Reduction.backwardDifference).equal([-3, -5, -8]));
    assert(i.windowedReduce!(Reduction.sum).equal ([+5, +13, +26]));
    assert([1].windowedReduce.empty);
    version(print) dln(i.windowedReduce!(Reduction.sum));
}

/* TODO: Assert that ElementType!R only value semantics.  */
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

    TODO: Is there a difference between whether R r is immutable, const or
    mutable?

    TODO: If r contains only one element return empty range.

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
        alias D = typeof(_range.front - _range.front); // Element Difference Type. TODO: Use this as ElementType of range
        D _front;
        bool _initialized = false;

        this(R range)
        in { assert(!range.empty); }
        body {
            auto tmp = range;
            if (tmp.dropOne.empty) // TODO: This may be an unneccesary cost but is practical to remove extra logic
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
    b[].sort;
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
        foreach (i; 0 .. n)
            action(i); // use it as action input
    else
        foreach (i; 0 .. n)
            action();
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
    TODO: Remove when Issue 8715 is fixed providing zipWith
*/
auto zipWith(alias fun, Ranges...)(Ranges ranges) @safe pure nothrow if (Ranges.length >= 2 &&
									 allSatisfy!(isInputRange, Ranges))
{
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
static if (__VERSION__ < 2066)
{
    auto clamp(T, TLow, THigh)(T x, TLow lower, THigh upper) @safe pure nothrow
        in {
            assert(lower <= upper, "lower > upper");
        }
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
    } else {
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
    import std.range: map;
    import std.array: array;
    assert(([42].map!str).array == ["42"]);
}

import std.range: InputRange, OutputRange;
alias Source = InputRange;
alias Sink = OutputRange;

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

/** Slicer.
    Enhanced version of std.algorithm.splitter.
    http://forum.dlang.org/thread/qjbmfeukiqvribmdylkl@forum.dlang.org?page=1
    http://dlang.org/library/std/algorithm/splitter.html.
*/
auto slicer(alias isTerminator, Range)(Range input) /* if (((isRandomAccessRange!Range && */
                                                    /*       hasSlicing!Range) || */
                                                    /*      isSomeString!Range) && */
                                                    /*     is(typeof(unaryFun!isTerminator(input.front)))) */
{
    import std.functional: unaryFun;
    return SlicerResult!(unaryFun!isTerminator, Range)(input);
}

private struct SlicerResult(alias isTerminator, Range)
{
    //alias notTerminator = not!isTerminator;

    private Range _input;
    private size_t _end = 0;

    private void findTerminator()
    {
        auto r = _input.save.find!(not!isTerminator).find!isTerminator();
        _end = _input.length - r.length;
    }

    this(Range input)
    {
        _input = input;
        if (_input.empty)
            _end = size_t.max;
        else
            findTerminator();
    }

    import std.range: isInfinite;

    static if (isInfinite!Range)
    {
        enum bool empty = false;  // Propagate infiniteness.
    }
    else
    {
        @property bool empty()
        {
            return _end == size_t.max;
        }
    }

    @property auto front()
    {
        return _input[0 .. _end];
    }

    void popFront()
    {
        _input = _input[_end .. _input.length];
        if (_input.empty)
        {
            _end = size_t.max;
            return;
        }
        findTerminator();
    }

    @property typeof(this) save()
    {
        auto ret = this;
        ret._input = _input.save;
        return ret;
    }
}

version(none)
unittest
{
    import std.string: isUpper;
    "SomeGreatVariableName"  .slicer!isUpper.writeln();
    "someGGGreatVariableName".slicer!isUpper.writeln();
    "".slicer!isUpper.writeln();
    "a".slicer!isUpper.writeln();
    "A".slicer!isUpper.writeln();
}


/* Check if $(D part) is part of $(D whole).
   See also: http://forum.dlang.org/thread/ls9dbk$jkq$1@digitalmars.com
   TODO: Standardize name and remove alises.
   TODO: Use partOf if generalized to InputRange.
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
auto dropWhile(R, E)(R range, E element) if (isInputRange!R &&
                                             is(ElementType!R == E))
{
    import std.algorithm: find;
    return range.find!(a => a != element);
}
alias dropAllOf = dropWhile;
alias stripFront = dropWhile;
alias lstrip = dropWhile;       // Python style

unittest
{
    assert([1, 2, 3].dropWhile(1) == [2, 3]);
    assert([1, 1, 1, 2, 3].dropWhile(1) == [2, 3]);
    assert([1, 2, 3].dropWhile(2) == [1, 2, 3]);
    assert("abc".dropWhile(cast(dchar)'a') == "bc");
}

/* See also: http://forum.dlang.org/thread/cjpplpzdzebfxhyqtskw@forum.dlang.org#post-cjpplpzdzebfxhyqtskw:40forum.dlang.org */
auto takeWhile(R, E)(R range, E element) if (isInputRange!R &&
                                             is(ElementType!R == E))
{
    import std.algorithm: until;
    return range.until!(a => a != element);
}
alias takeAllOf = takeWhile;

unittest
{
    import std.algorithm: equal;
    equal([1, 1, 2, 3].takeWhile(1),
          [1, 1]);
}

/** Simpler Variant of Phobos' findSplit. */
auto findSplit(alias pred, R1)(R1 haystack) if (isForwardRange!R1)
{
    static if (isSomeString!R1 ||
               isRandomAccessRange!R1)
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
    auto x = "aa1bb".findSplit!(a => a.isDigit);
    assert(equal(x[0], "aa"));
    assert(equal(x[1], "1"));
    assert(equal(x[2], "bb"));
}

/** Simpler Variant of Phobos' findSplitBefore. */
auto findSplitBefore(alias pred, R1)(R1 haystack) if (isForwardRange!R1)
{
    static if (isSomeString!R1 ||
               sRandomAccessRange!R1)
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
    auto x = "11ab".findSplitBefore!(a => !a.isDigit);
    assert(equal(x[0], "11"));
    assert(equal(x[1], "ab"));
}
