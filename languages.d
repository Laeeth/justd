#!/usr/bin/env rdmd-dev

/** Generic Language Constructs. */
module languages;

import std.traits: isSomeChar, isSomeString;
import std.typecons: Nullable;
import std.algorithm: uniq, startsWith;
import std.array: array;
import std.conv: to;

/** (Human) Language Code according to ISO 639-1.
    See also: http://www.mathguide.de/info/tools/languagecode.html
    See also: https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
 */
enum HumanLang:ubyte
{
    unknown,
    en,                       // English, 英語
    // ac,                       // TODO?
    // ace,                      // TODO?
    // ai,                       // TODO?
    // ain,                       // TODO?
    af,                       // Afrikaans
    ar,                       // Arabic
    // ary,                       // TODO?
    // arc,                       // TODO?
    ae,                       // Avestan
    ak,                       // Akan
    // akk,                      // TODO?
    an,                       // Aragonese
    // ang,                       // TODO?
    as,                       // Assamese
    // ase,                       // TODO?
    // ast,                       // TODO?
    // ax,                       // TODO?
    az,                       // Azerbaijani
    hy,                       // Armenian
    eu,                       // Basque
    ba,                       // Baskhir
    // ban,                      // TODO?
    be,                       // Belarusian
    // bj,                       // TODO?
    bn,                       // Bengali
    br,                       // Breton
    bs,                       // Bosnian
    bg,                       // Bulgarian
    bo,                       // Tibetan
    // bp,                       // TODO?
    // bt,                       // TODO?
    my,                       // Burmese
    zh,                       // Chinese Mandarin
    crh,                      // Crimean Tatar
    hr,                       // Croatian
    // cr,                       // TODO?
    ca,                       // Catalan
    cy,                       // Welch
    cs,                       // Czech
    // csb,                      // TODO?
    da,                       // Danish
    // ds,                       // TODO?
    // dsb,                      // TODO?
    nl,                       // Dutch
    eo,                       // Esperanto
    et,                       // Estonian
    fi,                       // Finnish
    fj,                       // Fiji
    fo,                       // Faeroese
    // fu,                       // TODO?
    // fur,                      // TODO?
    fr,                       // French
    gl,                       // Galician
    gv,                       // Manx
    de,                       // German
    el,                       // Greek
    ha,                       // Hausa
    // haw,                      // TODO?
    he,                       // Hebrew
    // hs,                       // TODO?
    // hsb,                      // TODO?
    hi,                       // Hindi
    hu,                       // Hungarian
    is_,                      // Icelandic
    io,                       // Ido
    id,                       // Indonesian
    ga,                       // Irish
    it,                       // Italian
    ja,                       // Japanese, 日本語
    ka,                       // Georgian
    ku,                       // Kurdish
    kn,                       // Kannada
    kk,                       // Kazakh
    km,                       // Khmer
    ko,                       // Korean
    ky,                       // Kyrgyz
    lo,                       // Lao
    la,                       // Latin
    lt,                       // Lithuanian
    lv,                       // Latvian
    jbo,                      // Lojban
    mk,                       // Macedonian
    nan,                      // Min Nan
    mg,                       // Malagasy
    mn,                       // Mongolian
    ms,                       // Malay
    mt,                       // Maltese
    ne,                       // Nepali
    no,                       // Norwegian
    ps,                       // Pashto
    fa,                       // Persian
    oc,                       // Occitan
    pl,                       // Polish
    pt,                       // Portuguese
    ro,                       // Romanian
    ru,                       // Russian
    sa,                       // Sanskrit
    // sc,                       // TODO?
    // scn,                       // TODO?
    si,                       // Sinhalese
    sm,                       // Samoan
    sco,                      // Scots
    sq,                       // Albanian
    // se,                       // TODO?
    // sy,                       // TODO?
    // syc,                       // TODO?
    te,                       // Tegulu
    tl,                       // Tagalog
    // tp,                       // TODO?
    // tpi,                       // TODO?
    gd,                       // Scottish Gaelic
    sr,                       // Serbian
    sk,                       // Slovak
    sl,                       // Slovene, Slovenian
    es,                       // Spanish
    sw,                       // Swahili
    sv,                       // Swedish
    tg,                       // Tajik
    ta,                       // Tamil
    th,                       // Thai
    tr,                       // Turkish
    tk,                       // Turkmen
    uk,                       // Ukrainian
    ur,                       // Urdu
    uz,                       // Uzbek
    vi,                       // Vietnamese
    vo,                       // Volapük
    wa,                       // Waloon
    yi,                       // Yiddish
}

