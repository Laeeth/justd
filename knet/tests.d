module knet.tests;

import knet.base;
import knet.traversal: bfWalker, nnWalker, nnWalk, WalkStrategy;
import knet.filtering: StepFilter;

import dbg: pln;

void testLinkReusage()
{
    auto gr = new Graph();
    const ndA = gr.add(`Skänninge`, Lang.sv, Sense.city, Origin.manual);
    const ndB = gr.add(`3200`, Lang.sv, Sense.population, Origin.manual);

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
    const ndA = gr.add(`big`, Lang.en, Sense.adjective, Origin.manual);
    const ndB = gr.add(`large`, Lang.en, Sense.adjective, Origin.manual);
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
    const beEn1 = gr.add(`be`.idup, Lang.en, Sense.verb, Origin.manual);
    const beEn2 = gr.add(`be`.idup, Lang.en, Sense.verb, Origin.manual);
    assert(gr[beEn1].lemma.expr.ptr ==
           gr[beEn2].lemma.expr.ptr); // assert clever reuse of already hashed expr
}

// Lemmas with same expr should be reused
void testLemmasExprReusage()
{
    auto gr = new Graph();
    const beEn = gr.add(`be`.idup, Lang.en, Sense.verb, Origin.manual);
    const beSv = gr.add(`be`.idup, Lang.sv, Sense.verb, Origin.manual);
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

    auto ndA = gr.add(`A`, lang, sense, origin);
    auto ndB1 = gr.add(`B1`, lang, sense, origin);
    auto ndB2 = gr.add(`B2`, lang, sense, origin);
    auto ndC = gr.add(`C`, lang, sense, origin);
    auto ndD = gr.add(`D`, lang, sense, origin);
    auto ndE = gr.add(`E`, lang, sense, origin);
    auto ndF = gr.add(`F`, lang, sense, origin);

    gr.connect1toM(ndA, role, [ndB1, ndB2], origin, 0.5, true);
    gr.connectMto1([ndB1, ndB2], role, ndC, origin, 0.5, true);
    gr.connect(ndC, role, ndD, origin, 0.5, true);
    gr.connect(ndA, role, ndD, origin, 0.1, true);
    gr.connect(ndD, role, ndE, origin, 0.1, true);
    gr.connect(ndE, role, ndF, origin, 0.1, true);

    auto walker = gr.bfWalker(ndA);
    if (false)
    {
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
}

// TODO Move somewhere reusable.
bool similar(A, B)(A a, B b) pure
{
    const eps = 5e-3; // epsilon
    return abs(a - b) / (abs(a) + abs(b)) < eps;
}

void testNNWalkABCDE() pure
{
    auto gr = new Graph();
    enum sense = Sense.letter;
    enum lang = Lang.en;
    enum role = Role(Rel.any);
    enum origin = Origin.manual;

    /* Sample Graph:
       A ==W:0.5==> B ==W:0.4==> C ==W:0.4==> D ==W:0.4==> E
       A ==D:0.5==> B ==D:0.6==> C ==W:0.6==> D ==W:0.6==> E
    */

    // nodes
    auto a = gr.add(`A`, lang, sense, origin);
    auto b = gr.add(`B`, lang, sense, origin);
    auto c = gr.add(`C`, lang, sense, origin);
    auto d = gr.add(`D`, lang, sense, origin);
    auto e = gr.add(`E`, lang, sense, origin);

    // links
    Ln ab = gr.connect(a, role, b, origin, 0.5, true);
    Ln bc = gr.connect(b, role, c, origin, 0.4, true);
    Ln cd = gr.connect(c, role, d, origin, 0.4, true);
    Ln de = gr.connect(d, role, e, origin, 0.4, true);

    // perform walk
    auto w = gr.nnWalk!(WalkStrategy.dijkstraMinDistance)(b);
    assert(w.start == b);

    // check distances from b
    assert(similar(w.visitByNd[a][0], 1-0.5));
    assert(similar(w.visitByNd[c][0], 1-0.4));
    assert(similar(w.visitByNd[d][0], 2*(1-0.4)));
    assert(similar(w.visitByNd[e][0], 3*(1-0.4)));
}

void testNNWalker2()
{
    auto gr = new Graph();
    enum sense = Sense.letter;
    enum lang = Lang.en;
    enum role = Role(Rel.any);
    enum origin = Origin.manual;

    auto ndA = gr.add(`A`, lang, sense, origin);
    auto ndB1 = gr.add(`B1`, lang, sense, origin);
    auto ndB2 = gr.add(`B2`, lang, sense, origin);
    auto ndC = gr.add(`C`, lang, sense, origin);
    auto ndD = gr.add(`D`, lang, sense, origin);
    auto ndE = gr.add(`E`, lang, sense, origin);
    auto ndF = gr.add(`F`, lang, sense, origin);

    gr.connect1toM(ndA, role, [ndB1, ndB2], origin, 0.5, true);
    gr.connectMto1([ndB1, ndB2], role, ndC, origin, 0.5, true);
    gr.connect(ndC, role, ndD, origin, 0.5, true);
    gr.connect(ndA, role, ndD, origin, 0.1, true);
    gr.connect(ndD, role, ndE, origin, 0.1, true);
    gr.connect(ndE, role, ndF, origin, 0.1, true);

    auto w = gr.nnWalker!(WalkStrategy.dijkstraMinDistance)(ndA);
    auto wRef = w; // new reference
    auto wCopy = w.save; // copy

    // iterate without side-effects
    foreach (const nd; w) {}
    assert(w == wRef);  // iteration should not change copy
    assert(w == wCopy);  // iteration should not change saved copy
    assert(!w.empty);
    assert(!wRef.empty);
    assert(!wCopy.empty);
    assert(w.visitByNd.length == 1);

    // iterate side-effects
    while (!w.empty) { w.popFront; }
    assert(w.empty);
    assert(w != wRef);
    assert(w != wCopy);

    // print some stuff
    // foreach (const pair; w.visitByNd.byPair)
    // {
    //     write(`Shortest distance from `, gr[ndA].lemma.expr,
    //           ` to `, gr[pair[0]].lemma.expr, ` is `, pair[1][0]);
    //     if (pair[1][1].defined)
    //     {
    //         write(` and came out of `, gr[pair[1][1]].lemma.expr);
    //     }
    //     write(` pair: `, `{`, pair[0], `, `, `{`, pair[1][0], `, `, pair[1][1], `}`, `}`);
    //     writeln();
    // }

    assert(w.visitByNd.length == gr.db.tabs.allNodes.length);
    while (!wRef.empty) { wRef.popFront; } // empty with side effects
    assert(wRef.empty);
    assert(w == wRef);
}

void showWalker(Walker)(Graph gr, ref Walker walker)
{
    writeln("\nWalk with start at \"", gr[walker.start].lemma.expr, "\": ");
    foreach (e; walker.visitByNd.byPair)
    {
        writeln("nd: ", gr[e[0]].lemma.expr,
                ", weight: ", e[1][0]);
    }
}

void testContextOf()
{
    auto gr = new Graph();
    enum sense = Sense.letter;
    enum lang = Lang.en;
    enum role = Role(Rel.any);
    enum origin = Origin.manual;

    auto b1 = gr.add(`B1`, lang, sense, origin);
    auto b2 = gr.add(`B2`, lang, sense, origin);
    auto b3 = gr.add(`B3`, lang, sense, origin);

    auto a  = gr.add(`A`, lang, sense, origin);
    auto c  = gr.add(`C`, lang, sense, origin);

    auto bs = [b1, b2, b3];

    auto aLns = gr.connect1toM(a, role, bs, origin, 0.5, true);
    auto dLns = gr.connect1toM(c, role, bs, origin, 0.6, true);

    import knet.filtering: NodeFilter;
    import knet.association: contextsOf;
    auto result = gr.contextsOf!(WalkStrategy.dijkstraMinDistance)(bs, StepFilter.init, NodeFilter.init, 1);
    auto contexts = result[0];
    auto walkers = result[1];

    // check context
    foreach (const context; contexts)
    {
        const Nd nd = context.key;
        const hit = context.value;
        writeln(" - ", gr[nd].lemma,
                ": visitCount:", hit.visitCount,
                ", goodness:", hit.goodnessSum);
    }
    assert(!contexts.empty);
    assert(contexts[0].key == c);
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

    testNNWalkABCDE;
    testNNWalker2;

    testContextOf;
}
