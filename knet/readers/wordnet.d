module knet.readers.wordnet;

import std.container: Array;

import knet.base;

Role decodeWordNetPointerSymbol(S)(S sym, Sense sense) pure if (isSomeString!S)
{
    typeof(return) role;
    with (Rel)
    {
        switch (sym)
        {
            case  `!`: role = Role(antonymFor); break;
            case  `@`: role = Role(hypernymOf, true); break;
            case `@i`: role = Role(instanceHypernymOf, true); break;
            case  `~`: role = Role(hyponymOf); break;
            case `~i`: role = Role(instanceHyponymOf); break;
            case  `*`: role = Role(causes, true); break; // entailment.

            case `#m`: role = Role(memberHolonym); break;
            case `#s`: role = Role(substanceHolonym); break;
            case `#p`: role = Role(partHolonym); break;
            case `%m`: role = Role(memberOf); break;
            case `%s`: role = Role(madeOf); break;
            case `%p`: role = Role(partOf); break;

            case  `=`: role = Role(attribute); break;
            case  `+`: role = Role(derivationallyRelatedForm); break;

            case `;c`: role = Role(topicDomainOfSynset); break;
            case `-c`: role = Role(memberOfTopicDomain); break;

            case `;r`: role = Role(regionDomainOfSynset); break;
            case `-r`: role = Role(memberOfRegionDomain); break;

            case `;u`: role = Role(usageDomainOfSynset); break;
            case `-u`: role = Role(memberOfUsageDomain); break;

            case  `>`: role = Role(causes); break;
            case  `^`: role = Role(alsoSee); break;
            case  `$`: role = Role(formOfVerb); break;

            case  `&`: role = Role(similarTo); break;
            case  `<`: role = Role(participleOfVerb); break;

            case  `\`: role = Role(pertainym); break; // pertains to noun

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
    // else                    { immutable lemma = words[0].replace(`_`, ` `).to!string; }
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

alias WordNr = uint;

struct Ptr
{
    @safe pure nothrow @nogc:

    bool isSemantic() const { return (srcSynSetWordNr == 0 &&
                                      dstSynSetWordNr == 0); }

    Role role;
    SynSetOffset synset_offset;
    uint pos;
    WordNr srcSynSetWordNr;
    WordNr dstSynSetWordNr;
}
alias Ptrs = Array!Ptr;

import std.typecons: Tuple;
alias Row = Tuple!(SynSetOffset, Ptrs);
alias Rows = Row[];

size_t readWordNetDataLine(R, N)(Graph graph,
                                 ref Rows rows,
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
        return 0;
    }

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

    // w_cnt: word count
    auto w_cnt_s = parts.front; // TODO post issue?
    uint w_cnt = w_cnt_s.parse!uint(16);
    const wordCount = w_cnt;
    parts.popFront; // decode hex string

    // (word lex_id)+
    SynSet synset;
    while (w_cnt--)
    {
        const word = parts.front.replace(`_`, ` `);
        parts.popFront;

        auto lex_id_s = parts.front; // TODO post issue?
        const lex_id = lex_id_s.parse!uint(16);
        parts.popFront;

        synset ~= graph.store(word, lang, sense, Origin.wordnet);
    }

    // store it in local associative array
    if (auto existingSynSet = synset_offset in graph.db.ixes.synsetByOffset)
    {
        *existingSynSet ~= synset;
    }
    else
    {
        graph.db.ixes.synsetByOffset[synset_offset] = synset;
    }

    graph.connectCycle(synset, Rel.synonymFor, Origin.wordnet, true); // TODO use connectFully instead?

    // p_cnt: pointer count
    auto p_cnt = parts.front.to!uint; parts.popFront;

    Row row;
    row[0] = synset_offset;
    row[1].reserve(p_cnt);

    // [ptr...]: pointers
    while (p_cnt--)
    {
        Ptr ptr;

        // pointer_symbol
        ptr.role = parts.front.decodeWordNetPointerSymbol(sense);
        parts.popFront;

        // synset_offset
        ptr.synset_offset = parts.front.to!SynSetOffset;
        parts.popFront;

        // pos
        ptr.pos = 0; // TODO
        parts.popFront;

        // source/target: distinguishes between lexical and semantic pointers
        auto src = parts.front[0..2];
        auto dst = parts.front[2..4];
        ptr.srcSynSetWordNr = src.parse!WordNr(16);
        ptr.dstSynSetWordNr = dst.parse!WordNr(16);
        if (ptr.srcSynSetWordNr == 0 &&
            ptr.dstSynSetWordNr == 0)
        {
            // connectMtoN(currentSynSet, pointerSynSet)
        }
        parts.popFront;

        row[1] ~= ptr;
    }

    rows ~= row;

    return wordCount;
}

/** Read WordNet Data File $(D fileName).
    Manual page: wndb
*/
void readWordNetData(Graph graph,
                     ref Rows rows,
                     string fileName,
                     bool useMmFile = false,
                     Lang lang = Lang.unknown,
                     Sense sense = Sense.unknown)
{
    size_t lnr = 0;
    size_t wordCount = 0;

    if (useMmFile)
    {
        import mmfile_ex: mmFileLinesRO;
        foreach (line; mmFileLinesRO(fileName))
        {
            wordCount += graph.readWordNetDataLine(rows, line, lnr, lang, sense, useMmFile);
            lnr++;
        }
    }
    else
    {
        import std.stdio: File;
        foreach (line; File(fileName).byLine)
        {
            wordCount += graph.readWordNetDataLine(rows, line, lnr, lang, sense);
            lnr++;
        }
    }

    // TODO process rows

    import std.stdio: writeln;
    writeln(`Read `, lnr, ` synonym sets (synsets) with `, wordCount, ` words from `, fileName);
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

    Rows rows;

    graph.readWordNetData(rows, dirPath.buildNormalizedPath(`data.adj`), false, lang, Sense.adjective);
    graph.readWordNetData(rows, dirPath.buildNormalizedPath(`data.adv`), false, lang, Sense.adverb);
    graph.readWordNetData(rows, dirPath.buildNormalizedPath(`data.noun`), false, lang, Sense.noun);
    graph.readWordNetData(rows, dirPath.buildNormalizedPath(`data.verb`), false, lang, Sense.verb);

    // link them together
    foreach (const row; rows)
    {
        if (auto srcSynSet_ = row[0] in graph.db.ixes.synsetByOffset)
        {
            foreach (const ptr; row[1])
            {
                if (auto dstSynSet_ = ptr.synset_offset in graph.db.ixes.synsetByOffset)
                {
                    if (ptr.isSemantic)
                    {
                        graph.connectMtoN(*srcSynSet_,
                                          ptr.role,
                                          *dstSynSet_,
                                          Origin.wordnet, 1.0, true, true);
                    }
                    else
                    {
                        assert(ptr.srcSynSetWordNr != 0);
                        assert(ptr.dstSynSetWordNr != 0);
                        const Nd srcNd = (*srcSynSet_)[ptr.srcSynSetWordNr - 1];
                        const Nd dstNd = (*dstSynSet_)[ptr.dstSynSetWordNr - 1];
                        if (srcNd != dstNd)
                        {
                            graph.connect(srcNd, ptr.role, dstNd, Origin.wordnet, 1.0, true);
                        }
                        else
                        {
                            if (false)
                            {
                                writeln("Skipping self connection of ",
                                        graph[srcNd].lemma.expr,
                                        " >=", ptr.role.rel, " => ",
                                        graph[dstNd].lemma.expr,
                                        "");
                            }
                        }
                    }
                }
                else
                {
                    writeln("Could not lookup destination SynSet ", ptr.synset_offset);
                }
            }
        }
        else
        {
            writeln("Could not lookup source SynSet ", row[0]);
        }
    }
}
