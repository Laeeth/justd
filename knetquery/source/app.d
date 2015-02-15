import std.stdio;
import getopt_ex;
import knet.base;
import knet.tests;
import knet.inference;
import knet.persistence;
import knet.io;
import knet.lectures;
import knet.readers;

import etc.linux.memoryerror;
debug import backtrace.backtrace;

int main(string[] args)
{
    debug import std.stdio: stderr;
    debug backtrace.backtrace.install(stderr);
    registerMemoryErrorHandler();

    bool loadCache = false;
    bool saveCache = false;
    bool useCache = false;
    bool helpPrinted = getoptEx("knetquery --- Command Line interface to knet.\n",
                                args,
                                std.getopt.config.caseInsensitive,
                                "load-cache", "\tLoad database cache upon startup.",  &loadCache,
                                "save-cache", "\tSave database cache upon shutdown.",  &saveCache,
                                "use-cache|c", "\tUse caching of database.",  &useCache);
    if (helpPrinted)
    {
        return 0;
    }

    if (useCache)               // wildcard
    {
        loadCache = true;
        saveCache = true;
    }

    const cachePath = "~/.cache";

    auto graph = new Graph();

    graph.testAll;

    // loads
    if (false) graph.loadUniquelySensedLemmas(cachePath);

    if (loadCache)
    {
        graph.load(cachePath);
    }
    else
    {
        graph.learnDefault;
    }

    graph.showRelations;

    // saves
    if (false) graph.inferSpecializedSenses;
    if (saveCache) graph.saveUniquelySensedLemmas(cachePath);
    if (saveCache) { graph.save(cachePath); }

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
