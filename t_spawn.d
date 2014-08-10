#!/usr/bin/env rdmd-dev

void otherMain()
{
    import std.stdio;
    writeln("hello world!");
}

void main(string[] args)
{
    import std.concurrency: spawn;
    auto otherMainTid = spawn(&otherMain);
}
