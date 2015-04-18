module knet.association;

import std.typecons: Tuple;

import knet.base;
import knet.filtering: NodeFilter, StepFilter;
import knet.traversal: WalkStrategy;

alias Block = size_t;
enum maxCount = 8*Block.sizeof;

import bitset: BitSet;
alias WalkerVisits = BitSet!(maxCount, Block); // bit $(D n) is set if Walker $(D n) has visited $(D Nd)

alias Rank = NWeight;

/** Walker Hits for a Specific Node. */
struct Hits
{
    WalkerVisits visits;
    NWeight goodnessSum; // sum of either minimum distance or maximum strength

    auto visitCount() const @safe @nogc pure nothrow { return visits.countOnes; }

    // TODO http://forum.dlang.org/thread/dgriaerekyrcqegrrrer@forum.dlang.org#post-dgriaerekyrcqegrrrer:40forum.dlang.org
    auto opCmp_alt(const Hits rhs) const
    {
        import std.algorithm: cmp;
        import std.range: only;
        if(auto c = cmp(only(visitCount),
                        only(rhs.visitCount)))
        {
            return c;
        }
        else                    /* 'count' values are equal. */
        {
            return cmp(only(goodnessSum),
                       only(rhs.goodnessSum));
        }
    }

    auto opCmp(const Hits rhs) const
    {
        if      (this.visitCount > rhs.visitCount) // TODO this is not intuitive
        {
            return -1;
        }
        else if (this.visitCount < rhs.visitCount) // TODO this is not intuitive
        {
            return +1;
        }
        else
        {
            if      (this.goodnessSum < rhs.goodnessSum)
            {
                return -1;
            }
            else if (this.goodnessSum > rhs.goodnessSum)
            {
                return +1;
            }
            else
            {
                return 0;
            }
        }
    }
}

alias Context = Tuple!(Nd, Hits);
alias Contexts = Context[];

/** Get Context (node) of Expressions $(D exprs).
 */
auto contextsOf(WalkStrategy strategy,
                Exprs)(Graph gr,
                       Exprs exprs,
                       const StepFilter walkerFilter = StepFilter.init,
                       const NodeFilter contextFilter = NodeFilter.init,
                       size_t maxContextCount = 0,
                       uint durationInMsecs = 1000) if (isIterable!Exprs &&
                                                        isSomeString!(ElementType!Exprs))
{
    import std.algorithm: joiner;
    import knet.lookup: lemmasOfExpr;
    // writeln("exprs: ", exprs);
    auto lemmas = exprs.map!(expr => gr.lemmasOfExpr(expr)).joiner;
    // writeln("lemmas: ", lemmas);
    auto nds = lemmas.map!(lemma => gr.db.ixes.ndByLemma[lemma]);
    // writeln("nds: ", nds);
    return gr.contextsOf!(strategy)(nds, walkerFilter,
                                    contextFilter,
                                    maxContextCount, durationInMsecs);
}

import dbg: pln;

/** Get $(D maxContextCount) Strongest Contextual Nodes of Nodes $(D nds).

    Implemented as an Any-Time Algorithm completing after $(D durationInMsecs).

    If $(D maxContextCount) is zero it's set to some default value.

    Context means the node (Nd) which is most strongly related to $(D nds).

    Either exists
    - after $(D durationInMsecs) millseconds has passed, or
    - a common (context) node has been found

    If $(D intervalInMsecs) is set to a non-zero value provide feedback in such
    intervals.

    TODO Compare with function Context() in ConceptNet API.
*/
auto contextsOf(WalkStrategy strategy,
                Nds)(Graph gr,
                     Nds nds,
                     const StepFilter walkerFilter = StepFilter.init,
                     const NodeFilter contextFilter = NodeFilter.init,
                     size_t maxContextCount = 0,
                     uint durationInMsecs = 1000,
                     uint intervalInMsecs = 0) if (isIterable!Nds &&
                                                   is(Nd == ElementType!Nds))
