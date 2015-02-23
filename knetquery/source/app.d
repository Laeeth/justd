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

    bool loadUniquelySensedLemmasCache = false;
    bool saveUniquelySensedLemmasCache = false;

    bool loadCache = false;
    bool saveCache = false;

    bool useCache = false;

    bool helpPrinted = getoptEx("knetquery --- Command Line interface to knet.\n",
                                args,
                                std.getopt.config.caseInsensitive,
                                "load-unique-senses", "\tLoad unique senses upon startup.",  &loadUniquelySensedLemmasCache,
                                "save-unique-senses", "\tSave unique senses upon shutdown.",  &saveUniquelySensedLemmasCache,

                                "load-cache", "\tLoad database cache upon startup.",  &loadCache,
                                "save-cache", "\tSave database cache upon shutdown.",  &saveCache,
                                "use-cache", "\tUse caching of database.",  &useCache);
    if (helpPrinted)
    {
        return 0;
    }

    const cachePath = "~/.cache";
    if (useCache)               // wildcard
    {
        loadCache = true;
        saveCache = true;
    }

    testAll;

    auto gr = new Graph();

    // loads
    if (loadUniquelySensedLemmasCache) { gr.loadUniquelySensedLemmas(cachePath); }

    if (loadCache) { gr.load(cachePath); }
    else
    {
        import knet.readers.wordnet;
        //gr.readWordNet(`../knowledge/en/wordnet`);
        gr.learnDefault;
    }

    gr.showRelations;

    // saves
    if (false) gr.inferSpecializedSenses;

    if (saveUniquelySensedLemmasCache) { gr.saveUniquelySensedLemmas(cachePath); }

    if (saveCache) { gr.save(cachePath); }

    while (true)
    {
        write("_____________\n" ~
              "< Concept(s) or ? for help: "); stdout.flush;
        string line;
        if ((line = readln()) !is null)
        {
            gr.showNodes(line);
        }
        else
        {
            writeln();
            break;
        }
    }

    return 0;
}
