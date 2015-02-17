module knet.iteration;

import predicates: of;

import knet.relations: RelDir, specializes;
import knet.base;

/** Get Links Refs (Ln) of $(D node) with direction $(D dir).
*/
auto lnsOf(Graph graph,
           Node node,
           RelDir dir = RelDir.any,
           Role role = Role.init) pure
{
    return node.links[]
               .filter!(ln => (dir.of(RelDir.any, ln.dir) &&  // TODO functionize match(RelDir, RelDir)
                               graph[ln].role.negation == role.negation &&
                               // TODO graph[ln].role.reversion == role.reversion &&
                               (graph[ln].role.rel == role.rel ||
                                graph[ln].role.rel.specializes(role.rel))));
}

/** Get Links References of $(D nd) type $(D rel) learned from $(D origins).
 */
auto lnsOf(Graph graph,
           Nd nd,
           const Role[] roles = [],
           const Origin[] origins = []) pure
{
    import std.algorithm.searching: canFind;
    return graph[nd].links[]
                    .filter!(ln => ((roles.empty ||
                                     roles.canFind(graph[ln].role)) &&
                                    (origins.empty ||
                                     origins.canFind(graph[ln].origin))))
                    .map!(ln => ln.raw);
}

/** Get Links References of $(D nd) type $(D rel) learned from $(D origins).
 */
