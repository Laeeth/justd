module knet.lectures.names;

import knet.base;

void learnNames(Graph graph)
{
    writeln(`Reading Names ...`);

    // Surnames
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/surname.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `surname`, Sense.surname, Sense.nounSingular, 1.0);
    graph.learnMto1(Lang.sv, rdT(`../knowledge/sv/surname.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `surname`, Sense.surname, Sense.nounSingular, 1.0);
}
