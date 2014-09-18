#!/usr/bin/env rdmd-dev

/**
   Generic Language Constructs.
 */
module languages;

import std.traits: isSomeChar, isSomeString;
import std.typecons: Nullable;
import std.algorithm: uniq;
import std.array: array;

/** (Human) Language Code according to ISO 639-1.
    See also: http://www.mathguide.de/info/tools/languagecode.html
    See also: https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
 */
enum HLang:ubyte
{
    unknown,                    /// Unknown
    en,                       /// English, 英語
    // ac,                       /// TODO?
    // ace,                      /// TODO?
    // ai,                       /// TODO?
    // ain,                       /// TODO?
    af,                       /// Afrikaans
    ar,                       /// Arabic
    // ary,                       /// TODO?
    // arc,                       /// TODO?
    ae,                       /// Avestan
    ak,                       /// Akan
    // akk,                      /// TODO?
    an,                       /// Aragonese
    // ang,                       /// TODO?
    as,                       /// Assamese
    // ase,                       /// TODO?
    // ast,                       /// TODO?
    // ax,                       /// TODO?
    az,                       /// Azerbaijani
    hy,                       /// Armenian
    eu,                       /// Basque
    ba,                       /// Baskhir
    // ban,                      /// TODO?
    be,                       /// Belarusian
    // bj,                       /// TODO?
    bn,                       /// Bengali
    br,                       /// Breton
    bs,                       /// Bosnian
    bg,                       /// Bulgarian
    bo,                       /// ibetan
    // bp,                       /// TODO?
    // bt,                       /// TODO?
    my,                       /// Burmese
    zh,                       /// Chinese Mandarin
    crh,                      /// Crimean Tatar
    hr,                       /// Croatian
    // cr,                       /// TODO?
    ca,                       /// Catalan
    cy,                       /// Welch
    cs,                       /// Czech
    // csb,                      /// TODO?
    da,                       /// Danish
    // ds,                       /// TODO?
    // dsb,                      /// TODO?
    nl,                       /// Dutch
    eo,                       /// Esperanto
    et,                       /// Estonian
    fi,                       /// Finnish
    fj,                       /// Fiji
    fo,                       /// Faeroese
    // fu,                       /// TODO?
    // fur,                      /// TODO?
    fr,                       /// French
    gl,                       /// Galician
    gv,                       /// Manx
    de,                       /// German
    el,                       /// Greek
    ha,                       /// Hausa
    // haw,                      /// TODO?
    he,                       /// Hebrew
    // hs,                       /// TODO?
    // hsb,                      /// TODO?
    hi,                       /// Hindi
    hu,                       /// Hungarian
    is_,                      /// Icelandic
    io,                       /// Ido
    id,                       /// Indonesian
    ga,                       /// Irish
    it,                       /// Italian
    ja,                       /// Japanese, 日本語
    ka,                       /// Georgian
    ku,                       /// Kurdish
    kn,                       /// Kannada
    kk,                       /// Kazakh
    km,                       /// Khmer
    ko,                       /// Korean
    ky,                       /// Kyrgyz
    lo,                       /// Lao
    la,                       /// Latin
    lt,                       /// Lithuanian
    lv,                       /// Latvian
    jbo,                      /// Lojban
    mk,                       /// Macedonian
    nan,                      /// Min Nan
    mg,                       /// Malagasy
    mn,                       /// Mongolian
    ms,                       /// Malay
    mt,                       /// Maltese
    ne,                       /// Nepali
    no,                       /// Norwegian
    ps,                       /// Pashto
    fa,                       /// Persian
    oc,                       /// Occitan
    pl,                       /// Polish
    pt,                       /// Portuguese
    ro,                       /// omanian
    ru,                       /// ussian
    sa,                       /// Sanskrit
    // sc,                       /// TODO?
    // scn,                       /// TODO?
    si,                       /// Sinhalese
    sm,                       /// Samoan
    sco,                      /// Scots
    sq,                       /// Albanian
    // se,                       /// TODO?
    // sy,                       /// TODO?
    // syc,                       /// TODO?
    te,                       /// egulu
    tl,                       /// agalog
    // tp,                       /// TODO?
    // tpi,                       /// TODO?
    gd,                       /// Scottish Gaelic
    sr,                       /// Serbian
    sk,                       /// Slovak
    sl,                       /// Slovene, Slovenian
    es,                       /// Spanish
    sw,                       /// Swahili
    sv,                       /// Swedish
    tg,                       /// Tajik
    ta,                       /// Tamil
    th,                       /// Thai
    tr,                       /// Turkish
    tk,                       /// Turkmen
    uk,                       /// Ukrainian
    ur,                       /// Urdu
    uz,                       /// Uzbek
    vi,                       /// Vietnamese
    vo,                       /// Volapük
    wa,                       /// Waloon
    yi,                       /// Yiddish
}

