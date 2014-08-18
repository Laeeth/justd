module typecons_ex;

// TODO: Add to Phobos and refer to http://forum.dlang.org/thread/lzyqywovlmdseqgqfvun@forum.dlang.org#post-ibvkvjwexdafpgtsamut:40forum.dlang.org

import std.typecons: Nullable;

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
