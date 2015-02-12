module knet.readers.wordnet;

import knet.base;

Role decodeWordNetPointerSymbol(S)(S sym, Sense sense) pure if (isSomeString!S)
{
    typeof(return) role;
    with (Rel)
    {
        switch (sym)
        {
            case `!`:  role = Role(antonymFor); break;
            case `@`:  role = Role(hypernymOf, true); break;
            case `@i`: role = Role(instanceHypernymOf, true); break;
            case `~`:  role = Role(hyponymOf); break;
            case `~i`: role = Role(instanceHyponymOf); break;
            case `*`:  role = Role(causes, true); break; // entailment.

            // case `#m`: role = Role(memberHolonym); break;
            // case `#s`: role = Role(substanceHolonym); break;
            // case `#p`: role = Role(partHolonym); break;
            case `%m`: role = Role(memberOf); break;
            case `%s`: role = Role(madeOf); break;
            case `%p`: role = Role(partOf); break;

            // case `=`:  role = Role(attribute); break;
            // case `+`:  role = Role(derivationallyRelatedForm); break;
            // case `;c`: role = Role(domainOfSynset); break; // TOPIC
            // case `-c`: role = Role(memberOfThisDomain); break;  // TOPIC
            // case `;r`: role = Role(domainOfSynset); break; // REGION
            // case `-r`: role = Role(memberOfThisDomain); break; // REGION
            // case `;u`: role = Role(domainOfSynset); break; // USAGE
            // case `-u`: role = Role(memberOfThisDomain); break; // USAGE

            case `>`:  role = Role(causes); break;
            // case `^`:  role = Role(alsoSee); break;
            case `$`:  role = Role(formOfVerb); break;

            case `&`:  role = Role(similarTo); break;
            case `<`:  role = Role(participleOfVerb); break;

            // case `\`:  role = Role(pertainym); break; // pertains to noun
            // case `=`:  role = Role(attribute); break;

            default:
                assert(false, `Unexpected relation type ` ~ sym);
        }
    }
    return role;
}

bool readWordNetIndexLine(R, N)(Graph graph,
                                const R line,
                                const N lnr,
                                const Lang lang = Lang.unknown,
                                Sense sense = Sense.unknown,
                                const bool useMmFile = false)
{
    import std.uni: isWhite;
    import std.range: split, front;
    import std.array: replace;

    if (line.empty ||
        line.front.isWhite) // if first is not space. TODO move this check
    {
        return false;
    }

    const linestr = line.to!string;
    const words = linestr.split; // TODO Use splitter to optimize

    // static if (useRCString) { immutable Lemma lemma = words[0].replace(`_`, ` `); }
    // else                    { immutable lemma = words[0].replace(`_`, ` `).idup; }
    const lemma = words[0].replace(`_`, ` `);

    const pos          = words[1]; // Part of Speech (PoS)
    const synset_cnt   = words[2].to!uint; // Synonym Set Counter
    const p_cnt        = words[3].to!uint;
    const ptr_symbol   = words[4 .. 4+p_cnt];

    // const sense_cnt    = words[4+p_cnt].to!uint; // same as synset_cnt above (redundant)
    // debug assert(synset_cnt == sense_cnt);

    const tagsense_cnt = words[5+p_cnt].to!uint;
    const synset_off   = words[6+p_cnt].to!uint;
    auto ids = words[6+p_cnt .. $].map!(a => a.to!uint); // relating ids

    import knet.senses: decodeWordSense;
    const posSense = pos.decodeWordSense;
    if (sense == Sense.unknown) { sense = posSense; }
    if (posSense != sense) { assert(posSense == sense); }

    if (false)
    {
        const roles = ptr_symbol.map!(sym => sym.decodeWordNetPointerSymbol(sense));
    }

    // static if (useArray)
    // {
    //     // auto links = Links(ids);
    // }
    // else
    // {
    //     // auto links = ids.array;
    // }

    auto node = graph.store(lemma, Lang.en, sense, Origin.wordnet);

    // dln(at(node).lemma.expr, " has pointers ", ptr_symbol);
    // auto meaning = Entry!Links(words[1].front.decodeWordSense,
    //                            words[2].to!ubyte, links, lang);
    // _words[lemma] ~= meaning;

    return true;
}

/** Read WordNet Index File $(D fileName).
    Manual page: wndb
*/
void readWordNetIndex(Graph graph,
                      string fileName,
                      bool useMmFile = false,
                      Lang lang = Lang.unknown,
                      Sense sense = Sense.unknown)
{
    size_t lnr;
    /* TODO Functionize and merge with conceptnet5.readCSV */
    if (useMmFile)
    {
        import mmfile_ex: mmFileLinesRO;
        foreach (line; mmFileLinesRO(fileName))
        {
            graph.readWordNetIndexLine(line, lnr, lang, sense, useMmFile);
            lnr++;
        }
    }
    else
    {
        import std.stdio: File;
        foreach (line; File(fileName).byLine)
        {
            graph.readWordNetIndexLine(line, lnr, lang, sense);
            lnr++;
        }
    }

    import std.stdio: writeln;
    writeln(`Read `, lnr, ` words from `, fileName);
}

/** Current byte offset in the file represented as an 8 digit decimal integer.
 */
alias SynSetOffset = uint;
alias SynSet = Nds; // TODO use Array!Nd

