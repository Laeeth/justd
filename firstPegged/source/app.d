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

/*
  TODO This may happen again:

  per:~/justd] master(+9/-9) ± cd firstPegged/
  /home/per/justd/firstPegged
  [per:~/justd/firstPegged] master(+14/-14) ± dub
  Fetching pegged ~master (getting selected version)...
  Placing pegged ~master to /home/per/.dub/packages/...
  WARNING: A deprecated branch based version specification is used for the dependency pegged. Please use numbered versions instead. Also note that you can still use the dub.selections.json file to override a certain dependency to use a branch instead.
  Building pegged ~master configuration "library", build type debug.
  Running dmd...
  Building firstpegged ~master configuration "application", build type debug.
  Compiling using dmd...
  Skipped cached parser parser_A.d
  Skipped cached grammar grammar_A.peg
  Grammar grammar_A.peg has changed
  Linking...
  Running ./firstpegged
  std.file.FileException@std/file.d(450): generated_source/parser_A.d: No such file or directory
  Error executing command run:
  Program exited with code 1
 */

// TODO Use template mixins in pegged automation as done here
// http://forum.dlang.org/thread/bzzwikiplqydlzmphllp@forum.dlang.org
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

    const srcC = "int x, y;";
    writeln(`C Source Size: `, srcC.length);

    auto treeC = C(srcC);
    auto decC = C.decimateTree(treeC);

    writeln();
    writeln(`C ParseTree Size: `, treeC.pack.length);
    writeln(treeC);

    if (treeC != decC)
    {
        writeln();
        writeln(`C Decimated ParseTree Size: `, decC.pack.length);
        writeln(decC);
    }
}
