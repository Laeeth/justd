module wordnet;

import languages: WordCategory;
import std.algorithm, std.stdio, std.string, std.range, std.ascii, std.utf, std.path, std.conv, std.typecons, std.array;

/** WordMeaning Interpretation. */
struct WordMeaning
{
    WordCategory category;
    ubyte synsetCount; // Number of senses (meanings).
    uint[] links;
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

        foreach (lemma; ["and", "or", "but", "nor", "so", "for", "yet"])
        {
            set(lemma, WordCategory.coordinatingConjunction, 1);
        }

        foreach (lemma; ["after", "although", "as", "as if", "as long as",
                        "because", "before", "even if", "even though", "if",
                        "once", "provided", "since", "so that", "that",
                        "though", "till", "unless", "until", "what", "
                        when", "whenever", "wherever", "whether", "while"])
        {
            set(lemma, WordCategory.subordinatingConjunction, 1);
        }

        foreach (lemma; [
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
            set(lemma, WordCategory.conjunctiveAdverb, 1);
        }
    }

    auto set(string lemma, WordCategory category, ubyte synsetCount)
    {
        if (lemma in _words)
        {
            auto existing = _words[lemma];
            auto hit = existing.find!(meaning => meaning.category == WordCategory.anyAdverb);
            if (!hit.empty &&
                category == WordCategory.conjunctiveAdverb)
            {
                hit.front.category = category; // specializing
                return this;
            }
        }
        _words[lemma] ~= WordMeaning(category, synsetCount);
        return this;
    }

    WordMeaning[] get(string lemma)
    {
        typeof(return) word;
        const lower = lemma.toLower;
        if (lower in _words)
        {
            word = _words[lower];
        }
        return word;
    }

    WordCategory parseCategory(dchar x)
    {
        WordCategory category;
        with (WordCategory)
        {
            switch (x)
            {
                case 'n': category = noun; break;
                case 'v': category = verb; break;
                case 'a': category = adjective; break;
                case 'r': category = anyAdverb; break;
                default: category = unknown; break;
            }
        }
        return category;
    }

    /** Read WordNet Index File $(D filename).
        Manual page: wndb
    */
    void read(string filename)
    {
        foreach (line; File(filename).byLine)
        {
            if (!line.front.isWhite) // if first is not space. TODO: move this check
            {
                const words        = line.split; // TODO: Non-eager split?
                const lemma        = words[0].idup;
                const pos          = words[1];
                const synset_cnt   = words[2].to!uint;
                const p_cnt        = words[3].to!uint;
                const ptr_symbol   = words[4..4+p_cnt];
                const sense_cnt    = words[4+p_cnt].to!uint;
                const tagsense_cnt = words[5+p_cnt].to!uint;
                const synset_off   = words[6+p_cnt].to!uint;
                auto links         = words[6+p_cnt..$].map!(a => a.to!uint).array;
                auto meaning       = WordMeaning(parseCategory(words[1].front),
                                                 words[2].to!ubyte,
                                                 links);
                debug assert(synset_cnt == sense_cnt);
                _words[lemma] ~= meaning;
            }
        }
    }

    WordMeaning[][string] _words;
}

/** Decode Ambiguous Meaning(s) of string $(D s). */
version(none)
// TODO: This gives error. Fix.
private auto to(T: WordMeaning[], S)(S x) if (isSomeString!S ||
                                              isSomeChar!S)
{
    T meanings;
    return meanings;
}

unittest
{
    auto wn = new WordNet("~/Knowledge/WordNet-3.0/dict");
    writeln(wn.get("car"));
    writeln(wn.get("trout"));
    writeln(wn.get("seal"));
    writeln(wn.get("and"));
    writeln(wn.get("or"));
    writeln(wn.get("script"));
    writeln(wn.get("shell"));
    writeln(wn.get("soon"));
    writeln(wn.get("long"));
    writeln(wn.get("longing"));
}
