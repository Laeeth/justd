module knet.senses;

import std.traits: isSomeChar, isSomeString;

/** Human Word Sense (Category). */
enum Sense:ubyte
{
    unknown,

    language,
    languageNatural, languageHuman = languageNatural,
    languageProgramming,

    prefix,                     /// Word prefix, commin in Latin
    beginning = prefix,         /// Word beginning
    suffix,                     /// Word suffix, common in Latin languages
    ending = suffix,            /// Word ending

    letter,
    letterLowercase,
    letterUppercase,
    word,
    phrase,                     /// Phrase.

    nounPhrase, /// Noun Phrase. See also: https://en.wikipedia.org/wiki/Moby_Project#Hyphenator
    idiom,                      /// Idiomatic Expression.

    punctuation,

    noun,

    nounNeuter,

    nounCollective,
    nounCollectivePeople,
    nounCollectiveCreatures,
    nounCollectiveThings,

    nounRegular,
    nounIrregular,

    nounSingular,               // Swedish: skog, English: forest
    nounSingularIndefinite,     // Swedish: en skog, English: a forest
    nounSingularDefinite,       // Swedish: skogen, English: the forest

    nounSingularMale,
    nounSingularFemale,
    nounSingularNeuter,

    nounPlural,
    nounPluralMale,
    nounPluralFemale,
    nounPluralNeuter,

    nounUncountable, uncountable = nounUncountable,

    nounNominative,

    nounDemonym, demonym = nounDemonym, // https://en.wikipedia.org/wiki/Demonym
    nounDemonymSingular,
    nounDemonymSingularMale,
    nounDemonymSingularFemale,
    nounDemonymPlural,
    nounDemonymPluralMale,
    nounDemonymPluralFemale,

    numeric,

    plant,
    food,
    spice,

    material,
    substance,
    metal,

    quantifier,
    quantifierOfSingularNoun,
    quantifierOfPluralNoun,
    quantifierOfUncountableNoun,

    numeral,
    numeralMasculine,
    numeralFeminine,
    numeralNeuter,

    numeralOrdinal,
    ordinalNumber = numeralOrdinal, ///< https://en.wikipedia.org/wiki/Ordinal_number_%28linguistics%29
    rank = ordinalNumber,
    numeralFraction,

    integer,                /// 11
    integerPositive,        /// 0,1, ...
    integerNegative,        /// ..., -1, 0

    decimal,                /// 3.14

    numberRational,         /// 1/3
    numberIrrational,       /// sqrt(2), pi, e
    numberTranscendental,   /// pi, e
    numberComplex,          /// 1 + 2i

    population,

    name, properNoun = name, properName = properNoun, eigenName = properName, /// name, or proper noun
    nameMale,               /// proper name
    nameFemale,             /// proper name
    surname,                /// proper surname

    location,                   /// Stockholm
    namePerson,                 /// John
    organisation,               /// CIA

    region,
    island,
    city,                       /// Skänninge
    county,                     /// Cornwall
    province,
    state,                      /// Ohio
    country,                    /// Sweden
    continent,                  /// Europe
    newspaper,                  /// Tidning

    timePeriod,
    weekday,
    month,
    dayOfMonth,
    year,
    dayOfYear, nounDate = dayOfYear,

    season,

    abbrevation,
    contraction,            /// can't instead of can not
    nounAbbrevation,
    nounAcronym,

    baseSIUnit,
    derivedSIUnit,

    /* Verb */

    verb,

    verbTransitive,
    verbIntransitive,
    verbReflexive,

    verbRegular,
    verbIrregular,

    verbAbbrevation,

    verbImperative,

    verbInfinitive, verbBase = verbInfinitive,
    verbRegularInfinitive,
    verbIrregularInfinitive,

    verbPresent,
    verbPresentSingular1st,
    verbPresentSingular2nd,
    verbPresentSingular3rd,
    verbPresentPlural1st,
    verbPresentPlural2nd,
    verbPresentPlural3rd,

    verbPast, verbImperfect = verbPast, /// See also: https://en.wikipedia.org/wiki/Imperfect
    verbRegularPast,
    verbIrregularPast,

    verbPastParticiple, verbSupinum = verbPastParticiple,
    verbRegularPastParticiple,
    verbIrregularPastParticiple,

    verbFuture, /// See also: https://en.wikipedia.org/wiki/Future_tense
    verbFuturum = verbFuture,
    verbFuturumI,
    verbFuturumII,

    auxiliaryVerb, /// See also: https://en.wikipedia.org/wiki/Auxiliary_verb. "Hjälpverb" in Swedish
    auxiliaryVerbModal, /// Modalt Hjälpverb

    /* Adjective */

    adjective,
    adjectiveDemonym,           // Brittish, bajersk
    adjectiveMale,
    adjectiveFeminine,
    adjectiveNeuter,

    adjectiveRegular,
    adjectiveIrregular,
    adjectiveAbbrevation,

    adjectiveNominative,
    adjectiveComparative,
    adjectiveSuperlative,
    adjectiveElative,
    adjectiveExzessive,

    adjectivePossessive,
    adjectivePossessiveSingular,
    adjectivePossessivePlural,