bool readWordNetDataLine(R, N)(Graph graph,
                               SynSet[SynSetOffset] synsetNdsByOffset,
                               const R line,
                               const N lnr,
                               const Lang lang = Lang.unknown,
                               Sense sense = Sense.unknown,
                               const bool useMmFile = false)
{
    import std.conv: to, parse;
    import std.stdio;
    import std.range: front;
    import std.ascii: isDigit;

    if (line.empty ||
        line.front.isWhite) // if first is not space. TODO move this check
    {
        return false;
    }

    import std.container: Array;

    // writeln("line: ", line);

    auto parts = line.splitter;

    // synset_offset: unique synset id
    const synset_offset = parts.front.to!SynSetOffset;
    parts.popFront;

    // lex_filenum
    const lex_filenum = parts.front.to!uint;
    parts.popFront;

    // ss_type: synset type (sense)
    const char ss_type = parts.front[0];
    parts.popFront;

    // w_cnt: word count
    auto w_cnt_s = parts.front; // TODO post issue?
    uint w_cnt = w_cnt_s.parse!uint(16);
    parts.popFront; // decode hex string

    // (word lex_id)+
    SynSet synsetNds;
    while (w_cnt--)
    {
        const word = parts.front;
        parts.popFront;

        auto lex_id_s = parts.front; // TODO post issue?
        const lex_id = lex_id_s.parse!uint(16);
        parts.popFront;

        synsetNds ~= graph.store(word, lang, sense, Origin.wordnet);
    }
    // store it in local associative array
    assert(synset_offset !in synsetNdsByOffset); // assert unique ids
    synsetNdsByOffset[synset_offset] = synsetNds;

    struct Pointer
    {
        Role role;
        SynSetOffset synset_offset;
        uint pos;
        uint sourceSynSetWordNr;
        uint targetSynSetWordNr;
    }

    // p_cnt: pointer count
    auto p_cnt = parts.front.to!uint; parts.popFront;
    Array!Pointer refs;
    refs.reserve(p_cnt);

    // [ptr...]: pointers
    if (false)
        while (p_cnt--)
        {
            Pointer ptr;

            // pointer_symbol
            ptr.role = parts.front.decodeWordNetPointerSymbol(sense);
            parts.popFront;

            ptr.synset_offset = parts.front.to!SynSetOffset;
            parts.popFront;
        }

    // decoding done

    Sense ssSense;
    final switch (ss_type)
    {
        case 'n': ssSense = Sense.noun; break;
        case 'v': ssSense = Sense.verb; break;
        case 'a': ssSense = Sense.adjective; break;
        case 's': ssSense = Sense.adjective; break; // TODO adjectiveSatellite
        case 'r': ssSense = Sense.adverb; break;
    }
    assert(sense == ssSense);

    // writeln(synset_offset, " ", lex_filenum, " ", ss_type, " ", w_cnt, " ", word, " ", lex_id);

    return true;
}

/** Read WordNet Data File $(D fileName).
    Manual page: wndb
*/
void readWordNetData(Graph graph,
                     string fileName,
                     bool useMmFile = false,
                     Lang lang = Lang.unknown,
                     Sense sense = Sense.unknown)
{
    size_t lnr;
    SynSet[SynSetOffset] synsetNdsByOffset;
    if (useMmFile)
    {
        import mmfile_ex: mmFileLinesRO;
        foreach (line; mmFileLinesRO(fileName))
        {
            graph.readWordNetDataLine(synsetNdsByOffset,
                                      line, lnr, lang, sense, useMmFile);
            lnr++;
        }
    }
    else
    {
        import std.stdio: File;
        foreach (line; File(fileName).byLine)
        {
            graph.readWordNetDataLine(synsetNdsByOffset,
                                      line, lnr, lang, sense);
            lnr++;
        }
    }

    import std.stdio: writeln;
    writeln(`Read `, lnr, ` words from `, fileName);
}


/// Read WordNet Database (dict) in directory $(D dirPath).
void readWordNet(Graph graph,
                 string dirPath)
{
    import std.path: expandTilde, buildNormalizedPath;
    dirPath = dirPath.expandTilde;
    // NOTE: Test both read variants through alternating uses of Mmfile or not
    const lang = Lang.en;

    if (false)              // these indexes are not needed only data files
    {
        graph.readWordNetIndex(dirPath.buildNormalizedPath(`index.adj`), false, lang, Sense.adjective);
        graph.readWordNetIndex(dirPath.buildNormalizedPath(`index.adv`), false, lang, Sense.adverb);
        graph.readWordNetIndex(dirPath.buildNormalizedPath(`index.noun`), false, lang, Sense.noun);
        graph.readWordNetIndex(dirPath.buildNormalizedPath(`index.verb`), false, lang, Sense.verb);
    }

    graph.readWordNetData(dirPath.buildNormalizedPath(`data.adj`), false, lang, Sense.adjective);
    graph.readWordNetData(dirPath.buildNormalizedPath(`data.adv`), false, lang, Sense.adverb);
    graph.readWordNetData(dirPath.buildNormalizedPath(`data.noun`), false, lang, Sense.noun);
    graph.readWordNetData(dirPath.buildNormalizedPath(`data.verb`), false, lang, Sense.verb);
}
