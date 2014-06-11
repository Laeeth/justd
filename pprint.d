#!/usr/bin/env rdmd-dev-module

/** Pretty Printing.
    Copyright: Per Nordlöw 2014-.
    License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
    Authors: $(WEB Per Nordlöw)
    TODO: How should std.typecons.Tuple be pretty printed?
    TODO: Add visited member to keeps track of what objects that have been visited
    TODO: Add asGCCMessage pretty prints
          seq($PATH, ':', $ROW, ':', $COL, ':', message, '[', $TYPE, ']'
*/
module pprint;

import std.range: isInputRange;
import std.traits: isInstanceOf, isSomeString, isAggregateType, Unqual, isArray;
import std.stdio: stdout;
import std.conv: to;
import std.path: dirSeparator;
import std.range: map;

import w3c: encodeHTML;
import arsd.terminal; // TODO: Make this optional

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
enum stdFace = face(arsd.terminal.Color.white, arsd.terminal.Color.black);
enum pathFace = face(arsd.terminal.Color.green, arsd.terminal.Color.black, true);

enum dirFace = face(arsd.terminal.Color.blue, arsd.terminal.Color.black, true);
enum fileFace = face(arsd.terminal.Color.magenta, arsd.terminal.Color.black, true);
enum baseNameFace = fileFace;
enum specialFileFace = face(arsd.terminal.Color.red, arsd.terminal.Color.black, true);
enum regFileFace = face(arsd.terminal.Color.white, arsd.terminal.Color.black, true, false, ["b"]);
enum symlinkFace = face(arsd.terminal.Color.cyan, arsd.terminal.Color.black, true, true, ["i"]);
enum symlinkBrokenFace = face(arsd.terminal.Color.red, arsd.terminal.Color.black, true, true, ["i"]);

enum contextFace = face(arsd.terminal.Color.green, arsd.terminal.Color.black);

enum timeFace = face(arsd.terminal.Color.magenta, arsd.terminal.Color.black);
enum digestFace = face(arsd.terminal.Color.yellow, arsd.terminal.Color.black);
enum bytesFace = face(arsd.terminal.Color.yellow, arsd.terminal.Color.black);

enum infoFace = face(arsd.terminal.Color.white, arsd.terminal.Color.black, true);
enum warnFace = face(arsd.terminal.Color.yellow, arsd.terminal.Color.black);
enum kindFace = warnFace;
enum errorFace = face(arsd.terminal.Color.red, arsd.terminal.Color.black);

enum titleFace = face(arsd.terminal.Color.white, arsd.terminal.Color.black, false, false, ["title"]);
enum h1Face = face(arsd.terminal.Color.white, arsd.terminal.Color.black, false, false, ["h1"]);

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
    struct InIt(T...) { T args; } auto inIt(T...)(T args) { return InIt!T(args); }
    /** Bold. */
    struct InBold(T...) { T args; } auto inBold(T...)(T args) { return InBold!T(args); }

    /** Code. */
    struct AsCode(T...) { T args; }
    auto ref asCode(T...)(T args) { return AsCode!T(args); }
    auto ref asKeyword(T...)(T args) { return AsCode!T(args); }

    /** Emphasized. */
    struct AsEm(T...) { T args; } auto ref asEm(T...)(T args) { return AsEm!T(args); }
    /** Strong. */
    struct AsStrong(T...) { T args; } auto ref asStrong(T...)(T args) { return AsStrong!T(args); }
    /** Preformatted. */
    struct AsPre(T...) { T args; } auto ref asPre(T...)(T args) { return AsPre!T(args); }

    /** Scan Hit with Color index $(D ix)). */
    struct AsHit(T...) { uint ix; T args; } auto ref asHit(T)(uint ix, T args) { return AsHit!T(ix, args); }

    /** Scan Hit Context with Color index $(D ix)). */
    struct AsCtx(T...) { uint ix; T args; } auto ref asCtx(T)(uint ix, T args) { return AsCtx!T(ix, args); }

    /** Header. */
    struct AsH(uint Level, T...) { T args; enum level = Level; }
    auto ref asH(uint Level, T...)(T args) { return AsH!(Level, T)(args); }
    /** Paragraph. */
    struct AsP(T...) { T args; } auto ref asP(T...)(T args) { return AsP!T(args); }

    /** Unordered List.
        TODO: Should asUList, asOList autowrap args as AsItems when needed?
    */
    struct AsUList(T...) { T args; } auto ref asUList(T...)(T args) { return AsUList!T(args); }
    /** Ordered List. */
    struct AsOList(T...) { T args; } auto ref asOList(T...)(T args) { return AsOList!T(args); }

    /** Table.
        TODO: Should asTable autowrap args AsRows when needed?
    */
    struct AsTable(T...)
    {
        string border;
        T args;
    }
    auto ref asTable(T...)(T args) { return AsTable!T("\"1\"", args); }

    struct AsCols(T...) { T args; }
    auto ref asCols(T...)(T args) { return AsCols!T(args); }

    /** Row Numbering */
    enum RowNr { none, offsetZero, offsetOne }
    struct AsRows(RowNr N, T...) {
        enum nr = N;
        T args;
    }
    auto ref asRows(RowNr N,
                    T...)(T args) { return AsRows!(N, T)(args); }

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

    const string lbr(bool useHTML) { return (useHTML ? "<br>" : ""); } // line break
}

