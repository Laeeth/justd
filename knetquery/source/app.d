import std.stdio;
import knet;

import etc.linux.memoryerror;
debug import backtrace.backtrace;

int main(string[] args)
{
    debug import std.stdio: stderr;
    debug backtrace.backtrace.install(stderr);
    registerMemoryErrorHandler();

    auto net = new Net!(true, false)(`~/Knowledge/conceptnet5-5.3/data/assertions/`);
    net.showNodes(`car_wash`);

    while (true)
    {
        write("_____________\n" ~
              "< Concept(s) or ? for help: "); stdout.flush;
        string line;
        if ((line = readln()) !is null)
        {
            net.showNodes(line);
        }
        else
        {
            writeln();
            break;
        }
    }
    /* if (true) */
    /* { */
    /*     auto netPack = net.pack; */
    /*     writeln(`Packed to `, netPack.length, ` bytes`); */
    /* } */

    if (false) // just to make all variants of compile
    {
        /* auto netH = new Net!(!useHashedStorage)(`~/Knowledge/conceptnet5-5.3/data/assertions/`); */
    }

    return 0;
}
