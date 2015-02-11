import std.stdio;
import knet.base;
import knet.tests;
import knet.inference;
import knet.lectures.all;

import etc.linux.memoryerror;
debug import backtrace.backtrace;

int main(string[] args)
{
    debug import std.stdio: stderr;
    debug backtrace.backtrace.install(stderr);
    registerMemoryErrorHandler();

    auto gr = new Graph();
    gr.testAll;
    gr.initialize;
    if (false) gr.inferSpecializedSenses;

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
