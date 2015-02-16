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

struct Ix(T = size_t)
{
    @safe pure: @nogc nothrow:
    this(T ix) { this._ix = ix; }
    alias _ix this;
    private T _ix = 0;
}

/** Wrapper for $(D R) with Type-Safe $(D I)-Indexing.
    See also: http://forum.dlang.org/thread/gayfjaslyairnzrygbvh@forum.dlang.org#post-gayfjaslyairnzrygbvh:40forum.dlang.org
   */
struct IndexedBy(R, I)
{
    auto ref opIndex(I ix) inout { return _r[ix]; }
    auto ref opSlice(I lower, I upper) inout { return _r[lower .. upper]; }
    R _r;
    alias _r this;
}

auto indexedBy(I, R)(R range)
{
    return IndexedBy!(R, I)(range);
}

unittest
{
    import std.stdio;
    auto x = [1, 2, 3];
    alias I = int;
    auto ix = x.indexedBy!I;
    ix[0] = 11;

    alias J = Ix!size_t;
    auto jx = x.indexedBy!J;
    jx[J(0)] = 11;              // should compile
    jx[0] = 11;                 // how can I make this not compile?
}