HumanLang decodeHumanLang(char[] x)
    @safe pure
{
    import std.stdio: writeln;
    if (x == "is")
    {
        return HumanLang.is_;
    }
    else
    {
        try
        {
            return x.to!HumanLang;
        }
        catch (Exception a)
        {
            return HumanLang.unknown;
        }
    }
}

unittest
{
    assert("sv".to!HumanLang == HumanLang.sv);
}

/* LANGUAGES = { */
/* 'English': 'en', */
/* 'Afrikaans': 'af', */
/* 'Arabic': 'ar', */
/* 'Armenian': 'hy', */
/* 'Basque': 'eu', */
/* 'Belarusian': 'be', */
/* 'Bengali': 'bn', */
/* 'Bosnian': 'bs', */
/* 'Bulgarian': 'bg', */
/* 'Burmese': 'my', */
/* 'Chinese': 'zh', */
/* 'Crimean Tatar': 'crh', */
/* 'Croatian': 'hr', */
/* 'Czech': 'cs', */
/* 'Danish': 'da', */
/* 'Dutch': 'nl', */
/* 'Esperanto': 'eo', */
/* 'Estonian': 'et', */
/* 'Finnish': 'fi', */
/* 'French': 'fr', */
/* 'Galician': 'gl', */
/* 'German': 'de', */
/* 'Greek': 'el', */
/* 'Hebrew': 'he', */
/* 'Hindi': 'hi', */
/* 'Hungarian': 'hu', */
/* 'Icelandic': 'is', */
/* 'Ido': 'io', */
/* 'Indonesian': 'id', */
/* 'Irish': 'ga', */
/* 'Italian': 'it', */
/* 'Japanese': 'ja', */
/* 'Kannada': 'kn', */
/* 'Kazakh': 'kk', */
/* 'Khmer': 'km', */
/* 'Korean': 'ko', */
/* 'Kyrgyz': 'ky', */
/* 'Lao': 'lo', */
/* 'Latin': 'la', */
/* 'Lithuanian': 'lt', */
/* 'Lojban': 'jbo', */
/* 'Macedonian': 'mk', */
/* 'Min Nan': 'nan', */
/* 'Malagasy': 'mg', */
/* 'Mandarin': 'zh', */
/* 'Norwegian': 'no', */
/* 'Pashto': 'ps', */
/* 'Persian': 'fa', */
/* 'Polish': 'pl', */
/* 'Portuguese': 'pt', */
/* 'Romanian': 'ro', */
/* 'Russian': 'ru', */
/* 'Sanskrit': 'sa', */
/* 'Sinhalese': 'si', */
/* 'Scots': 'sco', */
/* 'Scottish Gaelic': 'gd', */
/* 'Serbian': 'sr', */
/* 'Slovak': 'sk', */
/* 'Slovene': 'sl', */
/* 'Slovenian': 'sl', */
/* 'Spanish': 'es', */
/* 'Swahili': 'sw', */
/* 'Swedish': 'sv', */
/*     'Tajik': 'tg', */
/*     'Tamil': 'ta', */
/*     'Thai': 'th', */
/*     'Turkish': 'tr', */
/*     'Turkmen': 'tk', */
/*     'Ukrainian': 'uk', */
/*     'Urdu': 'ur', */
/*     'Uzbek': 'uz', */
/*     'Vietnamese': 'vi', */
/*     '英語': 'en', */
/*     '日本語': 'ja' */
/* } */

/* /\** Programming Language. *\/ */
enum Lang:ubyte
{
    unknown,                    // Unknown: ?
    c,                          // C
    cxx,                        // C++
    objective_c,                // Objective-C
    d,                          // D
    java,                       // Java
}

unittest
{
    assert(Lang.init.toTag == `?`);
    assert(Lang.c.toTag == `C`);
    assert(Lang.cxx.toTag == `C++`);
    assert(Lang.d.toTag == `D`);
    assert(Lang.java.toTag == `Java`);
}

string toTag(Lang lang) @safe @nogc pure nothrow
{
    final switch (lang)
    {
        case Lang.unknown: return `?`;
        case Lang.c: return `C`;
        case Lang.cxx: return `C++`;
        case Lang.d: return `D`;
        case Lang.java: return `Java`;
        case Lang.objective_c: return `Objective-C`;
    }
}

string toHTML(Lang lang) @safe @nogc pure nothrow
{
    return lang.toTag;
}

string toMathML(Lang lang) @safe @nogc pure nothrow
{
    return lang.toHTML;
}

Lang language(string name)
{
    switch (name)
    {
        case `C`:    return Lang.c;
        case `C++`:  return Lang.cxx;
        case `Objective-C`:  return Lang.objective_c;
        case `D`:    return Lang.d;
        case `Java`: return Lang.java;
        default:     return Lang.unknown;
    }
}

