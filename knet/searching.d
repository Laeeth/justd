module knet.searching;

import knet.base;

/** Get Node References whose Lemma Expr starts with $(D prefix). */
auto canFind(S)(Graph graph,
                S part,
                Lang lang = Lang.unknown,
                Sense sense = Sense.unknown) if (isSomeString!S)
{
    import std.algorithm.searching: canFind;
    return graph.db.ixes.ndByLemma.values.filter!(nd => graph[nd].lemma.expr.canFind(part));
}

/** Get Node References whose Lemma Expr starts with $(D prefix). */
auto startsWith(S)(Graph graph,
                   S prefix,
                   Lang lang = Lang.unknown,
                   Sense sense = Sense.unknown) if (isSomeString!S)
{
    import std.algorithm.searching: startsWith;
    return graph.db.ixes.ndByLemma.values.filter!(nd => graph[nd].lemma.expr.startsWith(prefix));
}

/** Get Node References whose Lemma Expr starts with $(D suffix). */
auto endsWith(S)(Graph graph,
                 S suffix,
                 Lang lang = Lang.unknown,
                 Sense sense = Sense.unknown) if (isSomeString!S)
{
    import std.algorithm.searching: endsWith;
    return graph.db.ixes.ndByLemma.values.filter!(nd => graph[nd].lemma.expr.endsWith(suffix));
}
