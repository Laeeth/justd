module knet.lectures.standard;

import std.file;
import std.algorithm: splitter;
import std.range: empty;

import knet.base;
import knet.separators;

void learnDefault(Graph graph)
{
    // absolute (trusthful) things before untrusted machine generated data
    graph.learnPreciseThings();
    graph.learnTrainedThings();
    graph.learnAssociativeThings();
}

/// Learn Externally (Trained) Supervised Things.
void learnTrainedThings(Graph graph)
{
    // wordnet = new WordNet!(true, true)([Lang.en]); // TODO Remove
    import knet.readers.wordnet;
    graph.readWordNet(`../knowledge/en/wordnet-3.1`);

    import knet.readers.swesaurus;
    graph.readSwesaurus;

    const quick = true;
    const maxCount = quick ? 50000 : size_t.max; // 50000 doesn't crash CN5

    // CN5
    import knet.readers.cn5;
    graph.readCN5(`~/Knowledge/conceptnet5-5.3/data/assertions/`, maxCount);

    // NELL
    import knet.readers.nell;
    //graph.readNELLFile(`~/Knowledge/nell/NELL.08m.895.esv.csv`, maxCount);
}

/** Learn Precise (Absolute) Thing.
 */
void learnPreciseThings(Graph graph)
{
    graph.learnEnumMemberNameHierarchy!Sense(Sense.nounSingular);

    // TODO replace with automatics
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/uncountable_noun.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `uncountable`, Sense.nounUncountable, Sense.noun, 1.0);
    graph.learnMto1(Lang.sv, rdT(`../knowledge/sv/uncountable_noun.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `uncountable`, Sense.nounUncountable, Sense.noun, 1.0);

    // Part of Speech (PoS)
    graph.learnPartOfSpeech();

    graph.learnPunctuation();

    graph.learnEnglishComputerKnowledge();

    graph.learnMath();
    graph.learnPhysics();
    graph.learnComputers();

    graph.learnEnglishOther();

    graph.learnVerbReversions();
    graph.learnEtymologicallyDerivedFroms();

    graph.learnSwedishGrammar();

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

            // Irregular Noun
            graph.learnMtoNMaybe(buildPath(dirPath, `irregular_noun.txt`),
                                 Sense.nounSingular, lang,
                                 Role(Rel.formOfNoun),
                                 Sense.nounPlural, lang,
                                 Origin.manual, 1.0);

            // Abbrevation
            graph.learnMtoNMaybe(buildPath(dirPath, `abbrevation.txt`),
                                 Sense.unknown, lang,
                                 Role(Rel.abbreviationFor),
                                 Sense.unknown, lang,
                                 Origin.manual, 1.0);
            graph.learnMtoNMaybe(buildPath(dirPath, `noun_abbrevation.txt`),
                                 Sense.noun, lang,
                                 Role(Rel.abbreviationFor),
                                 Sense.noun, lang,
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
                                 Sense.nounConcrete, Sense.adjective, 1.0);
            graph.learnMto1Maybe(lang, buildPath(dirPath, `abstract_noun.txt`),
                                 Role(Rel.hasAttribute), `abstract`,
                                 Sense.nounAbstract, Sense.adjective, 1.0);
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

            // City
            try
            {
                foreach (entry; rdT(buildPath(dirPath, `city.txt`)).splitter('\n').filter!(w => !w.empty))
                {
                    const items = entry.split(roleSeparator);
                    const cityName = items[0];
                    const population = items[1];
                    const yearFounded = items[2];
                    const city = graph.store(cityName, lang, Sense.city, Origin.manual);
                    graph.connect(city, Role(Rel.hasAttribute),
                                  graph.store(population, lang, Sense.population, Origin.manual), Origin.manual, 1.0);
                    graph.connect(city, Role(Rel.foundedIn),
                                  graph.store(yearFounded, lang, Sense.year, Origin.manual), Origin.manual, 1.0);
                }
            }
            catch (std.file.FileException e) {}

            try { graph.learnMto1(lang, rdT(buildPath(dirPath, `vehicle.txt`)).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `vehicle`, Sense.noun, Sense.noun, 1.0); }
            catch (std.file.FileException e) {}

            try { graph.learnMto1(lang, rdT(buildPath(dirPath, `lowercase_letter.txt`)).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `lowercase letter`, Sense.letterLowercase, Sense.noun, 1.0); }
            catch (std.file.FileException e) {}

            try { graph.learnMto1(lang, rdT(buildPath(dirPath, `uppercase_letter.txt`)).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `uppercase letter`, Sense.letterUppercase, Sense.noun, 1.0); }
            catch (std.file.FileException e) {}

            try { graph.learnMto1(lang, rdT(buildPath(dirPath, `old_proverb.txt`)).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `old proverb`, Sense.unknown, Sense.noun, 1.0); }
            catch (std.file.FileException e) {}

            try { graph.learnMto1(lang, rdT(buildPath(dirPath, `contronym.txt`)).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `contronym`, Sense.unknown, Sense.noun, 1.0); }
            catch (std.file.FileException e) {}

            try { graph.learnOpposites(lang); }
            catch (std.exception.ErrnoException e) {}
        }
        catch (std.conv.ConvException e)
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

    graph.learnEmotions();
    graph.learnEnglishFeelings();
    graph.learnSwedishFeelings();

    graph.learnEnglishWordUsageRanks();
}

void learnEnglishWordUsageRanks(Graph graph)
{
    const path = `../knowledge/en/word_usage_rank.txt`;
    foreach (line; File(path).byLine)
    {
        auto split = line.splitter(roleSeparator);
        const rank = split.front.idup; split.popFront;
        const word = split.front;
        graph.connect(graph.store(word, Lang.en, Sense.unknown, Origin.manual), Role(Rel.hasAttribute),
                      graph.store(rank, Lang.en, Sense.rank, Origin.manual), Origin.manual, 1.0);
    }
}

void learnPartOfSpeech(Graph graph)
{
    graph.learnPronouns();
    graph.learnAdjectives();
    graph.learnAdverbs();
    graph.learnUndefiniteArticles();
    graph.learnDefiniteArticles();
    graph.learnPartitiveArticles();
    graph.learnConjunctions();
    graph.learnInterjections();
    graph.learnTime();

    // Verb
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/regular_verb.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `regular verb`, Sense.verbRegular, Sense.noun, 1.0);

    graph.learnMto1(Lang.en, rdT(`../knowledge/en/determiner.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `determiner`, Sense.determiner, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/predeterminer.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `predeterminer`, Sense.predeterminer, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/adverbs.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `adverb`, Sense.adverb, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/preposition.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `preposition`, Sense.preposition, Sense.noun, 1.0);

    graph.learnMto1(Lang.en, [`since`, `ago`, `before`, `past`], Role(Rel.instanceOf), `time preposition`, Sense.prepositionTime, Sense.noun, 1.0);

    import knet.readers.moby;
    graph.learnMobyPoS();

    // learn these after Moby as Moby is more specific
    graph.learnNouns();
    graph.learnVerbs();

    graph.learnMto1(Lang.en, rdT(`../knowledge/en/figure_of_speech.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `figure of speech`, Sense.unknown, Sense.noun, 1.0);

    graph.learnMobyEnglishPronounciations();
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
                    graph.connect(graph.store(i.toHuman, Lang.en, memberSense, origin), Role(Rel.isA),
                                  graph.store(j.toHuman, Lang.en, memberSense, origin), origin, 1.0);
                }
            }
        }
    }
}

void learnNouns(Graph graph)
{
    writeln(`Reading Nouns ...`);

    const origin = Origin.manual;

    graph.connect(graph.store(`male`, Lang.en, Sense.noun, origin), Role(Rel.hasAttribute),
                  graph.store(`masculine`, Lang.en, Sense.adjective, origin), origin, 1.0);
    graph.connect(graph.store(`female`, Lang.en, Sense.noun, origin), Role(Rel.hasAttribute),
                  graph.store(`feminine`, Lang.en, Sense.adjective, origin), origin, 1.0);

    graph.learnEnglishNouns();
    graph.learnSwedishNouns();
}

void learnEnglishNouns(Graph graph)
{
    writeln(`Reading English Nouns ...`);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/collective_noun.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `collective noun`, Sense.nounCollective, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/noun.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `noun`, Sense.noun, Sense.noun, 1.0);
}

void learnSwedishNouns(Graph graph)
{
    writeln(`Reading Swedish Nouns ...`);
    graph.learnMto1(Lang.sv, rdT(`../knowledge/sv/collective_noun.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `collective noun`, Sense.nounCollective, Sense.noun, 1.0);
}

void learnPronouns(Graph graph)
{
    writeln(`Reading Pronouns ...`);
    graph.learnEnglishPronouns();
    graph.learnSwedishPronouns();
}

void learnEnglishPronouns(Graph graph)
{
    enum lang = Lang.en;

    // Singular
    graph.learnMto1(lang, [`I`, `me`], Role(Rel.instanceOf), `singular personal pronoun`, Sense.pronounPersonalSingular1st, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`you`], Role(Rel.instanceOf), `singular personal pronoun`, Sense.pronounPersonalSingular2nd, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`it`], Role(Rel.instanceOf), `singular personal pronoun`, Sense.pronounPersonalSingular, Sense.nounPhrase, 1.0);

    graph.learnMto1(lang, [`he`], Role(Rel.instanceOf), `1st-person male singular personal pronoun`, Sense.pronounPersonalSingularMale1st, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`him`], Role(Rel.instanceOf), `2nd-person male singular personal pronoun`, Sense.pronounPersonalSingularMale2nd, Sense.nounPhrase, 1.0);

    graph.learnMto1(lang, [`she`], Role(Rel.instanceOf), `1st-person female singular personal pronoun`, Sense.pronounPersonalSingularFemale1st, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`her`], Role(Rel.instanceOf), `2nd-person female singular personal pronoun`, Sense.pronounPersonalSingularFemale2nd, Sense.nounPhrase, 1.0);

    graph.learnMto1(lang, [`we`, `us`], Role(Rel.instanceOf), `1st-person plural personal pronoun`, Sense.pronounPersonalPlural1st, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`you`], Role(Rel.instanceOf), `2nd-person plural personal pronoun`, Sense.pronounPersonalPlural2nd, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`they`, `they`], Role(Rel.instanceOf), `3rd-person plural personal pronoun`, Sense.pronounPersonalPlural3rd, Sense.nounPhrase, 1.0);

    graph.learnMto1(lang, [`this`, `that`], Role(Rel.instanceOf), `singular demonstrative pronoun`, Sense.pronounDemonstrativeSingular, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`these`, `those`], Role(Rel.instanceOf), `plural demonstrative pronoun`, Sense.pronounDemonstrativePlural, Sense.nounPhrase, 1.0);

    // Possessive
    graph.learnMto1(lang, [`my`, `your`], Role(Rel.instanceOf), `singular possessive adjective`, Sense.adjectivePossessiveSingular, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`our`, `their`], Role(Rel.instanceOf), `plural possessive adjective`, Sense.adjectivePossessivePlural, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`mine`, `yours`], Role(Rel.instanceOf), `singular possessive pronoun`, Sense.pronounPossessiveSingular, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`his`], Role(Rel.instanceOf), `male singular possessive pronoun`, Sense.pronounPossessiveSingularMale, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`hers`], Role(Rel.instanceOf), `female singular possessive pronoun`, Sense.pronounPossessiveSingularFemale, Sense.nounPhrase, 1.0);

    graph.learnMto1(lang, [`ours`], Role(Rel.instanceOf), `1st-person plural possessive pronoun`, Sense.pronounPossessivePlural1st, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`yours`], Role(Rel.instanceOf), `2nd-person plural possessive pronoun`, Sense.pronounPossessivePlural2nd, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`theirs`], Role(Rel.instanceOf), `3rd-person plural possessive pronoun`, Sense.pronounPossessivePlural3rd, Sense.nounPhrase, 1.0);

    graph.learnMto1(lang, [`who`, `whom`, `what`, `which`, `whose`, `whoever`, `whatever`, `whichever`], Role(Rel.instanceOf), `interrogative pronoun`, Sense.pronounInterrogative, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`myself`, `yourself`, `himself`, `herself`, `itself`], Role(Rel.instanceOf), `singular reflexive pronoun`, Sense.pronounReflexiveSingular, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`ourselves`, `yourselves`, `themselves`], Role(Rel.instanceOf), `plural reflexive pronoun`, Sense.pronounReflexivePlural, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`each other`, `one another`], Role(Rel.instanceOf), `reciprocal pronoun`, Sense.pronounReciprocal, Sense.nounPhrase, 1.0);

    graph.learnMto1(lang, [`who`, `whom`, // generally only for people
                     `whose`, // possession
                     `which`, // things
                     `that` // things and people
                  ], Role(Rel.instanceOf), `relative pronoun`, Sense.pronounRelative, Sense.nounPhrase, 1.0);

    graph.learnMto1(lang, [`all`, `any`, `more`, `most`, `none`, `some`, `such`], Role(Rel.instanceOf), `indefinite pronoun`, Sense.pronounIndefinitePlural, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`another`, `anybody`, `anyone`, `anything`, `each`, `either`, `enough`,
                     `everybody`, `everyone`, `everything`, `less`, `little`, `much`, `neither`,
                     `nobody`, `noone`, `one`, `other`,
                     `somebody`, `someone`,
                     `something`, `you`], Role(Rel.instanceOf), `singular indefinite pronoun`, Sense.pronounIndefiniteSingular, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`both`, `few`, `fewer`, `many`, `others`, `several`, `they`], Role(Rel.instanceOf), `plural indefinite pronoun`, Sense.pronounIndefinitePlural, Sense.nounPhrase, 1.0);

    // Rest
    graph.learnMto1(lang, rdT(`../knowledge/en/pronoun.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `pronoun`, Sense.pronoun, Sense.nounSingular, 1.0); // TODO Remove?
}

void learnSwedishPronouns(Graph graph)
{
    enum lang = Lang.sv;

    // Personal
    graph.learnMto1(lang, [`jag`, `mig`], Role(Rel.instanceOf), `1st-person singular personal pronoun`, Sense.pronounPersonalSingular1st, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`du`, `dig`], Role(Rel.instanceOf), `2nd-person singular personal pronoun`, Sense.pronounPersonalSingular2nd, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`den`, `det`], Role(Rel.instanceOf), `3rd-person singular personal pronoun`, Sense.pronounPersonalSingular3rd, Sense.nounPhrase, 1.0);

    graph.learnMto1(lang, [`han`], Role(Rel.instanceOf), `1st-person male singular personal pronoun`, Sense.pronounPersonalSingularMale1st, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`honom`], Role(Rel.instanceOf), `2nd-person male singular personal pronoun`, Sense.pronounPersonalSingularMale2nd, Sense.nounPhrase, 1.0);

    graph.learnMto1(lang, [`hon`], Role(Rel.instanceOf), `1st-person female singular personal pronoun`, Sense.pronounPersonalSingularFemale1st, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`henne`], Role(Rel.instanceOf), `2nd-person female singular personal pronoun`, Sense.pronounPersonalSingularFemale2nd, Sense.nounPhrase, 1.0);

    graph.learnMto1(lang, [`hen`], Role(Rel.instanceOf), `androgyn singular personal pronoun`, Sense.pronounPersonalSingular, Sense.nounPhrase, 1.0);

    graph.learnMto1(lang, [`vi`, `oss`], Role(Rel.instanceOf), `1st-person plural personal pronoun`, Sense.pronounPersonalPlural1st, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`ni`], Role(Rel.instanceOf), `2nd-person plural personal pronoun`, Sense.pronounPersonalPlural2nd, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`de`, `dem`], Role(Rel.instanceOf), `3rd-person plural personal pronoun`, Sense.pronounPersonalPlural3rd, Sense.nounPhrase, 1.0);

    // Possessive
    graph.learnMto1(lang, [`min`], Role(Rel.instanceOf), `1st-person singular possessive adjective`, Sense.pronounPossessiveSingular1st, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`din`], Role(Rel.instanceOf), `2nd-person possessive adjective`, Sense.pronounPossessiveSingular2nd, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`hans`], Role(Rel.instanceOf), `male singular possessive pronoun`, Sense.pronounPossessiveSingularMale, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`hennes`], Role(Rel.instanceOf), `female singular possessive pronoun`, Sense.pronounPossessiveSingularFemale, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`hens`], Role(Rel.instanceOf), `singular possessive pronoun`, Sense.pronounPossessiveSingular, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`dens`, `dets`], Role(Rel.instanceOf), `singular possessive pronoun`, Sense.pronounPossessiveSingularNeutral, Sense.nounPhrase, 1.0);

    graph.learnMto1(lang, [`vår`], Role(Rel.instanceOf), `1st-person plural possessive pronoun`, Sense.pronounPossessivePlural1st, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`er`], Role(Rel.instanceOf), `2nd-person plural possessive pronoun`, Sense.pronounPossessivePlural2nd, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`deras`], Role(Rel.instanceOf), `3rd-person plural possessive pronoun`, Sense.pronounPossessivePlural3rd, Sense.nounPhrase, 1.0);

    // Demonstrative
    graph.learnMto1(lang, [`den här`, `den där`], Role(Rel.instanceOf), `singular demonstrative pronoun`, Sense.pronounDemonstrativeSingular, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`de här`, `de där`], Role(Rel.instanceOf), `plural demonstrative pronoun`, Sense.pronounDemonstrativePlural, Sense.nounPhrase, 1.0);

    graph.learnMto1(lang, [`den`, `det`], Role(Rel.instanceOf),
              `singular determinative pronoun`,
              Sense.pronounDeterminativeSingular, Sense.nounPhrase, 1.0);

    graph.learnMto1(lang, [`de`, `dem`], Role(Rel.instanceOf),
              `singular determinative pronoun`,
              Sense.pronounDeterminativePlural, Sense.nounPhrase, 1.0);

    graph.learnMto1(lang, [`en sådan`], Role(Rel.instanceOf),
              `singular determinative pronoun`,
              Sense.pronounDeterminativeSingular, Sense.nounPhrase, 1.0);

    graph.learnMto1(lang, [`sådant`, `sådana`], Role(Rel.instanceOf),
              `singular determinative pronoun`,
              Sense.pronounDeterminativePlural, Sense.nounPhrase, 1.0);

    // Other
    graph.learnMto1(lang, [`vem`, `som`, `vad`, `vilken`, `vems`], Role(Rel.instanceOf), `interrogative pronoun`, Sense.pronounInterrogative, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`mig själv`, `dig själv`, `han själv`, `henne själv`, `hen själv`, `den själv`, `det själv`], Role(Rel.instanceOf), `singular reflexive pronoun`, Sense.pronounReflexiveSingular, Sense.nounPhrase, 1.0); // TODO person
    graph.learnMto1(lang, [`oss själva`, `er själva`, `dem själva`], Role(Rel.instanceOf), `plural reflexive pronoun`, Sense.pronounReflexivePlural, Sense.nounPhrase, 1.0); // TODO person
    graph.learnMto1(lang, [`varandra`], Role(Rel.instanceOf), `reciprocal pronoun`, Sense.pronounReciprocal, Sense.nounPhrase, 1.0);
}

void learnVerbs(Graph graph)
{
    writeln(`Reading Verbs ...`);
    graph.learnSwedishRegularVerbs();
    graph.learnSwedishIrregularVerbs();
    graph.learnEnglishVerbs();
}

void learnAdjectives(Graph graph)
{
    writeln(`Reading Adjectives ...`);
    graph.learnSwedishAdjectives();
    graph.learnEnglishAdjectives();
    graph.learnGermanIrregularAdjectives();
}

void learnEnglishVerbs(Graph graph)
{
    writeln(`Reading English Verbs ...`);
    graph.learnEnglishIrregularVerbs();
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/verbs.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `verb`, Sense.verb, Sense.noun, 1.0);
}

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

void learnDefiniteArticles(Graph graph)
{
    writeln(`Reading Definite Articles ...`);

    graph.learnMto1(Lang.en, [`the`],
              Role(Rel.instanceOf), `definite article`, Sense.articleDefinite, Sense.nounPhrase, 1.0);
    graph.learnMto1(Lang.de, [`der`, `die`, `das`, `des`, `dem`, `den`],
              Role(Rel.instanceOf), `definite article`, Sense.articleDefinite, Sense.nounPhrase, 1.0);
    graph.learnMto1(Lang.fr, [`le`, `la`, `l'`, `les`],
              Role(Rel.instanceOf), `definite article`, Sense.articleDefinite, Sense.nounPhrase, 1.0);
    graph.learnMto1(Lang.sv, [`den`, `det`],
              Role(Rel.instanceOf), `definite article`, Sense.articleDefinite, Sense.nounPhrase, 1.0);
}

void learnUndefiniteArticles(Graph graph)
{
    writeln(`Reading Undefinite Articles ...`);

    graph.learnMto1(Lang.en, [`a`, `an`],
              Role(Rel.instanceOf), `undefinite article`, Sense.articleIndefinite, Sense.nounPhrase, 1.0);
    graph.learnMto1(Lang.de, [`ein`, `eine`, `eines`, `einem`, `einen`, `einer`],
              Role(Rel.instanceOf), `undefinite article`, Sense.articleIndefinite, Sense.nounPhrase, 1.0);
    graph.learnMto1(Lang.fr, [`un`, `une`, `des`],
              Role(Rel.instanceOf), `undefinite article`, Sense.articleIndefinite, Sense.nounPhrase, 1.0);
    graph.learnMto1(Lang.sv, [`en`, `ena`, `ett`],
              Role(Rel.instanceOf), `undefinite article`, Sense.articleIndefinite, Sense.nounPhrase, 1.0);
}

void learnPartitiveArticles(Graph graph)
{
    writeln(`Reading Partitive Articles ...`);

    graph.learnMto1(Lang.en, [`some`],
              Role(Rel.instanceOf), `partitive article`, Sense.articlePartitive, Sense.nounPhrase, 1.0);
    graph.learnMto1(Lang.fr, [`du`, `de`, `la`, `de`, `l'`, `des`],
              Role(Rel.instanceOf), `partitive article`, Sense.articlePartitive, Sense.nounPhrase, 1.0);
}

