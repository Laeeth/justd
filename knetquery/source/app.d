import std.stdio;
import knet.base;
import knet.lectures.all;

import etc.linux.memoryerror;
debug import backtrace.backtrace;

int main(string[] args)
{
    debug import std.stdio: stderr;
    debug backtrace.backtrace.install(stderr);
    registerMemoryErrorHandler();

    auto gr = new Graph!(true, false)();
    gr.showNodes(`car_wash`);

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
    /* if (true) */
    /* { */
    /*     auto netPack = gr.pack; */
    /*     writeln(`Packed to `, netPack.length, ` bytes`); */
    /* } */

    if (false) // just to make all variants of compile
    {
        /* auto netH = new Graph!(!useHashedStorage)(`~/Knowledge/conceptnet5-5.3/data/assertions/`); */
    }

    return 0;
}
