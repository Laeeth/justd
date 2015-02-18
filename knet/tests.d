module knet.tests;

import knet.base;

/** Run Unittestsx.
 */
void testAll(Graph gr)
{
    {
        enum sense = Sense.letter;
        enum lang = Lang.en;
        enum role = Role(Rel.any);
        enum origin = Origin.manual;

        auto ndA = gr.store(`A`, lang, sense, origin);
        auto ndB1 = gr.store(`B1`, lang, sense, origin);
        auto ndB2 = gr.store(`B2`, lang, sense, origin);
        auto ndC = gr.store(`C`, lang, sense, origin);
        auto ndD = gr.store(`D`, lang, sense, origin);
        auto ndE = gr.store(`E`, lang, sense, origin);
        auto ndF = gr.store(`F`, lang, sense, origin);

        gr.connect1toM(ndA, role, [ndB1, ndB2], origin, 0.5, true);
        gr.connectMto1([ndB1, ndB2], role, ndC, origin, 0.5, true);
        gr.connect(ndC, role, ndD, origin, 0.5, true);
        gr.connect(ndA, role, ndD, origin, 0.1, true);
        gr.connect(ndD, role, ndE, origin, 0.1, true);
        gr.connect(ndE, role, ndF, origin, 0.1, true);

        import knet.traversal: bfWalk;
        auto bw = gr.bfWalk(ndA);
        foreach (const nds; bw) // for each `connectivity expansion`
        {
            foreach (const nd; nds)
            {
                writeln(gr[nd]);
            }
        }

        writeln(`Connectiveness with ndA `, bw.connectivenessByNd[ndA]);
        writeln(`Connectiveness with ndB1 `, bw.connectivenessByNd[ndB1]);
        writeln(`Connectiveness with ndB2 `, bw.connectivenessByNd[ndB2]);
        writeln(`Connectiveness with ndC `, bw.connectivenessByNd[ndC]);

        import knet.traversal: dijkstraWalk;
        auto dw = gr.dijkstraWalk(ndA);
        foreach (const nd; dw)
        {
            writeln(gr[nd]);
        }

        foreach (const pair; dw.mapByNd.byPair)
        {
            write(`Shortest distance from `, gr[ndA].lemma.expr,
                  ` to `, gr[pair[0]].lemma.expr, ` is `, pair[1][0]);
            if (pair[1][1].defined)
            {
                write(` and came out of `, gr[pair[1][1]].lemma.expr);
            }
            write(` pair: `, `{`, pair[0], `, `, `{`, pair[1][0], `, `, pair[1][1], `}`, `}`);
            writeln();
        }
    }

    // link should be reused
    {
        const ndA = gr.store(`Skänninge`, Lang.sv, Sense.city, Origin.manual);
        const ndB = gr.store(`3200`, Lang.sv, Sense.population, Origin.manual);
        const ln1 = gr.connect(ndA, Role(Rel.hasAttribute), ndB, Origin.manual, 1.0, true);
        const ln2 = gr.connect(ndA, Role(Rel.hasAttribute), ndB, Origin.manual, 1.0, true);
        assert(ln1 == ln2);
    }

    // symmetric link should be reused in reverse order
    {
        const ndA = gr.store(`big`, Lang.en, Sense.adjective, Origin.manual);
        const ndB = gr.store(`large`, Lang.en, Sense.adjective, Origin.manual);
        const ln1 = gr.connect(ndA, Role(Rel.synonymFor),
                               ndB, Origin.manual, 1.0, true);
        // reversion order should return same link because synonymFor is symmetric
        const ln2 = gr.connect(ndB, Role(Rel.synonymFor),
                               ndA, Origin.manual, 1.0, true);
        assert(ln1 == ln2);
    }

    // Lemmas with same expr should be reused
    const beEn1 = gr.store(`be`.idup, Lang.en, Sense.verb, Origin.manual);
    const beEn2 = gr.store(`be`.idup, Lang.en, Sense.verb, Origin.manual);
    assert(gr[beEn1].lemma.expr.ptr ==
           gr[beEn2].lemma.expr.ptr); // assert clever reuse of already hashed expr

    // Lemmas with same expr should be reused
    const beEn = gr.store(`be`.idup, Lang.en, Sense.verb, Origin.manual);
    const beSv = gr.store(`be`.idup, Lang.sv, Sense.verb, Origin.manual);
    assert(gr[beEn].lemma.expr.ptr ==
           gr[beSv].lemma.expr.ptr); // assert clever reuse of already hashed expr
}
