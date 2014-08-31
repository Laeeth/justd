#!/usr/bin/env rdmd-dev-module

/** Pretty Printing to AsciiDoc, HTML, LaTeX, JIRA Wikitext, etc.

    Copyright: Per Nordlöw 2014-.
    License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
    Authors: $(WEB Per Nordlöw)

    TODO: Remove all restrictions on pp.*Raw.* and call them using ranges such as repeat

    TODO: Use "alias this" on wrapper structures and test!

    TODO: x.in!Bold
    TODO: x.in!Color(1,2,3)
    TODO: x.in!Color(x"122123")
    TODO: x.in!"bold"

    TODO: How should std.typecons.Tuple be pretty printed?
    TODO: Add visited member to keeps track of what objects that have been visited
    TODO: Add asGCCMessage pretty prints
          seq($PATH, ':', $ROW, ':', $COL, ':', message, '[', $TYPE, ']'

    TODO: Support VizForm.D3js
*/
module pprint;

import std.range: isInputRange, map, repeat;
import std.traits: isInstanceOf, isSomeString, isSomeChar, isAggregateType, Unqual, isArray, isIterable;
import std.stdio: stdout;
import std.conv: to;
import std.path: dirSeparator;

import w3c: encodeHTML;
import arsd.terminal; // TODO: Make this optional

/* TODO: Move logic (toHTML) to these deps and remove these imports */
import digest_ex: Digest;
import csunits: Bytes;
import fs: FKind, isSymlink, isDir;
import notnull: NotNull;
import mathml;
import languages;

import traits_ex: isCallableWith;

import rational;

// TODO: Check for MathML support on backend
@property @trusted void ppMathML(T)(Viz viz,
                                    Rational!T arg)
{
    viz.ppTagOpen(`math`);
    viz.ppTagOpen(`mfrac`);
    viz.ppTaggedN(`mi`, arg.numerator);
    viz.ppTaggedN(`mi`, arg.denominator);
    viz.ppTagClose(`mfrac`);
    viz.ppTagClose(`math`);
}

import core.time: Duration;

/** Returns: Duration $(D dur) in a Level-Of-Detail (LOD) string
    representation.
*/
string shortDurationString(in Duration dur) @safe pure
{
    import std.conv: to;
    static if (__VERSION__ >= 2066L)
    {
        immutable weeks = dur.total!"weeks";
        if (weeks)
        {
            if (weeks < 52)
            {
                return to!string(weeks) ~ " week" ~ (weeks >= 2 ? "s" : "");
            }
            else
            {
                immutable years = weeks / 52;
                immutable weeks_rest = weeks % 52;
                return to!string(years) ~ " year" ~ (years >= 2 ? "s" : "") ~
                    " and " ~
                    to!string(weeks_rest) ~ " week" ~ (weeks_rest >= 2 ? "s" : "");
            }
        }
        immutable days = dur.total!"days";       if (days)    return to!string(days) ~ " day" ~ (days >= 2 ? "s" : "");
        immutable hours = dur.total!"hours";     if (hours)   return to!string(hours) ~ " hour" ~ (hours >= 2 ? "s" : "");
        immutable minutes = dur.total!"minutes"; if (minutes) return to!string(minutes) ~ " minute" ~ (minutes >= 2 ? "s" : "");
        immutable seconds = dur.total!"seconds"; if (seconds) return to!string(seconds) ~ " second" ~ (seconds >= 2 ? "s" : "");
        immutable msecs = dur.total!"msecs";     if (msecs) return to!string(msecs) ~ " millisecond" ~ (msecs >= 2 ? "s" : "");
        immutable usecs = dur.total!"usecs";     if (usecs) return to!string(usecs) ~ " microsecond" ~ (msecs >= 2 ? "s" : "");
        immutable nsecs = dur.total!"nsecs";     return to!string(nsecs) ~ " nanosecond" ~ (msecs >= 2 ? "s" : "");
    }
    else
    {
        immutable weeks = dur.weeks();
        if (weeks)
        {
            if (weeks < 52)
            {
                return to!string(weeks) ~ " week" ~ (weeks >= 2 ? "s" : "");
            }
            else
            {
                immutable years = weeks / 52;
                immutable weeks_rest = weeks % 52;
                return to!string(years) ~ " year" ~ (years >= 2 ? "s" : "") ~
                    " and " ~
                    to!string(weeks_rest) ~ " week" ~ (weeks_rest >= 2 ? "s" : "");
            }
        }
        immutable days = dur.days();       if (days)    return to!string(days) ~ " day" ~ (days >= 2 ? "s" : "");
        immutable hours = dur.hours();     if (hours)   return to!string(hours) ~ " hour" ~ (hours >= 2 ? "s" : "");
        immutable minutes = dur.minutes(); if (minutes) return to!string(minutes) ~ " minute" ~ (minutes >= 2 ? "s" : "");
        immutable seconds = dur.seconds(); if (seconds) return to!string(seconds) ~ " second" ~ (seconds >= 2 ? "s" : "");
        immutable msecs = dur.msecs();     if (msecs) return to!string(msecs) ~ " millisecond" ~ (msecs >= 2 ? "s" : "");
        immutable usecs = dur.usecs();     if (usecs) return to!string(usecs) ~ " microsecond" ~ (msecs >= 2 ? "s" : "");
        immutable nsecs = dur.nsecs();     return to!string(nsecs) ~ " nanosecond" ~ (msecs >= 2 ? "s" : "");
    }
}

/** Returns: Documentation String for Enumeration Type $(D EnumType). */
string enumDoc(EnumType, string separator = `|`)() @safe pure nothrow
{
    /* import std.traits: EnumMembers; */
    /* return EnumMembers!EnumType.join(separator); */
    /* auto subsSortingNames = EnumMembers!EnumType; */
    auto x = (__traits(allMembers, EnumType));
    string doc = ``;
    foreach (ix, name; x)
    {
        if (ix >= 1) { doc ~= separator; }
        doc ~= name;
    }
    return doc;
}

