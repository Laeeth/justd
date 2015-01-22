#!/usr/bin/rdmd

pragma(lib, "curl");

void readNordicNames()
{
    import std.string: strip;
    import std.range: empty;
    import std.path: expandTilde, buildNormalizedPath;
    import std.file: dirEntries, SpanMode, readText;
    import std.stdio: writeln;
    import std.algorithm: joiner, findSplitBefore, findSplitAfter, endsWith, startsWith, until, split, findSkip;
    import std.conv: to;
    import std.net.curl;
    import std.array: array;
    import arsd.dom;
    import separators;
    import grammars: Gender;
    import skip_ex: skipOverBack;

    const dirPath = `~/Knowledge/nordic_names/wiki`;
    const fixedPath = dirPath.expandTilde.buildNormalizedPath;

    size_t nameIx = 0;
    foreach (fileName; fixedPath.dirEntries(SpanMode.shallow))
    {
        writeln(`Scanning `, fileName, ` ...`);
        auto doc = new Document(readText(fileName));

        // decode name and gender
        Gender gender;
        if (!doc.title.empty)
        {
            auto name = doc.title.until(`-`).array.strip;
            if (name.skipOverBack(` m`))
            {
                gender = Gender.male;
            }
            else if (name.skipOverBack(` f`))
            {
                gender = Gender.female;
            }
            writeln("Name: ", name);
            writeln("Gender: ", gender);
        }

        const author = doc.getMeta("author");
        if (!author.empty) writeln(`Author: `, author);

        // foreach (a; doc.querySelectorAll(`a[href]`)) {}

        foreach (h2; doc.querySelectorAll(`h2`)) { /* writeln(h2.children); */ }

        size_t pIx = 0;
        string[] fields;
        string[] langs;
        string explanation;
        string seeAlso;
        string stat;
        foreach (p; doc.querySelectorAll(`h2 + p`))
        {
            const text = p.innerText.strip;
            switch (pIx)
            {
                case 0:
                    langs = text.split;
                    writeln("Languages: ", langs);
                    break;
                case 1:
                    explanation = text.findSplitBefore(`[`)[0];
                    writeln("Explanation: ", explanation);
                    break;
                case 2:
                    seeAlso = text.findSplitAfter(`See `)[1].findSplitBefore(`[`)[0];
                    writeln("See: ", seeAlso);
                    break;
                case 3:
                    if (!text.startsWith(`No recent statistics trend found in databases for`))
                    {
                        stat = text;
                        writeln("Stat: ", stat);
                    }
                    break;
                default:
                    writeln(` -- "`, text, `"`); // innerText or directText
                    break;
            }
            ++pIx;
        }

        const line = fields.joiner(roleSeparator.to!string);
        writeln(``);

        if (nameIx >= 100000) break;
        ++nameIx;
    }
}

void main()
{
    readNordicNames();
}
