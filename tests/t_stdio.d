#!/usr/bin/env rdmd-dev

int main(string[] args)
{
    import std.stdio;
    write(`Press enter to continue: `);
    stdout.flush;
    auto line = readln();
    writeln("Read ", line);
    return 0;
}
