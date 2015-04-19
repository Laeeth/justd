module knet.lectures.time;

import knet.base;

void learnTime(Graph graph)
{
    writeln(`Reading Time ...`);

    // TODO Reuse Node(nounSingular:weekday@en)
    graph.learnMto1MultiLingual(Lang.en, [`Monday`, `Tuesday`, `Wednesday`, `Thursday`, `Friday`, `Saturday`, `Sunday`],    Role(Rel.instanceOf), `weekday`, Sense.weekday, Lang.en, Sense.nounSingular, 1.0);
    // TODO weekday must be in Swedish
    graph.learnMto1MultiLingual(Lang.de, [`Montag`, `Dienstag`, `Mittwoch`, `Donnerstag`, `Freitag`, `Samstag`, `Sonntag`], Role(Rel.instanceOf), `weekday`, Sense.weekday, Lang.en, Sense.nounSingular, 1.0);
    graph.learnMto1MultiLingual(Lang.sv, [`måndag`, `tisdag`, `onsdag`, `torsdag`, `fredag`, `lördag`, `söndag`], Role(Rel.instanceOf), `weekday`, Sense.weekday, Lang.en, Sense.nounSingular, 1.0);

    // TODO Reuse Node(nounSingular:month@en)
    graph.learnMto1MultiLingual(Lang.en, [`January`, `February`, `Mars`, `April`, `May`, `June`, `July`, `August`, `September`, `Oktober`, `November`, `December`], Role(Rel.instanceOf), `month`, Sense.month, Lang.en, Sense.nounSingular, 1.0);
    graph.learnMto1MultiLingual(Lang.de, [`Januar`, `Februar`, `März`, `April`, `Mai`, `Juni`, `Juli`, `August`, `September`, `Oktober`, `November`, `Dezember`], Role(Rel.instanceOf), `month`, Sense.month, Lang.en, Sense.nounSingular, 1.0);
    graph.learnMto1MultiLingual(Lang.sv, [`januari`, `februari`, `mars`, `april`, `maj`, `juni`, `juli`, `augusti`, `september`, `oktober`, `november`, `december`], Role(Rel.instanceOf), `month`, Sense.month, Lang.en, Sense.nounSingular, 1.0);

    graph.learnMto1MultiLingual(Lang.en, [`time period`], Role(Rel.isA), `noun`, Sense.noun, Lang.en, Sense.nounSingular, 1.0);
    graph.learnMto1MultiLingual(Lang.en, [`month`], Role(Rel.isA), `time period`, Sense.noun, Lang.en, Sense.nounSingular, 1.0);
}
