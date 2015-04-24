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
size_t inferPhraseRelations(Graph gr,
                            Expr expr,
                            Lemmas compoundLemmas,
                            Lang[] langs)
{
    const words = expr.split(` `);
    size_t cnt = 0;
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
                    ++cnt;
                }
                foreach (const nounNd; gr.ndsOf(words[1], [compoundLemma.lang], [Sense.noun], false, false)) // noun:light
                {
                    gr.connect(compoundNd,
                               Role(Rel.isA),
                               nounNd,
                               Origin.inference, 1.0);
                    ++cnt;
                }
            }
            break;
        default:
            break;
    }
    return cnt;
}

size_t inferSpecializedSenses(Graph gr, Expr expr, Lemmas lemmas)
{
    size_t cnt = 0;
    bool show = true;
    import std.algorithm.iteration: groupBy;
    foreach (lemmasOfSameLang; lemmas.groupBy!((lemmaA,
                                                lemmaB) => (lemmaA.lang ==
                                                            lemmaB.lang)))
    {
        import knet.senses: specializes;
        import knet.languages: toHuman;
        switch (lemmasOfSameLang.count)
        {
            case 2:
                const lang = lemmas[0].lang;
                const lemmas_ = lemmasOfSameLang.array;
                if (lemmas[0].sense.specializes(lemmas[1].sense, true, lang, false, true))
                {
                    if (show)
                    {
                        writeln(`Specializing Lemma expr "`, expr,
                                `" in `, lemmas[0].lang.toHuman, ` of sense from "`,
                                lemmas[1].sense, `" to "`, lemmas[0].sense, `"`);
                    }
                    // TODO replace all Nds of lemmas[1] with Nds of lemmas[0]
                    // lemmas[1].sense = lemmas[0].sense;
                    ++cnt;
                }
                else if (lemmas[1].sense.specializes(lemmas[0].sense, true, lang, false, true))
                {
                    if (show)
                    {
                        writeln(`Specializing Lemma expr "`, expr,
                                `" in `, lemmas[0].lang.toHuman, ` of sense from "`,
                                lemmas[0].sense, `" to "`, lemmas[1].sense, `"`);
                    }
                    // TODO replace all Nds of lemmas[0] with Nds of lemmas[1]
                    // lemmas[0].sense = lemmas[1].sense;
                    ++cnt;
                }
                break;
            default:
                break;
        }
    }
    return cnt;
}

void inferAll(Graph gr)
{
    writeln(`Inferring ...`);
    size_t inferSpecializedSensesCount = 0;
    size_t inferPhraseRelationsCount = 0;
    foreach (pair; gr.db.ixes.lemmasByExpr.byPair)
    {
        inferSpecializedSensesCount += gr.inferSpecializedSenses(pair[0], pair[1]);
        inferPhraseRelationsCount += gr.inferPhraseRelations(pair[0], pair[1], [Lang.en, Lang.de, Lang.sv]);
    }
    writeln(`- Inferred Specializations of `, inferSpecializedSensesCount, ` Lemma Senses`);
    writeln(`- Inferred `, inferPhraseRelationsCount, ` Noun/Verb Phrase Relations`);
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
