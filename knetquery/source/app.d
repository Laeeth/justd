import std.stdio;
import knet.base;
import knet.tests;
import knet.inference;
import knet.persistence;
import knet.io;
import knet.lectures;

import etc.linux.memoryerror;
debug import backtrace.backtrace;

int main(string[] args)
{
    debug import std.stdio: stderr;
    debug backtrace.backtrace.install(stderr);
    registerMemoryErrorHandler();

    const cachePath = "~/.cache";

    auto graph = new Graph();

    graph.testAll;

    // loads
    if (false) graph.loadUniquelySensedLemmas(cachePath);
    if (false) { graph.load(cachePath); }

    graph.learnDefault;

    graph.showRelations;

    // saves
    if (false) graph.inferSpecializedSenses;
    if (false) graph.saveUniquelySensedLemmas(cachePath);
    if (false) { graph.save(cachePath); }

    while (true)
    {
        write("_____________\n" ~
              "< Concept(s) or ? for help: "); stdout.flush;
        string line;
        if ((line = readln()) !is null)
        {
            graph.showNodes(line);
        }
        else
        {
            writeln();
            break;
        }
    }

    return 0;
}
