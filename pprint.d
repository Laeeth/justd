#!/usr/bin/env rdmd-dev-module

/** Pretty Printing.
    Copyright: Per Nordlöw 2014-.
    License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
    Authors: $(WEB Per Nordlöw)
    TODO: How should std.typecons.Tuple be pretty printed?
*/
module pprint;

import std.range: isInputRange;
import std.traits: isInstanceOf, isSomeChar;
import std.stdio: stdout;
import std.conv: to;
import std.path: dirSeparator;
import std.range: map;

import arsd.terminal;

// See also: https://en.wikipedia.org/wiki/Character_entity_reference#Predefined_entities_in_XML
__gshared string[256] convLatin1ToXML;
// See also: https://en.wikipedia.org/wiki/Character_entity_reference#Character_entity_references_in_HTML
// string[256] convLatin1ToHTML;

shared static this()
{
    initTables();
}

void initTables()
{
    convLatin1ToXML['"'] = "&quot";
    convLatin1ToXML['.'] = "&amp";
    convLatin1ToXML['\''] = "&apos";
    convLatin1ToXML['<'] = "&lt";
    convLatin1ToXML['>'] = "&gt";

    convLatin1ToXML[0x22] = "&quot"; // U+0022 (34)	HTML 2.0	HTMLspecial	ISOnum	quotation mark (= APL quote)
    convLatin1ToXML[0x26] = "&amp";  // U+0026 (38)	HTML 2.0	HTMLspecial	ISOnum	ampersand
    convLatin1ToXML[0x27] = "&apos"; // U+0027 (39)	XHTML 1.0	HTMLspecial	ISOnum	apostrophe (= apostrophe-quote); see below
    convLatin1ToXML[0x60] = "&lt";   // U+003C (60)	HTML 2.0	HTMLspecial	ISOnum	less-than sign
    convLatin1ToXML[0x62] = "&gt";   // U+003E (62)	HTML 2.0	HTMLspecial	ISOnum	greater-than sign

    convLatin1ToXML[0xA0] = "&nbsp"; // nbsp	 	U+00A0 (160)	HTML 3.2	HTMLlat1	ISOnum	no-break space (= non-breaking space)[d]
    convLatin1ToXML[0xA1] = "&iexcl"; // iexcl	¡	U+00A1 (161)	HTML 3.2	HTMLlat1	ISOnum	inverted exclamation mark
    convLatin1ToXML[0xA2] = "&cent"; // cent	¢	U+00A2 (162)	HTML 3.2	HTMLlat1	ISOnum	cent sign
    convLatin1ToXML[0xA3] = "&pound"; // pound	£	U+00A3 (163)	HTML 3.2	HTMLlat1	ISOnum	pound sign
    convLatin1ToXML[0xA4] = "&curren"; // curren	¤	U+00A4 (164)	HTML 3.2	HTMLlat1	ISOnum	currency sign
    convLatin1ToXML[0xA5] = "&yen"; // yen	¥	U+00A5 (165)	HTML 3.2	HTMLlat1	ISOnum	yen sign (= yuan sign)
    convLatin1ToXML[0xA6] = "&brvbar"; // brvbar	¦	U+00A6 (166)	HTML 3.2	HTMLlat1	ISOnum	broken bar (= broken vertical bar)
    convLatin1ToXML[0xA7] = "&sect"; // sect	§	U+00A7 (167)	HTML 3.2	HTMLlat1	ISOnum	section sign
    convLatin1ToXML[0xA8] = "&uml"; // uml	¨	U+00A8 (168)	HTML 3.2	HTMLlat1	ISOdia	diaeresis (= spacing diaeresis); see Germanic umlaut
    convLatin1ToXML[0xA9] = "&copy"; // copy	©	U+00A9 (169)	HTML 3.2	HTMLlat1	ISOnum	copyright symbol
    convLatin1ToXML[0xAA] = "&ordf"; // ordf	ª	U+00AA (170)	HTML 3.2	HTMLlat1	ISOnum	feminine ordinal indicator
    convLatin1ToXML[0xAB] = "&laquo"; // laquo	«	U+00AB (171)	HTML 3.2	HTMLlat1	ISOnum	left-pointing double angle quotation mark (= left pointing guillemet)
    convLatin1ToXML[0xAC] = "&not"; // not	¬	U+00AC (172)	HTML 3.2	HTMLlat1	ISOnum	not sign
    convLatin1ToXML[0xAD] = "&shy"; // shy	 	U+00AD (173)	HTML 3.2	HTMLlat1	ISOnum	soft hyphen (= discretionary hyphen)
    convLatin1ToXML[0xAE] = "&reg"; // reg	®	U+00AE (174)	HTML 3.2	HTMLlat1	ISOnum	registered sign ( = registered trademark symbol)
    convLatin1ToXML[0xAF] = "&macr"; // macr	¯	U+00AF (175)	HTML 3.2	HTMLlat1	ISOdia	macron (= spacing macron = overline = APL overbar)
    convLatin1ToXML[0xB0] = "&deg"; // deg	°	U+00B0 (176)	HTML 3.2	HTMLlat1	ISOnum	degree symbol
    convLatin1ToXML[0xB1] = "&plusmn"; // plusmn	±	U+00B1 (177)	HTML 3.2	HTMLlat1	ISOnum	plus-minus sign (= plus-or-minus sign)
    convLatin1ToXML[0xB2] = "&sup2"; // sup2	²	U+00B2 (178)	HTML 3.2	HTMLlat1	ISOnum	superscript two (= superscript digit two = squared)
    convLatin1ToXML[0xB3] = "&sup3"; // sup3	³	U+00B3 (179)	HTML 3.2	HTMLlat1	ISOnum	superscript three (= superscript digit three = cubed)
    convLatin1ToXML[0xB4] = "&acute"; // acute	´	U+00B4 (180)	HTML 3.2	HTMLlat1	ISOdia	acute accent (= spacing acute)
    convLatin1ToXML[0xB5] = "&micro"; // micro	µ	U+00B5 (181)	HTML 3.2	HTMLlat1	ISOnum	micro sign
    convLatin1ToXML[0xB6] = "&para"; // para	¶	U+00B6 (182)	HTML 3.2	HTMLlat1	ISOnum	pilcrow sign ( = paragraph sign)
    convLatin1ToXML[0xB7] = "&middot"; // middot	·	U+00B7 (183)	HTML 3.2	HTMLlat1	ISOnum	middle dot (= Georgian comma = Greek middle dot)
    convLatin1ToXML[0xB8] = "&cedil"; // cedil	¸	U+00B8 (184)	HTML 3.2	HTMLlat1	ISOdia	cedilla (= spacing cedilla)
    convLatin1ToXML[0xB9] = "&sup1"; // sup1	¹	U+00B9 (185)	HTML 3.2	HTMLlat1	ISOnum	superscript one (= superscript digit one)
    convLatin1ToXML[0xBA] = "&ordm"; // ordm	º	U+00BA (186)	HTML 3.2	HTMLlat1	ISOnum	masculine ordinal indicator
    convLatin1ToXML[0xBB] = "&raquo"; // raquo	»	U+00BB (187)	HTML 3.2	HTMLlat1	ISOnum	right-pointing double angle quotation mark (= right pointing guillemet)
    convLatin1ToXML[0xBC] = "&frac14"; // frac14	¼	U+00BC (188)	HTML 3.2	HTMLlat1	ISOnum	vulgar fraction one quarter (= fraction one quarter)
    convLatin1ToXML[0xBD] = "&frac12"; // frac12	½	U+00BD (189)	HTML 3.2	HTMLlat1	ISOnum	vulgar fraction one half (= fraction one half)
    convLatin1ToXML[0xBE] = "&frac34"; // frac34	¾	U+00BE (190)	HTML 3.2	HTMLlat1	ISOnum	vulgar fraction three quarters (= fraction three quarters)
    convLatin1ToXML[0xBF] = "&iquest"; // iquest	¿	U+00BF (191)	HTML 3.2	HTMLlat1	ISOnum	inverted question mark (= turned question mark)
    convLatin1ToXML[0xC0] = "&Agrave"; // Agrave	À	U+00C0 (192)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter A with grave accent (= Latin capital letter A grave)
    convLatin1ToXML[0xC1] = "&Aacute"; // Aacute	Á	U+00C1 (193)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter A with acute accent
    convLatin1ToXML[0xC2] = "&Acirc"; // Acirc	Â	U+00C2 (194)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter A with circumflex
    convLatin1ToXML[0xC3] = "&Atilde"; // Atilde	Ã	U+00C3 (195)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter A with tilde
    convLatin1ToXML[0xC4] = "&Auml"; // Auml	Ä	U+00C4 (196)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter A with diaeresis
    convLatin1ToXML[0xC5] = "&Aring"; // Aring	Å	U+00C5 (197)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter A with ring above (= Latin capital letter A ring)
    convLatin1ToXML[0xC6] = "&AElig"; // AElig	Æ	U+00C6 (198)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter AE (= Latin capital ligature AE)
    convLatin1ToXML[0xC7] = "&Ccedil"; // Ccedil	Ç	U+00C7 (199)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter C with cedilla
    convLatin1ToXML[0xC8] = "&Egrave"; // Egrave	È	U+00C8 (200)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter E with grave accent
    convLatin1ToXML[0xC9] = "&Eacute"; // Eacute	É	U+00C9 (201)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter E with acute accent
    convLatin1ToXML[0xCA] = "&Ecirc"; // Ecirc	Ê	U+00CA (202)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter E with circumflex
    convLatin1ToXML[0xCB] = "&Euml"; // Euml	Ë	U+00CB (203)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter E with diaeresis
    convLatin1ToXML[0xCC] = "&Igrave"; // Igrave	Ì	U+00CC (204)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter I with grave accent
    convLatin1ToXML[0xCD] = "&Iacute"; // Iacute	Í	U+00CD (205)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter I with acute accent
    convLatin1ToXML[0xCE] = "&Icirc"; // Icirc	Î	U+00CE (206)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter I with circumflex
    convLatin1ToXML[0xCF] = "&Iuml"; // Iuml	Ï	U+00CF (207)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter I with diaeresis
    convLatin1ToXML[0xD0] = "&ETH"; // ETH	Ð	U+00D0 (208)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter Eth
    convLatin1ToXML[0xD1] = "&Ntilde"; // Ntilde	Ñ	U+00D1 (209)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter N with tilde
    convLatin1ToXML[0xD2] = "&Ograve"; // Ograve	Ò	U+00D2 (210)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter O with grave accent
    convLatin1ToXML[0xD3] = "&Oacute"; // Oacute	Ó	U+00D3 (211)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter O with acute accent
    convLatin1ToXML[0xD4] = "&Ocirc"; // Ocirc	Ô	U+00D4 (212)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter O with circumflex
    convLatin1ToXML[0xD5] = "&Otilde"; // Otilde	Õ	U+00D5 (213)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter O with tilde
    convLatin1ToXML[0xD6] = "&Ouml"; // Ouml	Ö	U+00D6 (214)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter O with diaeresis
    convLatin1ToXML[0xD7] = "&times"; // times	×	U+00D7 (215)	HTML 3.2	HTMLlat1	ISOnum	multiplication sign
    convLatin1ToXML[0xD8] = "&Oslash"; // Oslash	Ø	U+00D8 (216)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter O with stroke (= Latin capital letter O slash)
    convLatin1ToXML[0xD9] = "&Ugrave"; // Ugrave	Ù	U+00D9 (217)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter U with grave accent
    convLatin1ToXML[0xDA] = "&Uacute"; // Uacute	Ú	U+00DA (218)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter U with acute accent
    convLatin1ToXML[0xDB] = "&Ucirc"; // Ucirc	Û	U+00DB (219)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter U with circumflex
    convLatin1ToXML[0xDC] = "&Uuml"; // Uuml	Ü	U+00DC (220)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter U with diaeresis
    convLatin1ToXML[0xDD] = "&Yacute"; // Yacute	Ý	U+00DD (221)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter Y with acute accent
    convLatin1ToXML[0xDE] = "&THORN"; // THORN	Þ	U+00DE (222)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter THORN
    convLatin1ToXML[0xDF] = "&szlig"; // szlig	ß	U+00DF (223)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter sharp s (= ess-zed); see German Eszett
    convLatin1ToXML[0xE0] = "&agrave"; // agrave	à	U+00E0 (224)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter a with grave accent
    convLatin1ToXML[0xE1] = "&aacute"; // aacute	á	U+00E1 (225)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter a with acute accent
    convLatin1ToXML[0xE2] = "&acirc"; // acirc	â	U+00E2 (226)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter a with circumflex
    convLatin1ToXML[0xE3] = "&atilde"; // atilde	ã	U+00E3 (227)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter a with tilde
    convLatin1ToXML[0xE4] = "&auml"; // auml	ä	U+00E4 (228)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter a with diaeresis
    convLatin1ToXML[0xE5] = "&aring"; // aring	å	U+00E5 (229)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter a with ring above
    convLatin1ToXML[0xE6] = "&aelig"; // aelig	æ	U+00E6 (230)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter ae (= Latin small ligature ae)
    convLatin1ToXML[0xE7] = "&ccedil"; // ccedil	ç	U+00E7 (231)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter c with cedilla
    convLatin1ToXML[0xE8] = "&egrave"; // egrave	è	U+00E8 (232)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter e with grave accent
    convLatin1ToXML[0xE9] = "&eacute"; // eacute	é	U+00E9 (233)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter e with acute accent
    convLatin1ToXML[0xEA] = "&ecirc"; // ecirc	ê	U+00EA (234)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter e with circumflex
    convLatin1ToXML[0xEB] = "&euml"; // euml	ë	U+00EB (235)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter e with diaeresis
    convLatin1ToXML[0xEC] = "&igrave"; // igrave	ì	U+00EC (236)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter i with grave accent
    convLatin1ToXML[0xED] = "&iacute"; // iacute	í	U+00ED (237)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter i with acute accent
    convLatin1ToXML[0xEE] = "&icirc"; // icirc	î	U+00EE (238)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter i with circumflex
    convLatin1ToXML[0xEF] = "&iuml"; // iuml	ï	U+00EF (239)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter i with diaeresis
    convLatin1ToXML[0xF0] = "&eth"; // eth	ð	U+00F0 (240)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter eth
    convLatin1ToXML[0xF1] = "&ntilde"; // ntilde	ñ	U+00F1 (241)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter n with tilde
    convLatin1ToXML[0xF2] = "&ograve"; // ograve	ò	U+00F2 (242)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter o with grave accent
    convLatin1ToXML[0xF3] = "&oacute"; // oacute	ó	U+00F3 (243)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter o with acute accent
    convLatin1ToXML[0xF4] = "&ocirc"; // ocirc	ô	U+00F4 (244)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter o with circumflex
    convLatin1ToXML[0xF5] = "&otilde"; // otilde	õ	U+00F5 (245)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter o with tilde
    convLatin1ToXML[0xF6] = "&ouml"; // ouml	ö	U+00F6 (246)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter o with diaeresis
    convLatin1ToXML[0xF7] = "&divide"; // divide	÷	U+00F7 (247)	HTML 3.2	HTMLlat1	ISOnum	division sign (= obelus)
    convLatin1ToXML[0xF8] = "&oslash"; // oslash	ø	U+00F8 (248)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter o with stroke (= Latin small letter o slash)
    convLatin1ToXML[0xF9] = "&ugrave"; // ugrave	ù	U+00F9 (249)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter u with grave accent
    convLatin1ToXML[0xFA] = "&uacute"; // uacute	ú	U+00FA (250)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter u with acute accent
    convLatin1ToXML[0xFB] = "&ucirc"; // ucirc	û	U+00FB (251)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter u with circumflex
    convLatin1ToXML[0xFC] = "&uuml"; // uuml	ü	U+00FC (252)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter u with diaeresis
    convLatin1ToXML[0xFD] = "&yacute"; // yacute	ý	U+00FD (253)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter y with acute accent
    convLatin1ToXML[0xFE] = "&thorn"; // thorn	þ	U+00FE (254)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter thorn
    convLatin1ToXML[0xFF] = "&yuml"; // yuml	ÿ	U+00FF (255)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter y with diaeresis
}

