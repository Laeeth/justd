#!/usr/bin/env rdmd-dev

/** Generic Language Constructs. */
module languages;

import std.traits: isSomeChar, isSomeString;
import std.typecons: Nullable;

/** Human Language. */
enum HumanLang:ubyte
{
    en,                       // English, 英語
    af,                       // Afrikaans
    ar,                       // Arabic
    hy,                       // Armenian
    eu,                       // Basque
    be,                       // Belarusian
    bn,                       // Bengali
    bs,                       // Bosnian
    bg,                       // Bulgarian
    my,                       // Burmese
    zh,                       // Chinese Mandarin
    crh,                      // Crimean Tatar
    hr,                       // Croatian
    cs,                       // Czech
    da,                       // Danish
    nl,                       // Dutch
    eo,                       // Esperanto
    et,                       // Estonian
    fi,                       // Finnish
    fr,                       // French
    gl,                       // Galician
    de,                       // German
    el,                       // Greek
    he,                       // Hebrew
    hi,                       // Hindi
    hu,                       // Hungarian
    is_,                      // Icelandic
    io,                       // Ido
    id,                       // Indonesian
    ga,                       // Irish
    it,                       // Italian
    ja,                       // Japanese, 日本語
    kn,                       // Kannada
    kk,                       // Kazakh
    km,                       // Khmer
    ko,                       // Korean
    ky,                       // Kyrgyz
    lo,                       // Lao
    la,                       // Latin
    lt,                       // Lithuanian
    jbo,                      // Lojban
    mk,                       // Macedonian
    nan,                      // Min Nan
    mg,                       // Malagasy
    no,                       // Norwegian
    ps,                       // Pashto
    fa,                       // Persian
    pl,                       // Polish
    pt,                       // Portuguese
    ro,                       // Romanian
    ru,                       // Russian
    sa,                       // Sanskrit
    si,                       // Sinhalese
    sco,                      // Scots
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

/** Computer Token Id. */
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

/** Human Word Category. */
enum WordCategory:ubyte
{
    unknown,

    noun, nounInteger, nounRational,

    verb,
    adjective,

    adverb, anyAdverb = adverb,
    normalAdverb,
    conjunctiveAdverb, // joins together sentences

    adverbialConjunction = conjunctiveAdverb,

    preposition,
    pronoun,
    determiner,
    article,
    interjection,

    coordinatingConjunction,
    subordinatingConjunction,
}

/** Lookup WordCategory from Textual $(D x).
    TODO: Construct internal hash table from WordNet.
 */
auto to(T: WordCategory, S)(S x) if (isSomeString!S ||
                                     isSomeChar!S)
{
    T type;
    with (WordCategory)
    {
        switch (x)
        {
            case "car": type = noun; break;
            case "drive": type = verb; break;
            case "fast": type = adjective; break;
            case "quickly": type = normalAdverb; break;
            case "at": type = preposition; break;
            case "he": type = pronoun; break;
            case "the": type = article; break;
            case "uh":
            case "er":
            case "um": type = interjection; break;
            default: break;
        }
        return type;
    }
}

unittest
{
    with (WordCategory)
    {
        assert("car".to!WordCategory == WordCategory.noun);
    }
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
