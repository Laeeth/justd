module knet.traversal;

import knet.base;

/** Bread First Graph Walk(er) (Traverser)
    Modelled as an (Input Range) with ElementType being an Nd-array (Nd[]).
*/
class BFWalk
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
        this.senses = senses;
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
    auto range = new typeof(return)(graph, start, langs, senses, roles, origins);
    return range;
}

/** Nearest-Origin-First Graph Walker/Traverser Range.

    Dijkstra's Railroad Algorithm turned into a D Range.

    Modelled as a Forward Range with ElementType being Nd.

    Upon iteration completion distMap contains a map from node to (distance, and
    closest parent node) to walk starting point (startNd). This can be used to
    reconstruct the closest path from any given Nd to startNd.
*/
class DijkstraWalk
{
    import std.typecons: Tuple;

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
        this.senses = senses;
        this.roles = roles;
        this.origins = origins;

        nextNds ~= startNd.raw;

        import std.typecons: tuple;
        distMap[startNd.raw] = tuple(0, // TODO parameterize on distance function
                                     Nd.asUndefined); // first node has parent
    }

    auto front() const @safe pure nothrow
    {
        import std.range: empty;
        assert(!nextNds.empty, "Can't fetch front from an empty DijkstraWalk");
        import std.range: front;
        return nextNds.front;
    }

    enum useArray = true;

    void popFront()
    {
        assert(!nextNds.empty, "Can't pop front from an empty DijkstraWalk");

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
            // TODO make UFCS work here by moving Graph members ndsOf to knet.iteration
            foreach (const nextNd; knet.iteration.ndsOf(graph, frontLn, langs, senses, frontNd))
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

    DijkstraWalk save() @property // makes this a ForwardRange
    {
        typeof(return) copy = this;
        // TODO unittest this
        /** TODO duplicate all non-const members with reference semantics except
            Graph.  Use MemberTypeTuple to iterate corresponding member of this
            and copy.
            */
        copy.nextNds = this.nextNds.dup;
        copy.distMap = this.distMap.dup; // TODO is this needed?
        return copy;
    }

    // Nd => tuple(Nd origin distance, parent Nd)
    Visit[Nd] distMap;

private:
    Graph graph;

    // yet to be untraversed nodes sorted by smallest distance to startNd
    static if (useArray)
    {
        import std.container: Array;
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

DijkstraWalk dijkstraWalk(Graph graph, Nd start,
                          const Lang[] langs = [],
                          const Sense[] senses = [],
                          const Role[] roles = [],
                          const Origin[] origins = [])
{
    return new typeof(return)(graph, start, langs, senses, roles, origins);
}