    adjectivePredicateOnly, /** Contextually dependent adjective relating to
                            subject. Found after linking verbs (verbLinking).  An adjective
                            that can be used only in predicate positions. If X
                            is a predicate adjective, it can only be used in
                            such phrases as "it is X " and never prenominally.
                            Examples: - The shoes look expensive.  - The man is
                            asleep.  - The animal is dead.
                        */

    adverb, /// changes or simplifies the meaning of a verb, adjective, other adverb, clause, or sentence.
    normalAdverb,
    timeAdverb,
    placeAdverb,
    frequencyAdverb,
    conjunctiveAdverb, adverbialConjunction = conjunctiveAdverb, /// joins together sentences
    negatingAdverb,
    affirmingAdverb,

    preposition, /// often ambiguous
    prepositionTime, /// only related to time
    prepositionPosition, /// only related to space (position)
    // prepositionPlace = prepositionPosition,
    prepositionDirection, /// only related to space change (velocity)

    pronoun, /// See also: https://www.englishclub.com/grammar/pronouns.htm

    pronounPersonal,  /// See also: https://www.englishclub.com/grammar/pronouns-personal.htm

    pronounPersonalSingular, /// See also: https://www.englishclub.com/grammar/pronouns-personal.htm

    pronounPersonalSingular1st, pronounPersonalSingularSubjective = pronounPersonalSingular1st,
    pronounPersonalSingular2nd,
    pronounPersonalSingular3rd,

    pronounPersonalSingularMale,
    pronounPersonalSingularMale1st, pronounPersonalSingularMaleSubjective = pronounPersonalSingularMale1st,
    pronounPersonalSingularMale2nd,

    pronounPersonalSingularFemale,
    pronounPersonalSingularFemale1st, pronounPersonalSingularFemaleSubjective = pronounPersonalSingularFemale1st,
    pronounPersonalSingularFemale2nd,

    pronounPersonalSingularNeutral,

    pronounPersonalPlural, /// See also: https://www.englishclub.com/grammar/pronouns-personal.htm
    pronounPersonalPlural1st,
    pronounPersonalPlural2nd,
    pronounPersonalPlural3rd,

    pronounDemonstrative, /// See also: https://www.englishclub.com/grammar/pronouns-demonstrative.htm
    pronounDemonstrativeSingular,
    pronounDemonstrativePlural,

    pronounDeterminative,
    pronounDeterminativeSingular,
    pronounDeterminativePlural,

    pronounPossessive, /// See also: https://www.englishclub.com/grammar/pronouns-possessive.htm

    pronounPossessiveSingular, /// See also: https://www.englishclub.com/grammar/pronouns-possessive.htm
    pronounPossessiveSingular1st,
    pronounPossessiveSingular2nd,
    pronounPossessiveSingularMale,

    pronounPossessiveSingularFemale,
    pronounPossessiveSingularNeutral,

    pronounPossessivePlural, /// See also: https://www.englishclub.com/grammar/pronouns-possessive.htm
    pronounPossessivePlural1st,
    pronounPossessivePlural2nd,
    pronounPossessivePlural3rd,

    pronounInterrogative, /// See also: https://www.englishclub.com/grammar/pronouns-reciprocal.htm

    pronounReflexive,
    pronounReflexiveSingular,
    pronounReflexivePlural,

    pronounReciprocal,

    pronounIndefinite,
    pronounIndefiniteSingular,
    pronounIndefinitePlural,

    pronounRelative, /// See also: https://www.englishclub.com/grammar/pronouns-relative.htm

    determiner,
    predeterminer,

    article,
    articleIndefinite,
    articleDefinite,
    articlePartitive,

    conjunction, /// See also: http://www.smart-words.org/linking-words/conjunctions.html
    conjunctionCoordinating,
    conjunctionSubordinating, subordinator = conjunctionSubordinating,
    conjunctionSubordinatingConcession,
    conjunctionSubordinatingCondition,
    conjunctionSubordinatingComparison,
    conjunctionSubordinatingTime,
    conjunctionSubordinatingReason,
    conjunctionSubordinatingAdjective,
    conjunctionSubordinatingPronoun,
    conjunctionSubordinatingManner,
    conjunctionSubordinatingPlace,
    conjunctionCorrelative,

    interjection, exclamation = interjection,

    /// Programming Language
    code,
    codeOperator,
    codeOperatorAssignment,
    codeFunction,
    codeFunctionReference,
    codeVariable,
    codeVariableReference,
    codeType,
}

/// Check if $(D sense) is a noun acting as subject.
bool isSubjectivePronoun(Sense sense)
{
    with (Sense) return sense.among!(pronounPersonalSingular1st,
                                     pronounPersonalSingular2nd,
                                     pronounPersonalPlural1st,
                                     pronounPersonalPlural2nd) != 0;
}

/// Check if $(D sense) is a noun acting as object.
bool isObjectivePronoun(Sense sense)
{
    with (Sense) return sense.among!(pronounPersonalSingular3rd,
                                     pronounPersonalPlural3rd) != 0;
}

