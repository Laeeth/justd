module set;

/** Set of Values of Type $(D T). */
struct Set(T)
{
    this(E...)(E args) if (is(CommonType!E == T))
    {
        _data = new T[args.length];
        foreach (ix, arg; args)
        {
            _data[ix] = arg;
        }
    }
    Set opSlice(T lo, T hi)
    {
        Set result;
        foreach(c; lo .. hi)
            result._data ~= c;
        return result;
    }
    Set opSlice(T lohi)
    {
        Set result;
        result._data ~= lohi;
        return result;
    }
    bool opIn_r(T elem)
    {
        import std.range: empty;
        if (_data.empty)
            return false;
        return ((elem >= _data[0]) &&
                (elem <= _data[$-1]));
    }
    static if (is(T == char))
    {
        string toString()
        {
            return _data;
        }
    }

private:
    static if (is(T == char)) string _data;
    else                      T[] _data;
}

import std.typecons: CommonType;

/** Instantiator for $(D Set). */
Set!(CommonType!T) set(T...)(T args)
{
    return typeof(return)(args);
}

unittest
{
    auto x = set(1, 3);
    assert(1 in x);
    assert(!(4 in x));
}

void main(string[] args)
{
    Set!char cs;

    auto a2k = cs['a' .. 'k'+1];
    auto A2K = cs['A' .. 'K'+1];
    auto Z29 = cs['0' .. '9'+1];

    assert('a' in a2k);
    assert(!('x' in a2k));

    assert('A' in A2K);
    assert(!('X' in A2K));

    import std.conv;
    assert(to!string(Z29) == "0123456789");

    assert('x' in cs['x' .. 'x'+1]);
}
