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
    import std.range: splitter;

    size_t magicCount = 0;
    size_t attributeCount = 0;

    foreach (file; dir.dirEntries(SpanMode.depth))
    {
        writeln(file.name);
        foreach (line; File(file).byLine)
        {
            auto parts = line.splitter("\t");
            if (!parts.empty) // line contains something
            {
                if (parts.front.startsWith('#')) // if comment
                {
                    /* writeln("comment: ", parts); */
                }
                else            // otherwise magic
                {
                    const first = parts.front;
                    const firstChar = first.front;
                    if (firstChar.isDigit)
                    {
                        if (first == "0")
                        {
                            writeln("zero: ", parts);
                            parts.popFront;
                            switch (parts.front)
                            {
                                case "string":
                                    parts.popFront;
                                    writeln("string: ", parts);
                                    break;
                                default:
                                    break;
                            }
                        }
                        else
                        {
                            writeln("non-zero: ", parts);
                        }
                        magicCount++;
                    }
                    else if (firstChar == '>')
                    {
                        writeln(">: ", parts);
                        attributeCount++;
                    }
                }
            }
        }
    }

    writeln("Found ", magicCount, " number of magics");
    writeln("Found ", attributeCount, " number of attributes");
}

unittest
{
    scanMagicFiles(`/home/per/ware/file/magic/Magdir/`);
}
