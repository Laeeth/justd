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

import std.algorithm: startsWith;

/** Skip Over Shortest Matching prefix in $(D needles) that prefixes $(D haystack).
    TODO Make return value a specific type that has bool conversion so we can
    call it as
    if (auto hit = r.skipOverShortestOf(...)) { ... }
 */
size_t skipOverShortestOf(alias pred = "a == b",
                          Range,
                          Ranges...)(ref Range haystack,
                                     Ranges needles) if (Ranges.length > 1 && is(typeof(startsWith!pred(haystack, needles))))
{
    const hit = startsWith!pred(haystack, needles);
    if (hit)
    {
        // get needle lengths
        size_t[needles.length] lengths;
        foreach (ix, needle; needles)
        {
            import std.traits: isSomeString, isSomeChar;
            import std.range: ElementType;
            import std.typecons: Unqual;

            alias Needle = Unqual!(typeof(needle));

            static if (is(Unqual!Range ==
                          Needle))
            {
                lengths[ix] = needle.length;
            }
            else static if (is(Unqual!(ElementType!Range) ==
                               Unqual!(ElementType!Needle)))
            {
                lengths[ix] = needle.length;
            }
            else static if (isSomeString!Range &&
                            isSomeString!Needle)
            {
                lengths[ix] = needle.length;
            }
            else static if (isSomeChar!(ElementType!Range) &&
                            isSomeChar!Needle)
            {
                lengths[ix] = 1;
            }
            else static if (is(Unqual!(ElementType!Range) ==
                               Needle))
            {
                lengths[ix] = 1;
            }
            else
            {
                static assert(false,
                              "Cannot handle needle of type " ~ Needle.stringof ~
                              " when haystack has ElementType " ~ (ElementType!Range).stringof);
            }
        }

        import std.range: popFrontN;
        haystack.popFrontN(lengths[hit - 1]);
    }

    return hit;

}

@safe pure unittest
{
    auto x = "beta version";
    assert(x.skipOverShortestOf("beta", "be") == 2);
    assert(x == "ta version");
}

@safe pure unittest
{
    auto x = "beta version";
    assert(x.skipOverShortestOf("be", "beta") == 1);
    assert(x == "ta version");
}

@safe pure unittest
{
    auto x = "beta version";
    assert(x.skipOverShortestOf('b', "be", "beta") == 1);
    assert(x == "eta version");
}

/** Skip Over Longest Matching prefix in $(D needles) that prefixes $(D haystack). */
Tuple!(bool, size_t) skipOverLongestOf(alias pred = "a == b", Range, Ranges...)(ref Range haystack, Ranges needles)
{
    // TODO figure out which needles that are prefixes of other needles by first
    // sorting them and then use some adjacent filtering algorithm
    return haystack.skipOverShortestOf(needles);
}

size_t skipOverBackShortestOf(alias pred = "a == b", Range, Ranges...)(ref Range haystack, Ranges needles)
// TODO We cannot prove that cast(ubyte[]) of a type that have no directions is safe
    @trusted if (Ranges.length > 1 && is(typeof(startsWith!pred(haystack, needles))))
{
    import std.range: retro, ElementType;
    import std.traits: hasIndirections;
    import std.typetuple: staticMap, TypeTuple;
    import traits_ex: allSame;

    static if ((!hasIndirections!(ElementType!Range)) &&
               allSame!(Range, Ranges))
    {
        auto retroHaystack = (cast(ubyte[])haystack).retro;

        alias Retro(Range) = typeof((ubyte[]).init.retro);
        TypeTuple!(staticMap!(Retro, Ranges)) retroNeedles;
        foreach (ix, needle; needles)
        {
            retroNeedles[ix] = (cast(ubyte[])needle).retro;
        }

        const retroHit = retroHaystack.skipOverShortestOf(retroNeedles);
        haystack = haystack[0.. $ - (haystack.length - retroHaystack.length)];

        return retroHit;
    }
    else
    {
        static assert(false, "Unsupported combination of haystack type " ~ Range.stringof ~
                      " with needle types " ~ Ranges.stringof);
    }
}

@safe pure unittest
{
    auto x = "alpha_beta";
    assert(x.skipOverBackShortestOf("x", "beta") == 2);
    assert(x == "alpha_");
}

@safe pure unittest
{
    auto x = "alpha_beta";
    assert(x.skipOverBackShortestOf("a", "beta") == 1);
    assert(x == "alpha_bet");
}
