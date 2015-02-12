module knet.lectures.grammar;

import knet.base;

/** Learn Swedish Grammar.
 */
void learnSwedishGrammar(Graph graph)
{
    enum lang = Lang.sv;
    graph.connectMto1(graph.store([`grundform`, `genitiv`], lang, Sense.noun, Origin.manual),
                      Role(Rel.instanceOf),
                      graph.store(`kasus`, lang, Sense.noun, Origin.manual),
                      Origin.manual);
    graph.connectMto1(graph.store([`reale`, `neutrum`], lang, Sense.noun, Origin.manual),
                      Role(Rel.instanceOf),
                      graph.store(`genus`, lang, Sense.noun, Origin.manual),
                      Origin.manual);
}