string encodeHTML(Char)(Char c) @safe pure if (isSomeChar!Char)
{
    if      (c == '&')  return "&amp;"; // ampersand
    else if (c == '<')  return "&lt;"; // less than
    else if (c == '>')  return "&gt;"; // greater than
    else if (c == '\"') return "&quot;"; // double quote
//		else if (c == '\'')
//			return ("&#39;"); // if you are in an attribute, it might be important to encode for the same reason as double quotes
    // FIXME: should I encode apostrophes too? as &#39;... I could also do space but if your html is so bad that it doesn't
    // quote attributes at all, maybe you deserve the xss. Encoding spaces will make everything really ugly so meh
    // idk about apostrophes though. Might be worth it, might not.
    else if (0 < c && c < 128)
        return to!string(cast(char)c);
    else
        return "&#" ~ to!string(cast(int)c) ~ ";";
}

static if (__VERSION__ >= 2066L)
{
    /** Copied from arsd.dom */
    auto encodeHTML(string data) @safe pure
    {
        import std.utf: byDchar;
        import std.algorithm: joiner;
        return data.byDchar.map!encodeHTML.joiner("");
        //pragma(msg, typeof(ret));
    }
}
else
{
    import std.array: appender, Appender;

    /** Copied from arsd.dom */
    string encodeHTML(string data,
                      Appender!string os = appender!string()) pure
    {
        bool skip = true;
        // NOTE: this extra loop may be deprecated by byCodeunit, byChar, byWchar
        // and byDchar available in DMD 2.066
        foreach (char c; data)
        {
            // non ASCII chars are always higher than 127 in utf8;
            // we'd better go to the full decoder if we see it.
            if (c == '<' ||
                c == '>' ||
                c == '"' ||
                c == '&' ||
                cast(uint) c > 127)
            {
                skip = false; // there's actual work to be done
                break;
            }
        }

        if (skip)
        {
            os.put(data);
            return data;
        }

        auto start = os.data.length;

        os.reserve(data.length + 64); // grab some extra space for the encoded entities

        foreach (dchar ch; data)
        {
            os.put(ch.encodeHTML);
        }

        return os.data[start .. $];
    }
}

