module knet.learning;

import knet.base;

/// Learn Opposites.
void learnOpposites(Graph gr, Lang lang, Origin origin = Origin.manual)
{
    foreach (expr; File(`../knowledge/` ~ lang.to!string ~ `/opposites.txt`).byLine.filter!(a => !a.empty))
    {
        auto split = expr.findSplit(roleSeparatorString); // TODO allow key to be ElementType of Range to prevent array creation here
        const auto first = split[0], second = split[2];
        NWeight weight = 1.0;
        import knet.lookup: uniqueCommonSense;
        const sense = gr.uniqueCommonSense(first, second);
        gr.connect(gr.add(first.idup, lang, sense, origin),
                   Role(Rel.oppositeOf),
                   gr.add(second.idup, lang, sense, origin),
                   origin, weight);
    }
}
