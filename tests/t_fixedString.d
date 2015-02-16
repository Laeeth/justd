#!/usr/bin/env rdmd-dev-module

import std.stdio;

void main(string[] args)
{
    alias string8 = immutable(char)[8];
    string8 str = "12345678";
    writeln(str[]);
}
