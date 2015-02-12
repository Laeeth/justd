module knet.lectures.physics;

import knet.base;

/** Learn Math.
 */
void learnPhysics(Graph graph)
{
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/si_base_unit_name.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `SI base unit name noun`, Sense.baseSIUnit, Sense.noun, 1.0);
    // TODO Name Symbol, Quantity, In SI units, In Si base units
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/si_derived_unit_name.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `SI derived unit name noun`, Sense.derivedSIUnit, Sense.noun, 1.0);
}

/// Learn Chemical Elements.
void learnChemicalElements(Graph graph,
                           Lang lang = Lang.en, Origin origin = Origin.manual)
{
    foreach (expr; File(`../knowledge/en/chemical_elements.txt`).byLine.filter!(a => !a.empty))
    {
        auto split = expr.findSplit([roleSeparator]); // TODO allow key to be ElementType of Range to prevent array creation here
        const name = split[0], sym = split[2];
        NWeight weight = 1.0;

        graph.connect(graph.store(name.idup, lang, Sense.nounUncountable, origin),
                      Role(Rel.instanceOf),
                      graph.store(`chemical element`, lang, Sense.nounSingular, origin),
                      origin, weight);

        graph.connect(graph.store(sym.idup, lang, Sense.noun, origin),
                      Role(Rel.symbolFor),
                      graph.store(name.idup, lang, Sense.noun, origin),
                      origin, weight);
    }
}
