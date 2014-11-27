#!/usr/bin/env rdmd-dev-module

import std.stdio;
import std.range: retro, array;
import std.utf;
import std.uni;

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

    static assert("ab" ~ null == "ab");
    static assert("ab" ~ [] == "ab");

    writeln("åäö".length);
    writeln("åäö".retro);
    writeln("åäö".byCodeUnit.retro);
    writeln("åäö".byCodePoint.retro);
    writeln("åäö".byCodePoint.length);
    writeln("åäö".byCodeUnit.length);
    writeln("åäö".byWchar.array.length);
    writeln("åäö".byDchar.array.length);

    import algorithm_ex: isPalindrome;
    writeln("åäå".isPalindrome);
}