unittest
{
    import dbg;
    dln(`<!-- --><script>/* */</script>`.encodeHTML);
}

/* TODO: These deps needs to be removed somehow */
import digest_ex: Digest;
import csunits: Bytes;
import fs: FKind, isSymlink, isDir;
import notnull: NotNull;

struct Face(Color)
{
    this(Color fg, Color bg, bool bright, bool italic, string[] tagsHTML)
    {
        this.fg = fg;
        this.bg = bg;
        this.bright = bright;
        this.tagsHTML = tagsHTML;
    }
    string[] tagsHTML;
    Color fg;
    Color bg;
    bool bright;
    bool italic;
}

Face!Color face(Color)(Color fg, Color bg,
                       bool bright = false,
                       bool italic = false,
                       string[] tagsHTML = [])
{
    return Face!Color(fg, bg, bright, italic, tagsHTML);
}

// Faces (Font/Color)
enum stdFace = face(Color.white, Color.black);
enum pathFace = face(Color.green, Color.black, true);

enum dirFace = face(Color.blue, Color.black, true);
enum fileFace = face(Color.magenta, Color.black, true);
enum baseNameFace = fileFace;
enum specialFileFace = face(Color.red, Color.black, true);
enum regFileFace = face(Color.white, Color.black, true, false, ["b"]);
enum symlinkFace = face(Color.cyan, Color.black, true, true, ["i"]);
enum symlinkBrokenFace = face(Color.red, Color.black, true, true, ["i"]);

