module wordnet;

import languages: WordGroup;

struct Word
{
    string name;
    WordGroup group;
    ubyte synsetCount; // Number of senses (meanings).
}

class WordNet
{
    import std.algorithm, std.stdio, std.string, std.range, std.ascii, std.utf, std.path, std.conv;

    this(string dirPath)
    {
        auto fixed = dirPath.expandTilde;
        read(buildNormalizedPath(fixed, "index.adj"));
        read(buildNormalizedPath(fixed, "index.adv"));
        read(buildNormalizedPath(fixed, "index.noun"));
        read(buildNormalizedPath(fixed, "index.verb"));
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
                WordGroup group;
                with (WordGroup)
                {
                    final switch (words[1].front)
                    {
                        case 'n': group = noun; break;
                        case 'v': group = verb; break;
                        case 'a': group = adjective; break;
                        case 'r': group = adverb; break;
                    }
                }
                _data[name] = Word(name.dup, group, words[2].to!ubyte);
            }
        }
    }

    Word[string] _data;
}

unittest
{
    auto wn = new WordNet("~/WordNet-3.0/dict");
}
