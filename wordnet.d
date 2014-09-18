#!/usr/bin/env rdmd-dev-module

/** WordNet
    */
module wordnet;

import languages;
import std.algorithm, std.stdio, std.string, std.range, std.ascii, std.utf, std.path, std.conv, std.typecons, std.array;

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

        const hlang = HLang.en;
        readIndex(nPath(fixed, "index.adj"), false, hlang);
        readIndex(nPath(fixed, "index.adv"), false, hlang);
        readIndex(nPath(fixed, "index.noun"), false, hlang);
        readIndex(nPath(fixed, "index.verb"), false, hlang);

        foreach (lemma; ["and", "or", "but", "nor", "so", "for", "yet"])
        {
            addWord(lemma, WordKind.coordinatingConjunction, 0, HLang.en);
        }

        foreach (lemma; ["since",
                         "ago",
                         "before",
                         "past",
                         ])
        {
            addWord(lemma, WordKind.prepositionTime, 0, HLang.en);
        }

        // TODO: Use all at http://www.ego4u.com/en/cram-up/grammar/prepositions
        foreach (lemma; ["to", "at", "of", "on", "off", "in", "out", "up",
                         "down", "from", "with", "into", "for", "about",
                         "between",
                         "till", "until",
                         "by", "out of", "towards", "through", "across",
                         "above", "over", "below", "under", "next to", "beside"])
        {
            addWord(lemma, WordKind.preposition, 0, HLang.en);
        }

        /* undefinite articles */
        foreach (lemma; ["a", "an"]) {
            addWord(lemma, WordKind.articleUndefinite, 0, HLang.en);
        }
        foreach (lemma; ["ein", "eine", "eines", "einem", "einen", "einer"]) {
            addWord(lemma, WordKind.articleUndefinite, 0, HLang.de);
        }
        foreach (lemma; ["un", "une", "des"]) {
            addWord(lemma, WordKind.articleUndefinite, 0, HLang.fr);
        }
        foreach (lemma; ["en", "ena", "ett"]) {
            addWord(lemma, WordKind.articleUndefinite, 0, HLang.sv);
        }

        /* definite articles */
        foreach (lemma; ["the"]) {
            addWord(lemma, WordKind.articleDefinite, 0, HLang.en);
        }
        foreach (lemma; ["der", "die", "das", "des", "dem", "den"]) {
            addWord(lemma, WordKind.articleDefinite, 0, HLang.de);
        }
        foreach (lemma; ["le", "la", "l'", "les"]) {
            addWord(lemma, WordKind.articleDefinite, 0, HLang.fr);
        }
        foreach (lemma; ["den", "det"]) {
            addWord(lemma, WordKind.articleDefinite, 0, HLang.sv);
        }

        /* partitive articles */
        foreach (lemma; ["some"]) {
            addWord(lemma, WordKind.articlePartitive, 0, HLang.en);
        }
        foreach (lemma; ["du", "de", "la", "de", "l'", "des"]) {
            addWord(lemma, WordKind.articlePartitive, 0, HLang.fr);
        }

        /* personal pronoun */
        foreach (lemma; ["I", "me", "you", "she", "her", "he", "him", "it"]) {
            addWord(lemma, WordKind.pronounPersonalSingular, 0, HLang.en);
        }
        foreach (lemma; ["jag", "mig", // 1st person
                         "du", "dig", // 2nd person
                         "han", "honom", // 3rd person
                         "hon", "henne", // 3rd person
                         "den", "det"]) { // 3rd person
            addWord(lemma, WordKind.pronounPersonalSingular, 0, HLang.sv);
        }

        foreach (lemma; ["we", "us", // 1st person
                         "you", // 2nd person
                         "they", "them"]) // 3rd person
        {
            addWord(lemma, WordKind.pronounPersonalPlural, 0, HLang.en);
        }
        foreach (lemma; ["vi", "oss", // 1st person
                         "ni", // 2nd person
                         "de", "dem"]) // 3rd person
        {
            addWord(lemma, WordKind.pronounPersonalPlural, 0, HLang.sv);
        }

        /* TODO: near/far in distance/time , singular, plural */
        foreach (lemma; ["this", "that",
                         "these", "those"])
        {
            addWord(lemma, WordKind.pronounDemonstrative, 0, HLang.en);
        }

        /* TODO: near/far in distance/time , singular, plural */
        foreach (lemma; ["den här", "den där",
                         "de här", "de där"])
        {
            addWord(lemma, WordKind.pronounDemonstrative, 0, HLang.sv);
        }

        foreach (lemma; ["mine", // 1st person
                         "yours", // 2nd person
                         "his", "hers", "its", // 3rd person
                     ])
        {
            addWord(lemma, WordKind.pronounPossessiveSingular, 0, HLang.en);
        }

        foreach (lemma; ["min", // 1st person
                         "din", // 2nd person
                         "hans", "hennes", "dens", "dets", // 3rd person
                     ])
        {
            addWord(lemma, WordKind.pronounPossessiveSingular, 0, HLang.sv);
        }

        foreach (lemma; ["ours", // 1st person
                         "yours", // 2nd person
                         "theirs" // 3rd person
                     ])
        {
            addWord(lemma, WordKind.pronounPossessivePlural, 0, HLang.en);
        }

        foreach (lemma; ["vår", // 1st person
                         "er", // 2nd person
                         "deras" // 3rd person
                     ])
        {
            addWord(lemma, WordKind.pronounPossessivePlural, 0, HLang.sv);
        }

        foreach (lemma; ["after", "although", "as", "as if", "as long as",
                         "because", "before", "even if", "even though", "if",
                         "once", "provided", "since", "so that", "that",
                         "though", "till", "unless", "until", "what",
                         "when", "whenever", "wherever", "whether", "while"])
        {
            addWord(lemma, WordKind.subordinatingConjunction, 0, HLang.en);
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
            addWord(lemma, WordKind.conjunctiveAdverb, 0, HLang.en);
        }

        /* weekdays */
        foreach (lemma; ["monday", "tuesday", "wednesday", "thursday", "friday",
                         "saturday", "sunday"]) {
            addWord(lemma, WordKind.nounWeekday, 0, HLang.en);
        }
        foreach (lemma; ["montag", "dienstag", "mittwoch", "donnerstag", "freitag",
                         "samstag", "sonntag"]) {
            addWord(lemma, WordKind.nounWeekday, 0, HLang.de);
        }
        foreach (lemma; ["måndag", "tisdag", "onsdag", "torsdag", "fredag",
                         "lördag", "söndag"]) {
            addWord(lemma, WordKind.nounWeekday, 0, HLang.sv);
        }

        // TODO: Learn: adjective strong <=> noun strength
    }

    /** Store $(D lemma) as $(D kind) in language $(D hlang). */
    auto addWord(string lemma, WordKind kind, ubyte synsetCount,
                 HLang hlang = HLang.unknown)
    {
        if (lemma in _words)
        {
            auto existing = _words[lemma];
            foreach (e; existing) // for each possible more general kind
            {
                writeln(e.kind, " => ", kind, " for lemma ", lemma);
                if (kind != e.kind &&
                    kind.memberOf(e.kind))
                {
                    e.kind = kind; // specialize
                    return this;
                }
            }
        }

        uint[] links;
        _words[lemma] ~= WordSense(kind, synsetCount, links, hlang);
        return this;
    }

    /** Get Possible Meanings of $(D lemma) in all $(D hlangs).
        TODO: filter on hlangs if hlangs is non-empty.
     */
    WordSense[] meaningsOf(S)(S lemma,
                              HLang[] hlangs = []) if (isSomeString!S)
    {
        typeof(return) senses;
        const lower = lemma.toLower;
        if (lower in _words)
        {
            senses = _words[lower];
            if (!hlangs.empty)
            {
                senses = senses.filter!(sense => !hlangs.find(sense.hlang).empty).array;
            }
        }
        return senses;
    }

    /** Return true if $(D lemma) can mean a $(D kind) in any of $(D
        hlangs).
    */
    auto canMean(S)(S lemma,
                    WordKind kind,
                    HLang[] hlangs = []) if (isSomeString!S)
    {
        import std.algorithm: canFind;
        return meaningsOf(lemma, hlangs).canFind!(meaning => meaning.kind.memberOf(kind));
    }


    void readIndexLine(R, N)(R line, N lnr,
                             HLang hlang = HLang.unknown,
                             bool useMmFile = false)
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
            const lemma        = words[0].idup; // NOTE: Stuff fails if this is set
            const pos          = words[1];
            const synset_cnt   = words[2].to!uint;
            const p_cnt        = words[3].to!uint;
            const ptr_symbol   = words[4..4+p_cnt];
            const sense_cnt    = words[4+p_cnt].to!uint;
            const tagsense_cnt = words[5+p_cnt].to!uint;
            const synset_off   = words[6+p_cnt].to!uint;
            auto links         = words[6+p_cnt..$].map!(a => a.to!uint).array;
            auto meaning       = WordSense(words[1].front.decodeWordKind,
                                           words[2].to!ubyte,
                                           links,
                                           hlang);
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
    void readIndex(string fileName, bool useMmFile = false,
                   HLang hlang = HLang.unknown)
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
                    readIndexLine(line, lnr, hlang, useMmFile);
                    lnr++;
                }
            }
        }
        else
        {
            foreach (line; File(fileName).byLine)
            {
                readIndexLine(line, lnr, hlang);
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

    assert(wn.canMean("car", WordKind.noun, [HLang.en]));
    assert(wn.canMean("måndag", WordKind.nounWeekday, [HLang.sv]));
    assert(!wn.canMean("longing", WordKind.verb, [HLang.en]));
}