/** Returns: Default Documentation String for value $(D a) of for Type $(D T). */
string defaultDoc(T)(in T a) @safe pure
{
    import std.conv: to;
    return (` (type:` ~ T.stringof ~
            `, default:` ~ to!string(a) ~
            `).`) ;
}

/** Visual Form(at). */
enum VizForm
{
    textAsciiDoc,
    textAsciiDocUTF8,
    HTML,
    D3js,                       // See also: http://d3js.org/
    LaTeX,
    jiraWikiMarkup, // See also: https://jira.atlassiana.com/secure/WikiRendererHelpAction.jspa?section=all
    Markdown,
}

/** Visual Backend. */
class Viz
{
    import std.stdio: ioFile = File;
    import arsd.terminal: Terminal;

    ioFile outFile;
    Terminal* term;

    bool treeFlag;
    VizForm form;

    bool colorFlag;
    bool flushNewlines = true;
    /* If any (HTML) tags should be ended with a newline.
       This increases the readability of generated HTML code.
     */
    bool newlinedTags = true;

    this(ioFile outFile,
         Terminal* term,
         bool treeFlag,
         VizForm form,
         bool colorFlag,
         bool flushNewlines = true,
         bool newlinedTags = true,
        )
    {
        this.outFile = outFile;
        this.term = term;
        this.treeFlag = treeFlag;
        this.form = form;
        this.colorFlag = colorFlag;
        this.flushNewlines = flushNewlines;
        this.newlinedTags = newlinedTags;
        if (form == VizForm.HTML)
        {
            ppRaw(this,
                  `<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8"/>
<style>

body {
    font: 10px Verdana, sans-serif;
}
hit0 {
    background-color:#F2B701;
    border: solid 0px grey;
}
hit1 {
    background-color:#F18204;
    border: solid 0px grey;
}
hit2 {
    background-color:#F50035;
    border: solid 0px grey;
}
hit3 {
    background-color:#F5007A;
    border: solid 0px grey;
}
hit4 {
    background-color:#A449B6;
    border: solid 0px grey;
}
hit5 {
    background-color:#3A70BB;
    border: solid 0px grey;
}
hit6 {
    background-color:#0DE7A6;
    border: solid 0px grey;
}
hit7 {
    background-color:#70AD48;
    border: solid 0px grey;
}

hit_context {
    background-color:#c0c0c0;
    border: solid 0px grey;
}

code {
    background-color:#FFFFE0;
}

td, th {
    border: 1px solid black;
}
table {
    border-collapse: collapse;
}

</style>
</head>
<body>
`);
        }
    }

    ~this()
    {
        if (form == VizForm.HTML)
        {
            ppRaw(this, "</body>\n</html>");
        }
    }
}

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
enum stdFace = face(arsd.terminal.Color.white, arsd.terminal.Color.black);
enum pathFace = face(arsd.terminal.Color.green, arsd.terminal.Color.black, true);

enum dirFace = face(arsd.terminal.Color.blue, arsd.terminal.Color.black, true);
enum fileFace = face(arsd.terminal.Color.magenta, arsd.terminal.Color.black, true);
enum baseNameFace = fileFace;
enum specialFileFace = face(arsd.terminal.Color.red, arsd.terminal.Color.black, true);
enum regFileFace = face(arsd.terminal.Color.white, arsd.terminal.Color.black, true, false, [`b`]);
enum symlinkFace = face(arsd.terminal.Color.cyan, arsd.terminal.Color.black, true, true, [`i`]);
enum symlinkBrokenFace = face(arsd.terminal.Color.red, arsd.terminal.Color.black, true, true, [`i`]);
enum missingSymlinkTargetFace = face(arsd.terminal.Color.red, arsd.terminal.Color.black, false, true, [`i`]);

enum contextFace = face(arsd.terminal.Color.green, arsd.terminal.Color.black);

enum timeFace = face(arsd.terminal.Color.magenta, arsd.terminal.Color.black);
enum digestFace = face(arsd.terminal.Color.yellow, arsd.terminal.Color.black);
enum bytesFace = face(arsd.terminal.Color.yellow, arsd.terminal.Color.black);

enum infoFace = face(arsd.terminal.Color.white, arsd.terminal.Color.black, true);
enum warnFace = face(arsd.terminal.Color.yellow, arsd.terminal.Color.black);
enum kindFace = warnFace;
enum errorFace = face(arsd.terminal.Color.red, arsd.terminal.Color.black);

