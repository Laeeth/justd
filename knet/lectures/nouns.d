module knet.lectures.nouns;

import std.stdio: writeln;

import knet.base;

void learnNouns(Graph graph)
{
    writeln(`Reading Nouns ...`);

    const origin = Origin.manual;

    graph.connect(graph.add(`male`, Lang.en, Sense.noun, origin), Role(Rel.hasAttribute),
                  graph.add(`masculine`, Lang.en, Sense.adjective, origin), origin, 1.0);
    graph.connect(graph.add(`female`, Lang.en, Sense.noun, origin), Role(Rel.hasAttribute),
                  graph.add(`feminine`, Lang.en, Sense.adjective, origin), origin, 1.0);

    graph.learnEnglishNouns();
    graph.learnSwedishNouns();
}

void learnEnglishNouns(Graph graph)
{
    writeln(`Reading English Nouns ...`);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/collective_noun.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `collective noun`, Sense.nounCollective, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/noun.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `noun`, Sense.noun, Sense.noun, 1.0);
}

void learnSwedishNouns(Graph graph)
{
    writeln(`Reading Swedish Nouns ...`);
    graph.learnMto1(Lang.sv, rdT(`../knowledge/sv/collective_noun.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `collective noun`, Sense.nounCollective, Sense.noun, 1.0);
}
