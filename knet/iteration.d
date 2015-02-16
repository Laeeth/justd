module knet.iteration;

import predicates: of;

import knet.relations: RelDir, specializes;
import knet.base;

/** Get Links Refs (Ln) of $(D node) with direction $(D dir).
    TODO what to do with role.reversion here?
*/
auto lnsOf(Graph graph,
           Node node,
           RelDir dir = RelDir.any,
           Role role = Role.init) pure
{
    return node.links[]
               .filter!(ln => (dir.of(RelDir.any, ln.dir) &&  // TODO functionize match(RelDir, RelDir)
                               graph[ln].role.negation == role.negation &&
                               (graph[ln].role.rel == role.rel ||
                                graph[ln].role.rel.specializes(role.rel))));
}

/** Get Links References of $(D nd) type $(D rel) learned from $(D origins).
 */
auto lnsOf(Graph graph,
           Nd nd,
           Role role = Role.init,
           Origin[] origins = []) pure
{
    import std.algorithm.searching: canFind;
    return graph[nd].links[]
                    .filter!(ln => (graph[ln].role == role &&
                                    (origins.empty ||
                                     origins.canFind(graph[ln].origin))))
                    .map!(ln => ln.raw);
}

/** Get Links of Node $(D node).
 */
auto linksOf(Graph graph,
             Node node,
             RelDir dir = RelDir.any,
             Role role = Role.init) pure
{
    return graph.lnsOf(node, dir, role).map!(ln => graph[ln]);
}

/** Get Links of Node Reference $(D nd).
 */
auto linksOf(Graph graph,
             Nd nd,
             RelDir dir = RelDir.any,
             Role role = Role.init) pure
{
    return graph.linksOf(graph[nd], dir, role);
}

/** Get Nearest Neighbours (Nears) of $(D nd) over links of type $(D rel)
    learned from $(D origins).
*/
auto nnsOf(Graph graph,
           Nd nd,
           Rel rel,
           Lang[] dstLangs = [],
           Origin[] origins = []) pure
{
    import std.algorithm.searching: canFind;
    debug writeln("nd: ", nd);
    foreach (ln; graph.lnsOf(nd, Role(rel), origins))
    {
        debug writeln("ln: ", ln);
        foreach (nd2; graph[ln].actors[])
        {
            debug writeln("nd2: ", nd2);
            if (nd2.ix != nd.ix) // no self-recursion
            {
                debug writeln("differs");
                debug writeln("node: ", graph[nd]);
                debug writeln("lang: ", graph[nd].lemma.lang);
                debug writeln("dstLangs: ", dstLangs);
                debug writeln("it: ", dstLangs.canFind(graph[nd].lemma.lang));
                if (dstLangs.empty ||
                    dstLangs.canFind(graph[nd].lemma.lang)) // TODO functionize to Lemma.ofLang
                {
                    debug writeln("nd2: ", nd);
                }
            }
        }
    }
    debug writeln("xx");
    import std.algorithm.iteration: joiner;
    return graph.lnsOf(nd, Role(rel), origins)
                .map!(ln =>
                      graph[ln].actors[]
                               .filter!(actor => (actor.ix != nd.ix &&
                                                  // TODO functionize to Lemma.ofLang
                                                  (dstLangs.empty ||
                                                   dstLangs.canFind(graph[actor].lemma.lang)))))
                .joiner(); // no self
}

