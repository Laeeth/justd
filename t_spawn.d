#!/usr/bin/env rdmd-dev

import std.stdio;
import std.concurrency: spawn;

alias T = string[];

void useArgs(int x)
{
    writefln("arg to %s is ", __FUNCTION__, x);
}

void main(T args)
{
    auto f1 = spawn(&useArgs, 1);
}
