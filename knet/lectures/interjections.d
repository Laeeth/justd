module knet.lectures.interjections;

import knet.base;
import knet.separators;

void learnInterjections(Graph graph)
{
    writeln(`Reading Interjections ...`);

    graph.learnMto1(Lang.en,
                    rdT(`../knowledge/en/interjection.txt`).splitter('\n').filter!(word => !word.empty),
                    Role(Rel.instanceOf), `interjection`, Sense.interjection, Sense.nounSingular, 1.0);
}
