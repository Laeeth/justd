#!/usr/bin/env rdmd-dev

import std.stdio;
import std.concurrency: spawn;

alias T = string[];

void useConstArgs(const T x)
{
    writeln("x: ", x);
}

void useArgs(T x)
{
    writeln("x: ", x);
}

void main(T args)
{
    useArgs(args); // ok to call in same thread
    auto f1 = spawn(&useConstArgs, args.idup); // Compile-Time Error: "Aliases to mutable thread-local data not allowed."
    auto f2 = spawn(&useArgs, args.idup); // Compile-Time Error: "Aliases to mutable thread-local data not allowed."
    auto f3 = spawn(&useArgs, args); // Compile-Time Error: "Aliases to mutable thread-local data not allowed."
}
