module knet.association;

import knet.base;

/** Get Node with strongest relatedness to $(D exprs).
 */
Nd contextOf(Exprs)(Graph gr,
                    Exprs exprs,
                    const Lang[] langs = [],
                    const Sense[] senses = [],
                    const Role[] roles = [],
                    const Origin[] origins = [],
                    uint durationInMsecs = 1000) if (isIterable!Exprs &&
                                                     isSomeString!(ElementType!Exprs))
{
    import std.algorithm: joiner;
    auto lemmas = exprs.map!(expr => gr.lemmasOfExpr(expr)).joiner;
    auto nds = lemmas.map!(lemma => gr.db.ixes.ndByLemma[lemma]);
    return gr.contextOf(nds, langs, senses, roles, origins, durationInMsecs);
}

/** Get Node with strongest relatedness to $(D text).
    TODO Compare with function Context() in ConceptNet API.
*/
Nd contextOf(Nds)(Graph gr,
                  Nds nds,
                  const Lang[] langs = [],
                  const Sense[] senses = [],
                  const Role[] roles = [],
                  const Origin[] origins = [],
                  uint durationInMsecs = 1000) if (isIterable!Nds &&
                                                   is(Nd == ElementType!Nds))
{
    auto node = typeof(return).init;
    import knet.traversal: dijkstraWalker;

    // log walker visits
    import bitset;
    alias Block = size_t;

    enum maxCount = 8*Block.sizeof;
    const count = nds.count;
    assert(nds.count >= 2);
    assert(nds.count <= maxCount);

    alias Visits = BitSet!(maxCount, Block); // bit n is set if walker has visited Nd
    Visits[Nd] visitedWalkersIndexesByNd;

    import std.datetime: StopWatch;
    StopWatch stopWatch;
    stopWatch.start();

    // do we need array here?
    auto walkers = nds.map!(nd => gr.dijkstraWalker(nd, langs, senses, roles, origins)).array;

    // iterate walkers in Round Robin fashion
    while (stopWatch.peek.msecs < durationInMsecs)
    {
        uint emptyCount = 0;
        foreach (wix, ref walker; walkers)
        {
            if (!walker.empty)
            {
                import std.range: moveFront;
                const visitedNd = walker.moveFront; // visit new node
                writeln("visitedNd: ", visitedNd, ", wix: ", wix);
                if (auto visits = visitedNd in visitedWalkersIndexesByNd)
                {
                    (*visits)[wix] = true; // log that walker now *also* have visited visitedNd
                    if ((*visits).allOne)
                    {
                        return visitedNd;
                    }
                }
                else
                {
                    Visits visits;
                    visits[wix] = true;
                    visitedWalkersIndexesByNd[visitedNd] = visits;
                }
            }
            else
            {
                ++emptyCount;
            }
        }
        if (emptyCount == walkers.length) // if all walkers are empty
        {
            break; // we're done
        }
    }

    return node;
}

alias topicOf = contextOf;