enum titleFace = face(arsd.terminal.Color.white, arsd.terminal.Color.black, false, false, [`title`]);
enum h1Face = face(arsd.terminal.Color.white, arsd.terminal.Color.black, false, false, [`h1`]);

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
    /** Words. */
    struct AsWords(T...) { T args; } auto ref asWords(T...)(T args) { return AsWords!T(args); }
    /** Comma-Separated List. */
    struct AsCSL(T...) { T args; } auto ref asCSL(T...)(T args) { return AsCSL!T(args); }

    /** Printed as Path. */
    struct AsPath(T) { T arg; } auto ref asPath(T)(T arg) { return AsPath!T(arg); }
    /** Printed as Name. */
    struct AsName(T) { T arg; } auto ref asName(T)(T arg) { return AsName!T(arg); }

    /* TODO: Turn these into an enum for more efficient parsing. */
    /** Printed as Italic/Slanted. */
    struct AsItalic(T...) { T args; } auto asItalic(T...)(T args) { return AsItalic!T(args); }
    /** Bold. */
    struct AsBold(T...) { T args; } auto asBold(T...)(T args) { return AsBold!T(args); }
    /** Monospaced. */
    struct AsMonospaced(T...) { T args; } auto asMonospaced(T...)(T args) { return AsMonospaced!T(args); }

    /** Code. */
    struct AsCode(TokenId token = TokenId.unknown,
                  Lang lang_ = Lang.unknown, T...)
    {
        this(T args) { this.args = args; }
        T args;
        static lang = lang_;
        string language;
        TokenId tokenId;
        Usage usage;
        auto ref setLanguage(string language)
        {
            this.language = language;
            return this;
        }
    }

    /* Instantiators */
    auto ref asCode(Lang lang_ = Lang.unknown, T...)(T args) { return AsCode!(TokenId.unknown, lang_, T)(args); }
    auto ref asKeyword(Lang lang_ = Lang.unknown, T...)(T args) { return AsCode!(TokenId.keyword, lang_, T)(args); } // Emacs: font-lock-keyword-face
    auto ref asType(Lang lang_ = Lang.unknown, T...)(T args) { return AsCode!(TokenId.type, lang_, T)(args); } // Emacs: font-lock-type-face
    auto ref asConstant(Lang lang_ = Lang.unknown, T...)(T args) { return AsCode!(TokenId.constant, lang_, T)(args); } // Emacs: font-lock-constant-face
    auto ref asVariable(Lang lang_ = Lang.unknown, T...)(T args) { return AsCode!(TokenId.variableName, lang_, T)(args); } // Emacs: font-lock-variable-name-face
    auto ref asComment(Lang lang_ = Lang.unknown, T...)(T args) { return AsCode!(TokenId.comment, lang_, T)(args); } // Emacs: font-lock-comment-face
    auto ref asFunction(Lang lang_ = Lang.unknown, T...)(T args) { return AsCode!(TokenId.functionName, lang_, T)(args); } // Emacs: font-lock-function-name-face
    auto ref asConstructor(Lang lang_ = Lang.unknown, T...)(T args) { return AsCode!(TokenId.constructor, lang_, T)(args); } // constuctor
    auto ref asDestructor(Lang lang_ = Lang.unknown, T...)(T args) { return AsCode!(TokenId.destructor, lang_, T)(args); } // destructor
    auto ref asBuiltin(Lang lang_ = Lang.unknown, T...)(T args) { return AsCode!(TokenId.builtinName, lang_, T)(args); } // Emacs: font-lock-builtin-name-face
    auto ref asTemplate(Lang lang_ = Lang.unknown, T...)(T args) { return AsCode!(TokenId.templateName, lang_, T)(args); } // Emacs: font-lock-builtin-name-face
    auto ref asOperator(Lang lang_ = Lang.unknown, T...)(T args) { return AsCode!(TokenId.operator, lang_, T)(args); } // Emacs: font-lock-operator-face
    auto ref asMacro(Lang lang_ = Lang.unknown, T...)(T args) { return AsCode!(TokenId.macroName, lang_, T)(args); }
    auto ref asAlias(Lang lang_ = Lang.unknown, T...)(T args) { return AsCode!(TokenId.aliasName, lang_, T)(args); }
    auto ref asEnumeration(Lang lang_ = Lang.unknown, T...)(T args) { return AsCode!(TokenId.enumeration, lang_, T)(args); }
    auto ref asEnumerator(Lang lang_ = Lang.unknown, T...)(T args) { return AsCode!(TokenId.enumerator, lang_, T)(args); }
    alias asCtor = asConstructor;
    alias asDtor = asDestructor;
    alias asEnum = asEnumeration;

    /** Emphasized. */
    struct AsEmphasized(T...) { T args; } auto ref asEmphasized(T...)(T args) { return AsEmphasized!T(args); }

    /** Strongly Emphasized. */
    struct AsStronglyEmphasized(T...) { T args; } auto ref asStronglyEmphasized(T...)(T args) { return AsStronglyEmphasized!T(args); }

    /** Strong. */
    struct AsStrong(T...) { T args; } auto ref asStrong(T...)(T args) { return AsStrong!T(args); }
    /** Citation. */
    struct AsCitation(T...) { T args; } auto ref asCitation(T...)(T args) { return AsCitation!T(args); }
    /** Deleted. */
    struct AsDeleted(T...) { T args; } auto ref asDeleted(T...)(T args) { return AsDeleted!T(args); }
    /** Inserted. */
    struct AsInserted(T...) { T args; } auto ref asInserted(T...)(T args) { return AsInserted!T(args); }
    /** Superscript. */
    struct AsSuperscript(T...) { T args; } auto ref asSuperscript(T...)(T args) { return AsSuperscript!T(args); }
    /** Subscript. */
    struct AsSubscript(T...) { T args; } auto ref asSubscript(T...)(T args) { return AsSubscript!T(args); }

    /** Preformatted. */
    struct AsPreformatted(T...) { T args; } auto ref asPreformatted(T...)(T args) { return AsPreformatted!T(args); }

    /** Scan Hit with index $(D ix)). */
    struct AsHit(T...) { uint ix; T args; } auto ref asHit(T)(uint ix, T args) { return AsHit!T(ix, args); }

    /** Scan Hit Context with index $(D ix)). */
    struct AsCtx(T...) { uint ix; T args; } auto ref asCtx(T)(uint ix, T args) { return AsCtx!T(ix, args); }

    /** Header. */
    struct AsHeader(uint Level, T...) { T args; enum level = Level; }
    auto ref asHeader(uint Level, T...)(T args) { return AsHeader!(Level, T)(args); }

    /** Paragraph. */
    struct AsParagraph(T...) { T args; } auto ref asParagraph(T...)(T args) { return AsParagraph!T(args); }

    /** Multi-Paragraph Blockquote. */
    struct AsBlockquote(T...) { T args; } auto ref asBlockquote(T...)(T args) { return AsBlockquote!T(args); }

    /** Single-Paragraph Blockquote. */
    struct AsBlockquoteSP(T...) { T args; } auto ref asBlockquoteSP(T...)(T args) { return AsBlockquoteSP!T(args); }

    /** Unordered List.
        TODO: Should asUList, asOList autowrap args as AsItems when needed?
    */
    struct AsUList(T...) { T args; } auto ref asUList(T...)(T args) { return AsUList!T(args); }
    /** Ordered List. */
    struct AsOList(T...) { T args; } auto ref asOList(T...)(T args) { return AsOList!T(args); }

    /** Description. */
    struct AsDescription(T...) { T args; } auto ref asDescription(T...)(T args) { return AsDescription!T(args); }

    /** Horizontal Ruler. */
    struct HorizontalRuler {} auto ref horizontalRuler() { return HorizontalRuler(); }

    /** MDash. */
    struct MDash {} auto ref mDash() { return MDash(); }

    enum RowNr { none, offsetZero, offsetOne }

    /** Table.
        TODO: Should asTable autowrap args AsRows when needed?
    */
    struct AsTable(T...)
    {
        string border;
        RowNr rowNr;
        bool recurseFlag;
        T args;
    }
    auto ref asTable(T...)(T args) { return AsTable!T(`"1"`, RowNr.none, false, args); }
    auto ref asTableTree(T...)(T args) { return AsTable!T(`"1"`, RowNr.none, true, args); }
    alias asTablesTable = asTableTree;
    auto ref asTableNr0(T...)(T args) { return AsTable!T(`"1"`, RowNr.offsetZero, false, args); }
    auto ref asTableNr1(T...)(T args) { return AsTable!T(`"1"`, RowNr.offsetOne, false, args); }

    struct AsCols(T...)
    {
        RowNr rowNr;
        size_t rowIx;
        bool recurseFlag;
        T args;
    }
    auto ref asCols(T...)(T args) { return AsCols!T(RowNr.none, 0, false, args); }

    /** Numbered Rows */
    struct AsRows(T...)
    {
        RowNr rowNr;
        bool recurseFlag;
        T args;
    }
    auto ref asRows(T...)(T args) { return AsRows!(T)(RowNr.none, false, args); }

    /** Table Row. */
    struct AsRow(T...) { T args; } auto ref asRow(T...)(T args) { return AsRow!T(args); }
    /** Table Cell. */
    struct AsCell(T...) { T args; } auto ref asCell(T...)(T args) { return AsCell!T(args); }

    /** Row/Column/... Span. */
    struct Span(T...) { uint _span; T args; }
    auto span(T...)(uint span, T args) { return span!T(span, args); }

    /** Table Heading. */
    struct AsTHeading(T...) { T args; } auto ref asTHeading(T...)(T args) { return AsTHeading!T(args); }

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
    struct AsItem(T...) { T args; } auto ref asItem(T...)(T args) { return AsItem!T(args); }

    string lbr(bool useHTML) { return (useHTML ? `<br>` : ``); } // line break

    /* HTML Aliases */
    alias asB = asBold;
    alias asI = asBold;
    alias asTT = asMonospaced;
    alias asP = asParagraph;
    alias asH = asHeader;
    alias HR = horizontalRuler;
    alias asUL = asUList;
    alias asOL = asOList;
    alias asTR = asRow;
    alias asTD = asCell;
}

