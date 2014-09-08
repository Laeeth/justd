module wordnet;

import languages: WordCategory;

struct Word
{
    string name;
    WordCategory category;
    ubyte synsetCount; // Number of senses (meanings).
}

class WordNet
{
    import std.algorithm, std.stdio, std.string, std.range, std.ascii, std.utf, std.path, std.conv;

    this(string dirPath)
    {
        auto fixed = dirPath.expandTilde;
        alias nPath = buildNormalizedPath;
        read(nPath(fixed, "index.adj"));
        read(nPath(fixed, "index.adv"));
        read(nPath(fixed, "index.noun"));
        read(nPath(fixed, "index.verb"));
    }

    void read(string path)
    {
        writeln(path);
        auto file = File(path);
        foreach (line; file.byLine)
        {
            if (!line.front.isWhite) // if first is not space
            {
                auto words = line.split;
                const name = words[0];
                WordCategory category;
                with (WordCategory)
                {
                    final switch (words[1].front)
                    {
                        case 'n': category = noun; break;
                        case 'v': category = verb; break;
                        case 'a': category = adjective; break;
                        case 'r': category = adverb; break;
                    }
                }
                _data[name] = Word(name.dup, category, words[2].to!ubyte);
            }
        }
    }

    Word[string] _data;
}

unittest
{
    auto wn = new WordNet("~/WordNet-3.0/dict");
}
