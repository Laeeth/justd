#!/usr/bin/env rdmd-dev-module

/** WordNet
    */
module wordnet;

import languages;
import std.algorithm, std.stdio, std.string, std.range, std.ascii, std.utf, std.path, std.conv, std.typecons, std.array;

/** Word Sense/Meaning/Interpretation. */
struct WordSense
{
    WordCategory category;
    ubyte synsetCount; // Number of senses (meanings).
    uint[] links;
    HLang hlang;
}

/** WordNet */
class WordNet
{
    /** WordNet Semantic Relation Type Code.
        See also: conceptnet5.Relation
    */
    enum Relation:ubyte
    {
        unknown,
        attribute,
        causes,
        classifiedByRegion,
        classifiedByUsage,
        classifiedByTopic,
        entails,
        hyponymOf, // also called hyperonymy, hyponymy,
        instanceOf,
        memberMeronymOf,
        partMeronymOf,
        sameVerbGroupAs,
        similarTo,
        substanceMeronymOf,
        antonymOf,
        derivationallyRelated,
        pertainsTo,
        seeAlso,
    }

    this(string dirPath)
    {
        auto fixed = dirPath.expandTilde;
        alias nPath = buildNormalizedPath;
        // NOTE: Test both read variants through alternating uses of Mmfile or not
        readIndex(nPath(fixed, "index.adj"), false);
        readIndex(nPath(fixed, "index.adv"), false);
        readIndex(nPath(fixed, "index.noun"), false);
        readIndex(nPath(fixed, "index.verb"), false);

        foreach (lemma; ["and", "or", "but", "nor", "so", "for", "yet"])
        {
            addWord(lemma, WordCategory.coordinatingConjunction, 0, HLang.en);
        }

        foreach (lemma; ["since",
                         "ago",
                         "before",
                         "past",
                         ])
        {
            addWord(lemma, WordCategory.prepositionTime, 0, HLang.en);
        }

        // TODO: Use all at http://www.ego4u.com/en/cram-up/grammar/prepositions
        foreach (lemma; ["to", "at", "of", "on", "off", "in", "out", "up",
                         "down", "from", "with", "into", "for", "about",
                         "between",
                         "till", "until",
                         "by", "out of", "towards", "through", "across",
                         "above", "over", "below", "under", "next to", "beside"])
        {
            addWord(lemma, WordCategory.preposition, 0, HLang.en);
        }

        /* undefinite articles */
        foreach (lemma; ["a", "an"]) {
            addWord(lemma, WordCategory.articleUndefinite, 0, HLang.en);
        }
        foreach (lemma; ["ein", "eine", "eines", "einem", "einen", "einer"]) {
            addWord(lemma, WordCategory.articleUndefinite, 0, HLang.de);
        }
        foreach (lemma; ["un", "une", "des"]) {
            addWord(lemma, WordCategory.articleUndefinite, 0, HLang.fr);
        }
        foreach (lemma; ["en", "ena", "ett"]) {
            addWord(lemma, WordCategory.articleUndefinite, 0, HLang.sv);
        }

        /* definite articles */
        foreach (lemma; ["the"]) {
            addWord(lemma, WordCategory.articleDefinite, 0, HLang.en);
        }
        foreach (lemma; ["der", "die", "das", "des", "dem", "den"]) {
            addWord(lemma, WordCategory.articleDefinite, 0, HLang.de);
        }
        foreach (lemma; ["le", "la", "l'", "les"]) {
            addWord(lemma, WordCategory.articleDefinite, 0, HLang.fr);
        }
        foreach (lemma; ["den", "det"]) {
            addWord(lemma, WordCategory.articleDefinite, 0, HLang.sv);
        }

        /* partitive articles */
        foreach (lemma; ["some"]) {
            addWord(lemma, WordCategory.articlePartitive, 0, HLang.en);
        }
        foreach (lemma; ["du", "de", "la", "de", "l'", "des"]) {
            addWord(lemma, WordCategory.articlePartitive, 0, HLang.fr);
        }

        /* personal pronoun */
        foreach (lemma; ["I", "me", "you", "she", "her", "he", "him", "it"]) {
            addWord(lemma, WordCategory.pronounPersonalSingular, 0, HLang.en);
        }
        foreach (lemma; ["we", "us", "you", "they", "them"]) {
            addWord(lemma, WordCategory.pronounPersonalPlural, 0, HLang.en);
        }

        /* TODO: near/far in distance/time , singular, plural */
        foreach (lemma; ["this", "that",
                         "these", "those"])
        {
            addWord(lemma, WordCategory.pronounDemonstrative, 0, HLang.en);
        }

        foreach (lemma; ["mine", // 1st person singular
                         "yours", // 2nd person singular
                         "his", "hers", "its", // 3rd person singular
                         "ours", // 1st person plural
                         "yours", // 2nd person plural
                         "theirs" // 3rd person plural
                     ])
        {
            addWord(lemma, WordCategory.pronounPossessive, 0, HLang.en);
        }

        foreach (lemma; ["after", "although", "as", "as if", "as long as",
                         "because", "before", "even if", "even though", "if",
                         "once", "provided", "since", "so that", "that",
                         "though", "till", "unless", "until", "what",
                         "when", "whenever", "wherever", "whether", "while"])
        {
            addWord(lemma, WordCategory.subordinatingConjunction, 0, HLang.en);
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
            addWord(lemma, WordCategory.conjunctiveAdverb, 0, HLang.en);
        }

        /* weekdays */
        foreach (lemma; ["monday", "tuesday", "wednesday", "thursday", "friday",
                         "saturday", "sunday"]) {
            addWord(lemma, WordCategory.nounWeekday, 0, HLang.en);
        }
        foreach (lemma; ["montag", "dienstag", "mittwoch", "donnerstag", "freitag",
                         "samstag", "sonntag"]) {
            addWord(lemma, WordCategory.nounWeekday, 0, HLang.de);
        }
        foreach (lemma; ["måndag", "tisdag", "onsdag", "torsdag", "fredag",
                         "lördag", "söndag"]) {
            addWord(lemma, WordCategory.nounWeekday, 0, HLang.sv);
        }

        // TODO: Learn: adjective strong <=> noun strength
    }