struct As(Attribute, Things...)
{
    Things things;
}
auto ref as(Attribute, Things...)(Things things)
{
    return As!(Attribute, Things)(things);
}

/** Put $(D arg) to $(D viz) without any conversion nor coloring. */
void ppRaw(T...)(Viz viz,
                 T args) @trusted
{
    foreach (arg; args)
    {
        if (viz.outFile == stdout)
            (*viz.term).write(arg);
        else
            viz.outFile.write(arg);
    }
}

/** Put $(D arg) to $(D viz) without any conversion nor coloring. */
void pplnRaw(T...)(Viz viz,
                   T args) @trusted
{
    foreach (arg; args)
    {
        if (viz.outFile == stdout)
            if (viz.flushNewlines)
                (*viz.term).writeln(arg);
            else
                (*viz.term).write(arg, '\n');
        else
            if (viz.flushNewlines)
                viz.outFile.writeln(arg);
            else
                viz.outFile.write(arg, '\n');
    }
}

void ppTagOpen(T, P...)(Viz viz,
                        T tag, P params) @trusted
{
    if (viz.form == VizForm.HTML)
    {
        viz.ppRaw(`<` ~ tag);
        foreach (param; params)
        {
            viz.ppRaw(' ', param);
        }
        viz.ppRaw(`>`);
    }
}

void ppTagClose(T)(Viz viz,
                   T tag) @trusted
{
    immutable arg = (viz.form == VizForm.HTML) ? `</` ~ tag ~ `>` : tag;
    viz.ppRaw(arg);
}

void pplnTagOpen(T)(Viz viz,
                    T tag) @trusted
{
    immutable arg = (viz.form == VizForm.HTML) ? `<` ~ tag ~ `>` : tag;
    if (viz.newlinedTags)
        viz.pplnRaw(arg);
    else
        viz.ppRaw(arg);
}

void pplnTagClose(T)(Viz viz,
                     T tag) @trusted
{
    immutable arg = (viz.form == VizForm.HTML) ? `</` ~ tag ~ `>` : tag;
    if (viz.newlinedTags)
        viz.pplnRaw(arg);
    else
        viz.ppRaw(arg);
}

/** Put $(D arg) to $(D viz) possibly with conversion. */
void ppPut(T)(Viz viz,
              T arg,
              bool nbsp = true) @trusted
{
    if (viz.outFile == stdout)
        (*viz.term).write(arg);
    else
    {
        if (viz.form == VizForm.HTML)
            viz.outFile.write(arg.encodeHTML(nbsp));
        else
            viz.outFile.write(arg);
    }
}

/** Put $(D arg) to $(D viz) possibly with conversion. */
void ppPut(T)(Viz viz,
              Face!Color face,
              T arg,
              bool nbsp = true) @trusted
{
    (*viz.term).setFace(face, viz.colorFlag);
    viz.ppPut(arg, nbsp);
}

/** Fazed (Rich) Text. */
struct Fazed(T)
{
    T text;
    const Face!Color face;
    string toString() const @property @trusted pure nothrow { return to!string(text); }
}
auto faze(T)(T text,
             in Face!Color face = stdFace) @safe pure nothrow
{
    return Fazed!T(text, face);
}

