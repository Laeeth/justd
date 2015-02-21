module knet.lectures.conjunctions;

import knet.base;
import knet.separators;

void learnConjunctions(Graph graph)
{
    writeln(`Reading Conjunctions ...`);

    // TODO merge with conjunctions?
    // TODO categorize like http://www.grammarbank.com/connectives-list.html
    enum connectives = [`the`, `of`, `and`, `to`, `a`, `in`, `that`, `is`,
                        `was`, `he`, `for`, `it`, `with`, `as`, `his`,
                        `on`, `be`, `at`, `by`, `i`, `this`, `had`, `not`,
                        `are`, `but`, `from`, `or`, `have`, `an`, `they`,
                        `which`, `one`, `you`, `were`, `her`, `all`, `she`,
                        `there`, `would`, `their`, `we him`, `been`, `has`,
                        `when`, `who`, `will`, `more`, `no`, `if`, `out`,
                        `so`, `said`, `what`, `up`, `its`, `about`, `into`,
                        `than them`, `can`, `only`, `other`, `new`, `some`,
                        `could`, `time`, `these`, `two`, `may`, `then`,
                        `do`, `first`, `any`, `my`, `now`, `such`, `like`,
                        `our`, `over`, `man`, `me`, `even`, `most`, `made`,
                        `after`, `also`, `did`, `many`, `before`, `must`,
                        `through back`, `years`, `where`, `much`, `your`,
                        `way`, `well`, `down`, `should`, `because`, `each`,
                        `just`, `those`, `people mr`, `how`, `too`,
                        `little`, `state`, `good`, `very`, `make`, `world`,
                        `still`, `own`, `see`, `men`, `work`, `long`, `get`,
                        `here`, `between`, `both`, `life`, `being`, `under`,
                        `never`, `day`, `same`, `another`, `know`, `while`,
                        `last`, `might us`, `great`, `old`, `year`, `off`,
                        `come`, `since`, `against`, `go`, `came`, `right`,
                        `used`, `take`, `three`];

    // Coordinating Conjunction
    graph.connect(graph.add(`coordinating conjunction`, Lang.en, Sense.nounPhrase, Origin.manual),
                  Role(Rel.uses),
                  graph.add(`graph.connect independent sentence parts`, Lang.en, Sense.unknown, Origin.manual),
                  Origin.manual, 1.0);
    graph.learnMto1(Lang.en, [`and`, `or`, `but`, `nor`, `so`, `for`, `yet`],
                    Role(Rel.instanceOf), `coordinating conjunction`, Sense.conjunctionCoordinating, Sense.nounPhrase, 1.0);
    graph.learnMto1(Lang.sv, [`och`, `eller`, `men`, `så`, `för`, `ännu`],
                    Role(Rel.instanceOf), `coordinating conjunction`, Sense.conjunctionCoordinating, Sense.nounPhrase, 1.0);
    graph.learnMto1(Lang.en, [`that`],
                    Role(Rel.instanceOf), `coordinating conjunction`, Sense.conjunctionSubordinating, Sense.nounPhrase, 1.0);
    graph.learnMto1(Lang.en, [`though`, `although`, `eventhough`, `even though`, `while`],
                    Role(Rel.instanceOf), `coordinating concession conjunction`, Sense.conjunctionSubordinatingConcession, Sense.nounPhrase, 1.0);
    graph.learnMto1(Lang.en, [`if`, `only if`, `unless`, `until`, `provided that`, `assuming that`, `even if`, `in case`, `in case that`, `lest`],
                    Role(Rel.instanceOf), `coordinating condition conjunction`, Sense.conjunctionSubordinatingCondition, Sense.nounPhrase, 1.0);
    graph.learnMto1(Lang.en, [`than`, `rather than`, `whether`, `as much as`, `whereas`],
                    Role(Rel.instanceOf), `coordinating comparison conjunction`, Sense.conjunctionSubordinatingComparison, Sense.nounPhrase, 1.0);
    graph.learnMto1(Lang.en, [`after`, `as long as`, `as soon as`, `before`, `by the time`, `now that`, `once`, `since`, `till`, `until`, `when`, `whenever`, `while`],
                    Role(Rel.instanceOf), `coordinating time conjunction`, Sense.conjunctionSubordinatingTime, Sense.nounPhrase, 1.0);
    graph.learnMto1(Lang.en, [`because`, `since`, `so that`, `in order`, `in order that`, `why`],
                    Role(Rel.instanceOf), `coordinating reason conjunction`, Sense.conjunctionSubordinatingReason, Sense.nounPhrase, 1.0);
    graph.learnMto1(Lang.en, [`how`, `as though`, `as if`],
                    Role(Rel.instanceOf), `coordinating manner conjunction`, Sense.conjunctionSubordinatingManner, Sense.nounPhrase, 1.0);
    graph.learnMto1(Lang.en, [`where`, `wherever`],
                    Role(Rel.instanceOf), `coordinating place conjunction`, Sense.conjunctionSubordinatingPlace, Sense.nounPhrase, 1.0);
    graph.learnMto1(Lang.en, [`as {*} as`,
                              `just as {*} so`,
                              `both {*} and`,
                              `hardly {*} when`,
                              `scarcely {*} when`,
                              `either {*} or`,
                              `neither {*} nor`,
                              `if {*} then`,
                              `not {*} but`,
                              `what with {*} and`,
                              `whether {*} or`,
                              `not only {*} but also`,
                              `no sooner {*} than`,
                              `rather {*} than`],
                    Role(Rel.instanceOf), `correlative conjunction`, Sense.conjunctionCorrelative, Sense.nounPhrase, 1.0);

    // Subordinating Conjunction
    graph.connect(graph.add(`subordinating conjunction`, Lang.en, Sense.nounPhrase, Origin.manual),
                  Role(Rel.uses),
                  graph.add(`establish the relationship between the dependent clause and the rest of the sentence`,
                              Lang.en, Sense.unknown, Origin.manual),
                  Origin.manual, 1.0);

    // Conjunction
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/conjunction.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `conjunction`, Sense.conjunction, Sense.nounSingular, 1.0);

    enum swedishConjunctions = [`alldenstund`, `allenast`, `ante`, `antingen`, `att`, `bara`, `blott`, `bå`, `båd'`, `både`, `dock`, `att`, `där`, `därest`, `därför`, `att`, `då`, `eftersom`, `ehur`, `ehuru`, `eller`, `emedan`, `enär`, `ety`, `evad`, `fast`, `fastän`, `för`, `förrän`, `försåvida`, `försåvitt`, `fȧst`, `huruvida`, `hvarför`, `hvarken`, `hvarpå`, `ifall`, `innan`, `ity`, `ity`, `att`, `liksom`, `medan`, `medans`, `men`, `mens`, `när`, `närhelst`, `oaktat`, `och`, `om`, `om`, `och`, `endast`, `om`, `plus`, `att`, `samt`, `sedan`, `som`, `sä`, `så`, `såframt`, `såsom`, `såvida`, `såvitt`, `såväl`, `sö`, `tast`, `tills`, `ty`, `utan`, `varför`, `varken`, `än`, `ändock`, `änskönt`, `ävensom`, `å`];
    graph.learnMto1(Lang.sv, swedishConjunctions, Role(Rel.instanceOf), `conjunction`, Sense.conjunction, Sense.nounSingular, 1.0);
}
