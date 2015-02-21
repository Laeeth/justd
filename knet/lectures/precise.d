module knet.lectures.precise;

import std.file;
import knet.base;

/** Learn Precise (Absolute) Thing.
 */
void learnPreciseThings(Graph graph)
{
    graph.learnEnumMemberNameHierarchy!Sense(Sense.nounSingular);

    // TODO replace with automatics
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/uncountable_noun.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `uncountable`, Sense.nounUncountable, Sense.noun, 1.0);
    graph.learnMto1(Lang.sv, rdT(`../knowledge/sv/uncountable_noun.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `uncountable`, Sense.nounUncountable, Sense.noun, 1.0);

    // Part of Speech (PoS)
    import knet.lectures.pos;
    graph.learnPartOfSpeech();

    import knet.lectures.punctuations;
    graph.learnPunctuation();

    import knet.lectures.computers;
    graph.learnEnglishComputerKnowledge();

    import knet.lectures.math;
    graph.learnMath();

    import knet.lectures.physics;
    graph.learnPhysics();

    import knet.lectures.computers;
    graph.learnComputers();

    import knet.lectures.misc;
    graph.learnEnglishMisc();

    import knet.lectures.etymology;
    graph.learnEtymologicallyDerivedFroms();

    import knet.lectures.grammar;
    graph.learnSwedishGrammar();

    import knet.lectures.names;
    graph.learnNames();

    graph.learnMto1(Lang.en, rdT(`../knowledge/en/people.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `people`, Sense.noun, Sense.nounUncountable, 1.0);

    // TODO functionize to learnGroup
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/compound_word.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `compound word`, Sense.unknown, Sense.nounSingular, 1.0);

    // Other

    // See also: https://en.wikipedia.org/wiki/Dolch_word_list
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/dolch_singular_noun.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `dolch word`, Sense.nounSingular, Sense.nounSingular, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/dolch_preprimer.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `dolch pre-primer word`, Sense.unknown, Sense.nounSingular, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/dolch_primer.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `dolch primer word`, Sense.unknown, Sense.nounSingular, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/dolch_1st_grade.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `dolch 1-st grade word`, Sense.unknown, Sense.nounSingular, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/dolch_2nd_grade.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `dolch 2-nd grade word`, Sense.unknown, Sense.nounSingular, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/dolch_3rd_grade.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `dolch 3-rd grade word`, Sense.unknown, Sense.nounSingular, 1.0);

    graph.learnMto1(Lang.en, rdT(`../knowledge/en/personal_quality.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `personal quality`, Sense.adjective, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/color.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `color`, Sense.unknown, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/shapes.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `shape`, Sense.noun, Sense.noun, 1.0);

    graph.learnMto1(Lang.en, rdT(`../knowledge/en/fruits.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `fruit`, Sense.noun, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/plants.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `plant`, Sense.noun, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/trees.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `tree`, Sense.noun, Sense.plant, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/spice.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `spice`, Sense.spice, Sense.food, 1.0);

    graph.learnMto1(Lang.en, rdT(`../knowledge/en/shoes.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `shoe`, Sense.noun, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/dances.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `dance`, Sense.noun, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/landforms.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `landform`, Sense.noun, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/desserts.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `dessert`, Sense.noun, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/countries.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `country`, Sense.noun, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/us_states.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `us_state`, Sense.noun, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/furniture.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `furniture`, Sense.noun, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/good_luck_symbols.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `good luck symbol`, Sense.noun, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/leaders.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `leader`, Sense.noun, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/measurements.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `measurement`, Sense.noun, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/quantity.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `quantity`, Sense.noun, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/language.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `language`, Sense.noun, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/insect.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `insect`, Sense.noun, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/musical_instrument.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `musical instrument`, Sense.noun, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/weapon.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `weapon`, Sense.noun, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/hats.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `hat`, Sense.noun, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/rooms.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `room`, Sense.noun, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/containers.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `container`, Sense.noun, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/virtues.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `virtue`, Sense.noun, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/vegetables.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `vegetable`, Sense.noun, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/flower.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `flower`, Sense.noun, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/reptile.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `reptile`, Sense.noun, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/famous_pair.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `pair`, Sense.noun, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/season.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `season`, Sense.noun, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/holiday.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `holiday`, Sense.noun, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/birthday.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `birthday`, Sense.noun, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/biomes.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `biome`, Sense.noun, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/dogs.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `dog`, Sense.noun, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/rodent.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `rodent`, Sense.noun, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/fish.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `fish`, Sense.noun, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/birds.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `bird`, Sense.noun, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/amphibians.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `amphibian`, Sense.noun, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/animals.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `animal`, Sense.noun, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/mammals.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `mammal`, Sense.noun, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/food.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `food`, Sense.noun, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/cars.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `car`, Sense.noun, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/building.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `building`, Sense.noun, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/housing.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `housing`, Sense.noun, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/occupation.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `occupation`, Sense.noun, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/cooking_tool.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `cooking tool`, Sense.noun, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/tool.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `tool`, Sense.noun, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/carparts.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.partOf), `car`, Sense.noun, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/bodyparts.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.partOf), `body`, Sense.noun, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/alliterations.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `alliteration`, Sense.unknown, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/positives.txt`).splitter('\n').filter!(word => !word.empty), Role(Rel.hasAttribute), `positive`, Sense.unknown, Sense.adjective, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/mineral.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `mineral`, Sense.noun, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/metal.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `metal`, Sense.noun, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/mineral_group.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `mineral group`, Sense.noun, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/major_mineral_group.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `major mineral group`, Sense.noun, Sense.noun, 1.0);

    // Swedish
    graph.learnMto1(Lang.sv, rdT(`../knowledge/sv/house.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `hus`, Sense.noun, Sense.noun, 1.0);

    graph.learnChemicalElements();

    import std.conv: ConvException;

    foreach (dirEntry; dirEntries("../knowledge/", SpanMode.shallow))
    {
        const langString = dirEntry.name.baseName;
        try
        {
            const lang = langString.to!Lang;
            const dirPath = `../knowledge/` ~ langString; // TODO reuse dirEntry

            // Male Name
            graph.learnMtoNMaybe(buildPath(dirPath, `male_name.txt`), // TODO isA male name
                                 Sense.nameMale, lang,
                                 Role(Rel.hasMeaning),
                                 Sense.unknown, lang,
                                 Origin.manual, 1.0);

            // Female Name
            graph.learnMtoNMaybe(buildPath(dirPath, `female_name.txt`), // TODO isA female name
                                 Sense.nameFemale, lang,
                                 Role(Rel.hasMeaning),
                                 Sense.unknown, lang,
                                 Origin.manual, 1.0);

            graph.learnMtoNMaybe(buildPath(dirPath, `collective_people_noun.txt`),
                                 Sense.nounPlural, lang,
                                 Role(Rel.formOfNoun),
                                 Sense.nounCollectivePeople, lang,
                                 Origin.manual, 1.0);

            graph.learnMtoNMaybe(buildPath(dirPath, `collective_creatures_noun.txt`),
                                 Sense.nounPlural, lang,
                                 Role(Rel.formOfNoun),
                                 Sense.nounCollectiveCreatures, lang,
                                 Origin.manual, 1.0);

            graph.learnMtoNMaybe(buildPath(dirPath, `collective_things_noun.txt`),
                                 Sense.nounPlural, lang,
                                 Role(Rel.formOfNoun),
                                 Sense.nounCollectiveThings, lang,
                                 Origin.manual, 1.0);

            // Irregular Noun
            graph.learnMtoNMaybe(buildPath(dirPath, `irregular_noun.txt`),
                                 Sense.nounSingular, lang,
                                 Role(Rel.formOfNoun),
                                 Sense.nounPlural, lang,
                                 Origin.manual, 1.0);

            // Abbrevation
            graph.learnMtoNMaybe(buildPath(dirPath, `abbrevation.txt`),
                                 Sense.abbrevation, lang,
                                 Role(Rel.abbreviationFor),
                                 Sense.unknown, lang,
                                 Origin.manual, 1.0);
            graph.learnMtoNMaybe(buildPath(dirPath, `noun_abbrevation.txt`),
                                 Sense.noun, lang,
                                 Role(Rel.abbreviationFor),
                                 Sense.noun, lang,
                                 Origin.manual, 1.0);

            // Contraction. See also: http://www.enchantedlearning.com/grammar/contractions/list.shtml
            graph.learnMtoNMaybe(buildPath(dirPath, `contraction.txt`),
                                 Sense.contraction, lang,
                                 Role(Rel.contractionFor),
                                 Sense.unknown, lang,
                                 Origin.manual, 1.0);

            // Synonym
            graph.learnMtoNMaybe(buildPath(dirPath, `synonym.txt`),
                                 Sense.unknown, lang, Role(Rel.synonymFor),
                                 Sense.unknown, lang, Origin.manual, 1.0);
            graph.learnMtoNMaybe(buildPath(dirPath, `obsolescent_synonym.txt`),
                                 Sense.unknown, lang, Role(Rel.obsolescentFor),
                                 Sense.unknown, lang, Origin.manual, 1.0);
            graph.learnMtoNMaybe(buildPath(dirPath, `noun_synonym.txt`),
                                 Sense.noun, lang, Role(Rel.synonymFor),
                                 Sense.noun, lang, Origin.manual, 0.5);
            graph.learnMtoNMaybe(buildPath(dirPath, `adjective_synonym.txt`),
                                 Sense.adjective, lang, Role(Rel.synonymFor),
                                 Sense.adjective, lang, Origin.manual, 1.0);

            // Prefix
            graph.learnMtoNMaybe(buildPath(dirPath, `word_prefix.txt`),
                                 Sense.prefix, lang, Role(Rel.hasMeaning),
                                 Sense.unknown, lang, Origin.manual, 1.0);
            graph.learnMtoNMaybe(buildPath(dirPath, `word_suffix.txt`),
                                 Sense.suffix, lang, Role(Rel.hasMeaning),
                                 Sense.unknown, lang, Origin.manual, 1.0);

            // Homophone
            graph.learnMtoNMaybe(buildPath(dirPath, `homophone.txt`),
                                 Sense.unknown, lang, Role(Rel.homophoneFor),
                                 Sense.unknown, lang, Origin.manual, 1.0);

            // Abbrevation
            graph.learnMtoNMaybe(buildPath(dirPath, `cardinal_direction_abbrevation.txt`),
                                 Sense.unknown, lang, Role(Rel.abbreviationFor),
                                 Sense.unknown, lang, Origin.manual, 1.0);
            graph.learnMtoNMaybe(buildPath(dirPath, `language_abbrevation.txt`),
                                 Sense.language, lang, Role(Rel.abbreviationFor),
                                 Sense.language, lang, Origin.manual, 1.0);

            // Noun
            graph.learnMto1Maybe(lang, buildPath(dirPath, `concrete_noun.txt`),
                                 Role(Rel.hasAttribute), `concrete`,
                                 Sense.noun, Sense.adjective, 1.0);
            graph.learnMto1Maybe(lang, buildPath(dirPath, `abstract_noun.txt`),
                                 Role(Rel.hasAttribute), `abstract`,
                                 Sense.noun, Sense.adjective, 1.0);
            graph.learnMto1Maybe(lang, buildPath(dirPath, `masculine_noun.txt`),
                                 Role(Rel.hasAttribute), `masculine`,
                                 Sense.noun, Sense.adjective, 1.0);
            graph.learnMto1Maybe(lang, buildPath(dirPath, `feminine_noun.txt`),
                                 Role(Rel.hasAttribute), `feminine`,
                                 Sense.noun, Sense.adjective, 1.0);

            // Acronym
            graph.learnMtoNMaybe(buildPath(dirPath, `acronym.txt`),
                                 Sense.nounAcronym, lang, Role(Rel.acronymFor),
                                 Sense.unknown, lang, Origin.manual, 1.0);
            graph.learnMtoNMaybe(buildPath(dirPath, `newspaper_acronym.txt`),
                                 Sense.newspaper, lang,
                                 Role(Rel.acronymFor),
                                 Sense.newspaper, lang,
                                 Origin.manual, 1.0);

            // Idioms
            graph.learnMtoNMaybe(buildPath(dirPath, `idiom_meaning.txt`),
                                 Sense.idiom, lang,
                                 Role(Rel.idiomFor),
                                 Sense.unknown, lang,
                                 Origin.manual, 0.7);

            // Slang
            graph.learnMtoNMaybe(buildPath(dirPath, `slang_meaning.txt`),
                                 Sense.unknown, lang,
                                 Role(Rel.slangFor),
                                 Sense.unknown, lang,
                                 Origin.manual, 0.7);

            // Slang Adjectives
            graph.learnMtoNMaybe(buildPath(dirPath, `slang_adjective_meaning.txt`),
                                 Sense.adjective, lang,
                                 Role(Rel.slangFor),
                                 Sense.unknown, lang,
                                 Origin.manual, 0.7);

            // Name
            graph.learnMtoNMaybe(buildPath(dirPath, `male_name_meaning.txt`),
                                 Sense.nameMale, lang,
                                 Role(Rel.hasMeaning),
                                 Sense.unknown, lang,
                                 Origin.manual, 0.7);
            graph.learnMtoNMaybe(buildPath(dirPath, `female_name_meaning.txt`),
                                 Sense.nameFemale, lang,
                                 Role(Rel.hasMeaning),
                                 Sense.unknown, lang,
                                 Origin.manual, 0.7);
            graph.learnMtoNMaybe(buildPath(dirPath, `name_day.txt`),
                                 Sense.name, lang,
                                 Role(Rel.hasNameDay),
                                 Sense.nounDate, Lang.en,
                                 Origin.manual, 1.0);
            graph.learnMtoNMaybe(buildPath(dirPath, `surname_languages.txt`),
                                 Sense.surname, Lang.unknown,
                                 Role(Rel.hasOrigin),
                                 Sense.language, Lang.en,
                                 Origin.manual, 1.0);

            import std.file: FileException;
            import std.exception: ErrnoException;

            // City
            try
            {
                foreach (entry; rdT(buildPath(dirPath, `city.txt`)).splitter('\n').filter!(w => !w.empty))
                {
                    const items = entry.split(roleSeparator);
                    const cityName = items[0];
                    const population = items[1];
                    const yearFounded = items[2];
                    const city = graph.add(cityName, lang, Sense.city, Origin.manual);
                    graph.connect(city, Role(Rel.hasAttribute),
                                  graph.add(population, lang, Sense.population, Origin.manual), Origin.manual, 1.0);
                    graph.connect(city, Role(Rel.foundedIn),
                                  graph.add(yearFounded, lang, Sense.year, Origin.manual), Origin.manual, 1.0);
                }
            }
            catch (FileException e) {}

            try { graph.learnMto1(lang, rdT(buildPath(dirPath, `vehicle.txt`)).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `vehicle`, Sense.noun, Sense.noun, 1.0); }
            catch (FileException e) {}

            try { graph.learnMto1(lang, rdT(buildPath(dirPath, `lowercase_letter.txt`)).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `lowercase letter`, Sense.letterLowercase, Sense.noun, 1.0); }
            catch (FileException e) {}

            try { graph.learnMto1(lang, rdT(buildPath(dirPath, `uppercase_letter.txt`)).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `uppercase letter`, Sense.letterUppercase, Sense.noun, 1.0); }
            catch (FileException e) {}

            try { graph.learnMto1(lang, rdT(buildPath(dirPath, `old_proverb.txt`)).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `old proverb`, Sense.unknown, Sense.noun, 1.0); }
            catch (FileException e) {}

            try { graph.learnMto1(lang, rdT(buildPath(dirPath, `contronym.txt`)).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `contronym`, Sense.unknown, Sense.noun, 1.0); }
            catch (FileException e) {}

            try { graph.learnOpposites(lang); }
            catch (ErrnoException e) {}
        }
        catch (ConvException e)
        {
            // handle knowledge/X-Y/*.txt such as knowledge/en-sv/*.txt
            const split = dirEntry.name.baseName.findSplit(`-`);
            if (!split[1].empty) // if subdirectory of knowledge container space
            {
                // try decoding them as iso language codes
                const srcLang = split[0].to!Lang;
                const dstLang = split[2].to!Lang;
                foreach (txtFile; dirEntries(dirEntry.name, SpanMode.shallow))
                {
                    Sense sense = Sense.unknown;
                    Rel rel;
                    switch (txtFile.name.baseName)
                    {
                        case "translation.txt":              sense = Sense.unknown;      rel = Rel.translationOf; break;
                        case "noun_translation.txt":         sense = Sense.noun;         rel = Rel.translationOf; break;
                        case "phrase_translation.txt":       sense = Sense.phrase;       rel = Rel.translationOf; break;
                        case "idiom_translation.txt":        sense = Sense.idiom;        rel = Rel.translationOf; break;
                        case "interjection_translation.txt": sense = Sense.interjection; rel = Rel.translationOf; break;
                        default:
                            writeln("Don't know how to decode sense and rel of ", txtFile.name);
                            sense = Sense.unknown;
                            break;
                    }

                    graph.learnMtoNMaybe(txtFile.name,
                                         sense, srcLang, Role(rel),
                                         sense, dstLang,
                                         Origin.manual, 1.0);
                }
            }
            else
            {
                writeln("TODO Process ", dirEntry.name);
            }
        }
    }

    import knet.lectures.emotions;
    graph.learnEmotions();

    import knet.lectures.feelings;
    graph.learnFeelings();

    import knet.lectures.usage;
    graph.learnEnglishWordUsageRanks();
}

void learnEnumMemberNameHierarchy(T)(Graph graph,
                                     Sense memberSense = Sense.unknown) if (is(T == enum))
{
    const origin = Origin.manual;
    foreach (i; enumMembers!T)
    {
        foreach (j; enumMembers!T)
        {
            if (i != T.unknown &&
                j != T.unknown &&
                i != j)
            {
                import knet.senses: specializes, toHuman;
                if (i.specializes(j))
                {
                    graph.connect(graph.add(i.toHuman, Lang.en, memberSense, origin), Role(Rel.isA),
                                  graph.add(j.toHuman, Lang.en, memberSense, origin), origin, 1.0);
                }
            }
        }
    }
}
