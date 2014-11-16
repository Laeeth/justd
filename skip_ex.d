#!/usr/bin/env rdmd-dev-module

module skip_ex;

import std.functional : binaryFun;
import std.range: back, save, empty, popBack, hasSlicing;

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

/** Skip Over Shortest Matching prefix in $(D needles) that prefixes $(D haystack).
    TODO Make return value a specific type that has bool conversion so we can
    call it as
        if (r.skipOverShortestOf(...)) { ... }
 */
Tuple!(bool, size_t) skipOverShortestOf(alias pred = "a == b", R, R2...)(ref R haystack, const R2 needles)
{
    import std.algorithm: find;
    import std.range: front;
    import std.traits: isSomeString, isSomeChar;

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

            static if (is(Unqual!R ==
                          Needle))
            {
                lengths[ix] = needle.length;
            }
            else static if (is(Unqual!(ElementType!R) ==
                               Unqual!(ElementType!Needle)))
            {
                lengths[ix] = needle.length;
            }
            else static if (isSomeString!R &&
                            isSomeString!Needle)
            {
                lengths[ix] = needle.length;
            }
            else static if (isSomeChar!(ElementType!R) &&
                            isSomeChar!Needle)
            {
                lengths[ix] = 1;
            }
            else static if (is(Unqual!(ElementType!R) ==
                               Needle))
            {
                lengths[ix] = 1;
            }
            else
            {
                static assert(false,
                              "Cannot handle needle of type " ~ Needle.stringof ~
                              " when haystack has ElementType " ~ (ElementType!R).stringof);
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
    // TODO figure out which needles that are prefixes of other needles by first
    // sorting them and then use some adjacent filtering algorithm
    return haystack.skipOverShortestOf(needles);
}

Tuple!(bool, size_t) skipOverBackShortestOf(alias pred = "a == b", R, R2...)(ref R haystack, const R2 needles)
@trusted // TODO We cannot prove that cast(ubyte[]) of a type that have no directions is safe
{
    import std.range: retro, ElementType;
    import std.traits: hasIndirections;
    import std.algorithm: array;
    import std.typetuple: staticMap, TypeTuple;
    import traits_ex: allSame;

    static if ((!hasIndirections!(ElementType!R)) && // previously isSomeString
               allSame!(R, R2))
    {
        auto retroHaystack = (cast(ubyte[])haystack).retro.array;
        alias Retro(R) = typeof((ubyte[]).init.retro.array);
        TypeTuple!(staticMap!(Retro, R2)) retroNeedles;
        foreach (ix, needle; needles)
        {
            retroNeedles[ix] = (cast(ubyte[])needle).retro.array;
        }
        pragma(msg, typeof(retroHaystack));
        pragma(msg, typeof(retroNeedles));

        const retroHit = retroHaystack.skipOverShortestOf(retroNeedles);
        haystack = haystack[0.. $ - (haystack.length - retroHaystack.length)];
        return retroHit;
    }
    else
    {
        static assert(false, "Unsupported combination of haystack type " ~ R.stringof ~
                      " with needle types " ~ R2.stringof);
    }

    return tuple(false, 0UL);
}

/* @safe pure unittest */
/* { */
/*     auto x = "alpha_beta"; */
/*     assert(x.skipOverBackShortestOf("beta") == tuple(true, 1)); */
/*     assert(x == "alpha_"); */
/* } */
