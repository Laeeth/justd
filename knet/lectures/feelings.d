module knet.lectures.feelings;

import knet.base;

void learnFeelings(Graph graph)
{
    graph.learnEnglishFeelings;
    graph.learnSwedishFeelings;
}

/// Learn English Feelings.
void learnEnglishFeelings(Graph graph)
{
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/feeling.txt`).splitter('\n').filter!(word => !word.empty), Role(Rel.instanceOf), `feeling`, Sense.adjective, Sense.nounSingular);
    enum feelings = [`afraid`, `alive`, `angry`, `confused`, `depressed`, `good`, `happy`,
                     `helpless`, `hurt`, `indifferent`, `interested`, `love`,
                     `negative`, `unpleasant`,
                     `positive`, `pleasant`,
                     `open`, `sad`, `strong`];
    foreach (feeling; feelings)
    {
        const path = `../knowledge/en/` ~ feeling ~ `_feeling.txt`;
        import knet.lectures.associations;
        graph.learnAssociations(path, Rel.similarTo, feeling.replace(`_`, ` `) ~ ` feeling`, Sense.adjective, Sense.adjective);
    }
}

/// Learn Swedish Feelings.
void learnSwedishFeelings(Graph graph)
{
    graph.learnMto1(Lang.sv,
                    rdT(`../knowledge/sv/känsla.txt`).splitter('\n').filter!(word => !word.empty),
                    Role(Rel.instanceOf), `känsla`, Sense.noun, Sense.nounSingular);
}
