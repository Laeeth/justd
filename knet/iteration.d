module knet.iteration;

import knet.relations: RelDir;
import knet.base;

/** Get Links Refs (Ln) of $(D node) with direction $(D dir).
*/
auto lnsOf(Graph gr,
           Node node,
           const RelDir dir = RelDir.any,
           const Role role = Role.init) pure
{
    import knet.relations: specializes;
    return node.links[]
               .map!(ln => ln.raw)
               .filter!(ln => (dir.among(RelDir.any, ln.dir) != 0 &&  // TODO functionize match(RelDir, RelDir)
                               gr[ln].role.negation == role.negation &&
                               // TODO gr[ln].role.reversed == role.reversed &&
                               (gr[ln].role.rel == role.rel ||
                                gr[ln].role.rel.specializes(role.rel))));
}

/** Get Links References of $(D nd) type $(D rel) learned from $(D origins).
 */
auto lnsOf(Graph gr,
           const Nd nd,
           const Role[] roles = [],
           const Origin[] origins = [],
           const Ln skipLn = Ln.init) pure
{
    import std.algorithm.searching: canFind;
    return gr[nd].links[]
                 .map!(ln => ln.raw)
                 .filter!(ln => (ln != skipLn &&
                                 (roles.empty || roles.canFind(gr[ln].role)) &&
                                 (origins.empty || origins.canFind(gr[ln].origin))));
}

/** Get Links References of $(D nd) type $(D rel) learned from $(D origins).
 */
auto lnsOf(Graph gr,
           const Nd nd,
           const Role role,
           const Origin[] origins = []) pure
{
    return gr.lnsOf(nd, [role], origins);
}

/** Get Links of Node $(D node).
 */
auto linksOf(Graph gr,
             Node node,
             const RelDir dir = RelDir.any,
             const Role role = Role.init) pure
{
    return gr.lnsOf(node, dir, role).map!(ln => gr[ln]);
}

/** Get Links of Node Reference $(D nd).
 */
auto linksOf(Graph gr,
             const Nd nd,
             const RelDir dir = RelDir.any,
             const Role role = Role.init) pure
{
    return gr.linksOf(gr[nd], dir, role);
}

/** Get All Node Indexes Indexed by a Lemma having expr $(D expr). */
auto ndsOf(S)(Graph gr,
              S expr) pure if (isSomeString!S)
{
    import knet.lookup: lemmasOfExpr;
    return gr.lemmasOfExpr(expr).map!(lemma => gr.db.ixes.ndByLemma[lemma]);
}

/** Get All Possible Nodes related to $(D word) in the interpretation
    (semantic context) $(D sense).
    If no sense given return all possible.
*/
Nds ndsOf(S)(Graph gr,
             S expr,
             Lang lang,
             Sense sense = Sense.unknown,
             Ctx context = anyContext) pure if (isSomeString!S)
{
    typeof(return) nodes;

    if (lang != Lang.unknown &&
        sense != Sense.unknown &&
        context != anyContext) // if exact Lemma key can be used
    {
        import knet.lookup: ndsByLemmaDirect;
        return gr.ndsByLemmaDirect(expr, lang, sense, context); // fast hash lookup
    }
    else
    {
        auto tmp = gr.ndsOf(expr)
                     .filter!(a => (lang == Lang.unknown ||
                                    gr[a].lemma.lang == lang))
                     .array;
        static if (useArray)
        {
            nodes = Nds(tmp); // TODO avoid allocations
        }
        else
        {
            nodes = tmp;
        }
    }

    if (nodes.empty)
    {
        /* writeln(`Lookup translation of individual expr; bil_tvätt => car-wash`); */
        /* foreach (word; expr.splitter(`_`)) */
        /* { */
        /*     writeln(`Translate word "`, word, `" from `, lang, ` to English`); */
        /* } */
    }
    return nodes;
}

/** Get Node References of $(D ln) matchin $(D langs) and $(D senses).
 */
auto ndsOf(Graph gr,
           const Ln ln,
           const Lang[] langs = [],
           const Sense[] senses = [],
           const Nd skipNd = Nd.init) pure
{
    import std.algorithm.searching: canFind;
    return gr[ln].actors[]
                 .map!(nd => nd.raw)
                 .filter!(nd => (nd != skipNd &&
                                 (langs.empty || langs.canFind(gr[nd].lemma.lang)) &&
                                 (senses.empty || senses.canFind(gr[nd].lemma.sense))));
}

alias meaningsOf = ndsOf;
alias interpretationsOf = ndsOf;

