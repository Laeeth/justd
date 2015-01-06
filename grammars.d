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

/** Language Code according to ISO 639-1 plus computer languages.
    See also: http://www.mathguide.de/info/tools/languagecode.html
    See also: https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
    See also: http://msdn.microsoft.com/en-us/library/ms533052(v=vs.85).aspx
 */
enum Lang:ushort
{
    unknown,                    /// Unknown
    any = unknown,
    en,                       /// English
    en_US,                       /// American. English
    en_GB,                       /// British English
    en_CA,                       /// Canadian English
    // ac,                       /// TODO?
    // ace,                      /// TODO?
    // ai,                       /// TODO?
    // ain,                       /// TODO?
    af,                       /// Afrikaans
    ar,                       /// Arabic
    // ary,                       /// TODO?
    // arc,                       /// TODO?
    ae,                       /// Avestan Iran (extinct)
    ak,                       /// Akan
    // akk,                      /// TODO?
    an,                       /// Aragonese
    // ang,                       /// TODO?
    as,                       /// Assamese
    // ase,                       /// TODO?
    // ast,                       /// TODO?
    // ax,                       /// TODO?
    az,                       /// Azerbaijani (Azeri)
    hy,                       /// Armenian: Armenia
    eu,                       /// Basque: Spain, France
    ba,                       /// Baskhir: Volga, Urals, Central Asia
    // ban,                      /// TODO?
    be,                       /// Belarusian
    // bj,                       /// TODO?
    bn,                       /// Bengali (Bangla): Bangladesh, India
    br,                       /// Breton: France
    bs,                       /// Bosnian
    bg,                       /// Bulgarian
    bo,                       /// Tibetan
    // bp,                       /// TODO?
    // bt,                       /// TODO?
    my,                       /// Burmese: Myanmar
    zh,                       /// Chinese (Mandarin, Putonghua): China, Singapore
    crh,                      /// Crimean Tatar
    hr,                       /// Croatian: Croatia
    // cr,                       /// TODO?
    ca,                       /// Catalan/Valencian (Spain)
    cy,                       /// Welch: Wales, Heddwch, Tangnefedd
    cs,                       /// Czech: Czech Republic
    // csb,                      /// TODO?
    da,                       /// Danish: Denmark, Greenland
    // ds,                       /// TODO?
    // dsb,                      /// TODO?
    nl,                       /// Dutch (Flemish): Netherlands, Belgium
    eo,                       /// Esperanto
    et,                       /// Estonian
    fi,                       /// Finnish: Finland, Sweden, Russia
    fj,                       /// Fijian: Fiji
    fo,                       /// Faroese (Faeroese): Faroe Islands
    // fu,                       /// TODO?
    fr,                       /// French: France, Belgium, Canada, Caribbean, West Africa, Polynesia
    fr_ch,                    /// French (Switzerland)
    gl,                       /// Galician (Gallegan): Spain, Portugal
    gv,                       /// Manx: Isle of Man
    de,                       /// German: Germany, Austria, Switzerland, Liechtenstein, Italy, Belgium
    el,                       /// Greek: Greece, Cyprus
    ha,                       /// Hausa: Nigeria
    haw,                      /// Hawaiian: Hawaii
    he,                       /// Hebrew: Israel
    // hs,                       /// TODO?
    // hsb,                      /// TODO?
    hi,                       /// Hindi: India, Nepal, Uganda, Suriname
    hu,                       /// Hungarian: Hungary, Romania, Slovakia
    is_,                      /// Icelandic
    io,                       /// Ido: Nigeria
    id,                       /// Indonesian (Bahasa): Indonesia
    ga,                       /// Irish: Ireland
    it,                       /// Italian: Italy, Switzerland
    ja,                       /// Japanese, 日本語: Japan
    ka,                       /// Georgian: Georgia
    ku,                       /// Kurdish: Kurdistan (Turkey, Syria, Iran, Iraq)
    kn,                       /// Kannada: India
    kk,                       /// Kazakh: Kazakhstan
    km,                       /// Khmer: Cambodia
    ko,                       /// Korean: Korea
    ky,                       /// Kirghiz (Kyrgyz): Kirghizstan, China
    lo,                       /// Lao: Laos
    la,                       /// Latin: Rome (extinct)
    lt,                       /// Lithuanian: Lithuania
    lv,                       /// Latvian: Latvia
    jbo,                      /// Lojban
    mk,                       /// Macedonian: Macedonia
    nan,                      /// Min Nan
    mg,                       /// Malagasy (Malgache): Madagascar
    mn,                       /// Mongolian: Mongolia
    ms,                       /// Malay: Malaysia
    mt,                       /// Maltese: Malta
    ne,                       /// Nepali: Nepal
    no,                       /// Norwegian: Norway
    ps,                       /// Pashto: Afghanistan, Iran, Pakistan
    fa,                       /// Persian (Farsi): Iran, Iraq, Afghanistan, Pakistan, Azerbaijan
    oc,                       /// Occitan (Provençal, Languedocian): France
    pl,                       /// Polish
    pt,                       /// Portuguese: Portugal, Brazil, Angola, Mozambique, Cape Verde, Guinea-Bissau
    pt_BR,                    /// Brazilian Portuguese
    ro,                       /// Romanian: Romania, Hungary
    ru,                       /// Russian
    sa,                       /// Sanskrit: India (extinct, liturgical)
    // sc,                    /// TODO?
    // scn,                   /// TODO?
    si,                       /// Sinhalese: Sri Lanka
    sm,                       /// Samoan: Samoa
    sco,                      /// Scots: Scotland
    sq,                       /// Albanian: Albania, Kosovo
    // se,                       /// TODO?
    // sy,                       /// TODO?
    // syc,                       /// TODO?
    te,                       /// Telugu: India
    tl,                       /// Tagalog (Pilipino): Philippines
    // tp,                       /// TODO?
    // tpi,                       /// TODO?
    gd,                       /// Scottish Gaelic: Scotland
    sr,                       /// Serbian: Serbia, Montenegro, Bosnia
    sk,                       /// Slovak: Slovak Republic
    sl,                       /// Slovene, Slovenian: Slovenia, Austria, Italy
    es,                       /// Spanish
    sw,                       /// Swahili: East Africa
    sv,                       /// Swedish
    tg,                       /// Tajik: Tajikistan, Afghanistan
    ta,                       /// Tamil: India
    th,                       /// Thai: Thailand
    tr,                       /// Turkish: Turkey, Cyprus
    tk,                       /// Turkmen: Turkmenistan, Afghanistan
    uk,                       /// Ukrainian
    ur,                       /// Urdu: Pakistan, India, Central Asia
    uz,                       /// Uzbek: Uzbekistan, Central Asia, China
    vi,                       /// Vietnamese: Viet Nam
    vo,                       /// Volapük
    wa,                       /// Waloon: Belgium
    yi,                       /// Yiddish: Israel, USA, Russia
    faroese,                  /// Faroese

