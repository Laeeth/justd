import std.typecons: Tuple, tuple;
import std.container: redBlackTree;

alias Node = string;
alias Weight = int;

const struct Neighbour
{
    Node target;
    Weight weight;
}

/** Adjacency Map. */
alias AdjacencyMap = Neighbour[][Node];

/** Dijkstra's Algorithm.
   See also: http://rosettacode.org/wiki/Dijkstra's_algorithm#D
 */
Tuple!(Weight[Node], Node[Node]) dijkstraComputePaths(in Node source,
                                                      in Node target,
                                                      in AdjacencyMap adjacencyMap) pure
{
    Weight[Node] minDist;
    foreach (immutable v, const neighs; adjacencyMap)
    {
        minDist[v] = Weight.max;
        foreach (immutable n; neighs)
            minDist[n.target] = Weight.max;
    }

    minDist[source] = 0;
    alias Pair = Tuple!(Weight, Node);
    auto nodeQ = redBlackTree(Pair(minDist[source], source));
    typeof(typeof(return).init[1]) previous;

    while (!nodeQ.empty)
    {
        const u = nodeQ.front[1];
        nodeQ.removeFront;

        if (u == target)
            break;

        // Visit each edge exiting u.
        foreach (immutable n; adjacencyMap.get(u, null))
        {
            const v = n.target;
            const distanceThroughU = minDist[u] + n.weight;
            if (distanceThroughU < minDist[v])
            {
                nodeQ.removeKey(Pair(minDist[v], v));
                minDist[v] = distanceThroughU;
                previous[v] = u;
                nodeQ.insert(Pair(minDist[v], v));
            }
        }
    }

    return tuple(minDist, previous);
}

Node[] dijkstraGetShortestPathTo(Node v,
                                 in Node[Node] previous) pure nothrow
{
    auto path = [v];
    while (v in previous)
    {
        v = previous[v];
        if (v == path[$ - 1])
            break;
        path ~= v;
    }
    import std.algorithm: reverse;
    path.reverse();
    return path;
}

version = print;

pure unittest
{
    immutable arcs = [tuple("a", "b", 7),
                      tuple("a", "c", 9),
                      tuple("a", "f", 14),
                      tuple("b", "c", 10),
                      tuple("b", "d", 15),
                      tuple("c", "d", 11),
                      tuple("c", "f", 2),
                      tuple("d", "e", 6),
                      tuple("e", "f", 9)];

    AdjacencyMap adj;
    foreach (immutable arc; arcs)
    {
        adj[arc[0]] ~= Neighbour(arc[1], arc[2]);
        // Add this if you want an undirected graph:
        //adj[arc[1]] ~= Neighbour(arc[0], arc[2]);
    }

    const minDistPrevious = dijkstraComputePaths("a", "e", adj);
    const minDist = minDistPrevious[0];
    const previous = minDistPrevious[1];

    assert(minDist["e"] == 26);
    assert(minDist["b"] ==  7);
    assert(minDist["c"] ==  9);
    assert(minDist["d"] == 20);
    assert(minDist["e"] == 26);
    assert(minDist["f"] == 11);
    assert(dijkstraGetShortestPathTo("e", previous) == ["a", "c", "d", "e"]);

    version(print)
    {
        import std.stdio: writeln;
        debug writeln(`Distance from "a" to "e": `, minDist["e"]);
        debug writeln("Path: ", dijkstraGetShortestPathTo("e", previous));
    }
}