string toHuman(Sense sense) @safe pure @nogc nothrow
{
    final switch (sense) with (Sense)
    {
        case unknown: return `unknown`;

        case language: return `language`;
        case languageNatural: return `natural language`;
        case languageProgramming: return `programming language`;

        case prefix: return `prefix`;
        case suffix: return `suffix`;

        case letter: return `letter`;
        case letterLowercase: return `lowercase letter`;
        case letterUppercase: return `uppercase letter`;
        case word: return `word`;
        case phrase: return `phrase`;
        case nounPhrase: return `noun phrase`;
        case idiom: return `idiom`;

        case punctuation: return `punctuation`;

        case noun: return `noun`;
        case nounNeuter: return `neuter noun`;
        case nounCollective: return `collective noun`;
        case nounCollectivePeople: return `collective noun people`;
        case nounCollectiveCreatures: return `collective noun creatures`;
        case nounCollectiveThings: return `collective noun things`;
        case nounRegular: return `regular noun`;
        case nounIrregular: return `irregular noun`;

        case nounSingular: return `singular noun`;
        case nounSingularDefinite: return `definite singular noun`;
        case nounSingularIndefinite: return `indefinite singular noun`;

        case nounSingularMale: return `male singular noun`;
        case nounSingularFemale: return `female singular noun`;
        case nounSingularNeuter: return `neuter singular noun`;

        case nounPlural: return `plural noun`;
        case nounPluralMale: return `male plural noun`;
        case nounPluralFemale: return `female plural noun`;
        case nounPluralNeuter: return `neuter plural noun`;

        case nounDemonym: return "demonym";
        case nounDemonymSingular: return "singular demonym";
        case nounDemonymSingularMale: return "singular male demonym";
        case nounDemonymSingularFemale: return "singular female demonym";
        case nounDemonymPlural: return "plural demonym";
        case nounDemonymPluralMale: return "plural male demonym";
        case nounDemonymPluralFemale: return "plural female demonym";

        case nounNominative: return `nominative noun`;

        case numeric: return `numeric`;

        case plant: return `plant`;
        case food: return `food`;
        case spice: return `spice`;

        case substance: return `substance`;
        case material: return `material`;
        case metal: return `metal`;

        case quantifier: return `quantifier`;
        case quantifierOfSingularNoun: return `quantifier of singular noun`;
        case quantifierOfPluralNoun: return `quantifier of plural noun`;
        case quantifierOfUncountableNoun: return `quantifier of uncountable noun`;

        case numeral: return `numeral`;
        case numeralOrdinal: return `ordinal numeral`;
        case numeralFraction: return `fraction numeral`;
        case numeralMasculine: return `masculine numeral`;
        case numeralFeminine: return `feminine numeral`;
        case numeralNeuter: return `neuter numeral`;

        case integer: return `integer`;
        case integerPositive: return `positive integer`;
        case integerNegative: return `negative integer`;

        case decimal: return `decimal`;

        case numberRational: return `rational number`;
        case numberIrrational: return `irrational number`;
        case numberTranscendental: return `transcendental number`;
        case numberComplex: return `complex number`;

        case population: return `population`;

        case name: return `name`;
        case nameMale: return `male name`;
        case nameFemale: return `female name`;
        case surname: return `surname`;

        case location: return `location name`;
        case namePerson: return `person name`;
        case organisation: return `organisation name`;
        case region: return `region`;
        case island: return `island`;
        case city: return `city`;
        case county: return `county`;
        case province: return `province`;
        case state: return `state`;
        case country: return `country`;
        case continent: return `continent`;
        case newspaper: return `newspaper`;

        case timePeriod: return `time period`;
        case weekday: return `weekday`;
        case month: return `month`;
        case dayOfMonth: return `day of month`;
        case year: return `year`;
        case dayOfYear: return `day of year`;

        case season: return `season`;

        case nounUncountable: return `uncountable`;

        case abbrevation: return `abbrevation`;
        case contraction: return `contraction`;
        case nounAbbrevation: return `noun abbrevation`;
        case nounAcronym: return `noun acronym`;

        case baseSIUnit: return `base SI unit`;
        case derivedSIUnit: return `derived SI unit`;

        case verb: return `verb`;
        case verbTransitive: return `transitive verb`;
        case verbIntransitive: return `intransitive verb`;
        case verbReflexive: return `reflexive verb`;
        case verbRegular: return `regular verb`;
        case verbIrregular: return `irregular verb`;

        case verbAbbrevation: return `verb abbrevation`;

        case verbImperative: return `verb imperative`;

        case verbInfinitive: return `verb infinitive`;

        case verbPresent: return `verb present`;
        case verbPresentSingular1st: return `verb present 1st person singular`;
        case verbPresentSingular2nd: return `verb present 2nd person singular`;
        case verbPresentSingular3rd: return `verb present 3rd person singular`;
        case verbPresentPlural1st: return `verb present 1st person plural`;
        case verbPresentPlural2nd: return `verb present 2nd person plural`;
        case verbPresentPlural3rd: return `verb present 3rd person plural`;

        case verbRegularInfinitive: return `verb regular infinitive`;
        case verbIrregularInfinitive: return `verb irregular infinitive`;

        case verbPast: return `regular past`;
        case verbRegularPast: return `regular verb past`;
        case verbIrregularPast: return `irregular verb past`;

        case verbPastParticiple: return `verb past participle`;
        case verbRegularPastParticiple: return `verb regular past participle`;
        case verbIrregularPastParticiple: return `verb irregular past participle`;

        case verbFuture: return `verb future`;
        case verbFuturumI: return `verb futurum I`;
        case verbFuturumII: return `verb futurum II`;

        case auxiliaryVerb: return `auxiliary verb`;
        case auxiliaryVerbModal: return `modal auxiliary verb`;

        case adjective: return `adjective`;

        case adjectiveDemonym: return `demonym adjective`;
        case adjectiveMale: return `male adjective`;
        case adjectiveFeminine: return `feminine adjective`;
        case adjectiveNeuter: return `neuter adjective`;

        case adjectivePredicateOnly: return `predicate only adjective`;
        case adjectiveRegular: return `regular adjective`;
        case adjectiveIrregular: return `irregular adjective`;
        case adjectiveAbbrevation: return `adjective abbrevation`;

        case adjectiveNominative: return `adjective nominative`;
        case adjectiveComparative: return `adjective comparative`;
        case adjectiveSuperlative: return `adjective superlative`;
        case adjectiveElative: return `adjective elative`;
        case adjectiveExzessive: return `adjective exzessive`;

        case adjectivePossessive: return `possessive adjective`;
        case adjectivePossessiveSingular: return `possessive adjective singular`;
        case adjectivePossessivePlural: return `possessive adjective plural`;

        case adverb: return `adverb`;
        case normalAdverb: return `normal adverb`;
        case timeAdverb: return `time adverb`;
        case placeAdverb: return `place adverb`;
        case frequencyAdverb: return `frequency adverb`;
        case conjunctiveAdverb: return `conjunctive adverb`;
        case negatingAdverb: return `negating adverb`;
        case affirmingAdverb: return `affirming adverb`;

        case preposition: return `preposition`;
        case prepositionTime: return `time preposition`;
        case prepositionPosition: return `position preposition`;
        case prepositionDirection: return `direction preposition`;

        case pronoun: return `pronoun`;

        case pronounPersonal: return `personal pronoun`;
        case pronounPersonalSingular: return `personal pronoun singular`;

        case pronounPersonalSingular1st: return `personal pronoun singular 1st-person`;
        case pronounPersonalSingular2nd: return `personal pronoun singular 2nd-person`;
        case pronounPersonalSingular3rd: return `personal pronoun singular 3rd-person`;

        case pronounPersonalSingularMale: return `male personal pronoun singular`;
        case pronounPersonalSingularMale1st: return `male personal pronoun singular 1st person`;
        case pronounPersonalSingularMale2nd: return `male personal pronoun singular 2nd person`;

        case pronounPersonalSingularFemale: return `female personal pronoun singular`;
        case pronounPersonalSingularFemale1st: return `female personal pronoun singular 1st person`;
        case pronounPersonalSingularFemale2nd: return `female personal pronoun singular 2nd person`;

        case pronounPersonalSingularNeutral: return `neutral personal pronoun singular`;

        case pronounPersonalPlural: return `personal pronoun plural`;
        case pronounPersonalPlural1st: return `personal pronoun plural 1st-person`;
        case pronounPersonalPlural2nd: return `personal pronoun plural 2nd-person`;
        case pronounPersonalPlural3rd: return `personal pronoun plural 3rd-person`;

        case pronounDemonstrative: return `demonstrative pronoun`;
        case pronounDemonstrativeSingular: return `demonstrative pronoun singular`;
        case pronounDemonstrativePlural: return `demonstrative pronoun plural`;

        case pronounDeterminative: return `determinative pronoun`;
        case pronounDeterminativeSingular: return `determinative pronoun singular`;
        case pronounDeterminativePlural: return `determinative pronoun plural`;

        case pronounPossessive: return `possessive pronoun`;

        case pronounPossessiveSingular: return `possessive pronoun singular`;
        case pronounPossessiveSingular1st: return `possessive pronoun singular 1st-person`;
        case pronounPossessiveSingular2nd: return `possessive pronoun singular 2nd-person`;
        case pronounPossessiveSingularMale: return `possessive pronoun singular male-person`;

        case pronounPossessiveSingularFemale: return `possessive pronoun singular female`;
        case pronounPossessiveSingularNeutral: return `possessive pronoun singular neutral`;

        case pronounPossessivePlural: return `possessive pronoun plural`;
        case pronounPossessivePlural1st: return `possessive pronoun plural 1st-person`;
        case pronounPossessivePlural2nd: return `possessive pronoun plural 2nd-person`;
        case pronounPossessivePlural3rd: return `possessive pronoun plural 3rd-person`;

        case pronounInterrogative: return `interrogative pronoun`;

        case pronounReflexive: return `reflexive pronoun `;
        case pronounReflexiveSingular: return `reflexive pronoun singular`;
        case pronounReflexivePlural: return `reflexive pronoun plural`;

        case pronounReciprocal: return `reciprocal pronoun`;

        case pronounIndefinite: return `indefinite pronoun`;
        case pronounIndefiniteSingular: return `indefinite pronoun singular`;
        case pronounIndefinitePlural: return `indefinite pronoun plural`;

        case pronounRelative: return `relative pronoun`;

        case determiner: return `determiner`;
        case predeterminer: return `predeterminer`;

        case article: return `article`;
        case articleIndefinite: return `undefinite article`;
        case articleDefinite: return `definite article`;
        case articlePartitive: return `partitive article`;

        case conjunction: return `conjunction`;
        case conjunctionCoordinating: return `coordinating conjunction`;
        case conjunctionSubordinating: return `subordinating conjunction`;
        case conjunctionSubordinatingConcession: return `subordinating conjunction concession`;
        case conjunctionSubordinatingCondition: return `subordinating conjunction condition`;
        case conjunctionSubordinatingComparison: return `subordinating conjunction comparison`;
        case conjunctionSubordinatingTime: return `subordinating conjunction time`;
        case conjunctionSubordinatingReason: return `subordinating conjunction reason`;
        case conjunctionSubordinatingAdjective: return `subordinating conjunction adjective`;
        case conjunctionSubordinatingPronoun: return `subordinating conjunction pronoun`;
        case conjunctionSubordinatingManner: return `subordinating conjunction manner`;
        case conjunctionSubordinatingPlace: return `subordinating conjunction place`;
        case conjunctionCorrelative: return `correlative conjunction`;

        case interjection: return `interjection`;

        case code: return `code`;
        case codeOperator: return `code operator`;
        case codeOperatorAssignment: return `code assignment operator`;
        case codeFunction: return `code function`;
        case codeFunctionReference: return `code function reference`;
        case codeVariable: return `code variable`;
        case codeVariableReference: return `code variable reference`;
        case codeType: return `code type`;
    }
}

