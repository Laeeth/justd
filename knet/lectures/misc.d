module knet.lectures.misc;

import knet.base;

void learnEnglishMisc(Graph graph)
{
    graph.connectMto1(graph.store([`preserve food`,
                                   `cure illness`,
                                   `augment cosmetics`],
                                  Lang.en, Sense.noun, Origin.manual),
                      Role(Rel.uses),
                      graph.store(`herb`, Lang.en, Sense.noun, Origin.manual),
                      Origin.manual, 1.0);

    graph.connectMto1(graph.store([`enrich taste of food`,
                                   `improve taste of food`,
                                   `increase taste of food`],
                                  Lang.en, Sense.noun, Origin.manual),
                      Role(Rel.uses),
                      graph.store(`spice`, Lang.en, Sense.noun, Origin.manual),
                      Origin.manual, 1.0);

    graph.connect1toM(graph.store(`herb`, Lang.en, Sense.noun, Origin.manual),
                      Role(Rel.madeOf),
                      graph.store([`leaf`, `plant`], Lang.en, Sense.noun, Origin.manual),
                      Origin.manual, 1.0);

    graph.connect1toM(graph.store(`spice`, Lang.en, Sense.noun, Origin.manual),
                      Role(Rel.madeOf),
                      graph.store([`root`, `plant`], Lang.en, Sense.noun, Origin.manual),
                      Origin.manual, 1.0);
}