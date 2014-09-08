#!/usr/bin/env rdmd-dev

/** Generic Language Constructs. */
module languages;

import std.traits: isSomeChar, isSomeString;

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
    assert(toTag(Lang.init) == `?`);
    assert(toTag(Lang.c) == `C`);
    assert(toTag(Lang.cxx) == `C++`);
    assert(toTag(Lang.d) == `D`);
    assert(toTag(Lang.java) == `Java`);
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

    noun,
    verb,
    adjective,

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
WordCategory to(T: WordCategory, S)(S x) if (isSomeChar!S ||
                                             isSomeString!S)
{
    typeof(return) type;
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