/** Markup Language */
enum MarkupLang:ubyte
{
    unknown,                    // Unknown: ?
    HTML,
    MathML
}

/** Computer Token Usage. */
enum Usage:ubyte
{
    definition,
    reference,
    call
}

/** Computer Token. */
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
    operator
}

/** English Tense.
    See also: http://www.ego4u.com/en/cram-up/grammar/tenses-graphic
    See also: http://www.ego4u.com/en/cram-up/grammar/tenses-examples
*/
enum Tense:ubyte
{
    pastMoment, // played
    presentMoment, // plays
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

/** Human Word Category. */
enum WordCategory:ubyte
{
    unknown,

    noun,
    nounInteger,
    nounRational,
    nounLocation,
    nounPerson,
    nounName,

    verb,
    adjective,

    adverb, // changes or simplifies the meaning of a verb, adjective, other adverb, clause, or sentence.
    normalAdverb,
    conjunctiveAdverb, // joins together sentences

    adverbialConjunction = conjunctiveAdverb,

    preposition, // often ambiguous
    prepositionTime, // only related to time
    prepositionPosition, // only related to space (position)
    prepositionPlace = prepositionPosition,
    prepositionDirection, // only related to space change (velocity)

    pronoun,
    pronounPersonal,
    pronounDemonstrative,
    pronounPossessive,

    determiner,
    article,
    interjection,

    coordinatingConjunction,
    subordinatingConjunction,
}

@safe pure @nogc nothrow
{
    bool isNoun(WordCategory category)
    {
        with (WordCategory)
        {
            return (category == noun ||
                    category == nounInteger ||
                    category == nounRational ||
                    category == nounLocation ||
                    category == nounPerson ||
                    category == nounName);
        }
        // return category.to!string.startsWith("noun");
    }
    bool isVerb(WordCategory category) { return (category == WordCategory.verb); }
    bool isAdjective(WordCategory category) { return (category == WordCategory.adjective); }
    bool isAdverb(WordCategory category)
    {
        return (category == WordCategory.adverb ||
                category == WordCategory.normalAdverb ||
                category == WordCategory.conjunctiveAdverb);
    }
    bool isPronoun(WordCategory category)
    {
        return (category == WordCategory.pronoun ||
                category == WordCategory.pronounPersonal ||
                category == WordCategory.pronounDemonstrative ||
                category == WordCategory.pronounPossessive);
    }
}

unittest
{
    assert(WordCategory.noun.isNoun);
}

/** English Noun Suffixes. */
static immutable nounSuffixes = [ "s", "ses", "xes", "zes", "ches", "shes", "men", "ies", ];

/** English Verb Suffixes. */
static immutable verbSuffixes = [ "s", "ies", "es", "es", "ed", "ed", "ing", "ing", ];

/** English Adjective Suffixes. */
static immutable adjectiveSuffixes = [ "er", "est", "er", "est" ];

/** English Word Suffixes. */
static immutable wordSuffixes = [ nounSuffixes ~ verbSuffixes ~ adjectiveSuffixes ].uniq.array;

auto wordBase(S)(S x) if (isSomeString!S ||
                          isSomeChar!S)
{
    doit;
}

/** Get english order name of $(D n). */
string nthString(T)(T n) @safe pure
{
    import std.conv : to;
    string s;
    switch (n)
    {
        default: s = to!string(n) ~ ":th"; break;
        case 0: s = "zeroth"; break;
        case 1: s = "first"; break;
        case 2: s = "second"; break;
        case 3: s = "third"; break;
        case 4: s = "fourth"; break;
        case 5: s = "fifth"; break;
        case 6: s = "sixth"; break;
        case 7: s = "seventh"; break;
        case 8: s = "eighth"; break;
        case 9: s = "ninth"; break;
        case 10: s = "tenth"; break;
        case 11: s = "eleventh"; break;
        case 12: s = "twelveth"; break;
        case 13: s = "thirteenth"; break;
        case 14: s = "fourteenth"; break;
        case 15: s = "fifteenth"; break;
        case 16: s = "sixteenth"; break;
        case 17: s = "seventeenth"; break;
        case 18: s = "eighteenth"; break;
        case 19: s = "nineteenth"; break;
        case 20: s = "twentieth"; break;
    }
    return s;
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
            return word ~ "es";
        case 'f':
            return word[0 .. $-1] ~ "ves";
        case 'y':
            return word[0 .. $-1] ~ "ies";
        default:
            return word ~ "s";
    }
}

import std.traits: isIntegral;

