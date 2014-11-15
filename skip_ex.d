#!/usr/bin/env rdmd-dev-module

module skip_ex;

import std.functional : binaryFun;
import std.range: back, save, empty, popBack;
import std.range: hasSlicing;

/**
   If $(D startsWith(r1, r2)), consume the corresponding elements off $(D
   r1) and return $(D true). Otherwise, leave $(D r1) unchanged and
   return $(D false).
*/
bool skipOverBack(alias pred = "a == b", R1, R2)(ref R1 r1, R2 r2) if (is(typeof(binaryFun!pred(r1.back, r2.back))))
{
    auto r = r1.save;
    while (!r2.empty && !r.empty && binaryFun!pred(r.back, r2.back))
    {
        r.popBack();
        r2.popBack();
    }
    if (r2.empty)
        r1 = r;
    return r2.empty;
}

@safe pure unittest
{
    import std.algorithm: equal;

    auto s1 = "Hello world";
    assert(!skipOverBack(s1, "Ha"));
    assert(s1 == "Hello world");
    assert(skipOverBack(s1, "world") && s1 == "Hello ");
}

import std.typecons: tuple, Tuple;

/** Skip Over Shortest Matching prefix in $(D needles) that prefixes $(D haystack). */
Tuple!(bool, size_t) skipOverShortestOf(alias pred = "a == b", R, R2...)(ref R haystack, const R2 needles)
{
    import std.algorithm: find;
    import std.range: front;
    import std.traits: isSomeChar;

    // do match
    const match = haystack.find(needles);
    const ok = (match[1] != 0 && // match[1]:th needle matched
                match[0].front is haystack.front); // match at beginning of haystack

    if (ok)
    {
        // get needle lengths
        size_t[needles.length] lengths;
        foreach (ix, needle; needles)
        {
            import std.range: ElementType;
            import std.typecons: Unqual;

            alias Needle = Unqual!(typeof(needle));

            static if (is(R == Needle))
            {
                lengths[ix] = needle.length;
            }
            else static if (isSomeChar!(ElementType!R) &&
                            isSomeChar!Needle)
            {
                lengths[ix] = 1;
            }
            else static if (is(ElementType!R == Needle))
            {
                lengths[ix] = 1;
            }
            else
            {
                static assert(false, "Cannot handle needle of type " ~ Needle.stringof ~ " when haystack is of type " ~ (ElementType!R).stringof);
            }
        }

        import std.range: popFrontN;
        haystack.popFrontN(lengths[match[1] - 1]);
    }

    return typeof(return)(ok, match[1]);
}

@safe pure unittest
{
    auto x = "beta version";
    assert(x.skipOverShortestOf("beta", "be") == tuple(true, 2));
    assert(x == "ta version");
}

@safe pure unittest
{
    auto x = "beta version";
    assert(x.skipOverShortestOf("be", "beta") == tuple(true, 1));
    assert(x == "ta version");
}

@safe pure unittest
{
    auto x = "beta version";
    assert(x.skipOverShortestOf('b', "be", "beta") == tuple(true, 1));
    assert(x == "eta version");
}

/** Skip Over Longest Matching prefix in $(D needles) that prefixes $(D haystack). */
Tuple!(bool, size_t) skipOverLongestOf(alias pred = "a == b", R, R2...)(ref R haystack, const R2 needles)
{
    // TODO figure out which needles that are prefixes of other needles
    return haystack.skipOverShortestOf(needles);
}

Tuple!(bool, size_t) skipOverBackShortestOf(alias pred = "a == b", R, R2...)(ref R haystack, const R2 needles)
{
    import std.range: retro;
    import std.algorithm: array;
    auto retroHaystack = haystack.retro.array;
    pragma(msg, typeof(retroHaystack));
    const retroHit = retroHaystack.skipOverShortestOf(needles);
    haystack = haystack[0.. $ - (haystack.length - retroHaystack.length)];
    return retroHit;
}

/* @safe pure unittest */
/* { */
/*     auto x = "ab"; */
/*     assert(x.skipOverBackShortestOf('b') == tuple(true, 1)); */
/*     assert(x == "a"); */
/* } */