enum contextFace = face(Color.green, Color.black);

enum timeFace = face(Color.magenta, Color.black);
enum digestFace = face(Color.yellow, Color.black);
enum bytesFace = face(Color.yellow, Color.black);

enum infoFace = face(Color.white, Color.black, true);
enum warnFace = face(Color.yellow, Color.black);
enum kindFace = warnFace;
enum errorFace = face(Color.red, Color.black);

enum titleFace = face(Color.white, Color.black, false, false, ["title"]);
enum h1Face = face(Color.white, Color.black, false, false, ["h1"]);

// Support these as immutable

/** Key (Hit) Face Palette. */
enum ctxFaces = [face(Color.red, Color.black),
                 face(Color.green, Color.black),
                 face(Color.blue, Color.black),
                 face(Color.cyan, Color.black),
                 face(Color.magenta, Color.black),
                 face(Color.yellow, Color.black),
    ];
/** Key (Hit) Faces. */
enum keyFaces = ctxFaces.map!(a => face(a.fg, a.bg, true));

void setFace(Term, Face)(ref Term term, Face face, bool colorFlag) @trusted
{
    if (colorFlag)
        term.color(face.fg | (face.bright ? Bright : 0) ,
                   face.bg);
}

@safe pure nothrow @nogc
{
    /** Printed as Words. */
    struct AsWords(T...) { T args; } auto asWords(T...)(T args) { return AsWords!T(args); }
    /** Printed as Comma-Separated List. */
    struct AsCSL(T...) { T args; } auto asCSL(T...)(T args) { return AsCSL!T(args); }

    /** Printed as Path. */
    struct AsPath(T) { T arg; } auto asPath(T)(T arg) { return AsPath!T(arg); }
    /** Printed as Name. */
    struct AsName(T) { T arg; } auto asName(T)(T arg) { return AsName!T(arg); }

    /* TODO: Turn these into an enum for more efficient parsing. */
    /** Printed as Italic/Slanted. */
    struct InIt(T...) { T args; } auto inIt(T...)(T args) { return InIt!T(args); }
    /** Bold. */
    struct InBold(T...) { T args; } auto inBold(T...)(T args) { return InBold!T(args); }
    /** Code. */
    struct AsCode(T...) { T args; } auto asCode(T...)(T args) { return AsCode!T(args); }
    /** Emphasized. */
    struct AsEm(T...) { T args; } auto asEm(T...)(T args) { return AsEm!T(args); }
    /** Strong. */
    struct AsStrong(T...) { T args; } auto asStrong(T...)(T args) { return AsStrong!T(args); }
    /** Preformatted. */
    struct AsPre(T...) { T args; } auto asPre(T...)(T args) { return AsPre!T(args); }

    /** Scan Hit with Color index $(D ix)). */
    struct AsHit(T...) { uint ix; T args; } auto asHit(T)(uint ix, T args) { return AsHit!T(ix, args); }

    /** Scan Hit Context with Color index $(D ix)). */
    struct AsCtx(T...) { uint ix; T args; } auto asCtx(T)(uint ix, T args) { return AsCtx!T(ix, args); }

    /** Header. */
    struct Header(uint Level, T...) { T args; enum level = Level; }
    auto asH(uint Level, T...)(T args) { return Header!(Level, T)(args); }

    /** Unordered List.
        TODO: Should asUList, asOList autowrap args as AsItems when needed?
    */
    struct AsUList(T...) { T args; } auto asUList(T...)(T args) { return AsUList!T(args); }
    /** Ordered List. */
    struct AsOList(T...) { T args; } auto asOList(T...)(T args) { return AsOList!T(args); }

    /** Table.
        TODO: Should asTable autowrap args AsRows when needed?
    */
    struct AsTable(T...) {
        string border;
        T args;
    }
    auto asTable(T...)(T args) {
        return AsTable!T("\"1\"", args);
    }

    /** Table Row. */
    struct AsRow(T...) { T args; } auto asRow(T...)(T args) { return AsRow!T(args); }
    /** Table Cell. */
    struct AsCell(T...) { T args; } auto asCell(T...)(T args) { return AsCell!T(args); }

    /** Row/Column/... Span. */
    struct Span(T...) { uint _span; T args; }
    auto span(T...)(uint span, T args) { return span!T(span, args); }

    /** Table Heading. */
    struct AsTHeading(T...) { T args; } auto asTHeading(T...)(T args) { return AsTHeading!T(args); }

    /* /\** Unordered List Beginner. *\/ */
    /* struct UListBegin(T...) { T args; } */
    /* auto uListBegin(T...)(T args) { return UListBegin!T(args); } */
    /* /\** Unordered List Ender. *\/ */
    /* struct UListEnd(T...) { T args; } */
    /* auto uListEnd(T...)(T args) { return UListEnd!T(args); } */
    /* /\** Ordered List Beginner. *\/ */
    /* struct OListBegin(T...) { T args; } */
    /* auto oListBegin(T...)(T args) { return OListBegin!T(args); } */
    /* /\** Ordered List Ender. *\/ */
    /* struct OListEnd(T...) { T args; } */
    /* auto oListEnd(T...)(T args) { return OListEnd!T(args); } */

    /** List Item. */
    struct AsItem(T...) { T args; } auto asItem(T...)(T args) { return AsItem!T(args); }

    const string lbr(bool useHTML) { return (useHTML ? "<br>" : ""); } // line break
}

