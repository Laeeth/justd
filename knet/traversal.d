module knet.traversal;

import knet.base;

/** Bread First Graph Walk(er) (Traverser)
*/
struct BFWalker
{
    pure:

    this(Graph gr,
         const Nd start,
         const Filter filter = Filter.init) @safe nothrow in { assert(start.defined); }
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
    const Filter filter;
private:
    Graph gr;
    Nds frontNds;              // current nodes (internal state)
}

BFWalker bfWalker(Graph gr, Nd start,
                  const Filter filter = Filter.init) pure
{
    return typeof(return)(gr, start, filter);
}

/** Nearest-Origin-First Graph Walker/Traverser Range.

    Dijkstra's Railroad Algorithm turned into a D Range.

    Modelled as a Forward Range with ElementType being Nd.

    Upon iteration completion distMap contains a map from node to (distance, and
    closest parent node) to walker starting point (start). This can be used to
    reconstruct the closest path from any given Nd to start.

    See also: http://rosettacode.org/wiki/Dijkstra%27s_algorithm#D

    WARNING pending and distMap must initialized here to provide reference semantics in for
    range behaviour to work correctly

    See also: http://forum.dlang.org/thread/xrxejicnoakanvkyasso@forum.dlang.org#post-yipmrrdilsxcaypeoqhz:40forum.dlang.org

    TODO: Use containers.hashmap.HashMap and tag as @nogc
*/
struct DijkstraWalker
{
    import std.typecons: Tuple, tuple;
    import std.container: redBlackTree, RedBlackTree;

    alias Visit = Tuple!(NWeight, Nd);
    alias Queue = RedBlackTree!Visit;

    this(Graph gr,
         const Nd start,
         const Filter filter = Filter.init) in { assert(start.defined); }
    body
    {
        this.gr = gr;
        this.filter = filter;
        this.start = start;

        // WARNING distMap must initialized here to provide reference semantics
        pending = redBlackTree(Visit(0, start));
        distMap[start.raw] = Visit(0, Nd.asUndefined);

        assert(!pending.empty); // must be initialized to enable reference semantics
        assert(distMap !is null); // must be initialized to enable reference semantics
    }

    /** Postblit. */
    this(this) in { assert(pending !is null &&
                           distMap !is null); }
    body
    {
        pending = pending.dup;
        distMap = distMap.dup;
        writeln("Called postblit when nextNd is ", gr[pending.front[1]].lemma,
                " and pending.length=", pending.length,
                " and distMap.length=", distMap.length);
    }

    Nd front() @safe pure nothrow // TODO make const when pending.empty is const
    {
        import std.range: empty;
        assert(!pending.empty, "Can't fetch front from an empty DijkstraWalker");
        import std.range: front;
        return pending.front[1];
    }

    void popFront()
    {
        assert(!pending.empty, "Can't pop front from an empty DijkstraWalker");

        import std.range: moveFront;
        const curr = pending.front; pending.removeFront;
        const currW = curr[0];
        const currNd = curr[1];

        const savedLength = pending.length;

        import knet.iteration: lnsOf;
        foreach (const frontLn; gr.lnsOf(currNd, filter.roles, filter.origins))
        {
            import knet.iteration: ndsOf;
            foreach (const nextNd; gr.ndsOf(frontLn, filter.langs, filter.senses, currNd))
            {
                const newNextDist = currW + gr[frontLn].ndist; // TODO parameterize on distance funtion
                if (auto hit = nextNd in distMap)          // if nextNd already visited
                {
                    const NWeight currNextDist = (*hit)[0]; // NOTE (*hit)[1] is not needed to compare here
                    if (newNextDist < currNextDist) // a closer way was found
                    {
                        *hit = Visit(newNextDist, currNd); // update distMap with best yet
                        pending.removeKey(Visit(currNextDist, nextNd)); // remove old
                        pending.insert(Visit(newNextDist, nextNd));
                    }
                }
                else            // if first time we visit nextNd
                {
                    distMap[nextNd] = Visit(newNextDist, currNd); // first is best
                    pending.insert(Visit(newNextDist, nextNd));
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

    DijkstraWalker save() @property // makes this a ForwardRange
    {
        typeof(return) copy = this;
        return copy;
    }

public:
    Visit[Nd] distMap;          // Nd => tuple(Nd origin distance, parent Nd)
    Queue pending;              // queue of pending (untraversed) nodes
    const Nd start;             // search start node
    const Filter filter;
private:
    Graph gr;
}

DijkstraWalker dijkstraWalker(Graph gr, Nd start, const Filter filter = Filter.init)
{
    return typeof(return)(gr, start, filter);
}

/** Perform a Complete Traversal of $(D gr) using DijkstraWalker with $(D start) as origin. */
DijkstraWalker dijkstraWalk(Graph gr, Nd start, const Filter filter = Filter.init)
{
    auto walker = dijkstraWalker(gr, start, filter);
    while (!walker.empty) { walker.popFront; } // TODO functionize to exhaust
    return walker;                             // hopefully this moves
}
