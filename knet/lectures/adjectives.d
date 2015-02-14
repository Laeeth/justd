module knet.lectures.adjectives;

import std.stdio: writeln;

import knet.base;

void learnAdjectives(Graph graph)
{
    writeln(`Reading Adjectives ...`);
    graph.learnSwedishAdjectives();
    graph.learnEnglishAdjectives();
    graph.learnGermanIrregularAdjectives();
}

/** Learn Swedish Adjectives.
 */
void learnSwedishAdjectives(Graph graph)
{
    enum lang = Lang.sv;
    graph.learnAdjective(lang, `tung`, `tyngre`, `tyngst`);
    graph.learnAdjective(lang, `få`, `färre`, `färst`);
    graph.learnAdjective(lang, `många`, `fler`, `flest`);
    graph.learnAdjective(lang, `bra`, `bättre`, `bäst`);
    graph.learnAdjective(lang, `dålig`, `sämre`, `sämst`);
    graph.learnAdjective(lang, `liten`, `mindre`, `minst`);
    graph.learnAdjective(lang, `gammal`, `äldre`, `äldst`);
    graph.learnAdjective(lang, `hög`, `högre`, `högst`);
    graph.learnAdjective(lang, `låg`, `lägre`, `lägst`);
    graph.learnAdjective(lang, `lång`, `längre`, `längst`);
    graph.learnAdjective(lang, `stor`, `större`, `störst`);
    graph.learnAdjective(lang, `tung`, `tyngre`, `tyngst`);
    graph.learnAdjective(lang, `ung`, `yngre`, `yngst`);
    graph.learnAdjective(lang, `mycket`, `mer`, `mest`);
    graph.learnAdjective(lang, `gärna`, `hellre`, `helst`);
}

/** Learn English Adjectives.
 */
void learnEnglishAdjectives(Graph graph)
{
    graph.learnEnglishIrregularAdjectives();
    const lang = Lang.en;
    graph.connectMto1(graph.store([`ablaze`, `abreast`, `afire`, `afloat`, `afraid`, `aghast`, `aglow`,
                                   `alert`, `alike`, `alive`, `alone`, `aloof`, `ashamed`, `asleep`,
                                   `awake`, `aware`, `fond`, `unaware`],
                                  lang, Sense.adjectivePredicateOnly, Origin.manual),
                      Role(Rel.instanceOf),
                      graph.store(`predicate only adjective`,
                                  lang, Sense.noun, Origin.manual),
                      Origin.manual);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/adjective.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `adjective`, Sense.adjective, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/subjective_adjective.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.hasAttribute), `subjective`, Sense.adjective, Sense.adjective, 1.0);
}

/** Learn English Irregular Adjectives.
 */
void learnEnglishIrregularAdjectives(Graph graph)
{
    enum lang = Lang.en;
    graph.learnAdjective(lang, `good`, `better`, `best`);
    graph.learnAdjective(lang, `well`, `better`, `best`);

    graph.learnAdjective(lang, `bad`, `worse`, `worst`);

    graph.learnAdjective(lang, `little`, `less`, `least`);
    graph.learnAdjective(lang, `little`, `smaller`, `smallest`);

    graph.learnAdjective(lang, `much`, `more`, `most`);
    graph.learnAdjective(lang, `many`, `more`, `most`);

    graph.learnAdjective(lang, `far`, `further`, `furthest`);
    graph.learnAdjective(lang, `far`, `farther`, `farthest`);

    graph.learnAdjective(lang, `big`, `larger`, `largest`);
    graph.learnAdjective(lang, `big`, `bigger`, `biggest`);
    graph.learnAdjective(lang, `large`, `larger`, `largest`);

    graph.learnAdjective(lang, `old`, `older`, `oldest`);
    graph.learnAdjective(lang, `old`, `elder`, `eldest`);
}

/** Learn German Irregular Adjectives.
 */
void learnGermanIrregularAdjectives(Graph graph)
{
    enum lang = Lang.de;

    graph.learnAdjective(lang, `schön`, `schöner`, `schönste`);
    graph.learnAdjective(lang, `wild`, `wilder`, `wildeste`);
    graph.learnAdjective(lang, `groß`, `größer`, `größte`);

    graph.learnAdjective(lang, `gut`, `besser`, `beste`);
    graph.learnAdjective(lang, `viel`, `mehr`, `meiste`);
    graph.learnAdjective(lang, `gern`, `lieber`, `liebste`);
    graph.learnAdjective(lang, `hoch`, `höher`, `höchste`);
    graph.learnAdjective(lang, `wenig`, `weniger`, `wenigste`);
    graph.learnAdjective(lang, `wenig`, `minder`, `mindeste`);
    graph.learnAdjective(lang, `nahe`, `näher`, `nähchste`);
}