/** Put $(D arg) to $(D viz) without any conversion nor coloring. */
void ppRaw(Arg)(Viz viz,
                Arg arg) @trusted
{
    if (viz.outFile == stdout)
        (*viz.term).write(arg);
    else
        viz.outFile.write(arg);
}

/** Put $(D arg) to $(D viz) possibly with conversion. */
void ppPut(Arg)(Viz viz,
                Arg arg) @trusted
{
    if (viz.outFile == stdout)
    {
        (*viz.term).write(arg);
    }
    else
    {
        if (viz.form == VizForm.html)
        {
            /* import dbg:dln; */
            /* dln(arg.encodeHTML); */
            viz.outFile.write(arg.encodeHTML);
        }
        else
            viz.outFile.write(arg);
    }
}

/** Put $(D arg) to $(D viz) possibly with conversion. */
void ppPut(Arg)(Viz viz,
                Face!Color face,
                Arg arg) @trusted
{
    (*viz.term).setFace(face, viz.colorFlag);
    viz.ppPut(arg);
}

/** Fazed (Rich) Text. */
struct Fazed(T)
{
    T text;
    const Face!Color face;
    string toString() const @property @trusted pure nothrow { return to!string(text); }
}
auto faze(T)(T text, in Face!Color face = stdFace) @safe pure nothrow
{
    return Fazed!T(text, face);
}

