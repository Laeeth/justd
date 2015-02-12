module knet.lectures.emotions;

import knet.base;

/// Learn Emotions.
void learnEmotions(Graph graph)
{
    enum groups = [`basic`, `positive`, `negative`, `strong`, `medium`, `light`];
    foreach (group; groups)
    {
        graph.learnMto1(Lang.en,
                        rdT(`../knowledge/en/` ~ group ~ `_emotion.txt`).splitter('\n').filter!(word => !word.empty),
                        Role(Rel.instanceOf), group ~ ` emotion`, Sense.unknown, Sense.nounSingular);
    }
}
