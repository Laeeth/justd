module knet.readers.wordnet;

import knet.base;
import knet.relations: Rel;
import knet.roles: Role;
import knet.languages: Lang;

Role decodeWordNetPointerSymbol(string sym, Sense sense) pure
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

void readWordNetIndexLine(R, N)(Graph graph,
                                const R line,
                                const N lnr,
                                const Lang lang = Lang.unknown,
                                Sense sense = Sense.unknown,
                                const bool useMmFile = false)
{
    import std.uni: isWhite;
    import std.range: empty, front;
    import std.conv: to;
    import std.range: split;
    import std.algorithm: map;
    import std.array: replace;

    if (!line.empty &&
        !line.front.isWhite) // if first is not space. TODO move this check
    {
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

        import knet.origins: Origin;
        auto node = graph.store(lemma, Lang.en, sense, Origin.wordnet);

        // dln(at(node).lemma.expr, " has pointers ", ptr_symbol);
        // auto meaning = Entry!Links(words[1].front.decodeWordSense,
        //                            words[2].to!ubyte, links, lang);
        // _words[lemma] ~= meaning;
    }
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
}