void learnNames(Graph graph)
{
    writeln(`Reading Names ...`);

    // Surnames
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/surname.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `surname`, Sense.surname, Sense.nounSingular, 1.0);
    graph.learnMto1(Lang.sv, rdT(`../knowledge/sv/surname.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `surname`, Sense.surname, Sense.nounSingular, 1.0);
}

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
    graph.connect(graph.store(`coordinating conjunction`, Lang.en, Sense.nounPhrase, Origin.manual),
                  Role(Rel.uses),
                  graph.store(`graph.connect independent sentence parts`, Lang.en, Sense.unknown, Origin.manual),
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
    graph.connect(graph.store(`subordinating conjunction`, Lang.en, Sense.nounPhrase, Origin.manual),
                  Role(Rel.uses),
                  graph.store(`establish the relationship between the dependent clause and the rest of the sentence`,
                        Lang.en, Sense.unknown, Origin.manual),
                  Origin.manual, 1.0);

    // Conjunction
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/conjunction.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `conjunction`, Sense.conjunction, Sense.nounSingular, 1.0);

    enum swedishConjunctions = [`alldenstund`, `allenast`, `ante`, `antingen`, `att`, `bara`, `blott`, `bå`, `båd'`, `både`, `dock`, `att`, `där`, `därest`, `därför`, `att`, `då`, `eftersom`, `ehur`, `ehuru`, `eller`, `emedan`, `enär`, `ety`, `evad`, `fast`, `fastän`, `för`, `förrän`, `försåvida`, `försåvitt`, `fȧst`, `huruvida`, `hvarför`, `hvarken`, `hvarpå`, `ifall`, `innan`, `ity`, `ity`, `att`, `liksom`, `medan`, `medans`, `men`, `mens`, `när`, `närhelst`, `oaktat`, `och`, `om`, `om`, `och`, `endast`, `om`, `plus`, `att`, `samt`, `sedan`, `som`, `sä`, `så`, `såframt`, `såsom`, `såvida`, `såvitt`, `såväl`, `sö`, `tast`, `tills`, `ty`, `utan`, `varför`, `varken`, `än`, `ändock`, `änskönt`, `ävensom`, `å`];
    graph.learnMto1(Lang.sv, swedishConjunctions, Role(Rel.instanceOf), `conjunction`, Sense.conjunction, Sense.nounSingular, 1.0);
}

void learnInterjections(Graph graph)
{
    writeln(`Reading Interjections ...`);

    graph.learnMto1(Lang.en,
              rdT(`../knowledge/en/interjection.txt`).splitter('\n').filter!(word => !word.empty),
              Role(Rel.instanceOf), `interjection`, Sense.interjection, Sense.nounSingular, 1.0);
}

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

/// Learn Emotions.
void learnEmotions(Graph graph)
{
    enum groups = [`basic`, `positive`, `negative`, `strong`, `medium`, `light`];
    foreach (group; groups)
    {
        graph.learnMto1(Lang.en,
                  rdT(`../knowledge/en/` ~ group ~ `_emotion.txt`).splitter('\n').filter!(word => !word.empty),
                  Role(Rel.instanceOf), group ~ ` emotion`, Sense.unknown, Sense.nounSingular);
    }
}

/// Learn English Feelings.
void learnEnglishFeelings(Graph graph)
{
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/feeling.txt`).splitter('\n').filter!(word => !word.empty), Role(Rel.instanceOf), `feeling`, Sense.adjective, Sense.nounSingular);
    enum feelings = [`afraid`, `alive`, `angry`, `confused`, `depressed`, `good`, `happy`,
                     `helpless`, `hurt`, `indifferent`, `interested`, `love`,
                     `negative`, `unpleasant`,
                     `positive`, `pleasant`,
                     `open`, `sad`, `strong`];
    foreach (feeling; feelings)
    {
        const path = `../knowledge/en/` ~ feeling ~ `_feeling.txt`;
        graph.learnAssociations(path, Rel.similarTo, feeling.replace(`_`, ` `) ~ ` feeling`, Sense.adjective, Sense.adjective);
    }
}

/// Learn Swedish Feelings.
void learnSwedishFeelings(Graph graph)
{
    graph.learnMto1(Lang.sv,
              rdT(`../knowledge/sv/känsla.txt`).splitter('\n').filter!(word => !word.empty),
              Role(Rel.instanceOf), `känsla`, Sense.noun, Sense.nounSingular);
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
        auto split = expr.findSplit([countSeparator]); // TODO allow key to be ElementType of Range to prevent array creation here
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

/// Learn Chemical Elements.
void learnChemicalElements(Graph graph,
                           Lang lang = Lang.en, Origin origin = Origin.manual)
{
    foreach (expr; File(`../knowledge/en/chemical_elements.txt`).byLine.filter!(a => !a.empty))
    {
        auto split = expr.findSplit([roleSeparator]); // TODO allow key to be ElementType of Range to prevent array creation here
        const name = split[0], sym = split[2];
        NWeight weight = 1.0;

        graph.connect(graph.store(name.idup, lang, Sense.nounUncountable, origin),
                Role(Rel.instanceOf),
                graph.store(`chemical element`, lang, Sense.nounSingular, origin),
                origin, weight);

        graph.connect(graph.store(sym.idup, lang, Sense.noun, origin),
                Role(Rel.symbolFor),
                graph.store(name.idup, lang, Sense.noun, origin),
                origin, weight);
    }
}

/// Learn Verb Reversions.
void learnVerbReversions(Graph graph)
{
    // TODO Copy all from krels.toHuman
    graph.learnVerbReversion(`is a`, `can be`, Lang.en);
    graph.learnVerbReversion(`leads to`, `can infer`, Lang.en);
    graph.learnVerbReversion(`is part of`, `contains`, Lang.en);
    graph.learnVerbReversion(`is member of`, `has member`, Lang.en);
}

/// Learn Etymologically Derived Froms.
void learnEtymologicallyDerivedFroms(Graph graph)
{
    graph.learnEtymologicallyDerivedFrom(`holiday`, Lang.en, Sense.noun,
                                   `holy day`, Lang.en, Sense.noun);
    graph.learnEtymologicallyDerivedFrom(`juletide`, Lang.en, Sense.noun,
                                   `juletid`, Lang.sv, Sense.noun);
    graph.learnEtymologicallyDerivedFrom(`smorgosbord`, Lang.en, Sense.noun,
                                   `smörgåsbord`, Lang.sv, Sense.noun);
    graph.learnEtymologicallyDerivedFrom(`förgätmigej`, Lang.sv, Sense.noun,
                                   `förgät mig ej`, Lang.sv, Sense.unknown); // TODO uppmaning
    graph.learnEtymologicallyDerivedFrom(`OK`, Lang.en, Sense.unknown,
                                   `Old Kinderhook`, Lang.en, Sense.unknown);
}

/** Learn English Computer Acronyms.
 */
void learnEnglishComputerKnowledge(Graph graph)
{
    // TODO Context: Computer
    graph.learnEnglishAcronym(`IETF`, `Internet Engineering Task Force`, 0.9);
    graph.learnEnglishAcronym(`RFC`, `Request For Comments`, 0.8);
    graph.learnEnglishAcronym(`FYI`, `For Your Information`, 0.7);
    graph.learnEnglishAcronym(`BCP`, `Best Current Practise`, 0.6);
    graph.learnEnglishAcronym(`LGTM`, `Looks Good To Me`, 0.9);

    graph.learnEnglishAcronym(`AJAX`, `Asynchronous Javascript And XML`, 1.0); // 5-star
    graph.learnEnglishAcronym(`AJAX`, `Associação De Jogadores Amadores De Xadrez`, 0.5); // 1-star

    // TODO Context: (Orakel) Computer
    graph.learnEnglishAcronym(`3NF`, `Third Normal Form`, 0.5);
    graph.learnEnglishAcronym(`ACID`, `Atomicity, Consistency, Isolation, and Durability`, 0.5);
    graph.learnEnglishAcronym(`ACL`, `Access Control List`, 0.5);
    graph.learnEnglishAcronym(`ACLs`, `Access Control Lists`, 0.5);
    graph.learnEnglishAcronym(`ADDM`, `Automatic Database Diagnostic Monitor`, 0.5);
    graph.learnEnglishAcronym(`ADR`, `Automatic Diagnostic Repository`, 0.5);
    graph.learnEnglishAcronym(`ASM`, `Automatic Storage Management`, 0.5);
    graph.learnEnglishAcronym(`AWR`, `Automatic Workload Repository`, 0.5);
    graph.learnEnglishAcronym(`AWT`, `Asynchronous WriteThrough`, 0.5);
    graph.learnEnglishAcronym(`BGP`, `Basic Graph Pattern`, 0.5);
    graph.learnEnglishAcronym(`BLOB`, `Binary Large Object`, 0.5);
    graph.learnEnglishAcronym(`CBC`, `Cipher Block Chaining`, 0.5);
    graph.learnEnglishAcronym(`CCA`, `Control Center Agent`, 0.5);
    graph.learnEnglishAcronym(`CDATA`, `Character DATA`, 0.5);
    graph.learnEnglishAcronym(`CDS`, `Cell Directory Services`, 0.5);
    graph.learnEnglishAcronym(`CFS`, `Cluster File System`, 0.5);
    graph.learnEnglishAcronym(`CIDR`, `Classless Inter-Domain Routing`, 0.5);
    graph.learnEnglishAcronym(`CLOB`, `Character Large OBject`, 0.5);
    graph.learnEnglishAcronym(`CMADMIN`, `Connection Manager Administration`, 0.5);
    graph.learnEnglishAcronym(`CMGW`, `Connection Manager GateWay`, 0.5);
    graph.learnEnglishAcronym(`COM`, `Component Object Model`, 0.8);
    graph.learnEnglishAcronym(`CORBA`, `Common Object Request Broker API`, 0.8);
    graph.learnEnglishAcronym(`CORE`, `Common Oracle Runtime Environment`, 0.3);
    graph.learnEnglishAcronym(`CRL`, `certificate revocation list`, 0.5);
    graph.learnEnglishAcronym(`CRSD`, `Cluster Ready Services Daemon`, 0.5);
    graph.learnEnglishAcronym(`CSS`, `Cluster Synchronization Services`, 0.5);
    graph.learnEnglishAcronym(`CT`, `Code Template`, 0.2);
    graph.learnEnglishAcronym(`CVU`, `Cluster Verification Utility`, 0.3);
    graph.learnEnglishAcronym(`CWM`, `Common Warehouse Metadata`, 0.5);
    graph.learnEnglishAcronym(`DAS`, `Direct Attached Storage`, 0.5);
    graph.learnEnglishAcronym(`DBA`, `DataBase Administrator`, 0.5);
    graph.learnEnglishAcronym(`DBMS`, `DataBase Management System`, 0.8);
    graph.learnEnglishAcronym(`DBPITR`, `Database Point-In-Time Recovery`, 0.5);
    graph.learnEnglishAcronym(`DBW`, `Database Writer`, 0.5);
    graph.learnEnglishAcronym(`DCE`, `Distributed Computing Environment`, 0.3);
    graph.learnEnglishAcronym(`DCOM`, `Distributed Component Object Model`, 0.7);
    graph.learnEnglishAcronym(`DDL LCR`, `DDL Logical Change Record`, 0.5);
    graph.learnEnglishAcronym(`DHCP`, `Dynamic Host Configuration Protocol`, 0.9);
    graph.learnEnglishAcronym(`DICOM`, `Digital Imaging and Communications in Medicine`, 0.5);
    graph.learnEnglishAcronym(`DIT`, `Directory Information Tree`, 0.5);
    graph.learnEnglishAcronym(`DLL`, `Dynamic-Link Library`, 0.8);
    graph.learnEnglishAcronym(`DN`, `Distinguished Name`, 0.5);
    graph.learnEnglishAcronym(`DNS`, `Domain Name System`, 0.5);
    graph.learnEnglishAcronym(`DOM`, `Document Object Model`, 0.6);
    graph.learnEnglishAcronym(`DTD`, `Document Type Definition`, 0.8);
    graph.learnEnglishAcronym(`DTP`, `Distributed Transaction Processing`, 0.5);
    graph.learnEnglishAcronym(`Dnnn`, `Dispatcher Process`, 0.5);
    graph.learnEnglishAcronym(`DoS`, `Denial-Of-Service`, 0.9);
    graph.learnEnglishAcronym(`EJB`, `Enterprise JavaBean`, 0.5);
    graph.learnEnglishAcronym(`EMCA`, `Enterprise Manager Configuration Assistant`, 0.5);
    graph.learnEnglishAcronym(`ETL`, `Extraction, Transformation, and Loading`, 0.5);
    graph.learnEnglishAcronym(`EVM`, `Event Manager`, 0.5);
    graph.learnEnglishAcronym(`EVMD`, `Event Manager Daemon`, 0.5);
    graph.learnEnglishAcronym(`FAN`, `Fast Application Notification`, 0.5);
    graph.learnEnglishAcronym(`FIPS`, `Federal Information Processing Standard`, 0.5);
    graph.learnEnglishAcronym(`GAC`, `Global Assembly Cache`, 0.5);
    graph.learnEnglishAcronym(`GCS`, `Global Cache Service`, 0.5);
    graph.learnEnglishAcronym(`GDS`, `Global Directory Service`, 0.5);
    graph.learnEnglishAcronym(`GES`, `Global Enqueue Service`, 0.5);
    graph.learnEnglishAcronym(`GIS`, `Geographic Information System`, 0.5);
    graph.learnEnglishAcronym(`GNS`, `Grid Naming Service`, 0.5);
    graph.learnEnglishAcronym(`GNSD`, `Grid Naming Service Daemon`, 0.5);
    graph.learnEnglishAcronym(`GPFS`, `General Parallel File System`, 0.5);
    graph.learnEnglishAcronym(`GSD`, `Global Services Daemon`, 0.5);
    graph.learnEnglishAcronym(`GV$`, `global dynamic performance views`, 0.5);
    graph.learnEnglishAcronym(`HACMP`, `High Availability Cluster Multi-Processing`, 0.5);
    graph.learnEnglishAcronym(`HBA`, `Host Bus Adapter`, 0.5);
    graph.learnEnglishAcronym(`IDE`, `Integrated Development Environment`, 0.5);
    graph.learnEnglishAcronym(`IPC`, `Interprocess Communication`, 0.5);
    graph.learnEnglishAcronym(`IPv4`, `IP Version 4`, 0.5);
    graph.learnEnglishAcronym(`IPv6`, `IP Version 6`, 0.5);
    graph.learnEnglishAcronym(`ITL`, `Interested Transaction List`, 0.5);
    graph.learnEnglishAcronym(`J2EE`, `Java 2 Platform, Enterprise Edition`, 0.5);
    graph.learnEnglishAcronym(`JAXB`, `Java Architecture for XML Binding`, 0.5);
    graph.learnEnglishAcronym(`JAXP`, `Java API for XML Processing`, 0.5);
    graph.learnEnglishAcronym(`JDBC`, `Java Database Connectivity`, 0.5);
    graph.learnEnglishAcronym(`JDK`, `Java Developer's Kit`, 0.5);
    graph.learnEnglishAcronym(`JNDI`,`Java Naming and Directory Interface`, 0.5);
    graph.learnEnglishAcronym(`JRE`,`Java Runtime Environment`, 0.5);
    graph.learnEnglishAcronym(`JSP`,`JavaServer Pages`, 0.5);
    graph.learnEnglishAcronym(`JSR`,`Java Specification Request`, 0.5);
    graph.learnEnglishAcronym(`JVM`,`Java Virtual Machine`, 0.8);
    graph.learnEnglishAcronym(`KDC`,`Key Distribution Center`, 0.5);
    graph.learnEnglishAcronym(`KWIC`, `Key Word in Context`, 0.5);
    graph.learnEnglishAcronym(`LCR`, `Logical Change Record`, 0.5);
    graph.learnEnglishAcronym(`LDAP`, `Lightweight Directory Access Protocol`, 0.5);
    graph.learnEnglishAcronym(`LDIF`, `Lightweight Directory Interchange Format`, 0.5);
    graph.learnEnglishAcronym(`LGWR`, `LoG WRiter`, 0.5);
    graph.learnEnglishAcronym(`LMD`, `Global Enqueue Service Daemon`, 0.5);
    graph.learnEnglishAcronym(`LMON`, `Global Enqueue Service Monitor`, 0.5);
    graph.learnEnglishAcronym(`LMSn`, `Global Cache Service Processes`, 0.5);
    graph.learnEnglishAcronym(`LOB`, `Large OBject`, 0.5);
    graph.learnEnglishAcronym(`LOBs`, `Large Objects`, 0.5);
    graph.learnEnglishAcronym(`LRS Segment`, `Geometric Segment`, 0.5);
    graph.learnEnglishAcronym(`LUN`, `Logical Unit Number`, 0.5);
    graph.learnEnglishAcronym(`LUNs`, `Logical Unit Numbers`, 0.5);
    graph.learnEnglishAcronym(`LVM`, `Logical Volume Manager`, 0.5);
    graph.learnEnglishAcronym(`MAPI`, `Messaging Application Programming Interface`, 0.5);
    graph.learnEnglishAcronym(`MBR`, `Master Boot Record`, 0.5);
    graph.learnEnglishAcronym(`MS DTC`, `Microsoft Distributed Transaction Coordinator`, 0.5);
    graph.learnEnglishAcronym(`MTTR`, `Mean Time To Recover`, 0.5);
    graph.learnEnglishAcronym(`NAS`, `Network Attached Storage`, 0.5);
    graph.learnEnglishAcronym(`NCLOB`, `National Character Large Object`, 0.5);
    graph.learnEnglishAcronym(`NFS`, `Network File System`, 0.5);
    graph.learnEnglishAcronym(`NI`, `Network Interface`, 0.5);
    graph.learnEnglishAcronym(`NIC`, `Network Interface Card`, 0.5);
    graph.learnEnglishAcronym(`NIS`, `Network Information Service`, 0.5);
    graph.learnEnglishAcronym(`NIST`, `National Institute of Standards and Technology`, 0.5);
    graph.learnEnglishAcronym(`NPI`, `Network Program Interface`, 0.5);
    graph.learnEnglishAcronym(`NS`, `Network Session`, 0.5);
    graph.learnEnglishAcronym(`NTP`, `Network Time Protocol`, 0.5);
    graph.learnEnglishAcronym(`OASIS`, `Organization for the Advancement of Structured Information`, 0.5);
    graph.learnEnglishAcronym(`OCFS`, `Oracle Cluster File System`, 0.5);
    graph.learnEnglishAcronym(`OCI`, `Oracle Call Interface`, 0.5);
    graph.learnEnglishAcronym(`OCR`, `Oracle Cluster Registry`, 0.5);
    graph.learnEnglishAcronym(`ODBC`, `Open Database Connectivity`, 0.5);
    graph.learnEnglishAcronym(`ODBC INI`, `ODBC Initialization File`, 0.5);
    graph.learnEnglishAcronym(`ODP NET`, `Oracle Data Provider for .NET`, 0.5);
    graph.learnEnglishAcronym(`OFA`, `optimal flexible architecture`, 0.5);
    graph.learnEnglishAcronym(`OHASD`, `Oracle High Availability Services Daemon`, 0.5);
    graph.learnEnglishAcronym(`OIFCFG`, `Oracle Interface Configuration Tool`, 0.5);
    graph.learnEnglishAcronym(`OLM`, `Object Link Manager`, 0.5);
    graph.learnEnglishAcronym(`OLTP`, `online transaction processing`, 0.5);
    graph.learnEnglishAcronym(`OMF`, `Oracle Managed Files`, 0.5);
    graph.learnEnglishAcronym(`ONS`, `Oracle Notification Services`, 0.5);
    graph.learnEnglishAcronym(`OO4O`, `Oracle Objects for OLE`, 0.5);
    graph.learnEnglishAcronym(`OPI`, `Oracle Program Interface`, 0.5);
    graph.learnEnglishAcronym(`ORDBMS`, `object-relational database management system`, 0.5);
    graph.learnEnglishAcronym(`OSI`, `Open Systems Interconnection`, 0.5);
    graph.learnEnglishAcronym(`OUI`, `Oracle Universal Installer`, 0.5);
    graph.learnEnglishAcronym(`OraMTS`, `Oracle Services for Microsoft Transaction Server`, 0.5);
    graph.learnEnglishAcronym(`ASM`, `Automatic Storage Management`, 0.5);
    graph.learnEnglishAcronym(`RAC`, `Real Application Clusters`, 0.5);
    graph.learnEnglishAcronym(`PCDATA`, `Parsed Character Data`, 0.5);
    graph.learnEnglishAcronym(`PGA`, `Program Global Area`, 0.5);
    graph.learnEnglishAcronym(`PKI`, `Public Key Infrastructure`, 0.5);
    graph.learnEnglishAcronym(`RAID`, `Redundant Array of Inexpensive Disks`, 0.5);
    graph.learnEnglishAcronym(`RDBMS`, `Relational Database Management System`, 0.5);
    graph.learnEnglishAcronym(`RDN`, `Relative Distinguished Name`, 0.5);
    graph.learnEnglishAcronym(`RM`, `Resource Manager`, 0.5);
    graph.learnEnglishAcronym(`RMAN`, `Recovery Manager`, 0.5);
    graph.learnEnglishAcronym(`ROI`, `Return On Investment`, 0.5);
    graph.learnEnglishAcronym(`RPO`, `Recovery Point Objective`, 0.5);
    graph.learnEnglishAcronym(`RTO`, `Recovery Time Objective`, 0.5);
    graph.learnEnglishAcronym(`SAN`, `Storage Area Network`, 0.5);
    graph.learnEnglishAcronym(`SAX`, `Simple API for XML`, 0.5);
    graph.learnEnglishAcronym(`SCAN`, `Single Client Access Name`, 0.5);
    graph.learnEnglishAcronym(`SCN`, `System Change Number`, 0.5);
    graph.learnEnglishAcronym(`SCSI`, `Small Computer System Interface`, 0.5);
    graph.learnEnglishAcronym(`SDU`, `Session Data Unit`, 0.5);
    graph.learnEnglishAcronym(`SGA`, `System Global Area`, 0.5);
    graph.learnEnglishAcronym(`SGML`, `Structured Generalized Markup Language`, 0.5);
    graph.learnEnglishAcronym(`SHA`, `Secure Hash Algorithm`, 0.5);
    graph.learnEnglishAcronym(`SID`, `System IDentifier`, 0.5);
    graph.learnEnglishAcronym(`SKOS`, `Simple Knowledge Organization System`, 0.5);
    graph.learnEnglishAcronym(`SOA`, `Service-Oriented Architecture`, 0.5);
    graph.learnEnglishAcronym(`SOAP`, `Simple Object Access Protocol`, 0.5);
    graph.learnEnglishAcronym(`SOP`, `Service Object Pair`, 0.5);
    graph.learnEnglishAcronym(`SQL`, `Structured Query Language`, 0.5);
    graph.learnEnglishAcronym(`SRVCTL`, `Server Control`, 0.5);
    graph.learnEnglishAcronym(`SSH`, `Secure Shell`, 0.5);
    graph.learnEnglishAcronym(`SSL`, `Secure Sockets Layer`, 0.5);
    graph.learnEnglishAcronym(`SSO`, `Single Sign-On`, 0.5);
    graph.learnEnglishAcronym(`STS`, `Sql Tuning Set`, 0.5);
    graph.learnEnglishAcronym(`SWT`, `Synchronous WriteThrough`, 0.5);
    graph.learnEnglishAcronym(`TAF`, `Transparent Application Failover`, 0.5);
    graph.learnEnglishAcronym(`TCO`, `Total Cost of Ownership`, 0.5);
    graph.learnEnglishAcronym(`TNS`, `Transparent Network Substrate`, 0.5);
    graph.learnEnglishAcronym(`TSPITR`, `Tablespace Point-In-Time Recovery`, 0.5);
    graph.learnEnglishAcronym(`TTC`, `Two-Task Common`, 0.5);
    graph.learnEnglishAcronym(`UGA`, `User Global Area`, 0.5);
    graph.learnEnglishAcronym(`UID`, `Unique IDentifier`, 0.5);
    graph.learnEnglishAcronym(`UIX`, `User Interface XML`, 0.5);
    graph.learnEnglishAcronym(`UNC`, `Universal Naming Convention`, 0.5);
    graph.learnEnglishAcronym(`UTC`, `Coordinated Universal Time`, 0.5);
    graph.learnEnglishAcronym(`VPD`, `Virtual Private Database`, 0.5);
    graph.learnEnglishAcronym(`VSS`, `Volume Shadow Copy Service`, 0.5);
    graph.learnEnglishAcronym(`W3C`, `World Wide Web Consortium`, 0.5);
    graph.learnEnglishAcronym(`WG`, `Working Group`, 0.5);
    graph.learnEnglishAcronym(`WebDAV`, `World Wide Web Distributed Authoring and Versioning`, 0.5);
    graph.learnEnglishAcronym(`Winsock`, `Windows sockets`, 0.5);
    graph.learnEnglishAcronym(`XDK`, `XML Developer's Kit`, 0.5);
    graph.learnEnglishAcronym(`XIDs`,`Transaction Identifiers`, 0.5);
    graph.learnEnglishAcronym(`XML`,`eXtensible Markup Language`, 0.5);
    graph.learnEnglishAcronym(`XQuery`,`XML Query`, 0.5);
    graph.learnEnglishAcronym(`XSL`,`eXtensible Stylesheet Language`, 0.5);
    graph.learnEnglishAcronym(`XSLFO`, `eXtensible Stylesheet Language Formatting Object`, 0.5);
    graph.learnEnglishAcronym(`XSLT`, `eXtensible Stylesheet Language Transformation`, 0.5);
    graph.learnEnglishAcronym(`XSU`, `XML SQL Utility`, 0.5);
    graph.learnEnglishAcronym(`XVM`, `XSLT Virtual Machine`, 0.5);
    graph.learnEnglishAcronym(`Approximate CSCN`, `Approximate Commit System Change Number`, 0.5);
    graph.learnEnglishAcronym(`mDNS`, `Multicast Domain Name Server`, 0.5);
    graph.learnEnglishAcronym(`row LCR`, `Row Logical Change Record`, 0.5);

    /* Use: atLocation (US) */

    /* Context: Non-animal methods for toxicity testing */

    graph.learnEnglishAcronym(`3D`,`three dimensional`, 0.9);
    graph.learnEnglishAcronym(`3RS`,`Replacement, Reduction, Refinement`, 0.5);
    graph.learnEnglishAcronym(`AALAS`,`American Association for Laboratory Animal Science`, 0.8);
    graph.learnEnglishAcronym(`ADI`,`Acceptable Daily Intake [human]`, 0.6);
    graph.learnEnglishAcronym(`AFIP`,`Armed Forces Institute of Pathology`, 0.6);
    graph.learnEnglishAcronym(`AHI`,`Animal Health Institute (US)`, 0.5);
    graph.learnEnglishAcronym(`AIDS`,`Acquired Immune Deficiency Syndrome`, 0.95);
    graph.learnEnglishAcronym(`ANDA`,`Abbreviated New Drug Application (US FDA)`, 0.5);
    graph.learnEnglishAcronym(`AOP`,`Adverse Outcome Pathway`, 0.5);
    graph.learnEnglishAcronym(`APHIS`,`Animal and Plant Health Inspection Service (USDA)`, 0.9);
    graph.learnEnglishAcronym(`ARDF`,`Alternatives Research and Development Foundation`, 0.5);
    graph.learnEnglishAcronym(`ATLA`,`Alternatives to Laboratory Animals`, 0.5);
    graph.learnEnglishAcronym(`ATSDR`,`Agency for Toxic Substances and Disease Registry (US CDC)`, 0.5);
    graph.learnEnglishAcronym(`BBMO`,`Biosensors Based on Membrane Organization to Replace Animal Testing`, 0.5);
    graph.learnEnglishAcronym(`BCOP`,`Bovine Corneal Opacity and Permeability assay`, 0.5);
    graph.learnEnglishAcronym(`BFR`,`German Federal Institute for Risk Assessment`, 0.5);
    graph.learnEnglishAcronym(`BLA`,`Biological License Application (US FDA)`, 0.5);
    graph.learnEnglishAcronym(`BRD`,`Background Review Document (ICCVAM)`, 0.5);
    graph.learnEnglishAcronym(`BSC`,`Board of Scientific Counselors (US NTP)`, 0.5);
    graph.learnEnglishAcronym(`BSE`,`Bovine Spongiform Encephalitis`, 0.5);
    graph.learnEnglishAcronym(`CAAI`,`University of California Center for Animal Alternatives Information`, 0.5);
    graph.learnEnglishAcronym(`CAAT`,`Johns Hopkins Center for Alternatives to Animal Testing`, 0.5);
    graph.learnEnglishAcronym(`CAMVA`,`Chorioallantoic Membrane Vascularization Assay`, 0.5);
    graph.learnEnglishAcronym(`CBER`,`Center for Biologics Evaluation and Research (US FDA)`, 0.5);
    graph.learnEnglishAcronym(`CDC`,`Centers for Disease Control and Prevention (US)`, 0.5);
    graph.learnEnglishAcronym(`CDER`,`Center for Drug Evaluation and Research (US FDA)`, 0.5);
    graph.learnEnglishAcronym(`CDRH`,`Center for Devices and Radiological Health (US FDA)`, 0.5);
    graph.learnEnglishAcronym(`CERHR`,`Center for the Evaluation of Risks to Human Reproduction (US NTP)`, 0.5);
    graph.learnEnglishAcronym(`CFR`,`Code of Federal Regulations (US)`, 0.5);
    graph.learnEnglishAcronym(`CFSAN`,`Center for Food Safety and Applied Nutrition (US FDA)`, 0.5);
    graph.learnEnglishAcronym(`CHMP`,`Committees for Medicinal Products for Human Use`, 0.5);
    graph.learnEnglishAcronym(`CMR`,`Carcinogenic, Mutagenic and Reprotoxic`, 0.5);
    graph.learnEnglishAcronym(`CO2`,`Carbon Dioxide`, 0.5);
    graph.learnEnglishAcronym(`COLIPA`,`European Cosmetic Toiletry & Perfumery Association`, 0.5);
    graph.learnEnglishAcronym(`COMP`,`Committee for Orphan Medicinal Products`, 0.5);
    graph.learnEnglishAcronym(`CORDIS`,`Community Research & Development Information Service`, 0.5);
    graph.learnEnglishAcronym(`CORRELATE`,`European Reference Laboratory for Alternative Tests`, 0.5);
    graph.learnEnglishAcronym(`CPCP`,`Chemical Prioritization Community of Practice (US EPA)`, 0.5);
    graph.learnEnglishAcronym(`CPSC`,`Consumer Product Safety Commission (US)`, 0.5);
    graph.learnEnglishAcronym(`CTA`,`Cell Transformation Assays`, 0.5);
    graph.learnEnglishAcronym(`CVB`,`Center for Veterinary Biologics (USDA)`, 0.5);
    graph.learnEnglishAcronym(`CVM`,`Center for Veterinary Medicine (US FDA)`, 0.5);
    graph.learnEnglishAcronym(`CVMP`,`Committee for Medicinal Products for Veterinary Use`, 0.5);
    graph.learnEnglishAcronym(`DARPA`,`Defense Advanced Research Projects Agency (US)`, 0.5);
    graph.learnEnglishAcronym(`DG`,`Directorate General`, 0.5);
    graph.learnEnglishAcronym(`DOD`,`Department of Defense (US)`, 0.5);
    graph.learnEnglishAcronym(`DOT`,`Department of Transportation (US)`, 0.5);
    graph.learnEnglishAcronym(`DRP`,`Detailed Review Paper (OECD)`, 0.5);
    graph.learnEnglishAcronym(`EC`,`European Commission`, 0.5);
    graph.learnEnglishAcronym(`ECB`,`European Chemicals Bureau`, 0.5);
    graph.learnEnglishAcronym(`ECHA`,`European Chemicals Agency`, 0.5);
    graph.learnEnglishAcronym(`ECOPA`,`European Consensus Platform for Alternatives`, 0.5);
    graph.learnEnglishAcronym(`ECVAM`,`European Centre for the Validation of Alternative Methods`, 0.5);
    graph.learnEnglishAcronym(`ED`,`Endocrine Disrupters`, 0.5);
    graph.learnEnglishAcronym(`EDQM`,`European Directorate for Quality of Medicines & HealthCare`, 0.5);
    graph.learnEnglishAcronym(`EEC`,`European Economic Commission`, 0.5);
    graph.learnEnglishAcronym(`EFPIA`,`European Federation of Pharmaceutical Industries and Associations`, 0.5);
    graph.learnEnglishAcronym(`EFSA`,`European Food Safety Authority`, 0.5);
    graph.learnEnglishAcronym(`EFSAPPR`,`European Food Safety Authority Panel on plant protection products and their residues`, 0.5);
    graph.learnEnglishAcronym(`EFTA`,`European Free Trade Association`, 0.5);
    graph.learnEnglishAcronym(`ELINCS`,`European List of Notified Chemical Substances`, 0.5);
    graph.learnEnglishAcronym(`ELISA`,`Enzyme-Linked ImmunoSorbent Assay`, 0.5);
    graph.learnEnglishAcronym(`EMEA`,`European Medicines Agency`, 0.5);
    graph.learnEnglishAcronym(`ENVI`,`European Parliament Committee on the Environment, Public Health and Food Safety`, 0.5);
    graph.learnEnglishAcronym(`EO`,`Executive Orders (US)`, 0.5);
    graph.learnEnglishAcronym(`EPA`,`Environmental Protection Agency (US)`, 0.5);
    graph.learnEnglishAcronym(`EPAA`,`European Partnership for Alternative Approaches to Animal Testing`, 0.5);
    graph.learnEnglishAcronym(`ESACECVAM`,`Scientific Advisory Committee (EU)`, 0.5);
    graph.learnEnglishAcronym(`ESOCOC`,`Economic and Social Council (UN)`, 0.5);
    graph.learnEnglishAcronym(`EU`,`European Union`, 0.5);
    graph.learnEnglishAcronym(`EURL`,`ECVAM European Union Reference Laboratory on Alternatives to Animal Testing`, 0.5);
    graph.learnEnglishAcronym(`EWG`,`Expert Working group`, 0.5);

    graph.learnEnglishAcronym(`FAO`,`Food and Agriculture Organization of the United Nations`, 0.5);
    graph.learnEnglishAcronym(`FDA`,`Food and Drug Administration (US)`, 0.5);
    graph.learnEnglishAcronym(`FFDCA`,`Federal Food, Drug, and Cosmetic Act (US)`, 0.5);
    graph.learnEnglishAcronym(`FHSA`,`Federal Hazardous Substances Act (US)`, 0.5);
    graph.learnEnglishAcronym(`FIFRA`,`Federal Insecticide, Fungicide, and Rodenticide Act (US)`, 0.5);
    graph.learnEnglishAcronym(`FP`,`Framework Program`, 0.5);
    graph.learnEnglishAcronym(`FRAME`,`Fund for the Replacement of Animals in Medical Experiments`, 0.5);
    graph.learnEnglishAcronym(`GCCP`,`Good Cell Culture Practice`, 0.5);
    graph.learnEnglishAcronym(`GCP`,`Good Clinical Practice`, 0.5);
    graph.learnEnglishAcronym(`GHS`,`Globally Harmonized System for Classification and Labeling of Chemicals`, 0.5);
    graph.learnEnglishAcronym(`GJIC`,`Gap Junction Intercellular Communication [assay]`, 0.5);
    graph.learnEnglishAcronym(`GLP`,`Good Laboratory Practice`, 0.5);
    graph.learnEnglishAcronym(`GMO`,`Genetically Modified Organism`, 0.5);
    graph.learnEnglishAcronym(`GMP`,`Good Manufacturing Practice`, 0.5);
    graph.learnEnglishAcronym(`GPMT`,`Guinea Pig Maximization Test`, 0.5);
    graph.learnEnglishAcronym(`HCE`,`Human corneal epithelial cells`, 0.5);
    graph.learnEnglishAcronym(`HCE`,`T Human corneal epithelial cells`, 0.5);
    graph.learnEnglishAcronym(`HESI`,`ILSI Health and Environmental Sciences Institute`, 0.5);
    graph.learnEnglishAcronym(`HET`,`CAM Hen’s Egg Test – Chorioallantoic Membrane assay`, 0.5);
    graph.learnEnglishAcronym(`HHS`,`Department of Health and Human Services (US)`, 0.5);
    graph.learnEnglishAcronym(`HIV`,`Human Immunodeficiency Virus`, 0.5);
    graph.learnEnglishAcronym(`HMPC`,`Committee on Herbal Medicinal Products`, 0.5);
    graph.learnEnglishAcronym(`HPV`,`High Production Volume`, 0.5);
    graph.learnEnglishAcronym(`HSUS`,`The Humane Society of the United States`, 0.5);
    graph.learnEnglishAcronym(`HTS`,`High Throughput Screening`, 0.5);
    graph.learnEnglishAcronym(`HGP`,`Human Genome Project`, 0.5);
    graph.learnEnglishAcronym(`IARC`,`International Agency for Research on Cancer (WHO)`, 0.5);
    graph.learnEnglishAcronym(`ICAPO`,`International Council for Animal Protection in OECD`, 0.5);
    graph.learnEnglishAcronym(`ICCVAM`,`Interagency Coordinating Committee on the Validation of Alternative Methods (US)`, 0.5);
    graph.learnEnglishAcronym(`ICE`,`Isolated Chicken Eye`, 0.5);
    graph.learnEnglishAcronym(`ICH`,`International Conference on Harmonization of Technical Requirements for Registration of Pharmaceuticals for Human Use`, 0.5);
    graph.learnEnglishAcronym(`ICSC`,`International Chemical Safety Cards`, 0.5);
    graph.learnEnglishAcronym(`IFAH`,`EUROPE International Federation for Animal Health Europe`, 0.5);
    graph.learnEnglishAcronym(`IFPMA`,`International Federation of Pharmaceutical Manufacturers & Associations`, 0.5);
    graph.learnEnglishAcronym(`IIVS`,`Institute for In Vitro Sciences`, 0.5);
    graph.learnEnglishAcronym(`ILAR`,`Institute for Laboratory Animal Research`, 0.5);
    graph.learnEnglishAcronym(`ILO`,`International Labour Organization`, 0.5);
    graph.learnEnglishAcronym(`ILSI`,`International Life Sciences Institute`, 0.5);
    graph.learnEnglishAcronym(`IND`,`Investigational New Drug (US FDA)`, 0.5);
    graph.learnEnglishAcronym(`INVITROM`,`International Society for In Vitro Methods`, 0.5);
    graph.learnEnglishAcronym(`IOMC`,`Inter-Organization Programme for the Sound Management of Chemicals (WHO)`, 0.5);
    graph.learnEnglishAcronym(`IPCS`,`International Programme on Chemical Safety (WHO)`, 0.5);
    graph.learnEnglishAcronym(`IQF`,`International QSAR Foundation to Reduce Animal Testing`, 0.5);
    graph.learnEnglishAcronym(`IRB`,`Institutional review board`, 0.5);
    graph.learnEnglishAcronym(`IRE`,`Isolated rabbit eye`, 0.5);
    graph.learnEnglishAcronym(`IWG`,`Immunotoxicity Working Group (ICCVAM)`, 0.5);
    graph.learnEnglishAcronym(`JACVAM`,`Japanese Center for the Validation of Alternative Methods`, 0.5);
    graph.learnEnglishAcronym(`JAVB`,`Japanese Association of Veterinary Biologics`, 0.5);
    graph.learnEnglishAcronym(`JECFA`,`Joint FAO/WHO Expert Committee on Food Additives`, 0.5);
    graph.learnEnglishAcronym(`JMAFF`,`Japanese Ministry of Agriculture, Forestry and Fisheries`, 0.5);
    graph.learnEnglishAcronym(`JPMA`,`Japan Pharmaceutical Manufacturers Association`, 0.5);
    graph.learnEnglishAcronym(`JRC`,`Joint Research Centre (EU)`, 0.5);
    graph.learnEnglishAcronym(`JSAAE`,`Japanese Society for Alternatives to Animal Experiments`, 0.5);
    graph.learnEnglishAcronym(`JVPA`,`Japanese Veterinary Products Association`, 0.5);

    graph.learnEnglishAcronym(`KOCVAM`,`Korean Center for the Validation of Alternative Method`, 0.5);
    graph.learnEnglishAcronym(`LIINTOP`,`Liver Intestine Optimization`, 0.5);
    graph.learnEnglishAcronym(`LLNA`,`Local Lymph Node Assay`, 0.5);
    graph.learnEnglishAcronym(`MAD`,`Mutual Acceptance of Data (OECD)`, 0.5);
    graph.learnEnglishAcronym(`MEIC`,`Multicenter Evaluation of In Vitro Cytotoxicity`, 0.5);
    graph.learnEnglishAcronym(`MEMOMEIC`,`Monographs on Time-Related Human Lethal Blood Concentrations`, 0.5);
    graph.learnEnglishAcronym(`MEPS`,`Members of the European Parliament`, 0.5);
    graph.learnEnglishAcronym(`MG`,`Milligrams [a unit of weight]`, 0.5);
    graph.learnEnglishAcronym(`MHLW`,`Ministry of Health, Labour and Welfare (Japan)`, 0.5);
    graph.learnEnglishAcronym(`MLI`,`Molecular Libraries Initiative (US NIH)`, 0.5);
    graph.learnEnglishAcronym(`MSDS`,`Material Safety Data Sheets`, 0.5);

    graph.learnEnglishAcronym(`MW`,`Molecular Weight`, 0.5);
    graph.learnEnglishAcronym(`NC3RSUK`,`National Center for the Replacement, Refinement and Reduction of Animals in Research`, 0.5);
    graph.learnEnglishAcronym(`NKCA`,`Netherlands Knowledge Centre on Alternatives to animal use`, 0.5);
    graph.learnEnglishAcronym(`NCBI`,`National Center for Biotechnology Information (US)`, 0.5);
    graph.learnEnglishAcronym(`NCEH`,`National Center for Environmental Health (US CDC)`, 0.5);
    graph.learnEnglishAcronym(`NCGCNIH`,`Chemical Genomics Center (US)`, 0.5);
    graph.learnEnglishAcronym(`NCI`,`National Cancer Institute (US NIH)`, 0.5);
    graph.learnEnglishAcronym(`NCPDCID`,`National Center for Preparedness, Detection and Control of Infectious Diseases`, 0.5);
    graph.learnEnglishAcronym(`NCCT`,`National Center for Computational Toxicology (US EPA)`, 0.5);
    graph.learnEnglishAcronym(`NCTR`,`National Center for Toxicological Research (US FDA)`, 0.5);
    graph.learnEnglishAcronym(`NDA`,`New Drug Application (US FDA)`, 0.5);
    graph.learnEnglishAcronym(`NGO`,`Non-Governmental Organization`, 0.5);
    graph.learnEnglishAcronym(`NIAID`,`National Institute of Allergy and Infectious Diseases`, 0.5);
    graph.learnEnglishAcronym(`NICA`,`Nordic Information Center for Alternative Methods`, 0.5);
    graph.learnEnglishAcronym(`NICEATM`,`National Toxicology Program Interagency Center for Evaluation of Alternative Toxicological Methods (US)`, 0.5);
    graph.learnEnglishAcronym(`NIEHS`,`National Institute of Environmental Health Sciences (US NIH)`, 0.5);
    graph.learnEnglishAcronym(`NIH`,`National Institutes of Health (US)`, 0.5);
    graph.learnEnglishAcronym(`NIHS`,`National Institute of Health Sciences (Japan)`, 0.5);
    graph.learnEnglishAcronym(`NIOSH`,`National Institute for Occupational Safety and Health (US CDC)`, 0.5);
    graph.learnEnglishAcronym(`NITR`,`National Institute of Toxicological Research (Korea)`, 0.5);
    graph.learnEnglishAcronym(`NOAEL`,`Nd-Observed Adverse Effect Level`, 0.5);
    graph.learnEnglishAcronym(`NOEL`,`Nd-Observed Effect Level`, 0.5);
    graph.learnEnglishAcronym(`NPPTAC`,`National Pollution Prevention and Toxics Advisory Committee (US EPA)`, 0.5);
    graph.learnEnglishAcronym(`NRC`,`National Research Council`, 0.5);
    graph.learnEnglishAcronym(`NTP`,`National Toxicology Program (US)`, 0.5);
    graph.learnEnglishAcronym(`OECD`,`Organisation for Economic Cooperation and Development`, 0.5);
    graph.learnEnglishAcronym(`OMCLS`,`Official Medicines Control Laboratories`, 0.5);
    graph.learnEnglishAcronym(`OPPTS`,`Office of Prevention, Pesticides and Toxic Substances (US EPA)`, 0.5);
    graph.learnEnglishAcronym(`ORF`,`open reading frame`, 0.5);
    graph.learnEnglishAcronym(`OSHA`,`Occupational Safety and Health Administration (US)`, 0.5);
    graph.learnEnglishAcronym(`OSIRIS`,`Optimized Strategies for Risk Assessment of Industrial Chemicals through the Integration of Non-test and Test Information`, 0.5);
    graph.learnEnglishAcronym(`OT`,`Cover-the-counter [drug]`, 0.5);

    graph.learnEnglishAcronym(`PBPK`,`Physiologically-Based Pharmacokinetic (modeling)`, 0.5);
    graph.learnEnglishAcronym(`P&G`,` Procter & Gamble`, 0.5);
    graph.learnEnglishAcronym(`PHRMA`,`Pharmaceutical Research and Manufacturers of America`, 0.5);
    graph.learnEnglishAcronym(`PL`,`Public Law`, 0.5);
    graph.learnEnglishAcronym(`POPS`,`Persistent Organic Pollutants`, 0.5);
    graph.learnEnglishAcronym(`QAR`, `Quantitative Structure Activity Relationship`, 0.5);
    graph.learnEnglishAcronym(`QSM`,`Quality, Safety and Efficacy of Medicines (WHO)`, 0.5);
    graph.learnEnglishAcronym(`RA`,`Regulatory Acceptance`, 0.5);
    graph.learnEnglishAcronym(`REACH`,`Registration, Evaluation, Authorization and Restriction of Chemicals`, 0.5);
    graph.learnEnglishAcronym(`RHE`,`Reconstructed Human Epidermis`, 0.5);
    graph.learnEnglishAcronym(`RIPSREACH`,`Implementation Projects`, 0.5);
    graph.learnEnglishAcronym(`RNAI`,`RNA Interference`, 0.5);
    graph.learnEnglishAcronym(`RLLNA`,`Reduced Local Lymph Node Assay`, 0.5);
    graph.learnEnglishAcronym(`SACATM`,`Scientific Advisory Committee on Alternative Toxicological Methods (US)`, 0.5);
    graph.learnEnglishAcronym(`SAICM`,`Strategic Approach to International Chemical Management (WHO)`, 0.5);
    graph.learnEnglishAcronym(`SANCO`,`Health and Consumer Protection Directorate General`, 0.5);
    graph.learnEnglishAcronym(`SCAHAW`,`Scientific Committee on Animal Health and Animal Welfare`, 0.5);
    graph.learnEnglishAcronym(`SCCP`,`Scientific Committee on Consumer Products`, 0.5);
    graph.learnEnglishAcronym(`SCENIHR`,`Scientific Committee on Emerging and Newly Identified Health Risks`, 0.5);
    graph.learnEnglishAcronym(`SCFCAH`,`Standing Committee on the Food Chain and Animal Health`, 0.5);
    graph.learnEnglishAcronym(`SCHER`,`Standing Committee on Health and Environmental Risks`, 0.5);
    graph.learnEnglishAcronym(`SEPS`,`Special Emphasis Panels (US NTP)`, 0.5);
    graph.learnEnglishAcronym(`SIDS`,`Screening Information Data Sets`, 0.5);
    graph.learnEnglishAcronym(`SOT`,`Society of Toxicology`, 0.5);
    graph.learnEnglishAcronym(`SPORT`,`Strategic Partnership on REACH Testing`, 0.5);
    graph.learnEnglishAcronym(`TBD`,`To Be Determined`, 0.5);
    graph.learnEnglishAcronym(`TDG`,`Transport of Dangerous Goods (UN committee)`, 0.5);
    graph.learnEnglishAcronym(`TER`,`Transcutaneous Electrical Resistance`, 0.5);
    graph.learnEnglishAcronym(`TEWG`,`Technical Expert Working Group`, 0.5);
    graph.learnEnglishAcronym(`TG`,`Test Guideline (OECD)`, 0.5);
    graph.learnEnglishAcronym(`TOBI`,`Toxin Binding Inhibition`, 0.5);
    graph.learnEnglishAcronym(`TSCA`,`Toxic Substances Control Act (US)`, 0.5);
    graph.learnEnglishAcronym(`TTC`,`Threshold of Toxicological Concern`, 0.5);

    graph.learnEnglishAcronym(`UC`,`University of California`, 0.5);
    graph.learnEnglishAcronym(`UCD`,`University of California Davis`, 0.5);
    graph.learnEnglishAcronym(`UK`,`United Kingdom`, 0.5);
    graph.learnEnglishAcronym(`UN`,`United Nations`, 0.5);
    graph.learnEnglishAcronym(`UNECE`,`United Nations Economic Commission for Europe`, 0.5);
    graph.learnEnglishAcronym(`UNEP`,`United Nations Environment Programme`, 0.5);
    graph.learnEnglishAcronym(`UNITAR`,`United Nations Institute for Training and Research`, 0.5);
    graph.learnEnglishAcronym(`USAMRICD`,`US Army Medical Research Institute of Chemical Defense`, 0.5);
    graph.learnEnglishAcronym(`USAMRIID`,`US Army Medical Research Institute of Infectious Diseases`, 0.5);
    graph.learnEnglishAcronym(`USAMRMC`,`US Army Medical Research and Material Command`, 0.5);
    graph.learnEnglishAcronym(`USDA`,`United States Department of Agriculture`, 0.5);
    graph.learnEnglishAcronym(`USUHS`,`Uniformed Services University of the Health Sciences`, 0.5);
    graph.learnEnglishAcronym(`UV`,`ultraviolet`, 0.5);
    graph.learnEnglishAcronym(`VCCEP`,`Voluntary Children’s Chemical Evaluation Program (US EPA)`, 0.5);
    graph.learnEnglishAcronym(`VICH`,`International Cooperation on Harmonization of Technical Requirements for Registration of Veterinary Products`, 0.5);
    graph.learnEnglishAcronym(`WHO`,`World Health Organization`, 0.5);
    graph.learnEnglishAcronym(`WRAIR`,`Walter Reed Army Institute of Research`, 0.5);
    graph.learnEnglishAcronym(`ZEBET`,`Centre for Documentation and Evaluation of Alternative Methods to Animal Experiments (Germany)`, 0.5);

    // TODO Context: Digital Communications
    graph.learnEnglishAcronym(`AAMOF`, `as a matter of fact`, 0.5);
    graph.learnEnglishAcronym(`ABFL`, `a big fat lady`, 0.5);
    graph.learnEnglishAcronym(`ABT`, `about`, 0.5);
    graph.learnEnglishAcronym(`ADN`, `any day now`, 0.5);
    graph.learnEnglishAcronym(`AFAIC`, `as far as I’m concerned`, 0.5);
    graph.learnEnglishAcronym(`AFAICT`, `as far as I can tell`, 0.5);
    graph.learnEnglishAcronym(`AFAICS`, `as far as I can see`, 0.5);
    graph.learnEnglishAcronym(`AFAIK`, `as far as I know`, 0.5);
    graph.learnEnglishAcronym(`AFAYC`, `as far as you’re concerned`, 0.5);
    graph.learnEnglishAcronym(`AFK`, `away from keyboard`, 0.5);
    graph.learnEnglishAcronym(`AH`, `asshole`, 0.5);
    graph.learnEnglishAcronym(`AISI`, `as I see it`, 0.5);
    graph.learnEnglishAcronym(`AIUI`, `as I understand it`, 0.5);
    graph.learnEnglishAcronym(`AKA`, `also known as`, 0.5);
    graph.learnEnglishAcronym(`AML`, `all my love`, 0.5);
    graph.learnEnglishAcronym(`ANFSCD`, `and now for something completely different`, 0.5);
    graph.learnEnglishAcronym(`ASAP`, `as soon as possible`, 0.5);
    graph.learnEnglishAcronym(`ASL`, `assistant section leader`, 0.5);
    graph.learnEnglishAcronym(`ASL`, `age, sex, location`, 0.5);
    graph.learnEnglishAcronym(`ASLP`, `age, sex, location, picture`, 0.5);
    graph.learnEnglishAcronym(`A/S/L`, `age/sex/location`, 0.5);
    graph.learnEnglishAcronym(`ASOP`, `assistant system operator`, 0.5);
    graph.learnEnglishAcronym(`ATM`, `at this moment`, 0.5);
    graph.learnEnglishAcronym(`AWA`, `as well as`, 0.5);
    graph.learnEnglishAcronym(`AWHFY`, `are we having fun yet?`, 0.5);
    graph.learnEnglishAcronym(`AWGTHTGTTA`, `are we going to have to go trough this again?`, 0.5);
    graph.learnEnglishAcronym(`AWOL`, `absent without leave`, 0.5);
    graph.learnEnglishAcronym(`AWOL`, `away without leave`, 0.5);
    graph.learnEnglishAcronym(`AYOR`, `at your own risk`, 0.5);
    graph.learnEnglishAcronym(`AYPI`, `?	and your point is?`, 0.5);

    graph.learnEnglishAcronym(`B4`, `before`, 0.5);
    graph.learnEnglishAcronym(`BAC`, `back at computer`, 0.5);
    graph.learnEnglishAcronym(`BAG`, `busting a gut`, 0.5);
    graph.learnEnglishAcronym(`BAK`, `back at the keyboard`, 0.5);
    graph.learnEnglishAcronym(`BBIAB`, `be back in a bit`, 0.5);
    graph.learnEnglishAcronym(`BBL`, `be back later`, 0.5);
    graph.learnEnglishAcronym(`BBLBNTSBO`, `be back later but not to soon because of`, 0.5);
    graph.learnEnglishAcronym(`BBR`, `burnt beyond repair`, 0.5);
    graph.learnEnglishAcronym(`BBS`, `be back soon`, 0.5);
    graph.learnEnglishAcronym(`BBS`, `bulletin board system`, 0.5);
    graph.learnEnglishAcronym(`BC`, `be cool`, 0.5);
    graph.learnEnglishAcronym(`B`, `/C	because`, 0.5);
    graph.learnEnglishAcronym(`BCnU`, `be seeing you`, 0.5);
    graph.learnEnglishAcronym(`BEG`, `big evil grin`, 0.5);
    graph.learnEnglishAcronym(`BF`, `boyfriend`, 0.5);
    graph.learnEnglishAcronym(`B/F`, `boyfriend`, 0.5);
    graph.learnEnglishAcronym(`BFN`, `bye for now`, 0.5);
    graph.learnEnglishAcronym(`BG`, `big grin`, 0.5);
    graph.learnEnglishAcronym(`BION`, `believe it or not`, 0.5);
    graph.learnEnglishAcronym(`BIOYIOB`, `blow it out your I/O port`, 0.5);
    graph.learnEnglishAcronym(`BITMT`, `but in the meantime`, 0.5);
    graph.learnEnglishAcronym(`BM`, `bite me`, 0.5);
    graph.learnEnglishAcronym(`BMB`, `bite my bum`, 0.5);
    graph.learnEnglishAcronym(`BMTIPG`, `brilliant minds think in parallel gutters`, 0.5);
    graph.learnEnglishAcronym(`BKA`, `better known as`, 0.5);
    graph.learnEnglishAcronym(`BL`, `belly laughing`, 0.5);
    graph.learnEnglishAcronym(`BOB`, `back off bastard`, 0.5);
    graph.learnEnglishAcronym(`BOL`, `be on later`, 0.5);
    graph.learnEnglishAcronym(`BOM`, `bitch of mine`, 0.5);
    graph.learnEnglishAcronym(`BOT`, `back on topic`, 0.5);
    graph.learnEnglishAcronym(`BRB`, `be right back`, 0.5);
    graph.learnEnglishAcronym(`BRBB`, `be right back bitch`, 0.5);
    graph.learnEnglishAcronym(`BRBS`, `be right back soon`, 0.5);
    graph.learnEnglishAcronym(`BRH`, `be right here`, 0.5);
    graph.learnEnglishAcronym(`BRS`, `big red switch`, 0.5);
    graph.learnEnglishAcronym(`BS`, `big smile`, 0.5);
    graph.learnEnglishAcronym(`BS`, `bull shit`, 0.5);
    graph.learnEnglishAcronym(`BSF`, `but seriously folks`, 0.5);
    graph.learnEnglishAcronym(`BST`, `but seriously though`, 0.5);
    graph.learnEnglishAcronym(`BTA`, `but then again`, 0.5);
    graph.learnEnglishAcronym(`BTAIM`, `be that as it may`, 0.5);
    graph.learnEnglishAcronym(`BTDT`, `been there done that`, 0.5);
    graph.learnEnglishAcronym(`BTOBD`, `be there or be dead`, 0.5);
    graph.learnEnglishAcronym(`BTOBS`, `be there or be square`, 0.5);
    graph.learnEnglishAcronym(`BTSOOM`, `beats the shit out of me`, 0.5);
    graph.learnEnglishAcronym(`BTW`, `by the way`, 0.5);
    graph.learnEnglishAcronym(`BUDWEISER`, `because you deserve what every individual should ever receive`, 0.5);
    graph.learnEnglishAcronym(`BWQ`, `buzz word quotient`, 0.5);
    graph.learnEnglishAcronym(`BWTHDIK`, `but what the heck do I know`, 0.5);
    graph.learnEnglishAcronym(`BYOB`, `bring your own bottle`, 0.5);
    graph.learnEnglishAcronym(`BYOH`, `Bat You Onna Head`, 0.5);

    graph.learnEnglishAcronym(`C&G`, `chuckle and grin`, 0.5);
    graph.learnEnglishAcronym(`CAD`, `ctrl-alt-delete`, 0.5);
    graph.learnEnglishAcronym(`CADET`, `can’t add, doesn’t even try`, 0.5);
    graph.learnEnglishAcronym(`CDIWY`, `couldn’t do it without you`, 0.5);
    graph.learnEnglishAcronym(`CFV`, `call for votes`, 0.5);
    graph.learnEnglishAcronym(`CFS`, `care for secret?`, 0.5);
    graph.learnEnglishAcronym(`CFY`, `calling for you`, 0.5);
    graph.learnEnglishAcronym(`CID`, `crying in disgrace`, 0.5);
    graph.learnEnglishAcronym(`CIM`, `CompuServe information manager`, 0.5);
    graph.learnEnglishAcronym(`CLM`, `career limiting move`, 0.5);
    graph.learnEnglishAcronym(`CM@TW`, `catch me at the web`, 0.5);
    graph.learnEnglishAcronym(`CMIIW`, `correct me if I’m wrong`, 0.5);
    graph.learnEnglishAcronym(`CNP`, `continue in next post`, 0.5);
    graph.learnEnglishAcronym(`CO`, `conference`, 0.5);
    graph.learnEnglishAcronym(`CRAFT`, `can’t remember a f**king thing`, 0.5);
    graph.learnEnglishAcronym(`CRS`, `can’t remember shit`, 0.5);
    graph.learnEnglishAcronym(`CSG`, `chuckle snicker grin`, 0.5);
    graph.learnEnglishAcronym(`CTS`, `changing the subject`, 0.5);
    graph.learnEnglishAcronym(`CU`, `see you`, 0.5);
    graph.learnEnglishAcronym(`CU2`, `see you too`, 0.5);
    graph.learnEnglishAcronym(`CUL`, `see you later`, 0.5);
    graph.learnEnglishAcronym(`CUL8R`, `see you later`, 0.5);
    graph.learnEnglishAcronym(`CWOT`, `complete waste of time`, 0.5);
    graph.learnEnglishAcronym(`CWYL`, `chat with you later`, 0.5);
    graph.learnEnglishAcronym(`CYA`, `see ya`, 0.5);
    graph.learnEnglishAcronym(`CYA`, `cover your ass`, 0.5);
    graph.learnEnglishAcronym(`CYAL8R`, `see ya later`, 0.5);
    graph.learnEnglishAcronym(`CYO`, `see you online`, 0.5);

    graph.learnEnglishAcronym(`DBA`, `doing business as`, 0.5);
    graph.learnEnglishAcronym(`DCed`, `disconnected`, 0.5);
    graph.learnEnglishAcronym(`DFLA`, `disenhanced four-letter acronym`, 0.5);
    graph.learnEnglishAcronym(`DH`, `darling husband`, 0.5);
    graph.learnEnglishAcronym(`DIIK`, `darn if i know`, 0.5);
    graph.learnEnglishAcronym(`DGA`, `digital guardian angel`, 0.5);
    graph.learnEnglishAcronym(`DGARA`, `don’t give a rats ass`, 0.5);
    graph.learnEnglishAcronym(`DIKU`, `do I know you?`, 0.5);
    graph.learnEnglishAcronym(`DIRTFT`, `do it right the first time`, 0.5);
    graph.learnEnglishAcronym(`DITYID`, `did I tell you I’m distressed`, 0.5);
    graph.learnEnglishAcronym(`DIY`, `do it yourself`, 0.5);
    graph.learnEnglishAcronym(`DL`, `download`, 0.5);
    graph.learnEnglishAcronym(`DL`, `dead link`, 0.5);
    graph.learnEnglishAcronym(`DLTBBB`, `don’t let the bad bugs bite`, 0.5);
    graph.learnEnglishAcronym(`DMMGH`, `don’t make me get hostile`, 0.5);
    graph.learnEnglishAcronym(`DQMOT`, `don’t quote me on this`, 0.5);
    graph.learnEnglishAcronym(`DND`, `do not disturb`, 0.5);
    graph.learnEnglishAcronym(`DTC`, `damn this computer`, 0.5);
    graph.learnEnglishAcronym(`DTRT`, `do the right thing`, 0.5);
    graph.learnEnglishAcronym(`DUCT`, `did you see that?`, 0.5);
    graph.learnEnglishAcronym(`DWAI`, `don’t worry about it`, 0.5);
    graph.learnEnglishAcronym(`DWIM`, `do what I mean`, 0.5);
    graph.learnEnglishAcronym(`DWIMC`, `do what I mean, correctly`, 0.5);
    graph.learnEnglishAcronym(`DWISNWID`, `do what I say, not what I do`, 0.5);
    graph.learnEnglishAcronym(`DYJHIW`, `don’t you just hate it when...`, 0.5);
    graph.learnEnglishAcronym(`DYK`, `do you know`, 0.5);

    graph.learnEnglishAcronym(`EAK`, `eating at keyboard`, 0.5);
    graph.learnEnglishAcronym(`EIE`, `enough is enough`, 0.5);
    graph.learnEnglishAcronym(`EG`, `evil grin`, 0.5);
    graph.learnEnglishAcronym(`EMFBI`, `excuse me for butting in`, 0.5);
    graph.learnEnglishAcronym(`EMFJI`, `excuse me for jumping in`, 0.5);
    graph.learnEnglishAcronym(`EMSG`, `email message`, 0.5);
    graph.learnEnglishAcronym(`EOD`, `end of discussion`, 0.5);
    graph.learnEnglishAcronym(`EOF`, `end of file`, 0.5);
    graph.learnEnglishAcronym(`EOL`, `end of lecture`, 0.5);
    graph.learnEnglishAcronym(`EOM`, `end of message`, 0.5);
    graph.learnEnglishAcronym(`EOS`, `end of story`, 0.5);
    graph.learnEnglishAcronym(`EOT`, `end of thread`, 0.5);
    graph.learnEnglishAcronym(`ETLA`, `extended three letter acronym`, 0.5);
    graph.learnEnglishAcronym(`EYC`, `excitable, yet calm`, 0.5);

    graph.learnEnglishAcronym(`F`, `female`, 0.5);
    graph.learnEnglishAcronym(`F/F`, `face to face`, 0.5);
    graph.learnEnglishAcronym(`F2F`, `face to face`, 0.5);
    graph.learnEnglishAcronym(`FAQ`, `frequently asked questions`, 0.5);
    graph.learnEnglishAcronym(`FAWC`, `for anyone who cares`, 0.5);
    graph.learnEnglishAcronym(`FBOW`, `for better or worse`, 0.5);
    graph.learnEnglishAcronym(`FBTW`, `fine, be that way`, 0.5);
    graph.learnEnglishAcronym(`FCFS`, `first come, first served`, 0.5);
    graph.learnEnglishAcronym(`FCOL`, `for crying out loud`, 0.5);
    graph.learnEnglishAcronym(`FIFO`, `first in, first out`, 0.5);
    graph.learnEnglishAcronym(`FISH`, `first in, still here`, 0.5);
    graph.learnEnglishAcronym(`FLA`, `four-letter acronym`, 0.5);
    graph.learnEnglishAcronym(`FOAD`, `f**k off and die`, 0.5);
    graph.learnEnglishAcronym(`FOAF`, `friend of a friend`, 0.5);
    graph.learnEnglishAcronym(`FOB`, `f**k off bitch`, 0.5);
    graph.learnEnglishAcronym(`FOC`, `free of charge`, 0.5);
    graph.learnEnglishAcronym(`FOCL`, `falling of chair laughing`, 0.5);
    graph.learnEnglishAcronym(`FOFL`, `falling on the floor laughing`, 0.5);
    graph.learnEnglishAcronym(`FOS`, `freedom of speech`, 0.5);
    graph.learnEnglishAcronym(`FOTCL`, `falling of the chair laughing`, 0.5);
    graph.learnEnglishAcronym(`FTF`, `face to face`, 0.5);
    graph.learnEnglishAcronym(`FTTT`, `from time to time`, 0.5);
    graph.learnEnglishAcronym(`FU`, `f**ked up`, 0.5);
    graph.learnEnglishAcronym(`FUBAR`, `f**ked up beyond all recognition`, 0.5);
    graph.learnEnglishAcronym(`FUDFUCT`, `fear, uncertainty and doubt`, 0.5);
    graph.learnEnglishAcronym(`FUCT`, `failed under continuas testing`, 0.5);
    graph.learnEnglishAcronym(`FURTB`, `full up ready to burst (about hard disk drives)`, 0.5);
    graph.learnEnglishAcronym(`FW`, `freeware`, 0.5);
    graph.learnEnglishAcronym(`FWIW`, `for what it’s worth`, 0.5);
    graph.learnEnglishAcronym(`FYA`, `for your amusement`, 0.5);
    graph.learnEnglishAcronym(`FYE`, `for your entertainment`, 0.5);
    graph.learnEnglishAcronym(`FYEO`, `for your eyes only`, 0.5);
    graph.learnEnglishAcronym(`FYI`, `for your information`, 0.5);

    graph.learnEnglishAcronym(`G`, `grin`, 0.5);
    graph.learnEnglishAcronym(`G2B`,`going to bed`, 0.5);
    graph.learnEnglishAcronym(`G&BIT`, `grin & bear it`, 0.5);
    graph.learnEnglishAcronym(`G2G`, `got to go`, 0.5);
    graph.learnEnglishAcronym(`G2GGS2D`, `got to go get something to drink`, 0.5);
    graph.learnEnglishAcronym(`G2GTAC`, `got to go take a crap`, 0.5);
    graph.learnEnglishAcronym(`G2GTAP`, `got to go take a pee`, 0.5);
    graph.learnEnglishAcronym(`GA`, `go ahead`, 0.5);
    graph.learnEnglishAcronym(`GA`, `good afternoon`, 0.5);
    graph.learnEnglishAcronym(`GAFIA`, `get away from it all`, 0.5);
    graph.learnEnglishAcronym(`GAL`, `get a life`, 0.5);
    graph.learnEnglishAcronym(`GAS`, `greetings and salutations`, 0.5);
    graph.learnEnglishAcronym(`GBH`, `great big hug`, 0.5);
    graph.learnEnglishAcronym(`GBH&K`, `great big huh and kisses`, 0.5);
    graph.learnEnglishAcronym(`GBR`, `garbled beyond recovery`, 0.5);
    graph.learnEnglishAcronym(`GBY`, `god bless you`, 0.5);
    graph.learnEnglishAcronym(`GD`, `&H	grinning, ducking and hiding`, 0.5);
    graph.learnEnglishAcronym(`GD&R`, `grinning, ducking and running`, 0.5);
    graph.learnEnglishAcronym(`GD&RAFAP`, `grinning, ducking and running as fast as possible`, 0.5);
    graph.learnEnglishAcronym(`GD&REF&F`, `grinning, ducking and running even further and faster`, 0.5);
    graph.learnEnglishAcronym(`GD&RF`, `grinning, ducking and running fast`, 0.5);
    graph.learnEnglishAcronym(`GD&RVF`, `grinning, ducking and running very`, 0.5);
    graph.learnEnglishAcronym(`GD&W`, `grin, duck and wave`, 0.5);
    graph.learnEnglishAcronym(`GDW`, `grin, duck and wave`, 0.5);
    graph.learnEnglishAcronym(`GE`, `good evening`, 0.5);
    graph.learnEnglishAcronym(`GF`, `girlfriend`, 0.5);
    graph.learnEnglishAcronym(`GFETE`, `grinning from ear to ear`, 0.5);
    graph.learnEnglishAcronym(`GFN`, `gone for now`, 0.5);
    graph.learnEnglishAcronym(`GFU`, `good for you`, 0.5);
    graph.learnEnglishAcronym(`GG`, `good game`, 0.5);
    graph.learnEnglishAcronym(`GGU`, `good game you two`, 0.5);
    graph.learnEnglishAcronym(`GIGO`, `garbage in garbage out`, 0.5);
    graph.learnEnglishAcronym(`GJ`, `good job`, 0.5);
    graph.learnEnglishAcronym(`GL`, `good luck`, 0.5);
    graph.learnEnglishAcronym(`GL&GH`, `good luck and good hunting`, 0.5);
    graph.learnEnglishAcronym(`GM`, `good morning / good move / good match`, 0.5);
    graph.learnEnglishAcronym(`GMAB`, `give me a break`, 0.5);
    graph.learnEnglishAcronym(`GMAO`, `giggling my ass off`, 0.5);
    graph.learnEnglishAcronym(`GMBO`, `giggling my butt off`, 0.5);
    graph.learnEnglishAcronym(`GMTA`, `great minds think alike`, 0.5);
    graph.learnEnglishAcronym(`GN`, `good night`, 0.5);
    graph.learnEnglishAcronym(`GOK`, `god only knows`, 0.5);
    graph.learnEnglishAcronym(`GOWI`, `get on with it`, 0.5);
    graph.learnEnglishAcronym(`GPF`, `general protection fault`, 0.5);
    graph.learnEnglishAcronym(`GR8`, `great`, 0.5);
    graph.learnEnglishAcronym(`GR&D`, `grinning, running and ducking`, 0.5);
    graph.learnEnglishAcronym(`GtG`, `got to go`, 0.5);
    graph.learnEnglishAcronym(`GTSY`, `glad to see you`, 0.5);

    graph.learnEnglishAcronym(`H`, `hug`, 0.5);
    graph.learnEnglishAcronym(`H/O`, `hold on`, 0.5);
    graph.learnEnglishAcronym(`H&K`, `hug and kiss`, 0.5);
    graph.learnEnglishAcronym(`HAK`, `hug and kiss`, 0.5);
    graph.learnEnglishAcronym(`HAGD`, `have a good day`, 0.5);
    graph.learnEnglishAcronym(`HAGN`, `have a good night`, 0.5);
    graph.learnEnglishAcronym(`HAGS`, `have a good summer`, 0.5);
    graph.learnEnglishAcronym(`HAG1`, `have a good one`, 0.5);
    graph.learnEnglishAcronym(`HAHA`, `having a heart attack`, 0.5);
    graph.learnEnglishAcronym(`HAND`, `have a nice day`, 0.5);
    graph.learnEnglishAcronym(`HB`, `hug back`, 0.5);
    graph.learnEnglishAcronym(`HB`, `hurry back`, 0.5);
    graph.learnEnglishAcronym(`HDYWTDT`, `how do you work this dratted thing`, 0.5);
    graph.learnEnglishAcronym(`HF`, `have fun`, 0.5);
    graph.learnEnglishAcronym(`HH`, `holding hands`, 0.5);
    graph.learnEnglishAcronym(`HHIS`, `hanging head in shame`, 0.5);
    graph.learnEnglishAcronym(`HHJK`, `ha ha, just kidding`, 0.5);
    graph.learnEnglishAcronym(`HHOJ`, `ha ha, only joking`, 0.5);
    graph.learnEnglishAcronym(`HHOK`, `ha ha, only kidding`, 0.5);
    graph.learnEnglishAcronym(`HHOS`, `ha ha, only seriously`, 0.5);
    graph.learnEnglishAcronym(`HIH`, `hope it helps`, 0.5);
    graph.learnEnglishAcronym(`HILIACACLO`, `help I lapsed into a coma and can’t log off`, 0.5);
    graph.learnEnglishAcronym(`HIWTH`, `hate it when that happens`, 0.5);
    graph.learnEnglishAcronym(`HLM`, `he loves me`, 0.5);
    graph.learnEnglishAcronym(`HMS`, `home made smiley`, 0.5);
    graph.learnEnglishAcronym(`HMS`, `hanging my self`, 0.5);
    graph.learnEnglishAcronym(`HMT`, `here’s my try`, 0.5);
    graph.learnEnglishAcronym(`HMWK`, `homework`, 0.5);
    graph.learnEnglishAcronym(`HOAS`, `hold on a second`, 0.5);
    graph.learnEnglishAcronym(`HSIK`, `how should i know`, 0.5);
    graph.learnEnglishAcronym(`HTH`, `hope this helps`, 0.5);
    graph.learnEnglishAcronym(`HTHBE`, `hope this has been enlightening`, 0.5);
    graph.learnEnglishAcronym(`HYLMS`, `hate you like my sister`, 0.5);

    graph.learnEnglishAcronym(`IAAA`, `I am an accountant`, 0.5);
    graph.learnEnglishAcronym(`IAAL`, `I am a lawyer`, 0.5);
    graph.learnEnglishAcronym(`IAC`, `in any case`, 0.5);
    graph.learnEnglishAcronym(`IC`, `I see`, 0.5);
    graph.learnEnglishAcronym(`IAE`, `in any event`, 0.5);
    graph.learnEnglishAcronym(`IAG`, `it’s all good`, 0.5);
    graph.learnEnglishAcronym(`IAG`, `I am gay`, 0.5);
    graph.learnEnglishAcronym(`IAIM`, `in an Irish minute`, 0.5);
    graph.learnEnglishAcronym(`IANAA`, `I am not an accountant`, 0.5);
    graph.learnEnglishAcronym(`IANAL`, `I am not a lawyer`, 0.5);
    graph.learnEnglishAcronym(`IBN`, `I’m bucked naked`, 0.5);
    graph.learnEnglishAcronym(`ICOCBW`, `I could of course be wrong`, 0.5);
    graph.learnEnglishAcronym(`IDC`, `I don’t care`, 0.5);
    graph.learnEnglishAcronym(`IDGI`, `I don’t get it`, 0.5);
    graph.learnEnglishAcronym(`IDGARA`, `I don’t give a rat’s ass`, 0.5);
    graph.learnEnglishAcronym(`IDGW`, `in a good way`, 0.5);
    graph.learnEnglishAcronym(`IDI`, `I doubt it`, 0.5);
    graph.learnEnglishAcronym(`IDK`, `I don’t know`, 0.5);
    graph.learnEnglishAcronym(`IDTT`, `I’ll drink to that`, 0.5);
    graph.learnEnglishAcronym(`IFVB`, `I feel very bad`, 0.5);
    graph.learnEnglishAcronym(`IGP`, `I gotta pee`, 0.5);
    graph.learnEnglishAcronym(`IGTP`, `I get the point`, 0.5);
    graph.learnEnglishAcronym(`IHTFP`, `I hate this f**king place`, 0.5);
    graph.learnEnglishAcronym(`IHTFP`, `I have truly found paradise`, 0.5);
    graph.learnEnglishAcronym(`IHU`, `I hate you`, 0.5);
    graph.learnEnglishAcronym(`IHY`, `I hate you`, 0.5);
    graph.learnEnglishAcronym(`II`, `I’m impressed`, 0.5);
    graph.learnEnglishAcronym(`IIT`, `I’m impressed too`, 0.5);
    graph.learnEnglishAcronym(`IIR`, `if I recall`, 0.5);
    graph.learnEnglishAcronym(`IIRC`, `if I recall correctly`, 0.5);
    graph.learnEnglishAcronym(`IJWTK`, `I just want to know`, 0.5);
    graph.learnEnglishAcronym(`IJWTS`, `I just want to say`, 0.5);
    graph.learnEnglishAcronym(`IK`, `I know`, 0.5);
    graph.learnEnglishAcronym(`IKWUM`, `I know what you mean`, 0.5);
    graph.learnEnglishAcronym(`ILBCNU`, `I’ll be seeing you`, 0.5);
    graph.learnEnglishAcronym(`ILU`, `I love you`, 0.5);
    graph.learnEnglishAcronym(`ILY`, `I love you`, 0.5);
    graph.learnEnglishAcronym(`ILYFAE`, `I love you forever and ever`, 0.5);
    graph.learnEnglishAcronym(`IMAO`, `in my arrogant opinion`, 0.5);
    graph.learnEnglishAcronym(`IMFAO`, `in my f***ing arrogant opinion`, 0.5);
    graph.learnEnglishAcronym(`IMBO`, `in my bloody opinion`, 0.5);
    graph.learnEnglishAcronym(`IMCO`, `in my considered opinion`, 0.5);
    graph.learnEnglishAcronym(`IME`, `in my experience`, 0.5);
    graph.learnEnglishAcronym(`IMHO`, `in my humble opinion`, 0.5);
    graph.learnEnglishAcronym(`IMNSHO`, `in my, not so humble opinion`, 0.5);
    graph.learnEnglishAcronym(`IMO`, `in my opinion`, 0.5);
    graph.learnEnglishAcronym(`IMOBO`, `in my own biased opinion`, 0.5);
    graph.learnEnglishAcronym(`IMPOV`, `in my point of view`, 0.5);
    graph.learnEnglishAcronym(`IMP`, `I might be pregnant`, 0.5);
    graph.learnEnglishAcronym(`INAL`, `I’m not a lawyer`, 0.5);
    graph.learnEnglishAcronym(`INPO`, `in no particular order`, 0.5);
    graph.learnEnglishAcronym(`IOIT`, `I’m on Irish Time`, 0.5);
    graph.learnEnglishAcronym(`IOW`, `in other words`, 0.5);
    graph.learnEnglishAcronym(`IRL`, `in real life`, 0.5);
    graph.learnEnglishAcronym(`IRMFI`, `I reply merely for information`, 0.5);
    graph.learnEnglishAcronym(`IRSTBO`, `it really sucks the big one`, 0.5);
    graph.learnEnglishAcronym(`IS`, `I’m sorry`, 0.5);
    graph.learnEnglishAcronym(`ISEN`, `internet search environment number`, 0.5);
    graph.learnEnglishAcronym(`ISTM`, `it seems to me`, 0.5);
    graph.learnEnglishAcronym(`ISTR`, `I seem to recall`, 0.5);
    graph.learnEnglishAcronym(`ISWYM`, `I see what you mean`, 0.5);
    graph.learnEnglishAcronym(`ITFA`, `in the final analysis`, 0.5);
    graph.learnEnglishAcronym(`ITRO`, `in the reality of`, 0.5);
    graph.learnEnglishAcronym(`ITRW`, `in the real world`, 0.5);
    graph.learnEnglishAcronym(`ITSFWI`, `if the shoe fits, wear it`, 0.5);
    graph.learnEnglishAcronym(`IVL`, `in virtual live`, 0.5);
    graph.learnEnglishAcronym(`IWALY`, `I will always love you`, 0.5);
    graph.learnEnglishAcronym(`IWBNI`, `it would be nice if`, 0.5);
    graph.learnEnglishAcronym(`IYKWIM`, `if you know what I mean`, 0.5);
    graph.learnEnglishAcronym(`IYSWIM`, `if you see what I mean`, 0.5);

    graph.learnEnglishAcronym(`JAM`, `just a minute`, 0.5);
    graph.learnEnglishAcronym(`JAS`, `just a second`, 0.5);
    graph.learnEnglishAcronym(`JASE`, `just another system error`, 0.5);
    graph.learnEnglishAcronym(`JAWS`, `just another windows shell`, 0.5);
    graph.learnEnglishAcronym(`JIC`, `just in case`, 0.5);
    graph.learnEnglishAcronym(`JJWY`, `just joking with you`, 0.5);
    graph.learnEnglishAcronym(`JK`, `just kidding`, 0.5);
    graph.learnEnglishAcronym(`J/K`, `just kidding`, 0.5);
    graph.learnEnglishAcronym(`JMHO`, `just my humble opinion`, 0.5);
    graph.learnEnglishAcronym(`JMO`, `just my opinion`, 0.5);
    graph.learnEnglishAcronym(`JP`, `just playing`, 0.5);
    graph.learnEnglishAcronym(`J/P`, `just playing`, 0.5);
    graph.learnEnglishAcronym(`JTLYK`, `just to let you know`, 0.5);
    graph.learnEnglishAcronym(`JW`, `just wondering`, 0.5);

    graph.learnEnglishAcronym(`K`, `OK`, 0.5);
    graph.learnEnglishAcronym(`K`, `kiss`, 0.5);
    graph.learnEnglishAcronym(`KHYF`, `know how you feel`, 0.5);
    graph.learnEnglishAcronym(`KB`, `kiss back`, 0.5);
    graph.learnEnglishAcronym(`KISS`, `keep it simple sister`, 0.5);
    graph.learnEnglishAcronym(`KIS(S)`, `keep it simple (stupid)`, 0.5);
    graph.learnEnglishAcronym(`KISS`, `keeping it sweetly simple`, 0.5);
    graph.learnEnglishAcronym(`KIT`, `keep in touch`, 0.5);
    graph.learnEnglishAcronym(`KMA`, `kiss my ass`, 0.5);
    graph.learnEnglishAcronym(`KMB`, `kiss my butt`, 0.5);
    graph.learnEnglishAcronym(`KMSMA`, `kiss my shiny metal ass`, 0.5);
    graph.learnEnglishAcronym(`KOTC`, `kiss on the cheek`, 0.5);
    graph.learnEnglishAcronym(`KOTL`, `kiss on the lips`, 0.5);
    graph.learnEnglishAcronym(`KUTGW`, `keep up the good work`, 0.5);
    graph.learnEnglishAcronym(`KWIM`, `know what I mean?`, 0.5);

    graph.learnEnglishAcronym(`L`, `laugh`, 0.5);
    graph.learnEnglishAcronym(`L8R`, `later`, 0.5);
    graph.learnEnglishAcronym(`L8R`, `G8R	later gator`, 0.5);
    graph.learnEnglishAcronym(`LAB`, `life’s a bitch`, 0.5);
    graph.learnEnglishAcronym(`LAM`, `leave a message`, 0.5);
    graph.learnEnglishAcronym(`LBR`, `little boys room`, 0.5);
    graph.learnEnglishAcronym(`LD`, `long distance`, 0.5);
    graph.learnEnglishAcronym(`LIMH`, `laughing in my head`, 0.5);
    graph.learnEnglishAcronym(`LG`, `lovely greetings`, 0.5);
    graph.learnEnglishAcronym(`LIMH`, `laughing in my head`, 0.5);
    graph.learnEnglishAcronym(`LGR`, `little girls room`, 0.5);
    graph.learnEnglishAcronym(`LHM`, `Lord help me`, 0.5);
    graph.learnEnglishAcronym(`LHU`, `Lord help us`, 0.5);
    graph.learnEnglishAcronym(`LL&P`, `live long & prosper`, 0.5);
    graph.learnEnglishAcronym(`LNK`, `love and kisses`, 0.5);
    graph.learnEnglishAcronym(`LMA`, `leave me alone`, 0.5);
    graph.learnEnglishAcronym(`LMABO`, `laughing my ass back on`, 0.5);
    graph.learnEnglishAcronym(`LMAO`, `laughing my ass off`, 0.5);
    graph.learnEnglishAcronym(`MBO`, `laughing my butt off`, 0.5);
    graph.learnEnglishAcronym(`LMHO`, `laughing my head off`, 0.5);
    graph.learnEnglishAcronym(`LMFAO`, `laughing my fat ass off`, 0.5);
    graph.learnEnglishAcronym(`LMK`, `let me know`, 0.5);
    graph.learnEnglishAcronym(`LOL`, `laughing out loud`, 0.5);
    graph.learnEnglishAcronym(`LOL`, `lots of love`, 0.5);
    graph.learnEnglishAcronym(`LOL`, `lots of luck`, 0.5);
    graph.learnEnglishAcronym(`LOLA`, `laughing out loud again`, 0.5);
    graph.learnEnglishAcronym(`LOML`, `light of my life (or love of my life)`, 0.5);
    graph.learnEnglishAcronym(`LOMLILY`, `light of my life, I love you`, 0.5);
    graph.learnEnglishAcronym(`LOOL`, `laughing out outrageously loud`, 0.5);
    graph.learnEnglishAcronym(`LSHIPMP`, `laughing so hard I pissed my pants`, 0.5);
    graph.learnEnglishAcronym(`LSHMBB`, `laughing so hard my belly is bouncing`, 0.5);
    graph.learnEnglishAcronym(`LSHMBH`, `laughing so hard my belly hurts`, 0.5);
    graph.learnEnglishAcronym(`LTNS`, `long time no see`, 0.5);
    graph.learnEnglishAcronym(`LTR`, `long term relationship`, 0.5);
    graph.learnEnglishAcronym(`LTS`, `laughing to self`, 0.5);
    graph.learnEnglishAcronym(`LULAS`, `love you like a sister`, 0.5);
    graph.learnEnglishAcronym(`LUWAMH`, `love you with all my heart`, 0.5);
    graph.learnEnglishAcronym(`LY`, `love ya`, 0.5);
    graph.learnEnglishAcronym(`LYK`, `let you know`, 0.5);
    graph.learnEnglishAcronym(`LYL`, `love ya lots`, 0.5);
    graph.learnEnglishAcronym(`LYLAB`, `love ya like a brother`, 0.5);
    graph.learnEnglishAcronym(`LYLAS`, `love ya like a sister`, 0.5);

    graph.learnEnglishAcronym(`M`, `male`, 0.5);
    graph.learnEnglishAcronym(`MB`, `maybe`, 0.5);
    graph.learnEnglishAcronym(`MYOB`, `mind your own business`, 0.5);
    graph.learnEnglishAcronym(`M8`, `mate`, 0.5);

    graph.learnEnglishAcronym(`N`, `in`, 0.5);
    graph.learnEnglishAcronym(`N2M`, `not too much`, 0.5);
    graph.learnEnglishAcronym(`N/C`, `not cool`, 0.5);
    graph.learnEnglishAcronym(`NE1`, `anyone`, 0.5);
    graph.learnEnglishAcronym(`NETUA`, `nobody ever tells us anything`, 0.5);
    graph.learnEnglishAcronym(`NFI`, `no f***ing idea`, 0.5);
    graph.learnEnglishAcronym(`NL`, `not likely`, 0.5);
    graph.learnEnglishAcronym(`NM`, `never mind / nothing much`, 0.5);
    graph.learnEnglishAcronym(`N/M`, `never mind / nothing much`, 0.5);
    graph.learnEnglishAcronym(`NMH`, `not much here`, 0.5);
    graph.learnEnglishAcronym(`NMJC`, `nothing much, just chillin’`, 0.5);
    graph.learnEnglishAcronym(`NOM`, `no offense meant`, 0.5);
    graph.learnEnglishAcronym(`NOTTOMH`, `not of the top of my mind`, 0.5);
    graph.learnEnglishAcronym(`NOYB`, `none of your business`, 0.5);
    graph.learnEnglishAcronym(`NOYFB`, `none of your f***ing business`, 0.5);
    graph.learnEnglishAcronym(`NP`, `no problem`, 0.5);
    graph.learnEnglishAcronym(`NPS`, `no problem sweet(ie)`, 0.5);
    graph.learnEnglishAcronym(`NTA`, `non-technical acronym`, 0.5);
    graph.learnEnglishAcronym(`N/S`, `no shit`, 0.5);
    graph.learnEnglishAcronym(`NVM`, `nevermind`, 0.5);

    graph.learnEnglishAcronym(`OBTW`, `oh, by the way`, 0.5);
    graph.learnEnglishAcronym(`OIC`, `oh, I see`, 0.5);
    graph.learnEnglishAcronym(`OF`, `on fire`, 0.5);
    graph.learnEnglishAcronym(`OFIS`, `on floor with stitches`, 0.5);
    graph.learnEnglishAcronym(`OK`, `abbreviation of oll korrect (all correct)`, 0.5);
    graph.learnEnglishAcronym(`OL`, `old lady (wife, girlfriend)`, 0.5);
    graph.learnEnglishAcronym(`OM`, `old man (husband, boyfriend)`, 0.5);
    graph.learnEnglishAcronym(`OMG`, `oh my god / gosh / goodness`, 0.5);
    graph.learnEnglishAcronym(`OOC`, `out of character`, 0.5);
    graph.learnEnglishAcronym(`OT`, `Off topic / other topic`, 0.5);
    graph.learnEnglishAcronym(`OTOH`, `on the other hand`, 0.5);
    graph.learnEnglishAcronym(`OTTOMH`, `off the top of my head`, 0.5);

    graph.learnEnglishAcronym(`P@H`, `parents at home`, 0.5);
    graph.learnEnglishAcronym(`PAH`, `parents at home`, 0.5);
    graph.learnEnglishAcronym(`PAW`, `parents are watching`, 0.5);
    graph.learnEnglishAcronym(`PDS`, `please don’t shoot`, 0.5);
    graph.learnEnglishAcronym(`PEBCAK`, `problem exists between chair and keyboard`, 0.5);
    graph.learnEnglishAcronym(`PIZ`, `parents in room`, 0.5);
    graph.learnEnglishAcronym(`PLZ`, `please`, 0.5);
    graph.learnEnglishAcronym(`PM`, `private message`, 0.5);
    graph.learnEnglishAcronym(`PMJI`, `pardon my jumping in (Another way for PMFJI)`, 0.5);
    graph.learnEnglishAcronym(`PMFJI`, `pardon me for jumping in`, 0.5);
    graph.learnEnglishAcronym(`PMP`, `peed my pants`, 0.5);
    graph.learnEnglishAcronym(`POAHF`, `put on a happy face`, 0.5);
    graph.learnEnglishAcronym(`POOF`, `I have left the chat`, 0.5);
    graph.learnEnglishAcronym(`POTB`, `pats on the back`, 0.5);
    graph.learnEnglishAcronym(`POS`, `parents over shoulder`, 0.5);
    graph.learnEnglishAcronym(`PPL`, `people`, 0.5);
    graph.learnEnglishAcronym(`PS`, `post script`, 0.5);
    graph.learnEnglishAcronym(`PSA`, `public show of affection`, 0.5);

    graph.learnEnglishAcronym(`Q4U`, `question for you`, 0.5);
    graph.learnEnglishAcronym(`QSL`, `reply`, 0.5);
    graph.learnEnglishAcronym(`QSO`, `conversation`, 0.5);
    graph.learnEnglishAcronym(`QT`, `cutie`, 0.5);

    graph.learnEnglishAcronym(`RCed`, `reconnected`, 0.5);
    graph.learnEnglishAcronym(`RE`, `hi again (same as re’s)`, 0.5);
    graph.learnEnglishAcronym(`RME`, `rolling my eyses`, 0.5);
    graph.learnEnglishAcronym(`ROFL`, `rolling on floor laughing`, 0.5);
    graph.learnEnglishAcronym(`ROFLAPMP`, `rolling on floor laughing and peed my pants`, 0.5);
    graph.learnEnglishAcronym(`ROFLMAO`, `rolling on floor laughing my ass off`, 0.5);
    graph.learnEnglishAcronym(`ROFLOLAY`, `rolling on floor laughing out loud at you`, 0.5);
    graph.learnEnglishAcronym(`ROFLOLTSDMC`, `rolling on floor laughing out loud tears streaming down my cheeks`, 0.5);
    graph.learnEnglishAcronym(`ROFLOLWTIME`, `rolling on floor laughing out loud with tears in my eyes`, 0.5);
    graph.learnEnglishAcronym(`ROFLOLUTS`, `rolling on floor laughing out loud unable to speak`, 0.5);
    graph.learnEnglishAcronym(`ROTFL`, `rolling on the floor laughing`, 0.5);
    graph.learnEnglishAcronym(`RVD`, `really very dumb`, 0.5);
    graph.learnEnglishAcronym(`RUTTM`, `are you talking to me`, 0.5);
    graph.learnEnglishAcronym(`RTF`, `read the FAQ`, 0.5);
    graph.learnEnglishAcronym(`RTFM`, `read the f***ing manual`, 0.5);
    graph.learnEnglishAcronym(`RTSM`, `read the stupid manual`, 0.5);

    graph.learnEnglishAcronym(`S2R`, `send to receive`, 0.5);
    graph.learnEnglishAcronym(`SAMAGAL`, `stop annoying me and get a live`, 0.5);
    graph.learnEnglishAcronym(`SCNR`, `sorry, could not resist`, 0.5);
    graph.learnEnglishAcronym(`SETE`, `smiling ear to ear`, 0.5);
    graph.learnEnglishAcronym(`SH`, `so hot`, 0.5);
    graph.learnEnglishAcronym(`SH`, `same here`, 0.5);
    graph.learnEnglishAcronym(`SHICPMP`, `so happy I could piss my pants`, 0.5);
    graph.learnEnglishAcronym(`SHID`, `slaps head in disgust`, 0.5);
    graph.learnEnglishAcronym(`SHMILY`, `see how much I love you`, 0.5);
    graph.learnEnglishAcronym(`SNAFU`, `situation normal, all F***ed up`, 0.5);
    graph.learnEnglishAcronym(`SO`, `significant other`, 0.5);
    graph.learnEnglishAcronym(`SOHF`, `sense of humor failure`, 0.5);
    graph.learnEnglishAcronym(`SOMY`, `sick of me yet?`, 0.5);
    graph.learnEnglishAcronym(`SPAM`, `stupid persons’ advertisement`, 0.5);
    graph.learnEnglishAcronym(`SRY`, `sorry`, 0.5);
    graph.learnEnglishAcronym(`SSDD`, `same shit different day`, 0.5);
    graph.learnEnglishAcronym(`STBY`, `sucks to be you`, 0.5);
    graph.learnEnglishAcronym(`STFU`, `shut the f*ck up`, 0.5);
    graph.learnEnglishAcronym(`STI`, `stick(ing) to it`, 0.5);
    graph.learnEnglishAcronym(`STW`, `search the web`, 0.5);
    graph.learnEnglishAcronym(`SWAK`, `sealed with a kiss`, 0.5);
    graph.learnEnglishAcronym(`SWALK`, `sweet, with all love, kisses`, 0.5);
    graph.learnEnglishAcronym(`SWL`, `screaming with laughter`, 0.5);
    graph.learnEnglishAcronym(`SIM`, `shit, it’s Monday`, 0.5);
    graph.learnEnglishAcronym(`SITWB`, `sorry, in the wrong box`, 0.5);
    graph.learnEnglishAcronym(`S/U`, `shut up`, 0.5);
    graph.learnEnglishAcronym(`SYS`, `see you soon`, 0.5);
    graph.learnEnglishAcronym(`SYSOP`, `system operator`, 0.5);

    graph.learnEnglishAcronym(`TA`, `thanks again`, 0.5);
    graph.learnEnglishAcronym(`TCO`, `taken care of`, 0.5);
    graph.learnEnglishAcronym(`TGIF`, `thank god its Friday`, 0.5);
    graph.learnEnglishAcronym(`THTH`, `to hot to handle`, 0.5);
    graph.learnEnglishAcronym(`THX`, `thanks`, 0.5);
    graph.learnEnglishAcronym(`TIA`, `thanks in advance`, 0.5);
    graph.learnEnglishAcronym(`TIIC`, `the idiots in charge`, 0.5);
    graph.learnEnglishAcronym(`TJM`, `that’s just me`, 0.5);
    graph.learnEnglishAcronym(`TLA`, `three-letter acronym`, 0.5);
    graph.learnEnglishAcronym(`TMA`, `take my advice`, 0.5);
    graph.learnEnglishAcronym(`TMI`, `to much information`, 0.5);
    graph.learnEnglishAcronym(`TMS`, `to much showing`, 0.5);
    graph.learnEnglishAcronym(`TNSTAAFL`, `there’s no such thing as a free lunch`, 0.5);
    graph.learnEnglishAcronym(`TNX`, `thanks`, 0.5);
    graph.learnEnglishAcronym(`TOH`, `to other half`, 0.5);
    graph.learnEnglishAcronym(`TOY`, `thinking of you`, 0.5);
    graph.learnEnglishAcronym(`TPTB`, `the powers that be`, 0.5);
    graph.learnEnglishAcronym(`TSDMC`, `tears streaming down my cheeks`, 0.5);
    graph.learnEnglishAcronym(`TT2T`, `to tired to talk`, 0.5);
    graph.learnEnglishAcronym(`TTFN`, `ta ta for now`, 0.5);
    graph.learnEnglishAcronym(`TTT`, `thought that, too`, 0.5);
    graph.learnEnglishAcronym(`TTUL`, `talk to you later`, 0.5);
    graph.learnEnglishAcronym(`TTYIAM`, `talk to you in a minute`, 0.5);
    graph.learnEnglishAcronym(`TTYL`, `talk to you later`, 0.5);
    graph.learnEnglishAcronym(`TTYLMF`, `talk to you later my friend`, 0.5);
    graph.learnEnglishAcronym(`TU`, `thank you`, 0.5);
    graph.learnEnglishAcronym(`TWMA`, `till we meet again`, 0.5);
    graph.learnEnglishAcronym(`TX`, `thanx`, 0.5);
    graph.learnEnglishAcronym(`TY`, `thank you`, 0.5);
    graph.learnEnglishAcronym(`TYVM`, `thank you very much`, 0.5);

    graph.learnEnglishAcronym(`U2`, `you too`, 0.5);
    graph.learnEnglishAcronym(`UAPITA`, `you’re a pain in the ass`, 0.5);
    graph.learnEnglishAcronym(`UR`, `your`, 0.5);
    graph.learnEnglishAcronym(`UW`, `you’re welcom`, 0.5);
    graph.learnEnglishAcronym(`URAQT!`, `you are a cutie!`, 0.5);

    graph.learnEnglishAcronym(`VBG`, `very big grin`, 0.5);
    graph.learnEnglishAcronym(`VBS`, `very big smile`, 0.5);

    graph.learnEnglishAcronym(`W8`, `wait`, 0.5);
    graph.learnEnglishAcronym(`W8AM`, `wait a minute`, 0.5);
    graph.learnEnglishAcronym(`WAY`, `what about you`, 0.5);
    graph.learnEnglishAcronym(`WAY`, `who are you`, 0.5);
    graph.learnEnglishAcronym(`WB`, `welcome back`, 0.5);
    graph.learnEnglishAcronym(`WBS`, `write back soon`, 0.5);
    graph.learnEnglishAcronym(`WDHLM`, `why doesn’t he love me`, 0.5);
    graph.learnEnglishAcronym(`WDYWTTA`, `What Do You Want To Talk About`, 0.5);
    graph.learnEnglishAcronym(`WE`, `whatever`, 0.5);
    graph.learnEnglishAcronym(`W/E`, `whatever`, 0.5);
    graph.learnEnglishAcronym(`WFM`, `works for me`, 0.5);
    graph.learnEnglishAcronym(`WNDITWB`, `we never did it this way before`, 0.5);
    graph.learnEnglishAcronym(`WP`, `wrong person`, 0.5);
    graph.learnEnglishAcronym(`WRT`, `with respect to`, 0.5);
    graph.learnEnglishAcronym(`WTF`, `what/who the F***?`, 0.5);
    graph.learnEnglishAcronym(`WTG`, `way to go`, 0.5);
    graph.learnEnglishAcronym(`WTGP`, `want to go private?`, 0.5);
    graph.learnEnglishAcronym(`WTH`, `what/who the heck?`, 0.5);
    graph.learnEnglishAcronym(`WTMI`, `way to much information`, 0.5);
    graph.learnEnglishAcronym(`WU`, `what’s up?`, 0.5);
    graph.learnEnglishAcronym(`WUD`, `what’s up dog?`, 0.5);
    graph.learnEnglishAcronym(`WUF`, `where are you from?`, 0.5);
    graph.learnEnglishAcronym(`WUWT`, `whats up with that`, 0.5);
    graph.learnEnglishAcronym(`WYMM`, `will you marry me?`, 0.5);
    graph.learnEnglishAcronym(`WYSIWYG`, `what you see is what you get`, 0.5);

    graph.learnEnglishAcronym(`XTLA`, `extended three letter acronym`, 0.5);

    graph.learnEnglishAcronym(`Y`, `why?`, 0.5);
    graph.learnEnglishAcronym(`Y2K`, `you’re too kind`, 0.5);
    graph.learnEnglishAcronym(`YATB`, `you are the best`, 0.5);
    graph.learnEnglishAcronym(`YBS`, `you’ll be sorry`, 0.5);
    graph.learnEnglishAcronym(`YG`, `young gentleman`, 0.5);
    graph.learnEnglishAcronym(`YHBBYBD`, `you’d have better bet your bottom dollar`, 0.5);
    graph.learnEnglishAcronym(`YKYWTKM`, `you know you want to kiss me`, 0.5);
    graph.learnEnglishAcronym(`YL`, `young lady`, 0.5);
    graph.learnEnglishAcronym(`YL`, `you ’ll live`, 0.5);
    graph.learnEnglishAcronym(`YM`, `you mean`, 0.5);
    graph.learnEnglishAcronym(`YM`, `young man`, 0.5);
    graph.learnEnglishAcronym(`YMMD`, `you’ve made my day`, 0.5);
    graph.learnEnglishAcronym(`YMMV`, `your mileage may vary`, 0.5);
    graph.learnEnglishAcronym(`YVM`, `you’re very welcome`, 0.5);
    graph.learnEnglishAcronym(`YW`, `you’re welcome`, 0.5);
    graph.learnEnglishAcronym(`YWIA`, `you’re welcome in advance`, 0.5);
    graph.learnEnglishAcronym(`YWTHM`, `you want to hug me`, 0.5);
    graph.learnEnglishAcronym(`YWTLM`, `you want to love me`, 0.5);
    graph.learnEnglishAcronym(`YWTKM`, `you want to kiss me`, 0.5);
    graph.learnEnglishAcronym(`YOYO`, `you’re on your own`, 0.5);
    graph.learnEnglishAcronym(`YY4U`, `two wise for you`, 0.5);

    graph.learnEnglishAcronym(`?`, `huh?`, 0.5);
    graph.learnEnglishAcronym(`?4U`, `question for you`, 0.5);
    graph.learnEnglishAcronym(`>U`, `screw you!`, 0.5);
    graph.learnEnglishAcronym(`/myB`, `kick my boobs`, 0.5);
    graph.learnEnglishAcronym(`2U2`, `to you too`, 0.5);
    graph.learnEnglishAcronym(`2MFM`, `to much for me`, 0.5);
    graph.learnEnglishAcronym(`4AYN`, `for all you know`, 0.5);
    graph.learnEnglishAcronym(`4COL`, `for crying out loud`, 0.5);
    graph.learnEnglishAcronym(`4SALE`, `for sale`, 0.5);
    graph.learnEnglishAcronym(`4U`, `for you`, 0.5);
    graph.learnEnglishAcronym(`=w=`, `whatever`, 0.5);
    graph.learnEnglishAcronym(`*G*`, `giggle or grin`, 0.5);
    graph.learnEnglishAcronym(`*H*`, `hug`, 0.5);
    graph.learnEnglishAcronym(`*K*`, `kiss`, 0.5);
    graph.learnEnglishAcronym(`*S*`, `smile`, 0.5);
    graph.learnEnglishAcronym(`*T*`, `tickle`, 0.5);
    graph.learnEnglishAcronym(`*W*`, `wink`, 0.5);

    // https://en.wikipedia.org/wiki/List_of_emoticons
    graph.learnEnglishEmoticon([`:-)`, `:)`, `:)`, `:o)`, `:]`, `:3`, `:c)`, `:>`],
                         [`Smiley`, `Happy`], 0.5);
}

/** Learn English Irregular Verbs.
    TODO Move to irregular_verb.txt in format: bewas,werebeen
    TODO Merge with http://www.enchantedlearning.com/wordlist/irregularverbs.shtml
*/
void learnEnglishIrregularVerbs(Graph graph)
{
    writeln(`Reading English Irregular Verbs ...`);
    /* base form	past simple	past participle	3rd person singular	present participle / gerund */
    graph.learnEnglishIrregularVerb(`alight`, [`alit`, `alighted`], [`alit`, `alighted`]); // alights	alighting
    graph.learnEnglishIrregularVerb(`arise`, `arose`, `arisen`); // arises	arising
    graph.learnEnglishIrregularVerb(`awake`, `awoke`, `awoken`); // awakes	awaking
    graph.learnEnglishIrregularVerb(`be`, [`was`, `were`], `been`); // is	being
    graph.learnEnglishIrregularVerb(`bear`, `bore`, [`born`, `borne`]); // bears	bearing
    graph.learnEnglishIrregularVerb(`beat`, `beat`, `beaten`); // beats	beating
    graph.learnEnglishIrregularVerb(`become`, `became`, `become`); // becomes	becoming
    graph.learnEnglishIrregularVerb(`begin`, `began`, `begun`); // begins	beginning
    graph.learnEnglishIrregularVerb(`behold`, `beheld`, `beheld`); // beholds	beholding
    graph.learnEnglishIrregularVerb(`bend`, `bent`, `bent`); // bends	bending
    graph.learnEnglishIrregularVerb(`bet`, `bet`, `bet`); // bets	betting
    graph.learnEnglishIrregularVerb(`bid`, `bade`, `bidden`); // bids	bidding
    graph.learnEnglishIrregularVerb(`bid`, `bid`, `bid`); // bids	bidding
    graph.learnEnglishIrregularVerb(`bind`, `bound`, `bound`); // binds	binding
    graph.learnEnglishIrregularVerb(`bite`, `bit`, `bitten`); // bites	biting
    graph.learnEnglishIrregularVerb(`bleed`, `bled`, `bled`); // bleeds	bleeding
    graph.learnEnglishIrregularVerb(`blow`, `blew`, `blown`); // blows	blowing
    graph.learnEnglishIrregularVerb(`break`, `broke`, `broken`); // breaks	breaking
    graph.learnEnglishIrregularVerb(`breed`, `bred`, `bred`); // breeds	breeding
    graph.learnEnglishIrregularVerb(`bring`, `brought`, `brought`); // brings	bringing
    graph.learnEnglishIrregularVerb(`broadcast`, [`broadcast`, `broadcasted`], [`broadcast`, `broadcasted`]); // broadcasts	broadcasting
    graph.learnEnglishIrregularVerb(`build`, `built`, `built`); // builds	building
    graph.learnEnglishIrregularVerb(`burn`, [`burnt`, `burned`], [`burnt`, `burned`]); // burns	burning
    graph.learnEnglishIrregularVerb(`burst`, `burst`, `burst`); // bursts	bursting
    graph.learnEnglishIrregularVerb(`bust`, `bust`, `bust`); // busts	busting
    graph.learnEnglishIrregularVerb(`buy`, `bought`, `bought`); // buys	buying
    graph.learnEnglishIrregularVerb(`cast`, `cast`, `cast`); // casts	casting
    graph.learnEnglishIrregularVerb(`catch`, `caught`, `caught`); // catches	catching
    graph.learnEnglishIrregularVerb(`choose`, `chose`, `chosen`); // chooses	choosing
    graph.learnEnglishIrregularVerb(`clap`, [`clapped`, `clapt`], [`clapped`, `clapt`]); // claps	clapping
    graph.learnEnglishIrregularVerb(`cling`, `clung`, `clung`); // clings	clinging
    graph.learnEnglishIrregularVerb(`clothe`, [`clad`, `clothed`], [`clad`, `clothed`]); // clothes	clothing
    graph.learnEnglishIrregularVerb(`come`, `came`, `come`); // comes	coming
    graph.learnEnglishIrregularVerb(`cost`, `cost`, `cost`); // costs	costing
    graph.learnEnglishIrregularVerb(`creep`, `crept`, `crept`); // creeps	creeping
    graph.learnEnglishIrregularVerb(`cut`, `cut`, `cut`); // cuts	cutting
    graph.learnEnglishIrregularVerb(`dare`, [`dared`, `durst`], `dared`); // dares	daring
    graph.learnEnglishIrregularVerb(`deal`, `dealt`, `dealt`); // deals	dealing
    graph.learnEnglishIrregularVerb(`dig`, `dug`, `dug`); // digs	digging
    graph.learnEnglishIrregularVerb(`dive`, [`dived`, `dove`], `dived`); // dives	diving
    graph.learnEnglishIrregularVerb(`do`, `did`, `done`); // does	doing
    graph.learnEnglishIrregularVerb(`draw`, `drew`, `drawn`); // draws	drawing
    graph.learnEnglishIrregularVerb(`dream`, [`dreamt`, `dreamed`], [`dreamt`, `dreamed`]); // dreams	dreaming
    graph.learnEnglishIrregularVerb(`drink`, `drank`, `drunk`); // drinks	drinking
    graph.learnEnglishIrregularVerb(`drive`, `drove`, `driven`); // drives	driving
    graph.learnEnglishIrregularVerb(`dwell`, `dwelt`, `dwelt`); // dwells	dwelling
    graph.learnEnglishIrregularVerb(`eat`, `ate`, `eaten`); // eats	eating
    graph.learnEnglishIrregularVerb(`fall`, `fell`, `fallen`); // falls	falling
    graph.learnEnglishIrregularVerb(`feed`, `fed`, `fed`); // feeds	feeding
    graph.learnEnglishIrregularVerb(`feel`, `felt`, `felt`); // feels	feeling
    graph.learnEnglishIrregularVerb(`fight`, `fought`, `fought`); // fights	fighting
    graph.learnEnglishIrregularVerb(`find`, `found`, `found`); // finds	finding
    graph.learnEnglishIrregularVerb(`fit`, [`fit`, `fitted`], [`fit`, `fitted`]); // fits	fitting
    graph.learnEnglishIrregularVerb(`flee`, `fled`, `fled`); // flees	fleeing
    graph.learnEnglishIrregularVerb(`fling`, `flung`, `flung`); // flings	flinging
    graph.learnEnglishIrregularVerb(`fly`, `flew`, `flown`); // flies	flying
    graph.learnEnglishIrregularVerb(`forbid`, [`forbade`, `forbad`], `forbidden`); // forbids	forbidding
    graph.learnEnglishIrregularVerb(`forecast`, [`forecast`, `forecasted`], [`forecast`, `forecasted`]); // forecasts	forecasting
    graph.learnEnglishIrregularVerb(`foresee`, `foresaw`, `foreseen`); // foresees	foreseeing
    graph.learnEnglishIrregularVerb(`foretell`, `foretold`, `foretold`); // foretells	foretelling
    graph.learnEnglishIrregularVerb(`forget`, `forgot`, `forgotten`); // forgets	foregetting
    graph.learnEnglishIrregularVerb(`forgive`, `forgave`, `forgiven`); // forgives	forgiving
    graph.learnEnglishIrregularVerb(`forsake`, `forsook`, `forsaken`); // forsakes	forsaking
    graph.learnEnglishIrregularVerb(`freeze`, `froze`, `frozen`); // freezes	freezing
    graph.learnEnglishIrregularVerb(`frostbite`, `frostbit`, `frostbitten`); // frostbites	frostbiting
    graph.learnEnglishIrregularVerb(`get`, `got`, [`got`, `gotten`]); // gets	getting
    graph.learnEnglishIrregularVerb(`give`, `gave`, `given`); // gives	giving
    graph.learnEnglishIrregularVerb(`go`, `went`, [`gone`, `been`]); // goes	going
    graph.learnEnglishIrregularVerb(`grind`, `ground`, `ground`); // grinds	grinding
    graph.learnEnglishIrregularVerb(`grow`, `grew`, `grown`); // grows	growing
    graph.learnEnglishIrregularVerb(`handwrite`, `handwrote`, `handwritten`); // handwrites	handwriting
    graph.learnEnglishIrregularVerb(`hang`, [`hung`, `hanged`], [`hung`, `hanged`]); // hangs	hanging
    graph.learnEnglishIrregularVerb(`have`, `had`, `had`); // has	having
    graph.learnEnglishIrregularVerb(`hear`, `heard`, `heard`); // hears	hearing
    graph.learnEnglishIrregularVerb(`hide`, `hid`, `hidden`); // hides	hiding
    graph.learnEnglishIrregularVerb(`hit`, `hit`, `hit`); // hits	hitting
    graph.learnEnglishIrregularVerb(`hold`, `held`, `held`); // holds	holding
    graph.learnEnglishIrregularVerb(`hurt`, `hurt`, `hurt`); // hurts	hurting
    graph.learnEnglishIrregularVerb(`inlay`, `inlaid`, `inlaid`); // inlays	inlaying
    graph.learnEnglishIrregularVerb(`input`, [`input`, `inputted`], [`input`, `inputted`]); // inputs	inputting
    graph.learnEnglishIrregularVerb(`interlay`, `interlaid`, `interlaid`); // interlays	interlaying
    graph.learnEnglishIrregularVerb(`keep`, `kept`, `kept`); // keeps	keeping
    graph.learnEnglishIrregularVerb(`kneel`, [`knelt`, `kneeled`], [`knelt`, `kneeled`]); // kneels	kneeling
    graph.learnEnglishIrregularVerb(`knit`, [`knit`, `knitted`], [`knit`, `knitted`]); // knits	knitting
    graph.learnEnglishIrregularVerb(`know`, `knew`, `known`); // knows	knowing
    graph.learnEnglishIrregularVerb(`lay`, `laid`, `laid`); // lays	laying
    graph.learnEnglishIrregularVerb(`lead`, `led`, `led`); // leads	leading
    graph.learnEnglishIrregularVerb(`lean`, [`leant`, `leaned`], [`leant`, `leaned`]); // leans	leaning
    graph.learnEnglishIrregularVerb(`leap`, [`leapt`, `leaped`], [`leapt`, `leaped`]); // leaps	leaping
    graph.learnEnglishIrregularVerb(`learn`, [`learnt`, `learned`], [`learnt`, `learned`]); // learns	learning
    graph.learnEnglishIrregularVerb(`leave`, `left`, `left`); // leaves	leaving
    graph.learnEnglishIrregularVerb(`lend`, `lent`, `lent`); // lends	lending
    graph.learnEnglishIrregularVerb(`let`, `let`, `let`); // lets	letting
    graph.learnEnglishIrregularVerb(`lie`, `lay`, `lain`); // lies	lying
    graph.learnEnglishIrregularVerb(`light`, `lit`, `lit`); // lights	lighting
    graph.learnEnglishIrregularVerb(`lose`, `lost`, `lost`); // loses	losing
    graph.learnEnglishIrregularVerb(`make`, `made`, `made`); // makes	making
    graph.learnEnglishIrregularVerb(`mean`, `meant`, `meant`); // means	meaning
    graph.learnEnglishIrregularVerb(`meet`, `met`, `met`); // meets	meeting
    graph.learnEnglishIrregularVerb(`melt`, `melted`, [`molten`, `melted`]); // melts	melting
    graph.learnEnglishIrregularVerb(`mislead`, `misled`, `misled`); // misleads	misleading
    graph.learnEnglishIrregularVerb(`mistake`, `mistook`, `mistaken`); // mistakes	mistaking
    graph.learnEnglishIrregularVerb(`misunderstand`, `misunderstood`, `misunderstood`); // misunderstands	misunderstanding
    graph.learnEnglishIrregularVerb(`miswed`, [`miswed`, `miswedded`], [`miswed`, `miswedded`]); // misweds	miswedding
    graph.learnEnglishIrregularVerb(`mow`, `mowed`, `mown`); // mows	mowing
    graph.learnEnglishIrregularVerb(`overdraw`, `overdrew`, `overdrawn`); // overdraws	overdrawing
    graph.learnEnglishIrregularVerb(`overhear`, `overheard`, `overheard`); // overhears	overhearing
    graph.learnEnglishIrregularVerb(`overtake`, `overtook`, `overtaken`); // overtakes	overtaking
    graph.learnEnglishIrregularVerb(`partake`, `partook`, `partaken`);
    graph.learnEnglishIrregularVerb(`pay`, `paid`, `paid`); // pays	paying
    graph.learnEnglishIrregularVerb(`preset`, `preset`, `preset`); // presets	presetting
    graph.learnEnglishIrregularVerb(`prove`, `proved`, [`proven`, `proved`]); // proves	proving
    graph.learnEnglishIrregularVerb(`put`, `put`, `put`); // puts	putting
    graph.learnEnglishIrregularVerb(`quit`, `quit`, `quit`); // quits	quitting
    graph.learnEnglishIrregularVerb(`re-prove`, `re-proved`, `re-proven/re-proved`); // re-proves	re-proving
    graph.learnEnglishIrregularVerb(`read`, `read`, `read`); // reads	reading
    graph.learnEnglishIrregularVerb(`rend`, `rent`, `rent`);
    graph.learnEnglishIrregularVerb(`rid`, [`rid`, `ridded`], [`rid`, `ridded`]); // rids	ridding
    graph.learnEnglishIrregularVerb(`ride`, `rode`, `ridden`); // rides	riding
    graph.learnEnglishIrregularVerb(`ring`, `rang`, `rung`); // rings	ringing
    graph.learnEnglishIrregularVerb(`rise`, `rose`, `risen`); // rises	rising
    graph.learnEnglishIrregularVerb(`rive`, `rived`, [`riven`, `rived`]); // rives	riving
    graph.learnEnglishIrregularVerb(`run`, `ran`, `run`); // runs	running
    graph.learnEnglishIrregularVerb(`saw`, `sawed`, [`sawn`, `sawed`]); // saws	sawing
    graph.learnEnglishIrregularVerb(`say`, `said`, `said`); // says	saying
    graph.learnEnglishIrregularVerb(`see`, `saw`, `seen`); // sees	seeing
    graph.learnEnglishIrregularVerb(`seek`, `sought`, `sought`); // seeks	seeking
    graph.learnEnglishIrregularVerb(`sell`, `sold`, `sold`); // sells	selling
    graph.learnEnglishIrregularVerb(`send`, `sent`, `sent`); // sends	sending
    graph.learnEnglishIrregularVerb(`set`, `set`, `set`); // sets	setting
    graph.learnEnglishIrregularVerb(`sew`, `sewed`, [`sewn`, `sewed`]); // sews	sewing
    graph.learnEnglishIrregularVerb(`shake`, `shook`, `shaken`); // shakes	shaking
    graph.learnEnglishIrregularVerb(`shave`, `shaved`, [`shaven`, `shaved`]); // shaves	shaving
    graph.learnEnglishIrregularVerb(`shear`, [`shore`, `sheared`], [`shorn`, `sheared`]); // shears	shearing
    graph.learnEnglishIrregularVerb(`shed`, `shed`, `shed`); // sheds	shedding
    graph.learnEnglishIrregularVerb(`shine`, `shone`, `shone`); // shines	shining
    graph.learnEnglishIrregularVerb(`shoe`, `shod`, `shod`); // shoes	shoeing
    graph.learnEnglishIrregularVerb(`shoot`, `shot`, `shot`); // shoots	shooting
    graph.learnEnglishIrregularVerb(`show`, `showed`, `shown`); // shows	showing
    graph.learnEnglishIrregularVerb(`shrink`, `shrank`, `shrunk`); // shrinks	shrinking
    graph.learnEnglishIrregularVerb(`shut`, `shut`, `shut`); // shuts	shutting
    graph.learnEnglishIrregularVerb(`sing`, `sang`, `sung`); // sings	singing
    graph.learnEnglishIrregularVerb(`sink`, `sank`, `sunk`); // sinks	sinking
    graph.learnEnglishIrregularVerb(`sit`, `sat`, `sat`); // sits	sitting
    graph.learnEnglishIrregularVerb(`slay`, `slew`, `slain`); // slays	slaying
    graph.learnEnglishIrregularVerb(`sleep`, `slept`, `slept`); // sleeps	sleeping
    graph.learnEnglishIrregularVerb(`slide`, `slid`, [`slid`, `slidden`]); // slides	sliding
    graph.learnEnglishIrregularVerb(`sling`, `slung`, `slung`); // slings	slinging
    graph.learnEnglishIrregularVerb(`slink`, `slunk`, `slunk`); // slinks	slinking
    graph.learnEnglishIrregularVerb(`slit`, `slit`, `slit`); // slits	slitting
    graph.learnEnglishIrregularVerb(`smell`, [`smelt`, `smelled`], [`smelt`, `smelled`]); // smells	smelling
    graph.learnEnglishIrregularVerb(`sneak`, [`sneaked`, `snuck`], [`sneaked`, `snuck`]); // sneaks	sneaking
    graph.learnEnglishIrregularVerb(`soothsay`, `soothsaid`, `soothsaid`); // soothsays	soothsaying
    graph.learnEnglishIrregularVerb(`sow`, `sowed`, `sown`); // sows	sowing
    graph.learnEnglishIrregularVerb(`speak`, `spoke`, `spoken`); // speaks	speaking
    graph.learnEnglishIrregularVerb(`speed`, [`sped`, `speeded`], [`sped`, `speeded`]); // speeds	speeding
    graph.learnEnglishIrregularVerb(`spell`, [`spelt`, `spelled`], [`spelt`, `spelled`]); // spells	spelling
    graph.learnEnglishIrregularVerb(`spend`, `spent`, `spent`); // spends	spending
    graph.learnEnglishIrregularVerb(`spill`, [`spilt`, `spilled`], [`spilt`, `spilled`]); // spills	spilling
    graph.learnEnglishIrregularVerb(`spin`, [`span`, `spun`], `spun`); // spins	spinning
    graph.learnEnglishIrregularVerb(`spit`, [`spat`, `spit`], [`spat`, `spit`]); // spits	spitting
    graph.learnEnglishIrregularVerb(`split`, `split`, `split`); // splits	splitting
    graph.learnEnglishIrregularVerb(`spoil`, [`spoilt`, `spoiled`], [`spoilt`, `spoiled`]); // spoils	spoiling
    graph.learnEnglishIrregularVerb(`spread`, `spread`, `spread`); // spreads	spreading
    graph.learnEnglishIrregularVerb(`spring`, `sprang`, `sprung`); // springs	springing
    graph.learnEnglishIrregularVerb(`stand`, `stood`, `stood`); // stands	standing
    graph.learnEnglishIrregularVerb(`steal`, `stole`, `stolen`); // steals	stealing
    graph.learnEnglishIrregularVerb(`stick`, `stuck`, `stuck`); // sticks	sticking
    graph.learnEnglishIrregularVerb(`sting`, `stung`, `stung`); // stings	stinging
    graph.learnEnglishIrregularVerb(`stink`, `stank`, `stunk`); // stinks	stinking
    graph.learnEnglishIrregularVerb(`stride`, [`strode`, `strided`], `stridden`); // strides	striding
    graph.learnEnglishIrregularVerb(`strike`, `struck`, [`struck`, `stricken`]); // strikes	striking
    graph.learnEnglishIrregularVerb(`string`, `strung`, `strung`); // strings	stringing
    graph.learnEnglishIrregularVerb(`strip`, [`stript`, `stripped`], [`stript`, `stripped`]); // strips	stripping
    graph.learnEnglishIrregularVerb(`strive`, `strove`, `striven`); // strives	striving
    graph.learnEnglishIrregularVerb(`sublet`, `sublet`, `sublet`); // sublets	subletting
    graph.learnEnglishIrregularVerb(`sunburn`, [`sunburned`, `sunburnt`], [`sunburned`, `sunburnt`]); // sunburns	sunburning
    graph.learnEnglishIrregularVerb(`swear`, `swore`, `sworn`); // swears	swearing
    graph.learnEnglishIrregularVerb(`sweat`, [`sweat`, `sweated`], [`sweat`, `sweated`]); // sweats	sweating
    graph.learnEnglishIrregularVerb(`sweep`, [`swept`, `sweeped`], [`swept`, `sweeped`]); // sweeps	sweeping
    graph.learnEnglishIrregularVerb(`swell`, `swelled`, `swollen`); // swells	swelling
    graph.learnEnglishIrregularVerb(`swim`, `swam`, `swum`); // swims	swimming
    graph.learnEnglishIrregularVerb(`swing`, `swung`, `swung`); // swings	swinging
    graph.learnEnglishIrregularVerb(`take`, `took`, `taken`); // takes	taking
    graph.learnEnglishIrregularVerb(`teach`, `taught`, `taught`); // teaches	teaching
    graph.learnEnglishIrregularVerb(`tear`, `tore`, `torn`); // tears	tearing
    graph.learnEnglishIrregularVerb(`tell`, `told`, `told`); // tells	telling
    graph.learnEnglishIrregularVerb(`think`, `thought`, `thought`); // thinks	thinking
    graph.learnEnglishIrregularVerb(`thrive`, [`throve`, `thrived`], [`thriven`, `thrived`]); // thrives	thriving
    graph.learnEnglishIrregularVerb(`throw`, `threw`, `thrown`); // throws	throwing
    graph.learnEnglishIrregularVerb(`thrust`, `thrust`, `thrust`); // thrusts	thrusting
    graph.learnEnglishIrregularVerb(`tread`, `trod`, [`trodden`, `trod`]); // treads	treading
    graph.learnEnglishIrregularVerb(`undergo`, `underwent`, `undergone`); // undergoes	undergoing
    graph.learnEnglishIrregularVerb(`understand`, `understood`, `understood`); // understands	understanding
    graph.learnEnglishIrregularVerb(`undertake`, `undertook`, `undertaken`); // undertakes	undertaking
    graph.learnEnglishIrregularVerb(`upsell`, `upsold`, `upsold`); // upsells	upselling
    graph.learnEnglishIrregularVerb(`upset`, `upset`, `upset`); // upsets	upsetting
    graph.learnEnglishIrregularVerb(`vex`, [`vext`, `vexed`], [`vext`, `vexed`]); // vexes	vexing
    graph.learnEnglishIrregularVerb(`wake`, `woke`, `woken`); // wakes	waking
    graph.learnEnglishIrregularVerb(`wear`, `wore`, `worn`); // wears	wearing
    graph.learnEnglishIrregularVerb(`weave`, `wove`, `woven`); // weaves	weaving
    graph.learnEnglishIrregularVerb(`wed`, [`wed`, `wedded`], [`wed`, `wedded`]); // weds	wedding
    graph.learnEnglishIrregularVerb(`weep`, `wept`, `wept`); // weeps	weeping
    graph.learnEnglishIrregularVerb(`wend`, [`wended`, `went`], [`wended`, `went`]); // wends	wending
    graph.learnEnglishIrregularVerb(`wet`, [`wet`, `wetted`], [`wet`, `wetted`]); // wets	wetting
    graph.learnEnglishIrregularVerb(`win`, `won`, `won`); // wins	winning
    graph.learnEnglishIrregularVerb(`wind`, `wound`, `wound`); // winds	winding
    graph.learnEnglishIrregularVerb(`withdraw`, `withdrew`, `withdrawn`); // withdraws	withdrawing
    graph.learnEnglishIrregularVerb(`withhold`, `withheld`, `withheld`); // withholds	withholding
    graph.learnEnglishIrregularVerb(`withstand`, `withstood`, `withstood`); // withstands	withstanding
    graph.learnEnglishIrregularVerb(`wring`, `wrung`, `wrung`); // wrings	wringing
    graph.learnEnglishIrregularVerb(`write`, `wrote`, `written`); // writes	writing
    graph.learnEnglishIrregularVerb(`zinc`, [`zinced`, `zincked`], [`zinced`, `zincked`]); // zincs/zincks	zincking
    graph.learnEnglishIrregularVerb(`abide`, [`abode`, `abided`], [`abode`, `abided`, `abidden`]); // abides	abiding
}

void learnMath(Graph graph)
{
    const origin = Origin.manual;

    graph.connect(graph.store(`π`, Lang.math, Sense.numberIrrational, origin),
                  Role(Rel.translationOf),
                  graph.store(`pi`, Lang.en, Sense.numberIrrational, origin), // TODO other Langs?
                  origin, 1.0);
    graph.connect(graph.store(`e`, Lang.math, Sense.numberIrrational, origin),
                  Role(Rel.translationOf),
                  graph.store(`e`, Lang.en, Sense.numberIrrational, origin), // TODO other Langs?
                  origin, 1.0);

    /// http://www.geom.uiuc.edu/~huberty/math5337/groupe/digits.html
    graph.connect(graph.store(`π`, Lang.math, Sense.numberIrrational, origin),
                  Role(Rel.definedAs),
                  graph.store(`3.14159265358979323846264338327950288419716939937510`,
                              Lang.math, Sense.decimal, origin),
                  origin, 1.0);

    graph.connect(graph.store(`e`, Lang.math, Sense.numberIrrational, origin),
                  Role(Rel.definedAs),
                  graph.store(`2.71828182845904523536028747135266249775724709369995`,
                              Lang.math, Sense.decimal, origin),
                  origin, 1.0);

    graph.learnMto1(Lang.en, [`quaternary`, `quinary`, `senary`, `octal`, `decimal`, `duodecimal`, `vigesimal`, `quadrovigesimal`, `duotrigesimal`, `sexagesimal`, `octogesimal`],
                    Role(Rel.hasProperty, true), `counting system`, Sense.adjective, Sense.noun, 1.0);
}

void learnPunctuation(Graph graph)
{
    const origin = Origin.manual;

    graph.connect(graph.store(`:`, Lang.unknown, Sense.punctuation, origin),
                  Role(Rel.definedAs),
                  graph.store(`colon`,
                              Lang.en, Sense.noun, origin),
                  origin, 1.0);

    graph.connect(graph.store(`;`, Lang.unknown, Sense.punctuation, origin),
                  Role(Rel.definedAs),
                  graph.store(`semicolon`,
                              Lang.en, Sense.noun, origin),
                  origin, 1.0);

    graph.connectMto1(graph.store([`,`, `،`, `、`], Lang.unknown, Sense.punctuation, origin),
                      Role(Rel.definedAs),
                      graph.store(`comma`,
                                  Lang.en, Sense.noun, origin),
                      origin, 1.0);

    graph.connectMtoN(graph.store([`/`, `⁄`], Lang.unknown, Sense.punctuation, origin),
                      Role(Rel.definedAs),
                      graph.store([`slash`, `stroke`, `solidus`],
                                  Lang.en, Sense.noun, origin),
                      origin, 1.0);

    graph.connect(graph.store(`-`, Lang.unknown, Sense.punctuation, origin),
                  Role(Rel.definedAs),
                  graph.store(`hyphen`, Lang.en, Sense.noun, origin),
                  origin, 1.0);

    graph.connect(graph.store(`-`, Lang.unknown, Sense.punctuation, origin),
                  Role(Rel.definedAs),
                  graph.store(`hyphen-minus`, Lang.en, Sense.noun, origin),
                  origin, 1.0);

    graph.connect(graph.store(`?`, Lang.unknown, Sense.punctuation, origin),
                  Role(Rel.definedAs),
                  graph.store(`question mark`, Lang.en, Sense.noun, origin),
                  origin, 1.0);

    graph.connect(graph.store(`!`, Lang.unknown, Sense.punctuation, origin),
                  Role(Rel.definedAs),
                  graph.store(`exclamation mark`, Lang.en, Sense.noun, origin),
                  origin, 1.0);

    graph.connect1toM(graph.store(`.`, Lang.unknown, Sense.punctuation, origin),
                      Role(Rel.definedAs),
                      graph.store([`full stop`, `period`], Lang.en, Sense.noun, origin),
                      origin, 1.0);

    graph.connectMto1(graph.store([`’`, `'`], Lang.unknown, Sense.punctuation, origin),
                      Role(Rel.definedAs),
                      graph.store(`apostrophe`, Lang.en, Sense.noun, origin),
                      origin, 1.0);

    graph.connectMto1(graph.store([`‒`, `–`, `—`, `―`], Lang.unknown, Sense.punctuation, origin),
                      Role(Rel.definedAs),
                      graph.store(`dash`, Lang.en, Sense.noun, origin),
                      origin, 1.0);

    graph.connectMto1(graph.store([`‘’`, `“”`, `''`, `""`], Lang.unknown, Sense.punctuation, origin),
                      Role(Rel.definedAs),
                      graph.store(`quotation marks`, Lang.en, Sense.noun, origin),
                      origin, 1.0);

    graph.connectMto1(graph.store([`…`, `...`], Lang.unknown, Sense.punctuation, origin),
                      Role(Rel.definedAs),
                      graph.store(`ellipsis`, Lang.en, Sense.noun, origin),
                      origin, 1.0);

    graph.connect(graph.store(`()`, Lang.unknown, Sense.punctuation, origin),
                  Role(Rel.definedAs),
                  graph.store(`parenthesis`, Lang.en, Sense.noun, origin),
                  origin, 1.0);

    graph.connect(graph.store(`{}`, Lang.unknown, Sense.punctuation, origin),
                  Role(Rel.definedAs),
                  graph.store(`curly braces`, Lang.en, Sense.noun, origin),
                  origin, 1.0);

    graph.connectMto1(graph.store([`[]`, `()`, `{}`, `⟨⟩`], Lang.unknown, Sense.punctuation, origin),
                      Role(Rel.definedAs),
                      graph.store(`brackets`, Lang.en, Sense.noun, origin),
                      origin, 1.0);

    graph.learnNumerals();
}

/// Learn Numerals (Groupings/Aggregates) (MÄngdmått)
void learnNumerals(Graph graph)
{
    graph.learnRomanLatinNumerals();

    const origin = Origin.manual;

    graph.connect(graph.store(`single`, Lang.en, Sense.numeral, origin),
            Role(Rel.definedAs),
            graph.store(`1`, Lang.math, Sense.integer, origin),
            origin, 1.0);
    graph.connect(graph.store(`pair`, Lang.en, Sense.numeral, origin),
            Role(Rel.definedAs),
            graph.store(`2`, Lang.math, Sense.integer, origin),
            origin, 1.0);
    graph.connect(graph.store(`duo`, Lang.en, Sense.numeral, origin),
            Role(Rel.definedAs),
            graph.store(`2`, Lang.math, Sense.integer, origin),
            origin, 1.0);
    graph.connect(graph.store(`triple`, Lang.en, Sense.numeral, origin),
            Role(Rel.definedAs),
            graph.store(`3`, Lang.math, Sense.integer, origin),
            origin, 1.0);
    graph.connect(graph.store(`quadruple`, Lang.en, Sense.numeral, origin),
            Role(Rel.definedAs),
            graph.store(`4`, Lang.math, Sense.integer, origin),
            origin, 1.0);
    graph.connect(graph.store(`quintuple`, Lang.en, Sense.numeral, origin),
            Role(Rel.definedAs),
            graph.store(`5`, Lang.math, Sense.integer, origin),
            origin, 1.0);
    graph.connect(graph.store(`sextuple`, Lang.en, Sense.numeral, origin),
            Role(Rel.definedAs),
            graph.store(`6`, Lang.math, Sense.integer, origin),
            origin, 1.0);
    graph.connect(graph.store(`septuple`, Lang.en, Sense.numeral, origin),
            Role(Rel.definedAs),
            graph.store(`7`, Lang.math, Sense.integer, origin),
            origin, 1.0);

    // Greek Numbering
    // TODO Also Latin?
    graph.connect(graph.store(`tetra`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
            graph.store(`4`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.store(`penta`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
            graph.store(`5`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.store(`hexa`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
            graph.store(`6`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.store(`hepta`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
            graph.store(`7`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.store(`octa`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
            graph.store(`8`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.store(`nona`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
            graph.store(`9`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.store(`deca`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
            graph.store(`10`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.store(`hendeca`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
            graph.store(`11`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.store(`dodeca`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
            graph.store(`12`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.store(`trideca`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
            graph.store(`13`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.store(`tetradeca`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
            graph.store(`14`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.store(`pentadeca`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
            graph.store(`15`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.store(`hexadeca`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
            graph.store(`16`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.store(`heptadeca`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
            graph.store(`17`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.store(`octadeca`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
            graph.store(`18`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.store(`enneadeca`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
            graph.store(`19`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.store(`icosa`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
            graph.store(`20`, Lang.math, Sense.integer, origin), origin, 1.0);

    graph.learnEnglishOrdinalShorthands();
    graph.learnSwedishOrdinalShorthands();

    // Aggregate
    graph.connect(graph.store(`dozen`, Lang.en, Sense.numeral, origin),
            Role(Rel.definedAs),
            graph.store(`12`, Lang.math, Sense.integer, origin),
            origin, 1.0);
    graph.connect(graph.store(`baker's dozen`, Lang.en, Sense.numeral, origin),
            Role(Rel.definedAs),
            graph.store(`13`, Lang.math, Sense.integer, origin),
            origin, 1.0);
    graph.connect(graph.store(`tjog`, Lang.sv, Sense.numeral, origin),
            Role(Rel.definedAs),
            graph.store(`20`, Lang.math, Sense.integer, origin),
            origin, 1.0);
    graph.connect(graph.store(`flak`, Lang.sv, Sense.numeral, origin),
            Role(Rel.definedAs),
            graph.store(`24`, Lang.math, Sense.integer, origin),
            origin, 1.0);
    graph.connect(graph.store(`skock`, Lang.sv, Sense.numeral, origin),
            Role(Rel.definedAs),
            graph.store(`60`, Lang.math, Sense.integer, origin),
            origin, 1.0);

    graph.connectMto1(graph.store([`dussin`, `tolft`], Lang.sv, Sense.numeral, origin),
                Role(Rel.definedAs),
                graph.store(`12`, Lang.math, Sense.integer, origin),
                origin, 1.0);

    graph.connect(graph.store(`gross`, Lang.en, Sense.numeral, origin),
            Role(Rel.definedAs),
            graph.store(`144`, Lang.math, Sense.integer, origin),
            origin, 1.0);
    graph.connect(graph.store(`gross`, Lang.sv, Sense.numeral, origin), // TODO Support [Lang.en, Lang.sv]
            Role(Rel.definedAs),
            graph.store(`144`, Lang.math, Sense.integer, origin),
            origin, 1.0);

    graph.connect(graph.store(`small gross`, Lang.en, Sense.numeral, origin),
            Role(Rel.definedAs),
            graph.store(`120`, Lang.math, Sense.integer, origin),
            origin, 1.0);

    graph.connect(graph.store(`great gross`, Lang.en, Sense.numeral, origin),
            Role(Rel.definedAs),
            graph.store(`1728`, Lang.math, Sense.integer, origin),
            origin, 1.0);
}

/** Learn Roman (Latin) Numerals.
    See also: https://en.wikipedia.org/wiki/Roman_numerals#Reading_Roman_numerals
*/
void learnRomanLatinNumerals(Graph graph)
{
    enum origin = Origin.manual;

    enum pairs = [tuple(`I`, `1`),
                  tuple(`V`, `5`),
                  tuple(`X`, `10`),
                  tuple(`L`, `50`),
                  tuple(`C`, `100`),
                  tuple(`D`, `500`),
                  tuple(`M`, `1000`)];
    foreach (pair; pairs)
    {
        graph.connect(graph.store(pair[0], Lang.la, Sense.numeral, origin), Role(Rel.definedAs),
                graph.store(pair[1], Lang.math, Sense.integer, origin), origin, 1.0);
    }

    graph.connect(graph.store(`ūnus`, Lang.la, Sense.numeralMasculine, origin), Role(Rel.definedAs),
            graph.store(`1`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.store(`ūna`, Lang.la, Sense.numeralFeminine, origin), Role(Rel.definedAs),
            graph.store(`1`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.store(`ūnum`, Lang.la, Sense.numeralNeuter, origin), Role(Rel.definedAs),
            graph.store(`1`, Lang.math, Sense.integer, origin), origin, 1.0);

    graph.connect(graph.store(`duo`, Lang.la, Sense.numeralMasculine, origin), Role(Rel.definedAs),
            graph.store(`2`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.store(`duae`, Lang.la, Sense.numeralFeminine, origin), Role(Rel.definedAs),
            graph.store(`2`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.store(`duo`, Lang.la, Sense.numeralNeuter, origin), Role(Rel.definedAs),
            graph.store(`2`, Lang.math, Sense.integer, origin), origin, 1.0);

    graph.connect(graph.store(`trēs`, Lang.la, Sense.numeralMasculine, origin), Role(Rel.definedAs),
            graph.store(`3`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.store(`trēs`, Lang.la, Sense.numeralFeminine, origin), Role(Rel.definedAs),
            graph.store(`3`, Lang.math, Sense.integer, origin), origin, 1.0);
    graph.connect(graph.store(`tria`, Lang.la, Sense.numeralNeuter, origin), Role(Rel.definedAs),
            graph.store(`3`, Lang.math, Sense.integer, origin), origin, 1.0);

    graph.connect(graph.store(`quattuor`, Lang.la, Sense.numeral, origin), Role(Rel.definedAs),
            graph.store(`4`, Lang.math, Sense.integer, origin), origin, 1.0);

    graph.connect(graph.store(`quīnque`, Lang.la, Sense.numeral, origin), Role(Rel.definedAs),
            graph.store(`5`, Lang.math, Sense.integer, origin), origin, 1.0);

    graph.connect(graph.store(`sex`, Lang.la, Sense.numeral, origin), Role(Rel.definedAs),
            graph.store(`6`, Lang.math, Sense.integer, origin), origin, 1.0);

    graph.connect(graph.store(`septem`, Lang.la, Sense.numeral, origin), Role(Rel.definedAs),
            graph.store(`7`, Lang.math, Sense.integer, origin), origin, 1.0);

    graph.connect(graph.store(`octō`, Lang.la, Sense.numeral, origin), Role(Rel.definedAs),
            graph.store(`8`, Lang.math, Sense.integer, origin), origin, 1.0);

    graph.connect(graph.store(`novem`, Lang.la, Sense.numeral, origin), Role(Rel.definedAs),
            graph.store(`9`, Lang.math, Sense.integer, origin), origin, 1.0);

    graph.connect(graph.store(`decem`, Lang.la, Sense.numeral, origin), Role(Rel.definedAs),
            graph.store(`10`, Lang.math, Sense.integer, origin), origin, 1.0);

    graph.connect(graph.store(`quīnquāgintā`, Lang.la, Sense.numeral, origin), Role(Rel.definedAs),
            graph.store(`50`, Lang.math, Sense.integer, origin), origin, 1.0);

    graph.connect(graph.store(`Centum`, Lang.la, Sense.numeral, origin), Role(Rel.definedAs),
            graph.store(`50`, Lang.math, Sense.integer, origin), origin, 1.0);

    graph.connect(graph.store(`Quīngentī`, Lang.la, Sense.numeral, origin), Role(Rel.definedAs),
            graph.store(`100`, Lang.math, Sense.integer, origin), origin, 1.0);

    graph.connect(graph.store(`Mīlle`, Lang.la, Sense.numeral, origin), Role(Rel.definedAs),
            graph.store(`500`, Lang.math, Sense.integer, origin), origin, 1.0);
}

/** Learn English Ordinal Number Shorthands.
 */
void learnEnglishOrdinalShorthands(Graph graph)
{
    enum pairs = [tuple(`1st`, `first`),
                  tuple(`2nd`, `second`),
                  tuple(`3rd`, `third`),
                  tuple(`4th`, `fourth`),
                  tuple(`5th`, `fifth`),
                  tuple(`6th`, `sixth`),
                  tuple(`7th`, `seventh`),
                  tuple(`8th`, `eighth`),
                  tuple(`9th`, `ninth`),
                  tuple(`10th`, `tenth`),
                  tuple(`11th`, `eleventh`),
                  tuple(`12th`, `twelfth`),
                  tuple(`13th`, `thirteenth`),
                  tuple(`14th`, `fourteenth`),
                  tuple(`15th`, `fifteenth`),
                  tuple(`16th`, `sixteenth`),
                  tuple(`17th`, `seventeenth`),
                  tuple(`18th`, `eighteenth`),
                  tuple(`19th`, `nineteenth`),
                  tuple(`20th`, `twentieth`),
                  tuple(`21th`, `twenty-first`),
                  tuple(`30th`, `thirtieth`),
                  tuple(`40th`, `fourtieth`),
                  tuple(`50th`, `fiftieth`),
                  tuple(`60th`, `sixtieth`),
                  tuple(`70th`, `seventieth`),
                  tuple(`80th`, `eightieth`),
                  tuple(`90th`, `ninetieth`),
                  tuple(`100th`, `one hundredth`),
                  tuple(`1000th`, `one thousandth`),
                  tuple(`1000000th`, `one millionth`),
                  tuple(`1000000000th`, `one billionth`)];
    foreach (pair; pairs)
    {
        const abbr = pair[0];
        const ordinal = pair[1];
        graph.connect(graph.store(abbr, Lang.en, Sense.numeralOrdinal, Origin.manual), Role(Rel.abbreviationFor),
                graph.store(ordinal, Lang.en, Sense.numeralOrdinal, Origin.manual), Origin.manual, 1.0);
        graph.connect(graph.store(abbr[0 .. $-2] ~ `:` ~ abbr[$-2 .. $],
                      Lang.sv, Sense.numeralOrdinal, Origin.manual), Role(Rel.abbreviationFor),
                graph.store(ordinal,
                      Lang.sv, Sense.numeralOrdinal, Origin.manual), Origin.manual, 0.5);
    }
}

/** Learn Swedish Ordinal Shorthands.
 */
void learnSwedishOrdinalShorthands(Graph graph)
{
    enum pairs = [tuple(`1:a`, `första`),
                  tuple(`2:a`, `andra`),
                  tuple(`3:a`, `tredje`),
                  tuple(`4:e`, `fjärde`),
                  tuple(`5:e`, `femte`),
                  tuple(`6:e`, `sjätte`),
                  tuple(`7:e`, `sjunde`),
                  tuple(`8:e`, `åttonde`),
                  tuple(`9:e`, `nionde`),
                  tuple(`10:e`, `tionde`),
                  tuple(`11:e`, `elfte`),
                  tuple(`12:e`, `tolfte`),
                  tuple(`13:e`, `trettonde`),
                  tuple(`14:e`, `fjortonde`),
                  tuple(`15:e`, `femtonde`),
                  tuple(`16:e`, `sextonde`),
                  tuple(`17:e`, `sjuttonde`),
                  tuple(`18:e`, `artonde`),
                  tuple(`19:e`, `nittonde`),
                  tuple(`20:e`, `tjugonde`),
                  tuple(`21:a`, `tjugoförsta`),
                  tuple(`22:a`, `tjugoandra`),
                  tuple(`23:e`, `tjugotredje`),
                  // ..
                  tuple(`30:e`, `trettionde`),
                  tuple(`40:e`, `fyrtionde`),
                  tuple(`50:e`, `femtionde`),
                  tuple(`60:e`, `sextionde`),
                  tuple(`70:e`, `sjuttionde`),
                  tuple(`80:e`, `åttionde`),
                  tuple(`90:e`, `nittionde`),
                  tuple(`100:e`, `hundrade`),
                  tuple(`1000:e`, `tusende`),
                  tuple(`1000000:e`, `miljonte`)];
    foreach (pair; pairs)
    {
        graph.connect(graph.store(pair[0], Lang.sv, Sense.numeralOrdinal, Origin.manual), Role(Rel.abbreviationFor),
                graph.store(pair[1], Lang.sv, Sense.numeralOrdinal, Origin.manual), Origin.manual, 1.0);
    }
}

/** Learn Math.
 */
void learnPhysics(Graph graph)
{
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/si_base_unit_name.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `SI base unit name noun`, Sense.baseSIUnit, Sense.noun, 1.0);
    // TODO Name Symbol, Quantity, In SI units, In Si base units
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/si_derived_unit_name.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `SI derived unit name noun`, Sense.derivedSIUnit, Sense.noun, 1.0);
}

void learnComputers(Graph graph)
{
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/programming_language.txt`).splitter('\n').filter!(w => !w.empty),
              Role(Rel.instanceOf), `programming language`, Sense.languageProgramming, Sense.language, 1.0);
    graph.learnCode();
}

void learnCode(Graph graph)
{
    graph.learnCodeInGeneral();
    graph.learnDCode;
}

void learnCodeInGeneral(Graph graph)
{
    graph.connect(graph.store(`keyword`, Lang.en, Sense.adjective, Origin.manual), Role(Rel.synonymFor),
            graph.store(`reserved word`, Lang.en, Sense.adjective, Origin.manual), Origin.manual, 1.0, true);
}

void learnDCode(Graph graph)
{
    enum attributes = [`@property`, `@safe`, `@trusted`, `@system`, `@disable`];

    graph.connectMto1(graph.store(attributes, Lang.d, Sense.unknown, Origin.manual), Role(Rel.instanceOf),
                graph.store("attribute", Lang.d, Sense.nounAbstract, Origin.manual), Origin.manual, 1.0);

    enum keywords = [`abstract`, `alias`, `align`, `asm`,
                     `assert`, `auto`, `body`, `bool`,
                     `byte`, `case`, `cast`, `catch`,
                     `char`, `class`, `const`, `continue`,
                     `dchar`, `debug`, `default`, `delegate`,
                     `deprecated`, `do`, `double`, `else`,
                     `enum`, `export`, `extern`, `false`,
                     `final`, `finally`, `float`, `for`,
                     `foreach`, `function`, `goto`, `if`,
                     `import`, `in`, `inout`, `int`,
                     `interface`, `invariant`, `is`, `long`,
                     `macro`, `mixin`, `module`, `new`,
                     `null`, `out`, `override`, `package`,
                     `pragma`, `private`, `protected`, `public`,
                     `real`, `ref`, `return`, `scope`,
                     `short`, `static`, `struct`, `super`,
                     `switch`, `synchronized`, `template`, `this`,
                     `throw`, `true`, `try`, `typeid`,
                     `typeof`, `ubyte`, `uint`, `ulong`,
                     `union`, `unittest`, `ushort`, `version`,
                     `void`, `wchar`, `while`, `with` ];

    graph.connectMto1(graph.store(keywords, Lang.d, Sense.unknown, Origin.manual), Role(Rel.instanceOf),
                graph.store("keyword", Lang.d, Sense.nounAbstract, Origin.manual), Origin.manual, 1.0);

    enum elements = [ tuple(`AA`, `associative array`),
                      tuple(`AAs`, `associative arrays`),

                      tuple(`mut`, `mutable`),
                      tuple(`imm`, `immutable`),
                      tuple(`const`, `constant`),

                      tuple(`int`, `integer`),
                      tuple(`long`, `long integer`),
                      tuple(`short`, `short integer`),
                      tuple(`cent`, `cent integer`),

                      tuple(`uint`, `unsigned integer`),
                      tuple(`ulong`, `unsigned long integer`),
                      tuple(`ushort`, `unsigned short integer`),
                      tuple(`ucent`, `unsigned cent integer`),

                      tuple(`ctor`, `constructor`),
                      tuple(`dtor`, `destructor`),
        ];

    foreach (e; elements)
    {
        graph.connect(graph.store(e[0], Lang.d, Sense.unknown, Origin.manual), Role(Rel.abbreviationFor),
                      graph.store(e[1], Lang.d, Sense.unknown, Origin.manual), Origin.manual, 1.0);
    }
}

/** Learn English Irregular Verbs.
 */
void learnEnglishOther(Graph graph)
{
    graph.connectMto1(graph.store([`preserve food`,
                                   `cure illness`,
                                   `augment cosmetics`],
                                  Lang.en, Sense.noun, Origin.manual),
                      Role(Rel.uses),
                      graph.store(`herb`, Lang.en, Sense.noun, Origin.manual),
                      Origin.manual, 1.0);

    graph.connectMto1(graph.store([`enrich taste of food`,
                                   `improve taste of food`,
                                   `increase taste of food`],
                                  Lang.en, Sense.noun, Origin.manual),
                      Role(Rel.uses),
                      graph.store(`spice`, Lang.en, Sense.noun, Origin.manual),
                      Origin.manual, 1.0);

    graph.connect1toM(graph.store(`herb`, Lang.en, Sense.noun, Origin.manual),
                      Role(Rel.madeOf),
                      graph.store([`leaf`, `plant`], Lang.en, Sense.noun, Origin.manual),
                      Origin.manual, 1.0);

    graph.connect1toM(graph.store(`spice`, Lang.en, Sense.noun, Origin.manual),
                      Role(Rel.madeOf),
                      graph.store([`root`, `plant`], Lang.en, Sense.noun, Origin.manual),
                      Origin.manual, 1.0);
}

/** Learn Swedish (Regular) Verbs.
 */
void learnSwedishRegularVerbs(Graph graph)
{
    graph.learnSwedishIrregularVerb(`kläd`, `kläda`, `kläder`, `klädde`, `klätt`);
    graph.learnSwedishIrregularVerb(`pryd`, `pryda`, `pryder`, `prydde`, `prytt`);
}

/** Learn Swedish (Irregular) Verbs.
 */
void learnSwedishIrregularVerbs(Graph graph)
{
    graph.learnSwedishIrregularVerb(`eka`, `eka`, `ekar`, `ekade`, `ekat`); // English:echo
    graph.learnSwedishIrregularVerb(`ge`, `ge`, `ger`, `gav`, `gett`);
    graph.learnSwedishIrregularVerb(`ge`, `ge`, `ger`, `gav`, `givit`);
    graph.learnSwedishIrregularVerb(`ange`, `ange`, `anger`, `angav`, `angett`);
    graph.learnSwedishIrregularVerb(`ange`, `ange`, `anger`, `angav`, `angivit`);
    graph.learnSwedishIrregularVerb(`anse`, `anse`, `anser`, `ansåg`, `ansett`);
    graph.learnSwedishIrregularVerb(`avgör`, `avgöra`, `avgör`, `avgjorde`, `avgjort`);
    graph.learnSwedishIrregularVerb(`avstå`, `avstå`, `avstår`, `avstod`, `avstått`);
    graph.learnSwedishIrregularVerb(`be`, `be`, `ber`, `bad`, `bett`);
    graph.learnSwedishIrregularVerb(`bestå`, `bestå`, `består`, `bestod`, `bestått`);
    graph.learnSwedishIrregularVerb([], [], `bör`, `borde`, `bort`);
    graph.learnSwedishIrregularVerb(`dra`, `dra`, `drar`, `drog`, `dragit`);
    graph.learnSwedishIrregularVerb([], `duga`, `duger`, `dög`, `dugit`); // TODO [`dög`, `dugde`]
    graph.learnSwedishIrregularVerb([], `duga`, `duger`, `dugde`, `dugit`);
    graph.learnSwedishIrregularVerb(`dyk`, `dyka`, `dyker`, `dök`, `dykit`); // TODO [`dök`, `dykte`]
    graph.learnSwedishIrregularVerb(`dyk`, `dyka`, `dyker`, `dykte`, `dykit`);
    graph.learnSwedishIrregularVerb(`dö`, `dö`, `dör`, `dog`, `dött`);
    graph.learnSwedishIrregularVerb(`dölj`, `dölja`, `döljer`, `dolde`, `dolt`);
    graph.learnSwedishIrregularVerb(`ersätt`, `ersätta`, `ersätter`, `ersatte`, `ersatt`);
    graph.learnSwedishIrregularVerb(`fortsätt`, `fortsätta`, `fortsätter`, `fortsatte`, `fortsatt`);
    graph.learnSwedishIrregularVerb(`framstå`, `framstå`, `framstår`, `framstod`, `framstått`);
    graph.learnSwedishIrregularVerb(`få`, `få`, `får`, `fick`, `fått`);
    graph.learnSwedishIrregularVerb(`förstå`, `förstå`, `förstår`, `förstod`, `förstått`);
    graph.learnSwedishIrregularVerb(`förutsätt`, `förutsätta`, `förutsätter`, `förutsatte`, `förutsatt`);
    graph.learnSwedishIrregularVerb(`gläd`, `glädja`, `gläder`, `gladde`, `glatt`);
    graph.learnSwedishIrregularVerb(`gå`, `gå`, `går`, `gick`, `gått`);
    graph.learnSwedishIrregularVerb(`gör`, `göra`, `gör`, `gjorde`, `gjort`);
    graph.learnSwedishIrregularVerb(`ha`, `ha`, `har`, `hade`, `haft`);
    graph.learnSwedishIrregularVerb([], `heta`, `heter`, `hette`, `hetat`);
    graph.learnSwedishIrregularVerb([], `ingå`, `ingår`, `ingick`, `ingått`);
    graph.learnSwedishIrregularVerb(`inse`, `inse`, `inser`, `insåg`, `insett`);
    graph.learnSwedishIrregularVerb(`kom`, `komma`, `kommer`, `kom`, `kommit`);
    graph.learnSwedishIrregularVerb([], `kunna`, `kan`, `kunde`, `kunnat`);
    graph.learnSwedishIrregularVerb(`le`, `le`, `ler`, `log`, `lett`);
    graph.learnSwedishIrregularVerb(`lev`, `leva`, `lever`, `levde`, `levt`);
    graph.learnSwedishIrregularVerb(`ligg`, `ligga`, `ligger`, `låg`, `legat`);
    graph.learnSwedishIrregularVerb(`lägg`, `lägga`, `lägger`, `la`, `lagt`);
    graph.learnSwedishIrregularVerb(`missförstå`, `missförstå`, `missförstår`, `missförstod`, `missförstått`);
    graph.learnSwedishIrregularVerb([], [], `måste`, `var tvungen`, `varit tvungen`);
    graph.learnSwedishIrregularVerb(`se`, `se`, `ser`, `såg`, `sett`);
    graph.learnSwedishIrregularVerb(`skilj`, `skilja`, `skiljer`, `skilde`, `skilt`);
    graph.learnSwedishIrregularVerb([], [], `ska`, `skulle`, []);
    graph.learnSwedishIrregularVerb(`smaksätt`, `smaksätta`, `smaksätter`, `smaksatte`, `smaksatt`);
    graph.learnSwedishIrregularVerb(`sov`, `sova`, `sover`, `sov`, `sovit`);
    graph.learnSwedishIrregularVerb(`sprid`, `sprida`, `sprider`, `spred`, `spridit`);
    graph.learnSwedishIrregularVerb(`stjäl`, `stjäla`, `stjäl`, `stal`, `stulit`);
    graph.learnSwedishIrregularVerb(`stå`, `stå`, `står`, `stod`, `stått`);
    graph.learnSwedishIrregularVerb(`stöd`, `stödja`, `stöder`, `stödde`, `stött`);
    graph.learnSwedishIrregularVerb(`svälj`, `svälja`, `sväljer`, `svalde`, `svalt`);
    graph.learnSwedishIrregularVerb(`säg`, `säga`, `säger`, `sa`, `sagt`);
    graph.learnSwedishIrregularVerb(`sälj`, `sälja`, `säljer`, `sålde`, `sålt`);
    graph.learnSwedishIrregularVerb(`sätt`, `sätta`, `sätter`, `satte`, `satt`);
    graph.learnSwedishIrregularVerb(`ta`, `ta`, `tar`, `tog`, `tagit`);
    graph.learnSwedishIrregularVerb(`tillsätt`, `tillsätta`, `tillsätter`, `tillsatte`, `tillsatt`);
    graph.learnSwedishIrregularVerb(`umgås`, `umgås`, `umgås`, `umgicks`, `umgåtts`);
    graph.learnSwedishIrregularVerb(`uppge`, `uppge`, `uppger`, `uppgav`, `uppgivit`);
    graph.learnSwedishIrregularVerb(`utgå`, `utgå`, `utgår`, `utgick`, `utgått`);
    graph.learnSwedishIrregularVerb(`var`, `vara`, `är`, `var`, `varit`);
    graph.learnSwedishIrregularVerb([], `veta`, `vet`, `visste`, `vetat`);
    graph.learnSwedishIrregularVerb(`vik`, `vika`, `viker`, `vek`, `vikt`);
    graph.learnSwedishIrregularVerb([], `vilja`, `vill`, `ville`, `velat`);
    graph.learnSwedishIrregularVerb(`välj`, `välja`, `väljer`, `valde`, `valt`);
    graph.learnSwedishIrregularVerb(`vänj`, `vänja`, `vänjer`, `vande`, `vant`);
    graph.learnSwedishIrregularVerb(`väx`, `växa`, `växer`, `växte`, `växt`);
    graph.learnSwedishIrregularVerb(`återge`, `återge`, `återger`, `återgav`, `återgivit`);
    graph.learnSwedishIrregularVerb(`översätt`, `översätta`, `översätter`, `översatte`, `översatt`);
    graph.learnSwedishIrregularVerb(`tyng`, `tynga`, `tynger`, `tyngde`, `tyngt`);
    graph.learnSwedishIrregularVerb(`glöm`, `glömma`, `glömmer`, `glömde`, `glömt`);
    graph.learnSwedishIrregularVerb(`förgät`, `förgäta`, `förgäter`, `förgat`, `förgätit`);

    // TODO Allow alternatives for all arguments
    static if (false)
    {
        graph.learnSwedishIrregularVerb(`ids`, `idas`, [`ids`, `ides`], `iddes`, [`itts`, `idats`]);
        graph.learnSwedishIrregularVerb(`gitt`, `gitta;1`, `gitter`, [`gitte`, `get`, `gat`], `gittat;1`);
    }

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
