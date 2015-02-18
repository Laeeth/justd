module knet.association;

import knet.base;

/** Get Node with strongest relatedness to $(D text).
    TODO Compare with function Context() in ConceptNet API.
*/
Nd contextOf(Nds)(Graph gr,
                  Nds nds,
                  const Lang[] langs = [],
                  const Sense[] senses = [],
                  const Role[] roles = [],
                  const Origin[] origins = []) if (isIterable!Nds &&
                                                   is(Nd == ElementType!Nds))
{
    auto node = typeof(return).init;
    import knet.traversal: dijkstraWalker;

    // do we need array here?
    auto walkers = nds.map!(nd => gr.dijkstraWalker(nd, langs, senses, roles, origins)).array;

    // iterate walkers in Round Robin fashion. TODO functionize
    import std.algorithm.searching: any;
    while (walkers.any!(walker => !walker.empty)) // while we still have walker
    {
        foreach (ref activeWalker; walkers.filter!(walker => !walker.empty))
        {
            import std.range: moveFront;
            const front = activeWalker.moveFront;
            writeln("front: ", front);
        }
    }

    return node;
}

/** Get Node with strongest relatedness to $(D exprs).
 */
Nd contextOf(Exprs)(Graph gr,
                    Exprs exprs,
                    const Lang[] langs = [],
                    const Sense[] senses = [],
                    const Role[] roles = [],
                    const Origin[] origins = []) if (isIterable!Exprs &&
                                                   isSomeString!(ElementType!Exprs))
{
    import std.algorithm: joiner;
    auto lemmas = exprs.map!(expr => gr.lemmasOfExpr(expr)).joiner;
    auto nds = lemmas.map!(lemma => gr.db.ixes.ndByLemma[lemma]);
    return gr.contextOf(nds, langs, senses, roles, origins);
}

alias topicOf = contextOf;
