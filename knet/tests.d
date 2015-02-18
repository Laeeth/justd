module knet.tests;

import knet.base;

void testLinkReusage()
{
    auto gr = new Graph();
    const ndA = gr.store(`Skänninge`, Lang.sv, Sense.city, Origin.manual);
    const ndB = gr.store(`3200`, Lang.sv, Sense.population, Origin.manual);

    const ln1 = gr.connect(ndA, Role(Rel.hasAttribute), ndB, Origin.manual, 1.0, true);

    const ln2 = gr.connect(ndA, Role(Rel.hasAttribute), ndB, Origin.manual, 1.0, true);
    assert(ln1 == ln2);

    const ln3 = gr.connect(ndB, Role(Rel.hasAttribute, true), ndA, Origin.manual, 1.0, true);
    assert(ln1 == ln3);

    // TODO fix this!
    // const ln4 = gr.connect(ndB, Role(Rel.hasAttribute), ndA, Origin.manual, 1.0, true);
    // assert(ln1 != ln4);
}

void testSymmetricLinkReusage()
{
    auto gr = new Graph();
    const ndA = gr.store(`big`, Lang.en, Sense.adjective, Origin.manual);
    const ndB = gr.store(`large`, Lang.en, Sense.adjective, Origin.manual);
    const ln1 = gr.connect(ndA, Role(Rel.synonymFor),
                           ndB, Origin.manual, 1.0, true);
    // reversion order should return same link because synonymFor is symmetric
    const ln2 = gr.connect(ndB, Role(Rel.synonymFor),
                           ndA, Origin.manual, 1.0, true);
    assert(ln1 == ln2);
}

void testLemmasWithSameExprReusage()
{
    auto gr = new Graph();
    const beEn1 = gr.store(`be`.idup, Lang.en, Sense.verb, Origin.manual);
    const beEn2 = gr.store(`be`.idup, Lang.en, Sense.verb, Origin.manual);
    assert(gr[beEn1].lemma.expr.ptr ==
           gr[beEn2].lemma.expr.ptr); // assert clever reuse of already hashed expr
}

// Lemmas with same expr should be reused
void testLemmasExprReusage()
{
    auto gr = new Graph();
    const beEn = gr.store(`be`.idup, Lang.en, Sense.verb, Origin.manual);
    const beSv = gr.store(`be`.idup, Lang.sv, Sense.verb, Origin.manual);
    assert(gr[beEn].lemma.expr.ptr ==
           gr[beSv].lemma.expr.ptr); // assert clever reuse of already hashed expr
}

void testBFWalker()
{
    auto gr = new Graph();
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

    import knet.traversal: bfWalker;
    auto walker = gr.bfWalker(ndA);
    foreach (const nds; walker) // for each `connectivity expansion`
    {
        foreach (const nd; nds)
        {
            writeln(gr[nd]);
        }
    }

    writeln(`Connectiveness with ndA `, walker.connectivenessByNd[ndA]);
    writeln(`Connectiveness with ndB1 `, walker.connectivenessByNd[ndB1]);
    writeln(`Connectiveness with ndB2 `, walker.connectivenessByNd[ndB2]);
    writeln(`Connectiveness with ndC `, walker.connectivenessByNd[ndC]);
}

void testDijkstraWalker()
{
    auto gr = new Graph();
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

    import knet.traversal: dijkstraWalker;
    auto w = gr.dijkstraWalker(ndA);
    auto wRef = w; // new reference
    auto wCopy = w.save; // copy

    // iterate without side-effects
    foreach (const nd; w)
    {
        writeln(gr[nd]);
    }
    assert(w == wRef);  // iteration should not change copy
    assert(w == wCopy);  // iteration should not change saved copy
    assert(!w.empty);
    assert(!wRef.empty);
    assert(!wCopy.empty);
    assert(w.distMap.length == 1);

    // iterate side-effects
    while (!w.empty) { w.popFront; }
    assert(w.empty);
    assert(w != wRef);
    assert(w != wCopy);
    foreach (const pair; w.distMap.byPair)
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
    assert(w.distMap.length == gr.db.tabs.allNodes.length);
    while (!wRef.empty) { wRef.popFront; } // empty with side effects
    assert(wRef.empty);
    assert(w == wRef);
}

void testContextOf()
{
    auto gr = new Graph();
    enum sense = Sense.letter;
    enum lang = Lang.en;
    enum role = Role(Rel.any);
    enum origin = Origin.manual;

    auto ndA  = gr.store(`A`, lang, sense, origin);

    auto ndB1 = gr.store(`B1`, lang, sense, origin);
    auto ndB2 = gr.store(`B2`, lang, sense, origin);
    auto ndB3 = gr.store(`B3`, lang, sense, origin);

    gr.connect1toM(ndA, role, [ndB1, ndB2, ndB3], origin, 0.5, true);

    auto ndsB = [ndB1, ndB2, ndB3];
    import knet.association: contextOf;
    const ndContext = gr.contextOf(ndsB);
}

/** Run Unittestsx.
 */
void testAll()
{
    assert(Nd.init == Nd.asUndefined);
    assert(Ln.init == Ln.asUndefined);

    testLemmasWithSameExprReusage;
    testLemmasExprReusage;

    testLinkReusage;
    testSymmetricLinkReusage;

    testBFWalker;
    testDijkstraWalker;

    testContextOf;
}
