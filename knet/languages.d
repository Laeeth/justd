module knet.languages;

import std.conv: to;
import std.traits: isSomeString;

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

    /** International Phonetic Alphabet (IPA)
        https://en.wikipedia.org/wiki/International_Phonetic_Alphabet */
    ipa,

    // Programming Languages.
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
    lastFormal = modelica,

    // Academic Languages
    math,                ///< "Mathematics is the only truly universal language"
    firstAcademic = math,
    physics,
    lastAcademic = physics,
}

/** Return true if $(D lang) is case-sensitive. */
bool hasCase(Lang lang) @safe pure @nogc nothrow
{
    import predicates: of;
    with (Lang) return lang.of(bg, ada);
}
alias isCaseSensitive = hasCase;

/** Return true if $(D lang) is a formal (computer) language. */
bool isFormal(Lang lang) @safe pure @nogc nothrow
{
    with (Lang) return (lang >= firstFormal &&
                        lang <= lastFormal);
}
alias forMachines = isFormal;
alias isProgrammingLanguage = isFormal;

/** Return true if $(D lang) is an academic language. */
bool isAcademic(Lang lang) @safe pure @nogc nothrow
{
    with (Lang) return (lang >= firstAcademic &&
                        lang <= lastAcademic);
}

/** TODO Remove when __traits(documentation is merged */
string toHuman(Lang lang) @safe pure @nogc nothrow
{
    switch (lang) with (Lang)
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

        case ipa: return `International Phonetic Alphabet`;

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
        default: return `??`;
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