auto getFace(Arg)(in Arg arg) @safe pure nothrow
{
    // pick face
    static if (__traits(hasMember, arg, "face"))
    {
        return arg.face;
    }
    else static if (isInstanceOf!(Digest, Arg)) // instead of is(Unqual!(Arg) == SHA1Digest)
    {
        return digestFace;
    }
    else static if (isInstanceOf!(Bytes, Arg))
    {
        return bytesFace;
    }
    else static if (isInstanceOf!(AsHit, Arg))
    {
        return keyFaces.cycle[arg.ix];
    }
    else static if (isInstanceOf!(AsCtx, Arg))
    {
        return ctxFaces.cycle[arg.ix];
    }
    else static if (isInstanceOf!(FKind, Arg) ||
                    isInstanceOf!(NotNull!FKind, Arg))
    {
        return kindFace;
    }
    else
    {
        return stdFace;
    }
}

/** Pretty-Print Argument $(D arg) to Terminal $(D term). */
void pp1(Arg)(Viz viz, int depth,
              Arg arg) @trusted
{
    static if (isInputRange!Arg)
    {
        foreach (subArg; arg)
        {
            viz.pp1(depth + 1, subArg);
        }
    }
    else static if (isInstanceOf!(AsWords, Arg))
    {
        foreach (ix, subArg; arg.args)
        {
            static if (ix >= 1)
                viz.pp1(depth + 1, " "); // separator
            viz.pp1(depth + 1, subArg);
        }
    }
    else static if (isInstanceOf!(AsCSL, Arg))
    {
        foreach (ix, subArg; arg.args)
        {
            static if (ix >= 1)
                viz.pp1(depth + 1, ","); // separator
            static if (isInputRange!(typeof(subArg)))
            {
                foreach (subsubArg; subArg)
                {
                    viz.ppN(subsubArg, ",");
                }
            }
        }
    }
    else static if (isInstanceOf!(InBold, Arg))
    {
        if (viz.form == VizForm.html) { viz.ppRaw("<b>"); }
        viz.ppN(arg.args);
        if (viz.form == VizForm.html) { viz.ppRaw("</b>"); }
    }
    else static if (isInstanceOf!(InIt, Arg))
    {
        if (viz.form == VizForm.html) { viz.ppRaw("<i>"); }
        viz.ppN(arg.args);
        if (viz.form == VizForm.html) { viz.ppRaw("</i>"); }
    }
    else static if (isInstanceOf!(AsCode, Arg))
    {
        if (viz.form == VizForm.html) { viz.ppRaw("<code>"); }
        viz.ppN(arg.args);
        if (viz.form == VizForm.html) { viz.ppRaw("</code>"); }
    }
    else static if (isInstanceOf!(AsEm, Arg))
    {
        if (viz.form == VizForm.html) { viz.ppRaw("<em>"); }
        viz.ppN(arg.args);
        if (viz.form == VizForm.html) { viz.ppRaw("</em>"); }
    }
    else static if (isInstanceOf!(AsStrong, Arg))
    {
        if (viz.form == VizForm.html) { viz.ppRaw("<strong>"); }
        viz.ppN(arg.args);
        if (viz.form == VizForm.html) { viz.ppRaw("</strong>"); }
    }
    else static if (isInstanceOf!(Header, Arg))
    {
        if (viz.form == VizForm.html) {
            const level_ = to!string(arg.level);
            viz.ppRaw("<h" ~ level_ ~ ">");
            viz.ppN(arg.args);
            viz.ppRaw("</h" ~ level_ ~ ">\n");
        }
        else if (viz.form == VizForm.textAsciiDoc ||
                 viz.form == VizForm.textAsciiDocUTF8)
        {
            string tag;
            foreach (ix; 0..arg.level)
            {
                tag ~= "=";
            }
            // TODO: Why doesn't this work?: const tag = "=".repeat(arg.level).joiner("");
            viz.ppN("\n", tag, " ", arg.args, " ", tag, "\n");
        }
    }
    else static if (isInstanceOf!(AsUList, Arg))
    {
        if (viz.form == VizForm.html) { viz.ppRaw("<ul>\n"); }
        else if (viz.form == VizForm.latex) { viz.ppRaw("\\begin{enumerate}\n"); }
        viz.ppN(arg.args);
        if (viz.form == VizForm.html) { viz.ppRaw("</ul>\n"); }
        else if (viz.form == VizForm.latex) { viz.ppRaw("\\end{enumerate}\n"); }
    }
    else static if (isInstanceOf!(AsOList, Arg))
    {
        if (viz.form == VizForm.html) { viz.ppRaw("<ol>\n"); }
        else if (viz.form == VizForm.latex) { viz.ppRaw("\\begin{itemize}\n"); }
        viz.ppN(arg.args);
        if (viz.form == VizForm.html) { viz.ppRaw("</ol>\n"); }
        else if (viz.form == VizForm.latex) { viz.ppRaw("\\end{itemize}\n"); }
    }
    else static if (isInstanceOf!(AsTable, Arg))
    {
        if (viz.form == VizForm.html) {
            const border = (arg.border ? " border=" ~ arg.border : "");
            viz.ppRaw("<table" ~ border ~ ">\n");
        }
        else if (viz.form == VizForm.latex) { viz.ppRaw("\\begin{tabular}\n"); }
        viz.ppN(arg.args);
        if (viz.form == VizForm.html) { viz.ppRaw("</table>\n"); }
        else if (viz.form == VizForm.latex) { viz.ppRaw("\\end{tabular}\n"); }
    }
    else static if (isInstanceOf!(AsRow, Arg))
    {
        string spanArg;
        static if (arg.args.length == 1 &&
                   isInstanceOf!(Span, typeof(arg.args[0])))
        {
            spanArg ~= ` rowspan="` ~ to!string(arg._span) ~ `"`;
        }
        if (viz.form == VizForm.html) { viz.ppRaw(`<tr` ~ spanArg ~ `>`); }
        viz.ppN(arg.args);
        if (viz.form == VizForm.html) { viz.ppRaw("</tr>\n"); }
    }
    else static if (isInstanceOf!(AsCell, Arg))
    {
        string spanArg;
        static if (arg.args.length == 1 &&
                   isInstanceOf!(Span, typeof(arg.args[0])))
        {
            spanArg ~= ` colspan="` ~ to!string(arg._span) ~ `"`;
        }
        if (viz.form == VizForm.html) { viz.ppRaw(`<td` ~ spanArg ~ `>`); }
        viz.ppN(arg.args);
        if (viz.form == VizForm.html) { viz.ppRaw("</td>\n"); }
    }
    else static if (isInstanceOf!(AsTHeading, Arg))
    {
        if (viz.form == VizForm.html) { viz.ppRaw("<th>\n"); }
        viz.ppN(arg.args);
        if (viz.form == VizForm.html) { viz.ppRaw("</th>\n"); }
    }
    else static if (isInstanceOf!(AsItem, Arg))
    {
        if (viz.form == VizForm.html) { viz.ppRaw("<li>"); }
        else if (viz.form == VizForm.textAsciiDoc) { viz.ppRaw(" - "); } // if inside ordered list use . instead of -
        else if (viz.form == VizForm.latex) { viz.ppRaw("\\item "); }
        else if (viz.form == VizForm.textAsciiDocUTF8) { viz.ppRaw(" • "); }
        viz.ppN(arg.args);
        if (viz.form == VizForm.html) { viz.ppRaw("</li>\n"); }
        else if (viz.form == VizForm.latex) { viz.ppRaw("\n"); }
        else if (viz.form == VizForm.textAsciiDoc ||
                 viz.form == VizForm.textAsciiDocUTF8) { viz.ppRaw("\n"); }
    }
    else static if (isInstanceOf!(AsPath, Arg))
    {
        auto vizArg = viz;
        vizArg.treeFlag = false;

        import std.traits: isSomeString;
        enum isString = isSomeString!(typeof(arg.arg));

        static if (isString)
            if (viz.form == VizForm.html)
            {
                viz.ppRaw("<a href=\"file://" ~ arg.arg ~ "\">");
            }

        pp1(vizArg, depth + 1, arg.arg);

        static if (isString)
            if (viz.form == VizForm.html) {
                viz.ppRaw("</a>");
            }
    }
    else static if (isInstanceOf!(AsName, Arg))
    {
        auto vizArg = viz;
        vizArg.treeFlag = true;
        pp1(term, vizArg, depth + 1, arg.arg);
    }
    else static if (isInstanceOf!(AsHit, Arg))
    {
        const ixs = to!string(arg.ix);
        if (viz.form == VizForm.html) { viz.ppRaw("<hit" ~ ixs ~ ">"); }
        viz.pp1(depth + 1, arg.args);
        if (viz.form == VizForm.html) { viz.ppRaw("</hit" ~ ixs ~ ">"); }
    }
    else static if (isInstanceOf!(AsCtx, Arg))
    {
        const ixs = to!string(arg.ix);
        if (viz.form == VizForm.html) { viz.ppRaw("<hit_context>"); }
        viz.pp1(depth + 1, arg.args);
        if (viz.form == VizForm.html) { viz.ppRaw("</hit_context>"); }
    }
    else static if (__traits(hasMember, arg, "parent")) // TODO: Use isFile = File or NonNull!File
    {
        if (viz.form == VizForm.html) {
            viz.ppRaw("<a href=\"file://");
            viz.ppPut(arg.path);
            viz.ppRaw("\">");
        }

        if (!viz.treeFlag)
        {
            // write parent path
            foreach (parent; arg.parents)
            {
                viz.ppPut(dirSeparator);
                if (viz.form == VizForm.html) { viz.ppRaw("<b>"); }
                viz.ppPut(dirFace, parent.name);
                if (viz.form == VizForm.html) { viz.ppRaw("</b>"); }
            }
            viz.ppPut(dirSeparator);
        }

        // write name
        static if (__traits(hasMember, arg, "isRoot")) // TODO: Use isDir = Dir or NonNull!Dir
        {
            immutable name = arg.isRoot ? dirSeparator : arg.name ~ dirSeparator;
        }
        else
        {
            immutable name = arg.name;
        }

        if (viz.form == VizForm.html)
        {
            static      if (isSymlink!Arg) { viz.ppRaw("<i>"); }
            else static if (isDir!Arg) { viz.ppRaw("<b>"); }
        }

        viz.ppPut(arg.getFace(), name);

        if (viz.form == VizForm.html)
        {
            static      if (isSymlink!Arg) { viz.ppRaw("</i>"); }
            else static if (isDir!Arg) { viz.ppRaw("</b>"); }
        }

        if (viz.form == VizForm.html) { viz.ppRaw("</a>"); }
    }
    else
    {
        // pick path
        static if (__traits(hasMember, arg, "path"))
        {
            pragma(msg, "Member arg has a path property!");
            const arg_string = arg.path;
        }
        else
        {
            const arg_string = to!string(arg);
        }

        static if (__traits(hasMember, arg, "face") &&
                   __traits(hasMember, arg.face, "tagsHTML")) {
            if (viz.form == VizForm.html)
            {
                foreach (tag; arg.face.tagsHTML)
                {
                    viz.outFile.write("<", tag, ">");
                }
            }
        }

        // write
        (*viz.term).setFace(arg.getFace(), viz.colorFlag);
        if (viz.outFile == stdout)
        {
            (*viz.term).write(arg_string);
        }
        else
        {
            import dbg: dln;
            /* dln(arg_string); */
            viz.ppPut(arg.getFace(), arg_string);
        }

        static if (__traits(hasMember, arg, "face") &&
                   __traits(hasMember, arg.face, "tagsHTML")) {
            if (viz.form == VizForm.html)
            {
                foreach (tag; arg.face.tagsHTML)
                {
                    viz.outFile.write("</", tag, ">");
                }
            }
        }
    }
}

