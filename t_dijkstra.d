import std.typecons: Tuple, tuple;
import std.container: redBlackTree;

alias Node = string;
alias Weight = int;

const struct Neighbor
{
    Node target;
    Weight weight;
}

alias AdjacencyMap = Neighbor[][Node];

/** Dijkstra's Algorithm.
   See also: http://rosettacode.org/wiki/Dijkstra's_algorithm#D
 */
Tuple!(Weight[Node], Node[Node]) dijkstraComputePaths(in Node source,
                                                      in Node target,
                                                      in AdjacencyMap adjacencyMap) /* pure */
{
    Weight[Node] minDistance;
    foreach (immutable v, const neighs; adjacencyMap)
    {
        minDistance[v] = Weight.max;
        foreach (immutable n; neighs)
            minDistance[n.target] = Weight.max;
    }

    minDistance[source] = 0;
    alias Pair = Tuple!(Weight, Node);
    auto vertexQueue = redBlackTree(Pair(minDistance[source], source));
    typeof(typeof(return).init[1]) previous;

    while (!vertexQueue.empty)
    {
        const u = vertexQueue.front[1];
        vertexQueue.removeFront;

        if (u == target)
            break;

        // Visit each edge exiting u.
        foreach (immutable n; adjacencyMap.get(u, null))
        {
            const v = n.target;
            const distanceThroughU = minDistance[u] + n.weight;
            if (distanceThroughU < minDistance[v])
            {
                vertexQueue.removeKey(Pair(minDistance[v], v));
                minDistance[v] = distanceThroughU;
                previous[v] = u;
                vertexQueue.insert(Pair(minDistance[v], v));
            }
        }
    }

    return tuple(minDistance, previous);
}

Node[] dijkstraGetShortestPathTo(Node v,
                                 in Node[Node] previous) /* pure */ nothrow
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

unittest
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
        adj[arc[0]] ~= Neighbor(arc[1], arc[2]);
        // Add this if you want an undirected graph:
        //adj[arc[1]] ~= Neighbor(arc[0], arc[2]);
    }

    const minDistPrevious = dijkstraComputePaths("a", "e", adj);
    const minDistance = minDistPrevious[0];
    const previous = minDistPrevious[1];

    assert(minDistance["e"] == 26);
    assert(minDistance["f"] == 11);
    assert(dijkstraGetShortestPathTo("e", previous) == ["a", "c", "d", "e"]);

    version(print)
    {
        import std.stdio: writeln;
        writeln(`Distance from "a" to "e": `, minDistance["e"]);
        writeln(`Distance from "a" to "f": `, minDistance["f"]);
        writeln("Path: ", dijkstraGetShortestPathTo("e", previous));
    }
}
