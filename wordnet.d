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

        foreach (e; ["and", "or", "but", "nor", "so", "for", "yet"])
        {
            addWord(e, WordKind.coordinatingConjunction, 0, HLang.en);
        }

        foreach (e; ["och", "eller", "men", "så", "för", "ännu"])
        {
            addWord(e, WordKind.coordinatingConjunction, 0, HLang.sv);
        }

        foreach (e; ["since", "ago", "before", "past"])
        {
            addWord(e, WordKind.prepositionTime, 0, HLang.en);
        }

        // TODO: Use all at http://www.ego4u.com/en/cram-up/grammar/prepositions
        foreach (e; ["to", "at", "of", "on", "off", "in", "out", "up",
                     "down", "from", "with", "into", "for", "about",
                     "between",
                     "till", "until",
                     "by", "out of", "towards", "through", "across",
                     "above", "over", "below", "under", "next to", "beside"])
        {
            addWord(e, WordKind.preposition, 0, HLang.en);
        }

        /* undefinite articles */
        foreach (e; ["a", "an"]) {
            addWord(e, WordKind.articleUndefinite, 0, HLang.en);
        }
        foreach (e; ["ein", "eine", "eines", "einem", "einen", "einer"]) {
            addWord(e, WordKind.articleUndefinite, 0, HLang.de);
        }
        foreach (e; ["un", "une", "des"]) {
            addWord(e, WordKind.articleUndefinite, 0, HLang.fr);
        }
        foreach (e; ["en", "ena", "ett"]) {
            addWord(e, WordKind.articleUndefinite, 0, HLang.sv);
        }

        /* definite articles */
        foreach (e; ["the"]) {
            addWord(e, WordKind.articleDefinite, 0, HLang.en);
        }
        foreach (e; ["der", "die", "das", "des", "dem", "den"]) {
            addWord(e, WordKind.articleDefinite, 0, HLang.de);
        }
        foreach (e; ["le", "la", "l'", "les"]) {
            addWord(e, WordKind.articleDefinite, 0, HLang.fr);
        }
        foreach (e; ["den", "det"]) {
            addWord(e, WordKind.articleDefinite, 0, HLang.sv);
        }

        /* partitive articles */
        foreach (e; ["some"]) {
            addWord(e, WordKind.articlePartitive, 0, HLang.en);
        }
        foreach (e; ["du", "de", "la", "de", "l'", "des"]) {
            addWord(e, WordKind.articlePartitive, 0, HLang.fr);
        }

        /* personal pronoun */
        foreach (e; ["I", "me",  "you", "it"]) {
            addWord(e, WordKind.pronounPersonalSingular, 0, HLang.en);
        }
        foreach (e; ["he", "him"]) {
            addWord(e, WordKind.pronounPersonalSingularMale, 0, HLang.en);
        }
        foreach (e; ["she", "her"]) {
            addWord(e, WordKind.pronounPersonalSingularFemale, 0, HLang.en);
        }

        foreach (e; ["jag", "mig", // 1st person
                     "du", "dig", // 2nd person
                     "den", "det"]) { // 3rd person
            addWord(e, WordKind.pronounPersonalSingular, 0, HLang.sv);
        }
        foreach (e; ["han", "honom"]) {
            addWord(e, WordKind.pronounPersonalSingularMale, 0, HLang.sv);
        }
        foreach (e; ["hon", "henne"]) {
            addWord(e, WordKind.pronounPersonalSingularFemale, 0, HLang.sv);
        }

        foreach (e; ["we", "us", // 1st person
                     "you", // 2nd person
                     "they", "them"]) // 3rd person
        {
            addWord(e, WordKind.pronounPersonalPlural, 0, HLang.en);
        }
        foreach (e; ["vi", "oss", // 1st person
                     "ni", // 2nd person
                     "de", "dem"]) // 3rd person
        {
            addWord(e, WordKind.pronounPersonalPlural, 0, HLang.sv);
        }

        /* TODO: near/far in distance/time , singular, plural */
        foreach (e; ["this", "that",
                     "these", "those"]) {
            addWord(e, WordKind.pronounDemonstrative, 0, HLang.en);
        }

        /* TODO: near/far in distance/time , singular, plural */
        foreach (e; ["den här", "den där",
                     "de här", "de där"]) {
            addWord(e, WordKind.pronounDemonstrative, 0, HLang.sv);
        }

        foreach (e; ["my", "your"]) {
            addWord(e, WordKind.adjectivePossessiveSingular, 0, HLang.en);
        }
        foreach (e; ["our", "their"]) {
            addWord(e, WordKind.adjectivePossessivePlural, 0, HLang.en);
        }

        foreach (e; ["mine", "yours"]) /* 1st person */ {
            addWord(e, WordKind.pronounPossessiveSingular, 0, HLang.en);
        }
        foreach (e; ["his"]) {
            addWord(e, WordKind.pronounPossessiveSingularMale, 0, HLang.en);
        }
        foreach (e; ["hers"]) {
            addWord(e, WordKind.pronounPossessiveSingularFemale, 0, HLang.en);
        }

        foreach (e; ["min", /* 1st person */ "din", /* 2nd person */ ]) {
            addWord(e, WordKind.pronounPossessiveSingular, 0, HLang.sv);
        }
        foreach (e; ["hans"]) {
            addWord(e, WordKind.pronounPossessiveSingularMale, 0, HLang.sv);
        }
        foreach (e; ["hennes"]) {
            addWord(e, WordKind.pronounPossessiveSingularFemale, 0, HLang.sv);
        }
        foreach (e; ["dens", "dets", /* 3rd person */ ]) {
            addWord(e, WordKind.pronounPossessiveSingularNeutral, 0, HLang.sv);
        }

        foreach (e; ["ours", // 1st person
                     "yours", // 2nd person
                     "theirs" // 3rd person
                     ])
        {
            addWord(e, WordKind.pronounPossessivePlural, 0, HLang.en);
        }

        foreach (e; ["vår", // 1st person
                     "er", // 2nd person
                     "deras" // 3rd person
                     ])
        {
            addWord(e, WordKind.pronounPossessivePlural, 0, HLang.sv);
        }
        foreach (e; ["who", "whom", "what", "which", "whose",
                     "whoever", "whatever", "whichever"]) {
            addWord(e, WordKind.pronounInterrogative, 0, HLang.sv);
        }
        foreach (e; ["vem", "som", "vad", "vilken", "vems"]) {
            addWord(e, WordKind.pronounInterrogative, 0, HLang.sv);
        }

        foreach (e; ["after", "although", "as", "as if", "as long as",
                     "because", "before", "even if", "even though", "if",
                     "once", "provided", "since", "so that", "that",
                     "though", "till", "unless", "until", "what",
                     "when", "whenever", "wherever", "whether", "while"])
        {
            addWord(e, WordKind.subordinatingConjunction, 0, HLang.en);
        }

        foreach (e; ["accordingly", "additionally", "again", "almost",
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
            addWord(e, WordKind.conjunctiveAdverb, 0, HLang.en);
        }

        /* weekdays */
        foreach (e; ["monday", "tuesday", "wednesday", "thursday", "friday",
                     "saturday", "sunday"]) {
            addWord(e, WordKind.nounWeekday, 0, HLang.en);
        }
        foreach (e; ["montag", "dienstag", "mittwoch", "donnerstag", "freitag",
                     "samstag", "sonntag"]) {
            addWord(e, WordKind.nounWeekday, 0, HLang.de);
        }
        foreach (e; ["måndag", "tisdag", "onsdag", "torsdag", "fredag",
                     "lördag", "söndag"]) {
            addWord(e, WordKind.nounWeekday, 0, HLang.sv);
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
                if (kind != e.kind &&
                    kind.memberOf(e.kind))
                {
                    writeln("Specializing ", e.kind, " => ", kind, " for lemma ", lemma);
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