/** Pretty-Print Arguments $(D args) to Terminal $(D term). */
void ppN(Args...)(Viz viz,
                     Args args) @trusted
{
    foreach (arg; args)
    {
        viz.pp1(0, arg);
    }
}

/** Pretty-Print Arguments $(D args) to Terminal $(D term) without Line Termination. */
void pp(Args...)(Viz viz,
                 Args args) @trusted
{
    viz.ppN(args);
    if (viz.outFile == stdout)
    {
        (*viz.term).flush();
    }
}

/** Visual Form(at). */
enum VizForm { textAsciiDoc,
               textAsciiDocUTF8,
               html,
               latex }

/** Visual Backend. */
struct Viz
{
    import std.stdio: ioFile = File;
    ioFile outFile;
    bool treeFlag;
    VizForm form;
    bool colorFlag;

    import arsd.terminal: Terminal;
    Terminal* term;
}

/** Pretty-Print Arguments $(D args) including final line termination. */
void ppln(Args...)(Viz viz, Args args) @trusted
{
    viz.ppN(args);
    if (viz.outFile == stdout)
    {
        (*viz.term).writeln(lbr(viz.form == VizForm.html));
        (*viz.term).flush();
    }
    else
    {
        viz.outFile.writeln(lbr(viz.form == VizForm.html));
    }
}

/** Pretty-Print Arguments $(D args) each including a final line termination. */
void pplns(Args...)(Viz viz, Args args) @trusted
{
    foreach (arg; args)
    {
        viz.ppln(args);
    }
}

/** Print End of Line to Terminal $(D term). */
void ppendl(Viz viz) @trusted
{
    return viz.ppln();
}
