#!/usr/bin/env rdmd-unittest-module

/** Scan file/magic/Magdir */
module magdir;

/** Scan Directory $(D dir) for file magic. */
void scanMagicFiles(string dir)
{
    import std.file: dirEntries, SpanMode;
    import std.stdio: writeln, File;
    import std.array: array;
    import std.range: front, empty;
    import std.algorithm: startsWith, find;
    import std.ascii: isDigit;

    size_t magicCount = 0;

    foreach (file; dir.dirEntries(SpanMode.depth))
    {
        writeln(file.name);
        import std.range: splitter;
        foreach (line; File(file).byLine)
        {
            auto parts = line.splitter("\t");
            if (!parts.empty)
            {
                if (parts.front.startsWith('#'))
                {
                    writeln("comment: ", parts);
                }
                else if (parts.front.front.isDigit)
                {
                    writeln(parts);
                }
                else if (parts.front.front == '>')
                {
                    writeln("2: ", parts);
                }
                magicCount++;
            }
        }
    }

    writeln("Found ", magicCount, " number of magics");
}

unittest
{
    scanMagicFiles(`/home/per/ware/file/magic/Magdir/`);
}
