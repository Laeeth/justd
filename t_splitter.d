#!/usr/bin/env rdmd-dev

import std.stdio, std.algorithm;

void main(string[] args)
{
    writeln(splitter("hello world", ' '));

    import std.uni: isWhite;
    import std.algorithm: splitter;
    import std.conv: to;
    import std.array: array;

    auto line = " car_wash ";
    import std.string: strip;
    auto normalizedLine = line.strip.splitter!isWhite.joiner("_").to!string;
    writeln(normalizedLine);

    const source = "1 2 3";
    foreach (const word; source.splitter)
    {
        const x = word.to!int;
    }

    auto words = source.splitter;
    const x = words.front.to!int; words.popFront;
}
