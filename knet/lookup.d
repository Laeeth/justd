module knet.lookup;

import knet.base;

Nd ndByLemmaMaybe(Graph gr,
                  in Lemma lemma) pure
{
    return get(gr.db.ixes.ndByLemma, lemma, typeof(return).init);
}

/** Try to Get Single Node related to $(D word) in the interpretation
    (semantic context) $(D sense).
*/
Nds ndsByLemmaDirect(S)(Graph gr,
                        S expr,
                        Lang lang,
                        Sense sense,
                        Ctx context) pure if (isSomeString!S)
{
    typeof(return) nodes;
    const lemma = Lemma(expr, lang, sense, context);
    if (const lemmaNd = lemma in gr.db.ixes.ndByLemma)
    {
        nodes ~= *lemmaNd; // use it
    }
    else
    {
        static if (false) // TODO Enable this logic by moving findWordsSplit to Graph
        {
            // try to lookup parts of word
            const wordsSplit = wordnet.findWordsSplit(expr, [lang]); // split in parts
            if (wordsSplit.length >= 2)
            {
                import std.algorithm.iteration: joiner;
                if (const lemmaFixedNd = Lemma(wordsSplit.joiner(`_`).to!S,
                                               lang, sense, context) in db.ixes.ndByLemma)
                {
                    nodes ~= *lemmaFixedNd;
                }
            }
        }
    }
    return nodes;
}

/** Get All Possible Lemmas related to Expression (set of words) $(D expr).
 */
Lemmas lemmasOfQualifiedExpr(S)(Graph gr,
                                S expr)
    @safe pure nothrow if (isSomeString!S)
{
    auto split = expr.findSplit(qualifierSeparatorString); // TODO use splitter instead to support en:noun:city
    const senseCode = split[0];
    if (!senseCode.empty)
    {
        import std.conv: ConvException;
        try
        {
            import std.conv: to;
            import knet.senses: specializes;
            const sense = senseCode.to!Sense;
            return gr.lemmasOfExpr(split[2], false)
                     .filter!(lemma => (sense != Sense.unknown &&
                                        (lemma.sense == sense ||
                                         lemma.sense.specializes(sense)))).array; // TODO functionize
        }
        catch (Exception e) { /* ok for now */ }
    }
    return [];
}

/** Get All Possible Lemmas related to Expression (set of words) $(D expr).
 */
Lemmas lemmasOfExpr(S)(Graph gr,
                       S expr,
                       bool tryQualifierSplit = true)
    @safe pure /*nothrow*/ if (isSomeString!S)
{
    static if (is(S == string)) // TODO Is there a prettier way to do this?
    {
        typeof(return) lemmas = gr.db.ixes.lemmasByExpr
                                  .get(expr, typeof(return).init);
    }
    else
    {
        typeof(return) lemmas = gr.db.ixes.lemmasByExpr
                                  .get(expr.dup, typeof(return).init); // TODO Why is dup needed here?
    }
    if (tryQualifierSplit &&
        lemmas.empty)
    {
        import knet.lookup: lemmasOfQualifiedExpr;
        return gr.lemmasOfQualifiedExpr(expr); // don't try multiple qualifiers for now
    }
    return lemmas;
}

/** Get All Possible Lemmas related to Word $(D word).
 */
Lemmas lemmasOfWord(S)(S word) if (isSomeString!S)
{
    static if (is(S == string)) // TODO Is there a prettier way to do this?
    {
        return db.lemmasByWord.get(word, typeof(return).init);
    }
    else
    {
        return db.lemmasByWord.get(word.dup, typeof(return).init); // TODO Why is dup needed here?
    }
}

/// Get Learn Possible Senses for $(D expr).
auto sensesOfExpr(S)(Graph gr,
                     S expr, bool includeUnknown = false) @safe pure if (isSomeString!S)
{
    return gr.lemmasOfExpr(expr)
             .map!(lemma => lemma.sense)
             .filter!(sense => (includeUnknown ||
                                sense != Sense.unknown));
}

/// Get Possible Common Sense for $(D a) and $(D b). TODO N-ary
auto commonSenses(S1, S2)(Graph gr,
                          S1 a, S2 b,
                          bool includeUnknown = false) @safe pure if (isSomeString!S1 &&
                                                                      isSomeString!S2)
{
    import std.algorithm: setIntersection;
    return setIntersection(gr.sensesOfExpr(a, includeUnknown).sorted,
                           gr.sensesOfExpr(b, includeUnknown).sorted);
}

/// Get Possible Unique Common Sense for $(D a) and $(D b). TODO N-ary
Sense uniqueCommonSense(S1, S2)(Graph gr,
                                S1 a, S2 b,
                                bool includeUnknown = false) @safe pure if (isSomeString!S1 &&
                                                                            isSomeString!S2)
{
    auto senses = gr.commonSenses(a, b, includeUnknown);
    return senses.count == 1 ? senses.front : Sense.unknown;
}