    /** Store $(D lemma) as $(D category) in language $(D hlang). */
    auto addWord(string lemma, WordCategory category, ubyte synsetCount,
                 HLang hlang = HLang.init)
    {
        if (lemma in _words)
        {
            auto existing = _words[lemma];
            foreach (e; existing) // for each possible more general category
            {
                writeln(e.category, " => ", category, " for lemma ", lemma);
                if (category != e.category &&
                    category.memberOf(e.category))
                {
                    e.category = category; // specialize
                    return this;
                }
            }
        }

        uint[] links;
        _words[lemma] ~= WordSense(category, synsetCount, links, hlang);
        return this;
    }

    /** Get Possible Meanings of $(D lemma) in all $(D hlangs).
        TODO: Make use of hlangs.
     */
    WordSense[] meaningsOf(S)(S lemma,
                              HLang[] hlangs = []) if (isSomeString!S)
    {
        typeof(return) wordSense;
        const lower = lemma.toLower;
        if (lower in _words)
        {
            wordSense = _words[lower];
        }
        // writeln(lemma, " have sense ", wordSense);
        return wordSense;
    }

    /** Return true if $(D lemma) can mean a $(D category) in any of $(D
        hlangs).
    */
    auto canMean(S)(S lemma,
                    WordCategory category,
                    HLang[] hlangs = []) if (isSomeString!S)
    {
        import std.algorithm: canFind;
        return meaningsOf(lemma, hlangs).canFind!(meaning => meaning.category.memberOf(category));
    }


    WordCategory parseCategory(C)(C x)
        @safe @nogc pure nothrow if (isSomeChar!C)
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
            auto meaning       = WordSense(parseCategory(words[1].front),
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
        size_t lnr;
        /* TODO: Functionize and merge with conceptnet5.readCSV */
        if (useMmFile)
        {
            version (none)
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

    WordSense[][string] _words;
}

/** Decode Ambiguous Meaning(s) of string $(D s). */
version(none)
// TODO: This gives error. Fix.
private auto to(T: WordSense[], S)(S x) if (isSomeString!S ||
                                            isSomeChar!S)
{
    T meanings;
    return meanings;
}

unittest
{
    auto wn = new WordNet("~/Knowledge/wordnet/WordNet-3.0/dict");
    const words = ["car", "trout", "seal", "and", "or", "script", "shell", "soon", "long", "longing", "at", "a"];
    foreach (word; words)
    {
        writeln(word, " has meanings ", wn.meaningsOf(word));
    }
    assert(wn.canMean("car", WordCategory.noun, [HLang.en]));
    assert(!wn.canMean("longing", WordCategory.verb, [HLang.en]));
}
