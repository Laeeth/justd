#!/usr/bin/env rdmd-dev

import std.stdio;
import std.file;
import std.parallelism : parallel;
import std.algorithm : filter, endsWith;

import backtrace.backtrace;

/** See also: http://forum.dlang.org/thread/nkmkhrafrwoqefdbbffn@forum.dlang.org */
void main(string[] args)
{
    import std.stdio: stderr;
    backtrace.backtrace.install(stderr);
    foreach(d; parallel(args[1 .. $], 1))
    {
        auto phpFiles = d.dirEntries(SpanMode.depth).filter!(a => a.name.endsWith(".php"));
        writeln(phpFiles);
    }
}
