#!/usr/bin/env rdmd-dev

import std.stdio;
import pegged.peg;
import pegged.grammar;
import std.typecons: tuple;
import msgpack;
import dbg;

import lang_A;
import lang_C;
import lang_Ada;

void main(string[] args)
{
    import std.conv: to;

    pragma(msg, (`ParseTree.sizeof: ` ~
                 ParseTree.sizeof.to!string));

    /* A */
    auto ptA = A(`1 + 2 - (3*x-5)*6`);
    assert(ptA.matches == [`1`, `+`, `2`, `-`, `(`, `3`, `*`, `x`, `-`, `5`, `)`, `*`, `6`]);
    writeln(`Original Packed Size: `, ptA.pack.length);

    auto decA = A.decimateTree(ptA);

    const srcC = `int x;`;
    writeln(`C Source Size: `, srcC.length);
    auto treeC = C(srcC);
    writeln(`C ParseTree Size: `, treeC.pack.length);
    writeln(treeC);
}
