module knet.association;

import knet.base;

alias Block = size_t;
enum maxCount = 8*Block.sizeof;

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

    If $(D intervalInMsecs) is set to a non-zero value provide feedback in such
    intervals.

    TODO Compare with function Context() in ConceptNet API.
*/
Nd contextOf(Nds)(Graph gr,
                  Nds nds,
                  const Filter filter = Filter.init,
                  uint durationInMsecs = 1000,
                  uint intervalInMsecs = 0) if (isIterable!Nds &&
                                                is(Nd == ElementType!Nds))
{
    auto node = typeof(return).init;
    import knet.traversal: nnWalker;

    auto count = nds.count;
    if (count < 2) // need at least two nodes
    {
        return Nd.init;
    }
    if (count > maxCount)
    {
        writeln(__FUNCTION__, ": Truncated node count from ", count, " to ", maxCount);
        count = maxCount;
    }

    if (intervalInMsecs == 0)
    {
        intervalInMsecs = 20;
    }

    writeln(`durationInMsecs: `, durationInMsecs);
    foreach (nd; nds)
    {
        writeln(`- `, gr[nd].lemma);
    }

    import bitset: BitSet;
    alias Visits = BitSet!(maxCount, Block); // bit n is set if walker has visited Nd
    Visits[Nd] visitsByNd;

    import std.datetime: StopWatch;
    StopWatch stopWatch;
    stopWatch.start();

    writeln("filter: ", filter);

    // TODO avoid Walker postblit
    auto walkers = nds.map!(nd => gr.nnWalker(nd, filter)).array;

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
                        writeln(`All match for `, gr[visitedNd].lemma);
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
