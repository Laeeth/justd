module knet.lectures.associations;

import knet.base;

/// Learn Assocative Things.
void learnAssociativeThings(Graph graph)
{
    writeln(`Reading Associative Things ...`);

    // TODO lower weights on these are not absolute
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/constitution.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `constitution`, Sense.unknown, Sense.nounSingular);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/election.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `election`, Sense.unknown, Sense.nounSingular);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/weather.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `weather`, Sense.noun, Sense.nounSingular);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/dentist.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `dentist`, Sense.unknown, Sense.nounSingular);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/firefighting.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `fire fighting`, Sense.unknown, Sense.nounSingular);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/driving.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `drive`, Sense.unknown, Sense.verb);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/art.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `art`, Sense.unknown, Sense.nounSingular);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/astronomy.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `astronomy`, Sense.unknown, Sense.nounSingular);

    graph.learnMto1(Lang.en, rdT(`../knowledge/en/vacation.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `vacation`, Sense.unknown, Sense.nounSingular);

    graph.learnMto1(Lang.en, rdT(`../knowledge/en/autumn.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `autumn`, Sense.unknown, Sense.season);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/winter.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `winter`, Sense.unknown, Sense.season);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/spring.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `spring`, Sense.unknown, Sense.season);

    graph.learnMto1(Lang.en, rdT(`../knowledge/en/summer_noun.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.atTime), `summer`, Sense.noun, Sense.season);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/summer_adjective.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.atTime), `summer`, Sense.adjective, Sense.season);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/summer_verb.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.atTime), `summer`, Sense.verb, Sense.season);

    graph.learnMto1(Lang.en, rdT(`../knowledge/en/household_device.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.atLocation), `house`, Sense.noun, Sense.nounSingular);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/household_device.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `device`, Sense.noun, Sense.nounSingular);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/farm.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.atLocation), `farm`, Sense.noun, Sense.nounSingular);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/school.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.atLocation), `school`, Sense.noun, Sense.nounSingular);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/circus.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.atLocation), `circus`, Sense.noun, Sense.nounSingular);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/near_yard.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.atLocation), `yard`, Sense.noun, Sense.nounSingular);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/restaurant.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.atLocation), `restaurant`, Sense.noun, Sense.nounSingular);

    graph.learnMto1(Lang.en, rdT(`../knowledge/en/bathroom.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.atLocation), `bathroom`, Sense.noun, Sense.nounSingular);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/house.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.atLocation), `house`, Sense.noun, Sense.nounSingular);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/kitchen.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.atLocation), `kitchen`, Sense.noun, Sense.nounSingular);

    graph.learnMto1(Lang.en, rdT(`../knowledge/en/beach.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.atLocation), `beach`, Sense.noun, Sense.nounSingular);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/ocean.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.atLocation), `ocean`, Sense.noun, Sense.nounSingular);

    graph.learnMto1(Lang.en, rdT(`../knowledge/en/happy.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.similarTo), `happy`, Sense.adjective, Sense.adjective);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/big.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.similarTo), `big`, Sense.adjective, Sense.adjective);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/many.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.similarTo), `many`, Sense.adjective, Sense.adjective);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/easily_upset.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.similarTo), `easily upset`, Sense.adjective, Sense.adjective);

    graph.learnMto1(Lang.en, rdT(`../knowledge/en/roadway.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `roadway`, Sense.noun, Sense.nounSingular);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/baseball.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `baseball`, Sense.noun, Sense.nounSingular);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/boat.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `boat`, Sense.noun, Sense.nounSingular);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/money.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `money`, Sense.noun, Sense.nounUncountable);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/family.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `family`, Sense.noun, Sense.nounCollective);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/geography.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `geography`, Sense.unknown, Sense.nounUncountable);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/energy.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `energy`, Sense.unknown, Sense.nounUncountable);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/time.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `time`, Sense.unknown, Sense.nounUncountable);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/water.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `water`, Sense.unknown, Sense.nounUncountable);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/clothing.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `clothing`, Sense.unknown, Sense.nounUncountable);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/music_theory.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `music theory`, Sense.unknown, Sense.nounSingular);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/happiness.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `happiness`, Sense.unknown, Sense.nounUncountable);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/pirate.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `pirate`, Sense.unknown, Sense.nounSingular);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/monster.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `monster`, Sense.unknown, Sense.nounSingular);

    graph.learnMto1(Lang.en, rdT(`../knowledge/en/halloween.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `halloween`, Sense.unknown, Sense.nounUncountable);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/christmas.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `christmas`, Sense.unknown, Sense.nounUncountable);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/thanksgiving.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `thanksgiving`, Sense.unknown, Sense.nounUncountable);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/camp.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `camping`, Sense.unknown, Sense.nounUncountable);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/cooking.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `cooking`, Sense.unknown, Sense.nounUncountable);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/sewing.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `sewing`, Sense.unknown, Sense.nounUncountable);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/military.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `military`, Sense.unknown, Sense.nounUncountable);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/science.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `science`, Sense.unknown, Sense.nounUncountable);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/computer.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `computing`, Sense.unknown, Sense.nounUncountable);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/math.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `math`, Sense.unknown, Sense.nounUncountable);

    graph.learnMto1(Lang.en, rdT(`../knowledge/en/transport.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `transportation`, Sense.unknown, Sense.nounUncountable);

    graph.learnMto1(Lang.en, rdT(`../knowledge/en/rock.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `rock`, Sense.unknown, Sense.nounUncountable);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/doctor.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `doctor`, Sense.unknown, Sense.nounSingular);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/st-patricks-day.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `St. Patrick's Day`, Sense.unknown, Sense.nounUncountable);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/new-years-eve.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `New Year's Eve`, Sense.unknown, Sense.nounUncountable);

    graph.learnMto1(Lang.en, rdT(`../knowledge/en/say.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `say`, Sense.verb, Sense.verbIrregularInfinitive);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/book_property.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.hasProperty, true), `book`, Sense.adjective, Sense.nounSingular);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/informal.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.hasAttribute), `informal`, Sense.adjective, Sense.adjective);

    // Red Wine
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/red_wine_color.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `red wine color`, Sense.noun, Sense.nounSingular);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/red_wine_flavor.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `red wine flavor`, Sense.noun, Sense.nounSingular);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/red_wine_food.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.servedWith), `red wine`, Sense.noun, Sense.nounSingular);

    graph.learnMto1(Lang.en, rdT(`../knowledge/en/literary_genre.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `literary genre`, Sense.noun, Sense.nounSingular);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/major_literary_form.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `major literary form`, Sense.noun, Sense.nounSingular);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/classic_major_literary_genre.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `classic major literary genre`, Sense.noun, Sense.nounSingular);

    // Female Names
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/female_name.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `female name`, Sense.nameFemale, Sense.nounSingular, 1.0);
    graph.learnMto1(Lang.sv, rdT(`../knowledge/sv/female_name.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `female name`, Sense.nameFemale, Sense.nounSingular, 1.0);
}

/// Read and Learn Assocations.
void learnAssociations(S)(Graph graph,
                          string path,
                          Rel rel,
                          S attribute,
                          Sense wordSense = Sense.unknown,
                          Sense attributeSense = Sense.noun,
                          Lang lang = Lang.en,
                          Origin origin = Origin.manual) if (isSomeString!S)
{
    foreach (expr; File(path).byLine.filter!(a => !a.empty))
    {
        auto split = expr.findSplit(countSeparatorString); // TODO allow key to be ElementType of Range to prevent array creation here
        const name = split[0], count = split[2];

        if (expr == `ack#2`)
        {
            import dbg: dln;
            dln(name, `, `, count);
        }

        NWeight nweight = 1.0;
        if (!count.empty)
        {
            const w = count.to!NWeight;
            nweight = w/(1 + w); // count to normalized weight
        }

        graph.connect(graph.store(name.idup, lang, wordSense, origin),
                      Role(rel),
                      graph.store(attribute, lang, attributeSense, origin),
                      origin, nweight);
    }
}