/** Convert the number $(D number) to its English textual representation.
    Opposite: toTextualIntegerMaybe
*/
string toTextualString(T)(T number, string minusName = "minus")
    @safe pure nothrow if (isIntegral!T)
{
    string word;

    if (number == 0)
        return "zero";

    if (number < 0)
    {
        word = minusName;
        number = -number;
    }

    while (number)
    {
        if (number < 100)
        {
            if (number < singleWords.length)
            {
                word ~= singleWords[cast(int) number];
                break;
            }
            else
            {
                auto tens = number / 10;
                word ~= tensPlaceWords[cast(int) tens];
                number = number % 10;
                if (number)
                    word ~= "-";
            }
        }
        else if (number < 1_000)
        {
            auto hundreds = number / 100;
            word ~= onesPlaceWords[cast(int) hundreds] ~ " hundred";
            number = number % 100;
            if (number)
                word ~= " and ";
        }
        else if (number < 1_000_000)
        {
            auto thousands = number / 1_000;
            word ~= toTextualString(thousands) ~ " thousand";
            number = number % 1_000;
            if (number)
                word ~= ", ";
        }
        else if (number < 1_000_000_000)
        {
            auto millions = number / 1_000_000;
            word ~= toTextualString(millions) ~ " million";
            number = number % 1_000_000;
            if (number)
                word ~= ", ";
        }
        else if (number < 1_000_000_000_000)
        {
            auto n = number / 1_000_000_000;
            word ~= toTextualString(n) ~ " billion";
            number = number % 1_000_000_000;
            if (number)
                word ~= ", ";
        }
        else if (number < 1_000_000_000_000_000)
        {
            auto n = number / 1_000_000_000_000;
            word ~= toTextualString(n) ~ " trillion";
            number = number % 1_000_000_000_000;
            if (number)
                word ~= ", ";
        }
        else
        {
            import std.conv;
            return to!string(number);
        }
    }

    return word;
}
alias toTextual = toTextualString;

unittest {
    assert(1.toTextualString == "one");
    assert(5.toTextualString == "five");
    assert(13.toTextualString == "thirteen");
    assert(54.toTextualString == "fifty-four");
    assert(178.toTextualString == "one hundred and seventy-eight");
    assert(592.toTextualString == "five hundred and ninety-two");
    assert(1_234.toTextualString == "one thousand, two hundred and thirty-four");
    assert(10_234.toTextualString == "ten thousand, two hundred and thirty-four");
    assert(105_234.toTextualString == "one hundred and five thousand, two hundred and thirty-four");
    assert(71_05_234.toTextualString == "seven million, one hundred and five thousand, two hundred and thirty-four");
    assert(3_007_105_234.toTextualString == "three billion, seven million, one hundred and five thousand, two hundred and thirty-four");
    assert(900_003_007_105_234.toTextualString == "nine hundred trillion, three billion, seven million, one hundred and five thousand, two hundred and thirty-four");
}

enum onesPlaceWords = [ "zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" ];
enum singleWords = onesPlaceWords ~ [ "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen" ];
enum tensPlaceWords = [ null, "ten", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety", ];

immutable ubyte onesPlaceWordsAA[string];
immutable ubyte singleWordsAA[string];
immutable ubyte tensPlaceWordsAA[string];

static this() {
    foreach (ubyte i, e; onesPlaceWords) { onesPlaceWordsAA[e] = i; }
    foreach (ubyte i, e; singleWords) { singleWordsAA[e] = i; }
    foreach (ubyte i, e; tensPlaceWords) { tensPlaceWordsAA[e] = i; }
}

/** Convert the number $(D number) to its English textual representation.
    Opposite: toTextualString.
    TODO: Throw if number doesn't fit in long.
    TODO: Add variant to toTextualBigIntegerMaybe.
*/
Nullable!long toTextualIntegerMaybe(S)(S x)
    @safe pure if (isSomeString!S)
{
    typeof(return) value;
    import std.algorithm: splitter, countUntil, skipOver;

    auto words = x.splitter;

    bool negative = words.skipOver(`minus`) || words.skipOver(`negative`);

    words.skipOver(`plus`);

    if (words.front in onesPlaceWordsAA)
    {
        value = onesPlaceWordsAA[words.front];
    }

    version(show)
    {
        import std.stdio;
        debug writeln(onesPlaceWords);
        debug writeln(words.front);
        debug writeln(words);
        debug writeln(ones);
    }

    if (!value.isNull)
    {
        value *= negative ? -1 : 1;
    }

    return value;
}

unittest
{
    foreach (i; 0..9)
    {
        const ti = i.toTextualString;
        assert(-i == (`minus ` ~ ti).toTextualIntegerMaybe);
        assert(+i == (`plus ` ~ ti).toTextualIntegerMaybe);
        assert(+i == ti.toTextualIntegerMaybe);
    }
}