/** TODO: Remove when __traits(documentation is merged */
string toName(HLang hlang)
{
    with (HLang)
    {
        final switch (hlang)
        {
            case unknown: return "Unknown";
            case en: return "English, 英語";
            case af: return "Afrikaans";
            case ar: return "Arabic";
            case ae: return "Avestan";
            case ak: return "Akan";
            case an: return "Aragonese";
            case as: return "Assamese";
            case az: return "Azerbaijani";
            case hy: return "Armenian";
            case eu: return "Basque";
            case ba: return "Baskhir";
            case be: return "Belarusian";
            case bn: return "Bengali";
            case br: return "Breton";
            case bs: return "Bosnian";
            case bg: return "Bulgarian";
            case bo: return "Tibetan";
            case my: return "Burmese";
            case zh: return "Chinese Mandarin";
            case crh: return "Crimean Tatar";
            case hr: return "Croatian";
            case ca: return "Catalan";
            case cy: return "Welch";
            case cs: return "Czech";
            case da: return "Danish";
            case nl: return "Dutch";
            case eo: return "Esperanto";
            case et: return "Estonian";
            case fi: return "Finnish";
            case fj: return "Fiji";
            case fo: return "Faeroese";
            case fr: return "French";
            case gl: return "Galician";
            case gv: return "Manx";
            case de: return "German";
            case el: return "Greek";
            case ha: return "Hausa";
            case he: return "Hebrew";
            case hi: return "Hindi";
            case hu: return "Hungarian";
            case is_: return "Icelandic";
            case io: return "Ido";
            case id: return "Indonesian";
            case ga: return "Irish";
            case it: return "Italian";
            case ja: return "Japanese, 日本語";
            case ka: return "Georgian";
            case ku: return "Kurdish";
            case kn: return "Kannada";
            case kk: return "Kazakh";
            case km: return "Khmer";
            case ko: return "Korean";
            case ky: return "Kyrgyz";
            case lo: return "Lao";
            case la: return "Latin";
            case lt: return "Lithuanian";
            case lv: return "Latvian";
            case jbo: return "Lojban";
            case mk: return "Macedonian";
            case nan: return "Min Nan";
            case mg: return "Malagasy";
            case mn: return "Mongolian";
            case ms: return "Malay";
            case mt: return "Maltese";
            case ne: return "Nepali";
            case no: return "Norwegian";
            case ps: return "Pashto";
            case fa: return "Persian";
            case oc: return "Occitan";
            case pl: return "Polish";
            case pt: return "Portuguese";
            case ro: return "Romanian";
            case ru: return "Russian";
            case sa: return "Sanskrit";
            case si: return "Sinhalese";
            case sm: return "Samoan";
            case sco: return "Scots";
            case sq: return "Albanian";
            case te: return "Tegulu";
            case tl: return "Tagalog";
            case gd: return "Scottish Gaelic";
            case sr: return "Serbian";
            case sk: return "Slovak";
            case sl: return "Slovene, Slovenian";
            case es: return "Spanish";
            case sw: return "Swahili";
            case sv: return "Swedish";
            case tg: return "Tajik";
            case ta: return "Tamil";
            case th: return "Thai";
            case tr: return "Turkish";
            case tk: return "Turkmen";
            case uk: return "Ukrainian";
            case ur: return "Urdu";
            case uz: return "Uzbek";
            case vi: return "Vietnamese";
            case vo: return "Volapük";
            case wa: return "Waloon";
            case yi: return "Yiddish";
        }
    }

}

HLang decodeHumanLang(char[] x)
    @safe pure
{
    import std.stdio: writeln;
    if (x == "is")
    {
        return HLang.is_;
    }
    else
    {
        try
        {
            import std.conv: to;
            return x.to!HLang;
        }
        catch (Exception a)
        {
            return HLang.unknown;
        }
    }
}