auto getFace(Arg)(in Arg arg) @safe pure nothrow
{
    // pick face
    static if (__traits(hasMember, arg, `face`))
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

void ppTaggedN(Tag, Args...)(Viz viz,
                             in Tag tag,
                             Args args)
    @trusted if (isSomeString!Tag)
{
    import dbg;
    if (viz.form == VizForm.HTML) { viz.ppRaw(`<` ~ tag ~ `>`); }
    viz.ppN(args);
    if (viz.form == VizForm.HTML) { viz.ppRaw(`</` ~ tag ~ `>`); }
}

void pplnTaggedN(Tag, Args...)(Viz viz,
                               in Tag tag,
                               Args args)
    @trusted if (isSomeString!Tag)
{
    viz.ppTaggedN(tag, args);
    if (viz.newlinedTags)
        viz.pplnRaw(``);
}

/** Pretty-Print Single Argument $(D arg) to Terminal $(D term). */
void pp1(Arg)(Viz viz,
              int depth,
              Arg arg)
    @trusted
{
    static if (is(typeof(viz.ppMathML(arg))))
    {
        if (viz.form == VizForm.HTML)
        {
            return viz.ppMathML(arg);
        }
    }
    static if (is(typeof(arg.toMathML)))
    {
        if (viz.form == VizForm.HTML)
        {
            // TODO: Check for MathML support on backend
            return viz.ppRaw(arg.toMathML);
        }
    }
    static if (is(typeof(arg.toHTML)))
    {
        if (viz.form == VizForm.HTML)
        {
            return viz.ppRaw(arg.toHTML);
        }
    }
    static if (is(typeof(arg.toLaTeX)))
    {
        if (viz.form == VizForm.LaTeX)
        {
            return viz.ppRaw(arg.toLaTeX);
        }
    }

    /* TODO: Check if any member has mmber toMathML if so call it otherwise call
     * toString. */

    static if (isArray!Arg &&
               !isSomeString!Arg)
    {
        viz.ppRaw(`[`);
        foreach (ix, subArg; arg)
        {
            if (ix >= 1)
                viz.ppRaw(`,`); // separator
            viz.pp1(depth + 1, subArg);
        }
        viz.ppRaw(`]`);
    }
    else static if (isInputRange!Arg)
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
                viz.ppRaw(` `); // separator
            viz.pp1(depth + 1, subArg);
        }
    }
    else static if (isInstanceOf!(AsCSL, Arg))
    {
        foreach (ix, subArg; arg.args)
        {
            static if (ix >= 1)
                viz.pp1(depth + 1, `,`); // separator
            static if (isInputRange!(typeof(subArg)))
            {
                foreach (subsubArg; subArg)
                {
                    viz.ppN(subsubArg, `,`);
                }
            }
        }
    }
    else static if (isInstanceOf!(AsBold, Arg))
    {
        if      (viz.form == VizForm.HTML)
        {
            viz.ppTaggedN(`b`, arg.args);
        }
        else if (viz.form == VizForm.Markdown)
        {
            viz.ppRaw(`**`);
            viz.ppN(arg.args);
            viz.ppRaw(`**`);
        }
    }
    else static if (isInstanceOf!(AsItalic, Arg))
    {
        if      (viz.form == VizForm.HTML)
        {
            viz.ppTaggedN(`i`, arg.args);
        }
        else if (viz.form == VizForm.Markdown)
        {
            viz.ppRaw(`*`);
            viz.ppN(arg.args);
            viz.ppRaw(`*`);
        }
    }
    else static if (isInstanceOf!(AsMonospaced, Arg))
    {
        if      (viz.form == VizForm.HTML)
        {
            viz.ppTaggedN(`tt`, arg.args);
        }
        else if (viz.form == VizForm.jiraWikiMarkup)
        {
            viz.ppRaw(`{{`);
            viz.ppN(arg.args);
            viz.ppRaw(`}}`);
        }
        else if (viz.form == VizForm.Markdown)
        {
            viz.ppRaw('`');
            viz.ppN(arg.args);
            viz.ppRaw('`');
        }
    }
    else static if (isInstanceOf!(AsCode, Arg))
    {
        if      (viz.form == VizForm.HTML)
        {
            /* TODO: Use arg.language member to highlight using fs tokenizers
             * which must be moved out of fs. */
            viz.ppTaggedN(`code`, arg.args);
        }
        else if (viz.form == VizForm.jiraWikiMarkup)
        {
            viz.ppRaw(arg.language ? `{code:` ~ arg.language ~ `}` : `{code}`);
            viz.ppN(arg.args);
            viz.ppRaw(`{code}`);
        }
    }
    else static if (isInstanceOf!(AsEmphasized, Arg))
    {
        if      (viz.form == VizForm.HTML)
        {
            viz.ppTaggedN(`em`, arg.args);
        }
        else if (viz.form == VizForm.jiraWikiMarkup)
        {
            viz.ppRaw(`_`);
            viz.ppN(arg.args);
            viz.ppRaw(`_`);
        }
        else if (viz.form == VizForm.Markdown)
        {
            viz.ppRaw(`_`);
            viz.ppN(arg.args);
            viz.ppRaw(`_`);
        }
    }
    else static if (isInstanceOf!(AsStronglyEmphasized, Arg))
    {
        if (viz.form == VizForm.Markdown)
        {
            viz.ppRaw(`__`);
            viz.ppN(arg.args);
            viz.ppRaw(`__`);
        }
    }
    else static if (isInstanceOf!(AsStrong, Arg))
    {
        if      (viz.form == VizForm.HTML)
        {
            viz.ppTaggedN(`strong`, arg.args);
        }
        else if (viz.form == VizForm.jiraWikiMarkup)
        {
            viz.ppRaw(`*`);
            viz.ppN(arg.args);
            viz.ppRaw(`*`);
        }
    }
    else static if (isInstanceOf!(AsCitation, Arg))
    {
        if      (viz.form == VizForm.HTML)
        {
            viz.ppTaggedN(`cite`, arg.args);
        }
        else if (viz.form == VizForm.jiraWikiMarkup)
        {
            viz.ppRaw(`??`);
            viz.ppN(arg.args);
            viz.ppRaw(`??`);
        }
    }
    else static if (isInstanceOf!(AsDeleted, Arg))
    {
        if      (viz.form == VizForm.HTML)
        {
            viz.ppTaggedN(`deleted`, arg.args);
        }
        else if (viz.form == VizForm.jiraWikiMarkup)
        {
            viz.ppRaw(`-`);
            viz.ppN(arg.args);
            viz.ppRaw(`-`);
        }
    }
    else static if (isInstanceOf!(AsInserted, Arg))
    {
        if      (viz.form == VizForm.HTML)
        {
            viz.ppTaggedN(`inserted`, arg.args);
        }
        else if (viz.form == VizForm.jiraWikiMarkup)
        {
            viz.ppRaw(`+`);
            viz.ppN(arg.args);
            viz.ppRaw(`+`);
        }
    }
    else static if (isInstanceOf!(AsSuperscript, Arg))
    {
        if      (viz.form == VizForm.HTML)
        {
            viz.ppTaggedN(`sup`, arg.args);
        }
        else if (viz.form == VizForm.jiraWikiMarkup)
        {
            viz.ppRaw(`^`);
            viz.ppN(arg.args);
            viz.ppRaw(`^`);
        }
    }
    else static if (isInstanceOf!(AsSubscript, Arg))
    {
        if      (viz.form == VizForm.HTML)
        {
            viz.ppTaggedN(`sub`, arg.args);
        }
        else if (viz.form == VizForm.jiraWikiMarkup)
        {
            viz.ppRaw(`~`);
            viz.ppN(arg.args);
            viz.ppRaw(`~`);
        }
    }
    else static if (isInstanceOf!(AsPreformatted, Arg))
    {
        if      (viz.form == VizForm.HTML)
        {
            viz.pplnTagOpen(`pre`);
            viz.ppN(arg.args);
            viz.pplnTagClose(`pre`);
        }
        else if (viz.form == VizForm.jiraWikiMarkup)
        {
            viz.pplnRaw(`{noformat}`);
            viz.ppN(arg.args);
            viz.pplnRaw(`{noformat}`);
        }
    }
    else static if (isInstanceOf!(AsHeader, Arg))
    {
        if      (viz.form == VizForm.HTML)
        {
            viz.pplnTaggedN(`h` ~ to!string(arg.level),
                         arg.args);
        }
        else if (viz.form == VizForm.jiraWikiMarkup)
        {
            viz.ppRaw(`h` ~ to!string(arg.level) ~ `. `);
            viz.ppN(arg.args);
            viz.pplnRaw(``);
        }
        else if (viz.form == VizForm.Markdown)
        {
            viz.ppN(`#`.repeat(arg.level), ` `, arg.args);
            viz.pplnRaw(``);
        }
        else if (viz.form == VizForm.textAsciiDoc ||
                 viz.form == VizForm.textAsciiDocUTF8)
        {
            viz.ppRaw('\n');
            viz.ppN(`=`.repeat(arg.level),
                    ' ',
                    arg.args,
                    ' ',
                    `=`.repeat(arg.level));
            viz.ppRaw('\n');
        }
    }
    else static if (isInstanceOf!(AsParagraph, Arg))
    {
        if (viz.form == VizForm.HTML)
        {
            viz.pplnTaggedN(`p`, arg.args);
        }
        else if (viz.form == VizForm.LaTeX)
        {
            viz.ppRaw(`\par `);
            viz.pplnTaggedN(arg.args);
        }
        else if (viz.form == VizForm.textAsciiDoc ||
                 viz.form == VizForm.textAsciiDocUTF8)
        {
            viz.ppRaw('\n');
            viz.ppN(`=`.repeat(arg.level),
                    ` `, arg.args,
                    ` `, tag, '\n');
        }
    }
    else static if (isInstanceOf!(AsBlockquote, Arg))
    {
        if (viz.form == VizForm.HTML)
        {
            viz.pplnTaggedN(`blockquote`, arg.args);
        }
        else if (viz.form == VizForm.jiraWikiMarkup)
        {
            viz.pplnRaw(`{quote}`);
            viz.pplnRaw(arg.args);
            viz.pplnRaw(`{quote}`);
        }
        else if (viz.form == VizForm.Markdown)
        {
            foreach (subArg; arg.args)
            {
                viz.pplnRaw(`> `, subArg); // TODO: Iterate for each line in subArg
            }
        }
    }
    else static if (isInstanceOf!(AsBlockquoteSP, Arg))
    {
        if (viz.form == VizForm.jiraWikiMarkup)
        {
            viz.ppRaw(`bq. `);
            viz.ppN(arg.args);
            viz.pplnRaw(``);
        }
    }
    else static if (is(HorizontalRuler == Arg))
    {
        if (viz.form == VizForm.HTML)
        {
            viz.pplnTagOpen(`hr`);
        }
        if (viz.form == VizForm.jiraWikiMarkup)
        {
            viz.pplnRaw(`----`);
        }
    }
    else static if (isInstanceOf!(MDash, Arg))
    {
        if (viz.form == VizForm.HTML)
        {
            viz.ppRaw(`&mdash;`);
        }
        if (viz.form == VizForm.jiraWikiMarkup ||
            viz.form == VizForm.Markdown ||
            viz.form == VizForm.LaTeX)
        {
            viz.pplnRaw(`---`);
        }
    }
    else static if (isInstanceOf!(AsUList, Arg))
    {
        if (viz.form == VizForm.HTML) { viz.pplnTagOpen(`ul`); }
        else if (viz.form == VizForm.LaTeX) { viz.pplnRaw(`\begin{enumerate}`); }
        viz.ppN(arg.args);
        if (viz.form == VizForm.HTML) { viz.pplnTagClose(`ul`); }
        else if (viz.form == VizForm.LaTeX) { viz.pplnRaw(`\end{enumerate}`); }
    }
    else static if (isInstanceOf!(AsOList, Arg))
    {
        if (viz.form == VizForm.HTML) { viz.pplnTagOpen(`ol`); }
        else if (viz.form == VizForm.LaTeX) { viz.pplnRaw(`\begin{itemize}`); }
        viz.ppN(arg.args);
        if (viz.form == VizForm.HTML) { viz.pplnTagClose(`ol`); }
        else if (viz.form == VizForm.LaTeX) { viz.pplnRaw(`\end{itemize}`); }
    }
    else static if (isInstanceOf!(AsDescription, Arg)) // if args .length == 1 && an InputRange of 2-tuples pairs
    {
        if (viz.form == VizForm.HTML) { viz.pplnTagOpen(`dl`); } // TODO: TERM <dt>, DEFINITION <dd>
        else if (viz.form == VizForm.LaTeX) { viz.pplnRaw(`\begin{description}`); } // TODO: \item[TERM] DEFINITION
        viz.ppN(arg.args);
        if (viz.form == VizForm.HTML) { viz.pplnTagClose(`dl`); }
        else if (viz.form == VizForm.LaTeX) { viz.pplnRaw(`\end{description}`); }
    }
    else static if (isInstanceOf!(AsTable, Arg))
    {
        if (viz.form == VizForm.HTML)
        {
            const border = (arg.border ? ` border=` ~ arg.border : ``);
            viz.pplnTagOpen(`table` ~ border);
        }
        else if (viz.form == VizForm.LaTeX)
        {
            viz.pplnRaw(`\begin{tabular}`);
        }

        static if (arg.args.length == 1 &&
                   isIterable!(typeof(arg.args[0])))
        {
            auto rows = arg.args[0].asRows;
            rows.recurseFlag = arg.recurseFlag; // propagate
            rows.rowNr = arg.rowNr;
            viz.pp(rows);
        }
        else
        {
            viz.ppN(arg.args);
        }

        if (viz.form == VizForm.HTML)
        {
            viz.pplnTagClose(`table`);
        }
        else if (viz.form == VizForm.LaTeX)
        {
            viz.pplnRaw(`\end{tabular}`);
        }
    }
    else static if (isInstanceOf!(AsRows, Arg) &&
                    arg.args.length == 1 &&
                    isArray!(typeof(arg.args[0]))) // if single array
    {
        bool capitalizeHeadings = true;

        /* See also: http://forum.dlang.org/thread/wjksldfpkpenoskvhsqa@forum.dlang.org#post-jwfildowqrbwtamywsmy:40forum.dlang.org */

        // use aggregate members as header
        import std.range: front;
        const first = arg.args[0].front;
        alias Front = typeof(first);
        static if (isAggregateType!Front)
        {
            /* TODO: When __traits(documentation,x)
               here https://github.com/D-Programming-Language/dmd/pull/3531
               get merged use it! */
            // viz.pplnTaggedN(`tr`, subArg.asCols); // TODO: asItalic

            // Use __traits(allMembers, T) instead

            // Can we lookup file and line of user defined types aswell?

            // member names header. TODO: Functionize
            if (viz.form == VizForm.HTML) { viz.pplnTagOpen(`tr`); }

            if      (arg.rowNr == RowNr.offsetZero)
                viz.pplnTaggedN(`td`, "Offset");
            else if (arg.rowNr == RowNr.offsetOne)
                viz.pplnTaggedN(`td`, "Offset");

            foreach (ix, member; first.tupleof)
            {
                enum idName = __traits(identifier, Front.tupleof[ix]);
                import std.string: capitalize;
                viz.pplnTaggedN(`td`, (capitalizeHeadings ? idName.capitalize : idName).asItalic.asBold);
            }
            if (viz.form == VizForm.HTML) { viz.pplnTagClose(`tr`); }

            // member types header. TODO: Functionize
            if (viz.form == VizForm.HTML) { viz.pplnTagOpen(`tr`); }

            if      (arg.rowNr == RowNr.offsetZero)
                viz.pplnTaggedN(`td`, "");
            else if (arg.rowNr == RowNr.offsetOne)
                viz.pplnTaggedN(`td`, "");

            foreach (member; first.tupleof)
            {
                alias Memb = Unqual!(typeof(member)); // skip constness for now

                enum type_string = Memb.stringof;

                // TODO: Why doesn't this work for builtin types:
                // enum type_string = __traits(identifier, Memb);

                static      if (is(Memb == struct))
                    enum qual_string = `struct `;
                else static if (is(Memb == class))
                    enum qual_string = `class `;
                else
                    enum qual_string = ``;

                viz.pplnTaggedN(`td`,
                                qual_string.asKeyword,
                                type_string.asType);
            }
            if (viz.form == VizForm.HTML) { viz.pplnTagClose(`tr`); }
        }

        foreach (ix, subArg; arg.args[0]) // for each table row
        {
            auto cols = subArg.asCols;
            cols.recurseFlag = arg.recurseFlag; // propagate
            cols.rowNr = arg.rowNr;
            cols.rowIx = ix;
            viz.pplnTaggedN(`tr`, cols); // print columns
        }
    }
    else static if (isInstanceOf!(AsCols, Arg))
    {
        if (arg.args.length == 1 &&
            isAggregateType!(typeof(arg.args[0])))
        {
            auto args0 = arg.args[0];
            if (viz.form == VizForm.jiraWikiMarkup)
            {
                /* if (args0.length >= 1) */
                /* { */
                /*     viz.ppRaw(`|`); */
                /* } */
            }
            if      (arg.rowNr == RowNr.offsetZero)
                viz.pplnTaggedN(`td`, arg.rowIx + 0);
            else if (arg.rowNr == RowNr.offsetOne)
                viz.pplnTaggedN(`td`, arg.rowIx + 1);
            foreach (subArg; args0.tupleof) // for each table column
            {
                if (viz.form == VizForm.HTML)
                {
                    viz.pplnTaggedN(`td`, subArg); // each element in aggregate as a column
                }
                else if (viz.form == VizForm.jiraWikiMarkup)
                {
                    /* viz.pp1(subArg); */
                    /* viz.ppRaw(`|`); */
                }
            }
        }
        else
        {
            viz.pplnTaggedN(`tr`, arg.args);
        }
    }
    else static if (isInstanceOf!(AsRow, Arg))
    {
        string spanArg;
        static if (arg.args.length == 1 &&
                   isInstanceOf!(Span, typeof(arg.args[0])))
        {
            spanArg ~= ` rowspan="` ~ to!string(arg._span) ~ `"`;
        }
        if (viz.form == VizForm.HTML) { viz.pplnTagOpen(`tr` ~ spanArg); }
        viz.ppN(arg.args);
        if (viz.form == VizForm.HTML) { viz.pplnTagClose(`tr`); }
    }
    else static if (isInstanceOf!(AsCell, Arg))
    {
        string spanArg;
        static if (arg.args.length >= 1 &&
                   isInstanceOf!(Span, typeof(arg.args[0])))
        {
            spanArg ~= ` colspan="` ~ to!string(arg._span) ~ `"`;
        }
        if (viz.form == VizForm.HTML) { viz.ppTagOpen(`td` ~ spanArg); }
        viz.ppN(arg.args);
        if (viz.form == VizForm.HTML) { viz.pplnTagClose(`td`); }
    }
    else static if (isInstanceOf!(AsTHeading, Arg))
    {
        if (viz.form == VizForm.HTML)
        {
            viz.pplnTagOpen(`th`);
            viz.ppN(arg.args);
            viz.pplnTagClose(`th`);
        }
        else if (viz.form == VizForm.jiraWikiMarkup)
        {
            if (args.length >= 1)
            {
                viz.ppRaw(`||`);
            }
            foreach (subArg; args)
            {
                viz.pp1(subArg);
                viz.ppRaw(`||`);
            }
        }
    }
    else static if (isInstanceOf!(AsItem, Arg))
    {
        if (viz.form == VizForm.HTML) { viz.ppTagOpen(`li`); }
        else if (viz.form == VizForm.textAsciiDoc) { viz.ppRaw(` - `); } // if inside ordered list use . instead of -
        else if (viz.form == VizForm.LaTeX) { viz.ppRaw(`\item `); }
        else if (viz.form == VizForm.textAsciiDocUTF8) { viz.ppRaw(` • `); }
        else if (viz.form == VizForm.Markdown) { viz.ppRaw(`* `); } // TODO: Alternatively +,-,*, or 1. TODO: Need counter for ordered lists
        viz.ppN(arg.args);
        if (viz.form == VizForm.HTML) { viz.pplnTagClose(`li`); }
        else if (viz.form == VizForm.LaTeX) { viz.pplnRaw(``); }
        else if (viz.form == VizForm.textAsciiDoc ||
                 viz.form == VizForm.textAsciiDocUTF8 ||
                 viz.form == VizForm.Markdown) { viz.pplnRaw(``); }
    }
    else static if (isInstanceOf!(AsPath, Arg))
    {
        auto vizArg = viz;
        vizArg.treeFlag = false;

        import std.traits: isSomeString;
        enum isString = isSomeString!(typeof(arg.arg));

        static if (isString)
            if (viz.form == VizForm.HTML)
            {
                viz.ppTagOpen(`a href="file://` ~ arg.arg ~ `"`);
            }

        pp1(vizArg, depth + 1, arg.arg);

        static if (isString)
            if (viz.form == VizForm.HTML)
            {
                viz.ppTagClose(`a`);
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
        if (viz.form == VizForm.HTML) { viz.ppTagOpen(`hit` ~ ixs); }
        viz.pp1(depth + 1, arg.args);
        if (viz.form == VizForm.HTML) { viz.ppTagClose(`hit` ~ ixs); }
    }
    else static if (isInstanceOf!(AsCtx, Arg))
    {
        if (viz.form == VizForm.HTML) { viz.ppTagOpen(`hit_context`); }
        viz.pp1(depth + 1, arg.args);
        if (viz.form == VizForm.HTML) { viz.ppTagClose(`hit_context`); }
    }
    else static if (__traits(hasMember, arg, "parent")) // TODO: Use isFile = File or NonNull!File
    {
        if (viz.form == VizForm.HTML)
        {
            viz.ppRaw(`<a href="file://`);
            viz.ppPut(arg.path);
            viz.ppRaw(`">`);
        }

        if (!viz.treeFlag)
        {
            // write parent path
            foreach (parent; arg.parents)
            {
                viz.ppPut(dirSeparator);
                if (viz.form == VizForm.HTML) { viz.ppTagOpen(`b`); }
                viz.ppPut(dirFace, parent.name);
                if (viz.form == VizForm.HTML) { viz.ppTagClose(`b`); }
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

        if (viz.form == VizForm.HTML)
        {
            static      if (isSymlink!Arg) { viz.ppTagOpen(`i`); }
            else static if (isDir!Arg) { viz.ppTagOpen(`b`); }
        }

        viz.ppPut(arg.getFace(), name);

        if (viz.form == VizForm.HTML)
        {
            static      if (isSymlink!Arg) { viz.ppTagClose(`i`); }
            else static if (isDir!Arg) { viz.ppTagClose(`b`); }
        }

        if (viz.form == VizForm.HTML) { viz.ppTagClose(`a`); }
    }
    else
    {
        static if (__traits(hasMember, arg, "path"))
        {
            const arg_string = arg.path;
        }
        else
        {
            const arg_string = to!string(arg);
        }

        static if (__traits(hasMember, arg, "face") &&
                   __traits(hasMember, arg.face, "tagsHTML"))
        {
            if (viz.form == VizForm.HTML)
            {
                foreach (tag; arg.face.tagsHTML)
                {
                    viz.outFile.write(`<`, tag, `>`);
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
            viz.ppPut(arg.getFace(), arg_string);
        }

        static if (__traits(hasMember, arg, "face") &&
                   __traits(hasMember, arg.face, "tagsHTML"))
        {
            if (viz.form == VizForm.HTML)
            {
                foreach (tag; arg.face.tagsHTML)
                {
                    viz.outFile.write(`</`, tag, `>`);
                }
            }
        }
    }
}

/** Pretty-Print Multiple Arguments $(D args) to Terminal $(D term). */
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

/** Pretty-Print Arguments $(D args) including final line termination. */
void ppln(Args...)(Viz viz,
                   Args args) @trusted
{
    viz.ppN(args);
    if (viz.outFile == stdout)
    {
        (*viz.term).writeln(lbr(viz.form == VizForm.HTML));
        (*viz.term).flush();
    }
    else
    {
        viz.outFile.writeln(lbr(viz.form == VizForm.HTML));
    }
}

/** Pretty-Print Arguments $(D args) each including a final line termination. */
void pplns(Args...)(Viz viz,
                    Args args) @trusted
{
    foreach (arg; args)
    {
        viz.ppln(args);
    }
}

/** Print End of Line to Terminal $(D term). */
void ppendl(Viz viz) @trusted
{
    viz.ppln(``);
}
