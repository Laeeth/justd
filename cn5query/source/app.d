import std.stdio;
import conceptnet5;

int main(string[] args)
{
    auto net = new Net!(true, false)(`~/Knowledge/conceptnet5-5.3/data/assertions/`);
    net.showConcepts(`car`);
    net.showConcepts(`car_wash`);

    while (true)
    {
        write(`Lookup: `); stdout.flush;
        string line;
        if ((line = readln()) !is null)
        {
            import std.string: strip;
            net.showConcepts(line.strip);
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
