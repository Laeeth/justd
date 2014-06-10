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

import w3c;
import arsd.terminal;

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
