module knet.lectures.time;

import knet.base;

void learnTime(Graph graph)
{
    writeln(`Reading Time ...`);

    graph.learnMto1(Lang.en, [`monday`, `tuesday`, `wednesday`, `thursday`, `friday`, `saturday`, `sunday`],    Role(Rel.instanceOf), `weekday`, Sense.weekday, Sense.nounSingular, 1.0);
    graph.learnMto1(Lang.de, [`montag`, `dienstag`, `mittwoch`, `donnerstag`, `freitag`, `samstag`, `sonntag`], Role(Rel.instanceOf), `weekday`, Sense.weekday, Sense.nounSingular, 1.0);
    graph.learnMto1(Lang.sv, [`montag`, `dienstag`, `mittwoch`, `donnerstag`, `freitag`, `samstag`, `sonntag`], Role(Rel.instanceOf), `weekday`, Sense.weekday, Sense.nounSingular, 1.0);

    graph.learnMto1(Lang.en, [`january`, `february`, `mars`, `april`, `may`, `june`, `july`, `august`, `september`, `oktober`, `november`, `december`], Role(Rel.instanceOf), `month`, Sense.month, Sense.nounSingular, 1.0);
    graph.learnMto1(Lang.de, [`Januar`, `Februar`, `März`, `April`, `Mai`, `Juni`, `Juli`, `August`, `September`, `Oktober`, `November`, `Dezember`], Role(Rel.instanceOf), `month`, Sense.month, Sense.nounSingular, 1.0);
    graph.learnMto1(Lang.sv, [`januari`, `februari`, `mars`, `april`, `maj`, `juni`, `juli`, `augusti`, `september`, `oktober`, `november`, `december`], Role(Rel.instanceOf), `month`, Sense.month, Sense.nounSingular, 1.0);

    graph.learnMto1(Lang.en, [`time period`], Role(Rel.isA), `noun`, Sense.noun, Sense.nounSingular, 1.0);
    graph.learnMto1(Lang.en, [`month`], Role(Rel.isA), `time period`, Sense.noun, Sense.nounSingular, 1.0);
}