/** Decode character $(D senseChar) into a $(D Sense). */
Sense decodeWordSense(C)(C senseChar) if (isSomeChar!C)
{
    switch (senseChar) with (Sense)
                       {
                           case 'n': return noun;
                           case 'v': return verb;
                           case 'a': return adjective;
                           case 'r': return adverb;
                           default: return unknown;
                       }
}

unittest
{
    assert('n'.decodeWordSense == Sense.noun);
}

/** Decode string $(D senseCode) into a $(D Sense). */
Sense decodeWordSense(S)(S senseCode) if (isSomeString!S)
{
    if (senseCode.length == 1)
    {
        return senseCode[0].decodeWordSense;
    }
    else
    {
        return typeof(return).init;
    }
}

unittest
{
    assert(`n`.decodeWordSense == Sense.noun);
}

/** Convert $(D word) to $(D sense). */
auto toWordOfSense(S)(S word,
                      Sense toSense,
                      Sense fromSense = Sense.unknown) if (isSomeString!S)
{
    return word;
}

/* TODO How do I make this work? */
/* private T to(T:Sense)(char x) */
unittest
{
    /* assert('n'.to!Sense == Sense.noun); */
}

import std.algorithm.comparison: among;

@safe pure @nogc nothrow
{
    bool isCode(Sense sense)
    {
        with (Sense) return (sense.among!(code,
                                          codeOperator,
                                          codeOperatorAssignment,
                                          codeFunction,
                                          codeFunctionReference,
                                          codeVariable,
                                          codeVariableReference,
                                          codeType) != 0);
    }
    bool isFood(Sense sense)
    {
        with (Sense) return (sense.among!(food,
                                          spice) != 0);
    }
    bool isNounAbstract(Sense sense)
    {
        with (Sense) return (sense.isNumeric ||
                             sense.isLanguage ||
                             sense.isTimePeriod);
    }
    bool isNounConcrete(Sense sense)
    {
        with (Sense) return (sense.among!(plant,
                                          material,
                                          metal,
                                          substance) != 0);
    }
    bool isLanguage(Sense sense)
    {
        with (Sense) return (sense.among!(language,
                                          languageNatural,
                                          languageProgramming) != 0);
    }
    bool isPhrase(Sense sense)
    {
        with (Sense) return (sense.among!(phrase,
                                          nounPhrase) != 0);
    }
    bool isNounCollective(Sense sense)
    {
        with (Sense) return (sense.among!(nounCollective,
                                          nounCollectivePeople,
                                          nounCollectiveCreatures,
                                          nounCollectiveThings) != 0);
    }
    bool isNounDemonymSingular(Sense sense)
    {
        with (Sense) return (sense.among!(nounDemonymSingular,
                                          nounDemonymSingularMale,
                                          nounDemonymSingularFemale) != 0);
    }
    bool isNounDemonymPlural(Sense sense)
    {
        with (Sense) return (sense.among!(nounDemonymPlural,
                                          nounDemonymPluralMale,
                                          nounDemonymPluralFemale) != 0);
    }
    bool isNounDemonym(Sense sense)
    {
        with (Sense) return (sense.among!(nounDemonym) != 0 ||
                             sense.isNounDemonymSingular ||
                             sense.isNounDemonymPlural);
    }
    bool isDemonym(Sense sense)
    {
        with (Sense) return (sense.isNounDemonym ||
                             sense.among!(adjectiveDemonym));
    }
    bool isNounSingular(Sense sense)
    {
        with (Sense) return (sense.isNounDemonymSingular ||
                             sense.among!(nounSingular,
                                          nounSingularIndefinite,
                                          nounSingularDefinite,
                                          nounSingularMale,
                                          nounSingularFemale,
                                          nounSingularNeuter) != 0);
    }
    bool isNounPlural(Sense sense)
    {
        with (Sense) return (sense.isNounDemonymPlural ||
                             sense.among!(nounPlural,
                                          nounPluralMale,
                                          nounPluralFemale,
                                          nounPluralNeuter) != 0);
    }
    bool isNoun(Sense sense)
    {
        with (Sense) return (sense.isNounAbstract ||
                             sense.isNounConcrete ||
                             sense.isFood ||
                             sense.isNounSingular ||
                             sense.isNounPlural ||
                             sense.isNounCollective ||
                             sense.isNounDemonym ||
                             sense.among!(noun,
                                          nounNeuter,
                                          nounRegular,
                                          nounIrregular,
                                          nounNominative,
                                          nounUncountable,
                                          nounAbbrevation,
                                          nounAcronym,
                                          plant) != 0||
                             sense.isName);
    }
    bool isTimePeriod(Sense sense)
    {
        with (Sense) return sense.among!(timePeriod,
                                         weekday,
                                         month,
                                         dayOfMonth,
                                         year,
                                         season) != 0;
    }
    bool isNumeric(Sense sense)
    {
        with (Sense) return (sense.isInteger ||
                             sense.among!(numeric,
                                          decimal,
                                          numberRational,
                                          numberIrrational,
                                          numberTranscendental,
                                          numberComplex) != 0);
    }
    bool isQuantifier(Sense sense)
    {
        with (Sense) return (sense.among!(quantifier,
                                          quantifierOfSingularNoun,
                                          quantifierOfPluralNoun,
                                          quantifierOfUncountableNoun) != 0);
    }
    bool isNumeral(Sense sense)
    {
        with (Sense) return (sense.among!(numeral,
                                          numeralOrdinal,
                                          numeralFraction,
                                          numeralMasculine,
                                          numeralFeminine,
                                          numeralNeuter) != 0);
    }
    bool isInteger(Sense sense)
    {
        with (Sense) return (sense.isNumeral ||
                             sense.among!(integer,
                                          integerPositive,
                                          integerNegative,
                                          population) != 0);
    }
    bool isName(Sense sense)
    {
        with (Sense) return sense.among!(name,
                                         nameMale,
                                         nameFemale,
                                         surname,
                                         location,
                                         namePerson,
                                         organisation,
                                         region,
                                         island,
                                         city,
                                         county,
                                         province,
                                         state,
                                         country,
                                         continent,
                                         newspaper) != 0;
    }
    alias isProperNoun = isName;
    bool isLocation(Sense sense)
    {
        with (Sense) return sense.among!(location,
                                         region,
                                         island,
                                         city,
                                         county,
                                         province,
                                         state,
                                         country,
                                         continent) != 0;
    }
    alias isRegion = isLocation;
    bool isVerb(Sense sense)
    {
        with (Sense) return (sense.isVerbRegular ||
                             sense.isVerbIrregular ||
                             sense.among!(verb,
                                          verbTransitive,
                                          verbIntransitive,
                                          verbReflexive,
                                          verbInfinitive,
                                          verbPast,
                                          verbPastParticiple,
                                          verbAbbrevation,
                                          verbImperative,
                                          verbPresent,
                                          verbPresentSingular1st,
                                          verbPresentSingular2nd,
                                          verbPresentSingular3rd,
                                          verbPresentPlural1st,
                                          verbPresentPlural2nd,
                                          verbPresentPlural3rd,
                                          verbFuture) != 0);
    }
    bool isVerbRegular(Sense sense)
    {
        with (Sense) return sense.among!(verbRegular,
                                         verbRegularInfinitive,
                                         verbRegularPast,
                                         verbRegularPastParticiple) != 0;
    }
    bool isVerbIrregular(Sense sense)
    {
        with (Sense) return sense.among!(verbIrregular,
                                         verbIrregularInfinitive,
                                         verbIrregularPast,
                                         verbIrregularPastParticiple) != 0;
    }
    bool isAdjective(Sense sense)
    {
        with (Sense) return sense.among!(adjective,
                                         adjectiveDemonym,
                                         adjectiveMale,
                                         adjectiveFeminine,
                                         adjectiveNeuter,
                                         adjectiveRegular,
                                         adjectiveIrregular,
                                         adjectiveAbbrevation,
                                         adjectiveNominative,
                                         adjectiveComparative,
                                         adjectiveSuperlative,
                                         adjectiveElative,
                                         adjectiveExzessive,
                                         adjectivePossessiveSingular,
                                         adjectivePossessivePlural,
                                         adjectivePredicateOnly) != 0;
    }
    bool isAdverb(Sense sense)
    {
        with (Sense) return sense.among!(adverb,
                                         normalAdverb,
                                         timeAdverb,
                                         placeAdverb,
                                         frequencyAdverb,
                                         negatingAdverb,
                                         affirmingAdverb,
                                         conjunctiveAdverb) != 0;
    }
    bool isPronoun(Sense sense)
    {
        with (Sense) return (sense == pronoun ||
                             sense.isPronounPersonal ||
                             sense.isPronounPossessive ||
                             sense.isPronounDemonstrative ||
                             sense.isPronounDeterminative ||
                             sense == pronounInterrogative ||
                             sense.isPronounReflexive ||
                             sense.isPronounIndefinite ||
                             sense == pronounRelative);
    }
    bool isPronounPersonal(Sense sense)
    {
        return (sense.isPronounPersonalSingular ||
                sense.isPronounPersonalPlural);
    }
    bool isPronounPersonalSingular(Sense sense)
    {
        with (Sense) return sense.among!(pronounPersonalSingular,

                                         pronounPersonalSingular1st,
                                         pronounPersonalSingular2nd,
                                         pronounPersonalSingular3rd,

                                         pronounPersonalSingularMale,
                                         pronounPersonalSingularMale1st,
                                         pronounPersonalSingularMale2nd,

                                         pronounPersonalSingularFemale,
                                         pronounPersonalSingularFemale1st,
                                         pronounPersonalSingularFemale2nd,

                                         pronounPersonalSingularNeutral) != 0;
    }
    bool isPronounPersonalPlural(Sense sense)
    {
        with (Sense) return sense.among!(pronounPersonalPlural,
                                         pronounPersonalPlural1st,
                                         pronounPersonalPlural2nd,
                                         pronounPersonalPlural3rd) != 0;
    }
    bool isPronounPossessive(Sense sense)
    {
        with (Sense) return (sense == pronounPossessive ||
                             sense.isPronounPossessiveSingular ||
                             sense.isPronounPossessivePlural);
    }
    bool isPronounPossessiveSingular(Sense sense)
    {
        with (Sense) return sense.among!(pronounPossessiveSingular,
                                         pronounPossessiveSingular1st,
                                         pronounPossessiveSingular2nd,
                                         pronounPossessiveSingularMale,
                                         pronounPossessiveSingularFemale,
                                         pronounPossessiveSingularNeutral) != 0;
    }
    bool isPronounPossessivePlural(Sense sense)
    {
        with (Sense) return sense.among!(pronounPossessivePlural,
                                         pronounPossessivePlural1st,
                                         pronounPossessivePlural2nd,
                                         pronounPossessivePlural3rd) != 0;
    }
    bool isPronounDemonstrative(Sense sense)
    {
        with (Sense) return sense.among!(pronounDemonstrative,
                                         pronounDemonstrativeSingular,
                                         pronounDemonstrativePlural) != 0;
    }
    bool isPronounDeterminative(Sense sense)
    {
        with (Sense) return sense.among!(pronounDeterminative,
                                         pronounDeterminativeSingular,
                                         pronounDeterminativePlural) != 0;
    }
    bool isPronounPlural(Sense sense)
    {
        with (Sense) return (sense.isPronounPersonalPlural ||
                             sense == pronounPossessivePlural);
    }
    bool isPronounReflexive(Sense sense)
    {
        with (Sense) return sense.among!(pronounReflexive,
                                         pronounReflexiveSingular,
                                         pronounReflexivePlural) != 0;
    }
    bool isPronounIndefinite(Sense sense)
    {
        with (Sense) return sense.among!(pronounIndefinite,
                                         pronounIndefiniteSingular,
                                         pronounIndefinitePlural) != 0;
    }
    bool isPreposition(Sense sense)
    {
        with (Sense) return sense.among!(preposition,
                                         prepositionTime,
                                         prepositionPosition,
                                         prepositionDirection) != 0;
    }
    bool isArticle(Sense sense)
    {
        with (Sense) return sense.among!(article,
                                         articleIndefinite,
                                         articleDefinite,
                                         articlePartitive) != 0;
    }
    bool isConjunction(Sense sense)
    {
        with (Sense) return (sense.among!(conjunction,
                                          conjunctionCoordinating,
                                          conjunctionCorrelative) != 0||
                             sense.isConjunctionSubordinating);
    }
    bool isConjunctionSubordinating(Sense sense)
    {
        with (Sense) return sense.among!(conjunctionSubordinating,
                                         conjunctionSubordinatingConcession,
                                         conjunctionSubordinatingCondition,
                                         conjunctionSubordinatingComparison,
                                         conjunctionSubordinatingTime,
                                         conjunctionSubordinatingReason,
                                         conjunctionSubordinatingAdjective,
                                         conjunctionSubordinatingPronoun,
                                         conjunctionSubordinatingManner,
                                         conjunctionSubordinatingPlace) != 0;
    }
    bool isAbbrevation(Sense sense)
    {
        with (Sense) return (sense.among!(abbrevation,
                                          nounAbbrevation,
                                          nounAcronym,
                                          contraction) != 0);
    }
    bool isReflexive(Sense sense)
    {
        with (Sense) return (sense.among!(verbReflexive) != 0||
                             sense.isPronounReflexive);
    }
    bool isActor(Sense sense)
    {
        return (sense.isNoun ||
                sense.isPronoun);
    }
    alias isRole = isActor;

    bool isInPlural(Sense sense)
    {
        return (sense.isNounPlural ||
                sense.isPronounPlural);
    }
}

