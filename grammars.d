#!/usr/bin/env rdmd-dev

/** Generic Language Constructs.
    See also: https://en.wikipedia.org/wiki/Predicate_(grammar)

    Note that ! and ? are more definite sentence enders than .
 */
module grammars;

import std.traits: isSomeChar, isSomeString;
import std.typecons: Nullable;
import std.algorithm: uniq, map, find, canFind, startsWith, endsWith, among;
import std.array: array;
import std.conv;
import predicates: of;

import knet.languages: Lang;

/** Computer Token Usage. */
enum Usage:ubyte
{
    definition,
    reference,
    call
}

/** English Vowels. */
enum englishVowels = ['a', 'o', 'u', 'e', 'i', 'y'];

/** Check if $(D c) is a Vowel. */
bool isEnglishVowel(C)(C c) if (isSomeChar!C)
{
    return c.of('a', 'o', 'u', 'e', 'i', 'y'); // TODO Reuse englishVowels and hash-table
}

/** English Accented Vowels. */
enum englishAccentedVowels = ['é'];

/** Check if $(D c) is an Accented Vowel. */
bool isEnglishAccentedVowel(C)(C c) if (isSomeChar!C)
{
    return c.of(['é']); // TODO Reuse englishAccentedVowels and hash-table
}

unittest
{
    assert('é'.isEnglishAccentedVowel);
}

/** Swedish Hard Vowels. */
enum swedishHardVowels = ['a', 'o', 'u', 'å'];

/** Swedish Soft Vowels. */
enum swedishSoftVowels = ['e', 'i', 'y', 'ä', 'ö'];

/** Swedish Vowels. */
enum swedishVowels = (swedishHardVowels ~
                      swedishSoftVowels);

/** Check if $(D c) is a Swedish Vowel. */
bool isSwedishVowel(C)(C c) if (isSomeChar!C)
{
    // TODO Reuse swedishVowels and hash-table
    return c.of('a', 'o', 'u', 'å',
                'e', 'i', 'y', 'ä', 'ö');
}

/** Spanish Accented Vowels. */
enum spanishAccentedVowels = ['á', 'é', 'í', 'ó', 'ú'];

/** Check if $(D c) is a Spanish Accented Vowel. */
bool isSpanishAccentedVowel(C)(C c) if (isSomeChar!C)
{
    return c.of(spanishAccentedVowels);
}

/** Check if $(D c) is a Spanish Vowel. */
bool isSpanishVowel(C)(C c) if (isSomeChar!C)
{
    return (c.isEnglishVowel ||
            c.isSpanishAccentedVowel);
}

unittest
{
    assert('é'.isSpanishVowel);
}

/** Check if $(D c) is a Vowel in language $(D lang). */
bool isVowel(C)(C c, Lang lang) if (isSomeChar!C)
{
    switch (lang) with (Lang)
    {
        case en: return c.isEnglishVowel;
        case sv: return c.isSwedishVowel;
        default: return c.isEnglishVowel;
    }
}

unittest
{
    assert(!'k'.isSwedishVowel);
    assert('å'.isSwedishVowel);
}

/** English Consonants.
    See also: https://simple.wikipedia.org/wiki/Consonant
*/
enum EnglishConsonant { b, c, d, f, g, h, j, k, l, m, n, p, q, r, s, t, v, w, x }

/** English Consontants. */
enum englishConsonants = ['b', 'c', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 'm', 'n', 'p', 'q', 'r', 's', 't', 'v', 'w', 'x'];

/** Check if $(D c) is a Consonant. */
bool isEnglishConsonant(C)(C c) if (isSomeChar!C)
{
    // TODO Reuse englishConsonants and hash-table
    return c.of('b', 'c', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 'm', 'n', 'p', 'q', 'r', 's', 't', 'v', 'w', 'x');
}
alias isSwedishConsonant = isEnglishConsonant;

unittest
{
    assert('k'.isEnglishConsonant);
    assert(!'å'.isEnglishConsonant);
}

/** English Letters. */
enum englishLetters = englishVowels ~ englishConsonants;

/** Check if $(D c) is a Letter. */
bool isEnglishLetter(C)(C c) if (isSomeChar!C)
{
    return c.of(englishLetters);
}
alias isEnglish = isEnglishLetter;

unittest
{
    assert('k'.isEnglishLetter);
    assert(!'å'.isEnglishLetter);
}

