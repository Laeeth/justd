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

    import std.datetime: StopWatch;
    StopWatch stopWatch;
    stopWatch.start();

    // do we need array here?
    auto walkers = nds.map!(nd => gr.dijkstraWalker(nd, langs, senses, roles, origins)).array;

    // iterate walkers in Round Robin fashion
    import std.algorithm.searching: any;
    while (stopWatch.peek().msecs >= durationInMsecs &&
           walkers.any!(walker => !walker.empty)) // while we still have walker
    {
        foreach (ref activeWalker; walkers.filter!(walker => !walker.empty))
        {
            import std.range: moveFront;
            const front = activeWalker.moveFront;
            // find node overlaps of walkers.
        }
    }

    return node;
}

alias topicOf = contextOf;
