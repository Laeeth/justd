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
    T opCast(U : T)() const { return _ix; }
    private T _ix = 0;
}

import std.traits: isUnsigned, isInstanceOf;
import std.range: hasSlicing;

enum IndexableBy(R, I) = (hasSlicing!R &&
                          (isUnsigned!I || // TODO should we allow isUnsigned here?
                           isInstanceOf!(Index, I) ||
                           is(I == enum)));

/** Wrapper for $(D R) with Type-Safe $(D I)-Indexing.
    See also: http://forum.dlang.org/thread/gayfjaslyairnzrygbvh@forum.dlang.org#post-gayfjaslyairnzrygbvh:40forum.dlang.org
    TODO Support indexing by tuples
    TODO Use std.range.indexed when I is an enum with non-contigious enumerators
    TODO Rename to By, by?!
   */
struct IndexedBy(R, I) if (IndexableBy!(R, I))
{
    auto ref opIndex(I i)      inout { return _r[cast(size_t)i]; }
    auto ref opSlice(I i, I j) inout { return _r[cast(size_t)i ..
                                                 cast(size_t)j]; }

    auto ref opIndexAssign(V)(V value, I i)      { return _r[cast(size_t)i] = value; }
    auto ref opSliceAssign(V)(V value, I i, I j) { return _r[cast(size_t)i ..
                                                             cast(size_t)j] = value; }

    // TODO is this needed?
    // alias RI = size_t; /* TODO: Extract this from R somehow. */
    // static if (!is(RI == I))
    // {
    //     @disable void opIndex(RI i);
    //     @disable void opIndexAssign(V)(V value, RI i);
    //     @disable void opSlice(RI i, RI j);
    //     @disable void opSliceAssign(V)(V value, RI i, RI j);
    // }

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

    alias J = Index!size_t;
    enum E { e0, e1, e2 }

    with (E)
    {
        auto xb = x.indexedBy!ubyte;
        auto xi = x.indexedBy!uint;
        auto xj = x.indexedBy!J;
        auto xe = x.indexedBy!E;

        // indexing with correct type
        xb[  0 ] = 11; assert(xb[  0 ] == 11);
        xi[  0 ] = 11; assert(xi[  0 ] == 11);
        xj[J(0)] = 11; assert(xj[J(0)] == 11);
        xe[ e0 ] = 11; assert(xe[ e0 ] == 11);

        // slicing with correct type
        xb[  0  ..   1 ] = 12; assert(xb[  0  ..   1 ] == [12]);
        xi[  0  ..   1 ] = 12; assert(xi[  0  ..   1 ] == [12]);
        xj[J(0) .. J(1)] = 12; assert(xj[J(0) .. J(1)] == [12]);
        xe[ e0  ..  e1 ] = 12; assert(xe[ e0  ..  e1 ] == [12]);

        // indexing with wrong type
        static assert(!__traits(compiles, { xb[J(0)] = 11; }));
        static assert(!__traits(compiles, { xi[J(0)] = 11; }));
        static assert(!__traits(compiles, { xj[  0 ] = 11; }));
        static assert(!__traits(compiles, { xe[  0 ] = 11; }));

        // slicing with wrong type
        static assert(!__traits(compiles, { xb[J(0), J(0)] = 11; }));
        static assert(!__traits(compiles, { xi[J(0), J(0)] = 11; }));
        static assert(!__traits(compiles, { xj[  0 ,   0 ] = 11; }));
        static assert(!__traits(compiles, { xe[  0 ,   0 ] = 11; }));

        import std.algorithm: equal;
        import std.algorithm.iteration: filter;

        assert(equal(xb.filter!(a => a < 11), [2, 3]));
        assert(equal(xi.filter!(a => a < 11), [2, 3]));
        assert(equal(xj.filter!(a => a < 11), [2, 3]));
        assert(equal(xe.filter!(a => a < 11), [2, 3]));
    }
}
