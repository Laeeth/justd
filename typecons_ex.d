module typecons_ex;

// TODO Add to Phobos and refer to http://forum.dlang.org/thread/lzyqywovlmdseqgqfvun@forum.dlang.org#post-ibvkvjwexdafpgtsamut:40forum.dlang.org
// TODO Better with?:
/* inout(Nullable!T) nullable(T)(inout T a) */
/* { */
/*     return typeof(return)(a); */
/* } */
/* inout(Nullable!(T, nullValue)) nullable(alias nullValue, T)(inout T value) */
/* if (is (typeof(nullValue) == T)) */
/* { */
/*     return typeof(return)(value); */
/* } */

import std.typecons: Nullable, NullableRef;

/** Instantiator for $(D Nullable).
 */
auto nullable(T)(T a)
{
    return Nullable!T(a);
}
unittest
{
    auto x = 42.5.nullable;
    assert(is(typeof(x) == Nullable!double));
}

/** Instantiator for $(D Nullable).
*/
auto nullable(alias nullValue, T)(T value)
    if (is (typeof(nullValue) == T))
{
    return Nullable!(T, nullValue)(value);
}
unittest
{
    auto x = 3.nullable!(int.max);
    assert(is (typeof(x) == Nullable!(int, int.max)));
}

/** Instantiator for $(D NullableRef).
 */
auto nullableRef(T)(T* a) @safe pure nothrow
{
    return NullableRef!T(a);
}
unittest
{
    auto x = 42.5;
    auto xr = nullableRef(&x);
    assert(!xr.isNull);
    xr.nullify;
    assert(xr.isNull);
}

/** See also: http://forum.dlang.org/thread/jwdbjlobbilowlnpdzzo@forum.dlang.org
 */
template New(T) if (is(T == class))
{
    T New(Args...) (Args args) {
        return new T(args);
    }
}

/* unittest */
/* { */
/*     class C { int x, y; } */
/*     assert(New!C == new C); */
/* } */

struct Index(T = size_t)
{
    @safe pure: @nogc nothrow:
    this(T ix) { this._ix = ix; }
    alias _ix this;
    private T _ix = 0;
}

import std.traits: isIntegral, isInstanceOf;
import std.range: hasSlicing;

enum IndexableBy(R, I) = (hasSlicing!R &&
                          (isIntegral!I || // TODO should we allo isIntegral here?
                           isInstanceOf!(Index, I) ||
                           is(I == enum)));

/** Wrapper for $(D R) with Type-Safe $(D I)-Indexing.
    See also: http://forum.dlang.org/thread/gayfjaslyairnzrygbvh@forum.dlang.org#post-gayfjaslyairnzrygbvh:40forum.dlang.org
    TODO Support indexing by tuples
    TODO Use std.range.indexed
   */
struct IndexedBy(R, I) if (IndexableBy!(R, I))
{
    alias RI = size_t; /* TODO: Extract this from R somehow. */

    auto ref opIndex(I ix) inout { return _r[ix]; }
    auto ref opIndexAssign(V)(V value, I ix) { return _r[ix] = value; }

    auto ref opSlice(I lower, I upper) inout { return _r[lower .. upper]; }
    auto ref opSliceAssign(V)(V value, I lower, I upper) { return _r[lower .. upper] = value; }

    static if (!is(RI == I))
    {
        @disable void opIndex(RI i);
        @disable void opIndexAssign(V)(V value, RI i);
        @disable void opSlice(RI i, RI j);
        @disable void opSliceAssign(V)(V value, RI i, RI j);
    }

    R _r;
    alias _r this; // TODO Use opDispatch instead; to override only opSlice and opIndex
}

/** Instantiator for $(D IndexedBy).
   */
auto indexedBy(I, R)(R range) if (IndexableBy!(R, I))
{
    return IndexedBy!(R, I)(range);
}

unittest
{
    import std.algorithm: equal;

    auto x = [1, 2, 3];

    alias I = int;
    alias J = Index!size_t;

    auto ix = x.indexedBy!I;
    auto jx = x.indexedBy!J;

    // indexing with correct type is allowed
    ix[0] = 11;
    assert(ix[0] == 11);

    // slicing with correct type is allowed
    ix[0 .. 1] = 12;
    assert(ix[0] == 12);

    // indexing with correct type is allowed
    jx[J(0)] = 11;
    // TODO assert(jx[J(0)] == 11);
    // TODO assert(equal(jx[0 .. 1], [11, 2, 3]));

    // slicing with correct type is allowed
    jx[J(0) .. J(1)] = 12;
    // TODO assert(jx[J(0)] == 12);

    // indexing with wrong type is disallowed
    static assert(!__traits(compiles, { ix[J(0)] = 11; }));
    static assert(!__traits(compiles, { jx[0] = 11; }));

    // slicing with wrong type is disallowed
    static assert(!__traits(compiles, { ix[J(0), J(0)] = 11; }));
    static assert(!__traits(compiles, { jx[0, 0] = 11; }));

    import std.algorithm: equal;
    import std.algorithm.iteration: filter;

    assert(equal(jx.filter!(a => a < 11), [2, 3]));
}