body
{
    if (maxContextCount == 0) { maxContextCount = 100; }
    if (intervalInMsecs == 0) { intervalInMsecs = 20; }

    auto count = nds.count;
    if (count > maxCount)
    {
        pln("Truncated node count from ", count, " to ", maxCount);
        count = maxCount;
    }

    // debug prints
    // foreach (nd; nds) { writeln(`- `, gr[nd].lemma); }

    WalkerVisits[Nd] walkerVisitsByNd;

    import std.datetime: StopWatch;
    StopWatch stopWatch;
    stopWatch.start();

    // TODO avoid Walker postblit
    import knet.traversal: nnWalker;
    const useRelevance = true;
    auto walkers = nds.map!(nd => gr.nnWalker!(strategy)(nd, walkerFilter, useRelevance)).array;

    // iterate walkers in Round Robin fashion
    while (stopWatch.peek.msecs < durationInMsecs)
    {
        uint emptyCount = 0;
        foreach (wix, ref walker; walkers)
        {
            if (!walker.empty)
            {
                const visitedNd = walker.moveFront; // visit new node
                if (contextFilter.matches(gr[visitedNd]))
                {
                    if (auto visits = visitedNd in walkerVisitsByNd)
                    {
                        // log that $(D walker) now (among at least one other) have visited visitedNd
                        (*visits)[wix] = true;
                        // TODO if ((*visits).allOneBetween(0, count)) { /* do something? */ }
                    }
                    else
                    {
                        // log that $(D walker) is (the first) to visit visitedNd
                        WalkerVisits visits;
                        visits[wix] = true;
                        walkerVisitsByNd[visitedNd] = visits;
                    }
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

    StopWatch sw;
    sw.start();
    pln("Combining walker results...");

    // if (!walkerVisitsByNd.byPair.empty)
    // {
    //     pragma(msg, typeof(walkerVisitsByNd.byPair.front));
    //     pragma(msg, typeof(walkerVisitsByNd.byKeyValue.front));
    // }

    // combine walker results
    Hits[Nd] hitsByNd;       // weights by node
    foreach (const nd, const visits; walkerVisitsByNd.byPair)
    {
        foreach (wix; 0 .. visits.length)
        {
            if (visits[wix]) // if walker wix visited nd
            {
                const visit = walkers[wix].visitByNd[nd];
                const goodnessSum = visit[0];
                const Nd prevNd = visit[1]; // TODO use to reconstruct path
                // store that wix has visited nd
                if (auto existingHit = nd in hitsByNd)
                {
                    (*existingHit).goodnessSum += goodnessSum;
                    (*existingHit).visits[wix] = true;
                }
                else
                {
                    WalkerVisits visits_;
                    visits_[wix] = true;
                    hitsByNd[nd] = Hits(visits_, goodnessSum);
                }
            }
        }
    }

    // sort contexts
    import std.algorithm: topNCopy, SortOutput;
    alias E = typeof(hitsByNd.byKeyValue.front); // TODO hackish
    E[] contexts; contexts.length = min(hitsByNd.length,
                                        maxContextCount);
    static if (strategy == WalkStrategy.dijkstraMinDistance)
    {
        hitsByNd.byKeyValue.topNCopy!("a.value < b.value")(contexts, SortOutput.yes); // shortest distances first
    }
    else static if (strategy == WalkStrategy.nordlowMaxConnectiveness)
    {
        hitsByNd.byKeyValue.topNCopy!("a.value > b.value")(contexts, SortOutput.yes); // largest connectiveness first
    }

    E[] pureContexts = contexts.filter!(context =>
                                        !nds.canFind(context.key))
                               .array; // exclude input nodes $(D nds)

    sw.stop();
    pln("Combining walker results took ", sw.peek.msecs);

    // print walker statistics
    foreach (ix, ref walker; walkers)
    {
        pln(" walker#", ix, ":",
            " pending.length:", walker.pending.length,
            " visitByNd.length:", walker.visitByNd.length);
    }

    return tuple(pureContexts, walkers);
}

alias topicsOf = contextsOf;
