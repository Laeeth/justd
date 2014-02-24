#!/usr/bin/env rdmd-dev-module

unittest
{
    import std.range: recurrence, take;
    import std.stdio: writeln;

    // a[0] = 1, a[1] = 1, and compute a[n+1] = a[n-1] + a[n]
    auto fib = recurrence!("a[n-1] + a[n-2]")(1, 1);
    // print the first 10 Fibonacci numbers
    foreach (e; take(fib, 10)) { writeln(e); }
    // print the first 10 factorials
    foreach (e; take(recurrence!("a[n-1] * n")(1), 10)) { writeln(e); }
}
