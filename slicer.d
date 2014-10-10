#!/usr/bin/env rdmd-dev-module

module slicer;

/** PreSlicer.
    Enhanced version of std.algorithm.splitter.
    http://forum.dlang.org/thread/qjbmfeukiqvribmdylkl@forum.dlang.org?page=1
    http://dlang.org/library/std/algorithm/splitter.html.
*/
auto preslicer(alias isTerminator, Range)(Range input) /* if (((isRandomAccessRange!Range && */
/*       hasSlicing!Range) || */
/*      isSomeString!Range) && */
/*     is(typeof(unaryFun!isTerminator(input.front)))) */
{
    import std.functional: unaryFun;
    return PreSlicer!(unaryFun!isTerminator, Range)(input);
}

private struct PreSlicer(alias isTerminator, Range)
{
    private Range _input;
    private size_t _end = 0;

    private void findTerminator()
    {
        import std.range: save;
        import std.algorithm: find;
        auto hit = _input.save.find!(a => !isTerminator(a));
        auto r = hit.find!isTerminator();
        _end = _input.length - r.length;
    }

    this(Range input)
    {
        _input = input;
        import std.range: empty;
        if (_input.empty)
            _end = size_t.max;
        else
        findTerminator();
    }

    import std.range: isInfinite;

    static if (isInfinite!Range)
    {
        enum bool empty = false;  // Propagate infiniteness.
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
    assert(equal("doThis".preslicer!isUpper, ["do", "This"]));
    assert(equal("SomeGreatVariableName".preslicer!isUpper, ["Some", "Great", "Variable", "Name"]));
    assert(equal("someGGGreatVariableName".preslicer!isUpper, ["some", "GGGreat", "Variable", "Name"]));
    string[] e;
    assert(equal("".preslicer!isUpper, e));
    assert(equal("a".preslicer!isUpper, ["a"]));
    assert(equal("A".preslicer!isUpper, ["A"]));
    assert(equal("A".preslicer!isUpper, ["A"]));

    assert(equal([1, -1, 1, -1].preslicer!(a => a > 0), [[1, -1], [1, -1]]));
}
