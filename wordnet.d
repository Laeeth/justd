module wordnet;

import languages: WordCategory;
import std.algorithm, std.stdio, std.string, std.range, std.ascii, std.utf, std.path, std.conv, std.typecons;

struct Word
{
    string name;
    WordCategory category;
    ubyte synsetCount; // Number of senses (meanings).
}

class WordNet
{
    this(string dirPath)
    {
        auto fixed = dirPath.expandTilde;
        alias nPath = buildNormalizedPath;
        read(nPath(fixed, "index.adj"));
        read(nPath(fixed, "index.adv"));
        read(nPath(fixed, "index.noun"));
        read(nPath(fixed, "index.verb"));

        foreach (name; ["and", "or", "but", "nor", "so", "for", "yet"])
        {
            set(name, WordCategory.coordinatingConjunction, 1);
        }

        foreach (name; ["after", "although", "as", "as if", "as long as",
                        "because", "before", "even if", "even though", "if",
                        "once", "provided", "since", "so that", "that",
                        "though", "till", "unless", "until", "what", "
                        when", "whenever", "wherever", "whether", "while"])
        {
            set(name, WordCategory.subordinatingConjunction, 1);
        }

        foreach (name; [
                     "accordingly",
                     "additionally",
                     "again",
                     "almost",
                     "although",
                     "anyway",
                     "as a result",
                     "besides",
                     "certainly",
                     "comparatively",
                     "consequently",
                     "contrarily",
                     "conversely",
                     "elsewhere",
                     "equally",
                     "eventually",
                     "finally",
                     "further",
                     "furthermore",
                     "hence",
                     "henceforth",
                     "however",
                     "in addition",
                     "in comparison",
                     "in contrast",
                     "in fact",
                     "incidentally",
                     "indeed",
                     "instead",
                     "just as",
                     "likewise",
                     "meanwhile",
                     "moreover",
                     "namely",
                     "nevertheless",
                     "next",
                     "nonetheless",
                     "notably",
                     "now",
                     "otherwise",
                     "rather",
                     "similarly",
                     "still",
                     "subsequently",
                     "that is",
                     "then",
                     "thereafter",
                     "therefore",
                     "thus",
                     "undoubtedly",
                     "uniquely",
                     "on the other hand",
                     "also",
                     "for example",
                     "for instance",
                     "of course",
                     "on the contrary",
                     "so far",
                     "until now",
                     "thus"
                     ])
        {
            set(name, WordCategory.conjunctiveAdverb, 1);
        }
    }

    auto set(string name, WordCategory category, ubyte synsetCount)
    {
        if (name in _words)
        {
            const existingCategory = _words[name].category;
            assert(existingCategory == category,
                   name ~ " stored as " ~
                   existingCategory.to!string ~ " cannot be restored as " ~
                   category.to!string);
        }
        else
        {
            _words[name] = Word(name, category, synsetCount);
        }
        return this;
    }

    Word get(string name)
    {
        typeof(return) word;
        const lower = name.toLower;
        if (lower in _words)
        {
            word = _words[lower];
        }
        return word;
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
                const name = words[0].idup;
                WordCategory category;
                with (WordCategory)
                {
                    switch (words[1].front)
                    {
                        case 'n': category = noun; break;
                        case 'v': category = verb; break;
                        case 'a': category = adjective; break;
                        case 'r': category = normalAdverb; break;
                        default: category = unknown; break;
                    }
                }
                _words[name] = Word(name, category, words[2].to!ubyte);
            }
        }
    }

    Word[string] _words;
}

unittest
{
    auto wn = new WordNet("~/WordNet-3.0/dict");
    writeln(wn.get("car"));
    writeln(wn.get("trout"));
    writeln(wn.get("seal"));
    writeln(wn.get("and"));
}
