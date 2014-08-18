module typecons_ex;

import std.typecons: Nullable;

/** Instantiator for $(D Nullable).
    TODO: Add to Phobos and refer to http://forum.dlang.org/thread/lzyqywovlmdseqgqfvun@forum.dlang.org#post-ibvkvjwexdafpgtsamut:40forum.dlang.org
*/
auto nullable(T)(T a)
{
    return Nullable!T(a);
}
unittest
{
    auto x = nullable(42.5);
    assert(is(typeof(x) == Nullable!double));
}

/** Instantiator for $(D Nullable).
    TODO: Add to Phobos.
*/
auto nullable(alias nullValue, T)(T value)
    if (is (typeof(nullValue) == T))
    {
        return Nullable!(T, nullValue)(value);
    }
unittest
{
    auto x = nullable!(int.max)(3);
    assert(is (typeof(x) == Nullable!(int, int.max)));
}
