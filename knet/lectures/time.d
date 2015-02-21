module knet.lectures.time;

import knet.base;

void learnTime(Graph graph)
{
    writeln(`Reading Time ...`);

    graph.learnMto1(Lang.en, [`Monday`, `Tuesday`, `Wednesday`, `Thursday`, `Friday`, `Saturday`, `Sunday`],    Role(Rel.instanceOf), `weekday`, Sense.weekday, Sense.nounSingular, 1.0);
    graph.learnMto1(Lang.de, [`Montag`, `Dienstag`, `Mittwoch`, `Donnerstag`, `Freitag`, `Samstag`, `Sonntag`], Role(Rel.instanceOf), `weekday`, Sense.weekday, Sense.nounSingular, 1.0);
    graph.learnMto1(Lang.sv, [`måndag`, `tisdag`, `onsdag`, `torsdag`, `fredag`, `lördag`, `söndag`], Role(Rel.instanceOf), `weekday`, Sense.weekday, Sense.nounSingular, 1.0);

    graph.learnMto1(Lang.en, [`January`, `February`, `Mars`, `April`, `May`, `June`, `July`, `August`, `September`, `Oktober`, `November`, `December`], Role(Rel.instanceOf), `month`, Sense.month, Sense.nounSingular, 1.0);
    graph.learnMto1(Lang.de, [`Januar`, `Februar`, `März`, `April`, `Mai`, `Juni`, `Juli`, `August`, `September`, `Oktober`, `November`, `Dezember`], Role(Rel.instanceOf), `month`, Sense.month, Sense.nounSingular, 1.0);
    graph.learnMto1(Lang.sv, [`januari`, `februari`, `mars`, `april`, `maj`, `juni`, `juli`, `augusti`, `september`, `oktober`, `november`, `december`], Role(Rel.instanceOf), `month`, Sense.month, Sense.nounSingular, 1.0);

    graph.learnMto1(Lang.en, [`time period`], Role(Rel.isA), `noun`, Sense.noun, Sense.nounSingular, 1.0);
    graph.learnMto1(Lang.en, [`month`], Role(Rel.isA), `time period`, Sense.noun, Sense.nounSingular, 1.0);
}
