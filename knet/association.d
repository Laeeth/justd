module knet.association;

import knet.base;

/** Get Context (node) of Expressions $(D exprs).
 */
Nd contextOf(Exprs)(Graph gr,
                    Exprs exprs,
                    const Filter filter = Filter.init,
                    uint durationInMsecs = 1000) if (isIterable!Exprs &&
                                                     isSomeString!(ElementType!Exprs))
{
    import std.algorithm: joiner;
    import knet.lookup: lemmasOfExpr;
    auto lemmas = exprs.map!(expr => gr.lemmasOfExpr(expr)).joiner;
    auto nds = lemmas.map!(lemma => gr.db.ixes.ndByLemma[lemma]);
    return gr.contextOf(nds, filter, durationInMsecs);
}

/** Get Context (node) of Nodes $(D nds).
    Context means the node (Nd) which is most strongly related to $(D nds).

    Either exists
    - after $(D durationInMsecs) millseconds has passed, or
    - a common (context) node has been found

    TODO Compare with function Context() in ConceptNet API.
*/
Nd contextOf(Nds)(Graph gr,
                  Nds nds,
                  const Filter filter = Filter.init,
                  uint durationInMsecs = 1000) if (isIterable!Nds &&
                                                   is(Nd == ElementType!Nds))
{
    auto node = typeof(return).init;
    import knet.traversal: dijkstraWalker;

    alias Block = size_t;
    enum maxCount = 8*Block.sizeof;
    const count = nds.count;

    if (count < 2)
    {
        return Nd.init;
    }
    assert(count <= maxCount);

    import bitset: BitSet;
    alias Visits = BitSet!(maxCount, Block); // bit n is set if walker has visited Nd
    Visits[Nd] visitsByNd;

    import std.datetime: StopWatch;
    StopWatch stopWatch;
    stopWatch.start();

    auto walkers = nds.map!(nd => gr.dijkstraWalker(nd, filter)).array; // TODO avoid Walker postblit

    // iterate walkers in Round Robin fashion
    while (stopWatch.peek.msecs < durationInMsecs)
    {
        uint emptyCount = 0;
        foreach (wix, ref walker; walkers)
        {
            if (!walker.empty)
            {
                const visitedNd = walker.moveFront; // visit new node
                if (auto visits = visitedNd in visitsByNd)
                {
                    // log that $(D walker) now (among at least one other) have visited visitedNd
                    (*visits)[wix] = true;

                    if ((*visits).allOneBetween(0, count))
                    {
                        return visitedNd;
                    }
                }
                else
                {
                    // log that $(D walker) is (the first) to visit visitedNd
                    Visits visits;
                    visits[wix] = true;
                    visitsByNd[visitedNd] = visits;
                }
            }
            else
            {
                ++emptyCount;
            }
        }
        if (emptyCount == count) // if all walkers are empty traversal is complete
        {
            break; // we're done
        }
    }

    writeln("contextOf: Sort visitsByNd on connectiveness");

    foreach (ix, ref walker; walkers)
    {
        writeln("walker#", ix, ":",
                " pending.length:", walker.pending.length,
                " distMap.length:", walker.distMap.length);
    }

    return node;
}

alias topicOf = contextOf;
