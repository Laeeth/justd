module knet.traversal;

import knet.base;
import knet.filtering: StepFilter;

/** Bread First Graph Walk(er) (Traverser)
*/
struct BFWalker
{
    pure:

    this(Graph gr,
         const Nd start,
         const StepFilter filter = StepFilter.init) @safe nothrow in { assert(start.defined); }
    body
    {
        this.gr = gr;
        this.filter = filter;

        frontNds ~= start.raw;
        connectivenessByNd[start.raw] = 1; // tag start as visited

        assert(!frontNds.empty);
        assert(connectivenessByNd !is null); // must be initialized to enable reference semantics
    }

    auto front() const @safe pure nothrow @nogc
    {
        import std.range: front;
        assert(!frontNds.empty, "Attempting to fetch the front of an empty Walker");
        return frontNds;
    }

    void popFront()
    {
        Nds pendingNds;

        foreach (const curr; frontNds)
        {
            import knet.iteration: lnsOf;
            foreach (const frontLn; gr.lnsOf(curr, filter.roles, filter.origins))
            {
                foreach (const nextNd; gr[frontLn].actors[] // TODO functionize using .ndsOf if we can find a way to include curr
                                                  .map!(nd => nd.raw)
                                                  .filter!(nd =>
                                                           nd != curr &&
                                                           (filter.langs.empty || filter.langs.canFind(gr[nd].lemma.lang)) &&
                                                           (filter.senses.empty || filter.senses.canFind(gr[nd].lemma.sense)) &&
                                                           nd.raw !in connectivenessByNd))
                {
                    pendingNds ~= nextNd;
                    const connectiveness = connectivenessByNd[curr] * gr[frontLn].nweight;
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

    bool empty() const @safe pure nothrow @nogc
    {
        import std.range: empty;
        return frontNds.empty;
    }

    BFWalker save() @property // makes this a ForwardRange
    {
        typeof(return) copy = this;
        copy.frontNds = copy.frontNds.dup;
        copy.connectivenessByNd = copy.connectivenessByNd.dup;
        return copy;
    }

    // internal state
    NWeight[Nd] connectivenessByNd; // maps frontNds minimum distance from visited to start
    const StepFilter filter;
private:
    Graph gr;
    Nds frontNds;              // current nodes (internal state)
}

BFWalker bfWalker(Graph gr, Nd start,
                  const StepFilter filter = StepFilter.init) pure
{
    return typeof(return)(gr, start, filter);
}

enum WalkStrategy
{
    dijkstraMinDistance, /// Dijkstra Minimum Path Distance to Start.
    nordlowMaxConnectiveness, /// Dijkstra Maximum Connectiveness to Start.
};

/** Nearest-Origin-First Walker/Visitor/Traverser; Dijkstra's Railroad Algorithm
    as a lazy $(D ForwardRange).

    IMPORTANT: A lazy range is needed in this case in order for knet graph
    searching algorithms to execute in constant (user) time.

    Upon iteration completion $(D visitByNd) contains a map from node to
    (distance, and closest parent node) to walker starting point (start). This
    can be used to reconstruct the closest path from any given $D(Nd) to start.

    See also: http://rosettacode.org/wiki/Dijkstra%27s_algorithm#D
    See also: http://forum.dlang.org/thread/xrxejicnoakanvkyasso@forum.dlang.org#post-yipmrrdilsxcaypeoqhz:40forum.dlang.org

    TODO: Use containers.hashmap.HashMap and tag as @nogc
*/
struct NNWalker(WalkStrategy strategy)
{
    // version = debugPrint;

    import std.typecons: Tuple, tuple;
    import std.container: RedBlackTree;

    alias Pending = Tuple!(NWeight, Nd);
    alias Visit = Tuple!(NWeight, Step);

    static      if (strategy == WalkStrategy.dijkstraMinDistance)
    {
        alias Queue = RedBlackTree!(Pending, "a < b");
    }
    else static if (strategy == WalkStrategy.nordlowMaxConnectiveness)
    {
        alias Queue = RedBlackTree!(Pending, "a > b");
    }

    /** Calculate and Return Path from $(D target) to $(D start) node.
        Returns: empty Path if $(D target) equals $(D start).
        Throws exception if $(D target) hasn't been visited by this walker.
       */
    Path pathFrom(Nd target)
    {
        Path path;
        auto curr = target;
        while (curr != start)
        {
            Step back = visitByNd[curr][1];
            path ~= back;
            curr = back[1];
        }
        return path;
    }

    this(Graph gr,
         const Nd start,
         const StepFilter filter = StepFilter.init,
         bool useRelevance = false) in { assert(start.defined); }
    body
    {
        this.gr = gr;
        this.filter = filter;
        this.start = start;
        this.useRelevance = useRelevance;

        static if (strategy == WalkStrategy.dijkstraMinDistance)
        {
            const NWeight startWeight = 0.0; // distance
        }
        else static if (strategy == WalkStrategy.nordlowMaxConnectiveness)
        {
            const NWeight startWeight = 1.0; // connectiveness
        }

        // WARNING must initialized arrays and AAs here to provide reference semantics
        pending = new Queue(Pending(startWeight, start));
        visitByNd[start.raw] = Visit(startWeight, Step.init);

        assert(!pending.empty); // must be initialized to enable reference semantics
        assert(visitByNd !is null); // must be initialized to enable reference semantics
    }

    /** Postblit. */
    this(this) in { assert(pending !is null &&
                           visitByNd !is null); }
    body
    {
        pending = pending.dup;
        visitByNd = visitByNd.dup;
        if (visitByNd.length >= 2)
        {
            writeln("warning: Called postblit when nextNd is ",
                    gr[pending.front[1]].lemma,
                    " and pending.length=", pending.length,
                    " and visitByNd.length=", visitByNd.length);
        }
    }

    Nd front() @safe pure nothrow // TODO make const when pending.empty is const
    {
        import std.range: empty;
        assert(!pending.empty, "Can't fetch front from an empty NNWalker");
        import std.range: front;
        return pending.front[1];
    }

    void popFront()
    {
        assert(!pending.empty, "Can't pop front from an empty NNWalker");

        import std.range: moveFront;
        const curr = pending.front; pending.removeFront;
        const currW = curr[0];
        const currNd = curr[1];

        import knet.iteration: lnsOf;
        foreach (const frontLn; gr.lnsOf(currNd, filter.roles, filter.origins))
        {
            const frontLink = gr[frontLn];
            import knet.iteration: ndsOf;
            foreach (const nextNd; gr.ndsOf(frontLn, filter.langs, filter.senses, currNd))
            {
                double relevance = 1.0;
                if (useRelevance)
                    relevance = frontLink.role.rel.relevance;
                static if (strategy == WalkStrategy.dijkstraMinDistance)
                {
                    const newNextGoodness = currW + frontLink.ndist(relevance);
                }
                else static if (strategy == WalkStrategy.nordlowMaxConnectiveness)
                {
                    const newNextGoodness = currW * frontLink.nweight(relevance);
                }

                version (debugPrint) write("currNd:", gr[currNd].lemma.expr, " ",
                                           "nextNd:", gr[nextNd].lemma.expr, " ");
                if (auto hit = nextNd in visitByNd)          // if nextNd already visited
                {
                    const NWeight currNextGoodness = (*hit)[0]; // NOTE (*hit)[1] is not needed to compare here

                    static if (strategy == WalkStrategy.dijkstraMinDistance)
                    {
                        version (debugPrint) write("dist:", currNextGoodness, "=>", newNextGoodness, " ");
                        if (newNextGoodness < currNextGoodness) // a stronger connection was found
                        {
                            version (debugPrint) writeln("is updated");
                            *hit = Visit(newNextGoodness, Step(frontLn, currNd)); // update visitByNd with best yet
                            pending.removeKey(Pending(currNextGoodness, nextNd)); // remove old
                            pending.insert(Pending(newNextGoodness, nextNd));
                        }
                        else
                        {
                            version (debugPrint) writeln("is not updated");
                        }
                    }
                    else static if (strategy == WalkStrategy.nordlowMaxConnectiveness)
                    {
                        const newTotalDist = newNextGoodness + currNextGoodness;
                        *hit = Visit(newTotalDist, currNd); // update visitByNd with best yet
                        pending.removeKey(Visit(currNextGoodness, nextNd)); // remove old
                        pending.insert(Visit(newTotalDist, nextNd));
                    }

                }
                else            // if first time we visit nextNd
                {
                    version (debugPrint) writeln("dist:", newNextGoodness, " is added");
                    visitByNd[nextNd] = Visit(newNextGoodness, Step(frontLn, currNd)); // first is best
                    pending.insert(Pending(newNextGoodness, nextNd));
                }
            }
        }
    }

    /** This needs to be explicit, otherwise std.range.moveFront calls postblit
     * makes traverser.moveFront a no-op. I don't know why.
     */
    Nd moveFront()
    {
        const Nd nd = front;
        popFront;
        return nd;
    }

    bool empty() @safe pure nothrow @nogc // TODO const
    {
        return pending.empty;
    }

    NNWalker save() @property // makes this a ForwardRange
    {
        typeof(return) copy = this;
        return copy;
    }

public:
    Visit[Nd] visitByNd;        // Nd => tuple(Nd origin distance, parent Nd)
    Queue pending;              // queue of pending (untraversed) nodes
    const Nd start;             // search start node
    const StepFilter filter;
    const useRelevance = false;
private:
    Graph gr;
}

auto nnWalker(WalkStrategy strategy)(Graph gr, Nd start, const StepFilter filter = StepFilter.init,
                                     bool useRelevance = false)
{
    return NNWalker!(strategy)(gr, start, filter, useRelevance);
}

/** Perform a Complete Traversal of $(D gr) using NNWalker with $(D start) as origin. */
auto nnWalk(WalkStrategy strategy)(Graph gr, Nd start, const StepFilter filter = StepFilter.init,
                                   bool useRelevance = false)
{
    auto walker = nnWalker!(strategy)(gr, start, filter, useRelevance);
    while (!walker.empty) { walker.popFront; } // TODO functionize to exhaust
    return walker;                             // hopefully this moves
}

/** Perform a Complete Traversal of $(D gr) using NNWalker with $(D start) as origin. */
auto dijkstraNNWalk(Graph gr, Nd start, const StepFilter filter = StepFilter.init,
                    bool useRelevance = false) pure
{
    return nnWalk!(WalkStrategy.dijkstraMinDistance)(gr, start, filter,
                                                     useRelevance);
}