    aa, // Afar	Ethiopia, Eritrea, Djibouti	Salaamata
    ab, // Abkhaz	Caucasus	needed!
    afa, // Luganda	Uganda	Emirembe
    akk, // Akkadian	Mesopotamia (extinct)	(Salmu)
    alg, // Abenaki	North America	Okikiamgenoka, Kamignokawôgan
    am, // Amharic	Ethopia, Egypt	ሰላም (salām)
    ang, // Anglo Saxon (Old English)	England (extinct)	ᚠᚱᛁᚦ (friþ), Frið
    arw, // Arawak	Suriname, Guyana, Venezuela	needed!
    arc, // Aramaic (Syriac, Assyrian)	Iraq, Iran, Syria, and liturgical	ܫܠܡܐ (shlamaa)
    arn, // Mapundungun	Chile	Uvchin, Tügkülen
    art, // Lojban	 	panpi
    ast, // Asturian	Spain	Paz
    at, // Haiti / Guiana Creole (Kreyol)	Caribbean	Lapè
    aus, // Olkola	Australia	Erray
    // aus, // Pintupi-Luritja	Australia	Yatanpa
    // aus, // Wagiman	Australia	Nyimbur-ma
    // aus, // Warlpiri	Australia	Iawa-nyinami
    av, // Avar	Caucasus	Рекъел (reqel)
    ay, // Aymara	Bolivia	Hacaña
    bai, // Dschang (Yemba)	Cameroon	Mbwɛ´né
    bas, // Basaa	Cameroon	SàN
    bat, // Old Prussian, Sudovian (Jatvingian)	Baltic (extinct)	Pakajan
    btk, // Batak	Indonesia	Pardamean
    bem, // Bemba	Zambia	Mutenden, Ukwikala mu
    bh, // Bihari	India	needed!
    bi, // Bislama	Vanuatu	Pís
    bla, // Blackfoot	North America	Innaihtsi'iyi
    bm, // Bambara	Mali	Here, Errébé
    cai, // Ch'ol (Tumbalá)	Chiapas (Mexico)	Ñʌch'chocoya
    car, // Caribe	Venezuala, Suriname	needed!
    ce, // Chechen	Chechnya (Caucasus)	Машар (mashar)
    ceb, // Cebuano	Philippines	Kalinaw, Kahusayan
    ch, // Chamorro	Guam	Minaggen
    cho, // Choctaw	North America	Achukma
    chk, // Chuuk	Truk	Kunammwey
    chr, // Cherokee (Tsalagi)	North America	ᏙᎯᏱ (dohiyi)
    chy, // Cheyenne	North America	Nanomonsetôtse
    co, // Corsican	Corsica (France)	Pace
    cop, // Coptic	Egypt (extinct) and liturgical	Ϩιρηνη (hirīnī)
    cpe, // Afro-Seminole	North America	needed!
    cpf, // Cajun French (Acadian, Kreyol Lwiziyen)	Louisiana (USA)	needed!
    cr, // Cree	North America	Wetaskiwin, Papayatik
    crp, // Fanagolo	South Africa	Kutula
    cu, // Old Church Slavonic	Eastern Europe (liturgical)	Ми́ръ (mírə)
    cv, // Chuvash	Russia	needed!
    del, // Lenape (Delaware)	North America	Achwangundowagan
    dua, // Duala	Cameroon	Musango
    dra, // Brahui	Pakistan, Afghanistan, Iran	(âsûdaî)
    dv, // Divehi (Maldivian)	Maldives	ސުޅަ (sulha)
    dz, // Dzongkha	Bhutan	གཞི་བདེ (gzhi-bde)
    ee, // Ewe (Évé)	West Africa	Ŋutifafa
    efi, // Efik	Nigeria	Emem
    enm, // Middle English	England (extinct)	Pes, Pise, Pees, ...
    ff, // Fula (Falani)	West Africa	Jam
    fiu, // Karelian	Russia, Finland	Rauhu, Vienosti
    fon, // Fon	Benin	Fifâ
    fro, // Old French	France	Pais
    fur, // Friulian (Frulan)	Friuli (Italy)	Pâs
    fy, // Frisian	Germany, Netherlands	Frede
    gez, // Ge'ez	Ethiopia, Eritrea (liturgical)	ሰላም (salām)
    gmh, // Middle High German	Central Europe (extinct)	Vride
    gn, // Guarani	Bolivia, Paraguay, Brazil	Apĭrĭvé, Ñerane'i, Py'aguapy
    goh, // Old High German	Central Europe (extinct)	Fridu
    got, // Gothic	Central Europe (extinct)
    grc, // Ancient Greek	Miditerranean (extinct) and liturgical	Εἰρήνη (eirḗnē)
    gu, // Gujarati	India, Pakistan	શાંતિ (śānti)
    hil, // Hiligaynon (Ilongo)	Philippines	Paghidait
    hmn, // Hmong	China, Viet Nam, Laos, Thailand	Kev tiaj tus
    ho, // Hiri Motu	Papua New Guinea	Taim billong sikan
    hz, // Herero	Southern Africa	needed!
    ia, // Interlingua	 	Pace
    ie, // Interlingue	 	Pace
    ig, // Igbo (Ibo)	Nigeria	Udo
    ii, // Sichuan Yi	China	ꄮꐽ (te-njo)
    ik, // Iñupiaq	Alaska	Kiñuiñak, Tutqiun
    ilo, // Ilocano	Philippines	Kappia
    inh, // Ingush	Ingutia (Caucasus)	Машар (mashar)
    iu, // Inuktitut	Canada	ᓴᐃᒻᒪᓯᒪᓂᖅ (saimmasimaniq)
    jpr, // Judeo-Persian (Bukharic)	Mideast, Central Asia	needed!
    jrb, // Judeo-Arabic	Mideast, North Africa	needed!
    jv, // Javanese	Indonesia	Rukun
    kab, // Kabyle	Algeria	Lahna
    kg, // Kongo	Congo	Kikœndi
    ki, // Kikuyu (Gikuyu)	Kenya	Thayu
    kj, // Kwanyama (Kuanyama)	Angola, Namibia	needed!
    kl, // Greenlandic (Kalaallisut)	Greenland	Irqigsiniq, Erĸigsineĸ
    kos, // Kosraean	Micronesia	Mihs
    kr, // Kanuri	Niger, Nigeria	needed!
    ks, // Kashmiri	Kashmir (India, Pakistan)	امن (amn)
    kv, // Komi	Russian Arctic	needed!
    kw, // Cornish	Cornwall (extinct)	Cres
    lad, // Ladino (Judeo-Spanish)	Turkey, Israel, North Africa	Pas, פאש
    lb, // Luxemburgish (Lëtzebuergesch)	Luxembourg	Fridd, Fridden
    lg, // Ganda	Niger, Congo	needed!
    li, // Limburgan (Limburgish)	Belgium	Vreij
    ln, // Lingala	Congo	Kímía
    lol, // Mongo-Nkundu	Congo	Bóoto
    loz, // Lozi	Zambia	Nala
    lu, // Luba-Katanga	Niger, Congo	needed!
    man, // Mandinka	Senegal, Gambia, Guinea-Bissau	Kayiroo
    map, // Bisaya	Brunei	Kalinaw
    mh, // Marshallese	Marshall Islands	Ainemon
    mi, // Maori	New Zealand	Rangima'arie, Nohopuku, Rongo
    mic, // Micmac	North America	Wôntôkóde
    mis, // Ainu	Japan	アプンノ, あぷんの (apunno)
    ml, // Malayalam	India	സമാധാനം (samaadhaanam)
    mno, // Manobo	Philippines	Linew
    mo, // Moldavian (Moldavan)	Moldava	Pace, Паче (pace)
    mos, // Mossi (Moré)	Burkina Faso	Lâfí
    mr, // Marathi	India	शांतता (śāntātā), शांती (śāntī)
    mus, // Muskogee (Creek)	North America	Ittimokla
    myn, // Kekchi	Guatemala, Belize	Tuktuquil usilal
    na, // Nauruan	Nauru	Iow
    nah, // Náhuatl (Aztec)	Mexico, Guatemala	Tlamatcanemiliztli, Mocehuia
    nd, // North Ndebele	Zimbabwe	needed!
    nds, // Old Saxon	Saxony (extinct)	Friðu
    ng, // Ndonga	Angola, Namibia	needed!
    non, // Old Norse	Scandinavia (extinct)	ᚠᚱᛁᚦᚱ, Friðr
    nr, // South Ndebele	Zimbabwe, Botswana	needed!
    nv, // Navajo (Navaho)	North America	K'é, Hozo
    ny, // Chichewa (Chewa, Nyanja)	Malawi	M'tendere
    om, // Oromo	Ethiopia, Kenya	Nagaya, ነገየ (nagaya)
    or, // Oriya	India	needed!
    os, // Ossetic (Ossetian)	Georgia, Russia	needed!
    oto, // Otomi	Mexico	Hmetho
    pa, // Panjabi (Punjab)	Pakistan, India	ਸ਼ਾਂਤੀ (śānti)
    paa, // Ekari	Indonesia	Muka-Muka
    pag, // Pangasinan	Philippines	Kareenan
    pam, // Pampangan (Kapampangan)	Philippines	Kapayapan
    pap, // Papiamentu	Netherlands Antilles	Pas
    pau, // Palauan	Palau	Búdech
    pi, // Pali	India	Sāma, Santi
    qu, // Quechua	Peru	Anka Kay, Qasikay, Aligu, Sonqo Tiaykuy
    rap, // Rapanui	Chile	Kiba-kiba, Pava
    rm, // Raeto-Romance (Romansch)	Switzerland	Pasch
    rn, // Rundi (Kirundi, Urundi)	Burundi	Amahoro
    rom, // Romany (Gypsy, Tsigane)	Europe, South America, etc	Smirom
    rw, // Kinyarwanda (Rwanda, Ruanda)	Rwanda	Nimuhóre, Amahoro
    sd, // Sindhi	Pakistan, India	शांति, شانت (śanti)
    sg, // Sango	Central African Republic	needed!
    sn, // Shona	Zimbabwe	Runyaro, Dendemaro
    so, // Somali	Somalia, Djibouti, Ethiopia	Nabáda
    ss, // Swati (Siswati)	Swaziland	Kuthála
    st, // Southern Sotho (Sesotho, Sesuthu)	South Africa	Kgotso, Khotso
    su, // Sundanese	Indonesia	needed!
    ti, // Tigrinya (Tigrigna)	Eritrea	ሰላም (salām)
    tli, // Tlingit	North America	Li-k'ei
    tn, // Tswana (Setswana)	Botswana	Khotso, Kagiso
    to, // Tonga	Zambia	Malino, Melino
    ts, // Tsonga	South Africa	needed!
    tt, // Tatar	Russia	Тынычлык (tınıçlık)
    tw, // Twi	West Africa	Asomdwee
    ty, // Tahitian	Tahiti	Hau
    ug, // Uighur (Uygur)	China, Central Asia	تىنچلىق (tinçlik)
    ve, // Venda	South Africa	needed!
    wen, // Upper Sorbian (Wendish)	Germany	Pokoj
    wo, // Wolof	West Africa	Jàmm
    xh, // Xhosa	South Africa, Botswana	Uxolo
    yo, // Yoruba	Nigeria, Benin, Togo	Alaáfía
    ypk, // Yu'pik	Alaska, Canada	Kiñuiñak
    za, // Chuang (Zhuang)	China	needed!
    zap, // Zapotec	Mexico	Layeni, Binlo
    zu, // Zulu	Southern Africa	Isithangami, Ukuthula

