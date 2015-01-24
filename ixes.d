module ixes;

/** Get length of Common Prefix of $(D a) and $(D b).
    See also: http://forum.dlang.org/thread/bmbhovkgqomaidnyakvy@forum.dlang.org#post-bmbhovkgqomaidnyakvy:40forum.dlang.org
*/
auto commonPrefixLength(Ranges...)(Ranges ranges)
{
    static if (ranges.length == 2)
    {
        import std.algorithm: commonPrefix;
        return commonPrefix(ranges[0], ranges[1]).length;
    }
    else
    {
        import std.range: zip, StoppingPolicy;
        import std.algorithm: countUntil, count;
        const hit = zip(a, b).countUntil!(ab => ab[0] != ab[1]); // TODO if countUntil return zip(a, b).count upon failre...
        return hit == -1 ? zip(a, b).count : hit; // TODO ..then this would not have been needed
    }
}

@safe pure unittest
{
    assert(commonPrefixLength(`åäö_`,
                              `åäö-`) == 6);
}

@safe pure nothrow unittest
{
    const x = [1, 2, 3, 10], y = [1, 2, 4, 10];
    void f() @safe @nogc pure nothrow
    {
        assert(commonPrefixLength(x, y) == 2);
    }
    f();
    assert(commonPrefixLength([1, 2, 3, 10],
                              [1, 2, 3]) == 3);
    assert(commonPrefixLength([1, 2, 3, 0, 4],
                              [1, 2, 3, 9, 4]) == 3);
}

/** Get length of Suffix Prefix of $(D a) and $(D b).
    See also: http://forum.dlang.org/thread/bmbhovkgqomaidnyakvy@forum.dlang.org#post-bmbhovkgqomaidnyakvy:40forum.dlang.org
*/
auto commonSuffixLength(Ranges...)(Ranges ranges)
{
    static if (ranges.length == 2)
    {
        import std.range: isNarrowString;
        import std.range: retro;
        static if (isNarrowString!(typeof(ranges[0])) &&
                   isNarrowString!(typeof(ranges[1])))
        {
            import std.string: representation;
            return commonPrefixLength(ranges[0].representation.retro,
                                      ranges[1].representation.retro);
        }
        else
        {
            return commonPrefixLength(ranges[0].retro,
                                      ranges[1].retro);
        }
    }
}

@safe pure unittest
{
    const x = [1, 2, 3, 10, 11, 12];
    const y = [1, 2, 4, 10, 11, 12];
    void f() @safe @nogc pure nothrow
    {
        assert(commonPrefixLength(x, y) == 2);
    }
    f();
    assert(commonSuffixLength(x, y) == 3);
    assert(commonSuffixLength([10, 1, 2, 3],
                              [1, 2, 3]) == 3);
}

@safe pure unittest
{
    assert(commonSuffixLength(`_åäö`,
                              `-åäö`) == 6);
}

/** Get Count of Suffix Prefix of $(D a) and $(D b).
    See also: http://forum.dlang.org/thread/bmbhovkgqomaidnyakvy@forum.dlang.org#post-bmbhovkgqomaidnyakvy:40forum.dlang.org
*/
auto commonPrefixCount(Ranges...)(Ranges ranges)
{
    static if (ranges.length == 2)
    {
        import std.range: isNarrowString;
        static if (isNarrowString!(typeof(ranges[0])) &&
                   isNarrowString!(typeof(ranges[1])))
        {
            import std.utf: byDchar;
            return commonPrefixLength(ranges[0].byDchar,
                                      ranges[1].byDchar);
        }
        else
        {
            return commonPrefixLength(ranges[0],
                                      ranges[1]);
        }
    }
}

@safe pure unittest
{
    assert(commonPrefixCount([1, 2, 3, 10],
                             [1, 2, 3]) == 3);
    assert(commonPrefixCount(`åäö_`,
                             `åäö-`) == 3);
}

/** Get Count of Suffix Prefix of $(D a) and $(D b).
    See also: http://forum.dlang.org/thread/bmbhovkgqomaidnyakvy@forum.dlang.org#post-bmbhovkgqomaidnyakvy:40forum.dlang.org
*/
auto commonSuffixCount(Ranges...)(Ranges ranges)
{
    static if (ranges.length == 2)
    {
        import std.range: retro;
        return commonPrefixLength(ranges[0].retro,
                                  ranges[1].retro);
    }
}

@safe pure unittest
{
    assert(commonSuffixCount(`_åäö`,
                             `-åäö`) == 3);
}

/** Get length of Common Prefix of ranges $(D ranges).
    See also: http://forum.dlang.org/thread/bmbhovkgqomaidnyakvy@forum.dlang.org#post-bmbhovkgqomaidnyakvy:40forum.dlang.org
*/
// auto commonPrefixLengthN(R...)(R ranges) if (ranges.length == 2)
// {
//     import std.range: zip;
//     return zip!((a, b) => a != b)(ranges);
// }

// unittest
// {
//     assert(commonPrefixLengthN([1, 2, 3, 10],
//                               [1, 2, 4, 10]) == 2);
// }
