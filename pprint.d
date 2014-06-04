#!/usr/bin/env rdmd-dev-module

/** Pretty Printing.
    Copyright: Per Nordlöw 2014-.
    License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
    Authors: $(WEB Per Nordlöw)
    TODO: How should std.typecons.Tuple be pretty printed?
*/
module pprint;

import std.range: isInputRange;
import std.traits: isInstanceOf;
import std.stdio: stdout;
import std.conv: to;
import std.path: dirSeparator;
import std.range: map;

/* TODO: These deps needs to be removed somehow */
import digest_ex: Digest;
import csunits: Bytes;
import fs: FKind, isSymlink, isDir;
import notnull: NotNull;

import terminal;

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
    struct InItalic(T) { T arg; } auto inItalic(T)(T arg) { return InItalic!T(arg); }
    /** Printed as Bold. */
    struct InBold(T) { T arg; } auto inBold(T)(T arg) { return InBold!T(arg); }
    /** Printed as Code. */
    struct AsCode(T) { T arg; } auto asCode(T)(T arg) { return AsCode!T(arg); }
    /** Printed as Emphasized. */
    struct AsEm(T) { T arg; } auto asEm(T)(T arg) { return AsEm!T(arg); }
    /** Printed as Strong. */
    struct AsStrong(T) { T arg; } auto asStrong(T)(T arg) { return AsStrong!T(arg); }
    /** Printed as Performatted. */
    struct AsPre(T) { T arg; } auto asPre(T)(T arg) { return AsPre!T(arg); }

    /** Printed as Hit. */
    struct AsHit(T...) { ulong ix; T args; } auto asHit(T)(ulong ix, T args) { return AsHit!T(ix, args); }

    /** Printed as Hit Context. */
    struct AsCtx(T...) { ulong ix; T args; } auto asCtx(T)(ulong ix, T args) { return AsCtx!T(ix, args); }

    /** Header. */
    struct Header(uint L, T...) { T args; enum level = L; }
    auto header(uint L, T...)(T args) { return Header!(L, T)(args); }

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

void ppRaw(Term, Arg)(ref Term term,
                      Viz viz,
                      Arg arg) @trusted
{
    if (viz.outFile == stdout)
        term.write(arg);
    else
        viz.outFile.write(arg);
}

