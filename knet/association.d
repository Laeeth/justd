module knet.association;

import std.typecons: Tuple;

import knet.base;
import knet.filtering: Filter;
import knet.traversal: WalkStrategy;

alias Block = size_t;
enum maxCount = 8*Block.sizeof;

import bitset: BitSet;
alias Visits = BitSet!(maxCount, Block); // bit $(D n) is set if Walker $(D n) has visited $(D Nd)

alias Rank = NWeight;

/** Walker Hits for a Specific Node. */
struct Hits
{
    Visits visits;
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
                       const Filter walkerFilter = Filter.init,
                       Lang[] contextLangs = [], Sense[] contextSenses = [], // TODO group these into a target filter
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
                                    contextLangs, contextSenses,
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
                     const Filter walkerFilter = Filter.init,

                     Lang[] contextLangs = [], Sense[] contextSenses = [], // TODO group these into a target filter

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
    writeln("walkerFilter: ", walkerFilter);
    foreach (nd; nds) { writeln(`- `, gr[nd].lemma); }

    Visits[Nd] visitsByNd;

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
                if (auto visits = visitedNd in visitsByNd)
                {
                    // log that $(D walker) now (among at least one other) have visited visitedNd
                    (*visits)[wix] = true;
                    // TODO if ((*visits).allOneBetween(0, count)) { /* do something? */ }
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

    StopWatch sw;
    sw.start();
    pln("Combining walker results...");

    // if (!visitsByNd.byPair.empty)
    // {
    //     pragma(msg, typeof(visitsByNd.byPair.front));
    //     pragma(msg, typeof(visitsByNd.byKeyValue.front));
    // }

    // combine walker results
    Hits[Nd] hitsByNd;       // weights by node
    foreach (const nd, const visits; visitsByNd.byPair)
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
                    Visits visits_;
                    visits_[wix] = true;
                    hitsByNd[nd] = Hits(visits_, goodnessSum);
                }
            }
        }
    }

    // sort contexts
    import std.algorithm: topNCopy, SortOutput;
    alias E = typeof(hitsByNd.byKeyValue.front); // TODO hackish
    E[] contexts; contexts.length = maxContextCount;

    auto filteredHitsByNd = hitsByNd.byKeyValue
                                    .filter!(ndHit => ((contextLangs.empty || // TODO functionize
                                                        contextLangs.canFind(gr[ndHit.key].lemma.lang)) &&
                                                       (contextSenses.empty ||
                                                        contextSenses.canFind(gr[ndHit.key].lemma.sense))));

    static if (strategy == WalkStrategy.dijkstraMinDistance)
    {
        filteredHitsByNd.topNCopy!("a.value < b.value")(contexts, SortOutput.yes); // shortest distances first
    }
    else static if (strategy == WalkStrategy.nordlowMaxConnectiveness)
    {
        filteredHitsByNd.topNCopy!("a.value > b.value")(contexts, SortOutput.yes); // largest connectiveness first
    }

    auto trueContexts = contexts.filter!(a => !nds.canFind(a.key)).array; // exclude input nodes $(D nds)

    sw.stop();
    pln("Combining walker results took ", sw.peek.msecs);

    // print walker statistics
    foreach (ix, ref walker; walkers)
    {
        pln(" walker#", ix, ":",
            " pending.length:", walker.pending.length,
            " visitByNd.length:", walker.visitByNd.length);
    }

    return tuple(trueContexts, walkers);
}

alias topicsOf = contextsOf;
