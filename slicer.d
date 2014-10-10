#!/usr/bin/env rdmd-dev-module

module slicer;

/** Slice at all positions where isTerminator is false before current element
    and true at current.

    See also: http://dlang.org/library/std/algorithm/splitter.html.
    See also: http://forum.dlang.org/thread/qjbmfeukiqvribmdylkl@forum.dlang.org?page=1
*/
auto preSlicer
(alias isTerminator, R)(R input) /* if (((isRandomAccessRange!R && */
/*       hasSlicing!R) || */
/*      isSomeString!R) && */
/*     is(typeof(unaryFun!isTerminator(input.front)))) */
{
    import std.functional: unaryFun;
    return PreSlicer!(unaryFun!isTerminator, R)(input);
}

private struct PreSlicer(alias isTerminator, R)
{
    private R _input;
    private size_t _end = 0;

    private void findTerminator()
    {
        import std.range: save;
        import std.algorithm: find;
        auto hit = _input.save.find!(a => !isTerminator(a));
        auto r = hit.find!isTerminator();
        _end = _input.length - r.length;
    }

    this(R input)
    {
        _input = input;
        import std.range: empty;
        if (_input.empty)
            _end = size_t.max;
        else
        findTerminator();
    }

    import std.range: isInfinite;

    static if (isInfinite!R)
    {
        enum bool empty = false;  // propagate infiniteness
    }
    else
    {
        @property bool empty()
        {
            return _end == size_t.max;
        }
    }

    @property auto front()
    {
        return _input[0 .. _end];
    }

    void popFront()
    {
        _input = _input[_end .. _input.length];
        import std.range: empty;
        if (_input.empty)
        {
            _end = size_t.max;
            return;
        }
        findTerminator();
    }

    @property typeof(this) save()
    {
        auto ret = this;
        import std.range: save;
        ret._input = _input.save;
        return ret;
    }
}

unittest
{
    import std.uni: isUpper;
    import std.algorithm: equal;
    import std.range: retro;
    assert(equal("doThis".preSlicer!isUpper, ["do", "This"]));
    assert(equal("SomeGreatVariableName".preSlicer!isUpper, ["Some", "Great", "Variable", "Name"]));
    assert(equal("someGGGreatVariableName".preSlicer!isUpper, ["some", "GGGreat", "Variable", "Name"]));
    string[] e;
    assert(equal("".preSlicer!isUpper, e));
    assert(equal("a".preSlicer!isUpper, ["a"]));
    assert(equal("A".preSlicer!isUpper, ["A"]));
    assert(equal("A".preSlicer!isUpper, ["A"]));

    assert(equal([1, -1, 1, -1].preSlicer!(a => a > 0), [[1, -1], [1, -1]]));
}
