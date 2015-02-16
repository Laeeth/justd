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
    immutable ext = ".php";
    foreach(dir; parallel(args[1 .. $], 1))
    {
        auto files = dir.dirEntries(SpanMode.depth).filter!(a => a.name.endsWith(ext));
        writeln(files);
    }
}
