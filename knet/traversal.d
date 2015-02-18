module knet.traversal;

import knet.base;

/** Bread First Graph Walk(er) (Traverser)
*/
struct BFWalker
{
    pure:

    this(Graph graph,
         const Nd start,
         const Lang[] langs = [],
         const Sense[] senses = [],
         const Role[] roles = [],
         const Origin[] origins = []) @safe nothrow in { assert(start.defined); }
    body
    {
        this.graph = graph;

        this.langs = langs;
        this.senses = senses;
        this.roles = roles;
        this.origins = origins;

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

        foreach (const frontNd; frontNds)
        {
            import knet.iteration: lnsOf;
            foreach (const frontLn; graph.lnsOf(frontNd, roles, origins))
            {
                foreach (const nextNd; graph[frontLn].actors[] // TODO functionize using .ndsOf if we can find a way to include frontNd
                                                     .map!(nd => nd.raw)
                                                     .filter!(nd =>
                                                              nd != frontNd &&
                                                              (langs.empty || langs.canFind(graph[nd].lemma.lang)) &&
                                                              (senses.empty || senses.canFind(graph[nd].lemma.sense)) &&
                                                              nd.raw !in connectivenessByNd))
                {
                    pendingNds ~= nextNd;
                    const connectiveness = connectivenessByNd[frontNd] * graph[frontLn].nweight;
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

private:
    Graph graph;

    // internal state
    Nds frontNds;              // current nodes

    // filters
    // TODO group into structure
    const Lang[] langs;         // languages to match
    const Sense[] senses;       // senses to match
    const Role[] roles;         // roles to match
    const Origin[] origins;     // origins to match
}

BFWalker bfWalker(Graph graph, Nd start,
              const Lang[] langs = [],
              const Sense[] senses = [],
              const Role[] roles = [],
              const Origin[] origins = []) pure
{
    return typeof(return)(graph, start, langs, senses, roles, origins);
}

/** Nearest-Origin-First Graph Walker/Traverser Range.

    Dijkstra's Railroad Algorithm turned into a D Range.

    Modelled as a Forward Range with ElementType being Nd.

    Upon iteration completion distMap contains a map from node to (distance, and
    closest parent node) to walker starting point (start). This can be used to
    reconstruct the closest path from any given Nd to start.
*/
struct DijkstraWalker
{
    import std.typecons: Tuple;

    alias Visit = Tuple!(NWeight, Nd);

    this(Graph graph,
         const Nd start,
         const Lang[] langs = [],
         const Sense[] senses = [],
         const Role[] roles = [],
         const Origin[] origins = []) in { assert(start.defined); }
    body
    {
        this.graph = graph;

        this.langs = langs;
        this.senses = senses;
        this.roles = roles;
        this.origins = origins;

        nextNds ~= start.raw;
        import std.typecons: tuple;
        // WARNING distMap must initialized here to provide reference semantics
        distMap[start.raw] = tuple(0, // TODO parameterize on distance function
                                     Nd.asUndefined); // first node has parent

        assert(!nextNds.empty); // must be initialized to enable reference semantics
        assert(distMap !is null); // must be initialized to enable reference semantics
    }

    /** Postblit. */
    this(this)
    {
        nextNds = nextNds.dup;
        distMap = distMap.dup;
    }

    auto front() const @safe pure nothrow
    {
        import std.range: empty;
        assert(!nextNds.empty, "Can't fetch front from an empty DijkstraWalker");
        import std.range: front;
        return nextNds.front;
    }

    enum useArray = true;
    static if (useArray)
    {
        import std.container: Array;
    }

    void popFront()
    {
        assert(!nextNds.empty, "Can't pop front from an empty DijkstraWalker");

        static if (useArray)
        {
            const frontNd = nextNds.front;
            nextNds = Array!Nd(nextNds[1 .. $]); // TODO too costly?
        }
        else
        {
            import std.range: moveFront;
            const frontNd = nextNds.moveFront;
        }

        const savedLength = nextNds.length;

        import knet.iteration: lnsOf;
        foreach (const frontLn; graph.lnsOf(frontNd, roles, origins))
        {
            import knet.iteration: ndsOf;
            foreach (const nextNd; graph.ndsOf(frontLn, langs, senses, frontNd))
            {
                const newDist = distMap[frontNd][0] + graph[frontLn].nweight; // TODO parameterize on distance funtion
                if (auto hit = nextNd in distMap)
                {
                    const dist = (*hit)[0]; // NOTE (*hit)[1] is not needed to compare here
                    if (newDist < dist) // a closer way was found
                    {
                        *hit = Visit(newDist, frontNd); // best yet
                    }
                }
                else
                {
                    distMap[nextNd] = Visit(newDist, frontNd); // best yet
                    nextNds ~= nextNd;
                }
            }
        }

        import std.algorithm.sorting: partialSort;
        // TODO use my radixSort for better performance
        nextNds[].partialSort!((a, b) => (distMap[a][0] <
                                          distMap[b][0]))(savedLength);
    }

    bool empty() const @safe pure nothrow @nogc
    {
        return nextNds.empty;
    }

    DijkstraWalker save() @property // makes this a ForwardRange
    {
        typeof(return) copy = this;
        return copy;
    }

    // WARNING distMap must initialized here to provide reference semantics in for range behaviour to work correctly
    // See also: http://forum.dlang.org/thread/xrxejicnoakanvkyasso@forum.dlang.org#post-yipmrrdilsxcaypeoqhz:40forum.dlang.org
    Visit[Nd] distMap;          // Nd => tuple(Nd origin distance, parent Nd)

private:
    Graph graph;

    // yet to be untraversed nodes sorted by smallest distance to start
    static if (useArray)
    {
        Array!Nd nextNds;
    }
    else
    {
        Nd[] nextNds;
    }

    // TODO how can I make use of BinaryHeap here instead?
    static if (false)
    {
        import std.container.binaryheap: BinaryHeap;
        BinaryHeap!(Nds, ((a, b) => (this.distMap[a][0] <
                                     this.distMap[b][0]))) pendingNds;
    }

    // filters
    // TODO group into structure
    const Lang[] langs;         // languages to match
    const Sense[] senses;       // senses to match

    const Role[] roles;         // roles to match
    const Origin[] origins;     // origins to match
}

DijkstraWalker dijkstraWalker(Graph graph, Nd start,
                              const Lang[] langs = [],
                              const Sense[] senses = [],
                              const Role[] roles = [],
                              const Origin[] origins = [])
{
    return typeof(return)(graph, start, langs, senses, roles, origins);
}

/** Perform a Complete Traversal of $(D graph) using DijkstraWalker with $(D start) as origin. */
DijkstraWalker dijkstraWalk(Graph graph, Nd start,
                            const Lang[] langs = [],
                            const Sense[] senses = [],
                            const Role[] roles = [],
                            const Origin[] origins = [])
{
    auto walker = dijkstraWalker(graph, start, langs, senses, roles, origins);
    while (!walker.empty) { walker.popFront; } // TODO functionize to exhaust
    return walker;                             // hopefully this moves
}