/** Get Possible Rhymes of $(D text) sorted by falling rhymness (relevance).
    Set withSameSyllableCount to true to get synonyms which can be used to
    help in translating songs with same rhythm.
    See also: http://stevehanov.ca/blog/index.php?id=8
*/
Nds rhymesOf(S)(Graph graph,
                S expr,
                Lang[] langs = [],
                Origin[] origins = [],
                size_t commonPhonemeCountMin = 2,  // at least two phonenes in common at the end
                bool withSameSyllableCount = false) pure if (isSomeString!S)
{
    foreach (srcNd; graph.ndsOf(expr)) // for each interpretation of expr
    {
        const srcNode = graph[srcNd];

        if (langs.empty)
        {
            langs = [srcNode.lemma.lang]; // stay within language by default
        }

        auto dstNds = graph.nnsOf(srcNd, Rel.translationOf, [Lang.ipa], origins);

        foreach (dstNd; dstNds) // translations to IPA-language
        {
            const dstNode = graph[dstNd];
            import std.algorithm.searching: canFind;
            auto hits = graph.db.allNodes.filter!(a => langs.canFind(a.lemma.lang))
                             .map!(a => tuple(a, commonSuffixCount(a.lemma.expr,
                                                                   graph[srcNd].lemma.expr)))
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
NWeight[Lang] languagesOf(R)(Graph graph,
                             R text) pure if (isIterable!R &&
                                              isSomeString!(ElementType!R))
{
    typeof(return) hist;
    foreach (word; text)
    {
        foreach (lemma; graph.lemmasOfExpr(word))
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
auto translationsOf(S)(Graph graph,
                       S expr,
                       Lang lang = Lang.unknown,
                       Sense sense = Sense.unknown,
                       Lang[] toLangs = []) pure if (isSomeString!S)
{
    auto nodes = graph.ndsOf(expr, lang, sense);
    // en => sv:
    // en-en => sv-sv
    /* auto translations = nodes.map!(node => lnsOf(node, RelDir.any, rel, false))/\* .joiner *\/; */
    return nodes;
}

/** Breadth-First Graph Walker (Traverser)
    Modelled as an (Input Range) of Nds.
*/
struct Walk
{
    pure:

    enum Order { breadFirst, nearestFirst } // TODO use

    this(Graph graph,
         const Nd firstNd,
         Lang[] langs = [],
         Role[] roles = [],
         Origin[] origins = [])
    {
        this.graph = graph;

        this.langs = langs;
        this.roles = roles;
        this.origins = origins;

        frontNds ~= firstNd.raw;
        minDistanceByNd[firstNd.raw] = 0; // tag firstNd as visited
    }

    auto front() pure
    {
        import std.range: front;
        assert(!frontNds.empty, "Attempting to fetch the front of an empty Walk");
        return frontNds;
    }

    void popFront() pure
    {
        import std.range: front, popFront;
        Nds pendingNds;

        foreach (currentNd; frontNds)
        {
            foreach (currentLn; graph.lnsOf(currentNd))
            {
                foreach (nextNd; graph[currentLn].actors[]
                                                 .filter!(actor =>
                                                          actor.raw !in minDistanceByNd)
                                                 .map!(actor => actor.raw))
                {
                    pendingNds ~= nextNd;
                    minDistanceByNd[nextNd] = 0;
                }
            }
        }

        frontNds = pendingNds;
    }

    bool empty() const
    {
        import std.range: empty;
        return frontNds.empty;
    }

private:
    Graph graph;

    // internal state
    NWeight[Nd] minDistanceByNd; // maps frontNds minimum distance from visited to firstNd
    Nds frontNds;              // current nodes

    // filters
    const Lang[] langs;         // languages to match
    const Role[] roles;         // roles to match
    const Origin[] origins;     // origins to match
}

Walk walk(Graph graph, Nd start) pure
{
    auto range = typeof(return)(graph, start);
    return range;
}
alias traverse = walk;

auto anagramsOf(S)(Graph graph,
                   S expr) pure if (isSomeString!S)
{
    const lsWord = expr.sorted; // letter-sorted expr
    return graph.db.allNodes.filter!(node => (lsWord != node.lemma.expr.toLower && // don't include one-self
                                              lsWord == node.lemma.expr.toLower.sorted));
}

/** TODO: http://rosettacode.org/wiki/Anagrams/Deranged_anagrams#D */
auto derangedAnagramsOf(S)(Graph graph,
                           S expr) pure if (isSomeString!S)
{
    return graph.anagramsOf(expr);
}

/** Get Synonyms of $(D word) optionally with Matching Syllable Count.
    Set withSameSyllableCount to true to get synonyms which can be used to
    help in translating songs with same rhythm.
*/
auto synonymsOf(S)(Graph graph,
                   S expr,
                   Lang lang = Lang.unknown,
                   Sense sense = Sense.unknown,
                   bool withSameSyllableCount = false) pure if (isSomeString!S)
{
    return graph.ndsOf(expr, lang, sense);
}
