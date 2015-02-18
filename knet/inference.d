module knet.inference;

import knet.base;

void inferSpecializedSenses(Graph graph)
{
    bool show = true;
    foreach (pair; graph.db.ixes.lemmasByExpr.byPair)
    {
        const expr = pair[0];
        auto lemmas = pair[1];

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
}
