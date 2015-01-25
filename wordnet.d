#!/usr/bin/env rdmd-dev-module

/** WordNet
    */
module wordnet;

import grammars;
import std.algorithm, std.stdio, std.string, std.range, std.ascii, std.utf, std.path, std.conv, std.typecons, std.array;
import std.algorithm: canFind;
import std.container: Array;
import rcstring;
import dbg;
import assert_ex;

import knet.relations;
import knet.senses;
import knet.languages;

alias nPath = buildNormalizedPath;

/** Word Sense/Meaning/Interpretation. */
struct Entry(Links = uint[])
{
    Sense sense;
    ubyte synsetCount; // Number of senses (meanings).
    Links links;
    Lang lang;
}

/** WordNet
    TODO represent dictionaries with a Trie instead of a hash table
    TODO aspell -d sv dump master > my.dict
    TODO https://superuser.com/questions/814761/dumping-all-words-with-properties-from-an-aspell-database
 */
class WordNet(bool useArray = true,
              bool useRCString = true)
{
    /** WordNet Semantic Relation Type Code.
        See also: conceptnet5.Relation
    */
    // enum Relation:ubyte
    // {
    //     unknown,
    //     attribute,
    //     causes,
    //     classifiedByRegion,
    //     classifiedByUsage,
    //     classifiedByTopic,
    //     entails,
    //     hyponymOf, // also called hyperonymy, hyponymy,
    //     instanceOf,
    //     memberMeronymOf,
    //     partMeronymOf,
    //     sameVerbGroupAs,
    //     similarTo,
    //     substanceMeronymOf,
    //     antonymOf,
    //     derivationallyRelated,
    //     pertainsTo,
    //     seeAlso,
    // }

    alias LinkIx = uint; // link index (precision)

    /* String Storage */
    static if (useRCString) { alias Lemma = RCXString!(immutable char, 24 - 1); }
    else                    { alias Lemma = string; }

    /* Links */
    static if (useArray) { alias Links = Array!LinkIx; }
    else                 { alias Links = LinkIx[]; }

    /** Normalize Lemma $(D lemma). */
    Tuple!(S, bool) normalize(S)(S lemma,
                                 Lang lang = Lang.unknown) if (isSomeString!S)
    {
        // TODO: Use Walter's new decoder functions
        if (!lang.hasCase) // to many exceptions are thrown for languages such as Bulgarian
        {
            return tuple(lemma, false); // skip it for them for now
        }
        try
        {
            return tuple(lemma.toLower, false);
        }
        catch (core.exception.UnicodeException e) // no all language support lowercasing
        {
            return tuple(lemma, true); // so leave it as is
        }
    }

    /** Formalize Sentence $(D sentence). */
    SentencePart[] formalize(Words)(const Words words,
                                    const Lang[] langs = []) if (isSomeString!(ElementType!Words))
    {
        typeof(return) roles;
        if (canMean(words[0], Sense.noun, langs) &&
            canMean(words[1], Sense.verb, langs))
        {
            roles = [SentencePart.subject,
                     SentencePart.predicate];
        }
        return roles;
    }

    SentencePart[] formalize(S)(const S sentence,
                                const Lang[] langs = []) if (isSomeString!S)
    {
        auto roles = formalize(sentence.split!isWhite, langs); // TODO splitter
        return roles;
    }

    void readUNIXDict(const string fileName,
                      Lang lang,
                      Sense kindAll = Sense.unknown)
    {
        size_t lnr = 0;
        size_t exceptionCount = 0;
        Lemma lemmaOld;
        foreach (lemma; File(fileName).byLine)
        {
            if (lang == Lang.sv &&
                lemma.startsWith(lemmaOld) &&
                lemma.length == lemmaOld.length + 1 &&
                lemma.back == 's') // Swedish genitive noun or passive verb form
            {
                /* writeln("Skipping genitive noun ", lemma); */
            }
            else
            {
                Sense sense;
                auto split = lemma.findSplit(`'`);
                if (!split[1].empty)
                {
                    lemma = split[0]; // exclude genitive ending 's
                    sense = Sense.noun;
                }
                const normalizedLemma = normalize(lemma, lang);
                if (normalizedLemma[1])
                    exceptionCount++;

                static if (useRCString) { immutable internedLemma = Lemma(normalizedLemma[0]); }
                else                    { immutable internedLemma = normalizedLemma[0].idup; }

                lnr += addWord(internedLemma, sense, 0, lang);
            }
            lemmaOld = lemma.idup;
        }
        writeln(`Added `, lnr, ` new `, lang.toHuman, ` (`, exceptionCount, ` uncaseable) words from `, fileName);
    }

    void readWordNet(const string dirName = `~/Knowledge/wordnet/dict-3.1`)
    {
        const dictDir = dirName.expandTilde;
        // NOTE: Test both read variants through alternating uses of Mmfile or not
        const lang = Lang.en;
        readIndex(dictDir.nPath(`index.adj`), false, lang);
        readIndex(dictDir.nPath(`index.adv`), false, lang);
        readIndex(dictDir.nPath(`index.noun`), false, lang);
        readIndex(dictDir.nPath(`index.verb`), false, lang);
    }

    void readDicts(const Lang[] langs = [Lang.en, Lang.sv],
                   bool allLangs = false)
    {
        const dictDir = `~/Knowledge/dict`.expandTilde;

        // See also: https://packages.debian.org/sv/sid/wordlist
        if (allLangs || langs.canFind(Lang.sv))
            readUNIXDict(dictDir.nPath(`swedish`), Lang.sv); // TODO apt:wswedish, NOTE iso-latin-1
        if (allLangs || langs.canFind(Lang.de))
            readUNIXDict(dictDir.nPath(`ogerman`), Lang.de); // TODO old german
        if (allLangs || langs.canFind(Lang.pl))
            readUNIXDict(dictDir.nPath(`polish`), Lang.pl);
        if (allLangs || langs.canFind(Lang.pt))
            readUNIXDict(dictDir.nPath(`portuguese`), Lang.pt);
        if (allLangs || langs.canFind(Lang.es))
            readUNIXDict(dictDir.nPath(`spanish`), Lang.es);
        if (allLangs || langs.canFind(Lang.fr_ch))
            readUNIXDict(dictDir.nPath(`swiss`), Lang.fr_ch);
        if (allLangs || langs.canFind(Lang.uk))
            readUNIXDict(dictDir.nPath(`ukrainian`), Lang.uk);

        if (allLangs || langs.canFind(Lang.en))
            readUNIXDict(dictDir.nPath(`words`), Lang.en); // TODO apt:dictionaries-common
        if (allLangs || langs.canFind(Lang.en_GB))
            readUNIXDict(dictDir.nPath(`british-english-insane`), Lang.en_GB); // TODO apt:wbritish-insane
        if (allLangs || langs.canFind(Lang.en_GB))
            readUNIXDict(dictDir.nPath(`british-english-huge`), Lang.en_GB); // TODO apt:wbritish-huge
        if (allLangs || langs.canFind(Lang.en_GB))
            readUNIXDict(dictDir.nPath(`british-english`), Lang.en_GB); // TODO apt:wbritish

        if (allLangs || langs.canFind(Lang.en_US))
            readUNIXDict(dictDir.nPath(`american-english-insane`), Lang.en_US); // TODO apt:wamerican-insane
        if (allLangs || langs.canFind(Lang.en_US))
            readUNIXDict(dictDir.nPath(`american-english-huge`), Lang.en_US); // TODO apt:wamerican-huge
        if (allLangs || langs.canFind(Lang.en_US))
            readUNIXDict(dictDir.nPath(`american-english`), Lang.en_US); // TODO apt:wamerican

        if (allLangs || langs.canFind(Lang.pt_BR))
            readUNIXDict(dictDir.nPath(`brazilian`), Lang.pt_BR); // TODO apt:wbrazilian, NOTE iso-latin-1

        if (allLangs || langs.canFind(Lang.pt_BR))
            readUNIXDict(dictDir.nPath(`bulgarian`), Lang.bg); // TODO apt:wbulgarian, NOTE ISO-8859

        if (allLangs || langs.canFind(Lang.en_CA))
            readUNIXDict(dictDir.nPath(`canadian-english-insane`), Lang.en_CA);

        if (allLangs || langs.canFind(Lang.da))
            readUNIXDict(dictDir.nPath(`danish`), Lang.da);

        if (allLangs || langs.canFind(Lang.nl))
            readUNIXDict(dictDir.nPath(`dutch`), Lang.nl);

        if (allLangs || langs.canFind(Lang.fr))
            readUNIXDict(dictDir.nPath(`french`), Lang.fr);

        if (allLangs || langs.canFind(Lang.faroese))
            readUNIXDict(dictDir.nPath(`faroese`), Lang.faroese);

        if (allLangs || langs.canFind(Lang.gl))
            readUNIXDict(dictDir.nPath(`galician-minimos`), Lang.gl);

        if (allLangs || langs.canFind(Lang.de))
            readUNIXDict(dictDir.nPath(`german-medical`), Lang.de); // TODO medical german

        if (allLangs || langs.canFind(Lang.it))
            readUNIXDict(dictDir.nPath(`italian`), Lang.it);

        if (allLangs || langs.canFind(Lang.de))
            readUNIXDict(dictDir.nPath(`ngerman`), Lang.de); // new german

        if (allLangs || langs.canFind(Lang.no))
            readUNIXDict(dictDir.nPath(`nynorsk`), Lang.no);

        if (allLangs || langs.canFind(Lang.en))
            readWordNet(); // put this last to specialize existing lemma
    }

    /** Create a WordNet of languages $(D langs).
     */
    this(const Lang[] langs = [Lang.en, Lang.sv],
         bool allLangs = false)
    {
        readDicts(langs, allLangs);

        // TODO Learn: adjective strong <=> noun strength

        size_t lnr = 0;
        size_t lemmaLengthSum = 0;
        foreach (lemma, sense; _words)
        {
            lemmaLengthSum += lemma.length;
            lnr++;
        }

        writeln(`Average Lemma Length `, cast(real)lemmaLengthSum/lnr);
        writeln(`Read `, lnr, ` words`);
    }

    /** Store $(D lemma) as $(D sense) in language $(D lang).
        Return true if a new word was added, false if word was specialized.
     */
    bool addWord(S)(const S lemma, Sense sense, ubyte synsetCount,
                    Lang lang = Lang.unknown)
    {
        static if (useRCString) { const Lemma lemmaFixed = lemma; }
        else                    { immutable lemmaFixed = lemma; }
        if (lemmaFixed in _words)
        {
            auto existing = _words[lemmaFixed];
            foreach (ref e; existing) // for each possible more general sense
            {
                if (e.sense == Sense.init ||
                    (sense != e.sense &&
                     sense.specializes(e.sense)))
                {
                    e.sense = sense; // specialize
                    return false;
                }
            }
        }

        Links links;
        _words[lemmaFixed] ~= Entry!Links(sense, synsetCount, links, lang);
        return true;
    }

    /** Get Possible Meanings of $(D lemma) in all $(D langs).
        TODO filter on langs if langs is non-empty.
     */
    Entry!Links[] meaningsOf(S)(const S lemma,
                                const Lang[] langs = [])
    {
        typeof(return) senses;

        static if (useRCString) { const Lemma lowLemma = lemma.toLower; }
        else                    { immutable lowLemma = lemma.toLower; }

        if (lowLemma in _words)
        {
            senses = _words[lowLemma];
            if (!langs.empty)
            {
                senses = senses.filter!(sense => !langs.find(sense.lang).empty).array;
            }
        }
        return senses;
    }

    /** Return true if $(D lemma) can mean a $(D sense) in any of $(D
        langs).
    */
    auto canMean(S)(const S lemma,
                    const Sense sense,
                    const Lang[] langs = []) if (isSomeString!S)
    {
        return meaningsOf(lemma, langs).canFind!(entry => entry.sense.specializes(sense));
    }

    bool canMeanSomething(S)(const S lemma,
                             const Lang[] langs = []) if (isSomeString!S)
    {
        return !meaningsOf(lemma, langs).empty;
    }

    /** Check if $(D first) and $(D second) are meaningful. */
    S[] tryWordSplit(S)(S first, S second,
                        const Lang[] langs = [],
                        const bool crossLanguage = false,
                        const size_t minSize = 2,
                        bool backwards = true) if (isSomeString!S)
    {
        if (first.length >= minSize &&
            second.length >= minSize)
        {
            auto firstOk = canMeanSomething(first, langs);
            bool genitiveForm = false;
            if (!firstOk &&
                first.length >= 2 &&
                first.endsWith(`s`))
            {
                firstOk = canMeanSomething(first[0..$ - 1], langs); // TODO is there a dropEnd
                if (firstOk)
                {
                    genitiveForm = true;
                }
            }

            if (firstOk)
            {
                auto secondOk = canMeanSomething(second, langs);
                if (secondOk)
                {
                    return [first, second];
                }
                else
                {
                    auto secondSplits = findWordsSplit(second, langs, crossLanguage, minSize);
                    if (secondSplits.length >= 2)
                    {
                        return [first] ~ secondSplits;
                    }
                }
            }
        }
        return null;
    }

    /** Find First Possible Split of $(D word) with semantic meaning(s) in
        languages $(D langs).
        TODO logic using minSize may pick single character for UTF-8 characters
        such, for instance, Swedish å, ä, ö
     */
    S[] findWordsSplit(S)(const S word,
                          const Lang[] langs = [],
                          const bool crossLanguage = false,
                          const size_t minSize = 2,
                          bool backwards = true) if (isSomeString!S)
    {
        import range_ex: slidingSplitter;

        if (word.length < 2*minSize)    // need at least two parts of at least two characters
            return [word];

        if (backwards)
        {
            foreach (immutable first, second; word.slidingSplitter.retro)
            {
                if (auto split = tryWordSplit(first, second,
                                              langs, crossLanguage, minSize, backwards))
                {
                    return split;
                }
            }
        }
        else
        {
            foreach (immutable first, second; word.slidingSplitter)
            {
                if (auto split = tryWordSplit(first, second,
                                              langs, crossLanguage, minSize, backwards))
                {
                    return split;
                }
            }
        }

        return [word];
    }

    /** Find All Possible Split of $(D word) with semantic meaning(s) in
        languages $(D langs).
    */
    S[][] findWordsSplits(S)(const S word,
                             const Lang[] langs = [],
                             const bool crossLanguage = false,
                             const size_t minSize = 2) if (isSomeString!S)
    {
        return (findWordsSplits(word, langs, crossLanguage, minSize, false) ~
                findWordsSplits(word, langs, crossLanguage, minSize, true));
    }

    auto canMean(S)(S lemma,
                    Sense sense,
                    Lang lang = Lang.unknown) if (isSomeString!S)
    {
        return canMean(lemma, sense, lang == Lang.unknown ? [] : [lang]);
    }

    void readIndexLine(R, N)(const R line,
                             const N lnr,
                             const Lang lang = Lang.unknown,
                             const bool useMmFile = false)
    {
        if (!line.empty &&
            !line.front.isWhite) // if first is not space. TODO move this check
        {
            static if (isSomeString!R) { const linestr = line; }
            else                       { const linestr = cast(string)line.idup; } // TODO Why is this needed? And why does this fail?
            /* pragma(msg, typeof(line).stringof); */
            /* pragma(msg, typeof(line.idup).stringof); */
            const words        = linestr.split; // TODO Non-eager split?

            // const lemma        = words[0].idup; // NOTE: Stuff fails if this is set
            static if (useRCString) { immutable Lemma lemma = words[0]; }
            else                    { immutable lemma = words[0].idup; }

            const pos          = words[1];
            const synset_cnt   = words[2].to!uint;
            const p_cnt        = words[3].to!uint;
            const ptr_symbol   = words[4..4+p_cnt];
            const sense_cnt    = words[4+p_cnt].to!uint;
            const tagsense_cnt = words[5+p_cnt].to!uint;
            const synset_off   = words[6+p_cnt].to!uint;
            static if (useArray) { auto links = Links(words[6+p_cnt..$].map!(a => a.to!uint)); }
            else                 { auto links = words[6+p_cnt..$].map!(a => a.to!uint).array; }
            auto meaning = Entry!Links(words[1].front.decodeWordSense,
                                           words[2].to!ubyte, links, lang);
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
                   Lang lang = Lang.unknown)
    {
        size_t lnr;
        /* TODO Functionize and merge with conceptnet5.readCSV */
        if (useMmFile)
        {
            version (none)
            {
                import std.mmfile: MmFile;
                auto mmf = new MmFile(fileName, MmFile.Mode.read, 0, null, pageSize);
                const data = cast(ubyte[])mmf[];
                // import algorithm_ex: byLine;
                foreach (line; data.byLine)
                {
                    readIndexLine(line, lnr, lang, useMmFile);
                    lnr++;
                }
            }
        }
        else
        {
            foreach (line; File(fileName).byLine)
            {
                readIndexLine(line, lnr, lang);
                lnr++;
            }
        }
        writeln(`Read `, lnr, ` words from `, fileName);
    }

    Entry!Links[][Lemma] _words;
}

auto ref makeWordNet(bool useArray = true,
                     bool useRCString = true)(Lang[] langs = [Lang.en,
                                                               Lang.sv])
{
    return new WordNet!(useArray, useRCString)(langs);
}

/** Decode Ambiguous Meaning(s) of string $(D s). */
version(none)
// TODO This gives error. Fix.
private auto to(T: Entry[], S)(S x) if (isSomeString!S ||
                                            isSomeChar!S)
{
    T meanings;
    return meanings;
}

unittest
{
    enum useArray = true;
    enum useRCString = false;

    const netLangs = [Lang.en,
                      Lang.de,
                      Lang.sv,
                      Lang.br];

    auto wn = new WordNet!(useArray, useRCString)(netLangs);

    /* const words = [`car`, `trout`, `seal`, `and`, `or`, `script`, `shell`, `soon`, `long`, `longing`, `at`, `a`]; */
    /* foreach (word; words) */
    /* { */
    /*     writeln(word, ` has meanings `, */
    /*             wn.meaningsOf(word).map!(wordSense => wordSense.sense.to!string).joiner(`, `)); */
    /* } */

    if (netLangs.canFind(Lang.en))
    {
        assert(wn.canMean(`car`, Sense.noun, [Lang.en]));
        assert(wn.canMean(`car`, Sense.noun, Lang.en));
        assert(!wn.canMean(`longing`, Sense.verb, [Lang.en]));
        assert(wn.canMean(`january`, Sense.month, [Lang.en]));
    }

    if (netLangs.canFind(Lang.sv))
    {
        const langs = [Lang.sv];
        assert(wn.findWordsSplit(`kärnkraftsavfallshink`, langs) == [`kärnkrafts`, `avfalls`, `hink`]);
        assert(wn.findWordsSplit(`kärnkraftsavfallshink`, langs, false, 2, false) == [`kärnkraft`, `sav`, `falls`, `hink`]);
        assert(wn.findWordsSplit(`papperskorg`, langs) == [`pappers`, `korg`]);
        assert(wn.findWordsSplit(``, langs) == [``]);
        assert(wn.findWordsSplit(`i`, langs) == [`i`]);
        assert(wn.findWordsSplit(`biltvätt`, langs) == [`bil`, `tvätt`]);
        assert(wn.findWordsSplit(`trötthet`, langs) == [`trött`, `het`]);
        assert(wn.findWordsSplit(`paprikabit`, langs) == [`paprika`, `bit`]);
        assert(wn.findWordsSplit(`funktionsteori`, langs) == [`funktions`, `teori`]);
        assert(wn.findWordsSplit(`nyhetstorka`, langs) == [`nyhets`, `torka`]);
        assert(wn.findWordsSplit(`induktionsbevis`, langs) == [`induktions`, `bevis`]);
        assert(wn.findWordsSplit(`kärnkraftsavfall`, langs) == [`kärnkrafts`, `avfall`]);
    }

    if (netLangs.canFind(Lang.sv))
    {
        assert(wn.canMean(`måndag`, Sense.weekday, [Lang.sv]));
        assert(wn.canMean(`måndag`, Sense.noun, [Lang.sv]));
        assert(wn.canMean(`bil`, Sense.unknown, [Lang.sv]));
        assert(wn.canMean(`tvätt`, Sense.unknown, [Lang.sv]));
        assert(!wn.canMean(`måndag`, Sense.verb, [Lang.sv]));
        assert(!wn.canMean(`måndag`, Sense.adjective, [Lang.sv]));
        assert(wn.canMean(`januari`, Sense.month, [Lang.sv]));
        assert(wn.canMean(`sopstation`, Sense.unknown, [Lang.sv]));
    }

    if (netLangs.canFind(Lang.de))
    {
        assert(wn.canMean(`fenster`, Sense.unknown, [Lang.de]));
    }

    if (netLangs.canFind(Lang.en))
    {
        const langs = [Lang.en];
        assert(wn.findWordsSplit(`hashusband`, langs, false, 2, false) == [`has`, `husband`]);
        assert(wn.findWordsSplit(`physicalaction`, langs) == [`physical`, `action`]);
        assert(wn.findWordsSplit(`physicsexam`, langs) == [`physics`, `exam`]);
        assert(wn.findWordsSplit(`carwash`, langs) == [`car`, `wash`]);
        assert(wn.findWordsSplit(`biltvätt`, langs) == [`biltvätt`]);
    }

    if (netLangs.canFind(Lang.en))
    {
        const langs = [Lang.en];
        assert(wn.formalize(`Jack run`, langs) == [SentencePart.subject,
                                                   SentencePart.predicate]);
        assert(wn.formalize(`Men swim`, langs) == [SentencePart.subject,
                                                   SentencePart.predicate]);
    }

    if (false) // TODO Activate
    {
        assert(wn.formalize(`Does jack run?`, [Lang.en]) == [SentencePart.subject, // TODO Wrap in Question()
                                                              SentencePart.predicate]);

        assert(wn.formalize(`Does men swim?`, [Lang.en]) == [SentencePart.subject, // TODO Wrap in Question()
                                                              SentencePart.predicate]);

        assert(wn.formalize(`Jack and Jill`, [Lang.en]), [SentencePart.subject]);
        assert(wn.formalize(`Men can drive`, [Lang.en]), [SentencePart.subject,
                                                           SentencePart.predicate]);
        assert(wn.formalize(`Women can also drive`, [Lang.en]), [SentencePart.subject,
                                                                  SentencePart.predicate]);

        assert(wn.formalize(`The big blue car`, [Lang.en]) == [SentencePart.subject]);
        assert(wn.formalize(`A big blue car`, [Lang.en]) == [SentencePart.subject]);

        assert(wn.formalize(`Jag spelar tennis`, [Lang.sv]) == [SentencePart.subject,
                                                                 SentencePart.predicate,
                                                                 SentencePart.object]);
        assert(wn.formalize(`Biltvätt`, [Lang.sv]) == [SentencePart.subject]);
    }

    /* write(`Press enter to continue: `); */
    /* readln(); */
}