unittest
{
    assert("sv".to!HLang == HLang.sv);
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
enum WordKind:ubyte
{
    unknown,

    noun,
    nounNumeric,
    nounInteger,                // 11
    nounRationalNumber,         // 1/3
    nounIrrationalNumber,       // pi
    nounComplexNumber,          // 1+2i

    nounLocationName,           // Stockholm
    nounPersonName,             // John
    nounOtherName,
    nounWeekday,

    verb,
    verbPresent,
    verbPast,
    verbFuture,

    adjective,

    adverb, /// changes or simplifies the meaning of a verb, adjective, other adverb, clause, or sentence.
    normalAdverb,
    conjunctiveAdverb, /// joins together sentences

    adverbialConjunction = conjunctiveAdverb,

    preposition, /// often ambiguous
    prepositionTime, /// only related to time
    prepositionPosition, /// only related to space (position)
    prepositionPlace = prepositionPosition,
    prepositionDirection, /// only related to space change (velocity)

    pronoun, /// https://www.englishclub.com/grammar/pronouns.htm

    pronounPersonal, /// https://www.englishclub.com/grammar/pronouns-personal.htm
    pronounPersonalSingular, /// https://www.englishclub.com/grammar/pronouns-personal.htm
    pronounPersonalPlural, /// https://www.englishclub.com/grammar/pronouns-personal.htm
    pronounDemonstrative, /// https://www.englishclub.com/grammar/pronouns-demonstrative.htm

    pronounPossessive, /// https://www.englishclub.com/grammar/pronouns-possessive.htm
    pronounPossessiveSingular, /// https://www.englishclub.com/grammar/pronouns-possessive.htm
    pronounPossessivePlural, /// https://www.englishclub.com/grammar/pronouns-possessive.htm

    determiner,
    article,
    articleUndefinite,
    articleDefinite,
    articlePartitive,
    interjection,

    conjunction,
    coordinatingConjunction,
    subordinatingConjunction,
}

/** Word Sense/Meaning/Interpretation. */
struct WordSense
{
    WordKind kind;
    ubyte synsetCount; // Number of senses (meanings).
    uint[] links;
    HLang hlang;
}

import std.conv: to;

/** Decode character $(D kindCode) into a $(D WordKind). */
WordKind decodeWordKind(C)(C kindCode) if (isSomeChar!C)
{
    typeof(return) kind;
    with (WordKind)
    {
        switch (kindCode)
        {
            case 'n': kind = noun; break;
            case 'v': kind = verb; break;
            case 'a': kind = adjective; break;
            case 'r': kind = adverb; break;
            default: kind = unknown; break;
        }
    }
    return kind;
}

unittest
{
    assert('n'.decodeWordKind == WordKind.noun);
}

/** Decode string $(D kindCode) into a $(D WordKind). */
WordKind decodeWordKind(S)(S kindCode) if (isSomeString!S)
{
    if (kindCode.length == 1)
    {
        return kindCode[0].decodeWordKind;
    }
    else
    {
        return typeof(return).init;
    }
}

unittest
{
    assert("n".decodeWordKind == WordKind.noun);
}

/** Convert $(D word) to $(D kind). */
auto toWordOfKind(S)(S word,
                     WordKind toKind,
                     WordKind fromKind = WordKind.unknown) if (isSomeString!S)
{
    return word;
}

/* TODO: How do I make this work? */
/* private T to(T:WordKind)(char x) */
unittest
{
    /* assert('n'.to!WordKind == WordKind.noun); */
}

@safe pure @nogc nothrow
{
    bool isNoun(WordKind kind)
    {
        with (WordKind)
        {
            return (kind == noun ||
                    kind == nounNumeric ||
                    kind == nounInteger ||
                    kind == nounRationalNumber ||
                    kind == nounIrrationalNumber ||
                    kind == nounComplexNumber ||
                    kind == nounLocationName ||
                    kind == nounPersonName ||
                    kind == nounOtherName ||
                    kind == nounWeekday);
        }
    }
    bool isNounNumeric(WordKind kind)
    {
        with (WordKind)
        {
            return (kind == nounNumeric ||
                    kind == nounInteger ||
                    kind == nounRationalNumber ||
                    kind == nounIrrationalNumber ||
                    kind == nounComplexNumber);
        }
    }
    bool isNounName(WordKind kind)
    {
        with (WordKind)
        {
            return (kind == nounLocationName ||
                    kind == nounPersonName ||
                    kind == nounOtherName);
        }
    }
    bool isVerb(WordKind kind)
    {
        return (kind == WordKind.verb ||
                kind == WordKind.verbPresent ||
                kind == WordKind.verbPast ||
                kind == WordKind.verbFuture);
    }
    bool isAdjective(WordKind kind) { return (kind == WordKind.adjective); }
    bool isAdverb(WordKind kind)
    {
        return (kind == WordKind.adverb ||
                kind == WordKind.normalAdverb ||
                kind == WordKind.conjunctiveAdverb);
    }
    bool isPronoun(WordKind kind)
    {
        return (kind == WordKind.pronoun ||
                kind == WordKind.pronounPersonal ||
                kind == WordKind.pronounPersonalSingular ||
                kind == WordKind.pronounPersonalPlural ||
                kind == WordKind.pronounDemonstrative ||
                kind == WordKind.pronounPossessive ||
                kind == WordKind.pronounPossessiveSingular ||
                kind == WordKind.pronounPossessivePlural);
    }
    bool isPronounSingular(WordKind kind)
    {
        return (kind == WordKind.pronounPersonalSingular ||
                kind == WordKind.pronounPossessiveSingular);
    }
    bool isPronounPluaral(WordKind kind)
    {
        return (kind == WordKind.pronounPersonalPlural ||
                kind == WordKind.pronounPossessivePlural);
    }
    bool isPreposition(WordKind kind)
    {
        return (kind == WordKind.preposition ||
                kind == WordKind.prepositionTime ||
                kind == WordKind.prepositionPosition ||
                kind == WordKind.prepositionPlace ||
                kind == WordKind.prepositionDirection);
    }
    bool isArticle(WordKind kind)
    {
        return (kind == WordKind.article ||
                kind == WordKind.articleUndefinite ||
                kind == WordKind.articleDefinite ||
                kind == WordKind.articlePartitive);
    }
    bool isConjunction(WordKind kind)
    {
        return (kind == WordKind.conjunction ||
                kind == WordKind.coordinatingConjunction ||
                kind == WordKind.subordinatingConjunction);
    }
}

bool memberOf(WordKind child,
              WordKind parent)
    @safe @nogc pure nothrow
{
    switch (parent)
    {
        /* TODO: Use static foreach over all enum members to generate all
         * relevant cases: */
        case WordKind.noun: return child.isNoun;
        case WordKind.verb: return child.isVerb;
        case WordKind.adverb: return child.isAdverb;
        case WordKind.adjective: return child.isAdjective;
        default:return child == parent;
    }
}

static immutable implies = [ "in order to" ];

unittest
{
    assert(WordKind.noun.isNoun);
}

/** Subject Count. */
enum Number { singular, plural }

/** Subject Person. */
enum Person { first, second, third }

/** Subject Gender. */
enum Gender { male, /// maskulinum in Swedish
              female, /// femininum in Swedish
              neutral }

/* Number number(string x, WordKind wc) {} */
/* Person person(string x, WordKind wc) {} */
/* Gender gender(string x, WordKind wc) {} */

/** English Negation Prefixes.
    See also: http://www.english-for-students.com/Negative-Prefixes.html
 */
static immutable negationPrefixes = [ "un", "non", "dis", "im", "in", "il", "ir", ];

/** English Noun Suffixes.
    See also: http://www.english-for-students.com/Noun-Suffixes.html
 */
static immutable adjectiveNounSuffixes = [ "ness", "ity", "ment", "ance" ];
static immutable verbNounSuffixes = [ "tion", "sion", "ment", "ence" ];
static immutable nounNounSuffixes = [ "ship", "hood" ];
static immutable allNounSuffixes = adjectiveNounSuffixes ~ verbNounSuffixes ~ nounNounSuffixes ~ [ "s", "ses", "xes", "zes", "ches", "shes", "men", "ies", ];

/** English Verb Suffixes. */
static immutable verbSuffixes = [ "s", "ies", "es", "es", "ed", "ed", "ing", "ing", ];

/** English Adjective Suffixes. */
static immutable adjectiveSuffixes = [ "er", "est", "er", "est" ];

/** English Job/Professin Title Suffixes.
    Typically built from noun or verb bases.
    See also: http://www.english-for-students.com/Job-Title-Suffixes.html
*/
static immutable jobTitleSuffixes = [ "or", // traitor
                                      "er", // builder
                                      "ist", // typist
                                      "an", // technician
                                      "man", // dustman, barman
                                      "woman", // policewoman
                                      "ian", // optician
                                      "person", // chairperson
                                      "sperson", // spokesperson
                                      "ess", // waitress
                                      "ive" // representative
    ];

/** English Word Suffixes. */
static immutable wordSuffixes = [ allNounSuffixes ~ verbSuffixes ~ adjectiveSuffixes ].uniq.array;

/** Get English Word Base of $(D x). */
auto wordBase(S)(S lemma, WordSense wordSense) if (isSomeString!S)
{
    doit;
}

/** Get English Order Name of $(D n). */
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
