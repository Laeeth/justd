module knet.lectures.adverbs;

import std.stdio: writeln;

import knet.base;

void learnAdverbs(Graph graph)
{
    writeln(`Reading Adverbs ...`);
    graph.learnEnglishAdverbs();
    graph.learnSwedishAdverbs();
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/adverb.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `adverb`, Sense.adverb, Sense.noun, 1.0);
}

void learnSwedishAdverbs(Graph graph)
{
    writeln(`Reading Swedish Adverbs ...`);
    enum lang = Lang.sv;

    graph.learnMto1(lang,
                    [`i går`, `i dag,`, `i morgon`,
                     `i kväll`, `i natt`,
                     `i går kväll`, `i går natt`, `i går morgon`
                     `nästa dag`, `nästnästa dag`
                     `nästa vecka`, `nästnästa vecka`
                     `nästa månad`, `nästnästa månad`
                     `nästa år`, `nästnästa år`
                     `nu`, `omedelbart`
                     `sedan`, `senare`, `nyligen`, `just nu`, `på sistone`, `snart`,
                     `redan`, `fortfarande`, `ännu`, `förr`, `förut`],
                    Role(Rel.instanceOf), `time adverb`, Sense.timeAdverb, Sense.nounPhrase, 1.0);

    graph.learnMto1(lang,
                    [`här`, `där`, `där borta`, `överallt`, `var som helst`,
                     `ingenstans`, `hem`, `bort`, `ut`],
                    Role(Rel.instanceOf), `place adverb`, Sense.placeAdverb, Sense.nounPhrase, 1.0);

    graph.learnMto1(lang,
                    [`alltid`, `ofta`, `vanligen`, `ibland`, `emellanåt`, `sällan`, `aldrig`],
                    Role(Rel.instanceOf), `frequency adverb`, Sense.frequencyAdverb, Sense.nounPhrase, 1.0);

    graph.learnMto1(lang,
                    [`ja`, `japp`, `överallt`, `alltid`],
                    Role(Rel.instanceOf), `affirming adverb`, Sense.affirmingAdverb, Sense.nounPhrase, 1.0);

    graph.learnMto1(lang,
                    [`ej`, `inte`, `icke`],
                    Role(Rel.instanceOf), `negating adverb`, Sense.negatingAdverb, Sense.nounPhrase, 1.0);

    graph.learnMto1(Lang.sv,
                    [`emellertid`, `däremot`, `dock`, `likväl`, `ändå`,
                     `trots det`, `trots detta`],
                    Role(Rel.instanceOf), `adverb`, Sense.adverb, Sense.nounPhrase, 1.0);
}

void learnEnglishAdverbs(Graph graph)
{
    writeln(`Reading English Adverbs ...`);

    enum lang = Lang.en;

    graph.learnMto1(lang,
                    [`yesterday`, `today`, `tomorrow`, `tonight`, `last night`, `this morning`,
                     `previous week`, `next week`,
                     `previous year`, `next year`,
                     `now`, `then`, `later`, `right now`, `already`,
                     `recently`, `lately`, `soon`, `immediately`,
                     `still`, `yet`, `ago`],
                    Role(Rel.instanceOf), `time adverb`, Sense.timeAdverb, Sense.nounPhrase, 1.0);

    graph.learnMto1(lang,
                    [`here`, `there`, `over there`, `out there`, `in there`,
                     `everywhere`, `anywhere`, `nowhere`, `home`, `away`, `out`],
                    Role(Rel.instanceOf), `place adverb`, Sense.placeAdverb, Sense.nounPhrase, 1.0);

    graph.learnMto1(lang,
                    [`always`, `frequently`, `usually`, `sometimes`, `occasionally`, `seldom`,
                     `rarely`, `never`],
                    Role(Rel.instanceOf), `frequency adverb`, Sense.frequencyAdverb, Sense.nounPhrase, 1.0);

    graph.learnMto1(lang,
                    [`accordingly`, `additionally`, `again`, `almost`,
                     `although`, `anyway`, `as a result`, `besides`,
                     `certainly`, `comparatively`, `consequently`,
                     `contrarily`, `conversely`, `elsewhere`, `equally`,
                     `eventually`, `finally`, `further`, `furthermore`,
                     `hence`, `henceforth`, `however`, `in addition`,
                     `in comparison`, `in contrast`, `in fact`, `incidentally`,
                     `indeed`, `instead`, `just as`, `likewise`,
                     `meanwhile`, `moreover`, `namely`, `nevertheless`,
                     `next`, `nonetheless`, `notably`, `now`, `otherwise`,
                     `rather`, `similarly`, `still`, `subsequently`, `that is`,
                     `then`, `thereafter`, `therefore`, `thus`,
                     `undoubtedly`, `uniquely`, `on the other hand`, `also`,
                     `for example`, `for instance`, `of course`, `on the contrary`,
                     `so far`, `until now`, `thus` ],
                    Role(Rel.instanceOf), `conjunctive adverb`,
                    Sense.conjunctiveAdverb, Sense.nounPhrase, 1.0);

    graph.learnMto1(lang,
                    [`no`, `not`, `never`, `nowhere`, `none`, `nothing`],
                    Role(Rel.instanceOf), `negating adverb`, Sense.negatingAdverb, Sense.nounPhrase, 1.0);

    graph.learnMto1(lang,
                    [`yes`, `yeah`],
                    Role(Rel.instanceOf), `affirming adverb`, Sense.affirmingAdverb, Sense.nounPhrase, 1.0);
}
