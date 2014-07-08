#!/usr/bin/env rdmd-unittest-module

int g = 1;

void inc()
{
    g += 1;
}

pure auto sqr(T)(in T a)
{
    inc();
    import std.stdio: writeln;
    writeln("f");
    return a*a;
}

unittest {
    int a = 1;
    assert(sqr(a) == sqr(a));
}

void main(string[] args)
{
}
