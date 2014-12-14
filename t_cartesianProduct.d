import std.range: isRandomAccessRange, hasLength;
import std.traits: isNarrowString;
import std.typecons: Tuple;

struct Pairwise(Range)
{
    import std.range: ForeachType;
    import std.traits: Unqual;

    alias R = Unqual!Range;
    alias Pair = Tuple!(ForeachType!R, "a",
                        ForeachType!R, "b");

    R _input;
    size_t i, j;

    this(Range r_)
    {
        this._input = r_;
        j = 1;
    }

    @property bool empty()
    {
        return j >= _input.length;
    }

    @property Pair front()
    {
        return Pair(_input[i], _input[j]);
    }

    void popFront()
    {
        if (j >= _input.length - 1)
        {
            i++;
            j = i + 1;
        }
        else
        {
            j++;
        }
    }
}

Pairwise!Range pairwise(Range)(Range r) if (isRandomAccessRange!Range &&
                                            hasLength!Range &&
                                            !isNarrowString!Range)
{
    return typeof(return)(r);
}

void main()
{
    import std.stdio: writeln;
    (new int[0]).pairwise.writeln;
    [10].pairwise.writeln;
    [10, 20].pairwise.writeln;
    [10, 20, 30].pairwise.writeln;
    [10, 20, 30, 40].pairwise.writeln;
}