/** Put $(D arg) to $(D viz) without any conversion nor coloring. */
void ppRaw(Arg)(ref Viz viz,
                Arg arg) @trusted if (isSomeString!Arg)
{
    if (viz.outFile == stdout)
        (*viz.term).write(arg);
    else
        viz.outFile.write(arg);
}

/** Put $(D arg) to $(D viz) possibly with conversion. */
void ppPut(Arg)(ref Viz viz,
                Arg arg) @trusted if (isSomeString!Arg)
{
    if (viz.outFile == stdout)
        (*viz.term).write(arg);
    else
    {
        if (viz.form == VizForm.HTML)
            viz.outFile.write(arg.encodeHTML);
        else
            viz.outFile.write(arg);
    }
}

/** Put $(D arg) to $(D viz) possibly with conversion. */
void ppPut(Arg)(ref Viz viz,
                Face!Color face,
                Arg arg) @trusted if (isSomeString!Arg)
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

void ppTagN(Tag, Args...)(ref Viz viz, in Tag tag, Args args) @trusted if (isSomeString!Tag)
{
    if (viz.form == VizForm.HTML) { viz.ppRaw("<" ~ tag ~ ">"); }
    viz.ppN(args);
    if (viz.form == VizForm.HTML) { viz.ppRaw("</" ~ tag ~ ">"); }
}

void pplnTagN(Tag, Args...)(ref Viz viz, in Tag tag, Args args) @trusted if (isSomeString!Tag)
{
    viz.ppTagN(tag, args);
    viz.ppRaw("\n");
}

