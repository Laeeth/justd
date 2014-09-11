#!/usr/bin/env rdmd-dev-module

/** Pretty Printing to AsciiDoc, HTML, LaTeX, JIRA Wikitext, etc.

    Copyright: Per Nordlöw 2014-.
    License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
    Authors: $(WEB Per Nordlöw)

    TODO: Remove all restrictions on pp.*Raw.* and call them using ranges such as repeat

    TODO: Use "alias this" on wrapper structures and test!

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
import std.range: ElementType;
import std.string: empty;

import w3c: encodeHTML;
import arsd.terminal; // TODO: Make this optional

/* TODO: Move logic (toHTML) to these deps and remove these imports */
import digest_ex: Digest;
import csunits: Bytes;
import fs: FKind, isSymlink, isDir;
import notnull: NotNull;
import mathml;
import languages;
import attributes;

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
string shortDurationString(in Duration dur)
    @safe pure nothrow
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

/** See also: http://ethanschoonover.com/solarized */
enum SolarizedLightColorTheme
{
    base00  = "657b83",
    base01  = "586e75",
    base02  = "073642",
    base03  = "002b36",

    base0   = "839496",
    base1   = "93a1a1",
    base2   = "eee8d5",
    base3   = "fdf6e3",

    yellow  = "b58900",
    orange  = "cb4b16",
    ed     = "dc322f",
    magenta = "d33682",
    viole   = "6c71c4",
    blue    = "268bd2",
    cya     = "2aa198",
    gree    = "859900"
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
tr:nth-child(even) { background-color: #EBEBEB; }
tr:nth-child(2n+0) { background: #` ~ SolarizedLightColorTheme.base2 ~ `; }
tr:nth-child(2n+1) { background: #` ~ SolarizedLightColorTheme.base3 ~ `; }

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

/** HTML tags with no side-effect when its arguments is empty.
    See also: http://www.w3schools.com/html/html_formatting.asp
 */
static immutable nonStateHTMLTags = [`b`, `i`, `strong`, `em`, `sub`, `sup`, `small`, `ins`, `del`, `mark`
                                     `code`, `kbd`, `samp`, `samp`, `var`, `pre`];

void ppTaggedN(Tag, Args...)(Viz viz,
                             in Tag tag,
                             Args args)
    @trusted if (isSomeString!Tag)
{
    import std.algorithm: find;
    static if (args.length == 1 &&
               isSomeString!(typeof(args[0])))
    {
        if (viz.form == VizForm.HTML &&
            args[0].empty &&
            !nonStateHTMLTags.find(tag).empty)
        {
            return;         // skip HTML tags with no content
        }
    }
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

    static if (isInstanceOf!(AsWords, Arg))
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
            auto rows = arg.args[0].asRows();
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
                    isIterable!(typeof(arg.args[0])))
    {
        bool capitalizeHeadings = true;

        /* See also: http://forum.dlang.org/thread/wjksldfpkpenoskvhsqa@forum.dlang.org#post-jwfildowqrbwtamywsmy:40forum.dlang.org */

        // use aggregate members as header
        alias Front = ElementType!(typeof(arg.args[0])); // elementtype of Iteratable
        static if (isAggregateType!Front)
        {
            /* TODO: When __traits(documentation,x)
               here https://github.com/D-Programming-Language/dmd/pull/3531
               get merged use it! */
            // viz.pplnTaggedN(`tr`, subArg.asCols); // TODO: asItalic
            // Use __traits(allMembers, T) instead
            // Can we lookup file and line of user defined types aswell?

            // member names header.
            if (viz.form == VizForm.HTML) { viz.pplnTagOpen(`tr`); } // TODO: Functionize

            // index column
            if      (arg.rowNr == RowNr.offsetZero) viz.pplnTaggedN(`td`, "0-Offset");
            else if (arg.rowNr == RowNr.offsetOne)  viz.pplnTaggedN(`td`, "1-Offset");
            foreach (ix, Member; typeof(Front.tupleof))
            {
                enum idName = __traits(identifier, Front.tupleof[ix]);
                enum typeName = Unqual!(Member).stringof; // constness of no interest hee

                static      if (is(Memb == struct))    enum qual = `struct `;
                else static if (is(Memb == class))     enum qual = `class `;
                else static if (is(Memb == enum))      enum qual = `enum `;
                else static if (is(Memb == interface)) enum qual = `interface `;
                else                                   enum qual = ``; // TODO: Are there more qualifiers

                import std.string: capitalize;
                viz.pplnTaggedN(`td`,
                                (capitalizeHeadings ? idName.capitalize : idName).asItalic.asBold,
                                `<br>`,
                                qual.asKeyword,
                                typeName.asType);
            }
            if (viz.form == VizForm.HTML) { viz.pplnTagClose(`tr`); }
        }

        size_t ix = 0;
        foreach (subArg; arg.args[0]) // for each table row
        {
            auto cols = subArg.asCols();
            cols.recurseFlag = arg.recurseFlag; // propagate
            cols.rowNr = arg.rowNr;
            cols.rowIx = ix;
            viz.pplnTaggedN(`tr`, cols); // print columns
            ix++;
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
                /* if (args0.length >= 1) { viz.ppRaw(`|`); } */
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
                    /* viz.pp1(subArg); viz.ppRaw(`|`); */
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
    else static if (isInstanceOf!(AsPath, Arg) ||
                    isInstanceOf!(AsURL, Arg))
    {
        auto vizArg = viz;
        vizArg.treeFlag = false;

        enum isString = isSomeString!(typeof(arg.arg)); // only create hyperlink if arg is a string

        static if (isString)
        {
            if (viz.form == VizForm.HTML)
            {
                static if (isInstanceOf!(AsPath, Arg))
                {
                    viz.ppTagOpen(`a href="file://` ~ arg.arg ~ `"`);
                }
                else static if (isInstanceOf!(AsURL, Arg))
                {
                    viz.ppTagOpen(`a href="` ~ arg.arg ~ `"`);
                }
            }
        }

        pp1(vizArg, depth + 1, arg.arg);

        static if (isString)
        {
            if (viz.form == VizForm.HTML)
            {
                viz.ppTagClose(`a`);
            }
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
    else static if (isArray!Arg &&
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
