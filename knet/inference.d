module knet.inference;

import knet.base;

/* TODO Infer in multiple steps/passes:
   synonymFor ==specializes==> abbreviationFor ==specializes=> acronymFor
   */
void inferSpecializedRelations(Graph gr)
{
}

/**
   Infer Noun/Verb Phrase Relations.

   noun:"red light"
   - isA noun:"light"
   - hasAttribute adjective:"red"
 */
void inferPhraseRelations(Graph gr,
                          Expr expr,
                          Lemmas compoundLemmas,
                          Lang[] langs)
{
    const words = expr.split(` `);
    switch (words.length)
    {
        case 2:
            import knet.iteration: ndsOf;
            import knet.filtering: matches;
            foreach (compoundLemma; compoundLemmas.filter!(lemma => (langs.matches(lemma.lang) &&
                                                                     [Sense.noun].matches(lemma.sense, true, lemma.lang)))) // noun:"red light"
            {
                const compoundNd = gr.db.ixes.ndByLemma[compoundLemma];
                foreach (const adjectiveNd; gr.ndsOf(words[0], [compoundLemma.lang], [Sense.adjective], false, false)) // adjective:red
                {
                    gr.connect(compoundNd,
                               Role(Rel.hasAttribute),
                               adjectiveNd,
                               Origin.inference, 1.0);
                }
                foreach (const nounNd; gr.ndsOf(words[1], [compoundLemma.lang], [Sense.noun], false, false)) // noun:light
                {
                    gr.connect(compoundNd,
                               Role(Rel.isA),
                               nounNd,
                               Origin.inference, 1.0);
                }
            }
            break;
        default:
            break;
    }
}

void inferSpecializedSenses(Graph gr, Expr expr, Lemmas lemmas)
{
    bool show = true;
    if (lemmas.map!(lemma => lemma.lang).allEqual)
    {
        import dbg: dln;
        import knet.senses: specializes;
        import knet.languages: toHuman;
        switch (lemmas.length)
        {
            case 2:
                if (lemmas[0].sense.specializes(lemmas[1].sense))
                {
                    if (show)
                    {
                        dln(`Specializing Lemma expr "`, expr,
                            `" in `, lemmas[0].lang.toHuman, ` of sense from "`,
                            lemmas[1].sense, `" to "`, lemmas[0].sense, `"`);
                    }
                    // lemmas[1].sense = lemmas[0].sense;
                }
                else if (lemmas[1].sense.specializes(lemmas[0].sense))
                {
                    if (show)
                    {
                        dln(`Specializing Lemma expr "`, expr,
                            `" in `, lemmas[0].lang.toHuman, ` of sense from "`,
                            lemmas[0].sense, `" to "`, lemmas[1].sense, `"`);
                    }
                    // lemmas[0].sense = lemmas[1].sense;
                }
                break;
            default:
                break;
        }
    }
}

void inferAll(Graph gr)
{
    writeln(`Inferring ...`);
    foreach (pair; gr.db.ixes.lemmasByExpr.byPair)
    {
        // gr.inferSpecializedSenses(pair[0], pair[1]);
        gr.inferPhraseRelations(pair[0], pair[1], [Lang.en, Lang.de, Lang.sv]);
    }
    writeln(`Inference done`);
}

import knet.senses: Sense;

import std.algorithm.comparison: among;

/** Check if $(D rel) propagates Sense(s). */
bool propagatesSense(Rel rel) @safe @nogc  nothrow
{
    with (Rel) return rel.among!(translationOf,
                                 synonymFor,
                                 antonymFor) != 0;
}

/** Check if $(D sense) always infers instanceOf relation. */
bool infersInstanceOf(Sense sense) @safe @nogc  nothrow
{
    with (Sense) return sense.among!(weekday,
                                     month,
                                     dayOfMonth,
                                     year,
                                     season) != 0;
}
