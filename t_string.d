#!/usr/bin/env rdmd-dev-module

import std.stdio, std.algorithm, std.range, std.array;

void main(string[] args)
{
    static assert(string.init is null);
    static assert(!string.init);
    static assert([].init is null);

    static assert([].ptr != null);
    static assert("ab"[$..$].ptr == null);
    static assert(![]);
    static assert(!null);

    static assert("ab"[0..0] == []);
    static assert("ab"[$..$] == []);
    static assert("ab"[$..$] !is null);
    static assert("ab"[$..$] == null);
    static assert("ab"[0..0] == "ab"[$..$]);
    static assert("ab"[0..0]); // contextual hit (BOL)
    static assert("a\nb"[2..2]); // contextual hit (beginning of second line)
    static assert("ab"[$..$]); // contextual hit (EOL)
}