enum EnglishDoubleConsonants = [`bb`, `dd`, `ff`, `gg`, `mm`, `nn`, `pp`, `rr`, `tt`];

/** Check if $(D c) is a Consonant. */
bool isEnglishDoubleConsonant(S)(S s) if (isSomeString!S)
{
    return c.of(`bb`, `dd`, `ff`, `gg`, `mm`, `nn`, `pp`, `rr`, `tt`);
}

/** computer Token. */
enum TokenId:ubyte
{
    unknown,

    keyword,
    type,
    constant,
    comment,
    variableName,
    functionName,
    builtinName,
    templateName,
    macroName,
    aliasName,
    enumeration,
    enumerator,
    constructor,
    destructors,
    operator,
}

/** Verb Form. */
enum VerbForm:ubyte
{
    unknown,

    imperative,
    infinitive, base = infinitive, // sv:infinitiv,grundform
    present, // sv:presens
    past, preteritum = past, // sv:imperfekt
    supinum, pastParticiple = supinum,
}

/** English Tense.
    Tempus on Swedish.
    See also: http://www.ego4u.com/en/cram-up/grammar/tenses-graphic
    See also: http://www.ego4u.com/en/cram-up/grammar/tenses-examples
*/
enum Tense:ubyte
{
    unknown,

    present, presens = present, // sv:nutid
    past, preteritum = past, imperfekt = past, // sv:dåtid, https://en.wikipedia.org/wiki/Past_tense
    future, futurum = future, // framtid, https://en.wikipedia.org/wiki/Future_tense

    pastMoment,
    presentMoment, // sv:plays
    futureMoment, // [will|is going to|intends to] play

    pastPeriod,
    presentPeriod,
    futurePeriod,

    pastResult,
    presentResult,
    futureResult,

    pastDuration,
    presentDuration,
    futureDuration,
}

@safe @nogc pure nothrow
{
    bool isPast(Tense tense)
    {
        with (Tense) return tense.of(past, pastMoment, pastPeriod, pastResult, pastDuration);
    }

    bool isPresent(Tense tense)
    {
        with (Tense) return tense.of(present, presentMoment, presentPeriod, presentResult, presentDuration);
    }

    bool isFuture(Tense tense)
    {
        with (Tense) return tense.of(future, futureMoment, futurePeriod, futureResult, futureDuration);
    }
}

/** Part of a Sentence. */
enum SentencePart:ubyte
{
    subject,
    predicate,
    adverbial,
    object,
}

class Part
{
}

class Predicate : Part
{
}

// TODO: Conversion to Sense
enum Article:ubyte { indefinite, definite,  partitive }

class Subject : Part
{
    Article article;
}

static immutable implies = [ `in order to` ];

/** Subject Count. */
enum Number:ubyte { singular, plural }

/** Subject Person. */
enum Person:ubyte { first, second, third }

/** Comparation.
    See also: https://en.wikipedia.org/wiki/Comparison_(grammar)
 */
enum Comparation:ubyte
{
    unknown,
    positive,
    comparative,
    superlative,
    elative,
    exzessive
}

/** Subject Gender. */
enum Gender:ubyte {
    unknown,
    male, maskulinum = male,
    female, femininum = female,
    neutral, neutrum = neutral, // human or alive, for example: "något"G
    reale, utrum = reale // non-human/alive, for example: "någon"
}

/** (Grammatical) Mood.
    Sometimes also called Mode.
    Modus in Swedish.
    See also: https://en.wikipedia.org/wiki/Grammatical_mood
*/
enum Mood:ubyte
{
    unknown,
    indicative, // indikativ in Swedish
    subjunctive,
    conjunctive = subjunctive, // konjunktiv in Swedish
    conditional,
    optative,
    imperative, // imperativ in Swedish
    jussive,
    potential,
    inferential,
    interrogative
}

/** Check if $(D mood) is a Realis Mood.
    See also: https://en.wikipedia.org/wiki/Grammatical_mood#Realis_moods
 */
bool isRealis(Mood mood) @safe pure @nogc nothrow
{
    with (Mood) return mood.of(indicative);
}

enum realisMoods = [Mood.indicative];

/** Check if $(D mood) is a Irrealis Mood.
    See also: https://en.wikipedia.org/wiki/Grammatical_mood#Irrealis_moods
*/
bool isIrrealis(Mood mood) @safe pure @nogc nothrow
{
    with (Mood) return mood.of(subjunctive,
                               conditional,
                               optative,
                               imperative,
                               jussive,
                               potential,
                               inferential);
}

