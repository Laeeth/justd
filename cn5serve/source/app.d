#!/usr/bin/env rdmd-dev

import vibe.d;

import conceptnet5;

void loadCN5()
{
    import std.stdio;
    // TODO Add auto-download and unpack from http://conceptnet5.media.mit.edu/downloads/current/

    auto net = new Net!(true, false)(`~/Knowledge/conceptnet5-5.3/data/assertions/`);
    net.showConcepts(`car`);
    net.showConcepts(`car_wash`);

    while (true)
    {
        write(`Lookup: `); stdout.flush;
        string line;
        if ((line = readln()) !is null)
        {
            net.showConcepts(line);
        }
        else
        {
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

    write(`Press enter to continue: `);
    readln();
}
