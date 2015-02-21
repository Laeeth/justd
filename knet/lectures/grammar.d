module knet.lectures.grammar;

import knet.base;

/** Learn Swedish Grammar.
 */
void learnSwedishGrammar(Graph graph)
{
    enum lang = Lang.sv;
    graph.connectMto1(graph.add([`grundform`, `genitiv`], lang, Sense.noun, Origin.manual),
                      Role(Rel.instanceOf),
                      graph.add(`kasus`, lang, Sense.noun, Origin.manual),
                      Origin.manual);
    graph.connectMto1(graph.add([`reale`, `neutrum`], lang, Sense.noun, Origin.manual),
                      Role(Rel.instanceOf),
                      graph.add(`genus`, lang, Sense.noun, Origin.manual),
                      Origin.manual);
}
