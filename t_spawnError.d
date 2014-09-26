#!/usr/bin/env rdmd-dev

import std.stdio;
import std.concurrency: spawn;

alias T = string[];

void useArgs(const T x)
{
    writeln("x: ", x);
}

void main(T args)
{
    useArgs(args); // ok to call in same thread
    auto f1 = spawn(&useArgs, args.idup); // Error: "Aliases to mutable thread-local data not allowed."
    auto f3 = spawn(&useArgs, args); // Error: "Aliases to mutable thread-local data not allowed."
}