auto lnsOf(Graph graph,
           Nd nd,
           Role role,
           const Origin[] origins = []) pure
{
    return graph.lnsOf(nd, [role], origins);
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
           const Role[] roles = [],
           const Lang[] dstLangs = [],
           const Origin[] origins = []) pure
{
    import std.algorithm.searching: canFind;
    debug writeln("nd: ", nd);
    foreach (const ln; graph.lnsOf(nd, roles, origins))
    {
        debug writeln("ln: ", ln);
        foreach (const nd2; graph[ln].actors[])
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
    return graph.lnsOf(nd, roles, origins)
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
                const Origin[] origins = [],
                size_t commonPhonemeCountMin = 2,  // at least two phonenes in common at the end
                bool withSameSyllableCount = false) pure if (isSomeString!S)
{
    foreach (const srcNd; graph.ndsOf(expr)) // for each interpretation of expr
    {
        const srcNode = graph[srcNd];

        if (langs.empty)
        {
            langs = [srcNode.lemma.lang]; // stay within language by default
        }

        auto dstNds = graph.nnsOf(srcNd, [Role(Rel.translationOf)], [Lang.ipa], origins);

        foreach (const dstNd; dstNds) // translations to IPA-language
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
    foreach (const word; text)
    {
        foreach (const lemma; graph.lemmasOfExpr(word))
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

/** Bread First Graph Walk(er) (Traverser)
    Modelled as an (Input Range) with ElementType being an Nd-array (Nd[]).
*/
struct BFWalk
{
    pure:

    this(Graph graph,
         const Nd startNd,
         const Lang[] langs = [],
         const Sense[] senses = [],
         const Role[] roles = [],
         const Origin[] origins = [])
    {
        this.graph = graph;

        this.langs = langs;
        this.roles = roles;
        this.origins = origins;

        frontNds ~= startNd.raw;
        connectivenessByNd[startNd.raw] = 1; // tag startNd as visited
    }

    auto front() const
    {
        import std.range: front;
        assert(!frontNds.empty, "Attempting to fetch the front of an empty Walk");
        return frontNds;
    }

    void popFront()
    {
        Nds pendingNds;

        foreach (const frontNd; frontNds)
        {
            foreach (const frontLn; graph.lnsOf(frontNd, roles, origins))
            {
                foreach (const nextNd; graph[frontLn].actors[] // TODO functionize
                                                     .map!(actor => actor.raw)
                                                     .filter!(actor =>
                                                              (langs.empty || langs.canFind(graph[actor].lemma.lang)) &&
                                                              (senses.empty || senses.canFind(graph[actor].lemma.sense)) &&
                                                              actor !in connectivenessByNd))
                {
                    pendingNds ~= nextNd;
                    const connectiveness = connectivenessByNd[frontNd] * graph[frontLn].nweight;
                    if (auto nextConnectiveness = nextNd in connectivenessByNd)
                    {
                        import std.algorithm: max;
                        *nextConnectiveness = max(*nextConnectiveness, connectiveness);
                    }
                    else
                    {
                        connectivenessByNd[nextNd] = connectiveness;
                    }
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

    // internal state
    NWeight[Nd] connectivenessByNd; // maps frontNds minimum distance from visited to startNd

private:
    Graph graph;

    // internal state
    Nds frontNds;              // current nodes

    // filters
    // TODO group into structure
    const Lang[] langs;         // languages to match
    const Sense[] senses;       // senses to match
    const Role[] roles;         // roles to match
    const Origin[] origins;     // origins to match
}

BFWalk bfWalk(Graph graph, Nd start,
              const Lang[] langs = [],
              const Sense[] senses = [],
              const Role[] roles = [],
              const Origin[] origins = []) pure
{
    auto range = typeof(return)(graph, start, langs, senses, roles, origins);
    return range;
}

/** Nearest First Graph Walk(er) (Traverser).
    Similar to Dijkstra's Railroad Algorithm.
    Modelled as an (Input Range) with ElementType being a Nd.

    Upon iteration completion mapByNd contains a map from node to (distance, and
    closest parent node) to walk starting point (startNd). This can be used to
    reconstruct the closest path from any given Nd to startNd.
*/
struct DijkstraWalk
{
    import std.container.binaryheap;
    import std.typecons: tuple, Tuple;
    pure:

    alias Visit = Tuple!(NWeight, Nd);

    this(Graph graph,
         const Nd startNd,
         const Lang[] langs = [],
         const Sense[] senses = [],
         const Role[] roles = [],
         const Origin[] origins = [])
    {
        this.graph = graph;

        this.langs = langs;
        this.roles = roles;
        this.origins = origins;

        untraversedNds ~= startNd.raw;
        mapByNd[startNd.raw] = tuple(0, // zero distance
                                               Nd.asUndefined); // no parent Nd
    }

    auto front() const
    {
        import std.range: empty;
        assert(!untraversedNds.empty, "Can't fetch front from an empty DijkstraWalk");
        import std.range: front;
        return untraversedNds.front;
    }

    void popFront()
    {
        assert(!untraversedNds.empty, "Can't pop front from an empty DijkstraWalk");

        import std.range: moveFront;
        const frontNd = untraversedNds.moveFront;

        const savedLength = untraversedNds.length;
        foreach (const frontLn; graph.lnsOf(frontNd, roles, origins))
        {
            foreach (const nextNd; graph[frontLn].actors[] // TODO functionize
                                                 .map!(actor => actor.raw)
                                                 .filter!(actor =>
                                                          (langs.empty || langs.canFind(graph[actor].lemma.lang)) &&
                                                          (senses.empty || senses.canFind(graph[actor].lemma.sense))))
            {
                const newDist = mapByNd[frontNd][0] + graph[frontLn].nweight; // TODO parameterize on distance funtion
                if (auto hit = nextNd in mapByNd)
                {
                    const dist = (*hit)[0];
                    const parentNd = (*hit)[1];
                    if (newDist < dist) // a closer way was found
                    {
                        *hit = Visit(newDist, frontNd); // best yet
                    }
                }
                else
                {
                    mapByNd[nextNd] = Visit(newDist, frontNd); // best yet
                    untraversedNds ~= nextNd;
                }
            }
        }

        import std.algorithm.sorting: partialSort;
        untraversedNds.partialSort!((aNd, bNd) => (mapByNd[aNd][0] <
                                                   mapByNd[bNd][0]))(savedLength);
    }

    bool empty() const
    {
        return untraversedNds.empty;
    }

    // Nd => tuple(Nd origin distance, parent Nd)
    Visit[Nd] mapByNd;

private:
    Graph graph;

    // TODO how can I make use of BinaryHeap here instead?
    Nds untraversedNds; // sorted by smallest distance to startNd
    static if (false)
    {
        BinaryHeap!(Nds, ((a, b) => (this.mapByNd[a][0] <
                                     this.mapByNd[b][0]))) pendingNds;
    }

    // filters
    // TODO group into structure
    const Lang[] langs;         // languages to match
    const Sense[] senses;       // sense to match

    const Role[] roles;         // roles to match
    const Origin[] origins;     // origins to match
}

DijkstraWalk dijkstraWalk(Graph graph, Nd start,
                          const Lang[] langs = [],
                          const Sense[] senses = [],
                          const Role[] roles = [],
                          const Origin[] origins = [])
{
    auto range = typeof(return)(graph, start, langs, senses, roles, origins);
    return range;
}

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
