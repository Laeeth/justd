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

import std.traits: isArray, isUnsigned, isInstanceOf, isSomeString;
import std.range.primitives: hasSlicing;

enum isIndex(I) = (is(I == enum) ||
                   isUnsigned!I || // TODO should we allow isUnsigned here?
                   __traits(compiles, { I i = 0; cast(size_t)i; }));

/** Check if $(D R) is indexable by $(D I). */
enum isIndexableBy(R, I) = (isArray!R &&     // TODO generalize to RandomAccessContainers. Ask on forum for hasIndexing!R.
                            isIndex!I);

unittest
{
    static assert(isIndexableBy!(int[3], ubyte));
}

/** Check if $(D R) is indexable by $(D I). */
enum isIndexableBy(R, alias I) = (isArray!R &&     // TODO generalize to RandomAccessContainers. Ask on forum for hasIndexing!R.
                                  (isSomeString!(typeof(I))));

unittest
{
    static assert(isIndexableBy!(int[], "I"));
}

/** Wrapper for $(D R) with Type-Safe $(D I)-Indexing.
    See also: http://forum.dlang.org/thread/gayfjaslyairnzrygbvh@forum.dlang.org#post-gayfjaslyairnzrygbvh:40forum.dlang.org

    TODO Use std.range.indexed when I is an enum with non-contigious
    enumerators. Perhaps use among aswell.

    TODO Rename to something more concise such as [Bb]y.

    TODO Allow $(D I) to be a string and if so derive $(D Index) to be that string.

    TODO Support R being a static array:
         - If I is an enum its number of elements should match R.length
   */
struct IndexedBy(R, I) if (isIndexableBy!(R, I))
{
    alias Index = I;        /// indexing type

    auto ref opIndex(I i) inout             { return _r[cast(size_t)i]; }
    auto ref opIndexAssign(V)(V value, I i) { return _r[cast(size_t)i] = value; }

    static if (hasSlicing!R)
    {
        auto ref opSlice(I i, I j) inout             { return _r[cast(size_t)i ..
                                                                 cast(size_t)j]; }
        auto ref opSliceAssign(V)(V value, I i, I j) { return _r[cast(size_t)i ..
                                                                 cast(size_t)j] = value; }
    }

    R _r;
    alias _r this; // TODO Use opDispatch instead; to override only opSlice and opIndex
}

/** Instantiator for $(D IndexedBy).
 */
auto indexedBy(I, R)(R range) if (isIndexableBy!(R, I))
{
    return IndexedBy!(R, I)(range);
}

struct IndexedBy(R, string I) if (isArray!R)
{
    mixin(q{ struct } ~ I ~
          q{ {
                  alias T = size_t;
                  this(T ix) { this._ix = ix; }
                  T opCast(U : T)() const { return _ix; }
                  private T _ix = 0;
              }
          });

    auto ref opIndex(I i) inout             { return _r[cast(size_t)i]; }
    auto ref opIndexAssign(V)(V value, I i) { return _r[cast(size_t)i] = value; }

    static if (hasSlicing!R)
    {
        auto ref opSlice(I i, I j) inout             { return _r[cast(size_t)i ..
                                                                 cast(size_t)j]; }
        auto ref opSliceAssign(V)(V value, I i, I j) { return _r[cast(size_t)i ..
                                                                 cast(size_t)j] = value; }
    }

    R _r;
    alias _r this; // TODO Use opDispatch instead; to override only opSlice and opIndex
}

/** Instantiator for $(D IndexedBy).
 */
auto indexedBy(string I, R)(R range) if (isArray!R)
{
    return IndexedBy!(R, I)(range);
}