    c,
    firstFormal = c,
    cxx,
    objectiveC,
    objectiveCxx,
    cSharp,
    d,
    java,
    ada,
    rust,
    swift,
    fortran,
    modelica,

    math,                ///< "Mathematics is the only truly universal language"
    physics,
}

/** Return true if $(D lang) is case-sensitive. */
bool hasCase(Lang lang) @safe pure @nogc nothrow
{
    with (Lang) return lang.of(bg, ada);
}
alias isCaseSensitive = hasCase;

/** Return true if $(D lang) is a formal (computer) language. */
bool isFormal(Lang lang) @safe pure @nogc nothrow
{
    with (Lang) return (lang >= firstFormal);
}
alias forMachines = isFormal;
alias isProgrammingLanguage = isFormal;

/** TODO Remove when __traits(documentation is merged */
string toHuman(Lang lang) @safe pure @nogc nothrow
{
    with (Lang)
    {
        switch (lang)
        {
            case unknown: return `??`;
            case en: return `English`; // 英語
            case en_US: return `American English`;
            case en_GB: return `British English`;
            case en_CA: return `Canadian English`;
            case af: return `Afrikaans`;
            case ar: return `Arabic`;
            case ae: return `Avestan`;
            case ak: return `Akan`;
            case an: return `Aragonese`;
            case as: return `Assamese`;
            case az: return `Azerbaijani`;
            case hy: return `Armenian`;
            case eu: return `Basque`;
            case ba: return `Baskhir`;
            case be: return `Belarusian`;
            case bn: return `Bengali`;
            case br: return `Breton`;
            case bs: return `Bosnian`;
            case bg: return `Bulgarian`;
            case bo: return `Tibetan`;
            case my: return `Burmese`;
            case zh: return `Chinese Mandarin`;
            case crh: return `Crimean Tatar`;
            case hr: return `Croatian`;
            case ca: return `Catalan`;
            case cy: return `Welch`;
            case cs: return `Czech`;
            case da: return `Danish`;
            case nl: return `Dutch`;
            case eo: return `Esperanto`;
            case et: return `Estonian`;
            case fi: return `Finnish`;
            case fj: return `Fiji`;
            case fo:
            case faroese: return `Faroese`;
            case fr: return `French`;
            case fr_ch: return `French (Switzerland)`;
            case gl: return `Galician`;
            case gv: return `Manx`;
            case de: return `German`;
            case el: return `Greek`;
            case ha: return `Hausa`;
            case he: return `Hebrew`;
            case hi: return `Hindi`;
            case hu: return `Hungarian`;
            case is_: return `Icelandic`;
            case io: return `Ido`;
            case id: return `Indonesian`;
            case ga: return `Irish`;
            case it: return `Italian`;
            case ja: return `Japanese`; // 日本語
            case ka: return `Georgian`;
            case ku: return `Kurdish`;
            case kn: return `Kannada`;
            case kk: return `Kazakh`;
            case km: return `Khmer`;
            case ko: return `Korean`;
            case ky: return `Kyrgyz`;
            case lo: return `Lao`;
            case la: return `Latin`;
            case lt: return `Lithuanian`;
            case lv: return `Latvian`;
            case jbo: return `Lojban`;
            case mk: return `Macedonian`;
            case nan: return `Min Nan`;
            case mg: return `Malagasy`;
            case mn: return `Mongolian`;
            case ms: return `Malay`;
            case mt: return `Maltese`;
            case ne: return `Nepali`;
            case no: return `Norwegian`;
            case ps: return `Pashto`;
            case fa: return `Persian`;
            case oc: return `Occitan`;
            case pl: return `Polish`;
            case pt: return `Portuguese`;
            case pt_BR: return `Brazilian Portuguese`;
            case ro: return `Romanian`;
            case ru: return `Russian`;
            case sa: return `Sanskrit`;
            case si: return `Sinhalese`;
            case sm: return `Samoan`;
            case sco: return `Scots`;
            case sq: return `Albanian`;
            case te: return `Tegulu`;
            case tl: return `Tagalog`;
            case gd: return `Scottish Gaelic`;
            case sr: return `Serbian`;
            case sk: return `Slovak`;
            case sl: return `Slovene`;
            case es: return `Spanish`;
            case sw: return `Swahili`;
            case sv: return `Swedish`;
            case tg: return `Tajik`;
            case ta: return `Tamil`;
            case th: return `Thai`;
            case tr: return `Turkish`;
            case tk: return `Turkmen`;
            case uk: return `Ukrainian`;
            case ur: return `Urdu`;
            case uz: return `Uzbek`;
            case vi: return `Vietnamese`;
            case vo: return `Volapük`;
            case wa: return `Waloon`;
            case yi: return `Yiddish`;
            case akk: return `Akkadian`;
            case ce: return `Chechen`;
            case co: return `Corsican`;
            case fur: return `Friulian`;
            case gu: return `Gujarati`;
            case hil: return `Hiligaynon`;
            case haw: return `Hawaiian`;

            case c: return `C`;
            case cxx: return `C++`;
            case cSharp: return `C#`;
            case objectiveC: return `Objective-C`;
            case objectiveCxx: return `Objective-C++`;
            case d: return `D`;
            case java: return `Java`;
            case ada: return `Ada`;
            case rust: return `Rust`;
            case swift: return `Swift`;
            case fortran: return `Fortran`;
            case modelica: return `Modelica`;
            case math: return `Mathematics`;
            case physics: return `Physics`;
            default: return "??";
        }
    }

}

