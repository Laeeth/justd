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

import knet.senses: Sense;

/** Check if $(D rel) infers Senses. */
Sense infersSense(Rel rel) @safe @nogc pure nothrow
{
    switch (rel) with (Rel) with (Sense)
    {
        case atLocation: return noun;
        default: return Sense.unknown;
    }
}

import std.algorithm.comparison: among;

/** Check if $(D rel) propagates Sense(s). */
bool propagatesSense(Rel rel) @safe @nogc pure nothrow
{
    with (Rel) return rel.among!(translationOf,
                                 synonymFor,
                                 antonymFor) != 0;
}

/** Check if $(D sense) always infers instanceOf relation. */
bool infersInstanceOf(Sense sense) @safe @nogc pure nothrow
{
    with (Sense) return sense.among!(weekday,
                                     month,
                                     dayOfMonth,
                                     year,
                                     season) != 0;
}