void ppPut(Term, Arg)(ref Term term,
                      Viz viz,
                      Face!Color face,
                      Arg arg) @trusted
{
    term.setFace(face, viz.colorFlag);
    if (viz.outFile == stdout)
        term.write(arg);
    else
        viz.outFile.write(arg);
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
void ppArg(Term, Arg)(ref Term term, Viz viz, int depth,
                      Arg arg) @trusted
{
    static if (isInputRange!Arg)
    {
        foreach (subArg; arg)
        {
            ppArg(term,viz, depth + 1, subArg);
        }
    }
    else static if (isInstanceOf!(AsWords, Arg))
    {
        foreach (ix, subArg; arg.args)
        {
            static if (ix >= 1)
                ppArg(term,viz, depth + 1, " "); // separator
            ppArg(term,viz, depth + 1, subArg);
        }
    }
    else static if (isInstanceOf!(AsCSL, Arg))
    {
        foreach (ix, subArg; arg.args)
        {
            static if (ix >= 1)
                ppArg(term,viz, depth + 1, ","); // separator
            static if (isInputRange!(typeof(subArg)))
            {
                foreach (subsubArg; subArg)
                {
                    ppArgs(term,viz, subsubArg, ",");
                }
            }
        }
    }
    else static if (isInstanceOf!(InBold, Arg))
    {
        if (viz.form == VizForm.html) { ppRaw(term,viz, "<b>"); }
        ppArgs(term,viz, arg.arg);
        if (viz.form == VizForm.html) { ppRaw(term,viz, "</b>"); }
    }
    else static if (isInstanceOf!(InItalic, Arg))
    {
        if (viz.form == VizForm.html) { ppRaw(term,viz, "<i>"); }
        ppArgs(term,viz, arg.arg);
        if (viz.form == VizForm.html) { ppRaw(term,viz, "</i>"); }
    }
    else static if (isInstanceOf!(AsCode, Arg))
    {
        if (viz.form == VizForm.html) { ppRaw(term,viz, "<code>"); }
        ppArgs(term,viz, arg.arg);
        if (viz.form == VizForm.html) { ppRaw(term,viz, "</code>"); }
    }
    else static if (isInstanceOf!(AsEm, Arg))
    {
        if (viz.form == VizForm.html) { ppRaw(term,viz, "<em>"); }
        ppArgs(term,viz, arg.arg);
        if (viz.form == VizForm.html) { ppRaw(term,viz, "</em>"); }
    }
    else static if (isInstanceOf!(AsStrong, Arg))
    {
        if (viz.form == VizForm.html) { ppRaw(term,viz, "<strong>"); }
        ppArgs(term,viz, arg.arg);
        if (viz.form == VizForm.html) { ppRaw(term,viz, "</strong>"); }
    }
    else static if (isInstanceOf!(Header, Arg))
    {
        if (viz.form == VizForm.html) {
            ppArgs(term, viz,
                   "<h" ~ to!string(arg.level) ~ ">",
                   arg.args,
                   "</h" ~ to!string(arg.level) ~ ">\n");
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
            ppArgs(term, viz,
                   "\n", tag, " ", arg.args, " ", tag, "\n");
        }
    }
    else static if (isInstanceOf!(AsUList, Arg))
    {
        if (viz.form == VizForm.html) { ppRaw(term,viz, "<ul>\n"); }
        else if (viz.form == VizForm.latex) { ppRaw(term,viz, "\\begin{enumerate}\n"); }
        ppArgs(term,viz, arg.args);
        if (viz.form == VizForm.html) { ppRaw(term,viz, "</ul>\n"); }
        else if (viz.form == VizForm.latex) { ppRaw(term,viz, "\\end{enumerate}\n"); }
    }
    else static if (isInstanceOf!(AsOList, Arg))
    {
        if (viz.form == VizForm.html) { ppRaw(term,viz, "<ol>\n"); }
        else if (viz.form == VizForm.latex) { ppRaw(term,viz, "\\begin{itemize}\n"); }
        ppArgs(term,viz, arg.args);
        if (viz.form == VizForm.html) { ppRaw(term,viz, "</ol>\n"); }
        else if (viz.form == VizForm.latex) { ppRaw(term,viz, "\\end{itemize}\n"); }
    }
    else static if (isInstanceOf!(AsTable, Arg))
    {
        if (viz.form == VizForm.html) {
            const border = (arg.border ? " border=" ~ arg.border : "");
            ppRaw(term,viz, "<table" ~ border ~ ">\n");
        }
        else if (viz.form == VizForm.latex) { ppRaw(term,viz, "\\begin{tabular}\n"); }
        ppArgs(term,viz, arg.args);
        if (viz.form == VizForm.html) { ppRaw(term,viz, "</table>\n"); }
        else if (viz.form == VizForm.latex) { ppRaw(term,viz, "\\end{tabular}\n"); }
    }
    else static if (isInstanceOf!(AsRow, Arg))
    {
        string spanArg;
        static if (arg.args.length == 1 &&
                   isInstanceOf!(Span, typeof(arg.args[0])))
        {
            spanArg ~= ` rowspan="` ~ to!string(arg._span) ~ `"`;
        }
        if (viz.form == VizForm.html) { ppRaw(term,viz,`<tr` ~ spanArg ~ `>`); }
        ppArgs(term,viz, arg.args);
        if (viz.form == VizForm.html) { ppRaw(term,viz, "</tr>\n"); }
    }
    else static if (isInstanceOf!(AsCell, Arg))
    {
        string spanArg;
        static if (arg.args.length == 1 &&
                   isInstanceOf!(Span, typeof(arg.args[0])))
        {
            spanArg ~= ` colspan="` ~ to!string(arg._span) ~ `"`;
        }
        if (viz.form == VizForm.html) { ppRaw(term,viz,`<td` ~ spanArg ~ `>`); }
        ppArgs(term,viz, arg.args);
        if (viz.form == VizForm.html) { ppRaw(term,viz, "</td>\n"); }
    }
    else static if (isInstanceOf!(AsTHeading, Arg))
    {
        if (viz.form == VizForm.html) { ppRaw(term,viz, "<th>\n"); }
        ppArgs(term,viz, arg.args);
        if (viz.form == VizForm.html) { ppRaw(term,viz, "</th>\n"); }
    }
    else static if (isInstanceOf!(AsItem, Arg))
    {
        if (viz.form == VizForm.html) { ppRaw(term,viz, "<li>"); }
        else if (viz.form == VizForm.textAsciiDoc) { ppRaw(term,viz, " - "); } // if inside ordered list use . instead of -
        else if (viz.form == VizForm.latex) { ppRaw(term,viz, "\\item "); }
        else if (viz.form == VizForm.textAsciiDocUTF8) { ppRaw(term,viz, " • "); }
        ppArgs(term,viz, arg.args);
        if (viz.form == VizForm.html) { ppRaw(term,viz, "</li>\n"); }
        else if (viz.form == VizForm.latex) { ppRaw(term,viz, "\n"); }
        else if (viz.form == VizForm.textAsciiDoc ||
                 viz.form == VizForm.textAsciiDocUTF8) { ppRaw(term,viz, "\n"); }
    }
    else static if (isInstanceOf!(AsPath, Arg))
    {
        auto vizArg = viz;
        vizArg.treeFlag = false;

        import std.traits: isSomeString;
        enum isString = isSomeString!(typeof(arg.arg));

        static if (isString)
            if (viz.form == VizForm.html) { ppRaw(term,viz, "<a href=\"file://" ~ arg.arg ~ "\">"); }

        ppArg(term, vizArg, depth + 1, arg.arg);

        static if (isString)
            if (viz.form == VizForm.html) { ppRaw(term,viz, "</a>"); }
    }
    else static if (isInstanceOf!(AsName, Arg))
    {
        auto vizArg = viz;
        vizArg.treeFlag = true;
        ppArg(term, vizArg, depth + 1, arg.arg);
    }
    else static if (isInstanceOf!(AsHit, Arg))
    {
        const ixs = to!string(arg.ix);
        if (viz.form == VizForm.html) { ppRaw(term,viz, "<hit" ~ ixs ~ ">"); }
        ppArg(term,viz, depth + 1, arg.args);
        if (viz.form == VizForm.html) { ppRaw(term,viz, "</hit" ~ ixs ~ ">"); }
    }
    else static if (isInstanceOf!(AsCtx, Arg))
    {
        const ixs = to!string(arg.ix);
        if (viz.form == VizForm.html) { ppRaw(term,viz, "<hit_context>"); }
        ppArg(term,viz, depth + 1, arg.args);
        if (viz.form == VizForm.html) { ppRaw(term,viz, "</hit_context>"); }
    }
    else static if (__traits(hasMember, arg, "parent")) // TODO: Use isFile = File or NonNull!File
    {
        if (viz.form == VizForm.html) { ppRaw(term,viz, "<a href=\"file://" ~ arg.path ~ "\">"); }

        if (!viz.treeFlag)
        {
            // write parent path
            size_t i = 0;
            foreach (parent; arg.parents)
            {
                ppRaw(term,viz, dirSeparator[0]);
                if (viz.form == VizForm.html) { ppRaw(term,viz, "<b>"); }
                ppPut(term,viz, dirFace, parent.name);
                if (viz.form == VizForm.html) { ppRaw(term,viz, "</b>"); }
            }
            ppRaw(term,viz, dirSeparator[0]);
        }

        // write name
        static if (__traits(hasMember, arg, "isRoot")) // TODO: Use isDir = Dir or NonNull!Dir
        {
            immutable name = arg.isRoot ? dirSeparator : arg.name;
        }
        else
        {
            immutable name = arg.name;
        }

        if (viz.form == VizForm.html)
        {
            static      if (isSymlink!Arg) { ppRaw(term,viz, "<i>"); }
            else static if (isDir!Arg) { ppRaw(term,viz, "<b>"); }
        }

        ppPut(term,viz, arg.getFace(), name);

        if (viz.form == VizForm.html)
        {
            static      if (isSymlink!Arg) { ppRaw(term,viz, "</i>"); }
            else static if (isDir!Arg) { ppRaw(term,viz, "</b>"); }
        }

        if (viz.form == VizForm.html) { ppRaw(term,viz, "</a>"); }
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
        term.setFace(arg.getFace(), viz.colorFlag);
        if (viz.outFile == stdout)
        {
            term.write(arg_string);
        }
        else
        {
            viz.outFile.write(arg_string);
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
void ppArgs(Term, Args...)(ref Term term, Viz viz,
                           Args args) @trusted
{
    foreach (arg; args)
    {
        ppArg(term,viz, 0, arg);
    }
}

/** Pretty-Print Arguments $(D args) to Terminal $(D term) without Line Termination. */
void pp(Term, Args...)(ref Term term,
                       Viz viz,
                       Args args) @trusted
{
    ppArgs(term,viz, args);
    if (viz.outFile == stdout)
    {
        term.flush();
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
}

/** Pretty-Print Arguments $(D args) to Terminal $(D term) including Line Termination. */
void ppln(Term, Args...)(ref Term term, Viz viz, Args args) @trusted
{
    ppArgs(term,viz, args);
    if (viz.outFile == stdout)
    {
        term.writeln(lbr(viz.form == VizForm.html));
        term.flush();
    }
    else
    {
        viz.outFile.writeln(lbr(viz.form == VizForm.html));
    }
}

/** Print End of Line to Terminal $(D term). */
void ppendl(Term)(ref Term term,
                  Viz viz) @trusted
{
    return ppln(term,viz);
}
