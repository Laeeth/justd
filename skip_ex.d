#!/usr/bin/env rdmd-dev-module

module skip_ex;

import std.functional : binaryFun;
import std.range: back, save, empty, popBack;

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

import std.typecons: Tuple;
debug import std.stdio;

/** Skip Over First Matching prefix in $(D needles) that prefixes $(D haystack). */
Tuple!(bool, size_t) skipOverFirstOf(alias pred = "a == b", R, R2...)(ref R haystack, R2 needles)
{
    import std.algorithm: find;
    import std.range: front;

    // do match
    const match = haystack.find(needles);
    const ok = (match[1] != 0 && // match[1]:th needle matched
                match[0].front is haystack.front); // match at beginning of haystack

    // get needle lengths
    size_t[needles.length] lengths;
    foreach (ix, needle; needles)
    {
        lengths[ix] = needle.length;
    }

    if (ok)
    {
        import std.range: popFrontN;
        haystack.popFrontN(lengths[match[1] - 1]);
    }

    return typeof(return)(ok, match[1]);
}

/** Skip Over Longest Matching prefix in $(D needles) that prefixes $(D haystack). */
Tuple!(bool, size_t) skipOverLongestOf(alias pred = "a == b", R, R2...)(ref R haystack, R2 needles)
{
    // TODO CTFE-sort needles on length
    return haystack.skipOverBack(needles);
}

@safe pure unittest
{
    import std.algorithm: find;
    auto x = "beta version";
    debug writeln(x.skipOverFirstOf("beta", "be"));
    debug writeln(x);
}

@safe pure unittest
{
    import std.algorithm: find;
    auto x = "beta version";
    debug writeln(x.skipOverFirstOf("be", "beta"));
    debug writeln(x);
}
