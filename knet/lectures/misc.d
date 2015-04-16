module knet.lectures.misc;

import knet.base;

void learnEnglishMisc(Graph graph)
{
    graph.connectMto1(graph.add([`preserve food`,
                                 `cure illness`,
                                 `augment cosmetics`],
                                Lang.en, Sense.noun, Origin.manual),
                      Role(Rel.uses),
                      graph.add(`herb`, Lang.en, Sense.noun, Origin.manual),
                      Origin.manual, 1.0);

    graph.connectMto1(graph.add([`enrich taste of food`,
                                   `improve taste of food`,
                                   `increase taste of food`],
                                  Lang.en, Sense.noun, Origin.manual),
                      Role(Rel.uses),
                      graph.add(`spice`, Lang.en, Sense.noun, Origin.manual),
                      Origin.manual, 1.0);

    graph.connect1toM(graph.add(`herb`, Lang.en, Sense.noun, Origin.manual),
                      Role(Rel.madeOf),
                      graph.add([`leaf`, `plant`], Lang.en, Sense.noun, Origin.manual),
                      Origin.manual, 1.0);

    graph.connect1toM(graph.add(`spice`, Lang.en, Sense.noun, Origin.manual),
                      Role(Rel.madeOf),
                      graph.add([`root`, `plant`], Lang.en, Sense.noun, Origin.manual),
                      Origin.manual, 1.0);
}
