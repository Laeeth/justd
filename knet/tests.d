module knet.tests;

import knet.base;
import knet.iteration;

/** Run unittests.
 */
void testAll(Graph graph)
{
    {
        enum sense = Sense.letter;
        enum lang = Lang.en;
        enum role = Role(Rel.any);
        enum origin = Origin.manual;

        const ndA = graph.store(`A`, lang, sense, origin);
        const ndB1 = graph.store(`B1`, lang, sense, origin);
        const ndB2 = graph.store(`B2`, lang, sense, origin);
        const ndC = graph.store(`C`, lang, sense, origin);

        const lnAB1 = graph.connect(ndA, role, ndB1, origin, 0.5, true);
        const lnAB2 = graph.connect(ndA, role, ndB2, origin, 0.5, true);
        const lnB1C = graph.connect(ndB1, role, ndC, origin, 0.5, true);
        const lnB2C = graph.connect(ndB2, role, ndC, origin, 0.5, true);

        foreach (const nds; graph.walk(ndA))
        {
            foreach (const nd; nds)
            {
                writeln(graph[nd]);
            }
        }
    }

    // link should be reused
    {
        const ndA = graph.store(`Skänninge`, Lang.sv, Sense.city, Origin.manual);
        const ndB = graph.store(`3200`, Lang.sv, Sense.population, Origin.manual);
        const ln1 = graph.connect(ndA, Role(Rel.hasAttribute), ndB, Origin.manual, 1.0, true);
        const ln2 = graph.connect(ndA, Role(Rel.hasAttribute), ndB, Origin.manual, 1.0, true);
        assert(ln1 == ln2);
    }

    // symmetric link should be reused in reverse order
    {
        const ndA = graph.store(`big`, Lang.en, Sense.adjective, Origin.manual);
        const ndB = graph.store(`large`, Lang.en, Sense.adjective, Origin.manual);
        const ln1 = graph.connect(ndA, Role(Rel.synonymFor),
                            ndB, Origin.manual, 1.0, true);
        // reversion order should return same link because synonymFor is symmetric
        const ln2 = graph.connect(ndB, Role(Rel.synonymFor),
                            ndA, Origin.manual, 1.0, true);
        assert(ln1 == ln2);
    }

    // Lemmas with same expr should be reused
    const beEn1 = graph.store(`be`.idup, Lang.en, Sense.verb, Origin.manual);
    const beEn2 = graph.store(`be`.idup, Lang.en, Sense.verb, Origin.manual);
    assert(graph[beEn1].lemma.expr.ptr ==
           graph[beEn2].lemma.expr.ptr); // assert clever reuse of already hashed expr

    // Lemmas with same expr should be reused
    const beEn = graph.store(`be`.idup, Lang.en, Sense.verb, Origin.manual);
    const beSv = graph.store(`be`.idup, Lang.sv, Sense.verb, Origin.manual);
    assert(graph[beEn].lemma.expr.ptr ==
           graph[beSv].lemma.expr.ptr); // assert clever reuse of already hashed expr
}
