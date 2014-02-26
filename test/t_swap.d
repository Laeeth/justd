#!/usr/bin/env rdmd-unittest-module

void main(string args[])
{
    import std.algorithm: swap, swapRanges, equal;
    import std.stdio: wln = writeln;

    auto x = [1, 2, 3];
    auto y = [4, 5, 6];
    auto x_ = x;

    swap(x, y); // swap references
    assert(x.equal([4, 5, 6]));
    assert(y.equal([1, 2, 3]));
    assert(x_.equal([1, 2, 3]));

    wln("x: ", x);
    wln("y: ", y);
    wln("x_: ", x_);

    swap(x, y); // swap references
    assert(x.equal([1, 2, 3]));
    assert(y.equal([4, 5, 6]));
    assert(x_.equal([1, 2, 3]));

    wln("x: ", x);
    wln("y: ", y);
    wln("x_: ", x_);

    swapRanges(x[], y[]); // swap contents
    assert(x.equal([4, 5, 6]));
    assert(y.equal([1, 2, 3]));
    assert(x_.equal([4, 5, 6]));
}
