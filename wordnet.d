#!/usr/bin/env rdmd-dev-module

/** WordNet
    */
module wordnet;

import grammars;
import std.algorithm, std.stdio, std.string, std.range, std.ascii, std.utf, std.path, std.conv, std.typecons, std.array;
import std.container: Array;
import rcstring;

alias nPath = buildNormalizedPath;

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

    alias LinkIx = uint; // link index (precision)

    /* String Storage */
    static if (useRCString) { alias Lemma = RCXString!(immutable char, 24 - 1); }
    else                    { alias Lemma = string; }

    static if (useArray) { alias Links = Array!LinkIx; }
    else                 { alias Links = LinkIx[]; }

    Tuple!(S, bool) normalize(S)(S lemma,
                                 HLang lang = HLang.unknown) if (isSomeString!S)
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

    void readUNIXDict(string fileName,
                      HLang lang,
                      WordKind kindAll = WordKind.unknown)
    {
        size_t lnr = 0;
        size_t exceptionCount = 0;
        Lemma lemmaOld;
        foreach (lemma; File(fileName).byLine)
        {
            if (lang == HLang.sv &&
                lemma.startsWith(lemmaOld) &&
                lemma.length == lemmaOld.length + 1 &&
                lemma.back == 's') // Swedish genitive noun or passive verb form
            {
                /* writeln("Skipping genitive noun ", lemma); */
            }
            else
            {
                WordKind kind;
                auto split = lemma.findSplit(`'`);
                if (!split[1].empty)
                {
                    lemma = split[0]; // exclude genitive ending 's
                    kind = WordKind.noun;
                }
                const normalizedLemma = normalize(lemma, lang);
                if (normalizedLemma[1])
                    exceptionCount++;

                static if (useRCString) { immutable internedLemma = Lemma(normalizedLemma[0]); }
                else                    { immutable internedLemma = normalizedLemma[0].idup; }

                lnr += addWord(internedLemma, kind, 0, lang);
            }
            lemmaOld = lemma.idup;
        }
        writeln(`Added `, lnr, ` new `, lang.toName, ` (`, exceptionCount, ` uncaseable) words from `, fileName);
    }

    void readWordNet(string dirName = `~/Knowledge/wordnet/WordNet-3.0/dict`)
    {
        const dictDir = dirName.expandTilde;
        // NOTE: Test both read variants through alternating uses of Mmfile or not
        const lang = HLang.en;
        readIndex(dictDir.nPath(`index.adj`), false, lang);
        readIndex(dictDir.nPath(`index.adv`), false, lang);
        readIndex(dictDir.nPath(`index.noun`), false, lang);
        readIndex(dictDir.nPath(`index.verb`), false, lang);
    }

    /** Create a WordNet of languages $(D langs).
     */
    this(HLang[] langs = [HLang.en],
         bool allLangs = false)
    {
        const dictDir = `~/Knowledge/dict`.expandTilde;

        // See also: https://packages.debian.org/sv/sid/wordlist
        if (allLangs || langs.canFind(HLang.sv))
            readUNIXDict(dictDir.nPath(`swedish`), HLang.sv); // TODO apt:wswedish, NOTE iso-latin-1
        if (allLangs || langs.canFind(HLang.de))
            readUNIXDict(dictDir.nPath("ogerman"), HLang.de); // TODO old german
        if (allLangs || langs.canFind(HLang.pl))
            readUNIXDict(dictDir.nPath("polish"), HLang.pl);
        if (allLangs || langs.canFind(HLang.pt))
            readUNIXDict(dictDir.nPath("portuguese"), HLang.pt);
        if (allLangs || langs.canFind(HLang.es))
            readUNIXDict(dictDir.nPath("spanish"), HLang.es);
        if (allLangs || langs.canFind(HLang.fr_ch))
            readUNIXDict(dictDir.nPath("swiss"), HLang.fr_ch);
        if (allLangs || langs.canFind(HLang.uk))
            readUNIXDict(dictDir.nPath("ukrainian"), HLang.uk);

        if (allLangs || langs.canFind(HLang.en))
            readUNIXDict(dictDir.nPath(`words`), HLang.en); // TODO apt:dictionaries-common
        if (allLangs || langs.canFind(HLang.en_GB))
            readUNIXDict(dictDir.nPath(`british-english-insane`), HLang.en_GB); // TODO apt:wbritish-insane
        if (allLangs || langs.canFind(HLang.en_GB))
            readUNIXDict(dictDir.nPath(`british-english-huge`), HLang.en_GB); // TODO apt:wbritish-huge
        if (allLangs || langs.canFind(HLang.en_GB))
            readUNIXDict(dictDir.nPath(`british-english`), HLang.en_GB); // TODO apt:wbritish

        if (allLangs || langs.canFind(HLang.en_US))
            readUNIXDict(dictDir.nPath(`american-english-insane`), HLang.en_US); // TODO apt:wamerican-insane
        if (allLangs || langs.canFind(HLang.en_US))
            readUNIXDict(dictDir.nPath(`american-english-huge`), HLang.en_US); // TODO apt:wamerican-huge
        if (allLangs || langs.canFind(HLang.en_US))
            readUNIXDict(dictDir.nPath(`american-english`), HLang.en_US); // TODO apt:wamerican

        if (allLangs || langs.canFind(HLang.pt_BR))
            readUNIXDict(dictDir.nPath(`brazilian`), HLang.pt_BR); // TODO apt:wbrazilian, NOTE iso-latin-1

        if (allLangs || langs.canFind(HLang.pt_BR))
            readUNIXDict(dictDir.nPath(`bulgarian`), HLang.bg); // TODO apt:wbulgarian, NOTE ISO-8859

        if (allLangs || langs.canFind(HLang.en_CA))
            readUNIXDict(dictDir.nPath("canadian-english-insane"), HLang.en_CA);

        if (allLangs || langs.canFind(HLang.da))
            readUNIXDict(dictDir.nPath("danish"), HLang.da);

        if (allLangs || langs.canFind(HLang.nl))
            readUNIXDict(dictDir.nPath("dutch"), HLang.nl);

        if (allLangs || langs.canFind(HLang.fr))
            readUNIXDict(dictDir.nPath("french"), HLang.fr);

        if (allLangs || langs.canFind(HLang.faroese))
            readUNIXDict(dictDir.nPath("faroese"), HLang.faroese);

        if (allLangs || langs.canFind(HLang.gl))
            readUNIXDict(dictDir.nPath("galician-minimos"), HLang.gl);

        if (allLangs || langs.canFind(HLang.de))
            readUNIXDict(dictDir.nPath("german-medical"), HLang.de); // TODO medical german

        if (allLangs || langs.canFind(HLang.it))
            readUNIXDict(dictDir.nPath("italian"), HLang.it);

        if (allLangs || langs.canFind(HLang.de))
            readUNIXDict(dictDir.nPath("ngerman"), HLang.de); // new german

        if (allLangs || langs.canFind(HLang.no))
            readUNIXDict(dictDir.nPath("nynorsk"), HLang.no);

        if (allLangs || langs.canFind(HLang.en))
            readWordNet(); // put this last to specialize existing lemma

        // TODO merge with conjunctions?
        // TODO categorize like http://www.grammarbank.com/connectives-list.html
        const connectives = [`the`, `of`, `and`, `to`, `a`, `in`, `that`, `is`,
                             `was`, `he`, `for`, `it`, `with`, `as`, `his`,
                             `on`, `be`, `at`, `by`, `i`, `this`, `had`, `not`,
                             `are`, `but`, `from`, `or`, `have`, `an`, `they`,
                             `which`, `one`, `you`, `were`, `her`, `all`, `she`,
                             `there`, `would`, `their`, `we him`, `been`, `has`,
                             `when`, `who`, `will`, `more`, `no`, `if`, `out`,
                             `so`, `said`, `what`, `up`, `its`, `about`, `into`,
                             `than them`, `can`, `only`, `other`, `new`, `some`,
                             `could`, `time`, `these`, `two`, `may`, `then`,
                             `do`, `first`, `any`, `my`, `now`, `such`, `like`,
                             `our`, `over`, `man`, `me`, `even`, `most`, `made`,
                             `after`, `also`, `did`, `many`, `before`, `must`,
                             `through back`, `years`, `where`, `much`, `your`,
                             `way`, `well`, `down`, `should`, `because`, `each`,
                             `just`, `those`, `people mr`, `how`, `too`,
                             `little`, `state`, `good`, `very`, `make`, `world`,
                             `still`, `own`, `see`, `men`, `work`, `long`, `get`,
                             `here`, `between`, `both`, `life`, `being`, `under`,
                             `never`, `day`, `same`, `another`, `know`, `while`,
                             `last`, `might us`, `great`, `old`, `year`, `off`,
                             `come`, `since`, `against`, `go`, `came`, `right`,
                             `used`, `take`, `three`];

        foreach (e; [`and`, `or`, `but`, `nor`, `so`, `for`, `yet`])
        {
            addWord(e, WordKind.coordinatingConjunction, 0, HLang.en);
        }

        foreach (e; [`och`, `eller`, `men`, `så`, `för`, `ännu`])
        {
            addWord(e, WordKind.coordinatingConjunction, 0, HLang.sv);
        }

        foreach (e; [`since`, `ago`, `before`, `past`])
        {
            addWord(e, WordKind.prepositionTime, 0, HLang.en);
        }

        // TODO Use all at http://www.ego4u.com/en/cram-up/grammar/prepositions
        foreach (e; [`to`, `at`, `of`, `on`, `off`, `in`, `out`, `up`,
                     `down`, `from`, `with`, `into`, `for`, `about`,
                     `between`,
                     `till`, `until`,
                     `by`, `out of`, `towards`, `through`, `across`,
                     `above`, `over`, `below`, `under`, `next to`, `beside`])
        {
            addWord(e, WordKind.preposition, 0, HLang.en);
        }

        /* undefinite articles */
        foreach (e; [`a`, `an`]) {
            addWord(e, WordKind.articleUndefinite, 0, HLang.en);
        }
        foreach (e; [`ein`, `eine`, `eines`, `einem`, `einen`, `einer`]) {
            addWord(e, WordKind.articleUndefinite, 0, HLang.de);
        }
        foreach (e; [`un`, `une`, `des`]) {
            addWord(e, WordKind.articleUndefinite, 0, HLang.fr);
        }
        foreach (e; [`en`, `ena`, `ett`]) {
            addWord(e, WordKind.articleUndefinite, 0, HLang.sv);
        }

        /* definite articles */
        foreach (e; [`the`]) {
            addWord(e, WordKind.articleDefinite, 0, HLang.en);
        }
        foreach (e; [`der`, `die`, `das`, `des`, `dem`, `den`]) {
            addWord(e, WordKind.articleDefinite, 0, HLang.de);
        }
        foreach (e; [`le`, `la`, `l'`, `les`]) {
            addWord(e, WordKind.articleDefinite, 0, HLang.fr);
        }
        foreach (e; [`den`, `det`]) {
            addWord(e, WordKind.articleDefinite, 0, HLang.sv);
        }

        /* partitive articles */
        foreach (e; [`some`]) {
            addWord(e, WordKind.articlePartitive, 0, HLang.en);
        }
        foreach (e; [`du`, `de`, `la`, `de`, `l'`, `des`]) {
            addWord(e, WordKind.articlePartitive, 0, HLang.fr);
        }

        /* personal pronoun */
        foreach (e; [`I`, `me`,  `you`, `it`]) {
            addWord(e, WordKind.pronounPersonalSingular, 0, HLang.en);
        }
        foreach (e; [`he`, `him`]) {
            addWord(e, WordKind.pronounPersonalSingularMale, 0, HLang.en);
        }
        foreach (e; [`she`, `her`]) {
            addWord(e, WordKind.pronounPersonalSingularFemale, 0, HLang.en);
        }

        foreach (e; [`jag`, `mig`, // 1st person
                     `du`, `dig`, // 2nd person
                     `den`, `det`]) { // 3rd person
            addWord(e, WordKind.pronounPersonalSingular, 0, HLang.sv);
        }
        foreach (e; [`han`, `honom`]) {
            addWord(e, WordKind.pronounPersonalSingularMale, 0, HLang.sv);
        }
        foreach (e; [`hon`, `henne`]) {
            addWord(e, WordKind.pronounPersonalSingularFemale, 0, HLang.sv);
        }

        foreach (e; [`we`, `us`, // 1st person
                     `you`, // 2nd person
                     `they`, `them`]) // 3rd person
        {
            addWord(e, WordKind.pronounPersonalPlural, 0, HLang.en);
        }
        foreach (e; [`vi`, `oss`, // 1st person
                     `ni`, // 2nd person
                     `de`, `dem`]) // 3rd person
        {
            addWord(e, WordKind.pronounPersonalPlural, 0, HLang.sv);
        }

        /* TODO near/far in distance/time , singular, plural */
        foreach (e; [`this`, `that`,
                     `these`, `those`]) {
            addWord(e, WordKind.pronounDemonstrative, 0, HLang.en);
        }

        /* TODO near/far in distance/time , singular, plural */
        foreach (e; [`den här`, `den där`,
                     `de här`, `de där`]) {
            addWord(e, WordKind.pronounDemonstrative, 0, HLang.sv);
        }

        foreach (e; [`my`, `your`]) {
            addWord(e, WordKind.adjectivePossessiveSingular, 0, HLang.en);
        }
        foreach (e; [`our`, `their`]) {
            addWord(e, WordKind.adjectivePossessivePlural, 0, HLang.en);
        }

        foreach (e; [`mine`, `yours`]) /* 1st person */ {
            addWord(e, WordKind.pronounPossessiveSingular, 0, HLang.en);
        }
        foreach (e; [`his`]) {
            addWord(e, WordKind.pronounPossessiveSingularMale, 0, HLang.en);
        }
        foreach (e; [`hers`]) {
            addWord(e, WordKind.pronounPossessiveSingularFemale, 0, HLang.en);
        }

        foreach (e; [`min`, /* 1st person */ `din`, /* 2nd person */ ]) {
            addWord(e, WordKind.pronounPossessiveSingular, 0, HLang.sv);
        }
        foreach (e; [`hans`]) {
            addWord(e, WordKind.pronounPossessiveSingularMale, 0, HLang.sv);
        }
        foreach (e; [`hennes`]) {
            addWord(e, WordKind.pronounPossessiveSingularFemale, 0, HLang.sv);
        }
        foreach (e; [`dens`, `dets`, /* 3rd person */ ]) {
            addWord(e, WordKind.pronounPossessiveSingularNeutral, 0, HLang.sv);
        }

        foreach (e; [`ours`, // 1st person
                     `yours`, // 2nd person
                     `theirs` // 3rd person
                     ])
        {
            addWord(e, WordKind.pronounPossessivePlural, 0, HLang.en);
        }

        foreach (e; [`vår`, // 1st person
                     `er`, // 2nd person
                     `deras` // 3rd person
                     ])
        {
            addWord(e, WordKind.pronounPossessivePlural, 0, HLang.sv);
        }
        foreach (e; [`who`, `whom`, `what`, `which`, `whose`,
                     `whoever`, `whatever`, `whichever`]) {
            addWord(e, WordKind.pronounInterrogative, 0, HLang.sv);
        }
        foreach (e; [`vem`, `som`, `vad`, `vilken`, `vems`]) {
            addWord(e, WordKind.pronounInterrogative, 0, HLang.sv);
        }

        foreach (e; [`myself`, `yourself`, `himself`, `herself`, `itself`]) {
            addWord(e, WordKind.pronounReflexiveSingular, 0, HLang.en);
        }
        foreach (e; [`mig själv`, `dig själv`, `han själv`, `henne själv`, `den själv`]) {
            addWord(e, WordKind.pronounReflexiveSingular, 0, HLang.sv);
        }

        foreach (e; [`ourselves`, `yourselves`, `themselves`]) {
            addWord(e, WordKind.pronounReflexivePlural, 0, HLang.en);
        }
        foreach (e; [`oss själva`, `er själva`, `dem själva`]) {
            addWord(e, WordKind.pronounReflexivePlural, 0, HLang.sv);
        }

        foreach (e; [`each other`, `one another`]) {
            addWord(e, WordKind.pronounReciprocal, 0, HLang.en);
        }
        foreach (e; [`varandra`]) {
            addWord(e, WordKind.pronounReciprocal, 0, HLang.sv);
        }

        foreach (e; [`another`, `anybody`, `anyone`, `anything`, `each`, `either`, `enough`,
                     `everybody`, `everyone`, `everything`, `less`, `little`, `much`, `neither`,
                     `nobody`, `noone`, `one`, `other`,
                     `somebody`, `someone`,
                     `something`, `you`]) {
            addWord(e, WordKind.pronounIndefiniteSingular, 0, HLang.en);
        }

        foreach (e; [`both`, `few`, `fewer`, `many`, `others`, `several`, `they`]) {
            addWord(e, WordKind.pronounIndefinitePlural, 0, HLang.en);
        }

        foreach (e; [`all`, `any`, `more`, `most`, `none`, `some`, `such`]) {
            addWord(e, WordKind.pronounIndefinite, 0, HLang.en);
        }

        foreach (e; [`who`, `whom`, // generally only for people
                     `whose`, // possession
                     `which`, // things
                     `that` // things and people
                     ]) {
            addWord(e, WordKind.pronounRelative, 0, HLang.en);
        }

        foreach (e; [`after`, `although`, `as`, `as if`, `as long as`,
                     `because`, `before`, `even if`, `even though`, `if`,
                     `once`, `provided`, `since`, `so that`, `that`,
                     `though`, `till`, `unless`, `until`, `what`,
                     `when`, `whenever`, `wherever`, `whether`, `while`])
        {
            addWord(e, WordKind.subordinatingConjunction, 0, HLang.en);
        }

        foreach (e; [`accordingly`, `additionally`, `again`, `almost`,
                     `although`, `anyway`, `as a result`, `besides`,
                     `certainly`, `comparatively`, `consequently`,
                     `contrarily`, `conversely`, `elsewhere`, `equally`,
                     `eventually`, `finally`, `further`, `furthermore`,
                     `hence`, `henceforth`, `however`, `in addition`,
                     `in comparison`, `in contrast`, `in fact`, `incidentally`,
                     `indeed`, `instead`, `just as`, `likewise`,
                     `meanwhile`, `moreover`, `namely`, `nevertheless`,
                     `next`, `nonetheless`, `notably`, `now`, `otherwise`,
                     `rather`, `similarly`, `still`, `subsequently`, `that is`,
                     `then`, `thereafter`, `therefore`, `thus`,
                     `undoubtedly`, `uniquely`, `on the other hand`, `also`,
                     `for example`, `for instance`, `of course`, `on the contrary`,
                     `so far`, `until now`, `thus` ])
        {
            addWord(e, WordKind.conjunctiveAdverb, 0, HLang.en);
        }

        /* weekdays */
        foreach (e; [`monday`, `tuesday`, `wednesday`, `thursday`, `friday`,
                     `saturday`, `sunday`]) {
            addWord(e, WordKind.nounWeekday, 0, HLang.en);
        }
        foreach (e; [`montag`, `dienstag`, `mittwoch`, `donnerstag`, `freitag`,
                     `samstag`, `sonntag`]) {
            addWord(e, WordKind.nounWeekday, 0, HLang.de);
        }
        foreach (e; [`måndag`, `tisdag`, `onsdag`, `torsdag`, `fredag`,
                     `lördag`, `söndag`]) {
            addWord(e, WordKind.nounWeekday, 0, HLang.sv);
        }

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

    /** Store $(D lemma) as $(D kind) in language $(D lang).
        Return true if a new word was added, false if word was specialized.
     */
    bool addWord(S)(S lemma, WordKind kind, ubyte synsetCount,
                    HLang lang = HLang.unknown)
    {
        static if (useRCString) { const Lemma lemmaFixed = lemma; }
        else                    { immutable lemmaFixed = lemma; }
        if (lemmaFixed in _words)
        {
            auto existing = _words[lemmaFixed];
            foreach (e; existing) // for each possible more general kind
            {
                if (e.kind == WordKind.init ||
                    (kind != e.kind &&
                     kind.memberOf(e.kind)))
                {
                    e.kind = kind; // specialize
                    return false;
                }
            }
        }

        Links links;
        _words[lemmaFixed] ~= WordSense!Links(kind, synsetCount, links, lang);
        return true;
    }

    /** Get Possible Meanings of $(D lemma) in all $(D hlangs).
        TODO filter on hlangs if hlangs is non-empty.
     */
    WordSense!Links[] meaningsOf(S)(S lemma,
                                    HLang[] hlangs = [])
    {
        typeof(return) senses;

        static if (useRCString) { const Lemma lowLemma = lemma.toLower; }
        else                    { immutable lowLemma = lemma.toLower; }

        if (lowLemma in _words)
        {
            senses = _words[lowLemma];
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

    auto canMean(S)(S lemma,
                    WordKind kind,
                    HLang lang = HLang.unknown) if (isSomeString!S)
    {
        return canMean(lemma, kind, lang == HLang.unknown ? [] : [lang]);
    }

    void readIndexLine(R, N)(R line, N lnr,
                             HLang lang = HLang.unknown,
                             bool useMmFile = false)
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
            auto meaning = WordSense!Links(words[1].front.decodeWordKind,
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
                   HLang lang = HLang.unknown)
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
                import algorithm_ex: byLine;
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

    WordSense!Links[][Lemma] _words;
}

auto ref makeWordNet(bool useArray = true,
                     bool useRCString = true)(HLang[] langs = [HLang.en,
                                                               HLang.sv])
{
    return new WordNet!(useArray, useRCString)(langs);
}

/** Decode Ambiguous Meaning(s) of string $(D s). */
version(none)
// TODO This gives error. Fix.
private auto to(T: WordSense[], S)(S x) if (isSomeString!S ||
                                            isSomeChar!S)
{
    T meanings;
    return meanings;
}

unittest
{
    enum useArray = true;
    enum useRCString = false;

    auto wn = new WordNet!(useArray, useRCString)();
    const words = [`car`, `trout`, `seal`, `and`, `or`, `script`, `shell`, `soon`, `long`, `longing`, `at`, `a`];
    foreach (word; words)
    {
        writeln(word, ` has meanings `, wn.meaningsOf(word));
    }

    assert(wn.canMean(`car`, WordKind.noun, [HLang.en]));
    assert(wn.canMean(`car`, WordKind.noun, HLang.en));
    /* assert(wn.canMean(`måndag`, WordKind.nounWeekday, [HLang.sv])); */
    assert(!wn.canMean(`longing`, WordKind.verb, [HLang.en]));

    /* write("Press enter to continue: "); */
    /* readln(); */
}
