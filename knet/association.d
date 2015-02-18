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
    import knet.traversal: dijkstraWalk;
    auto walks = nds.map!(nd => gr.dijkstraWalk(nd, langs, senses, roles, origins));

    // iterate walks in Round Robin fashion. TODO functionize
    import std.algorithm.searching: any;
    while (walks.any!(walk => !walk.empty)) // while we still have walk
    {
        foreach (ref activeWalk; walks.filter!(walk => !walk.empty))
        {
            import std.range: moveFront;
            const front = activeWalk.moveFront;
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