Lang decodeLang(S)(S lang) @safe pure nothrow if (isSomeString!S)
{
    if (lang == `is`)
    {
        return Lang.is_;
    }
    else
    {
        try
        {
            return lang.to!Lang;
        }
        catch (Exception a)
        {
            return Lang.unknown;
        }
    }
}

unittest
{
    assert(`sv`.to!Lang == Lang.sv);
}

unittest
{
    with (Lang)
    {
        assert(unknown.toHuman == `??`);
        assert(c.toHuman == `C`);
        assert(cxx.toHuman == `C++`);
        assert(d.toHuman == `D`);
        assert(java.toHuman == `Java`);
    }
}

string toHTML(Lang lang) @safe @nogc pure nothrow
{
    return lang.toHuman;
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
        case `Objective-C`:  return Lang.objectiveC;
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
enum spanishAccentedVowels = ['é', 'í', 'ó', 'ú', 'ü', 'ñ', 'ü'];

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
    with (Lang)
    {
        switch (lang)
        {
            case en: return c.isEnglishVowel;
            case sv: return c.isSwedishVowel;
            default: return c.isEnglishVowel;
        }
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

enum EnglishDoubleConsonants = ["bb", "dd", "ff", "gg", "mm", "nn", "pp", "rr", "tt"];

/** Check if $(D c) is a Consonant. */
bool isEnglishDoubleConsonant(S)(S s) if (isSomeString!S)
{
    return c.of("bb", "dd", "ff", "gg", "mm", "nn", "pp", "rr", "tt");
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

/** Human Word Sense Kind (Category). */
enum Sense:ubyte
{
    unknown,

    prefix,
    suffix,

    idiom,                      /// Idiomatic Expression.
    slang,                      /// Slang

    ordinalNumber, ///< https://en.wikipedia.org/wiki/Ordinal_number_%28linguistics%29

    noun,
    nounSingular,
    nounPlural,

    nounNumeric,

    nounInteger,                /// 11
    nounIntegerPositive,        /// 0,1, ...
    nounIntegerNegative,        /// ..., -1, 0

    nounDecimal,                /// 3.14

    nounRationalNumber,         /// 1/3
    nounIrrationalNumber,       /// pi, e
    nounComplexNumber,          /// 1+2i

    nounName,                   /// proper name
    nounNameMale,               /// proper name
    nounNameFemale,             /// proper name
    nounNameSur,                /// proper surname

    nounLocationName,           /// Stockholm
    nounPersonName,             /// John
    nounOrganisationName,       /// CIA
    nounCountry,                /// Sweden

    nounTimeWeekday,
    nounTimeMonth,
    nounTimeDayOfMonth,
    nounTimeYear,
    nounTimeDayOfYear, nounDate = nounTimeDayOfYear,

    nounSeason,

    nounUncountable,

    nounAbbrevation,
    nounAcronym,

    nounSIBaseUnitName,
    nounSIDerivedUnitName,

    /* Verb */

    verb,
    verbAbbrevation,

    verbImperative,

    verbInfinitive,
    verbBase = verbInfinitive,

    verbPresent,

    verbPast,
    verbImperfect = verbPast, /// https://en.wikipedia.org/wiki/Imperfect

    verbPastParticiple,
    verbSupinum = verbPastParticiple,

    verbFuture, /// https://en.wikipedia.org/wiki/Future_tense
    verbFuturum = verbFuture,
    verbFuturumI,
    verbFuturumII,

    auxiliaryVerb, /// https://en.wikipedia.org/wiki/Auxiliary_verb. "Hjälpverb" in Swedish
    auxiliaryVerbModal, /// Modalt Hjälpverb

    /* Adjective */

    adjective,
    adjectiveAbbrevation,

    adjectiveNominative,
    adjectiveComparative,
    adjectiveSuperlative,
    adjectivePossessive,
    adjectivePossessiveSingular,
    adjectivePossessivePlural,

    adverb, /// changes or simplifies the meaning of a verb, adjective, other adverb, clause, or sentence.
    normalAdverb,
    conjunctiveAdverb, adverbialConjunction = conjunctiveAdverb, /// joins together sentences
    negatingAdverb,
    affirmingAdverb,


    preposition, /// often ambiguous
    prepositionTime, /// only related to time
    prepositionPosition, /// only related to space (position)
    prepositionPlace = prepositionPosition,
    prepositionDirection, /// only related to space change (velocity)

    pronoun, /// https://www.englishclub.com/grammar/pronouns.htm

    pronounPersonal, /// https://www.englishclub.com/grammar/pronouns-personal.htm
    pronounPersonalSingular, /// https://www.englishclub.com/grammar/pronouns-personal.htm
    pronounPersonalSingularMale,
    pronounPersonalSingularFemale,
    pronounPersonalSingularNeutral,
    pronounPersonalPlural, /// https://www.englishclub.com/grammar/pronouns-personal.htm

    pronounDemonstrative, /// https://www.englishclub.com/grammar/pronouns-demonstrative.htm

    pronounPossessive, /// https://www.englishclub.com/grammar/pronouns-possessive.htm
    pronounPossessiveSingular, /// https://www.englishclub.com/grammar/pronouns-possessive.htm
    pronounPossessiveSingularMale,
    pronounPossessiveSingularFemale,
    pronounPossessiveSingularNeutral,
    pronounPossessivePlural, /// https://www.englishclub.com/grammar/pronouns-possessive.htm

    pronounInterrogative, /// https://www.englishclub.com/grammar/pronouns-reciprocal.htm

    pronounReflexive,
    pronounReflexiveSingular,
    pronounReflexivePlural,

    pronounReciprocal,

    pronounIndefinite,
    pronounIndefiniteSingular,
    pronounIndefinitePlural,

    pronounRelative, /// https://www.englishclub.com/grammar/pronouns-relative.htm

    determiner,
    predeterminer,

    article,
    articleUndefinite,
    articleDefinite,
    articlePartitive,

    conjunction,
    coordinatingConjunction,
    subordinatingConjunction,

    interjection, exclamation = interjection,
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
enum Article:ubyte { unindefinite, definite,  partitive }

class Subject : Part
{
    Article article;
}

/** Decode character $(D kindCode) into a $(D Sense). */
Sense decodeWordKind(C)(C kindCode) if (isSomeChar!C)
{
    typeof(return) kind;
    with (Sense)
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
    assert('n'.decodeWordKind == Sense.noun);
}

/** Decode string $(D kindCode) into a $(D Sense). */
Sense decodeWordKind(S)(S kindCode) if (isSomeString!S)
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
    assert(`n`.decodeWordKind == Sense.noun);
}

/** Convert $(D word) to $(D kind). */
auto toWordOfKind(S)(S word,
                     Sense toKind,
                     Sense fromKind = Sense.unknown) if (isSomeString!S)
{
    return word;
}

/* TODO How do I make this work? */
/* private T to(T:Sense)(char x) */
unittest
{
    /* assert('n'.to!Sense == Sense.noun); */
}

@safe pure @nogc nothrow
{
    bool isNoun(Sense kind)
    {
        with (Sense)
            return (kind.isNounNumeric ||
                    kind.of(noun,
                            nounSingular,
                            nounPlural,
                            nounTimeWeekday,
                            nounTimeMonth,
                            nounTimeDayOfMonth,
                            nounTimeYear,
                            nounSeason,
                            nounUncountable,
                            nounAbbrevation,
                            nounAcronym) ||
                    kind.isNounName);
    }
    bool isNounNumeric(Sense kind)
    {
        with (Sense)
            return (kind.isNounInteger ||
                    kind.of(nounNumeric,
                            nounDecimal,
                            nounRationalNumber,
                            nounIrrationalNumber,
                            nounComplexNumber));
    }
    bool isNounInteger(Sense kind)
    {
        with (Sense)
            return (kind.of(nounInteger,
                            nounIntegerPositive,
                            nounIntegerNegative));
    }
    bool isNounName(Sense kind)
    {
        with (Sense)
            return kind.of(nounName,
                           nounNameMale,
                           nounNameFemale,
                           nounNameSur,
                           nounLocationName,
                           nounPersonName,
                           nounOrganisationName,
                           nounCountry);
    }
    bool isVerb(Sense kind)
    {
        with (Sense)
            return kind.of(verb,
                           verbAbbrevation,
                           verbImperative,
                           verbInfinitive,
                           verbPresent,
                           verbPast,
                           verbFuture,
                           verbPastParticiple);
    }
    bool isAdjective(Sense kind)
    {
        with (Sense)
            return kind.of(adjective,
                           adjectiveAbbrevation,
                           adjectiveNominative,
                           adjectiveComparative,
                           adjectiveSuperlative,
                           adjectivePossessiveSingular,
                           adjectivePossessivePlural);
    }
    bool isAdverb(Sense kind)
    {
        with (Sense)
            return kind.of(adverb,
                           normalAdverb,
                           negatingAdverb,
                           affirmingAdverb,
                           conjunctiveAdverb);
    }
    bool isPronoun(Sense kind)
    {
        with (Sense)
            return (kind == pronoun ||
                    kind.isPronounPersonal ||
                    kind.isPronounPossessive ||
                    kind.isPronounDemonstrative ||
                    kind == pronounInterrogative ||
                    kind.isPronounReflexive ||
                    kind.isPronounIndefinite ||
                    kind == pronounRelative);
    }
    bool isPronounPersonal(Sense kind)
    {
        return (kind.isPronounPersonalSingular ||
                kind.isPronounPersonalPlural);
    }
    bool isPronounPersonalSingular(Sense kind)
    {
        with (Sense)
            return kind.of(pronounPersonalSingular,
                           pronounPersonalSingularMale,
                           pronounPersonalSingularFemale,
                           pronounPersonalSingularNeutral);
    }
    bool isPronounPersonalPlural(Sense kind)
    {
        with (Sense)
            return kind.of(pronounPersonalPlural);
    }
    bool isPronounPossessive(Sense kind)
    {
        with (Sense)
            return (kind == pronounPossessive ||
                    kind.isPronounPossessiveSingular ||
                    kind.isPronounPossessivePlural);
    }
    bool isPronounPossessiveSingular(Sense kind)
    {
        with (Sense)
            return kind.of(pronounPossessiveSingular,
                           pronounPossessiveSingularMale,
                           pronounPossessiveSingularFemale,
                           pronounPossessiveSingularNeutral);
    }
    bool isPronounPossessivePlural(Sense kind)
    {
        with (Sense)
            return kind.of(pronounPossessivePlural);
    }
    bool isPronounDemonstrative(Sense kind)
    {
        with (Sense)
            return kind.of(pronounDemonstrative);
    }
    bool isPronounPlural(Sense kind)
    {
        with (Sense)
            return (kind.isPronounPersonalPlural ||
                    kind == pronounPossessivePlural);
    }
    bool isPronounReflexive(Sense kind)
    {
        with (Sense)
            return kind.of(pronounReflexive,
                           pronounReflexiveSingular,
                           pronounReflexivePlural);
    }
    bool isPronounIndefinite(Sense kind)
    {
        with (Sense)
            return kind.of(pronounIndefinite,
                           pronounIndefiniteSingular,
                           pronounIndefinitePlural);
    }
    bool isPreposition(Sense kind)
    {
        with (Sense)
            return kind.of(preposition,
                           prepositionTime,
                           prepositionPosition,
                           prepositionPlace,
                           prepositionDirection);
    }
    bool isArticle(Sense kind)
    {
        with (Sense)
            return kind.of(article,
                           articleUndefinite,
                           articleDefinite,
                           articlePartitive);
    }
    bool isConjunction(Sense kind)
    {
        with (Sense)
            return kind.of(conjunction,
                           coordinatingConjunction,
                           subordinatingConjunction);
    }
}

bool specializes(Sense special,
                 Sense general)
    @safe @nogc pure nothrow
{
    with (Sense) {
        switch (general)
        {
            /* TODO Use static foreach over all enum members to generate all
             * relevant cases: */
            case unknown: return true;
            case noun: return special.isNoun || special.isPronoun;
            case nounNumeric: return special.isNounNumeric;
            case nounName: return special.isNounName;
            case nounAbbrevation: return special == nounAcronym;
            case verb: return special.isVerb;
            case adverb: return special.isAdverb;
            case adjective: return special.isAdjective;
            case adjectiveNominative:
            case adjectiveComparative:
            case adjectiveSuperlative:
                return special == general;
            case pronoun: return special.isPronoun;
            case pronounPersonal: return special.isPronounPersonal;
            case pronounPossessive: return special.isPronounPossessive;
            case preposition: return special.isPreposition;
            case article: return special.isArticle;
            case conjunction: return special.isConjunction;
            default: return special == general;
        }
    }
}

alias memberOf = specializes;

static immutable implies = [ `in order to` ];

unittest
{
    assert(Sense.noun.isNoun);
}

/** Subject Count. */
enum Number:ubyte { singular, plural }

/** Subject Person. */
enum Person:ubyte { first, second, third }

/** Subject Gender. */
enum Gender:ubyte {
    unknown,
    male, maskulinum = male,
    female, femininum = female,
    neutral, neutrum = neutral, // human or alive, for example: "något"G
    reale, utrum = reale // non-human/alive, for example: "någon"
}

/* Number number(string x, Sense wc) {} */
/* Person person(string x, Sense wc) {} */
/* Gender gender(string x, Sense wc) {} */

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

/** English Word Suffixes. */
static immutable wordSuffixes = [ allNounSuffixes ~ verbSuffixes ~ adjectiveSuffixes ].uniq.array;

Gender getGender(S)(S lemma, Sense kind) if (isSomeString!S)
{
    if (kind.isPronounSingularMale)
    {
        return Gender.male;
    }
    else if (kind.isPronounPersonalSingularFemale)
    {
        return Gender.female;
    }
    else if (kind.isPronounPersonalSingularNeutral)
    {
        return Gender.neutral;
    }
    else if (kind.isNoun)
    {
        return Gender.unknown;
    }
    else
    {
        return Gender.unknown;
    }
}

/** Get English Order Name of $(D n). */
string nthString(T)(T n) @safe pure
{
    string s;
    switch (n)
    {
        default: s = to!string(n) ~ `:th`; break;
        case 0: s = `zeroth`; break;
        case 1: s = `first`; break;
        case 2: s = `second`; break;
        case 3: s = `third`; break;
        case 4: s = `fourth`; break;
        case 5: s = `fifth`; break;
        case 6: s = `sixth`; break;
        case 7: s = `seventh`; break;
        case 8: s = `eighth`; break;
        case 9: s = `ninth`; break;
        case 10: s = `tenth`; break;
        case 11: s = `eleventh`; break;
        case 12: s = `twelveth`; break;
        case 13: s = `thirteenth`; break;
        case 14: s = `fourteenth`; break;
        case 15: s = `fifteenth`; break;
        case 16: s = `sixteenth`; break;
        case 17: s = `seventeenth`; break;
        case 18: s = `eighteenth`; break;
        case 19: s = `nineteenth`; break;
        case 20: s = `twentieth`; break;
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
            return word ~ `es`;
        case 'f':
            return word[0 .. $-1] ~ `ves`;
        case 'y':
            return word[0 .. $-1] ~ `ies`;
        default:
            return word ~ `s`;
    }
}

import std.typecons: tuple;

/** Irregular Adjectives.
    See also: http://www.talkenglish.com/Grammar/comparative-superlative-adjectives.aspx
*/
enum irregularAdjectivesEnglish = [tuple("good", "better", "best"),
                                   tuple("well", "better", "best"),

                                   tuple("bad", "worse", "worst"),

                                   tuple("little", "less", "least"),
                                   tuple("little", "smaller", "smallest"),
                                   tuple("much", "more", "most"),
                                   tuple("many", "more", "most"),

                                   tuple("far", "further", "furthest"),
                                   tuple("far", "farther", "farthest"),

                                   tuple("big", "larger", "largest"),
                                   tuple("old", "elder", "eldest"),
    ];

/** Return true if $(D s) is an adjective in nominative form.
    TODO Add to ConceptNet instead.
 */
bool isNominativeAdjective(S)(S s) if (isSomeString!S)
{
    import std.range: empty;
    return (irregularAdjectivesEnglish.map!(a => a[0]).array.canFind(s)); // TODO Check if s[0..$-2] is a wordnet adjective
}

/** Return true if $(D s) is an adjective in comparative form.
    TODO Add to ConceptNet instead.
 */
bool isComparativeAdjective(S)(S s) if (isSomeString!S)
{
    import std.range: empty;
    return (s.startsWith(`more `) || // TODO Check that s[5..$] is a wordnet adjective
            irregularAdjectivesEnglish.map!(a => a[1]).array.canFind(s) ||
            s.endsWith(`er`)   // TODO Check if s[0..$-2] is a wordnet adjective
        );
}

/** Return true if $(D s) is an adjective in superlative form.
    TODO Add to ConceptNet instead.
 */
bool isSuperlativeAdjective(S)(S s) if (isSomeString!S)
{
    import std.range: empty;
    return (s.startsWith(`most `) || // TODO Check that s[5..$] is a wordnet adjective
            irregularAdjectivesEnglish.map!(a => a[2]).array.canFind(s) ||
            s.endsWith(`est`)   // TODO Check if s[0..$-3] is a wordnet adjective
        );
}

unittest
{
    assert(`good`.isNominativeAdjective);
    assert(!`better`.isNominativeAdjective);
    assert(`better`.isComparativeAdjective);
    assert(!`best`.isComparativeAdjective);
    assert(`more important`.isComparativeAdjective);
    assert(`best`.isSuperlativeAdjective);
    assert(!`better`.isSuperlativeAdjective);
    assert(`most important`.isSuperlativeAdjective);
}

/** Irregular Adjectives. */
enum irregularAdjectivesGerman = [tuple("gut", "besser", "besten")
    ];

/** Return $(D s) lemmatized (normalized).
    See also: https://en.wikipedia.org/wiki/Lemmatisation
 */
S lemmatize(S)(S s) if (isSomeString!S)
{
    if      (s.of(`be`, `is`, `am`, `are`)) return `be`;
    else if (s.of(`do`, `does`))            return `do`;
    else return s;
}

import std.traits: isIntegral;

/** Convert the number $(D number) to its English textual representation.
    Opposite: toTextualIntegerMaybe
*/
string toTextualString(T)(T number, string minusName = `minus`)
    @safe pure nothrow if (isIntegral!T)
{
    string word;

    if (number == 0)
        return `zero`;

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
                    word ~= `-`;
            }
        }
        else if (number < 1_000)
        {
            auto hundreds = number / 100;
            word ~= onesPlaceWords[cast(int) hundreds] ~ ` hundred`;
            number = number % 100;
            if (number)
                word ~= ` and `;
        }
        else if (number < 1_000_000)
        {
            auto thousands = number / 1_000;
            word ~= toTextualString(thousands) ~ ` thousand`;
            number = number % 1_000;
            if (number)
                word ~= `, `;
        }
        else if (number < 1_000_000_000)
        {
            auto millions = number / 1_000_000;
            word ~= toTextualString(millions) ~ ` million`;
            number = number % 1_000_000;
            if (number)
                word ~= `, `;
        }
        else if (number < 1_000_000_000_000)
        {
            auto n = number / 1_000_000_000;
            word ~= toTextualString(n) ~ ` billion`;
            number = number % 1_000_000_000;
            if (number)
                word ~= `, `;
        }
        else if (number < 1_000_000_000_000_000)
        {
            auto n = number / 1_000_000_000_000;
            word ~= toTextualString(n) ~ ` trillion`;
            number = number % 1_000_000_000_000;
            if (number)
                word ~= `, `;
        }
        else
        {
            return to!string(number);
        }
    }

    return word;
}
alias toTextual = toTextualString;

