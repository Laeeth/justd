module knet.association;

import std.typecons: Tuple;

import knet.base;
import knet.filtering: Filter;
import knet.traversal: WalkStrategy;

alias Block = size_t;
enum maxCount = 8*Block.sizeof;

import bitset: BitSet;
alias Visits = BitSet!(maxCount, Block); // bit n is set if walker has visited Nd

alias Rank = NWeight;

struct Hit
{
    Visits visits; // walker visits
    NWeight rank; // rank (either minimum distance or maximum strength)

    auto visitCount() const @safe @nogc pure nothrow { return visits.countOnes; }

    // TODO http://forum.dlang.org/thread/dgriaerekyrcqegrrrer@forum.dlang.org#post-dgriaerekyrcqegrrrer:40forum.dlang.org
    auto opCmp_alt(const Hit rhs) const
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
            return cmp(only(rank),
                       only(rhs.rank));
        }
    }

    auto opCmp(const Hit rhs) const
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
            if      (this.rank < rhs.rank)
            {
                return -1;
            }
            else if (this.rank > rhs.rank)
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

alias Context = Tuple!(Nd, Hit);
alias Contexts = Context[];

/** Get Context (node) of Expressions $(D exprs).
 */
auto contextsOf(WalkStrategy strategy,
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

import dbg: pln;

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
auto contextsOf(WalkStrategy strategy,
                Nds)(Graph gr,
                     Nds nds,
                     const Filter filter = Filter.init,
                     size_t maxContextCount = 0,
                     uint durationInMsecs = 1000,
                     uint intervalInMsecs = 0) if (isIterable!Nds &&
                                                   is(Nd == ElementType!Nds))
    in { assert(nds.count >= 2); }   // need at least two nodes
body
{
    if (maxContextCount == 0)
    {
        maxContextCount = 100;
    }

    auto count = nds.count;
    if (count > maxCount)
    {
        pln("Truncated node count from ", count, " to ", maxCount);
        count = maxCount;
    }

    if (intervalInMsecs == 0)
    {
        intervalInMsecs = 20;
    }

    pln("Walkers: ");
    foreach (nd; nds)
    {
        writeln(`- `, gr[nd].lemma);
    }

    Visits[Nd] visitsByNd;

    import std.datetime: StopWatch;
    StopWatch stopWatch;
    stopWatch.start();

    pln("filter: ", filter);

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

    writeln("=========================================================");
    writeln("walkers[0].visitByNd: starting at ", gr[walkers[0].start].lemma.expr);
    foreach (const nd, const visit; walkers[0].visitByNd)
    {
        writeln("nd: ", gr[nd].lemma.expr,
                ", visit: ", visit);
    }

    // combine walker results
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
                    const rank = visit[0];
                    // store that walkIx has visited nd
                    if (auto existingHit = nd in connByNd)
                    {
                        (*existingHit).rank += rank; // TODO use prevNd for anything?
                        (*existingHit).visits[walkIx] = true;
                    }
                    else
                    {
                        Visits visits;
                        visits[walkIx] = true;
                        connByNd[nd] = Hit(visits, rank);
                    }
                }
            }
        }
        i++;
    }

    foreach (const nd, const hit; connByNd.byPair)
    {
        pln("nd:", gr[nd].lemma, ", hit:", hit);
    }

    // sort walker restults
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

    // print walker statistics
    foreach (ix, ref walker; walkers)
    {
        pln(" walker#", ix, ":",
            " pending.length:", walker.pending.length,
            " visitByNd.length:", walker.visitByNd.length);
    }

    // return maxContextCount best hits
    return tuple(contexts[0 .. maxContextCount], walkers);
}

alias topicsOf = contextsOf;