enum irrealisMoods = [Mood.subjunctive,
                      Mood.conditional,
                      Mood.optative,
                      Mood.imperative,
                      Mood.jussive,
                      Mood.potential,
                      Mood.inferential];

/** English Negation Prefixes.
    See also: http://www.english-for-students.com/Negative-Prefixes.html
*/
static immutable englishNegationPrefixes = [ `un`, `non`, `dis`, `im`, `in`, `il`, `ir`, ];

static immutable swedishNegationPrefixes = [ `icke`, `o`, ];

/** English Noun Suffixes.
    See also: http://www.english-for-students.com/Noun-Suffixes.html
 */
static immutable adjectiveNounSuffixes = [ `ness`, `ity`, `ment`, `ance` ];
static immutable verbNounSuffixes = [ `tion`, `sion`, `ment`, `ence` ];
static immutable nounNounSuffixes = [ `ship`, `hood` ];
static immutable allNounSuffixes = (adjectiveNounSuffixes ~
                                    verbNounSuffixes ~
                                    nounNounSuffixes ~
                                    [ `s`, `ses`, `xes`, `zes`, `ches`, `shes`, `men`, `ies`, ]);

/** English Verb Suffixes. */
static immutable verbSuffixes = [ `s`, `ies`, `es`, `es`, `ed`, `ed`, `ing`, `ing`, ];

/** English Adjective Suffixes. */
static immutable adjectiveSuffixes = [ `er`, `est`, `er`, `est` ];

/** English Job/Professin Title Suffixes.
    Typically built from noun or verb bases.
    See also: http://www.english-for-students.com/Job-Title-Suffixes.html
*/
static immutable jobTitleSuffixes = [ `or`, // traitor
                                      `er`, // builder
                                      `ist`, // typist
                                      `an`, // technician
                                      `man`, // dustman, barman
                                      `woman`, // policewoman
                                      `ian`, // optician
                                      `person`, // chairperson
                                      `sperson`, // spokesperson
                                      `ess`, // waitress
                                      `ive` // representative
    ];

/** English Linking Verbs in Nominative Form.
 */
static immutable englishLinkingVerbs = [`is`, `seem`, `look`, `appear to be`, `could be`];
static immutable swedishLinkingVerbs = [`är`, `verkar`, `ser`, `kan vara`];

/** English Word Suffixes. */
static immutable wordSuffixes = [ allNounSuffixes ~ verbSuffixes ~ adjectiveSuffixes ].uniq.array;

/** Get Gender of expression $(D expr) having sense $(D sense). */
Gender getGender(S)(S expr, Sense sense) if (isSomeString!S)
{
    if (sense.isPronounSingularMale)
    {
        return Gender.male;
    }
    else if (sense.isPronounPersonalSingularFemale)
    {
        return Gender.female;
    }
    else if (sense.isPronounPersonalSingularNeutral)
    {
        return Gender.neutral;
    }
    else if (sense.isNoun)
    {
        return Gender.unknown;
    }
    else
    {
        return Gender.unknown;
    }
}

/** Return string $(D word) in plural optionally in $(D count). */
string inPlural(string word, int count = 2,
                string pluralWord = null)
{
    if (count == 1 || word.length == 0)
        return word; // it isn't actually inPlural
    if (pluralWord !is null)
        return pluralWord;
    switch (word[$ - 1])
    {
        case 's':
        case 'a', 'e', 'i', 'o', 'u':
            return word ~ `es`;
        case 'f':
            return word[0 .. $-1] ~ `ves`;
        case 'y':
            return word[0 .. $-1] ~ `ies`;
        default:
            return word ~ `s`;
    }
}

/** Return $(D s) lemmatized (normalized).
    See also: https://en.wikipedia.org/wiki/Lemmatisation
 */
S lemmatize(S)(S s) if (isSomeString!S)
{
    if      (s.of(`be`, `is`, `am`, `are`)) return `be`;
    else if (s.of(`do`, `does`))            return `do`;
    else return s;
}

/**
   Reuse knet translation query instead.
 */
string negationIn(Lang lang = Lang.en) @safe pure nothrow
{
    switch (lang) with (Lang)
    {
        case en: return `not`;
        case sv: return `inte`;
        case de: return `nicht`;
        default: return `not`;
    }
}

enum Manner:ubyte
{
    formal,
    informal,
    slang,
    rude,
}
