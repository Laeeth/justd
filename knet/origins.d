module knet.origins;

/** Knowledge Origin. */
enum Origin:ubyte
{
    unknown,
    any = unknown,

    cn5,                        ///< ConceptNet5

    dbpedia,                    ///< DBPedia
    // dbpedia37,
    // dbpedia39Umbel,
    // dbpediaEn,

    wordnet,                    ///< WordNet
    moby,                       ///< Moby.

    umbel,                      ///< http://www.umbel.org/
    jmdict,                     ///< http://www.edrdg.org/jmdict/j_jmdict.html

    verbosity,                  ///< Verbosity
    wiktionary,                 ///< Wiktionary
    nell,                       ///< NELL
    yago,                       ///< Yago
    globalmind,                 ///< GlobalMind

    synlex, ///< Folkets synonymlexikon Synlex http://lexikon.nada.kth.se/synlex.html
    folketsLexikon,
    swesaurus, ///< Swesaurus: http://spraakbanken.gu.se/eng/resource/swesaurus

    manual
}

bool defined(Origin origin) @safe @nogc pure nothrow { return origin != Origin.unknown; }

string toNice(Origin origin) @safe pure
{
    final switch (origin) with (Origin)
    {
        case unknown: return `Unknown`;
        case cn5: return `CN5`;
        case dbpedia: return `DBpedia`;
            // case dbpedia37: return `DBpedia37`;
            // case dbpedia39Umbel: return `DBpedia39Umbel`;
            // case dbpediaEn: return `DBpediaEnglish`;

        case wordnet: return `WordNet`;
        case moby: return `Moby`;

        case umbel: return `umbel`;
        case jmdict: return `JMDict`;

        case verbosity: return `Verbosity`;
        case wiktionary: return `Wiktionary`;
        case nell: return `NELL`;
        case yago: return `Yago`;
        case globalmind: return `GlobalMind`;
        case synlex: return `Synlex`;
        case folketsLexikon: return `FolketsLexikon`;
        case swesaurus: return `Swesaurus`;
        case manual: return `Manual`;
    }
}