unittest {
    assert(1.toTextualString == `one`);
    assert(5.toTextualString == `five`);
    assert(13.toTextualString == `thirteen`);
    assert(54.toTextualString == `fifty-four`);
    assert(178.toTextualString == `one hundred and seventy-eight`);
    assert(592.toTextualString == `five hundred and ninety-two`);
    assert(1_234.toTextualString == `one thousand, two hundred and thirty-four`);
    assert(10_234.toTextualString == `ten thousand, two hundred and thirty-four`);
    assert(105_234.toTextualString == `one hundred and five thousand, two hundred and thirty-four`);
    assert(71_05_234.toTextualString == `seven million, one hundred and five thousand, two hundred and thirty-four`);
    assert(3_007_105_234.toTextualString == `three billion, seven million, one hundred and five thousand, two hundred and thirty-four`);
    assert(900_003_007_105_234.toTextualString == `nine hundred trillion, three billion, seven million, one hundred and five thousand, two hundred and thirty-four`);
}

enum onesPlaceWords = [ `zero`, `one`, `two`, `three`, `four`, `five`, `six`, `seven`, `eight`, `nine` ];
enum singleWords = onesPlaceWords ~ [ `ten`, `eleven`, `twelve`, `thirteen`, `fourteen`, `fifteen`, `sixteen`, `seventeen`, `eighteen`, `nineteen` ];
enum tensPlaceWords = [ null, `ten`, `twenty`, `thirty`, `forty`, `fifty`, `sixty`, `seventy`, `eighty`, `ninety`, ];

immutable ubyte[string] onesPlaceWordsAA;
immutable ubyte[string] singleWordsAA;
immutable ubyte[string] tensPlaceWordsAA;

static this() {
    foreach (ubyte i, e; onesPlaceWords) { onesPlaceWordsAA[e] = i; }
    foreach (ubyte i, e; singleWords) { singleWordsAA[e] = i; }
    foreach (ubyte i, e; tensPlaceWords) { tensPlaceWordsAA[e] = i; }
}

/** Convert the number $(D number) to its English textual representation.
    Opposite: toTextualString.
    TODO Throw if number doesn't fit in long.
    TODO Add variant to toTextualBigIntegerMaybe.
    TODO Could this be merged with to!(T)(string) if (isInteger!T) ?
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
        import std.stdio: writeln;
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

/**
   Reuse knet translation query instead.
 */
string negationIn(Lang lang = Lang.en)
    @safe pure nothrow
{
    with (Lang)
        switch (lang)
        {
            case en: return "not";
            case sv: return "inte";
            case de: return "nicht";
            default: return "not";
        }
}
