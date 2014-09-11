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
        // NOTE: Test both read variants through alternating uses of Mmfile or not
        readIndex(nPath(fixed, "index.adj"), false);
        readIndex(nPath(fixed, "index.adv"), true);
        readIndex(nPath(fixed, "index.noun"), false);
        readIndex(nPath(fixed, "index.verb"), true);

        foreach (lemma; ["and", "or", "but", "nor", "so", "for", "yet"])
        {
            set(lemma, WordCategory.coordinatingConjunction, 0);
        }

        foreach (lemma; ["since",
                         "ago",
                         "before",
                         "past",
                         ])
        {
            set(lemma, WordCategory.prepositionTime, 0);
        }

        // TODO: Use all at http://www.ego4u.com/en/cram-up/grammar/prepositions
        foreach (lemma; ["to", "at", "of", "on", "off", "in", "out", "up",
                         "down", "from", "with", "into", "for", "about",
                         "between",
                         "till", "until",
                         "by", "out of", "towards", "through", "across",
                         "above", "over", "below", "under", "next to", "beside"])
        {
            set(lemma, WordCategory.preposition, 0);
        }

        foreach (lemma; ["a", "the"])
        {
            set(lemma, WordCategory.article, 0);
        }

        foreach (lemma; ["after", "although", "as", "as if", "as long as",
                         "because", "before", "even if", "even though", "if",
                         "once", "provided", "since", "so that", "that",
                         "though", "till", "unless", "until", "what",
                         "when", "whenever", "wherever", "whether", "while"])
        {
            set(lemma, WordCategory.subordinatingConjunction, 0);
        }

        foreach (lemma; ["accordingly", "additionally", "again", "almost",
                         "although", "anyway", "as a result", "besides",
                         "certainly", "comparatively", "consequently",
                         "contrarily", "conversely", "elsewhere", "equally",
                         "eventually", "finally", "further", "furthermore",
                         "hence", "henceforth", "however", "in addition", "in
                         comparison", "in contrast", "in fact", "incidentally",
                         "indeed", "instead", "just as", "likewise",
                         "meanwhile", "moreover", "namely", "nevertheless",
                         "next", "nonetheless", "notably", "now", "otherwise",
                         "rather", "similarly", "still", "subsequently", "that
                         is", "then", "thereafter", "therefore", "thus",
                         "undoubtedly", "uniquely", "on the other hand", "also",
                         "for example", "for instance", "of course", "on the
                         contrary", "so far", "until now", "thus" ])
        {
            set(lemma, WordCategory.conjunctiveAdverb, 0);
        }
    }

    auto set(string lemma, WordCategory category, ubyte synsetCount)
    {
        if (lemma in _words)
        {
            auto existing = _words[lemma];
            auto hit = existing.find!(meaning => meaning.category == WordCategory.adverb);
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

    WordMeaning[] meaningsOf(string lemma)
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
                case 'r': category = adverb; break;
                default: category = unknown; break;
            }
        }
        return category;
    }

    void readIndexLine(R, N)(R line, N lnr)
    {
        if (!line.empty &&
            !line.front.isWhite) // if first is not space. TODO: move this check
        {
            static if (isSomeString!R)
            {
                const linestr = line;
            }
            else
            {
                const linestr = cast(string)line.idup; // TODO: Why is this needed? And why does this fail?
            }
            /* pragma(msg, typeof(line).stringof); */
            /* pragma(msg, typeof(line.idup).stringof); */
            const words        = linestr.split; // TODO: Non-eager split?
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

    auto pageSize() @trusted
    {
        version(linux)
        {
            import core.sys.posix.sys.shm: __getpagesize;
            return __getpagesize();
        }
        else
        {
            return 4096;
        }
    }

    /** Read WordNet Index File $(D fileName).
        Manual page: wndb
    */
    void readIndex(string fileName, bool useMmFile = false)
    {
        import algorithm_ex: byLine;
        size_t lnr;
        /* TODO: Functionize and merge with conceptnet5.readCSV */
        if (useMmFile)
        {
            import std.mmfile: MmFile;
            auto mmf = new MmFile(fileName, MmFile.Mode.read, 0, null, pageSize);
            const data = cast(ubyte[])mmf[];
            import algorithm_ex: byLine;
            foreach (line; data.byLine)
            {
                readIndexLine(line, lnr);
                lnr++;
            }
        }
        else
        {
            foreach (line; File(fileName).byLine)
            {
                readIndexLine(line, lnr);
                lnr++;
            }
        }
        writeln("Read ", lnr, " words from ", fileName);
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

/* /\** Lookup WordCategory from Textual $(D x). */
/* *\/ */
/* auto to(T: WordCategory[], S)(S x) if (isSomeString!S || */
/*                                      isSomeChar!S) */
/* { */
/* } */

unittest
{
    auto wn = new WordNet("~/Knowledge/WordNet-3.0/dict");
    writeln(wn.meaningsOf("car"));
    writeln(wn.meaningsOf("trout"));
    writeln(wn.meaningsOf("seal"));
    writeln(wn.meaningsOf("and"));
    writeln(wn.meaningsOf("or"));
    writeln(wn.meaningsOf("script"));
    writeln(wn.meaningsOf("shell"));
    writeln(wn.meaningsOf("soon"));
    writeln(wn.meaningsOf("long"));
    writeln(wn.meaningsOf("longing"));
    writeln(wn.meaningsOf("at"));
    writeln(wn.meaningsOf("a"));
}
