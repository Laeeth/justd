module knet.lectures.time;

import knet.base;

void learnTime(Graph gr)
{
    writeln(`Reading Time ...`);

    enum origin = Origin.manual;

    gr.learnMto1(Lang.en, [`time period`], Role(Rel.isA), `noun`, Sense.noun, Sense.nounSingular, 1.0);
    gr.learnMto1(Lang.en, [`month`], Role(Rel.isA), `time period`, Sense.noun, Sense.nounSingular, 1.0);

    const weekday = gr.add("weekday", Lang.en, Sense.timePeriod, origin);
    const month = gr.add("month", Lang.en, Sense.timePeriod, origin);

    gr.learnMto1(Lang.en, [`Monday`, `Tuesday`, `Wednesday`, `Thursday`, `Friday`, `Saturday`, `Sunday`],    Sense.weekday, Role(Rel.instanceOf), weekday, 1.0, origin);
    // TODO weekday must be in Swedish
    gr.learnMto1(Lang.de, [`Montag`, `Dienstag`, `Mittwoch`, `Donnerstag`, `Freitag`, `Samstag`, `Sonntag`], Sense.weekday, Role(Rel.instanceOf), weekday, 1.0, origin);
    gr.learnMto1(Lang.sv, [`måndag`, `tisdag`, `onsdag`, `torsdag`, `fredag`, `lördag`, `söndag`], Sense.weekday, Role(Rel.instanceOf), weekday, 1.0, origin);

    gr.learnMto1(Lang.en, [`January`, `February`, `Mars`, `April`, `May`, `June`, `July`, `August`, `September`, `Oktober`, `November`, `December`], Sense.month, Role(Rel.instanceOf), month, 1.0, origin);
    gr.learnMto1(Lang.de, [`Januar`, `Februar`, `März`, `April`, `Mai`, `Juni`, `Juli`, `August`, `September`, `Oktober`, `November`, `Dezember`], Sense.month, Role(Rel.instanceOf), month, 1.0, origin);
    gr.learnMto1(Lang.sv, [`januari`, `februari`, `mars`, `april`, `maj`, `juni`, `juli`, `augusti`, `september`, `oktober`, `november`, `december`], Sense.month, Role(Rel.instanceOf), month, 1.0, origin);
}
