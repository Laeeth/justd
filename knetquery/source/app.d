import std.stdio;
import knet;
debug import backtrace.backtrace;

int main(string[] args)
{
    debug import std.stdio: stderr;
    debug backtrace.backtrace.install(stderr);

    auto net = new Net!(true, false)(`~/Knowledge/conceptnet5-5.3/data/assertions/`);
    net.showConcepts(`car_wash`);

    while (true)
    {
        write(`Concept(s): `); stdout.flush;
        string line;
        if ((line = readln()) !is null)
        {
            net.showConcepts(line);
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