/** Get Nearest Neighbours (Nears) of $(D nd) over links of type $(D rel)
    learned from $(D origins).
*/
auto nnsOf(Graph gr,
           const Nd nd,
           const Role[] roles = [],
           const Lang[] dstLangs = [],
           const Origin[] origins = []) pure
{
    import std.algorithm.searching: canFind;
    import std.algorithm.iteration: joiner;
    return gr.lnsOf(nd, roles, origins)
             .map!(ln =>
                   gr[ln].actors[]
                         .filter!(actorNd => (actorNd.ix != nd.ix &&
                                              // TODO functionize to Lemma.ofLang
                                              (dstLangs.empty || dstLangs.canFind(gr[actorNd].lemma.lang)))))
             .joiner(); // no self
}

/** Get Possible Rhymes of $(D text) sorted by falling rhymness (relevance).
    Set withSameSyllableCount to true to get synonyms which can be used to
    help in translating songs with same rhythm.
    See also: http://stevehanov.ca/blog/index.php?id=8
*/
Nds rhymesOf(S)(Graph gr,
                S expr,
                Lang[] langs = [],
                const Origin[] origins = [],
                const size_t commonPhonemeCountMin = 2,  // at least two phonenes in common at the end
                const bool withSameSyllableCount = false) pure if (isSomeString!S)
{
    foreach (const srcNd; gr.ndsOf(expr)) // for each interpretation of expr
    {
        const srcNode = gr[srcNd];

        if (langs.empty)
        {
            langs = [srcNode.lemma.lang]; // stay within language by default
        }

        auto dstNds = gr.nnsOf(srcNd, [Role(Rel.translationOf)], [Lang.ipa], origins);

        foreach (const dstNd; dstNds) // translations to IPA-language
        {
            const dstNode = gr[dstNd];
            import std.algorithm.searching: canFind;
            auto hits = gr.db.tabs.allNodes.filter!(a => langs.canFind(a.lemma.lang))
                          .map!(a => tuple(a, commonSuffixCount(a.lemma.expr,
                                                                gr[srcNd].lemma.expr)))
                          .filter!(a => a[1] >= commonPhonemeCountMin)
            // .sorted!((a, b) => false)
            ;
        }
    }
    return typeof(return).init;
}

/** Get Possible Languages of $(D text) sorted by falling strength.
    TODO Weight hits with word node connectedness relative to average word
    connectedness in that language.
*/
NWeight[Lang] languagesOf(R)(Graph gr,
                             R text) pure if (isIterable!R &&
                                              isSomeString!(ElementType!R))
{
    typeof(return) hist;
    foreach (const word; text)
    {
        import knet.lookup: lemmasOfExpr;
        foreach (const lemma; gr.lemmasOfExpr(word))
        {
            ++hist[lemma.lang];
        }
    }
    return hist;
}

/** Get Translations of $(D word) in language $(D lang).
    If several $(D toLangs) are specified pick the closest match (highest
    relation weight).
*/
auto translationsOf(S)(Graph gr,
                       S expr,
                       const Lang lang = Lang.unknown,
                       const Sense sense = Sense.unknown,
                       const Lang[] toLangs = []) pure if (isSomeString!S)
{
    auto nodes = gr.ndsOf(expr, lang, sense);
    // en => sv:
    // en-en => sv-sv
    /* auto translations = nodes.map!(node => lnsOf(node, RelDir.any, rel, false))/\* .joiner *\/; */
    return nodes;
}

auto anagramsOf(S)(Graph gr,
                   S expr) pure if (isSomeString!S)
{
    const lsWord = expr.sorted; // letter-sorted expr
    return gr.db.tabs.allNodes.filter!(node => (lsWord != node.lemma.expr.toLower && // don't include one-self
                                                lsWord == node.lemma.expr.toLower.sorted));
}

/** TODO: http://rosettacode.org/wiki/Anagrams/Deranged_anagrams#D */
auto derangedAnagramsOf(S)(Graph gr,
                           S expr) pure if (isSomeString!S)
{
    return gr.anagramsOf(expr);
}

/** Get Synonyms of $(D word) optionally with Matching Syllable Count.
    Set withSameSyllableCount to true to get synonyms which can be used to
    help in translating songs with same rhythm.
*/
auto synonymsOf(S)(Graph gr,
                   S expr,
                   const Lang lang = Lang.unknown,
                   const Sense sense = Sense.unknown,
                   const bool withSameSyllableCount = false) pure if (isSomeString!S)
{
    return gr.ndsOf(expr, lang, sense);
}

/** Get Antonyms of $(D word) optionally with Matching Syllable Count.
    Set withSameSyllableCount to true to get antonyms which can be used to
    help in translating songs with same rhythm.
*/
auto antonymsOf(S)(Graph gr,
                   S expr,
                   const Lang lang = Lang.unknown,
                   const Sense sense = Sense.unknown,
                   const bool withSameSyllableCount = false) pure if (isSomeString!S)
{
    return gr.ndsOf(expr, lang, sense);
}
