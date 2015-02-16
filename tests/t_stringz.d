#!/usr/bin/env rdmd-dev-module

import std.stdio: wln = writeln;
import std.string;

void main(string[] args)
{
    alias z = toStringz;
    wln(typeof("a".toStringz).stringof);
    /* wln(typeof("a".z).stringof); */
    if ([])
    {
        wln("[] => true");
    }
    if (false)
    {
        wln("[] => true");
    }
    if ("")
    {
        wln(`"" => true`);
    }
}