/** Pretty-Print Single Argument $(D arg) to Terminal $(D term). */
void pp1(Arg)(ref Viz viz, int depth,
              Arg arg) @trusted
{
    static if (isArray!Arg &&
               !isSomeString!Arg)
    {
        foreach (ix, subArg; arg)
        {
            if (ix >= 1)
                viz.ppRaw(", "); // separator
            viz.pp1(depth + 1, subArg);
        }
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
                viz.ppRaw(" "); // separator
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
    else static if (isInstanceOf!(InBold, Arg))   { viz.ppTagN("b", arg.args); }
    else static if (isInstanceOf!(InIt, Arg))     { viz.ppTagN("i", arg.args); }
    else static if (isInstanceOf!(AsCode, Arg))   { viz.ppTagN("code", arg.args); }
    else static if (isInstanceOf!(AsEm, Arg))     { viz.ppTagN("em", arg.args); }
    else static if (isInstanceOf!(AsStrong, Arg)) { viz.ppTagN("strong", arg.args); }
    else static if (isInstanceOf!(AsH, Arg))
    {
        if (viz.form == VizForm.HTML)
        {
            viz.pplnTagN("h" ~ to!string(arg.level),
                         arg.args);
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
    else static if (isInstanceOf!(AsP, Arg))
    {
        if (viz.form == VizForm.HTML) {
            const level_ = to!string(arg.level);
            viz.pplnTagN("p", arg.args);
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
        if (viz.form == VizForm.HTML) { viz.ppRaw("<ul>\n"); }
        else if (viz.form == VizForm.LaTeX) { viz.ppRaw("\\begin{enumerate}\n"); }
        viz.ppN(arg.args);
        if (viz.form == VizForm.HTML) { viz.ppRaw("</ul>\n"); }
        else if (viz.form == VizForm.LaTeX) { viz.ppRaw("\\end{enumerate}\n"); }
    }
    else static if (isInstanceOf!(AsOList, Arg))
    {
        if (viz.form == VizForm.HTML) { viz.ppRaw("<ol>\n"); }
        else if (viz.form == VizForm.LaTeX) { viz.ppRaw("\\begin{itemize}\n"); }
        viz.ppN(arg.args);
        if (viz.form == VizForm.HTML) { viz.ppRaw("</ol>\n"); }
        else if (viz.form == VizForm.LaTeX) { viz.ppRaw("\\end{itemize}\n"); }
    }
    else static if (isInstanceOf!(AsTable, Arg))
    {
        if (viz.form == VizForm.HTML) {
            const border = (arg.border ? " border=" ~ arg.border : "");
            viz.ppRaw("<table" ~ border ~ ">\n");
        }
        else if (viz.form == VizForm.LaTeX)
        {
            viz.ppRaw("\\begin{tabular}\n");
        }

        static if (arg.args.length == 1 &&
                   isInputRange!(typeof(arg.args[0])))
        {
            viz.pp(arg.args[0].asRows!(RowNr.none));
        }
        else
        {
            viz.ppN(arg.args);
        }

        if (viz.form == VizForm.HTML)
        {
            viz.ppRaw("</table>\n");
        }
        else if (viz.form == VizForm.LaTeX)
        {
            viz.ppRaw("\\end{tabular}\n");
        }
    }
    else static if (isInstanceOf!(AsRows, Arg) &&
                    arg.args.length == 1 &&
                    isInputRange!(typeof(arg.args[0])))
    {
        bool capitalizeHeadings = true;

        /* See also: http://forum.dlang.org/thread/wjksldfpkpenoskvhsqa@forum.dlang.org#post-jwfildowqrbwtamywsmy:40forum.dlang.org */
        // table header
        import std.range: front;
        const first = arg.args[0].front;
        alias Front = typeof(first);
        if (isAggregateType!Front)
        {
            /* TODO: When __traits(documentation,x)
               here https://github.com/D-Programming-Language/dmd/pull/3531
               get merged use it! */
            // viz.pplnTagN("tr", arg_.asCols); // TODO: inIt

            // Use __traits(allMembers, T) instead

            // Can we lookup file and line of user defined types aswell?

            // member names header. TODO: Functionize
            if (viz.form == VizForm.HTML) { viz.ppRaw("<tr>"); }
            foreach (ix, member; first.tupleof)
            {
                enum idName = __traits(identifier, Front.tupleof[ix]);
                import std.string: capitalize;
                viz.pplnTagN("td",
                             (capitalizeHeadings ? idName.capitalize : idName).inIt.inBold);
            }
            if (viz.form == VizForm.HTML) { viz.ppRaw("</tr>"); }

            // member types header. TODO: Functionize
            if (viz.form == VizForm.HTML) { viz.ppRaw("<tr>"); }
            foreach (member; first.tupleof)
            {
                alias Memb = Unqual!(typeof(member));

                enum type_string = Memb.stringof;
                // TODO: Why doesn't this work for builtin types:
                // enum type_string = __traits(identifier, Memb);

                static      if (is(Memb == struct))
                    enum qual_string = "struct ";
                else static if (is(Memb == class))
                    enum qual_string = "class ";
                else
                    enum qual_string = "";

                viz.pplnTagN("td",
                             qual_string.asKeyword,
                             type_string.asCode.inBold);
            }
            if (viz.form == VizForm.HTML) { viz.ppRaw("</tr>\n"); }
        }

        foreach (ix, arg_; arg.args[0])
        {
            // row index
            static      if (arg.nr == RowNr.offsetZero)
                viz.pplnTagN("tr", ix + 0);
            else static if (arg.nr == RowNr.offsetOne)
                viz.pplnTagN("tr", ix + 1);
            // row columns
            viz.pplnTagN("tr", arg_.asCols);
        }
    }
    else static if (isInstanceOf!(AsCols, Arg))
    {
        if (arg.args.length == 1 &&
            isAggregateType!(typeof(arg.args[0])))
        {
            foreach (arg_; arg.args[0].tupleof)
            {
                viz.pplnTagN("td", arg_); // each element in aggregate as a column
            }
        }
        else
        {
            viz.pplnTagN("tr", arg.args);
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
        if (viz.form == VizForm.HTML) { viz.ppRaw(`<tr` ~ spanArg ~ `>`); }
        viz.ppN(arg.args);
        if (viz.form == VizForm.HTML) { viz.ppRaw("</tr>\n"); }
    }
    else static if (isInstanceOf!(AsCell, Arg))
    {
        string spanArg;
        static if (arg.args.length == 1 &&
                   isInstanceOf!(Span, typeof(arg.args[0])))
        {
            spanArg ~= ` colspan="` ~ to!string(arg._span) ~ `"`;
        }
        if (viz.form == VizForm.HTML) { viz.ppRaw(`<td` ~ spanArg ~ `>`); }
        viz.ppN(arg.args);
        if (viz.form == VizForm.HTML) { viz.ppRaw("</td>\n"); }
    }
    else static if (isInstanceOf!(AsTHeading, Arg))
    {
        if (viz.form == VizForm.HTML) { viz.ppRaw("<th>\n"); }
        viz.ppN(arg.args);
        if (viz.form == VizForm.HTML) { viz.ppRaw("</th>\n"); }
    }
    else static if (isInstanceOf!(AsItem, Arg))
    {
        if (viz.form == VizForm.HTML) { viz.ppRaw("<li>"); }
        else if (viz.form == VizForm.textAsciiDoc) { viz.ppRaw(" - "); } // if inside ordered list use . instead of -
        else if (viz.form == VizForm.LaTeX) { viz.ppRaw("\\item "); }
        else if (viz.form == VizForm.textAsciiDocUTF8) { viz.ppRaw(" • "); }
        viz.ppN(arg.args);
        if (viz.form == VizForm.HTML) { viz.ppRaw("</li>\n"); }
        else if (viz.form == VizForm.LaTeX) { viz.ppRaw("\n"); }
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
            if (viz.form == VizForm.HTML)
            {
                viz.ppRaw("<a href=\"file://" ~ arg.arg ~ "\">");
            }

        pp1(vizArg, depth + 1, arg.arg);

        static if (isString)
            if (viz.form == VizForm.HTML) {
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
        if (viz.form == VizForm.HTML) { viz.ppRaw("<hit" ~ ixs ~ ">"); }
        viz.pp1(depth + 1, arg.args);
        if (viz.form == VizForm.HTML) { viz.ppRaw("</hit" ~ ixs ~ ">"); }
    }
    else static if (isInstanceOf!(AsCtx, Arg))
    {
        const ixs = to!string(arg.ix);
        if (viz.form == VizForm.HTML) { viz.ppRaw("<hit_context>"); }
        viz.pp1(depth + 1, arg.args);
        if (viz.form == VizForm.HTML) { viz.ppRaw("</hit_context>"); }
    }
    else static if (__traits(hasMember, arg, "parent")) // TODO: Use isFile = File or NonNull!File
    {
        if (viz.form == VizForm.HTML) {
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
                if (viz.form == VizForm.HTML) { viz.ppRaw("<b>"); }
                viz.ppPut(dirFace, parent.name);
                if (viz.form == VizForm.HTML) { viz.ppRaw("</b>"); }
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
            static      if (isSymlink!Arg) { viz.ppRaw("<i>"); }
            else static if (isDir!Arg) { viz.ppRaw("<b>"); }
        }

        viz.ppPut(arg.getFace(), name);

        if (viz.form == VizForm.HTML)
        {
            static      if (isSymlink!Arg) { viz.ppRaw("</i>"); }
            else static if (isDir!Arg) { viz.ppRaw("</b>"); }
        }

        if (viz.form == VizForm.HTML) { viz.ppRaw("</a>"); }
    }
    else
    {
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
            if (viz.form == VizForm.HTML)
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
            viz.ppPut(arg.getFace(), arg_string);
        }

        static if (__traits(hasMember, arg, "face") &&
                   __traits(hasMember, arg.face, "tagsHTML")) {
            if (viz.form == VizForm.HTML)
            {
                foreach (tag; arg.face.tagsHTML)
                {
                    viz.outFile.write("</", tag, ">");
                }
            }
        }
    }
}

/** Pretty-Print Multiple Arguments $(D args) to Terminal $(D term). */
void ppN(Args...)(ref Viz viz,
                  Args args) @trusted
{
    foreach (arg; args)
    {
        viz.pp1(0, arg);
    }
}

/** Pretty-Print Arguments $(D args) to Terminal $(D term) without Line Termination. */
void pp(Args...)(ref Viz viz,
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
               HTML,
               LaTeX }

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
void ppln(Args...)(ref Viz viz, Args args) @trusted
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
void pplns(Args...)(ref Viz viz, Args args) @trusted
{
    foreach (arg; args)
    {
        viz.ppln(args);
    }
}

/** Print End of Line to Terminal $(D term). */
void ppendl(ref Viz viz) @trusted
{
    return viz.ppln("");
}