import grammars: Lang;

bool specializesWithExpr(Sense special,
                         Sense general,
                         bool uniquely = true,
                         string expr = null,
                         Lang lang = Lang.unknown)
    @safe pure nothrow // @nogc
{
    bool capitalized = false;
    try
    {
        if (expr)
        {
            import std.range: front;
            import std.uni: isUpper;
            capitalized = expr.front.isUpper;
        }
    }
    catch (Exception e) { }
    return specializes(special, general, uniquely, lang, capitalized);
}

/** Check if $(D special) (uniquely) specializes $(D general), that is if a word
    has been found to have sense $(D special) which is a more specialized sense
    than $(D general it must not have any other meaning less specialized thatn
    $(D special).
*/
bool specializes(Sense special,
                 Sense general,
                 bool uniquely = true,
                 Lang lang = Lang.unknown,
                 bool capitalized = false)
    @safe pure nothrow @nogc
{
    if (special == general) return false;
    switch (general) with (Sense)
    {
        case unknown: return false; // be strict as an unknown meaning can have different meaning say both a noun and verb
        case language: return special.isLanguage;
        case letter: return special.among!(letterLowercase,
                                           letterUppercase) != 0;
        case phrase: return special.isPhrase;
        case noun: return (special.isNoun ||
                           special.isPronoun ||
                           special.isName);
        case nounDemonym: return (special.isNounDemonym);
        case nounDemonymSingular: return (special.isNounDemonymSingular);
        case nounDemonymPlural: return (special.isNounDemonymPlural);

        // TODO https://en.wikipedia.org/wiki/Capitalization
        case nounSingular: return (special.isNounSingular ||
                                   (lang.among!(Lang.en, // TODO don't include weekdays, months, languages
                                                Lang.sv) &&
                                    capitalized &&
                                    special.isName)); // TODO functionize. list of languages that don't capitalize nouns (not German)
        case nounPlural: return (special.isNounPlural);
        case nounCollective: return (special.isNounCollective ||
                                     (lang.among!(Lang.en, Lang.sv) &&
                                      capitalized &&
                                      special.isName)); // TODO functionize

        case location: return special.isLocation;

        case food: return special.isFood;
        case quantifier: return (special.isQuantifier &&
                                 special == numeral);
        case numeral: return special.isNumeral;
        case integer: return special.isInteger;
        case numeric: return special.isNumeric;

        case name: return special.isName;
        case abbrevation: return special.isAbbrevation;

        case verb: return special.isVerb;
        case verbRegular: return special.isVerbRegular;
        case verbIrregular: return special.isVerbIrregular;

        case adverb: return special.isAdverb;
        case adjective: return special.isAdjective;

        case pronoun: return special.isPronoun;
        case pronounDemonstrative: return special.isPronounDemonstrative;
        case pronounDeterminative: return special.isPronounDeterminative;
        case pronounReflexive: return special.isPronounReflexive;
        case pronounIndefinite: return special.isPronounIndefinite;

        case pronounPersonal: return special.isPronounPersonal;
        case pronounPersonalSingular: return special.isPronounPersonalSingular;
        case pronounPersonalPlural: return special.isPronounPersonalPlural;

        case pronounPossessive: return special.isPronounPossessive;
        case pronounPossessiveSingular: return special.isPronounPossessiveSingular;
        case pronounPossessivePlural: return special.isPronounPossessivePlural;

        case preposition: return special.isPreposition;
        case article: return special.isArticle;

        case conjunction: return special.isConjunction;
        case conjunctionSubordinating: return special.isConjunctionSubordinating;

        default: return special == general;
    }
}

@safe @nogc pure nothrow unittest
{
    with (Sense)
    {
        assert(languageProgramming.specializes(language));
        assert(languageNatural.specializes(language));
        assert(name.specializes(noun));
        assert(verbTransitive.specializes(verb));
        assert(nounSingular.specializes(noun));
        assert(nounPlural.specializes(noun));
        assert(integerPositive.specializes(integer));
        assert(integerNegative.specializes(integer));
        assert(timeAdverb.specializes(adverb));
    }
    assert(Sense.noun.isNoun);
}

/** Check if $(D general) uniquely specializes $(D special).
    See also: $(D specializes).
*/
bool generalizes(Sense general,
                 Sense special,
                 bool uniquely = true,
                 string expr = null,
                 Lang lang = Lang.unknown)
    @safe pure nothrow // @nogc
{
    return specializesWithExpr(special, general, uniquely, expr, lang);
}

@safe @nogc pure nothrow unittest
{
    with (Sense)
    {
        assert(language.generalizes(languageProgramming));
    }
}
