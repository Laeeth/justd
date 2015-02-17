module knet.traversal;

import knet.base;

/** Bread First Graph Walk(er) (Traverser)
    Modelled as an (Input Range) with ElementType being an Nd-array (Nd[]).
*/
struct BFWalk
{
    pure:

    this(Graph graph,
         const Nd startNd,
         const Lang[] langs = [],
         const Sense[] senses = [],
         const Role[] roles = [],
         const Origin[] origins = []) @safe nothrow
    {
        this.graph = graph;

        this.langs = langs;
        this.roles = roles;
        this.origins = origins;

        frontNds ~= startNd.raw;
        connectivenessByNd[startNd.raw] = 1; // tag startNd as visited
    }

    auto front() const @safe pure nothrow @nogc
    {
        import std.range: front;
        assert(!frontNds.empty, "Attempting to fetch the front of an empty Walk");
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
                                                     .filter!(nd =>
                                                              nd.raw != frontNd &&
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

    // internal state
    NWeight[Nd] connectivenessByNd; // maps frontNds minimum distance from visited to startNd

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

BFWalk bfWalk(Graph graph, Nd start,
              const Lang[] langs = [],
              const Sense[] senses = [],
              const Role[] roles = [],
              const Origin[] origins = []) pure
{
    auto range = typeof(return)(graph, start, langs, senses, roles, origins);
    return range;
}

/** Nearest First Graph Walker/Traverser Range.
    Similar to Dijkstra's Railroad Algorithm.
    Modelled as a Forward Range with ElementType being a Nd.

    Upon iteration completion mapByNd contains a map from node to (distance, and
    closest parent node) to walk starting point (startNd). This can be used to
    reconstruct the closest path from any given Nd to startNd.
*/
struct DijkstraWalk(bool useArray)
{
    import std.typecons: Tuple;
    // TODO enable pure:

    alias Visit = Tuple!(NWeight, Nd);

    this(Graph graph,
         const Nd startNd,
         const Lang[] langs = [],
         const Sense[] senses = [],
         const Role[] roles = [],
         const Origin[] origins = [])
    {
        this.graph = graph;

        this.langs = langs;
        this.roles = roles;
        this.origins = origins;

        untraversedNds ~= startNd.raw;

        import std.typecons: tuple;
        mapByNd[startNd.raw] = tuple(0, // TODO parameterize on distance function
                                     Nd.asUndefined); // first node has parent
    }

    auto front() const @safe pure nothrow
    {
        import std.range: empty;
        assert(!untraversedNds.empty, "Can't fetch front from an empty DijkstraWalk");
        import std.range: front;
        return untraversedNds.front;
    }

    void popFront()
    {
        assert(!untraversedNds.empty, "Can't pop front from an empty DijkstraWalk");

        writeln(untraversedNds.length);

        import std.range: moveFront;
        const frontNd = untraversedNds.moveFront;

        const savedLength = untraversedNds.length;

        import knet.iteration: lnsOf;
        foreach (const frontLn; graph.lnsOf(frontNd, roles, origins))
        {
            foreach (const nextNd; graph[frontLn].actors[] // TODO functionize using .ndsOf if we can find a way to include frontNd
                                                 .filter!(nd =>
                                                          nd.raw != frontNd &&
                                                          (langs.empty || langs.canFind(graph[nd].lemma.lang)) &&
                                                          (senses.empty || senses.canFind(graph[nd].lemma.sense))))
            {
                const newDist = mapByNd[frontNd][0] + graph[frontLn].nweight; // TODO parameterize on distance funtion
                if (auto hit = nextNd in mapByNd)
                {
                    const dist = (*hit)[0];
                    const parentNd = (*hit)[1];
                    if (newDist < dist) // a closer way was found
                    {
                        *hit = Visit(newDist, frontNd); // best yet
                    }
                }
                else
                {
                    mapByNd[nextNd] = Visit(newDist, frontNd); // best yet
                    untraversedNds ~= nextNd;
                }
            }
        }

        import std.algorithm.sorting: partialSort;
        untraversedNds[].partialSort!((a, b) => (mapByNd[a][0] <
                                                 mapByNd[b][0]))(savedLength);
    }

    bool empty() const @safe pure nothrow @nogc
    {
        return untraversedNds.empty;
    }

    @property DijkstraWalk save() // makes this a ForwardRange
    {
        typeof(return) copy = this;
        copy.untraversedNds = this.untraversedNds.dup;
        copy.mapByNd = this.mapByNd.dup;
        return copy;
    }

    // Nd => tuple(Nd origin distance, parent Nd)
    Visit[Nd] mapByNd;

private:
    Graph graph;

    static if (useArray)
    {
        import std.container: Array;
        Array!Nd untraversedNds; // sorted by smallest distance to startNd
    }
    else
    {
        Nds untraversedNds; // sorted by smallest distance to startNd
    }

    // TODO how can I make use of BinaryHeap here instead?
    static if (false)
    {
        import std.container.binaryheap: BinaryHeap;
        BinaryHeap!(Nds, ((a, b) => (this.mapByNd[a][0] <
                                     this.mapByNd[b][0]))) pendingNds;
    }

    // filters
    // TODO group into structure
    const Lang[] langs;         // languages to match
    const Sense[] senses;       // senses to match

    const Role[] roles;         // roles to match
    const Origin[] origins;     // origins to match
}

auto dijkstraWalk(bool useArray = true)(Graph graph, Nd start,
                                        const Lang[] langs = [],
                                        const Sense[] senses = [],
                                        const Role[] roles = [],
                                        const Origin[] origins = [])
{
    auto range = DijkstraWalk!(useArray)(graph, start, langs, senses, roles, origins);
    return range;
}
