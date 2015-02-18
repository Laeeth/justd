unittest
{
    import std.stdio;
    auto x = [1, 2, 3];
    foreach (e; x) {}
    assert(x.length == 3);
}
