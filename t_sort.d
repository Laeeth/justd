#!/usr/bin/env rdmd-dev-module

int main(string[] args)
{
    auto x = [3, 2, 1];
    import std.algorithm: sort;
    x.sort;
    return 0;
}
