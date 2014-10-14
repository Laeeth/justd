#!/usr/bin/env rdmd-dev

import std.stdio, std.algorithm;

void main(string[] args)
{
    writeln(splitter("hello world", ' '));
    import std.uni: isWhite;
    import std.algorithm: splitter;
    import std.conv: to;
    auto line = " car_wash ";
    import std.string: strip;
    auto normalizedLine = line.strip.splitter!isWhite.joiner("_").to!string;
    writeln(normalizedLine);
}
