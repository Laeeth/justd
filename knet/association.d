module knet.association;

import knet.base;
import knet.filtering: Filter;
import knet.traversal: WalkStrategy;

alias Block = size_t;
enum maxCount = 8*Block.sizeof;

import std.typecons: Tuple;

alias Hit = Tuple!(NWeight, // association goodness (either distance or strength)
                   size_t); // hit count

alias Context = Tuple!(Nd,      // contextual node
                       Hit);
alias Contexts = Context[];

/** Get Context (node) of Expressions $(D exprs).
 */
Contexts contextsOf(WalkStrategy strategy = WalkStrategy.nordlowMaxConnectiveness,
                    Exprs)(Graph gr,
                           Exprs exprs,
                           const Filter filter = Filter.init,
                           size_t maxContextCount = 0,
                           uint durationInMsecs = 1000) if (isIterable!Exprs &&
                                                            isSomeString!(ElementType!Exprs))
{
    import std.algorithm: joiner;
    import knet.lookup: lemmasOfExpr;
    auto lemmas = exprs.map!(expr => gr.lemmasOfExpr(expr)).joiner;
    auto nds = lemmas.map!(lemma => gr.db.ixes.ndByLemma[lemma]);
    return gr.contextsOf!(strategy)(nds, filter, maxContextCount, durationInMsecs);
}

/** Get $(D maxContextCount) Strongest Contextual Nodes of Nodes $(D nds).

    If $(D maxContextCount) is zero it's set to some default value.

    Context means the node (Nd) which is most strongly related to $(D nds).

    Either exists
    - after $(D durationInMsecs) millseconds has passed, or
    - a common (context) node has been found

    If $(D intervalInMsecs) is set to a non-zero value provide feedback in such
    intervals.

    TODO Compare with function Context() in ConceptNet API.
*/
Contexts contextsOf(WalkStrategy strategy = WalkStrategy.nordlowMaxConnectiveness,
                    Nds)(Graph gr,
                         Nds nds,
                         const Filter filter = Filter.init,
                         size_t maxContextCount = 0,
                         uint durationInMsecs = 1000,
                         uint intervalInMsecs = 0) if (isIterable!Nds &&
                                                       is(Nd == ElementType!Nds))
{
    auto node = typeof(return).init;

    if (maxContextCount == 0)
    {
        maxContextCount = 100;
    }

    auto count = nds.count;
    if (count < 2) // need at least two nodes
    {
        return typeof(return).init;
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
    import knet.traversal: nnWalker;
    auto walkers = nds.map!(nd => gr.nnWalker!(strategy)(nd, filter)).array;

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
                        // TODO what to do with this?
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

    Hit[Nd] connByNd;       // weights by node

    size_t i;
    foreach (nd, const visits; visitsByNd.byPair)
    {
        for (auto walkIx = 0; walkIx < visits.length; ++walkIx)
        {
            if (visits[walkIx])
            {
                foreach (nd, visit; walkers[walkIx].visitByNd) // Nds visited by walker
                {
                    if (auto existingHit = nd in connByNd)
                    {
                        (*existingHit)[0] += visit[0]; // TODO use prevNd for anything?
                        (*existingHit)[1]++; // increase hit count
                    }
                    else
                    {
                        connByNd[nd] = tuple(0.0, 0); // distance and connectiveness sum starts as zero
                    }
                }
            }
        }
        i++;
    }

    import std.algorithm.sorting: topN;
    import sort_ex: sorted;
    import std.array: array;

    Contexts contexts = connByNd.byPair.array;
    maxContextCount = min(maxContextCount, contexts.length); // limit context count

    static if (strategy == WalkStrategy.dijkstraMinDistance)
    {
        contexts.topN!"a[1] < b[1]"(maxContextCount); // pick n strongest contexts
        contexts[0 .. maxContextCount].sort!"a[1] < b[1]"; // sort n  strongest contexts
    }
    else static if (strategy == WalkStrategy.nordlowMaxConnectiveness)
    {
        contexts.topN!"a[1] > b[1]"(maxContextCount); // pick n strongest contexts
        contexts[0 .. maxContextCount].sort!"a[1] > b[1]"; // sort n  strongest contexts
    }

    foreach (ix, ref walker; walkers)
    {
        writeln("walker#", ix, ":",
                " pending.length:", walker.pending.length,
                " visitByNd.length:", walker.visitByNd.length);
    }

    return contexts[0 .. maxContextCount];
}

alias topicsOf = contextsOf;
