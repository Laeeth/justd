#!/usr/bin/env rdmd-dev-module

import std.stdio: wln = writeln;
import std.string;

int main(string[] args)
{
    alias z = toStringz;
    wln(typeof("a".z).stringof);
}