@safe pure nothrow unittest
{
    int[3] x = [1, 2, 3];

    struct Index(T = size_t) if (isUnsigned!T)
    {
        this(T ix) { this._ix = ix; }
        T opCast(U : T)() const { return _ix; }
        private T _ix = 0;
    }
    alias J = Index!size_t;

    enum E { e0, e1, e2 }

    with (E)
    {
        auto xb = x.indexedBy!ubyte;
        auto xi = x.indexedBy!uint;
        auto xj = x.indexedBy!J;
        auto xe = x.indexedBy!E;

        auto xs = x.indexedBy!"I";
        alias XS = typeof(xs);
        XS xs_;

        // indexing with correct type
        xb[  0 ] = 11; assert(xb[  0 ] == 11);
        xi[  0 ] = 11; assert(xi[  0 ] == 11);
        xj[J(0)] = 11; assert(xj[J(0)] == 11);
        xe[ e0 ] = 11; assert(xe[ e0 ] == 11);
        xs[XS.I(0)] = 11; assert(xs[XS.I(0)] == 11);
        xs_[XS.I(0)] = 11; assert(xs_[XS.I(0)] == 11);

        // indexing with wrong type
        static assert(!__traits(compiles, { xb[J(0)] = 11; }));
        static assert(!__traits(compiles, { xi[J(0)] = 11; }));
        static assert(!__traits(compiles, { xj[  0 ] = 11; }));
        static assert(!__traits(compiles, { xe[  0 ] = 11; }));
        static assert(!__traits(compiles, { xs[  0 ] = 11; }));
        static assert(!__traits(compiles, { xs_[  0 ] = 11; }));

        import std.algorithm.comparison: equal;
        import std.algorithm.iteration: filter;

        assert(equal(xb[].filter!(a => a < 11), [2, 3]));
        assert(equal(xi[].filter!(a => a < 11), [2, 3]));
        assert(equal(xj[].filter!(a => a < 11), [2, 3]));
        assert(equal(xe[].filter!(a => a < 11), [2, 3]));
        assert(equal(xs[].filter!(a => a < 11), [2, 3]));
    }
}

@safe pure nothrow unittest
{
    auto x = [1, 2, 3];

    struct Index(T = size_t) if (isUnsigned!T)
    {
        this(T ix) { this._ix = ix; }
        T opCast(U : T)() const { return _ix; }
        private T _ix = 0;
    }
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
        static assert(!__traits(compiles, { xb[J(0) .. J(0)] = 11; }));
        static assert(!__traits(compiles, { xi[J(0) .. J(0)] = 11; }));
        static assert(!__traits(compiles, { xj[  0  ..   0 ] = 11; }));
        static assert(!__traits(compiles, { xe[  0  ..   0 ] = 11; }));

        import std.algorithm.comparison: equal;
        import std.algorithm.iteration: filter;

        assert(equal(xb.filter!(a => a < 11), [2, 3]));
        assert(equal(xi.filter!(a => a < 11), [2, 3]));
        assert(equal(xj.filter!(a => a < 11), [2, 3]));
        assert(equal(xe.filter!(a => a < 11), [2, 3]));
    }
}

@safe pure nothrow unittest
{
    auto x = [1, 2, 3];
    struct I(T = size_t)
    {
        this(T ix) { this._ix = ix; }
        T opCast(U : T)() const { return _ix; }
        private T _ix = 0;
    }
    alias J = I!size_t;
    auto xj = x.indexedBy!J;
}

@safe pure nothrow unittest
{
    auto x = [1, 2, 3];
    struct I(T = size_t)
    {
        this(T ix) { this._ix = ix; }
        private T _ix = 0;
    }
    alias J = I!size_t;
    static assert(!__traits(compiles, { auto xj = x.indexedBy!J; }));
}

@safe pure nothrow unittest
{
    auto x = [1, 2, 3];
    import bound: Bound;
    alias B = Bound!(ubyte, 0, 2);
    B b;
    auto c = cast(size_t)b;
    auto y = x.indexedBy!B;
}

/** TODO shorter name */
enum StaticArrayOfElementTypeIndexedBy(E, I) = IndexedBy!(E[I.elementCountOf!E], I);
