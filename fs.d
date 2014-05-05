#!/usr/bin/env rdmd-release

/**
   File Scanning Engine.

   Make rich use of Sparse Distributed Representations (SDR) using Hash Digests
   for relating Data and its Relations/Properties/Meta-Data.

   See also: http://stackoverflow.com/questions/12629749/how-does-grep-run-so-fast
   See also: http:www.regular-expressions.info/powergrep.html
   See also: http://ridiculousfish.com/blog/posts/old-age-and-treachery.html
   See also: http://www.olark.com/spw/2011/08/you-can-list-a-directory-with-8-million-files-but-not-with-ls/

   Example:
   ---
   ~/cognia/fs.d -d /etc --color alpha
   ---

   TODO: Maybe make use of https://github.com/Abscissa/scriptlike

   TODO: Calculate Tree grams and bist

   TODO: Get stats of the link itself not the target in SymLink constructors

   TODO: RegFile with FileContent.text should be decodable to Unicode using
   either iso-latin1, utf-8, etc. Check std.uni for how to try and decode stuff.

   TODO: Search for subwords.
   For example gtk_widget should also match widget_gtk and GtkWidget etc.

   TODO: Support multi-line keys

   TODO: Use hash-lookup in extSrcKinds for faster guessing of source file
   kind. Merge it with binary kind lookup. And check FileContent member of
   kind to instead determine if it should be scanned or not.
   Sub-Task: Case-Insensitive Matching of extensions if
   nothing else passes.

   TODO: Detect symlinks with duplicate targets and only follow one of them and
   group them together in visualization

   TODO: Add addTag, removeTag, etc and interface to fs.d for setting tags:
   --add-tag=comedy, remove-tag=comedy

   TODO: If files ends with ~ or .backup assume its a backup file, strip it from
   end match it again and set backupFlag in FileKind

   TODO: Acronym match can make use of normal histogram counts. Check denseness
   of binary histogram (bist) to determine if we should use a sparse or dense
   histogram.

   TODO: Activate and test support for ELF and Cxx11 subkinds

   TODO: Call either File.checkObseleted upon inotify. checkObseleted should remove stuff from hash tables
   TODO: Integrate logic in clearCStat to RegFile.makeObselete
   TODO: Upon Dir inotify call invalidate _depth, etc.

   TODO: Following command: fs.d --color -d ~/ware/emacs -s lispy  -k
   shows "Skipped PNG file (png) at first extension try".
   Assure that this logic reuses cache and instead prints something like "Skipped PNG file using cached FKind".

   TODO: Cache each Dir separately to a file named after SHA1 of its path

   TODO: Add ASCII kind: Requires optional stream analyzer member of FKind in
   replacement for magicData. ASCIIFile

   TODO: Search for CFile and add peg parsing of C files

   TODO: Defined NotAnyKind(binaryKinds) and cache it

   TODO: Create PkZipFile() in Dir.load() when FKind "pkZip Archive" is found.
   Use std.zip.ZipArchive(void[] from mmfile)

   TODO: Parse using Pegged and cache ASTs.

   TODO: Scan Subversion Dirs with http://pastebin.com/6ZzPvpBj

   TODO: Change order (binFlag || allBHist8Miss) and benchmark

   TODO: Display modification/access times as:
   See: http://forum.dlang.org/thread/k7afq6$2832$1@digitalmars.com

   TODO: Use User Defined Attributes (UDA): http://forum.dlang.org/thread/k7afq6$2832$1@digitalmars.com
   TODO: Use msgPack @nonPacked when needed

   TODO: Limit lines to terminal width

   TODO: Create array of (OFFSET, LENGTH) and this in FKind Pattern factory
   function.  Then for source file extra slice at (OFFSET, LENGTH) and use as
   input into hash-table from magic (if its a Lit-pattern to)
   TODO: Verify that "f.tar.z" gets tuple extensions tuple("tar", "z")
   TODO: Verify that "libc.so.1.2.3" gets tuple extensions tuple("so", "1", "2", "3") and "so" extensions should the be tried
   TODO: Cache Symbols larger than three characters in a global hash from symbol to path

   TODO: Benchmark horspool.d and perhaps use instead of std.find

   TODO: Splitting into keys should not split arguments such as "a b"

   TODO: Use binFKindsByMagic and binFKindsMagicLengths

   TODO: Sort Access and Modification times of subs in a Dir and msgpack them
   differentially as two arrays. Use http://rosettacode.org/wiki/Forward_difference#D

   TODO: Perhaps use http://www.chartjs.org/ to visualize stuff

   TODO: Make use of @nonPacked in version(msgpack).
*/
module fs;

version = msgpack; // Use cerealed serialization

import std.stdio: ioFile = File, stdout;
import std.typecons: Tuple, tuple;
import std.algorithm: find, map, filter, reduce, max, min, uniq, all;
import std.string: representation;
import std.stdio: write, writeln;
import std.path: baseName, dirName, isAbsolute, dirSeparator;
import std.datetime;
import std.file: FileException;
import std.digest.sha: sha1Of, toHexString;
import std.range: repeat, array, empty;
import std.stdint: uint64_t;
import std.traits: Unqual;
import core.memory: GC;
import core.exception;

import assert_ex;
import traits_ex;
import getopt_ex;
import digest_ex;
import algorithm_ex;
import codec;
import csunits;
alias Bytes64 = Bytes!ulong;
import terminal;
import sregex;
import english;
import bitset;
import dbg;
/* import backtrace.backtrace; */
import tempfs;
import rational: Rational;
import ngram;
import notnull;
import elf;
import allocator;

/* NGram Aliases */
/** Not very likely that we are interested in histograms 64-bit precision
 * Bucket/Bin Counts so pick 32-bit for now. */
alias RequestedBinType = uint;
enum NGramOrder = 3;
alias Bist  = NGram!(ubyte, 1, ngram.Kind.binary, ngram.Storage.denseStatic, ngram.Symmetry.ordered, void, immutable(ubyte)[]);
alias XGram = NGram!(ubyte, NGramOrder, ngram.Kind.saturated, ngram.Storage.sparse, ngram.Symmetry.ordered, RequestedBinType, immutable(ubyte)[]);

// Pegged
import pegged.peg;
/* import pegged.grammar; */
/* import pegged.examples.c; */
/* mixin(grammar(Cgrammar)); */
/* import pegged.dynamic.peg; */

/* Need for signal handling */
import std.c.stdlib;
version(linux) import std.c.linux.linux;
/* TODO: Set global state.
   http://forum.dlang.org/thread/cu9fgg$28mr$1@digitaldaemon.com
*/
/** Exception Describing Process Signal. */

shared uint ctrlC = 0; // Number of times Ctrl-C has been presed
class SignalCaughtException : Exception
{
    int signo = int.max;
    this(int signo, string file = __FILE__, size_t line = __LINE__ ) @safe {
        this.signo = signo;
        import std.conv: to;
        super("Signal number " ~ to!string(signo) ~ " at " ~ file ~ ":" ~ to!string(line));
    }
}

void signalHandler(int signo)
{
    if (signo == 2) { ++ctrlC; }
    // throw new SignalCaughtException(signo);
}

alias signalHandler_t = void function(int);
extern (C) signalHandler_t signal(int signal, signalHandler_t handler);

version(msgpack) {
    import msgpack;
}
version(cerealed) {
    /* import cerealed.cerealiser; */
    /* import cerealed.decerealiser; */
    /* import cerealed.cereal; */
}

/** Returns: Duration $(D dur) in a Level-Of-Detail (LOD) string
    representation.
*/
string shortDurationString(in Duration dur) @safe pure
{
    import std.conv: to;
    immutable weeks = dur.weeks;     if (weeks) {
        if (weeks < 52) {
            return to!string(weeks) ~ " week" ~ (weeks >= 2 ? "s" : "");
        } else {
            immutable years = weeks / 52;
            immutable weeks_rest = weeks % 52;
            return to!string(years) ~ " year" ~ (years >= 2 ? "s" : "") ~
                " and " ~
                to!string(weeks_rest) ~ " week" ~ (weeks_rest >= 2 ? "s" : "");
        }
    }
    immutable days = dur.days;       if (days)    return to!string(days) ~ " day" ~ (days >= 2 ? "s" : "");
    immutable hours = dur.hours;     if (hours)   return to!string(hours) ~ " hour" ~ (hours >= 2 ? "s" : "");
    immutable minutes = dur.minutes; if (minutes) return to!string(minutes) ~ " minute" ~ (minutes >= 2 ? "s" : "");
    immutable seconds = dur.seconds; if (seconds) return to!string(seconds) ~ " second" ~ (seconds >= 2 ? "s" : "");
    immutable frac = dur.fracSec;
    immutable msecs = frac.msecs; if (msecs) return to!string(msecs) ~ " millisecond" ~ (msecs >= 2 ? "s" : "");
    immutable usecs = frac.usecs; if (usecs) return to!string(usecs) ~ " microsecond" ~ (msecs >= 2 ? "s" : "");
    immutable nsecs = frac.nsecs; return to!string(nsecs) ~ " nanosecond" ~ (msecs >= 2 ? "s" : "");
}

/** Returns: Default Documentation String for value $(D a) of for Type $(D T). */
string defaultDoc(T)(in T a) @safe pure
{
    import std.conv: to;
    return (" (type:" ~ T.stringof ~
            ", default:" ~ to!string(a) ~
            ").") ;
}

/** Returns: Documentation String for Enumeration Type $(D EnumType). */
string enumDoc(EnumType, string separator = "|")() @safe pure nothrow
{
    /* import std.traits: EnumMembers; */
    /* return EnumMembers!EnumType.join(separator); */
    /* auto subsSortingNames = EnumMembers!EnumType; */
    auto x = (__traits(allMembers, EnumType));
    string doc = "";
    /* import std.algorithm: joiner; */
    /* return joiner(x, separator); */
    /* debug dln(typeof(x).stringof); */
    foreach (ix, name; x) {
        if (ix >= 1) { doc ~= separator; }
        doc ~= name;
    }
    return doc;
}

struct Face(Color)
{
    this(Color fg, Color bg, bool bright)
    {
        this.fg = fg;
        this.bg = bg;
        this.bright = bright;
    }
    Color fg;
    Color bg;
    bool bright;
}

Face!Color face(Color)(Color fg, Color bg, bool bright = false) { return Face!Color(fg, bg, bright); }

/** File Content Type Code. */
enum FileContent
{
    unknown,
    binaryUnknown,
    binary,
    text,
    textASCII,
    text8Bit,
    document,
    spreadsheet,
    database,
    tagsDatabase,
    image,
    audio,
    sound = audio,
    music = audio,
    video,
    movie,
    media,
    sourceCode,
    scriptCode,
    byteCode,
    machineCode,
    versionControl,
    numericalData,
    archive,
    compressed,
    cache,
    binaryCache,
    firmware,
    spellCheckWordList,
    font,
    performanceBenchmark,
    fingerprint,
}

/** How File Kinds are detected. */
enum FileKindDetection
{
    equalsName, // Only name must match
    equalsNameAndContents, // Both name and contents must match
    equalsNameOrContents, // Either name or contents must match
    equalsContents, // Only contents must match
    equalsWhatsGiven, // All information defined must match
}

/** Key Scan (Search) Context. */
enum ScanContext
{
    /* code, */
    /* comment, */
    /* string, */

    /* word, */
    /* symbol, */

    dirName,     // Name of directory being scanned.
    dir = dirName,

    fileName,    // Name of file being scanned.
    name = fileName,

    regularFileName,    // Name of file being scanned.
    symlinkName, // Name of symbolic linke being scanned.

    fileContent, // Contents of file being scanned.
    content = fileContent,

    /* modTime, */
    /* accessTime, */
    /* xattr, */
    /* size, */

    all,
    standard = all,
}

enum DuplicatesContext
{
    internal, // All duplicates must lie inside topDirs
    external, // At least one duplicate lie inside
    // topDirs. Others may lie outside
}

/** File Operation Type Code. */
enum FileOp
{
    checkSyntax, lint = checkSyntax,
    compile,
    run,

    /* VCS Operations */
    status,
}

/** Directory Operation Type Code. */
enum DirOp
{
    /* VCS Operations */
    status,
}

/** Shell Command.
 */
alias ShCmd = string;

/** Pair of Delimiters.
    Used to desribe for example comment and string delimiter syntax.
 */
struct Delim
{
    this(string intro)  {
        this.intro = intro;
        this.finish = finish.init;
    }
    this(string intro, string finish)  {
        this.intro = intro;
        this.finish = finish;
    }
    string intro;
    string finish; // Defaults to end of line if not defined.
}
unittest {
    const d = Delim("#", []);
    const e = Delim("#", null);
}

enum cCommentDelims = [Delim("/*", "*/"),
                       Delim("//")];
enum defaultCommentDelims = [Delim("#")];
enum defaultStringDelims = [Delim("\""), Delim("'"), Delim("`")];

/** File Kind.
 */
class FKind
{
    this(T, MagicData, RefPattern)(string kindName_,
                                   T baseNaming_,
                                   string[] typExts_,
                                   MagicData magicData, size_t magicOffset = 0,
                                   RefPattern refPattern_ = RefPattern.init,
                                   string[] keywords_ = [],

                                   Delim[] strings_ = [],
                                   Delim[] comments_ = [],

                                   FileContent content_ = FileContent.unknown,
                                   FileKindDetection detection_ = FileKindDetection.equalsWhatsGiven,
                                   FKind superKind = null,
                                   FKind[] subKinds = [],
                                   string description = null,
                                   string wikiURL = null) @trusted pure
    {
        this.kindName = kindName_;

        // Basename
        import std.traits: isArray;
        import std.range: ElementType;
        static if (is(T == string)) {
            this.baseNaming = lit(baseNaming_);
        } else static if (isArrayOf!(T, string)) {
            // TODO: Move to a factory function strs(x)
            auto alt_ = alt();
            foreach (ext; baseNaming_) { // add each string as an alternative
                alt_.alts ~= lit(ext);
            }
            this.baseNaming = alt_;
        } else static if (is(T == Patt)) {
            this.baseNaming = baseNaming_;
        }

        this.exts = typExts_;

        import std.traits: isAssignable;
        static      if (is(MagicData == ubyte[])) { this.magicData = lit(magicData) ; }
        else static if (is(MagicData == string)) { this.magicData = lit(magicData.representation.dup); }
        else static if (is(MagicData == void[])) { this.magicData = lit(cast(ubyte[])magicData); }
        else static if (isAssignable!(Patt, MagicData)) { this.magicData = magicData; }
        else static assert(false, "Cannot handle MagicData being type " ~ MagicData.stringof);

        this.magicOffset = magicOffset;

        static      if (is(RefPattern == ubyte[])) { this.refPattern = refPattern_; }
        else static if (is(RefPattern == string)) { this.refPattern = refPattern_.representation.dup; }
        else static if (is(RefPattern == void[])) { this.refPattern = (cast(ubyte[])refPattern_).dup; }
        else static assert(false, "Cannot handle RefPattern being type " ~ RefPattern.stringof);

        this.keywords = keywords_;

        this.strings = strings_;
        this.comments = comments_;

        this.content = content_;

        if ((content_ == FileContent.sourceCode ||
             content_ == FileContent.scriptCode) &&
            detection_ == FileKindDetection.equalsWhatsGiven) {
            // relax matching of sourcecode to only need name until we have complete parsers
            this.detection = FileKindDetection.equalsName;
        } else {
            this.detection = detection_;
        }

        this.superKind = superKind;
        this.subKinds = subKinds;
        this.description = description;
        this.wikiURL = wikiURL;
    }

    /** Returns: Id Unique to matching behaviour of $(D this) FKind. If match
        behaviour of $(D this) FKind changes returned id will change.
        value is memoized.
        TODO: Make pure when msgpack.pack is made pure.
    */
    auto ref const(SHA1Digest) behaviorId() @property @safe
        out(result) { assert(!result.empty); }
    body
    {
        if (_behaviourDigest.empty) { // if not yet defined
            ubyte[] bytes;
            if (const magicLit = cast(Lit)magicData)
                bytes = msgpack.pack(exts, magicLit.bytes, magicOffset, refPattern, keywords, content, detection);
            else
                dln("warning: Handle magicData of type ", kindName);
                bytes = msgpack.pack(exts, cast(ubyte[])[], magicOffset, refPattern, keywords, content, detection);
            _behaviourDigest = bytes.sha1Of;
        }
        return _behaviourDigest;
    }

    string kindName;    // Kind Nick Name.
    string description; // Kind Documenting Description.
    string wikiURL; // Wikipedia URL

    FKind superKind;    // Inherited pattern. For example ELF => ELF core file
    FKind[] subKinds;   // Inherited pattern. For example ELF => ELF core file
    Patt baseNaming;    // Pattern that matches typical file basenames of this Kind. May be null.

    string[] exts;      // Typical Extensions.
    Patt magicData;     // Magic Data.
    size_t magicOffset; // Magit Offset.
    ubyte[] refPattern; // Reference pattern.
    const FileContent content;
    const FileKindDetection detection;

    // Volatile Statistics:
    private SHA1Digest _behaviourDigest;
    RegFile[] hitFiles;     // Files of this kind.

    string[] keywords; // Keywords

    /* TODO: Move this to CompLang class */
    Delim[] strings; // String syntax.
    Delim[] comments; // Comment syntax.

    bool machineGenerated;

    Tuple!(FileOp, ShCmd)[] ops; // Operation and Corresponding Shell Command
}

/** Match $(D kind) with full filename $(D full). */
bool matchFullName(in FKind kind,
                   in string full, size_t six = 0) @safe pure nothrow
{
    /* debug dln("kind:", kind.kindName); */
    return (kind.baseNaming &&
            !kind.baseNaming.match(full, six).empty);
}

/** Match $(D kind) with file extension $(D ext). */
bool matchExtension(in FKind kind,
                    in string ext) @safe pure nothrow
{
    return !kind.exts.find(ext).empty;
}

bool matchName(in FKind kind,
               in string full, size_t six = 0,
               in string ext = null) @safe pure nothrow
{
    /* debug dln("kind:", kind.kindName); */
    return (kind.matchFullName(full) ||
            kind.matchExtension(ext));
}

/** Match (Magic) Contents of $(D kind) with $(D range).
    Returns: true iff match. */
bool matchContents(Range)(in FKind kind,
                          in Range range,
                          in RegFile regfile) pure nothrow if (hasSlicing!Range)
{
    const hit = kind.magicData.matchU(range, kind.magicOffset);
    /* debug dln("kind:", kind.kindName,  ", range.length:", hit.length); */
    return (!hit.empty);
}

enum KindHit
{
    none = 0,     // No hit.
    cached = 1,   // Cached hit.
    uncached = 2, // Uncached (fresh) hit.
}

/** Returns: true if file with extension $(D ext) is of type $(D kind). */
KindHit ofKind(NotNull!RegFile regfile,
               in string ext,
               NotNull!FKind kind,
               bool collectTypeHits,
               const ref FKind[SHA1Digest] allKindsById) /* nothrow */ @safe
{
    // Try cached first
    /* debug dln("", kind.kindName, " ", regfile.name, " ", kind.detection); */

    if (regfile._cstat.kindId.defined &&
        (regfile._cstat.kindId in allKindsById) && // if kind is known
        allKindsById[regfile._cstat.kindId] is kind) { // if cached kind equals
        /* dln(regfile.path, " cached kind detected as ", kind.kindName); */
        return KindHit.cached;
    }

    if (kind.superKind) {
        immutable baseHit = regfile.ofKind(ext,
                                           enforceNotNull(kind.superKind),
                                           collectTypeHits,
                                           allKindsById);
        if (!baseHit) {
            return baseHit;
        }
    }

    bool hit = false;
    final switch (kind.detection) {
    case FileKindDetection.equalsName:
        hit = kind.matchName(regfile.name, 0, ext);
        break;
    case FileKindDetection.equalsNameAndContents:
        hit = (kind.matchName(regfile.name, 0, ext) &&
               kind.matchContents(regfile.readOnlyContents, regfile));
        break;
    case FileKindDetection.equalsNameOrContents:
        hit = (kind.matchName(regfile.name, 0, ext) ||
               kind.matchContents(regfile.readOnlyContents, regfile));
        break;
    case FileKindDetection.equalsContents:
        hit = kind.matchContents(regfile.readOnlyContents, regfile);
        /* dln("path:", regfile.path, ", kind.name: ", kind.kindName, " hit.length:", hit, " magicData.length: ", kind.magicData.length); */
        break;
    case FileKindDetection.equalsWhatsGiven:
        // something must be defined
        assert(is(kind.baseNaming) ||
               !kind.exts.empty ||
               !(kind.magicData is null));
        hit = ((kind.matchName(regfile.name, 0, ext) &&
                (kind.magicData is null ||
                 kind.matchContents(regfile.readOnlyContents, regfile))));
        break;
    }
    if (hit) {
        if (collectTypeHits) {
            kind.hitFiles ~= regfile;
        }
        regfile._cstat.kindId = kind.behaviorId;       // store reference in File
    }

    return hit ? KindHit.uncached : KindHit.none;
}

/** Directory Kind.
 */
class DirKind
{
    this(string fn,
         string kn) {
        this.fileName = fn;
        this.kindName = kn;
    }

    version(msgpack)
    {
        this(Unpacker)(ref Unpacker unpacker) {
            fromMsgpack(msgpack.Unpacker(unpacker));
        }
        void toMsgpack(Packer)(ref Packer packer) const {
            packer.beginArray(this.tupleof.length);
            packer.pack(this.tupleof);
        }
        void fromMsgpack(Unpacker)(auto ref Unpacker unpacker) {
            unpacker.beginArray();
            unpacker.unpack(this.tupleof);
        }
    }

    string fileName;
    string kindName;
}
version(msgpack) unittest
{
    auto k = tuple("", "");
    auto data = pack(k);
    Tuple!(string, string) k_; data.unpack(k_);
    assert(k == k_);
}

import std.file: DirEntry, getLinkAttributes;
import std.datetime: SysTime, Interval;

/** File.
 */
class File
{
    this(Dir parent) { this.parent = parent;
        if (parent) { ++parent.gstats.noFiles; }
    }
    this(string name, Dir parent, Bytes64 size,
         SysTime timeLastModified,
         SysTime timeLastAccessed) {
        this.name = name;
        this.parent = parent;
        this.size = size;
        this.timeLastModified = timeLastModified;
        this.timeLastAccessed = timeLastAccessed;
        if (parent) { ++parent.gstats.noFiles; }
    }

    Bytes64 treeSize() @property @trusted /* @safe pure nothrow */ { return size; }

    /** Content Digest of Tree under this Directory. */
    const(SHA1Digest) treeContId() @property @trusted /* @safe pure nothrow */
    {
        return typeof(return).init;
    }

    Face!Color face() @property @safe pure nothrow { return fileFace; }

    /** Returns: Depth of Depth from File System root to this File. */
    int depth() @property @safe pure nothrow { return parent ? parent.depth + 1 : 0; }

    /** Check if $(D this) File has been invalidated by $(D dent).
        Returns: true iff $(D this) was obseleted.
    */
    bool checkObseleted(ref DirEntry dent) @trusted
    {
        // Git-Style Check for Changes (called Decider in SCons Build Tool)
        bool flag = false;
        if (dent.size != this.size || // size has changes
            (dent.timeLastModified != this.timeLastModified) // if current modtime has changed or
            ) {
            makeObselete();
            this.timeLastModified = dent.timeLastModified; // use new time
            this.size = dent.size; // use new time
            flag = true;
        }
        this.timeLastAccessed = dent.timeLastAccessed; // use new time
        return flag;
    }

    void makeObselete() @trusted {}
    void makeUnObselete() @safe {}

    /** Returns: Path to $(D this) File. */
    string path() @property @trusted pure out (result) {
        /* assertEqual(result, pathRecursive); */
    }
    body
    {
        if (!parent) { return dirSeparator; }

        Dir[] parents; // collected parents
        auto currParent = parent;
        size_t pathLength = 1 + name.length; // returned path length
        size_t j = 0;
        while (currParent !is null && !currParent.isRoot) {
            pathLength += 1;
            pathLength += currParent.name.length;
            parents ~= currParent;
            currParent = currParent.parent;
            ++j;
        }

        // build path
        auto path_ = new char[pathLength];
        size_t i = 0;
        import std.range: retro;
        foreach (currParent_; parents.retro) {
            immutable parentName = currParent_.name;
            path_[i++] = dirSeparator[0];
            path_[i .. i + parentName.length] = parentName[];
            i += parentName.length;
        }
        path_[i++] = dirSeparator[0];
        path_[i .. i + name.length] = name[];

        return path_;

    }

    /** Returns: Path to $(D this) File.
        Recursive Heap-active implementation.
    */
    string pathRecursive() @property @trusted pure
    {
        if (parent) {
            static if (true) {
                import std.path: dirSeparator;
                // NOTE: This is more efficient than buildPath(parent.path,
                // name) because we can guarantee things about parent.path and
                // name
                immutable parentPath = parent.isRoot ? "" : parent.pathRecursive;
                return parentPath ~ dirSeparator ~ name;
            } else {
                import std.path: buildPath;
                return buildPath(parent.pathRecursive, name);
            }
        } else {
            return "/";  // assume root folder with beginning slash
        }
    }

    version(msgpack)
    {
        void toMsgpack(Packer)(ref Packer packer) const
        {
            writeln("Entering File.toMsgpack ", name);
            packer.pack(name, size, timeLastModified.stdTime, timeLastAccessed.stdTime);
        }
        void fromMsgpack(Unpacker)(auto ref Unpacker unpacker)
        {
            long stdTime;
            unpacker.unpack(stdTime); timeLastModified = SysTime(stdTime); // TODO: Functionize
            unpacker.unpack(stdTime); timeLastAccessed = SysTime(stdTime); // TODO: Functionize
        }
    }

    Dir parent; // reference to parenting directory (or null if this is a root directory).
    string name; // Empty if root directory.
    Bytes64 size; // Size of file in bytes.
    SysTime timeLastModified;
    SysTime timeLastAccessed;
}

/** Maps Files to their tags. */
class FileTags
{
    FileTags addTag(File file, in string tag) @safe pure /* nothrow */
    {
        if (file in _tags) {
            if (_tags[file].find(tag).empty) {
                _tags[file] ~= tag; // add it
            }
        }
        else {
            _tags[file] = [tag];
        }
        return this;
    }
    FileTags removeTag(File file, string tag) @safe pure
    {
        if (file in _tags) {
            import std.algorithm: remove;
            _tags[file] = _tags[file].remove!(a => a == tag);
        }
        return this;
    }
    auto ref getTags(File file) const @safe pure nothrow
    {
        return file in _tags ? _tags[file] : null;
    }
    private string[][File] _tags; // Tags for each registered file.
}

version(linux) unittest
{
    auto ftags = new FileTags();
    GStats gstats = new GStats();
    auto root = assumeNotNull(new Dir(cast(Dir)null, gstats));
    auto etc = getDir(root, "/etc");
    assert(etc.path == "/etc");
    auto dent = DirEntry("/etc/passwd");
    auto passwd = getFile(root, "/etc/passwd", dent);
    assert(passwd.path == "/etc/passwd");
    assert(passwd.parent == etc);
    assert(etc.sub("passwd") == passwd);

    ftags.addTag(passwd, "Password");
    ftags.addTag(passwd, "Password");
    ftags.addTag(passwd, "Secret");
    assert(ftags.getTags(passwd) == ["Password", "Secret"]);
    ftags.removeTag(passwd, "Password");
    assert(ftags._tags[passwd] == ["Secret"]);
}

/** Symlink.
 */
class Symlink : File {
    this(NotNull!Dir parent) {
        super(parent);
        ++parent.gstats.noSymlinks;
    }
    this(ref DirEntry dent, NotNull!Dir parent) {
        Bytes64 sizeBytes;
        SysTime modified, accessed;
        bool ok = true;
        try {
            sizeBytes = dent.size.Bytes64;
            modified = dent.timeLastModified;
            accessed = dent.timeLastAccessed;
        } catch (Exception) {
            ok = false;
        }
        // const attrs = getLinkAttributes(dent.name); // attributes of target file
        // super(dent.name.baseName, parent, 0.Bytes64, cast(SysTime)0, cast(SysTime)0);
        super(dent.name.baseName, parent, sizeBytes, modified, accessed);
        if (ok) {
            this.retarget(dent); // trigger lazy load
        }
        ++parent.gstats.noSymlinks;
    }

    override Face!Color face() @property @safe pure nothrow { return symlinkFace; }

    string retarget(ref DirEntry dent) @trusted
    {
        import std.file: readLink;
        return _target = readLink(dent);
    }

    /** Cached/Memoized/Lazy Lookup for target. */
    string target() @property @trusted {
        if (!_target) {         // if target not yet read
            auto targetDent = DirEntry(path);
            return retarget(targetDent); // read it
        }
        return _target;
    }
    /** Cached/Memoized/Lazy Lookup for target as absolute normalized path. */
    string absoluteNormalizedTargetPath() @property @trusted
    {
        import std.path: absolutePath, buildNormalizedPath;
        return target.absolutePath(path.dirName).buildNormalizedPath;
    }

    version(msgpack) {
        /** Construct from msgpack $(D unpacker).  */
        this(Unpacker)(ref Unpacker unpacker) {
            fromMsgpack(msgpack.Unpacker(unpacker));
        }
        void toMsgpack(Packer)(ref Packer packer) const {
            /* writeln("Entering File.toMsgpack ", name); */
            packer.pack(name, size, timeLastModified.stdTime, timeLastAccessed.stdTime);
        }
        void fromMsgpack(Unpacker)(auto ref Unpacker unpacker) {
            unpacker.unpack(name, size);
            long stdTime;
            unpacker.unpack(stdTime); timeLastModified = SysTime(stdTime); // TODO: Functionize
            unpacker.unpack(stdTime); timeLastAccessed = SysTime(stdTime); // TODO: Functionize
        }
    }

    string _target;
}

/** Special File (Character or Block Device).
 */
class SpecialFile : File {
    this(NotNull!Dir parent) {
        super(parent);
        ++parent.gstats.noSpecialFiles;
    }
    this(ref DirEntry dent, NotNull!Dir parent) {
        super(dent.name.baseName, parent, 0.Bytes64, cast(SysTime)0, cast(SysTime)0);
        ++parent.gstats.noSpecialFiles;
    }

    override Face!Color face() @property @safe pure nothrow { return specialFileFace; }

    version(msgpack) {
        /** Construct from msgpack $(D unpacker).  */
        this(Unpacker)(ref Unpacker unpacker) {
            fromMsgpack(msgpack.Unpacker(unpacker));
        }
        void toMsgpack(Packer)(ref Packer packer) const {
            /* writeln("Entering File.toMsgpack ", name); */
            packer.pack(name, size, timeLastModified.stdTime, timeLastAccessed.stdTime);
        }
        void fromMsgpack(Unpacker)(auto ref Unpacker unpacker) {
            unpacker.unpack(name, size);
            long stdTime;
            unpacker.unpack(stdTime); timeLastModified = SysTime(stdTime); // TODO: Functionize
            unpacker.unpack(stdTime); timeLastAccessed = SysTime(stdTime); // TODO: Functionize
        }
    }
}

/** Bit (Content) Status. */
enum BitStatus
{
    unknown,
    bits7,
    bits8,
}

/** Regular File.
 */
class RegFile : File
{
    this(NotNull!Dir parent) {
        super(parent);
        ++parent.gstats.noRegFiles;
    }
    this(ref DirEntry dent, NotNull!Dir parent) {
        this(dent.name.baseName, parent, dent.size.Bytes64,
             dent.timeLastModified, dent.timeLastAccessed);
    }
    this(string name, NotNull!Dir parent, Bytes64 size, SysTime timeLastModified, SysTime timeLastAccessed) {
        super(name, parent, size, timeLastModified, timeLastAccessed);
        ++parent.gstats.noRegFiles;
    }

    ~this() { _cstat.deallocate(false); }

    /** Returns: Contents Id of $(D this). */
    override const(SHA1Digest) treeContId() @property @trusted /* @safe pure nothrow */ { return _cstat._contId; }

    override Face!Color face() @property @safe pure nothrow { return regFileFace; }

    /** Returns: SHA-1 of $(D this) $(D File) Contents at $(D src). */
    const(SHA1Digest) contId(inout (ubyte[]) src,
                             File[][SHA1Digest] filesByContId)
        @property pure out(result) { assert(!result.empty); } // must have be defined
    body
    {
        if (_cstat._contId.empty) { // if not yet defined
            _cstat._contId = src.sha1Of;
            filesByContId[_cstat._contId] ~= this;
            debug dln("Got SHA1 of " ~ path);
        }
        return _cstat._contId;
    }

    /** Returns: Cached/Memoized Binary Histogram of $(D this) $(D File). */
    auto ref bistogram8() @property @safe // ref needed here!
    {
        if (_cstat.bist.empty) {
            /* debug dln(this.path, " Recalculating bistogram8."); */
            _cstat.bist.put(readOnlyContents); // memoized calculated
        }
        return _cstat.bist;
    }

    /** Returns: Cached/Memoized XGram of $(D this) $(D File). */
    auto ref xgram() @property @safe // ref needed here!
    {
        if (_cstat.xgram.empty) {
            _cstat.xgram.put(readOnlyContents); // memoized calculated
            /* debug dln(this.path, " Recalculated xgram. empty:", _cstat.xgram.empty); */
        }
        return _cstat.xgram;
    }

    /** Returns: Cached/Memoized XGram Deep Denseness of $(D this) $(D File). */
    auto ref xgramDeepDenseness() @property @safe
    {
        if (!_cstat._xgramDeepDenseness) {
            _cstat._xgramDeepDenseness = xgram.denseness(-1).numerator;
            /* debug dln(this.path, " Recalculating xgramDeepDenseness to ", _cstat._xgramDeepDenseness); */
        }
        return Rational!ulong(_cstat._xgramDeepDenseness,
                              _cstat.xgram.noBins);
    }

    /** Process File in Cache Friendly Chunks. */
    void calculateCStatInChunks(size_t chunkSize,
                                bool doSHA1,
                                bool doBist,
                                bool doBitStatus,
                                NotNull!File[][SHA1Digest] filesByContId) @safe
    {
        if (_cstat._contId.defined) { doSHA1 = false; }
        if (!_cstat.bist.empty) { doBist = false; }
        if (_cstat.bitStatus != BitStatus.unknown) { doBitStatus = false; }

        import std.digest.sha;
        SHA1 sha1;
        if (doSHA1) { sha1.start(); }

        bool isASCII = true;

        if (doSHA1 || doBist || doBitStatus) {
            import std.range: chunks;
            foreach (chunk; readOnlyContents.chunks(chunkSize)) {
                if (doSHA1) { sha1.put(chunk); }
                if (doBist) { _cstat.bist.put(chunk); }
                if (doBitStatus) {
                    foreach (elt; chunk) {
                        import bitop_ex: bt;
                        isASCII = isASCII && !elt.bt(7); // ASCII has no topmost bit set
                    }
                }
            }
        }

        if (doBitStatus) {
            _cstat.bitStatus = isASCII ? BitStatus.bits7 : BitStatus.bits8;
        }

        if (doSHA1) {
            _cstat._contId = sha1.finish();
            filesByContId[_cstat._contId] ~= cast(NotNull!File)assumeNotNull(this);
        }
    }

    /** Clear/Reset Contents Statistics of $(D this) $(D File). */
    void clearCStat(File[][SHA1Digest] filesByContId) @safe nothrow
    {
        // SHA1-digest
        if (_cstat._contId in filesByContId) {
            auto dups = filesByContId[_cstat._contId];
            import std.algorithm: remove;
            immutable n = dups.length;
            dups = dups.remove!(a => a is this);
            assert(n == dups.length + 1); // assert that dups were not decreased by one");
        }
    }

    override string toString() @property @trusted
    {
        // import std.traits: fullyQualifiedName;
        // return fullyQualifiedName!(typeof(this)) ~ "(" ~ buildPath(parent.name, name) ~ ")"; // TODO: typenameof
        return (typeof(this)).stringof ~ "(" ~ this.path ~ ")"; // TODO: typenameof
    }

    version(msgpack)
    {
        /** Construct from msgpack $(D unpacker).  */
        this(Unpacker)(ref Unpacker unpacker) {
            fromMsgpack(msgpack.Unpacker(unpacker));
        }

        /** Pack. */
        void toMsgpack(Packer)(ref Packer packer) const {
            /* writeln("Entering RegFile.toMsgpack ", name); */

            packer.pack(this.name, this.size,
                        this.timeLastModified.stdTime,
                        this.timeLastAccessed.stdTime);

            // CStat: TODO: Group
            packer.pack(_cstat.kindId); // FKind
            packer.pack(_cstat._contId); // Digest

            // Bist
            immutable bistFlag = !_cstat.bist.empty;
            packer.pack(bistFlag);
            if (bistFlag) { packer.pack(_cstat.bist); }

            // XGram
            immutable xgramFlag = !_cstat.xgram.empty;
            packer.pack(xgramFlag);
            if (xgramFlag) {
                /* debug dln("packing xgram. empty:", _cstat.xgram.empty); */
                packer.pack(_cstat.xgram,
                            _cstat._xgramDeepDenseness);
            }

            /*     auto this_ = (cast(RegFile)this); // TODO: Ugly! Is there another way? */
            /*     const tags = this_.parent.gstats.ftags.getTags(this_); */
            /*     immutable tagsFlag = !tags.empty; */
            /*     packer.pack(tagsFlag); */
            /*     debug dln("Packing tags ", tags, " of ", this_.path); */
            /*     if (tagsFlag) { packer.pack(tags); } */
        }

        /** Unpack. */
        void fromMsgpack(Unpacker)(auto ref Unpacker unpacker) @trusted
        {
            unpacker.unpack(this.name, this.size); // Name, Size

            // Time
            long stdTime;
            unpacker.unpack(stdTime); this.timeLastModified = SysTime(stdTime); // TODO: Functionize
            unpacker.unpack(stdTime); this.timeLastAccessed = SysTime(stdTime); // TODO: Functionize

            // CStat: TODO: Group
            unpacker.unpack(_cstat.kindId); // FKind
            if (!(_cstat.kindId in parent.gstats.allKindsById)) {
                // kind database has changed since kindId was written to disk
                _cstat.kindId.reset; // forget it
            }
            unpacker.unpack(_cstat._contId); // Digest
            if (_cstat._contId.defined) {
                parent.gstats.filesByContId[_cstat._contId] ~= cast(NotNull!File)this;
            }

            // Bist
            bool bistFlag; unpacker.unpack(bistFlag);
            if (bistFlag) {
                unpacker.unpack(_cstat.bist);
            }

            // XGram
            bool xgramFlag; unpacker.unpack(xgramFlag);
            if (xgramFlag) {
                /* if (_cstat.xgram == null) { */
                /*     _cstat.xgram = cast(XGram*)core.stdc.stdlib.malloc(XGram.sizeof); */
                /* } */
                /* unpacker.unpack(*_cstat.xgram); */
                unpacker.unpack(_cstat.xgram,
                                _cstat._xgramDeepDenseness);
                /* debug dln("unpacked xgram. empty:", _cstat.xgram.empty); */
            }

            // tags
            /* bool tagsFlag; unpacker.unpack(tagsFlag); */
            /* if (tagsFlag) { */
            /*     string[] tags; */
            /*     unpacker.unpack(tags); */
            /* } */
        }

        override void makeObselete() @trusted { _cstat.reset(); /* debug dln("Reset CStat for ", path); */ }
    }

    /** Returns: Read-Only Contents of $(D this) Regular File. */
    // } catch (InvalidMemoryOperationError) { ppln(term, outFile, doHTML, "Failed to mmap ", dent.name); }
    // scope immutable src = cast(immutable ubyte[]) read(dent.name, upTo);
    immutable(ubyte[]) readOnlyContents(string file = __FILE__, int line = __LINE__)() @trusted
    {
        if (!_mmfile) {
            _mmfile = new MmFile(this.path, MmFile.Mode.read,
                                 mmfile_size, null, pageSize());
            if (parent.gstats.showMMaps) {
                writeln("Mapped ", path, " of size ", size);
            }
        }
        return cast(typeof(return))_mmfile[];
    }

    /** Returns: Read-Writable Contents of $(D this) Regular File. */
    // } catch (InvalidMemoryOperationError) { ppln(term, outFile, doHTML, "Failed to mmap ", dent.name); }
    // scope immutable src = cast(immutable ubyte[]) read(dent.name, upTo);
    ubyte[] readWriteableContents() @trusted
    {
        if (!_mmfile) {
            _mmfile = new MmFile(this.path, MmFile.Mode.readWrite,
                                 mmfile_size, null, pageSize());
        }
        return cast(typeof(return))_mmfile[];
    }

    /** If needed Free Allocated Contents of $(D this) Regular File. */
    bool freeContents() {
        if (_mmfile) { delete _mmfile; _mmfile = null; return true; }
        else { return false; }
    }

    import std.mmfile;
    private MmFile _mmfile;
    private CStat _cstat;     // Statistics about the contents of this RegFile.
}

/** Contents Statistics of a Regular File. */
struct CStat {
    void reset() @safe nothrow {
        kindId[] = 0;
        _contId[] = 0;
        hitCount = 0;
        bist.reset();
        xgram.reset();
        _xgramDeepDenseness = 0;
        deallocate();
    }

    void deallocate(bool nullify = true) @trusted nothrow {
        kindId[] = 0;
        /* if (xgram != null) { */
        /*     import core.stdc.stdlib; */
        /*     free(xgram); */
        /*     if (nullify) { */
        /*         xgram = null; */
        /*     } */
        /* } */
    }

    SHA1Digest kindId; // FKind Identifier/Fingerprint of this regular file.
    SHA1Digest _contId; // Contents Identifier/Fingerprint.

    /** Boolean Single Bistogram over file contents. If
        binHist0[cast(ubyte)x] is set then this file contains byte x. Consumes
        32 bytes. */
    Bist bist; // TODO: Put in separate slice std.allocator.

    /** Boolean Pair Bistogram (Digram) over file contents (higher-order statistics).
        If this RegFile contains a sequence of [byte0, bytes1],
        then bit at index byte0 + byte1 * 256 is set in xgram.
    */
    XGram xgram; // TODO: Use slice std.allocator
    private ulong _xgramDeepDenseness = 0;

    uint64_t hitCount = 0;
    BitStatus bitStatus = BitStatus.unknown;
}

import core.sys.posix.sys.types;

enum SymlinkFollowContext
{
    none,                       // Follow no symlinks
    internal,                   // Follow only symlinks outside of scanned tree
    external,                   // Follow only symlinks inside of scanned tree
    all,                        // Follow all symlinks
    standard = external
}

/** Global Scanner Statistics. */
class GStats
{
    NotNull!File[][string] filesByName;    // Potential File Name Duplicates
    NotNull!File[][ino_t] filesByInode;    // Potential Link Duplicates
    NotNull!File[][SHA1Digest] filesByContId; // File(s) (Duplicates) Indexed on Contents SHA1.
    FileTags ftags;
    Bytes64[File] treeSizesByFile;

    FKind[SHA1Digest] incKindsById;    // Index Kinds by their behaviour
    FKind[SHA1Digest] allKindsById;    // Index Kinds by their behaviour

    bool showNameDups = false;
    bool showContentDups = false;
    bool linkContentDups = false;

    bool showLinkDups = false;
    SymlinkFollowContext followSymlinks = SymlinkFollowContext.external;
    bool showBrokenSymlinks = true;
    bool showSymlinkCycles = true;

    bool showAnyDups = false;
    bool showMMaps = false;
    bool showUsage = false;
    bool showSHA1 = false;

    uint64_t noFiles = 0;
    uint64_t noRegFiles = 0;
    uint64_t noSymlinks = 0;
    uint64_t noSpecialFiles = 0;
    uint64_t noDirs = 0;

    uint64_t noScannedFiles = 0;
    uint64_t noScannedRegFiles = 0;
    uint64_t noScannedSymlinks = 0;
    uint64_t noScannedSpecialFiles = 0;
    uint64_t noScannedDirs = 0;

    auto shallowDensenessSum = Rational!ulong(0, 1);
    auto deepDensenessSum = Rational!ulong(0, 1);
    uint64_t densenessCount = 0;

}

struct Results
{
    Bytes64 numTotalHits; // Number of total hits.
    Bytes64 numFilesWithHits; // Number of files with hits

    Bytes64 noBytesTotal; // Number of bytes total.
    Bytes64 noBytesTotalContents; // Number of contents bytes total.
    Bytes64 noBytesScanned; // Number of bytes scanned.
    Bytes64 noBytesSkipped; // Number of bytes skipped.
    Bytes64 noBytesUnreadable; // Number of bytes unreadable.
}

version(cerealed) {
    void grain(T)(ref Cereal cereal, ref SysTime systime) {
        auto stdTime = systime.stdTime;
        cereal.grain(stdTime);
        if (stdTime != 0) {
            systime = SysTime(stdTime);
        }
    }
}

/** Directory Sorting Order. */
enum DirSorting
{
    /* onTimeCreated, /\* Windows only. Currently stored in Linux on ext4 but no */
    /*               * standard interface exists yet, it will probably be called */
    /*               * xstat(). *\/ */
    onTimeLastModified,
    onTimeLastAccessed,
    onSize,
    onNothing,
}

enum BuildType
{
    none,    // Don't compile
    devel,   // Compile with debug symbols
    release, // Compile without debugs symbols and optimizations
    standard = devel,
}

enum PathFormat
{
    absolute,
    relative,
}

import std.range: hasSlicing;

// Faces (Font/Color)

enum pathFace = face(Color.green, Color.black);

enum dirFace = face(Color.blue, Color.black);
enum fileFace = face(Color.magenta, Color.black);
enum specialFileFace = face(Color.red, Color.black);
enum regFileFace = face(Color.white, Color.black);
enum symlinkFace = face(Color.cyan, Color.black);

enum contextFace = face(Color.green, Color.black);

enum stdFace = face(Color.white, Color.black);

enum timeFace = face(Color.magenta, Color.black);
enum digestFace = face(Color.yellow, Color.black);
enum bytesFace = face(Color.yellow, Color.black);

enum infoFace = face(Color.white, Color.black, true);
enum warnFace = face(Color.yellow, Color.black);
enum skipFileFace = warnFace;
enum errorFace = face(Color.red, Color.black);

// Support these as immutable

/** Key (Hit) Face Palette. */
enum ctxFaces = [face(Color.red, Color.black) ,
                 face(Color.green, Color.black),
                 face(Color.blue, Color.black),
                 face(Color.cyan, Color.black),
                 face(Color.magenta, Color.black),
                 face(Color.yellow, Color.black),
    ];
/** Key (Hit) Faces. */
enum keyFaces = ctxFaces.map!(a => face(a.fg, a.bg, true));

void setFace(Term, Face)(ref Term term, Face face, bool colorFlag)
{
    if (colorFlag)
        term.color(face.fg | (face.bright ? Bright : 0) ,
                   face.bg);
}

@safe pure nothrow
{
    const string lbr(bool doHTML) { return (doHTML ? "<br>" : ""); } // line break
    const string begBold(bool doHTML) { return (doHTML ? "<b>" : ""); } // bold begin
    const string endBold(bool doHTML) { return (doHTML ? "</b>" : ""); } // bold end
    const T asBold(T)(bool doHTML, T txt) {
        return begBold(doHTML) ~ txt ~ endBold(doHTML);
    }
    const T asPath(T)(bool doHTML, T path, T name, bool dirFlag) {
        immutable path_ = asBold(doHTML,
                                 name ~ (dirFlag ? dirSeparator : ""));
        if (doHTML) {
            return "<a href=\"file://" ~ path ~ "\">" ~ path_ ~ "</a>";
        } else {
            return path_;
        }
    }
}

void ppArgs(Term, Args...)(ref Term term, ioFile outFile, bool doHTML, bool colorFlag, Args args)
{
    foreach (arg; args)
    {
        // pick path
        static if (__traits(hasMember, arg, "path"))
        {
            auto arg_name = arg.path;
        }
        else
        {
            auto arg_name = arg;
        }

        alias Arg = typeof(arg); // shorthand

        // pick face
        bool faceChanged = false;
        static if (__traits(hasMember, arg, "face"))
        {
            term.setFace(arg.face, colorFlag);
            faceChanged = true;
        }
        else static if (is(Unqual!(Arg) == SHA1Digest))
        {
            term.setFace(digestFace, colorFlag);
            faceChanged = true;
        }
        else static if (is(Unqual!(Arg) == Bytes64))
        {
            term.setFace(bytesFace, colorFlag);
            faceChanged = true;
        }

        // TODO: split path along / and print each part in colors
        /* static assert(!is(Arg == NotNull!File)); */
        /* static assert(!is(Arg == NotNull!RegFile)); */
        /* static assert(!is(Arg == NotNull!Dir)); */
        /* static assert(!is(Arg == NotNull!Dir)); */

        // write
        if (outFile == stdout)
        {
            term.write(arg_name);
            if (faceChanged)
                term.setFace(stdFace, colorFlag); // restore to standard
        }
        else
        {
            outFile.write(args);
        }
    }
}

template IsA(T, K) {
    static if (is(T t == K!U, U)) {
        enum IsA = true;
    } else {
        enum IsA = false;
    }
}

/** Pretty Print Arguments $(D args) to Terminal $(D term). */
void pp(Term, Args...)(ref Term term, ioFile outFile, bool doHTML, bool colorFlag, Args args)
{
    ppArgs(term, outFile, doHTML, colorFlag, args);
    if (outFile == stdout)
    {
        term.flush();
    }
}

/** Pretty Print Arguments $(D args) to Terminal $(D term) including Line Termination. */
void ppln(Term, Args...)(ref Term term, ioFile outFile, bool doHTML, bool colorFlag, Args args)
{
    ppArgs(term, outFile, doHTML, colorFlag, args);
    if (outFile == stdout)
    {
        term.writeln(lbr(doHTML));
        term.flush();
    }
    else
    {
        outFile.writeln(lbr(doHTML));
    }
}

/** Print End of Line to Terminal $(D term). */
void endl(Term)(ref Term term, ioFile outFile, bool doHTML, bool colorFlag) { return ppln(term, outFile, doHTML, colorFlag); }

/** Dir.
 */
class Dir : File
{
    /** Construct File System Root Directory. */
    this(Dir parent = null, GStats gstats = null)
    {
        super(parent);
        this._gstats = gstats;
        if (gstats) { ++gstats.noDirs; }
    }

    this(string root_path, GStats gstats)
        in { assert(root_path == "/"); assert(gstats); }
    body
    {
        auto rootDent = DirEntry(root_path);
        Dir rootParent = null;
        this(rootDent, rootParent, gstats);
    }

    this(ref DirEntry dent, Dir parent, GStats gstats)
        in { assert(gstats); }
    body
    {
        this(dent.name.baseName, parent, dent.size.Bytes64, dent.timeLastModified, dent.timeLastAccessed, gstats);
    }

    this(string name, Dir parent, Bytes64 size, SysTime timeLastModified, SysTime timeLastAccessed,
         GStats gstats = null)
    {
        super(name, parent, size, timeLastModified, timeLastAccessed);
        this._gstats = gstats;
        if (gstats) { ++gstats.noDirs; }
    }

    override Bytes64 treeSize() @property @trusted /* @safe pure nothrow */
    {
        if (_treeSize.untouched) {
            _treeSize = this.size + reduce!"a+b"(0.Bytes64,
                                                 _subs.byValue.map!"a.treeSize"); // recurse!
        }
        return _treeSize;
    }

    /** Returns: Contents Id of $(D this). */
    override const(SHA1Digest) treeContId() @property @trusted /* @safe pure nothrow */
    {
        if (_treeContId.untouched) {
            _treeContId = reduce!"a ^ b"(SHA1Digest.init,
                                         _subs.byValue.map!"a.treeContId"); // recurse!
            gstats.filesByContId[_treeContId] ~= cast(NotNull!File)this;
        }
        return _treeContId;
    }

    override Face!Color face() @property @safe pure nothrow { return dirFace; }

    bool isRoot() @property @safe const pure nothrow { return !parent; }

    GStats gstats(GStats gstats) @property @safe pure /* nothrow */ {
        return this._gstats = gstats;
    }
    GStats gstats() @property @safe pure nothrow {
        if (!_gstats && this.parent) {
            _gstats = this.parent.gstats();
        }
        return _gstats;
    }

    /** Returns: Depth of Depth from File System root to this File. */
    override int depth() @property @safe pure nothrow
    {
        if (_depth ==- 1) {
            _depth = parent ? parent.depth + 1 : 0; // memoized depth
        }
        return _depth;
    }

    /** Append Tree Statistics. */
    void addTreeStatsFromSub(F)(NotNull!F subFile, ref DirEntry subDent)
    {
        if (subDent.isFile) {
            /* _treeSize += subDent.size.Bytes64; */
            // dln("Updating ", _treeSize, " of ", path);

            /** TODO: Move these overloads to std.datetime */
            auto ref min(in SysTime a, in SysTime b) @trusted pure nothrow { return (a < b ? a : b); }
            auto ref max(in SysTime a, in SysTime b) @trusted pure nothrow { return (a > b ? a : b); }

            const lastMod = subDent.timeLastModified;
            _timeModifiedInterval = Interval!SysTime(min(lastMod, _timeModifiedInterval.begin),
                                                     max(lastMod, _timeModifiedInterval.end));
            const lastAcc = subDent.timeLastAccessed;
            _timeAccessedInterval = Interval!SysTime(min(lastAcc, _timeAccessedInterval.begin),
                                                     max(lastAcc, _timeAccessedInterval.end));
        }
    }

    /** Update Statistics for Sub-File $(D sub) with $(D subDent) of $(D this) Dir. */
    void updateStats(F)(NotNull!F subFile, ref DirEntry subDent, bool isRegFile)
    {
        auto localGStats = gstats();
        if (localGStats) {
            if (localGStats.showNameDups) {
                localGStats.filesByName[subFile.name] ~= cast(NotNull!File)subFile;
            }
            if (localGStats.showLinkDups &&
                isRegFile) {
                import core.sys.posix.sys.stat;
                immutable stat_t stat = subDent.statBuf();
                if (stat.st_nlink >= 2) {
                    localGStats.filesByInode[stat.st_ino] ~= cast(NotNull!File)subFile;
                }
            }
        }
    }

    /** Load Contents of $(D this) Directory from Disk using DirEntries.
        Returns: true iff Dir was updated (reread) from disk.
    */
    bool load(int depth = 0, bool force = false)
    {
        import std.range: empty;
        if (!_obseleteDir && // already loaded
            !force) {        // and not forced reload
            return false;    // signal already scanned
        }

        // dln("Zeroing ", _treeSize, " of ", path);
        _treeSize.reset; // this.size;
        auto oldSubs = _subs;
        _subs.reset;
        assert(_subs.length == 0); // TODO: Remove when verified

        import std.file: dirEntries, SpanMode;
        auto entries = dirEntries(path, SpanMode.shallow, false); // false: skip symlinks
        foreach (dent; entries) {
            immutable basename = dent.name.baseName;
            File sub = null;
            if (basename in oldSubs) {
                sub = oldSubs[basename]; // reuse from previous cache
            } else {
                bool isRegFile = false;
                if (dent.isSymlink) {
                    sub = new Symlink(dent, assumeNotNull(this));
                } else if (dent.isDir) {
                    sub = new Dir(dent, this, gstats);
                } else if (dent.isFile) {
                    // TODO: Delay construction of and specific files such as
                    // CFile, ELFFile, after FKind-recognition has been made.
                    sub = new RegFile(dent, assumeNotNull(this));
                    isRegFile = true;
                } else {
                    sub = new SpecialFile(dent, assumeNotNull(this));
                }
                updateStats(enforceNotNull(sub), dent, isRegFile);
            }
            addTreeStatsFromSub(enforceNotNull(sub), dent);
            _subs[basename] = sub;
        }
        _subs.rehash;           // optimize hash for faster lookups

        _obseleteDir = false;
        return true;
    }

    bool reload(int depth = 0) { return load(depth, true); }
    alias sync = reload;

    /* TODO: Can we get make this const to the outside world perhaps using inout? */
    ref File[string] subs() @property { load(); return _subs; }

    File[] subsSorted(DirSorting sorted = DirSorting.onTimeLastModified) @property {
        load();
        auto ssubs = _subs.values;
        /* TODO: Use radix sort to speed things up. */
        final switch (sorted) {
            /* case DirSorting.onTimeCreated: */
            /*     break; */
        case DirSorting.onTimeLastModified:
            ssubs.sort!((a, b) => (a.timeLastModified >
                                   b.timeLastModified));
            break;
        case DirSorting.onTimeLastAccessed:
            ssubs.sort!((a, b) => (a.timeLastAccessed >
                                   b.timeLastAccessed));
            break;
        case DirSorting.onSize:
            ssubs.sort!((a, b) => (a.size >
                                   b.size));
            break;
        case DirSorting.onNothing:
            break;
        }
        return ssubs;
    }

    File sub(Name)(Name sub_name) {
        load();
        return (sub_name in _subs) ? _subs[sub_name] : null;
    }
    File sub(File sub) {
        load();
        return (sub.path in _subs) != null ? sub : null;
    }

    version(cerealed) {
        void accept(Cereal cereal) {
            auto stdTime = timeLastModified.stdTime;
            cereal.grain(name, size, stdTime);
            timeLastModified = SysTime(stdTime);
        }
    }
    version(msgpack) {
        /** Construct from msgpack $(D unpacker).  */
        this(Unpacker)(ref Unpacker unpacker) {
            fromMsgpack(msgpack.Unpacker(unpacker));
        }

        void toMsgpack(Packer)(ref Packer packer) const {
            /* writeln("Entering Dir.toMsgpack ", this.name); */
            packer.pack(name, size,
                        timeLastModified.stdTime,
                        timeLastAccessed.stdTime,
                        kind);

            // Contents
            /* TODO: serialize map of polymorphic objects using
             * packer.packArray(_subs) and type trait lookup up all child-classes of
             * File */
            packer.pack(_subs.length);

            if (_subs.length >= 1) {

                auto diffsLastModified = _subs.byValue.map!"a.timeLastModified.stdTime".encodeForwardDifference;
                auto diffsLastAccessed = _subs.byValue.map!"a.timeLastAccessed.stdTime".encodeForwardDifference;
                /* auto timesLastModified = _subs.byValue.map!"a.timeLastModified.stdTime"; */
                /* auto timesLastAccessed = _subs.byValue.map!"a.timeLastAccessed.stdTime"; */

                packer.pack(diffsLastModified, diffsLastAccessed);

                /* debug dln(this.name, " sub.length: ", _subs.length); */
                /* debug dln(name, " modified diffs: ", diffsLastModified.pack.length); */
                /* debug dln(name, " accessed diffs: ", diffsLastAccessed.pack.length); */
                /* debug dln(name, " modified: ", timesLastModified.array.pack.length); */
                /* debug dln(name, " accessed: ", timesLastAccessed.array.pack.length); */
            }

            foreach (sub; _subs) {
                if        (const regfile = cast(RegFile)sub) {
                    packer.pack("RegFile");
                    regfile.toMsgpack(packer);
                } else if (const dir = cast(Dir)sub) {
                    packer.pack("Dir");
                    dir.toMsgpack(packer);
                } else if (const symlink = cast(Symlink)sub) {
                    packer.pack("Symlink");
                    symlink.toMsgpack(packer);
                } else if (const special = cast(SpecialFile)sub) {
                    packer.pack("SpecialFile");
                    special.toMsgpack(packer);
                } else {
                    immutable subClassName = sub.classinfo.name;
                    assert(false, "Unknown sub File class " ~ subClassName); // TODO: Exception
                }
            }
        }

        void fromMsgpack(Unpacker)(auto ref Unpacker unpacker)
        {
            unpacker.unpack(name, size);

            long stdTime;
            unpacker.unpack(stdTime); timeLastModified = SysTime(stdTime); // TODO: Functionize
            unpacker.unpack(stdTime); timeLastAccessed = SysTime(stdTime); // TODO: Functionize

            /* dln("before:", path, " ", size, " ", timeLastModified, " ", timeLastAccessed); */

            // FKind
            if (!kind) { kind = null; }
            unpacker.unpack(kind); /* TODO: kind = new DirKind(unpacker); */
            /* dln("after:", path); */

            _treeSize.reset; // this.size;

            // Contents
            /* TODO: unpacker.unpack(_subs); */
            immutable noPreviousSubs = _subs.length == 0;
            size_t subs_length; unpacker.unpack(subs_length); // TODO: Functionize to unpacker.unpack!size_t()

            ForwardDifferenceCode!(long[]) diffsLastModified, diffsLastAccessed;
            if (subs_length >= 1) {
                unpacker.unpack(diffsLastModified, diffsLastAccessed);
                /* auto x = diffsLastModified.decodeForwardDifference; */
            }

            foreach (ix; 0..subs_length) { // repeat for subs_length times
                string subClassName; unpacker.unpack(subClassName); // TODO: Functionize
                File sub = null;
                try {
                    switch (subClassName) {
                    default:
                        assert(false, "Unknown File parent class " ~ subClassName); // TODO: Exception
                    case "Dir":
                        auto subDir = assumeNotNull(new Dir(this, gstats));
                        unpacker.unpack(subDir); sub = subDir;
                        auto subDent = DirEntry(sub.path);
                        subDir.checkObseleted(subDent); // Invalidate Statistics using fresh CStat if needed
                        addTreeStatsFromSub(subDir, subDent);
                        break;
                    case "RegFile":
                        auto subRegFile = assumeNotNull(new RegFile(assumeNotNull(this)));
                        unpacker.unpack(subRegFile); sub = subRegFile;
                        auto subDent = DirEntry(sub.path);
                        subRegFile.checkObseleted(subDent); // Invalidate Statistics using fresh CStat if needed
                        updateStats(subRegFile, subDent, true);
                        addTreeStatsFromSub(subRegFile, subDent);
                        break;
                    case "Symlink":
                        auto subSymlink = assumeNotNull(new Symlink(assumeNotNull(this)));
                        unpacker.unpack(subSymlink); sub = subSymlink;
                        break;
                    case "SpecialFile":
                        auto SpecialFile = assumeNotNull(new SpecialFile(assumeNotNull(this)));
                        unpacker.unpack(SpecialFile); sub = SpecialFile;
                        break;
                    }
                    if (noPreviousSubs ||
                        !(sub.name in _subs)) {
                        _subs[sub.name] = sub;
                    }
                    /* dln("Unpacked Dir sub ", sub.path, " of type ", subClassName); */
                } catch (FileException) { // this may be a too generic exception
                    /* dln(sub.path, " is not accessible anymore"); */
                }
            }

        }
    }

    override void makeObselete() @trusted
    {
        _obseleteDir = true;
        _treeSize.reset;
        _timeModifiedInterval.reset;
        _timeAccessedInterval.reset;
    }
    override void makeUnObselete() @safe
    {
        _obseleteDir = false;
    }

    private File[string] _subs; // Directory contents
    DirKind kind;               // Kind of this directory
    uint64_t hitCount = 0;
    private int _depth = -1;            // Memoized Depth
    private bool _obseleteDir = true;  // Flags that this is obselete
    GStats _gstats = null;

    /* TODO: Reuse Span and span in Phobos. (Span!T).init should be (T.max, T.min) */
    Interval!SysTime _timeModifiedInterval;
    Interval!SysTime _timeAccessedInterval;
    Bytes64 _treeSize; // Size of tree with this directory as root. Zero means undefined.
    SHA1Digest _treeContId;
}

/** Externally Directory Memoized Calculation of Tree Size.
    Is it possible to make get any of @safe pure nothrow?
 */
Bytes64 treeSizeMemoized(NotNull!File file, Bytes64[File] cache) @trusted /* nothrow */
{
    typeof(return) sum = file.size;
    if (auto dir = cast(Dir)file) {
        if (file in cache) {
            sum = cache[file];
        } else {
            foreach (sub; dir.subs.byValue) {
                sum += treeSizeMemoized(assumeNotNull(sub), cache);
            }
            cache[file] = sum;
        }
    }
    return sum;
}

/** Save File System Tree Cache under Directory $(D rootDir).
    Returns: Serialized Byte Array.
*/
const(ubyte[]) saveRootDirTree(Term)(ref Term term, ioFile outFile, bool doHTML, bool colorFlag, Dir rootDir, string cacheFile) @trusted
{
    immutable tic = Clock.currTime;
    version(msgpack) {
        const data = rootDir.pack();
        import std.file: write;
    }
    else version(cerealed) {
            auto enc = new Cerealiser(); // encoder
            enc ~= rootDir;
            auto data = enc.bytes;
        } else {
        ubyte[] data;
    }
    cacheFile.write(data);
    immutable toc = Clock.currTime;
    term.setFace(stdFace, colorFlag);
    ppln(term, outFile, doHTML, colorFlag, "Wrote tree cache of size ", data.length.Bytes64, " to ", cacheFile, " in ",
         shortDurationString(toc - tic));
    return data;
}

/** Load File System Tree Cache from $(D cacheFile).
    Returns: Root Directory of Loaded Tree.
*/
Dir loadRootDirTree(Term)(ref Term term, ioFile outFile, bool doHTML, bool colorFlag, string cacheFile, GStats gstats) @trusted
{
    immutable tic = Clock.currTime;

    import std.file: read;
    try {
        const data = read(cacheFile);

        auto rootDir = new Dir(cast(Dir)null, gstats);
        version(msgpack) {
            unpack(cast(ubyte[])data, rootDir); /* Dir rootDir = new Dir(cast(const(ubyte)[])data); */
        }
        immutable toc = Clock.currTime;
        ppln(term, outFile, doHTML, colorFlag, "Read cache of size ", data.length.Bytes64, " from ", cacheFile, " in ",
             shortDurationString(toc - tic), " containing");
        pp(term, outFile, doHTML, colorFlag, gstats.noDirs, " Dirs, ");
        pp(term, outFile, doHTML, colorFlag, gstats.noRegFiles, " Regular Files, ");
        pp(term, outFile, doHTML, colorFlag, gstats.noSymlinks, " Symbolic Links, ");
        pp(term, outFile, doHTML, colorFlag, gstats.noSpecialFiles, " Special Files, ");
        ppln(term, outFile, doHTML, colorFlag, "totalling ", gstats.noFiles + 1, " Files"); // on extra because of lack of root
        assert(gstats.noDirs +
               gstats.noRegFiles +
               gstats.noSymlinks +
               gstats.noSpecialFiles == gstats.noFiles + 1);

        return rootDir;
    } catch (FileException) {
        ppln(term, outFile, doHTML, colorFlag, "Failed to read cache from ", cacheFile);
        return null;
    }
}

Dir[] getDirs(NotNull!Dir rootDir, string[] topDirNames)
{
    Dir[] topDirs;
    foreach (topName; topDirNames) {
        Dir topDir = getDir(rootDir, topName);
        if (!topDir) {
            dln("Directory " ~ topName ~ " is missing");
        } else {
            topDirs ~= topDir;
        }
    }
    return topDirs;
}

/** (Cached) Lookup of Directory $(D dirpath). */
File getFile(NotNull!Dir rootDir, string filePath, ref DirEntry dent) @trusted
{
    if (dent.isDir) {
        return getDir(rootDir, filePath);
    } else {
        if (auto parentDir = getDir(rootDir, filePath.dirName)) {
            return parentDir.sub(filePath.baseName);
        } else {
            dln("File path " ~ filePath ~ " doesn't exist");
        }
    }
    return null;
}

/** (Cached) Lookup of Directory $(D dirpath).
    Returns: Dir if present under rootDir, null otherwise.
    TODO: Make use of dent
*/
import std.path: isRooted;
Dir getDir(NotNull!Dir rootDir, string dirPath, ref DirEntry dent,
           ref Symlink[] followedSymlinks) @trusted
    in { assert(dirPath.isRooted); }
body
{
    Dir currDir = rootDir;

    import std.range: drop;
    import std.path: pathSplitter;
    foreach (part; dirPath.pathSplitter().drop(1)) { // all but first
        auto sub = currDir.sub(part);
        if        (auto subDir = cast(Dir)sub) {
            currDir = subDir;
        } else if (auto subSymlink = cast(Symlink)sub) {
            auto subDent = DirEntry(subSymlink.absoluteNormalizedTargetPath);
            if (subDent.isDir) {
                if (followedSymlinks.find(subSymlink)) {
                    dln("Infinite recursion in ", subSymlink);
                    return null;
                }
                followedSymlinks ~= subSymlink;
                currDir = getDir(rootDir, subSymlink.absoluteNormalizedTargetPath, subDent, followedSymlinks); // TODO: Check for infinite recursion
            } else {
                dln("Loaded path " ~ dirPath ~ " is not a directory");
                return null;
            }
        } else {
            return null;
        }
    }
    return currDir;
}

/** (Cached) Lookup of Directory $(D dirPath). */
Dir getDir(NotNull!Dir rootDir, string dirPath) @trusted
{
    Symlink[] followedSymlinks;
    try {
        auto dirDent = DirEntry(dirPath);
        return getDir(rootDir, dirPath, dirDent, followedSymlinks);
    } catch (FileException) {
        dln("Exception getting Dir");
        return null;
    }
}
unittest {
    /* auto tmp = tempfile("/tmp/fsfile"); */
}

enum ulong mmfile_size = 0; // 100*1024

auto pageSize() @trusted
{
    version(linux ) {
        import core.sys.posix.sys.shm: __getpagesize;
        return __getpagesize();
    } else {
        return 4096;
    }
}

enum KeyStrictness
{
    exact,
    acronym,
    eitherExactOrAcronym,
    standard = eitherExactOrAcronym,
}

/** File System Scanner. */
class Scanner(Term)
{
    this(string[] args, ref Term term) {
        _scanChunkSize = 32*pageSize();
        loadDirKinds();
        loadFileKinds();
        loadXML();
        prepare(args, term);
    }

    SysTime _currTime;
    import std.getopt;
    import std.string: toLower, toUpper, startsWith, CaseSensitive;
    import std.mmfile;
    import std.stdio: writeln, stdout, stderr, stdin, popen;
    import std.algorithm: find, joiner, count, countUntil, min, splitter;
    import std.range: join;
    import std.conv: to;

    import core.sys.posix.sys.mman;
    import core.sys.posix.pwd: passwd, getpwuid_r;
    version(linux) {
        // import core.sys.linux.sys.inotify;
        import core.sys.linux.sys.xattr;
    }
    import core.sys.posix.unistd: getuid, getgid;
    import std.file: read, FileException, exists, getcwd;
    import std.path: extension, buildNormalizedPath, expandTilde, absolutePath;
    import std.range: retro;
    import std.exception: ErrnoException;
    import core.sys.posix.sys.stat: stat_t, S_IRUSR, S_IRGRP, S_IROTH;
    import std.string: chompPrefix;

    uint64_t _hitsCountTotal = 0;

    Symlink[] _brokenSymlinks;

    // Directories
    DirKind[] skippedDirKinds;
    DirKind[string] skippedDirKindsMap;
    void loadDirKinds() {
        skippedDirKinds ~= new DirKind(".git",  "Git");
        skippedDirKinds ~= new DirKind(".svn",  "Subversion(Svn)");
        skippedDirKinds ~= new DirKind(".bzr",  "Mercurial (Bzr)");
        skippedDirKinds ~= new DirKind("RCS",  "RCS");
        skippedDirKinds ~= new DirKind("CVS",  "CVS");
        skippedDirKinds ~= new DirKind("MCVS",  "MCVS");
        skippedDirKinds ~= new DirKind("RCS",  "RCS");
        skippedDirKinds ~= new DirKind(".hg",  "Mercurial (Hg)");
        skippedDirKinds ~= new DirKind("SCCS",  "SCCS");
        skippedDirKinds ~= new DirKind(".wact",  "WACT");
        skippedDirKinds ~= new DirKind("_MTN",  "Monotone");
        skippedDirKinds ~= new DirKind("_darcs",  "Darcs");
        skippedDirKinds ~= new DirKind("{arch}",  "Arch");
        skippedDirKinds ~= new DirKind(".trash",  "Trash");
        skippedDirKinds ~= new DirKind(".undo",  "Undo");
        skippedDirKinds ~= new DirKind(".deps",  "Dependencies");
        skippedDirKinds ~= new DirKind(".backups",  "Backups");
        skippedDirKinds ~= new DirKind(".autom4te.cache",  "Automake Cache");
        foreach (k; skippedDirKinds) {
            skippedDirKindsMap[k.fileName] = k;
        }
        skippedDirKindsMap.rehash;
    }

    FKind[] srcFKinds; // Source Kinds
    FKind[string] srcFKindsByName;

    FKind[] binFKinds;
    FKind[][string] binFKindsByExt;    // Maps extension string to Binary FileKinds
    FKind[][size_t][immutable ubyte[]] binFKindsByMagic; // length => zero-offset magic byte array to Binary FileKinds
    FKind[SHA1Digest] binFKindsById;    // Index Kinds by their behaviour
    size_t[] binFKindsMagicLengths; // List of Magic lengths

    FKind[] incKinds; // FKind of file to include in search.
    FKind[][string] incKindsByName;

    void loadFileKinds() {
        srcFKinds ~= new FKind("Makefile", ["GNUmakefile", "Makefile", "makefile"],
                               ["mk", "mak", "makefile", "make", "gnumakefile"], [], 0, [], [],
                               [Delim("#")],
                               defaultStringDelims,
                               FileContent.sourceCode, FileKindDetection.equalsName);
        srcFKinds ~= new FKind("Automakefile", ["Makefile.am", "makefile.am"],
                               ["am"], [], 0, [], [],
                               [Delim("#")],
                               defaultStringDelims,
                               FileContent.sourceCode);
        srcFKinds ~= new FKind("Autoconffile", ["configure.ac", "configure.in"],
                               [], [], 0, [], [],
                               [Delim("#")],
                               defaultStringDelims,
                               FileContent.sourceCode);
        srcFKinds ~= new FKind("Doxygen", ["Doxyfile"],
                               ["doxygen"], [], 0, [], [],
                               [Delim("#")],
                               defaultStringDelims,
                               FileContent.sourceCode);

        srcFKinds ~= new FKind("Rake", ["Rakefile"],// TODO: inherit Ruby
                               ["mk", "makefile", "make", "gnumakefile"], [], 0, [], [],
                               [Delim("#"), Delim("=begin", "=end")],
                               defaultStringDelims,
                               FileContent.sourceCode, FileKindDetection.equalsName);

        srcFKinds ~= new FKind("HTML", [], ["htm", "html", "shtml", "xhtml"], [], 0, [], [],
                               [Delim("<!--", "-->")],
                               defaultStringDelims,
                               FileContent.text, FileKindDetection.equalsContents); // markup text
        srcFKinds ~= new FKind("XML", [], ["xml", "dtd", "xsl", "xslt", "ent", ], [], 0, "<?xml", [],
                               [Delim("<!--", "-->")],
                               defaultStringDelims,
                               FileContent.text, FileKindDetection.equalsContents); // TODO: markup text
        srcFKinds ~= new FKind("YAML", [], ["yaml", "yml"], [], 0, [], [],
                               [Delim("#")],
                               defaultStringDelims,
                               FileContent.text); // TODO: markup text
        srcFKinds ~= new FKind("CSS", [], ["css"], [], 0, [], [],
                               [Delim("/*", "*/")],
                               defaultStringDelims,
                               FileContent.text, FileKindDetection.equalsContents);

        srcFKinds ~= new FKind("Audacity Project", [], ["aup"], [], 0, "<?xml", [],
                               [Delim("#")],
                               defaultStringDelims,
                               FileContent.text, FileKindDetection.equalsNameAndContents);

        auto keywordsC = [ "auto", "const", "double", "float", "int", "short", "struct",
                           "unsigned", "break", "continue", "else", "for", "long", "signed",
                           "switch", "void", "case", "default", "enum", "goto", "register",
                           "sizeof", "typedef", "volatile", "char", "do", "extern", "if",
                           "return", "static", "union", "while", ];
        auto kindC = new FKind("C", [], ["c", "h"], [], 0, [],
                               keywordsC,
                               cCommentDelims,
                               defaultStringDelims,
                               FileContent.sourceCode, FileKindDetection.equalsWhatsGiven);
        srcFKinds ~= kindC;
        kindC.ops ~= tuple(FileOp.checkSyntax, "gcc -x c -fsyntax-only -c");

        auto keywordsCxx = keywordsC ~ ["asm", "dynamic_cast", "namespace", "reinterpret_cast", "try",
                                        "bool", "explicit", "new", "static_cast", "typeid",
                                        "catch", "false", "operator", "template", "typename",
                                        "class", "friend", "private", "this", "using",
                                        "const_cast", "inline", "public", "throw", "virtual",
                                        "delete", "mutable", "protected", "true", "wchar_t",
                                        // The following are not essential when
                                        // the standard ASCII character set is
                                        // being used, but they have been added
                                        // to provide more readable alternatives
                                        // for some of the C++ operators, and
                                        // also to facilitate programming with
                                        // character sets that lack characters
                                        // needed by C++.
                                        "and", "bitand", "compl", "not_eq", "or_eq", "xor_eq",
                                        "and_eq", "bitor", "not", "or", "xor", ];
        keywordsCxx = keywordsCxx.uniq.array;
        auto kindCxx = new FKind("C++", [], ["cpp", "hpp", "cxx", "hxx", "c++", "h++", "C", "H"], [], 0, [],
                                 keywordsCxx,
                                 cCommentDelims,
                                 defaultStringDelims,
                                 FileContent.sourceCode, FileKindDetection.equalsWhatsGiven);
        kindCxx.ops ~= tuple(FileOp.checkSyntax, "gcc -x c++ -fsyntax-only -c");
        srcFKinds ~= kindCxx;
        auto keywordsCxx11 = keywordsCxx ~ ["alignas", "alignof",
                                            "char16_t", "char32_t",
                                            "constexpr",
                                            "decltype",
                                            "override", "final",
                                            "noexcept", "nullptr",
                                            "auto",
                                            "thread_local",
                                            "static_assert", ];
        // TODO: Define as subkind
        /* srcFKinds ~= new FKind("C++11", [], ["cpp", "hpp", "cxx", "hxx", "c++", "h++", "C", "H"], [], 0, [], */
        /*                        keywordsCxx11, */
        /*                        [Delim("/\*", "*\/"), */
        /*                         Delim("//")], */
        /*                        defaultStringDelims, */
        /*                        FileContent.sourceCode, */
        /*                        FileKindDetection.equalsWhatsGiven); */

        auto keywordsNewObjectiveC = ["id",
                                      "in",
                                      "out", // Returned by reference
                                      "inout", // Argument is used both to provide information and to get information back
                                      "bycopy",
                                      "byref", "oneway", "self",
                                      "super", "@interface", "@end",
                                      "@implementation", "@end",
                                      "@interface", "@end",
                                      "@implementation", "@end",
                                      "@protoco", "@end", "@class" ];
        auto keywordsObjectiveC = keywordsC ~ keywordsNewObjectiveC;
        srcFKinds ~= new FKind("Objective-C", [], ["m", "h"], [], 0, [],
                               keywordsObjectiveC,
                               cCommentDelims,
                               defaultStringDelims,
                               FileContent.sourceCode, FileKindDetection.equalsWhatsGiven);
        auto keywordsObjectiveCxx = keywordsCxx ~ keywordsNewObjectiveC;
        srcFKinds ~= new FKind("Objective-C++", [], ["mm", "h"], [], 0, [],
                               keywordsObjectiveCxx,
                               [Delim("#")],
                               defaultStringDelims,
                               FileContent.sourceCode, FileKindDetection.equalsWhatsGiven);

        auto keywordsCSharp = ["if"]; // TODO: Add keywords
        srcFKinds ~= new FKind("C#", [], ["cs"], [], 0, [], keywordsCSharp,
                               cCommentDelims,
                               defaultStringDelims,
                               FileContent.sourceCode, FileKindDetection.equalsWhatsGiven);

        auto keywordsOCaml = ["and", "as", "assert", "begin", "class",
                              "constraint", "do", "done", "downto", "else",
                              "end", "exception", "external", "false", "for",
                              "fun", "function", "functor", "if", "in",
                              "include", "inherit", "inherit!", "initializer"
                              "lazy", "let", "match", "method", "method!",
                              "module", "mutable", "new", "object", "of",
                              "open", "or",
                              "private", "rec", "sig", "struct", "then", "to",
                              "true", "try", "type",
                              "val", "val!", "virtual",
                              "when", "while", "with"];
        srcFKinds ~= new FKind("OCaml", [], ["ocaml"], [], 0, [], keywordsOCaml,
                               [Delim("(*", "*)")],
                               defaultStringDelims,
                               FileContent.sourceCode, FileKindDetection.equalsWhatsGiven);

        srcFKinds ~= new FKind("Parrot", [], ["pir", "pasm", "pmc", "ops", "pod", "pg", "tg", ], [], 0, [], keywordsOCaml,
                               [Delim("#"),
                                Delim("^=", // TODO: Needs beginning of line instead of ^
                                      "=cut")],
                               defaultStringDelims,
                               FileContent.sourceCode, FileKindDetection.equalsWhatsGiven);

        auto keywordsD = [ "auto", "const", "double", "float", "int", "short", "struct",
                           "unsigned", "break", "continue", "else", "for", "long",
                           "switch", "void", "case", "default", "enum", "goto",
                           "sizeof", "typedef", "volatile", "char", "do", "extern", "if",
                           "return", "static", "union", "while", "class", "immutable", "import"];

        const interpretersForD = ["rdmd",
                                  "gdmd"];
        auto magicForD = shebangLine(alt(lit("rdmd"),
                                         lit("gdmd")));
        auto kindD = new FKind("D", [], ["d", "di"],
                               magicForD, 0,
                               [],
                               keywordsD,
                               cCommentDelims,
                               defaultStringDelims,
                               FileContent.sourceCode,
                               FileKindDetection.equalsNameOrContents);
        kindD.ops ~= tuple(FileOp.checkSyntax, "gdc -fsyntax-only");
        srcFKinds ~= kindD;

        auto keywordsFortran77 = ["if", "else"];
        // TODO: Support .h files but require it to contain some Fortran-specific or be parseable.
        auto kindFortan = new FKind("Fortran", [], ["f", "fortran", "f77", "f90", "f95", "f03", "for", "ftn", "fpp"], [], 0, [], keywordsFortran77,
                                    [Delim("^C")], // TODO: Need beginning of line instead ^. seq(bol(), alt(lit('C'), lit('c'))); // TODO: Add chars chs("cC");
                                    defaultStringDelims,
                                    FileContent.sourceCode);
        kindFortan.ops ~= tuple(FileOp.checkSyntax, "gcc -x fortran -fsyntax-only");
        srcFKinds ~= kindFortan;

        // Ada
        auto keywordsAda83 = [ "abort", "else", "new", "return", "abs", "elsif", "not", "reverse",
                               "end", "null", "accept", "entry", "select", "access", "exception", "of", "separate",
                               "exit", "or", "subtype", "all", "others", "and", "for", "out", "array",
                               "function", "task", "at", "package", "terminate", "generic", "pragma", "then", "begin", "goto", "private",
                               "type", "body", "procedure", "if", "case", "in", "use", "constant", "is", "raise",
                               "range", "when", "declare", "limited", "record", "while", "delay", "loop", "rem", "with", "delta", "renames",
                               "digits", "mod", "xor", "do", ];
        auto keywordsAda95 = keywordsAda83 ~ ["abstract", "aliased", "tagged", "protected", "until", "requeue"];
        auto keywordsAda2005 = keywordsAda95 ~ ["synchronized", "overriding", "interface"];
        auto keywordsAda2012 = keywordsAda2005 ~ ["some"];
        auto extensionsAda = ["ada", "adb", "ads"];
        srcFKinds ~= new FKind("Ada 82", [], extensionsAda, [], 0, [], keywordsAda83,
                               [Delim("--")],
                               defaultStringDelims,
                               FileContent.sourceCode);
        srcFKinds ~= new FKind("Ada 95", [], extensionsAda, [], 0, [], keywordsAda95,
                               [Delim("--")],
                               defaultStringDelims,
                               FileContent.sourceCode);
        srcFKinds ~= new FKind("Ada 2005", [], extensionsAda, [], 0, [], keywordsAda2005,
                               [Delim("--")],
                               defaultStringDelims,
                               FileContent.sourceCode);
        srcFKinds ~= new FKind("Ada 2012", [], extensionsAda, [], 0, [], keywordsAda2012,
                               [Delim("--")],
                               defaultStringDelims,
                               FileContent.sourceCode);
        srcFKinds ~= new FKind("Ada", [], extensionsAda, [], 0, [], keywordsAda2012,
                               [Delim("--")],
                               defaultStringDelims,
                               FileContent.sourceCode);

        auto aliKind = new FKind("Ada Library File", [], ["ali"], [], 0, `V "GNAT Lib v`, [],
                                 [], // N/A
                                 defaultStringDelims,
                                 FileContent.fingerprint); // TODO: Parse version following magic tag?
        aliKind.machineGenerated = true;
        srcFKinds ~= aliKind;

        srcFKinds ~= new FKind("Pascal", [], ["pas", "pascal"], [], 0, [], [],
                               [Delim("(*", "*)"),// Old-Style
                                Delim("{", "}"),// Turbo Pascal
                                Delim("//")],// Delphi
                               defaultStringDelims,
                               FileContent.sourceCode, FileKindDetection.equalsContents);
        srcFKinds ~= new FKind("Delphi", [], ["pas", "int", "dfm", "nfm", "dof", "dpk", "dproj", "groupproj", "bdsgroup", "bdsproj"],
                               [], 0, [], [],
                               [Delim("//")],
                               defaultStringDelims,
                               FileContent.sourceCode, FileKindDetection.equalsContents);

        srcFKinds ~= new FKind("Objective-C", [], ["m"], [], 0, [], [],
                               cCommentDelims,
                               defaultStringDelims,
                               FileContent.sourceCode);

        auto keywordsPython = ["and", "del", "for", "is", "raise", "assert", "elif", "from", "lambda", "return", "break", "else", "global", "not", "try", "class", "except", "if", "or", "while", "continue", "exec", "import", "pass", "yield", "def", "finally", "in", "print"];

        // Scripting

        srcFKinds ~= new FKind("Python", [], ["py"], [], 0, "#!/usr/bin/python", keywordsPython,
                               [Delim("#")], // TODO: Support multi-line triple-double quote strings
                               defaultStringDelims,
                               FileContent.scriptCode);
        srcFKinds ~= new FKind("Ruby", [], ["rb", "rhtml", "rjs", "rxml", "erb", "rake", "spec", ], [], 0, "#!/usr/bin/ruby", [],
                               [Delim("#"), Delim("=begin", "=end")],
                               defaultStringDelims,
                               FileContent.scriptCode);

        srcFKinds ~= new FKind("Scala", [], ["scala", ],
                               [], 0, "#!/usr/bin/scala", [],
                               cCommentDelims,
                               defaultStringDelims,
                               FileContent.scriptCode);
        srcFKinds ~= new FKind("Scheme", [], ["scm", "ss"], [], 0, [], [],
                               [Delim(";")],
                               defaultStringDelims,
                               FileContent.scriptCode);

        srcFKinds ~= new FKind("Smalltalk", [], ["st"], [], 0, [], [],
                               [Delim("\"", "\"")],
                               defaultStringDelims,
                               FileContent.sourceCode);

        srcFKinds ~= new FKind("Perl", [], ["pl", "pm", "pm6", "pod", "t", "psgi", ],
                               [], 0, "#!/usr/bin/perl", [],
                               [Delim("#")],
                               defaultStringDelims,
                               FileContent.scriptCode);
        srcFKinds ~= new FKind("PHP", [], ["php", "phpt", "php3", "php4", "php5", "phtml", ],
                               [], 0, "#!/usr/bin/php", [],
                               [Delim("#")] ~ cCommentDelims,
                               defaultStringDelims,
                               FileContent.scriptCode);
        srcFKinds ~= new FKind("Plone", [], ["pt", "cpt", "metadata", "cpy", "py", ], [], 0, [], [],
                               [Delim("#")],
                               defaultStringDelims,
                               FileContent.scriptCode);

        srcFKinds ~= new FKind("Shell", [], ["sh"], [], 0, "#!/usr/bin/sh", [],
                               [Delim("#")],
                               defaultStringDelims,
                               FileContent.scriptCode);
        srcFKinds ~= new FKind("Bash", [], ["bash"], [], 0, "#!/usr/bin/bash", [],
                               [Delim("#")],
                               defaultStringDelims,
                               FileContent.scriptCode);
        srcFKinds ~= new FKind("Zsh", [], ["zsh"], [], 0, "#!/usr/bin/zsh", [],
                               [Delim("#")],
                               defaultStringDelims,
                               FileContent.scriptCode);

        srcFKinds ~= new FKind("Batch", [], ["bat", "cmd"], [], 0, [], [],
                               [Delim("REM")],
                               defaultStringDelims,
                               FileContent.scriptCode);

        srcFKinds ~= new FKind("TCL", [], ["tcl", "itcl", "itk", ], [], 0, [], [],
                               [Delim("#")],
                               defaultStringDelims,
                               FileContent.scriptCode);
        srcFKinds ~= new FKind("Tex", [], ["tex", "cls", "sty", ], [], 0, [], [],
                               [Delim("%")],
                               defaultStringDelims,
                               FileContent.scriptCode);
        srcFKinds ~= new FKind("TT", [], ["tt", "tt2", "ttml", ], [], 0, [], [],
                               [Delim("#")],
                               defaultStringDelims,
                               FileContent.scriptCode);
        srcFKinds ~= new FKind("Visual Basic", [], ["bas", "cls", "frm", "ctl", "vb", "resx", ], [], 0, [], [],
                               [Delim("'")],
                               defaultStringDelims,
                               FileContent.scriptCode);

        srcFKinds ~= new FKind("Verilog", [], ["v", "vh", "sv"], [], 0, [], [],
                               cCommentDelims,
                               defaultStringDelims,
                               FileContent.scriptCode);
        srcFKinds ~= new FKind("VHDL", [], ["vhd", "vhdl"], [], 0, [], [],
                               [Delim("--")],
                               defaultStringDelims,
                               FileContent.scriptCode);

        srcFKinds ~= new FKind("Clojure", [], ["clj"], [], 0, [], [],
                               [Delim(";")],
                               defaultStringDelims,
                               FileContent.sourceCode);
        srcFKinds ~= new FKind("Go", [], ["go"], [], 0, [], [],
                               cCommentDelims,
                               defaultStringDelims,
                               FileContent.sourceCode);
        srcFKinds ~= new FKind("Java", [], ["java", "properties"], [], 0, [], [],
                               cCommentDelims,
                               defaultStringDelims,
                               FileContent.sourceCode);

        srcFKinds ~= new FKind("Groovy", [], ["groovy", "gtmpl", "gpp", "grunit"], [], 0, [], [],
                               cCommentDelims,
                               defaultStringDelims,
                               FileContent.sourceCode);
        srcFKinds ~= new FKind("Haskell", [], ["hs", "lhs"], [], 0, [], [],
                               [Delim("--}"),
                                Delim("{-", "-}")],
                               defaultStringDelims,
                               FileContent.sourceCode);

        immutable javascriptKeywords = ["break", "case", "catch", "continue", "debugger", "default", "delete", "do", "else", "finally", "for", "function", "if", "in", "instanceof", "new", "return", "switch", "this", "throw", "try", "typeof", "var", "void", "while", "with" ];
        srcFKinds ~= new FKind("JavaScript", [], ["js"], [], 0, [], [],
                               cCommentDelims,
                               defaultStringDelims,
                               FileContent.scriptCode);
        srcFKinds ~= new FKind("JavaScript Object Notation", [], ["json"], [], 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.sourceCode);

        // TODO: Inherit XML
        srcFKinds ~= new FKind("JSP", [], ["jsp", "jspx", "jhtm", "jhtml"], [], 0, [], [],
                               [Delim("<!--", "--%>"), // XML
                                Delim("<%--", "--%>")],
                               defaultStringDelims,
                               FileContent.scriptCode);

        srcFKinds ~= new FKind("ActionScript", [], ["as", "mxml"], [], 0, [], [],
                               cCommentDelims, // N/A
                               defaultStringDelims,
                               FileContent.scriptCode);

        srcFKinds ~= new FKind("LUA", [], ["lua"], [], 0, [], [],
                               [Delim("--")],
                               defaultStringDelims,
                               FileContent.scriptCode);
        srcFKinds ~= new FKind("Mason", [], ["mas", "mhtml", "mpl", "mtxt"], [], 0, [], [],
                               [], // TODO: Need sregex
                               defaultStringDelims,
                               FileContent.scriptCode);

        srcFKinds ~= new FKind("CFMX", [], ["cfc", "cfm", "cfml"], [], 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.scriptCode);

        // Numerical Computing

        srcFKinds ~= new FKind("Matlab", [], ["m"], [], 0, [], [],
                               [Delim("%{", "}%"), // TODO: Prio 1
                                Delim("%")], // TODO: Prio 2
                               defaultStringDelims,
                               FileContent.sourceCode);
        srcFKinds ~= new FKind("Octave", [], ["m"], [], 0, [], [],
                               [Delim("%{", "}%"), // TODO: Prio 1
                                Delim("%"),
                                Delim("#")],
                               defaultStringDelims,
                               FileContent.sourceCode);
        srcFKinds ~= new FKind("Julia", [], ["jl"], [], 0, [], [],
                               [Delim("#")],
                               defaultStringDelims,
                               FileContent.sourceCode); // ((:execute "julia") (:evaluate "julia -e"))

        srcFKinds ~= new FKind("Erlang", [], ["erl", "hrl"], [], 0, [], [],
                               [Delim("%")],
                               defaultStringDelims,
                               FileContent.sourceCode);

        auto kindElisp = new FKind("Emacs-Lisp", [], ["el", "lisp"], [], 0, [], [],
                                   [Delim(";")],
                                   defaultStringDelims,
                                   FileContent.sourceCode);
        /* kindELisp.moduleName = "(provide 'MODULE_NAME)"; */
        /* kindELisp.moduleImport = "(require 'MODULE_NAME)"; */
        srcFKinds ~= kindElisp;

        srcFKinds ~= new FKind("Lisp", [], ["lisp", "lsp"], [], 0, [], [],
                               [Delim(";")],
                               defaultStringDelims,
                               FileContent.sourceCode);
        srcFKinds ~= new FKind("PostScript", [], ["ps", "postscript"], [], 0, "%!", [],
                               [Delim("%")],
                               defaultStringDelims,
                               FileContent.sourceCode);

        srcFKinds ~= new FKind("CMake", [], ["cmake"], [], 0, [], [],
                               [Delim("#")],
                               defaultStringDelims,
                               FileContent.sourceCode);

        // http://stackoverflow.com/questions/277521/how-to-identify-the-file-content-as-ascii-or-binary
        srcFKinds ~= new FKind("Pure ASCII", [], ["ascii", "txt", "text", "README", "INSTALL"], [], 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.textASCII); // NOTE: Extend with matcher where all bytes are in either: 9–13 or 32–126
        srcFKinds ~= new FKind("8-Bit Text", [], ["ascii", "txt", "text", "README", "INSTALL"], [], 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.text8Bit); // NOTE: Extend with matcher where all bytes are in either: 9–13 or 32–126 or 128–255

        srcFKinds ~= new FKind("Assembler", [], ["asm", "s"], [], 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.sourceCode);

        // Index Source Kinds by File extension
        FKind[][string] extSrcKinds;
        foreach (k; srcFKinds) {
            foreach (ext; k.exts) {
                extSrcKinds[ext] ~= k;
            }
        }
        extSrcKinds.rehash;

        // Index Source Kinds by kindName
        foreach (k; srcFKinds) {
            srcFKindsByName[k.kindName] = k;
        }
        srcFKindsByName.rehash;

        // Binaries

        auto extsELF = ["o", "so", "ko", "os", "out", "bin", "x", "elf", "axf", "prx", "puff", "none"]; // ELF file extensions

        auto elfKind = new FKind("ELF",
                                 [], extsELF, x"7F45 4C46", 0, [], [],
                                 [], // N/A
                                 defaultStringDelims,
                                 FileContent.machineCode,
                                 FileKindDetection.equalsContents);
        elfKind.wikiURL = "https://en.wikipedia.org/wiki/Executable_and_Linkable_Format";
        binFKinds ~= elfKind;
        /* auto extsExeELF = ["out", "bin", "x", "elf", ]; // ELF file extensions */
        /* auto elfExeKind  = new FKind("ELF executable",    [], extsExeELF,  [0x2, 0x0], 16, [], [], FileContent.machineCode, FileKindDetection.equalsContents, elfKind); */
        /* auto elfSOKind   = new FKind("ELF shared object", [], ["so", "ko"],  [0x3, 0x0], 16, [], [], FileContent.machineCode, FileKindDetection.equalsContents, elfKind); */
        /* auto elfCoreKind = new FKind("ELF core file",     [], ["core"], [0x4, 0x0], 16, [], [], FileContent.machineCode, FileKindDetection.equalsContents, elfKind); */
        /* binFKinds ~= elfExeKind; */
        /* elfKind.subKinds ~= elfSOKind; */
        /* elfKind.subKinds ~= elfCoreKind; */
        /* elfKind.subKinds ~= elfKind; */

        // Executables
        binFKinds ~= new FKind("Mach-O", [], ["o"], x"CEFA EDFE", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.machineCode, FileKindDetection.equalsContents);
        binFKinds ~= new FKind("modules.symbols.bin", [], ["bin"],
                               cast(ubyte[])[0xB0, 0x07, 0xF4, 0x57, 0x00, 0x02, 0x00, 0x01, 0x20], 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.binaryUnknown, FileKindDetection.equalsContents);

        auto kindCOFF = new FKind("COFF/i386/32", [], ["o"], x"4C01", 0, [], [],
                                  [], // N/A
                                  defaultStringDelims,
                                  FileContent.machineCode, FileKindDetection.equalsContents);
        kindCOFF.description = "Common Object File Format";
        binFKinds ~= kindCOFF;

        auto kindPECOFF = new FKind("PE/COFF", [], ["cpl", "exe", "dll", "ocx", "sys", "scr", "drv", "obj"],
                                    "PE\0\0", 0x60, // And ("MZ") at offset 0x0
                                    [], [],
                                    [], // N/A
                                    defaultStringDelims,
                                    FileContent.machineCode, FileKindDetection.equalsContents);
        kindPECOFF.description = "COFF Portable Executable";
        binFKinds ~= kindPECOFF;

        auto kindDOSMZ = new FKind("DOS-MZ", [], ["exe", "dll"], "MZ", 0, [], [],
                                   [], // N/A
                                   defaultStringDelims,
                                   FileContent.machineCode);
        kindDOSMZ.description = "MS-DOS, OS/2 or MS Windows executable";
        binFKinds ~= kindDOSMZ;

        // Caches
        binFKinds ~= new FKind("ld.so.cache", [], ["cache"], "ld.so-", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.binaryCache);

        // Profile Data
        binFKinds ~= new FKind("perf benchmark data", [], ["data"], "PERFILE2h", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.performanceBenchmark);

        // Images
        binFKinds ~= new FKind("GIF87a", [], ["gif"], "GIF87a", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.image);
        binFKinds ~= new FKind("GIF89a", [], ["gif"], "GIF89a", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.image);
        auto extJPEG = ["jpeg", "jpg", "j2k", "jpeg2000"];
        binFKinds ~= new FKind("JPEG", [], extJPEG, x"FFD8", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.image); // TODO: Support ends with [0xFF, 0xD9]
        binFKinds ~= new FKind("JPEG/JFIF", [], extJPEG, x"FFD8", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.image); // TODO: Support ends with ['J','F','I','F', 0x00]
        binFKinds ~= new FKind("JPEG/Exif", [], extJPEG, x"FFD8", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.image); // TODO: Support contains ['E','x','i','f', 0x00] followed by metadata

        binFKinds ~= new FKind("Pack200-Compressed Java Bytes Code", [], ["class"], x"CAFEBABE", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.machineCode);
        binFKinds ~= new FKind("JRun Server Application", [], ["jsa"],
                               cast(ubyte[])[0xa2,0xab,0x0b,0xf0,
                                             0x01,0x00,0x00,0x00,
                                             0x00,0x00,0x20,0x00], 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.machineCode);

        binFKinds ~= new FKind("PNG", [], ["png"],
                               cast(ubyte[])[137, 80, 78, 71, 13, 10, 26, 10], 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.image);

        auto kindPDF = new FKind("PDF", [], ["pdf"], "%PDF", 0, [], [],
                                 [], // N/A
                                 defaultStringDelims,
                                 FileContent.document);
        kindPDF.description = "Portable Document Format";
        binFKinds ~= kindPDF;

        auto kindLatexPDFFmt = new FKind("LaTeX PDF Format", [], ["fmt"],
                                         cast(ubyte[])['W','2','T','X',
                                                       0x00,0x00,0x00,0x08,
                                                       0x70,0x64,0x66,0x74,
                                                       0x65,0x78], 0, [], [],
                                         [], // N/A
                                         defaultStringDelims,
                                         FileContent.binaryCache);
        binFKinds ~= kindLatexPDFFmt;

        binFKinds ~= new FKind("Microsoft Office Document", [], ["doc", "docx", "xls", "ppt"], x"D0CF11E0", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.document);

        // Fonts

        auto kindTTF = new FKind("TrueType Font", [], ["ttf"], x"0001000000", 0, [], [],
                                 [], // N/A
                                 defaultStringDelims,
                                 FileContent.font);
        binFKinds ~= kindTTF;

        auto kindTTCF = new FKind("TrueType/OpenType Font Collection", [], ["ttc"], "ttcf", 0, [], [],
                                  [], // N/A
                                  defaultStringDelims,
                                  FileContent.font);
        binFKinds ~= kindTTCF;

        // Audio

        binFKinds ~= new FKind("MIDI", [], ["mid", "midi"], "MThd", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.audio, FileKindDetection.equalsNameAndContents);

        // Au
        auto auKind = new FKind("Au", [], ["au", "snd"], ".snd", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.audio, FileKindDetection.equalsNameAndContents);
        auKind.wikiURL = "https://en.wikipedia.org/wiki/Au_file_format";
        binFKinds ~= auKind;

        binFKinds ~= new FKind("Ogg", [], ["ogg", "oga", "ogv"],
                               cast(ubyte[])[0x4F,0x67,0x67,0x53,
                                             0x00,0x02,0x00,0x00,
                                             0x00,0x00,0x00,0x00,
                                             0x00, 0x00], 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.media);

        // TODO: Support RIFF....WAVEfmt using sregex seq(lit("RIFF"), any(4), lit("WAVEfmt"))
        binFKinds ~= new FKind("WAV", [], ["wav", "wave"], "RIFF", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.audio, FileKindDetection.equalsContents);

        // Archives

        auto kindBSDAr = new FKind("BSD Archive", [], ["a", "ar"], "!<arch>\n", 0, [], [],
                                   [], // N/A
                                   defaultStringDelims,
                                   FileContent.archive, FileKindDetection.equalsContents);
        kindBSDAr.description = "BSD 4.4 and Mac OSX Archive";
        binFKinds ~= kindBSDAr;

        binFKinds ~= new FKind("GNU tar Archive", [], ["tar"], "ustar\040\040\0", 257, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.archive, FileKindDetection.equalsContents); // TODO: Specialized Derivation of "POSIX tar Archive"
        binFKinds ~= new FKind("POSIX tar Archive", [], ["tar"], "ustar\0", 257, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.archive, FileKindDetection.equalsContents);

        binFKinds ~= new FKind("pkZip Archive", [], ["zip", "jar", "pptx", "docx", "xlsx"], "PK\003\004", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.archive, FileKindDetection.equalsContents);
        binFKinds ~= new FKind("pkZip Archive (empty)", [], ["zip", "jar"], "PK\005\006", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.archive, FileKindDetection.equalsContents);

        binFKinds ~= new FKind("PAK file", [], ["pak"], cast(ubyte[])[0x40, 0x00, 0x00, 0x00,
                                                                      0x4a, 0x12, 0x00, 0x00,
                                                                      0x01, 0x2d, 0x23, 0xcb,
                                                                      0x6d, 0x00, 0x00, 0x2f], 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.spellCheckWordList,
                             FileKindDetection.equalsNameAndContents);

        binFKinds ~= new FKind("LZW-Compressed", [], ["z", "tar.z"], x"1F9D", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.compressed);
        binFKinds ~= new FKind("LZH-Compressed", [], ["z", "tar.z"], x"1FA0", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.compressed);

        binFKinds ~= new FKind("CompressedZ", [], ["z"], "\037\235", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.compressed);
        binFKinds ~= new FKind("GNU-Zip (gzip)", [], ["tgz", "gz", "gzip", "dz"], "\037\213", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.compressed);
        binFKinds ~= new FKind("BZip", [], ["bz2", "bz", "tbz2", "bzip2"], "BZh", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.compressed);
        binFKinds ~= new FKind("XZ/7-Zip", [], ["xz", "txz", "7z", "t7z", "lzma", "tlzma", "lz", "tlz"],
                               cast(ubyte[])[0xFD, '7', 'z', 'X', 'Z', 0x00], 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.compressed);
        binFKinds ~= new FKind("LZX", [], ["lzx"], "LZX", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.compressed);
        binFKinds ~= new FKind("SZip", [], ["szip"], "SZ\x0a\4", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.compressed);

        binFKinds ~= new FKind("Git Bundle", [], ["bundle"], "# v2 git bundle", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.versionControl);

        binFKinds ~= new FKind("Emacs-Lisp Bytes Code", [], ["elc"], ";ELC\27\0\0\0", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.byteCode, FileKindDetection.equalsContents);
        binFKinds ~= new FKind("Python Bytes Code", [], ["pyc"], x"0D0A", 2, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.byteCode, FileKindDetection.equalsNameAndContents); // TODO: Handle versions at src[0..2]

        binFKinds ~= new FKind("Zshell Wordcode", [], ["zwc"], x"07060504", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.byteCode);

        binFKinds ~= new FKind("Java Bytes Code", [], ["class"], x"CAFEBABE", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.byteCode, FileKindDetection.equalsContents);
        binFKinds ~= new FKind("Java KeyStore", [], [], x"FEEDFEED", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.binaryUnknown, FileKindDetection.equalsContents);
        binFKinds ~= new FKind("Java JCE KeyStore", [], [], x"CECECECE", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.binaryUnknown, FileKindDetection.equalsContents);

        binFKinds ~= new FKind("LLVM Bitcode", [], ["bc"], "BC", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.byteCode, FileKindDetection.equalsNameAndContents);

        binFKinds ~= new FKind("MATLAB MAT", [], ["mat"], "MATLAB 5.0 MAT-file", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.numericalData, FileKindDetection.equalsContents);
        binFKinds ~= new FKind("Hierarchical Data Format version 4", [], ["hdf", "h4", "hdf4", "he4"], x"0E031301", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.numericalData);
        binFKinds ~= new FKind("Hierarchical Data Format version 5", [], ["hdf", "h5", "hdf5", "he5"], x"894844460D0A1A0A", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.numericalData);
        binFKinds ~= new FKind("GNU GLOBAL Database", ["GTAGS", "GRTAGS", "GPATH", "GSYMS"], [], "b1\5\0", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.tagsDatabase, FileKindDetection.equalsContents);

        binFKinds ~= new FKind("MySQL table definition file", ["sql", "sqlite", "sqlite3"], [], x"FE01", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.tagsDatabase, FileKindDetection.equalsContents);
        binFKinds ~= new FKind("MySQL MyISAM index file", ["sql", "sqlite", "sqlite3"], [], x"FEFE07", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.tagsDatabase, FileKindDetection.equalsContents);
        binFKinds ~= new FKind("MySQL MyISAM compressed data file", ["sql", "sqlite", "sqlite3"], [], x"FEFE08", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.tagsDatabase, FileKindDetection.equalsContents);
        binFKinds ~= new FKind("MySQL Maria index file", ["sql", "sqlite", "sqlite3"], [], x"FFFFFF", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.tagsDatabase, FileKindDetection.equalsContents);
        binFKinds ~= new FKind("MySQL Maria compressed data file", ["sql", "sqlite", "sqlite3"], [], x"FFFFFF", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.tagsDatabase, FileKindDetection.equalsContents);
        binFKinds ~= new FKind("SQLite format 3", ["sql", "sqlite", "sqlite3"], [], "SQLite format 3", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.tagsDatabase, FileKindDetection.equalsContents); // TODO: Why is this detected at 49:th try?

        binFKinds ~= new FKind("Vim swap", [], ["swo"], [], 0, "b0VIM ", [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.binaryCache);

        binFKinds ~= new FKind("GCC precompiled header", [], ["pch", "gpch"], "gpch", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.cache);

        binFKinds ~= new FKind("Firmware", [], ["fw"], cast(ubyte[])[], 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.cache, FileKindDetection.equalsName); // TODO: Add check for binary contents and that some parenting directory is named "firmware"

        binFKinds ~= new FKind("LibreOffice or OpenOffice RDB", [], ["rdb"],
                               cast(ubyte[])[0x43,0x53,0x4d,0x48,
                                             0x4a,0x2d,0xd0,0x26,
                                             0x00,0x02,0x00,0x00,
                                             0x00,0x02,0x00,0x02], 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.database, FileKindDetection.equalsName); // TODO: Add check for binary contents and that some parenting directory is named "firmware"

        binFKinds ~= new FKind("sconsign", [], ["sconsign", "sconsign.dblite", "dblite"], x"7d710128", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.cache, FileKindDetection.equalsNameAndContents);
        binFKinds ~= new FKind("GnuPG (GPG) key public ring", [], ["gpg"], x"9901", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.binary, FileKindDetection.equalsNameOrContents);
        binFKinds ~= new FKind("GnuPG (GPG) encrypted data", [], [], x"8502", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.binary, FileKindDetection.equalsContents);
        binFKinds ~= new FKind("GNUPG (GPG) key trust database", [], [], "\001gpg", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.binary, FileKindDetection.equalsContents);

        binFKinds ~= new FKind("aspell word list (rowl)", [], ["rws"], "aspell default speller rowl ", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.spellCheckWordList, FileKindDetection.equalsNameAndContents);

        // By Extension
        foreach (kind; binFKinds) {
            foreach (ext; kind.exts) {
                binFKindsByExt[ext] ~= kind;
            }
        }
        binFKindsByExt.rehash;

        // By Magic
        foreach (kind; binFKinds) {
            if (kind.magicOffset == 0 && // only if zero-offset for now
                kind.magicData) {
                if (const magicLit = cast(Lit)kind.magicData) {
                    binFKindsByMagic[magicLit.bytes][magicLit.bytes.length] ~= kind;
                    binFKindsMagicLengths ~= magicLit.bytes.length; // add it
                }
            }
        }
        binFKindsMagicLengths = binFKindsMagicLengths.uniq.array; // remove duplicates
        binFKindsMagicLengths.sort; // and sort
        binFKindsByMagic.rehash;

        foreach (kind; binFKinds) {
            binFKindsById[kind.behaviorId] = kind;
        }
        binFKindsById.rehash;

        import std.range: chain;
        foreach (kind; chain(srcFKinds, binFKinds)) {
            gstats.allKindsById[kind.behaviorId] = kind;
        }
        gstats.allKindsById.rehash;

    }

    // Code

    // Interpret Command Line
    bool _beVerbose = false;
    bool _caseFold = false;
    bool _showSkipped = false;
    string includedTypes;
    string[] _topDirNames;
    string[] addTags;
    string[] removeTags;

    // See also: https://en.wikipedia.org/wiki/Character_entity_reference#Predefined_entities_in_XML
    string[256] lutLatin1ToXML;
    // See also: https://en.wikipedia.org/wiki/Character_entity_reference#Character_entity_references_in_HTML
    string[256] lutLatin1ToHTML;

    void loadXML() {
        lutLatin1ToXML['"'] = "&quot";
        lutLatin1ToXML['.'] = "&amp";
        lutLatin1ToXML['\''] = "&apos";
        lutLatin1ToXML['<'] = "&lt";
        lutLatin1ToXML['>'] = "&gt";

        lutLatin1ToXML[0x22] = "&quot"; // U+0022 (34)	HTML 2.0	HTMLspecial	ISOnum	quotation mark (= APL quote)
        lutLatin1ToXML[0x26] = "&amp";  // U+0026 (38)	HTML 2.0	HTMLspecial	ISOnum	ampersand
        lutLatin1ToXML[0x27] = "&apos"; // U+0027 (39)	XHTML 1.0	HTMLspecial	ISOnum	apostrophe (= apostrophe-quote); see below
        lutLatin1ToXML[0x60] = "&lt";   // U+003C (60)	HTML 2.0	HTMLspecial	ISOnum	less-than sign
        lutLatin1ToXML[0x62] = "&gt";   // U+003E (62)	HTML 2.0	HTMLspecial	ISOnum	greater-than sign

        lutLatin1ToXML[0xA0] = "&nbsp"; // nbsp	 	U+00A0 (160)	HTML 3.2	HTMLlat1	ISOnum	no-break space (= non-breaking space)[d]
        lutLatin1ToXML[0xA1] = "&iexcl"; // iexcl	¡	U+00A1 (161)	HTML 3.2	HTMLlat1	ISOnum	inverted exclamation mark
        lutLatin1ToXML[0xA2] = "&cent"; // cent	¢	U+00A2 (162)	HTML 3.2	HTMLlat1	ISOnum	cent sign
        lutLatin1ToXML[0xA3] = "&pound"; // pound	£	U+00A3 (163)	HTML 3.2	HTMLlat1	ISOnum	pound sign
        lutLatin1ToXML[0xA4] = "&curren"; // curren	¤	U+00A4 (164)	HTML 3.2	HTMLlat1	ISOnum	currency sign
        lutLatin1ToXML[0xA5] = "&yen"; // yen	¥	U+00A5 (165)	HTML 3.2	HTMLlat1	ISOnum	yen sign (= yuan sign)
        lutLatin1ToXML[0xA6] = "&brvbar"; // brvbar	¦	U+00A6 (166)	HTML 3.2	HTMLlat1	ISOnum	broken bar (= broken vertical bar)
        lutLatin1ToXML[0xA7] = "&sect"; // sect	§	U+00A7 (167)	HTML 3.2	HTMLlat1	ISOnum	section sign
        lutLatin1ToXML[0xA8] = "&uml"; // uml	¨	U+00A8 (168)	HTML 3.2	HTMLlat1	ISOdia	diaeresis (= spacing diaeresis); see Germanic umlaut
        lutLatin1ToXML[0xA9] = "&copy"; // copy	©	U+00A9 (169)	HTML 3.2	HTMLlat1	ISOnum	copyright symbol
        lutLatin1ToXML[0xAA] = "&ordf"; // ordf	ª	U+00AA (170)	HTML 3.2	HTMLlat1	ISOnum	feminine ordinal indicator
        lutLatin1ToXML[0xAB] = "&laquo"; // laquo	«	U+00AB (171)	HTML 3.2	HTMLlat1	ISOnum	left-pointing double angle quotation mark (= left pointing guillemet)
        lutLatin1ToXML[0xAC] = "&not"; // not	¬	U+00AC (172)	HTML 3.2	HTMLlat1	ISOnum	not sign
        lutLatin1ToXML[0xAD] = "&shy"; // shy	 	U+00AD (173)	HTML 3.2	HTMLlat1	ISOnum	soft hyphen (= discretionary hyphen)
        lutLatin1ToXML[0xAE] = "&reg"; // reg	®	U+00AE (174)	HTML 3.2	HTMLlat1	ISOnum	registered sign ( = registered trademark symbol)
        lutLatin1ToXML[0xAF] = "&macr"; // macr	¯	U+00AF (175)	HTML 3.2	HTMLlat1	ISOdia	macron (= spacing macron = overline = APL overbar)
        lutLatin1ToXML[0xB0] = "&deg"; // deg	°	U+00B0 (176)	HTML 3.2	HTMLlat1	ISOnum	degree symbol
        lutLatin1ToXML[0xB1] = "&plusmn"; // plusmn	±	U+00B1 (177)	HTML 3.2	HTMLlat1	ISOnum	plus-minus sign (= plus-or-minus sign)
        lutLatin1ToXML[0xB2] = "&sup2"; // sup2	²	U+00B2 (178)	HTML 3.2	HTMLlat1	ISOnum	superscript two (= superscript digit two = squared)
        lutLatin1ToXML[0xB3] = "&sup3"; // sup3	³	U+00B3 (179)	HTML 3.2	HTMLlat1	ISOnum	superscript three (= superscript digit three = cubed)
        lutLatin1ToXML[0xB4] = "&acute"; // acute	´	U+00B4 (180)	HTML 3.2	HTMLlat1	ISOdia	acute accent (= spacing acute)
        lutLatin1ToXML[0xB5] = "&micro"; // micro	µ	U+00B5 (181)	HTML 3.2	HTMLlat1	ISOnum	micro sign
        lutLatin1ToXML[0xB6] = "&para"; // para	¶	U+00B6 (182)	HTML 3.2	HTMLlat1	ISOnum	pilcrow sign ( = paragraph sign)
        lutLatin1ToXML[0xB7] = "&middot"; // middot	·	U+00B7 (183)	HTML 3.2	HTMLlat1	ISOnum	middle dot (= Georgian comma = Greek middle dot)
        lutLatin1ToXML[0xB8] = "&cedil"; // cedil	¸	U+00B8 (184)	HTML 3.2	HTMLlat1	ISOdia	cedilla (= spacing cedilla)
        lutLatin1ToXML[0xB9] = "&sup1"; // sup1	¹	U+00B9 (185)	HTML 3.2	HTMLlat1	ISOnum	superscript one (= superscript digit one)
        lutLatin1ToXML[0xBA] = "&ordm"; // ordm	º	U+00BA (186)	HTML 3.2	HTMLlat1	ISOnum	masculine ordinal indicator
        lutLatin1ToXML[0xBB] = "&raquo"; // raquo	»	U+00BB (187)	HTML 3.2	HTMLlat1	ISOnum	right-pointing double angle quotation mark (= right pointing guillemet)
        lutLatin1ToXML[0xBC] = "&frac14"; // frac14	¼	U+00BC (188)	HTML 3.2	HTMLlat1	ISOnum	vulgar fraction one quarter (= fraction one quarter)
        lutLatin1ToXML[0xBD] = "&frac12"; // frac12	½	U+00BD (189)	HTML 3.2	HTMLlat1	ISOnum	vulgar fraction one half (= fraction one half)
        lutLatin1ToXML[0xBE] = "&frac34"; // frac34	¾	U+00BE (190)	HTML 3.2	HTMLlat1	ISOnum	vulgar fraction three quarters (= fraction three quarters)
        lutLatin1ToXML[0xBF] = "&iquest"; // iquest	¿	U+00BF (191)	HTML 3.2	HTMLlat1	ISOnum	inverted question mark (= turned question mark)
        lutLatin1ToXML[0xC0] = "&Agrave"; // Agrave	À	U+00C0 (192)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter A with grave accent (= Latin capital letter A grave)
        lutLatin1ToXML[0xC1] = "&Aacute"; // Aacute	Á	U+00C1 (193)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter A with acute accent
        lutLatin1ToXML[0xC2] = "&Acirc"; // Acirc	Â	U+00C2 (194)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter A with circumflex
        lutLatin1ToXML[0xC3] = "&Atilde"; // Atilde	Ã	U+00C3 (195)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter A with tilde
        lutLatin1ToXML[0xC4] = "&Auml"; // Auml	Ä	U+00C4 (196)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter A with diaeresis
        lutLatin1ToXML[0xC5] = "&Aring"; // Aring	Å	U+00C5 (197)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter A with ring above (= Latin capital letter A ring)
        lutLatin1ToXML[0xC6] = "&AElig"; // AElig	Æ	U+00C6 (198)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter AE (= Latin capital ligature AE)
        lutLatin1ToXML[0xC7] = "&Ccedil"; // Ccedil	Ç	U+00C7 (199)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter C with cedilla
        lutLatin1ToXML[0xC8] = "&Egrave"; // Egrave	È	U+00C8 (200)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter E with grave accent
        lutLatin1ToXML[0xC9] = "&Eacute"; // Eacute	É	U+00C9 (201)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter E with acute accent
        lutLatin1ToXML[0xCA] = "&Ecirc"; // Ecirc	Ê	U+00CA (202)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter E with circumflex
        lutLatin1ToXML[0xCB] = "&Euml"; // Euml	Ë	U+00CB (203)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter E with diaeresis
        lutLatin1ToXML[0xCC] = "&Igrave"; // Igrave	Ì	U+00CC (204)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter I with grave accent
        lutLatin1ToXML[0xCD] = "&Iacute"; // Iacute	Í	U+00CD (205)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter I with acute accent
        lutLatin1ToXML[0xCE] = "&Icirc"; // Icirc	Î	U+00CE (206)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter I with circumflex
        lutLatin1ToXML[0xCF] = "&Iuml"; // Iuml	Ï	U+00CF (207)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter I with diaeresis
        lutLatin1ToXML[0xD0] = "&ETH"; // ETH	Ð	U+00D0 (208)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter Eth
        lutLatin1ToXML[0xD1] = "&Ntilde"; // Ntilde	Ñ	U+00D1 (209)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter N with tilde
        lutLatin1ToXML[0xD2] = "&Ograve"; // Ograve	Ò	U+00D2 (210)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter O with grave accent
        lutLatin1ToXML[0xD3] = "&Oacute"; // Oacute	Ó	U+00D3 (211)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter O with acute accent
        lutLatin1ToXML[0xD4] = "&Ocirc"; // Ocirc	Ô	U+00D4 (212)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter O with circumflex
        lutLatin1ToXML[0xD5] = "&Otilde"; // Otilde	Õ	U+00D5 (213)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter O with tilde
        lutLatin1ToXML[0xD6] = "&Ouml"; // Ouml	Ö	U+00D6 (214)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter O with diaeresis
        lutLatin1ToXML[0xD7] = "&times"; // times	×	U+00D7 (215)	HTML 3.2	HTMLlat1	ISOnum	multiplication sign
        lutLatin1ToXML[0xD8] = "&Oslash"; // Oslash	Ø	U+00D8 (216)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter O with stroke (= Latin capital letter O slash)
        lutLatin1ToXML[0xD9] = "&Ugrave"; // Ugrave	Ù	U+00D9 (217)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter U with grave accent
        lutLatin1ToXML[0xDA] = "&Uacute"; // Uacute	Ú	U+00DA (218)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter U with acute accent
        lutLatin1ToXML[0xDB] = "&Ucirc"; // Ucirc	Û	U+00DB (219)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter U with circumflex
        lutLatin1ToXML[0xDC] = "&Uuml"; // Uuml	Ü	U+00DC (220)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter U with diaeresis
        lutLatin1ToXML[0xDD] = "&Yacute"; // Yacute	Ý	U+00DD (221)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter Y with acute accent
        lutLatin1ToXML[0xDE] = "&THORN"; // THORN	Þ	U+00DE (222)	HTML 2.0	HTMLlat1	ISOlat1	Latin capital letter THORN
        lutLatin1ToXML[0xDF] = "&szlig"; // szlig	ß	U+00DF (223)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter sharp s (= ess-zed); see German Eszett
        lutLatin1ToXML[0xE0] = "&agrave"; // agrave	à	U+00E0 (224)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter a with grave accent
        lutLatin1ToXML[0xE1] = "&aacute"; // aacute	á	U+00E1 (225)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter a with acute accent
        lutLatin1ToXML[0xE2] = "&acirc"; // acirc	â	U+00E2 (226)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter a with circumflex
        lutLatin1ToXML[0xE3] = "&atilde"; // atilde	ã	U+00E3 (227)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter a with tilde
        lutLatin1ToXML[0xE4] = "&auml"; // auml	ä	U+00E4 (228)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter a with diaeresis
        lutLatin1ToXML[0xE5] = "&aring"; // aring	å	U+00E5 (229)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter a with ring above
        lutLatin1ToXML[0xE6] = "&aelig"; // aelig	æ	U+00E6 (230)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter ae (= Latin small ligature ae)
        lutLatin1ToXML[0xE7] = "&ccedil"; // ccedil	ç	U+00E7 (231)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter c with cedilla
        lutLatin1ToXML[0xE8] = "&egrave"; // egrave	è	U+00E8 (232)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter e with grave accent
        lutLatin1ToXML[0xE9] = "&eacute"; // eacute	é	U+00E9 (233)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter e with acute accent
        lutLatin1ToXML[0xEA] = "&ecirc"; // ecirc	ê	U+00EA (234)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter e with circumflex
        lutLatin1ToXML[0xEB] = "&euml"; // euml	ë	U+00EB (235)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter e with diaeresis
        lutLatin1ToXML[0xEC] = "&igrave"; // igrave	ì	U+00EC (236)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter i with grave accent
        lutLatin1ToXML[0xED] = "&iacute"; // iacute	í	U+00ED (237)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter i with acute accent
        lutLatin1ToXML[0xEE] = "&icirc"; // icirc	î	U+00EE (238)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter i with circumflex
        lutLatin1ToXML[0xEF] = "&iuml"; // iuml	ï	U+00EF (239)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter i with diaeresis
        lutLatin1ToXML[0xF0] = "&eth"; // eth	ð	U+00F0 (240)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter eth
        lutLatin1ToXML[0xF1] = "&ntilde"; // ntilde	ñ	U+00F1 (241)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter n with tilde
        lutLatin1ToXML[0xF2] = "&ograve"; // ograve	ò	U+00F2 (242)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter o with grave accent
        lutLatin1ToXML[0xF3] = "&oacute"; // oacute	ó	U+00F3 (243)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter o with acute accent
        lutLatin1ToXML[0xF4] = "&ocirc"; // ocirc	ô	U+00F4 (244)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter o with circumflex
        lutLatin1ToXML[0xF5] = "&otilde"; // otilde	õ	U+00F5 (245)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter o with tilde
        lutLatin1ToXML[0xF6] = "&ouml"; // ouml	ö	U+00F6 (246)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter o with diaeresis
        lutLatin1ToXML[0xF7] = "&divide"; // divide	÷	U+00F7 (247)	HTML 3.2	HTMLlat1	ISOnum	division sign (= obelus)
        lutLatin1ToXML[0xF8] = "&oslash"; // oslash	ø	U+00F8 (248)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter o with stroke (= Latin small letter o slash)
        lutLatin1ToXML[0xF9] = "&ugrave"; // ugrave	ù	U+00F9 (249)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter u with grave accent
        lutLatin1ToXML[0xFA] = "&uacute"; // uacute	ú	U+00FA (250)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter u with acute accent
        lutLatin1ToXML[0xFB] = "&ucirc"; // ucirc	û	U+00FB (251)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter u with circumflex
        lutLatin1ToXML[0xFC] = "&uuml"; // uuml	ü	U+00FC (252)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter u with diaeresis
        lutLatin1ToXML[0xFD] = "&yacute"; // yacute	ý	U+00FD (253)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter y with acute accent
        lutLatin1ToXML[0xFE] = "&thorn"; // thorn	þ	U+00FE (254)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter thorn
        lutLatin1ToXML[0xFF] = "&yuml"; // yuml	ÿ	U+00FF (255)	HTML 2.0	HTMLlat1	ISOlat1	Latin small letter y with diaeresis
    }

    string toHTML(in string src,
                  ref in string[256] lut) @safe pure {
        return src.map!(a => lut[a].length ? lut[a] : "" ~ cast(ubyte)a).reduce!((a, b) => a ~ b);
    }

    private {

        bool doHTML = false;
        bool browseOutput = false;
        bool collectTypeHits = false;
        bool colorFlag = false;

        GStats gstats = new GStats();

        ScanContext _scanContext = ScanContext.standard;
        bool keyAsWord;
        bool keyAsSymbol;

        KeyStrictness keyStrictness = KeyStrictness.standard;
        bool _keyAsAcronym = false;
        bool _keyAsExact = false;

        int _scanDepth = -1;

        bool showTree = false;

        DirSorting subsSorting = DirSorting.onTimeLastModified;
        BuildType buildType = BuildType.none;
        DuplicatesContext duplicatesContext = DuplicatesContext.internal;

        PathFormat _pathFormat = PathFormat.relative;

        string _cacheFile = "~/.cache/fs-root.msgpack";
        bool _recache = false;

        bool _useNGrams = false;

        Dir[] _topDirs;
        Dir _rootDir;

        uid_t _uid;
        gid_t _gid;
    }

    ioFile outFile;

    string[] keys; // Keys to scan.
    typeof(keys.map!bistogramOverRepresentation) keysBists;
    typeof(keys.map!(sparseUIntNGramOverRepresentation!NGramOrder)) keysXGrams;
    Bist keysBistsUnion;
    XGram keysXGramsUnion;

    string incKindsNote;

    void prepare(string[] args, ref Term term) {
        bool helpPrinted = getoptEx("FS --- File System Scanning Utility in D.\n" ~
                                    "Usage: fs { --switches } [KEY]...\n" ~
                                    "Note that scanning for multiple KEYs is possible.\nIf so hits are highlighted in different colors!\n" ~
                                    "Sample calls: \n" ~
                                    "  fs.d --color -d /etc -s --tree --usage -l --duplicates stallman\n"
                                    "  fs.d --color -d /etc -d /var --acronym sttccc\n"
                                    "  fs.d --color -d /etc -d /var --acronym dktp\n"
                                    "  fs.d --color -d /etc -d /var --acronym tms sttc prc dtp xsr\n" ~
                                    "  fs.d --color -d /etc min max delta\n" ~
                                    "  fs.d --color -d /etc if elif return len --duplicates --sort=onSize\n" ~
                                    "  fs.d --color -k -d /bin alpha\n" ~
                                    "  fs.d --color -d /lib -k linus" ~
                                    "  fs.d --color -d /etc --symbol alpha beta gamma delta" ~
                                    "  fs.d --color -d /var/spool/postfix/dev ",

                                    args,
                                    std.getopt.config.caseInsensitive,

                                    "verbose|v", "\tVerbose",  &_beVerbose,

                                    "color|C", "\tColorize Output" ~ defaultDoc(colorFlag),  &colorFlag,
                                    "types|T", "\tComma separated list (CSV) of file types/kinds to scan" ~ defaultDoc(includedTypes), &includedTypes,
                                    "group-types|G", "\tCollect and group file types found" ~ defaultDoc(collectTypeHits), &collectTypeHits,

                                    "i", "\tCase-Fold, Case-Insensitive" ~ defaultDoc(_caseFold), &_caseFold,
                                    "k", "\tShow Skipped Directories and Files" ~ defaultDoc(_showSkipped), &_showSkipped,
                                    "d", "\tRoot Directory(s) of tree(s) to scan, defaulted to current directory" ~ defaultDoc(_topDirNames), &_topDirNames,
                                    "depth", "\tDepth of tree to scan, defaulted to unlimited (-1) depth" ~ defaultDoc(_scanDepth), &_scanDepth,

                                    // Contexts
                                    "context|x", "\tComma Separated List of Contexts. Either: " ~ enumDoc!ScanContext, &_scanContext,

                                    "word|w", "\tSearch for key as a complete Word (A Letter followed by more Letters and Digits)." ~ defaultDoc(keyAsWord), &keyAsWord,
                                    "symbol|ident|id|s", "\tSearch for key as a complete Symbol (Identifier)" ~ defaultDoc(keyAsSymbol), &keyAsSymbol,
                                    "acronym|a", "\tSearch for key as an acronym (relaxed)" ~ defaultDoc(_keyAsAcronym), &_keyAsAcronym,
                                    "exact", "\tSearch for key only with exact match (strict)" ~ defaultDoc(_keyAsExact), &_keyAsExact,

                                    "name-duplicates|snd", "\tDetect & Show file name duplicates" ~ defaultDoc(gstats.showNameDups), &gstats.showNameDups,
                                    "hardlink-duplicates|inode-duplicates|shd", "\tDetect & Show multiple links to same inode" ~ defaultDoc(gstats.showLinkDups), &gstats.showLinkDups,
                                    "content-duplicates|scd", "\tDetect & Show file contents duplicates" ~ defaultDoc(gstats.showContentDups), &gstats.showContentDups,
                                    "duplicates|D", "\tDetect & Show file name and contents duplicates" ~ defaultDoc(gstats.showAnyDups), &gstats.showAnyDups,
                                    "duplicates-context", "\tDuplicates Detection Context. Either: " ~ enumDoc!DuplicatesContext, &duplicatesContext,
                                    "hardlink-content-duplicates", "\tConvert all content duplicates into hardlinks (common inode) if they reside on the same file system" ~ defaultDoc(gstats.linkContentDups), &gstats.linkContentDups,

                                    "usage", "\tShow disk usage (tree size) of scanned directories" ~ defaultDoc(gstats.showUsage), &gstats.showUsage,
                                    "sha1", "\tShow SHA1 content digests" ~ defaultDoc(gstats.showSHA1), &gstats.showSHA1,

                                    "mmaps", "\tShow when files are memory mapped (mmaped)" ~ defaultDoc(gstats.showMMaps), &gstats.showMMaps,

                                    "follow-symlinks|f", "\tFollow symbolic linkes" ~ defaultDoc(gstats.followSymlinks), &gstats.followSymlinks,
                                    "broken-symlinks|l", "\tDetect & Show broken symbolic links (target is non-existing file) " ~ defaultDoc(gstats.showBrokenSymlinks), &gstats.showBrokenSymlinks,
                                    "show-symlink-cycles|l", "\tDetect & Show symbolic links cycles " ~ defaultDoc(gstats.showSymlinkCycles), &gstats.showSymlinkCycles,

                                    "add-tag", "\tAdd tag string(s) to matching files" ~ defaultDoc(addTags), &addTags,
                                    "remove-tag", "\tAdd tag string(s) to matching files" ~ defaultDoc(removeTags), &removeTags,

                                    "tree|W", "\tShow Scanned Tree and Followed Symbolic Links" ~ defaultDoc(showTree), &showTree,
                                    "sort|S", "\tDirectory contents sorting order. Either: " ~ enumDoc!DirSorting, &subsSorting,
                                    "build", "\tBuild Source Code. Either: " ~ enumDoc!BuildType, &buildType,

                                    "path-format", "\tFormat of paths. Either: " ~ enumDoc!PathFormat ~ "." ~ defaultDoc(_pathFormat), &_pathFormat,

                                    "cache-file|F", "\tFile System Tree Cache File" ~ defaultDoc(_cacheFile), &_cacheFile,
                                    "recache", "\tSkip initial load of cache from disk" ~ defaultDoc(_recache), &_recache,

                                    "use-ngrams", "\tUse NGrams to cache statistics and thereby speed up search" ~ defaultDoc(_useNGrams), &_useNGrams,

                                    "html|H", "\tFormat output as HTML" ~ defaultDoc(doHTML), &doHTML,
                                    "browse|B", "\tFormat output as HTML to a temporary file" ~ defaultDoc(_cacheFile) ~ " and open it with default Web browser" ~ defaultDoc(browseOutput), &browseOutput,
                                    "author", "\tPrint name of\n"~"\tthe author",
                                    delegate() { writeln("Per Nordlöw"); }
            );

        if (gstats.showAnyDups) {
            gstats.showNameDups = true;
            gstats.showLinkDups = true;
            gstats.showContentDups = true;
        }
        if (helpPrinted)
            return;

        _cacheFile = std.path.expandTilde(_cacheFile);

        if (_topDirNames.empty) {
            _topDirNames = ["."];
        }
        if (_topDirNames == ["."]) {
            _pathFormat = PathFormat.relative;
        } else {
            _pathFormat = PathFormat.absolute;
        }
        foreach (ref topName; _topDirNames) {
            if (topName ==  ".") {
                topName = topName.absolutePath.buildNormalizedPath;
            } else {
                topName = topName.expandTilde.buildNormalizedPath;
            }
        }

        // Output Handling
        if (browseOutput) {
            doHTML = true;
            immutable outExt = doHTML ? "html" : "results.txt";
            outFile = ioFile("/tmp/test." ~ outExt, "w");
            popen("firefox " ~ outFile.name);
        } else {
            outFile = stdout;
        }

        auto cwd = getcwd();

        foreach (arg; args[1..$]) {
            if (!arg.startsWith("-")) { // if argument not a flag
                keys ~= arg;
            }
        }

        // Calc stats
        keysBists = keys.map!bistogramOverRepresentation;
        keysXGrams = keys.map!(sparseUIntNGramOverRepresentation!NGramOrder);
        keysBistsUnion = reduce!"a | b"(typeof(keysBists.front).init, keysBists);
        keysXGramsUnion = reduce!"a + b"(typeof(keysXGrams.front).init, keysXGrams);

        if (_useNGrams &&
            (!keys.empty) &&
            keysXGramsUnion.empty) {
            _useNGrams = false;
            ppln(term, outFile, doHTML, colorFlag,
                 "Keys must be at least of length " ~
                 to!string(NGramOrder + 1) ~
                 " in order for " ~
                 keysXGrams[0].typeName ~
                 " to be calculated");
        }

        if (doHTML) {
            ppln(term, outFile, doHTML, colorFlag, "<!DOCTYPE html>
<html>
<head>
<style>
body { font: 8px Verdana, sans-serif; }
</style>
</head>

<body>");
        }

        // ppln(term, outFile, doHTML, colorFlag, "<meta http-equiv=\"refresh\" content=\"1\"/>"); // refresh every second

        if (includedTypes) {
            foreach (lang; includedTypes.splitter(",")) {
                if (lang in srcFKindsByName) {
                    incKinds ~= srcFKindsByName[lang];
                } else if (lang.toLower in srcFKindsByName) {
                    incKinds ~= srcFKindsByName[lang.toLower];
                } else if (lang.toUpper in srcFKindsByName) {
                    incKinds ~= srcFKindsByName[lang.toUpper];
                } else {
                    writeln("warning: Language ", lang, " not registered. Defaulting to all file types.");
                }
            }
        }

        // Maps extension string to Included FileKinds
        foreach (kind; incKinds) {
            foreach (ext; kind.exts) {
                incKindsByName[ext] ~= kind;
            }
            gstats.incKindsById[kind.behaviorId] = kind;
        }
        incKindsByName.rehash;
        gstats.incKindsById.rehash;

        // Keys
        auto commaedKeys = keys.joiner(",");
        const keysPluralExt = keys.length >= 2 ? "s" : "";
        string commaedKeysString = to!string(commaedKeys);
        if (keys) {
            incKindsNote = " in " ~ (incKinds ? incKinds.map!(a => a.kindName).join(",") ~ "-" : "all ") ~ "files";
            immutable underNote = " under \"" ~ (_topDirNames.reduce!"a ~ ',' ~ b") ~ "\"";
            const exactNote = _keyAsExact ? "exact " : "";
            string asNote;
            if (_keyAsAcronym) {
                asNote = (" as " ~ exactNote ~
                          (keyAsWord ? "word" : "symbol") ~
                          " acronym" ~ keysPluralExt);
            } else if (keyAsSymbol) {
                asNote = " as " ~ exactNote ~ "symbol" ~ keysPluralExt;
            } else if (keyAsWord) {
                asNote = " as " ~ exactNote ~ "word" ~ keysPluralExt;
            } else {
                asNote = "";
            }
            ppln(term, outFile, doHTML, colorFlag,
                 "Searching for \"" ~ commaedKeysString ~ "\"" ~
                 " case-" ~ (_caseFold ? "in" : "") ~"sensitively"
                 ~asNote ~incKindsNote ~underNote);
        }

        if (_showSkipped) {
            ppln(term, outFile, doHTML, colorFlag,
                 "Skipping files of type\n", binFKinds.map!"' '~a.kindName".reduce!"a ~ \"\n\" ~ b");
        }

        // if (key && key == key.toLower()) { // if search key is all lowercase
        //     _caseFold = true;               // we do case-insensitive search like in Emacs
        // }

        _uid = getuid();
        _gid = getgid();


        // Setup root directory
        if (!_recache) {
            GC.disable;
            _rootDir = loadRootDirTree(term, outFile, doHTML, colorFlag, _cacheFile, gstats);
            GC.enable;
        }
        if (!_rootDir) { // if first time
            _rootDir = new Dir("/", gstats); // filesystem root directory. TODO: Make this uncopyable?
        }

        // Scan for exact key match
        _topDirs = getDirs(enforceNotNull(_rootDir), _topDirNames);

        _currTime = Clock.currTime();

        GC.disable;
        scanTopDirs(term, outFile, doHTML, colorFlag, commaedKeysString);
        GC.enable;

        GC.disable;
        saveRootDirTree(term, outFile, doHTML, colorFlag, _rootDir, _cacheFile);
        GC.enable;
        term.setFace(stdFace, colorFlag);

        // Print statistics
        showStats(term);
    }

    void scanTopDirs(Term)(ref Term term, ioFile outFile, bool doHTML, bool colorFlag, string commaedKeysString)
    {
        if (_topDirs) {
            foreach (topIx, topDir; _topDirs) {
                scanDir(term, assumeNotNull(topDir), assumeNotNull(topDir), keys);
                if (ctrlC) {
                    auto restDirs = _topDirs[topIx + 1..$];
                    if (!restDirs.empty) {
                        debug dln("Ctrl-C pressed: Skipping search of " ~ to!string(restDirs));
                        break;
                    }
                }
            }

            // Scan for acronym key match
            if (keys && _hitsCountTotal == 0) { // if keys given but no hit found
                auto keysString = (keys.length >= 2 ? "s" : "") ~ " \"" ~ commaedKeysString;
                term.setFace(stdFace, colorFlag);
                if (_keyAsAcronym)  {
                    ppln(term, outFile, doHTML, colorFlag, "No acronym matches for key" ~ keysString ~ `"` ~
                         (keyAsSymbol ? " as symbol" : "") ~
                         " found in files of type");
                } else if (!_keyAsExact) {
                    ppln(term, outFile, doHTML, colorFlag, "No exact matches for key" ~ keysString ~ `"` ~
                         (keyAsSymbol ? " as symbol" : "") ~
                         " found" ~ incKindsNote ~
                         ". Relaxing scan to" ~ (keyAsSymbol ? " symbol" : "") ~ " acronym match.");
                    _keyAsAcronym = true;

                    foreach (topDir; _topDirs) {
                        scanDir(term, assumeNotNull(topDir), assumeNotNull(topDir), keys);
                    }
                }
            }

            if (doHTML) {
                ppln(term, outFile, doHTML, colorFlag, "</body>");
                ppln(term, outFile, doHTML, colorFlag, "</html>");
            }
        }

        assert(gstats.noScannedDirs +
               gstats.noScannedRegFiles +
               gstats.noScannedSymlinks +
               gstats.noScannedSpecialFiles == gstats.noScannedFiles);
    }

    version(linux) {
        @trusted bool readable(in stat_t stat, uid_t uid, gid_t gid, ref string msg) {
            immutable mode = stat.st_mode;
            immutable ok = ((stat.st_uid == uid) && (mode & S_IRUSR) ||
                            (stat.st_gid == gid) && (mode & S_IRGRP) ||
                            (mode & S_IROTH));
            if (!ok) {
                msg = " is not readable by you, but only by";
                bool can = false; // someone can access
                if (mode & S_IRUSR) {
                    can = true;
                    msg ~= " user id " ~ to!string(stat.st_uid);

                    // Lookup user name from user id
                    passwd pw;
                    passwd* pw_ret;
                    immutable size_t bufsize = 16384;
                    char* buf = cast(char*)core.stdc.stdlib.malloc(bufsize);
                    getpwuid_r(stat.st_uid, &pw, buf, bufsize, &pw_ret);
                    if (pw_ret != null) {
                        string userName;
                        {
                            size_t n = 0;
                            while (pw.pw_name[n] != 0) {
                                userName ~= pw.pw_name[n];
                                n++;
                            }
                        }
                        msg ~= " (" ~ userName ~ ")";

                        // string realName;
                        // {
                        //     size_t n = 0;
                        //     while (pw.pw_gecos[n] != 0) {
                        //         realName ~= pw.pw_gecos[n];
                        //         n++;
                        //     }
                        // }
                    }
                    core.stdc.stdlib.free(buf);

                }
                if (mode & S_IRGRP) {
                    can = true;
                    if (msg != "") {
                        msg ~= " or";
                    }
                    msg ~= " group id " ~ to!string(stat.st_gid);
                }
                if (!can) {
                    msg ~= " root";
                }
            }
            return ok;
        }
    }

    Results results;

    void handleError(F)(ref Term term, NotNull!F file, bool isDir, size_t subIndex) {
        auto dent = DirEntry(file.path);
        immutable stat_t stat = dent.statBuf();
        string msg;
        if (!readable(stat, _uid, _gid, msg)) {
            results.noBytesUnreadable += dent.size;
            if (_showSkipped) {
                if (showTree) {
                    auto parentDir = file.parent;
                    immutable intro = subIndex == parentDir.subs.length - 1 ? "└" : "├";
                    term.setFace(stdFace, colorFlag); pp(term, outFile, doHTML, colorFlag, "│  ".repeat(parentDir.depth + 1).join("") ~ intro ~ "─ ");
                }
                term.setFace(isDir ? dirFace : fileFace, colorFlag);
                pp(term, outFile, doHTML, colorFlag, asPath(doHTML, file.path, showTree ? file.name : file.path, false));
                term.setFace(warnFace, colorFlag);
                ppln(term, outFile, doHTML, colorFlag, ":  ", isDir ? "Directory" : "File", msg);
            }
        }
    }

    void printSkipped(ref Term term, NotNull!RegFile regfile,
                      in string ext, size_t subIndex,
                      in NotNull!FKind kind, KindHit kindhit,
                      in string skipCause)
    {
        auto parentDir = regfile.parent;
        if (_showSkipped) {
            if (showTree) {
                immutable intro = subIndex == parentDir.subs.length - 1 ? "└" : "├";
                term.setFace(stdFace, colorFlag); pp(term, outFile, doHTML, colorFlag, "│  ".repeat(parentDir.depth + 1).join("") ~ intro ~ "─ ");
            }
            term.setFace(fileFace, colorFlag);
            pp(term, outFile, doHTML, colorFlag, asPath(doHTML, regfile.path, showTree ? regfile.name : regfile.path, false));
            term.setFace(skipFileFace, colorFlag);
            ppln(term, outFile, doHTML, colorFlag,
                 ": Skipped " ~ kind.kindName ~ " file" ~ skipCause);
        }
    }

    KindHit isBinary(ref Term term, NotNull!RegFile regfile,
                     in string ext, size_t subIndex) {
        auto hit = KindHit.none;

        auto parentDir = regfile.parent;

        // First Try with kindId as try
        if (regfile._cstat.kindId.defined) { // kindId is already defined and uptodate
            if (regfile._cstat.kindId in binFKindsById) {
                const kind = enforceNotNull(binFKindsById[regfile._cstat.kindId]);
                hit = KindHit.cached;
                printSkipped(term, regfile, ext, subIndex, kind, hit,
                             " using cached KindId");
            } else {
                hit = KindHit.none;
            }
            return hit;
        }

        // First Try with extension lookup as guess
        if (!ext.empty && ext in binFKindsByExt) {
            foreach (kindIndex, kind; binFKindsByExt[ext]) {
                auto nnKind = enforceNotNull(kind);
                hit = regfile.ofKind(ext, nnKind, collectTypeHits, gstats.allKindsById);
                if (hit) {
                    printSkipped(term, regfile, ext, subIndex, nnKind, hit,
                                 " (" ~ ext ~ ") at " ~ nthString(kindIndex + 1) ~ " extension try");
                    break;
                }
            }
        }

        if (!hit) { // If still no hit
            foreach (kindIndex, kind; binFKinds) { // Iterate each kind
                auto nnKind = enforceNotNull(kind);
                hit = regfile.ofKind(ext, nnKind, collectTypeHits, gstats.allKindsById);
                if (hit) {
                    if (_showSkipped)  {
                        if (showTree) {
                            immutable intro = subIndex == parentDir.subs.length - 1 ? "└" : "├";
                            term.setFace(stdFace, colorFlag); pp(term, outFile, doHTML, colorFlag, "│  ".repeat(parentDir.depth + 1).join("") ~ intro ~ "─ ");
                        }
                        term.setFace(fileFace, colorFlag);
                        pp(term, outFile, doHTML, colorFlag, asPath(doHTML, regfile.path, showTree ? regfile.name : regfile.path, false));
                        term.setFace(skipFileFace, colorFlag); ppln(term, outFile, doHTML, colorFlag, ": Skipped " ~ kind.kindName ~ " file at ",
                                                                        nthString(kindIndex + 1), " blind try");
                    }
                    break;
                }
            }
        }
        return hit;
    }

    size_t _scanChunkSize;

    KindHit isIncludedKind(NotNull!RegFile regfile,
                           FKind[] incKinds) @safe /* nothrow */
    {
        return isIncludedKind(regfile, regfile.name.extension.chompPrefix("."), incKinds);
    }

    KindHit isIncludedKind(NotNull!RegFile regfile,
                           in string ext,
                           FKind[] incKinds) @safe /* nothrow */
    {
        typeof(return) kindHit = KindHit.none;
        FKind hitKind;

        // Try cached kind first
        // First Try with kindId as try
        if (regfile._cstat.kindId.defined) { // kindId is already defined and uptodate
            if (regfile._cstat.kindId in gstats.incKindsById) {
                hitKind = gstats.incKindsById[regfile._cstat.kindId];
                kindHit = KindHit.cached;
                return kindHit;
            }
        }

        // Try with hash table first
        if (!ext.empty && // if file has extension and
            ext in incKindsByName) { // and extensions may match specified included files
            auto possibleKinds = incKindsByName[ext];
            foreach (kind; possibleKinds) {
                auto nnKind = enforceNotNull(kind);
                immutable hit = regfile.ofKind(ext, nnKind, collectTypeHits, gstats.allKindsById);
                if (hit) {
                    hitKind = nnKind;
                    kindHit = hit;
                    break;
                }
            }
        }

        if (!hitKind) { // if no hit yet
            // blindly try the rest
            foreach (kind; incKinds) {
                auto nnKind = enforceNotNull(kind);
                immutable hit = regfile.ofKind(ext, nnKind, collectTypeHits, gstats.allKindsById);
                if (hit) {
                    hitKind = nnKind;
                    kindHit = hit;
                    break;
                }
            }
        }

        return kindHit;
    }

    /** Search for Keys $(D keys) in Source $(D src).
     */
    size_t scanForKeys(Source, Keys)(ref Term term,
                                     NotNull!Dir topDir,
                                     NotNull!File theFile,
                                     NotNull!Dir parentDir,
                                     ref Symlink[] fromSymlinks,
                                     in Source src,
                                     in Keys keys,
                                     in bool[] bistHits = [],
                                     ScanContext ctx = ScanContext.standard)
    {
        typeof(return) hitCount = 0;

        import std.ascii: newline;

        auto thisFace = stdFace;
        if (colorFlag) {
            if (ScanContext.fileName) {
                thisFace = fileFace;
            }
        }

        // GNU Grep-Compatible File Name/Path Formatting
        immutable displayedFileName = ((_pathFormat == PathFormat.relative &&
                                        _topDirs.length == 1) ?
                                       "./" ~ theFile.name :
                                       theFile.path);

        size_t nL = 0; // line counter
        foreach (line; src.splitter(cast(immutable ubyte[])newline)) {
            auto rest = cast(string)line; // rest of line as a string

            bool anyHit = false; // will become true if any hit on current line
            // Hit search loop
            while (!rest.empty) {
                // Find any key

                /* TODO: Convert these to a range. */
                ptrdiff_t offKB = -1;
                ptrdiff_t offKE = -1;

                foreach (ix, key; keys) { // TODO: Call variadic-find instead to speed things up.

                    /* Bistogram Discardal */
                    if ((!bistHits.empty) &&
                        !bistHits[ix]) { // if neither exact nor acronym match possible
                        continue; // try next key
                    }

                    /* dln("key:", key, " line:", line); */
                    ptrdiff_t[] acronymOffsets;
                    if (_keyAsAcronym) { // acronym search
                        auto hit = (cast(immutable ubyte[])rest).findAcronymAt(key,
                                                                               keyAsSymbol ? FindContext.inSymbol : FindContext.inWord);
                        if (!hit[0].empty) {
                            acronymOffsets = hit[1];
                            offKB = hit[1][0];
                            offKE = hit[1][$-1] + 1;
                        }
                    } else { // normal search
                        import std.string: indexOf;
                        offKB = rest.indexOf(key,
                                             _caseFold ? CaseSensitive.no : CaseSensitive.yes); // hit begin offset
                        offKE = offKB + key.length; // hit end offset
                    }

                    if (offKB >= 0) { // if hit
                        if (!showTree && ctx == ScanContext.fileName) {
                            term.setFace(dirFace, colorFlag);
                            pp(term, outFile, doHTML, colorFlag, parentDir, dirSeparator);
                        }

                        // Check Context
                        if ((keyAsSymbol && !isSymbolASCII(rest, offKB, offKE)) ||
                            (keyAsWord   && !isWordASCII  (rest, offKB, offKE))) {
                            rest = rest[offKE..$]; // move forward in line
                            continue;
                        }

                        if (ctx == ScanContext.fileContent &&
                            !anyHit) { // if this is first hit
                            if (showTree) {
                                term.setFace(stdFace, colorFlag);
                                pp(term, outFile, doHTML, colorFlag, "│  ".repeat(parentDir.depth + 1).join("") ~ "├" ~ "─ ");
                            } else {
                                foreach (fromSymlink; fromSymlinks) {
                                    term.setFace(symlinkFace, colorFlag);
                                    pp(term, outFile, doHTML, colorFlag,
                                       asPath(doHTML, fromSymlink.path, fromSymlink.path, false));
                                    term.setFace(timeFace, colorFlag);
                                    pp(term, outFile, doHTML, colorFlag,
                                       " modified ",
                                       shortDurationString(_currTime - fromSymlink.timeLastModified) , " ago");
                                    term.setFace(stdFace, colorFlag); pp(term, outFile, doHTML, colorFlag, " -> ");
                                }

                                // show file path/name
                                term.setFace(regFileFace, colorFlag);
                                pp(term, outFile, doHTML, colorFlag,
                                   asPath(doHTML, theFile.path, displayedFileName, false)); // show path
                            }

                            // show file line:column
                            term.setFace(contextFace, colorFlag); pp(term, outFile, doHTML, colorFlag, ":",nL+1, ":",offKB+1, ":");
                        }
                        anyHit = true; // at least hit

                        // show content prefix
                        term.setFace(thisFace, colorFlag);
                        pp(term, outFile, doHTML, colorFlag, rest[0..offKB]);

                        // show hit part
                        immutable cIx = ix % keyFaces.length;
                        immutable ctxFace = ctxFaces[cIx];
                        immutable keyFace = keyFaces[cIx];
                        if (!acronymOffsets.empty) {
                            foreach (aIx, currOff; acronymOffsets) { // TODO: Reuse std.algorithm: zip or lockstep? Or create a new kind say named conv.
                                // context before
                                if (aIx >= 1) {
                                    immutable prevOff = acronymOffsets[aIx-1];
                                    if (prevOff + 1 < currOff) { // at least one letter in between
                                        term.setFace(ctxFace, colorFlag); pp(term, outFile, doHTML, colorFlag, rest[prevOff + 1 .. currOff]);
                                    }
                                }
                                // hit letter
                                term.setFace(keyFace, colorFlag); pp(term, outFile, doHTML, colorFlag, rest[currOff]);
                            }
                        } else {
                            term.setFace(keyFace, colorFlag); pp(term, outFile, doHTML, colorFlag, rest[offKB..offKE]);
                        }

                        rest = rest[offKE..$]; // move forward in line

                        hitCount++; // increase hit count
                        parentDir.hitCount++;
                        _hitsCountTotal++;

                        goto foundHit;
                    }
                }
            foundHit:
                if (offKB == -1) { break; }
            }

            // finalize line
            if (anyHit)  {
                // show final context suffix
                term.setFace(thisFace, colorFlag); ppln(term, outFile, doHTML, colorFlag, rest);
            }
            nL++;
        }

        // Previous solution
        // version(none) {
        //     ptrdiff_t offHit = 0;
        //     foreach(ix, key; keys) {
        //         scope immutable hit1 = src.find(key); // single key hit
        //         offHit = hit1.ptr - src.ptr;
        //         if (!hit1.empty) {
        //             scope immutable src0 = src[0..offHit]; // src beforce hi
        //             immutable rowHit = count(src0, newline);
        //             immutable colHit = src0.retro.countUntil(newline); // count backwards till beginning of rowHit
        //             immutable offBOL = offHit - colHit;
        //             immutable cntEOL = src[offHit..$].countUntil(newline); // count forwards to end of rowHit
        //             immutable offEOL = (cntEOL == -1 ? // if no hit
        //                                 src.length :   // end of file
        //                                 offHit + cntEOL); // normal case
        //             term.setFace(pathFace, colorFlag); pp(term, outFile, doHTML, colorFlag, asPath(doHTML, dent.name));
        //             term.setFace(stdFace, colorFlag); ppln(term, outFile, doHTML, colorFlag, ":", rowHit + 1,
        //                                                                               ":", colHit + 1,
        //                                                                               ":", cast(string)src[offBOL..offEOL]);
        //         }
        //     }
        // }

        // switch (keys.length) {
        // default:
        //     break;
        // case 0:
        //     break;
        // case 1:
        //     immutable hit1 = src.find(keys[0]);
        //     if (!hit1.empty) {
        //         ppln(term, outFile, doHTML, colorFlag, asPath(doHTML, dent.name[2..$]), ":1: HIT offset: ", hit1.length);
        //     }
        //     break;
        // // case 2:
        // //     immutable hit2 = src.find(keys[0], keys[1]); // find two keys
        // //     if (!hit2[0].empty) { ppln(term, outFile, doHTML, colorFlag, asPath(doHTML, dent.name[2..$]), ":1: HIT offset: ", hit2[0].length); }
        // //     if (!hit2[1].empty) { ppln(term, outFile, doHTML, colorFlag, asPath(doHTML, dent.name[2..$]) , ":1: HIT offset: ", hit2[1].length); }
        // //     break;
        // // case 3:
        // //     immutable hit3 = src.find(keys[0], keys[1], keys[2]); // find two keys
        // //     if (!hit3.empty) {
        // //         ppln(term, outFile, doHTML, colorFlag, asPath(doHTML, dent.name[2..$]) , ":1: HIT offset: ", hit1.length);
        // //     }
        // //     break;
        // }
        return hitCount;
    }

    /** Search for Keys $(D keys) in Regular File $(D theRegFile). */
    void scanRegFile(ref Term term,
                     NotNull!Dir topDir,
                     NotNull!RegFile theRegFile,
                     NotNull!Dir parentDir,
                     in string[] keys,
                     ref Symlink[] fromSymlinks,
                     size_t subIndex) {
        results.noBytesTotal += theRegFile.size;
        results.noBytesTotalContents += theRegFile.size;

        // Scan name
        if ((_scanContext == ScanContext.all ||
             _scanContext == ScanContext.fileName ||
             _scanContext == ScanContext.regularFileName) &&
            !keys.empty) {
            immutable hitCountInName = scanForKeys(term,
                                                   topDir, cast(NotNull!File)theRegFile, parentDir,
                                                   fromSymlinks,
                                                   theRegFile.name, keys, [], ScanContext.fileName);
        }

        // Scan Contents
        if ((_scanContext == ScanContext.all ||
             _scanContext == ScanContext.fileContent) &&
            (gstats.showContentDups ||
             !keys.empty) &&
            theRegFile.size != 0) {        // non-empty file
            // immutable upTo = size_t.max;

            // TODO: Flag for readText
            try {

                ++gstats.noScannedRegFiles;
                ++gstats.noScannedFiles;

                immutable ext = theRegFile.name.extension.chompPrefix("."); // extension sans dot

                // Check included kinds first because they are fast.
                KindHit incKindHit = isIncludedKind(theRegFile, ext, incKinds);
                if (!incKinds.empty && // TODO: Do we really need this one?
                    !incKindHit) {
                    return;
                }

                // Super-Fast Key-File Bistogram Discardal. TODO: Trim scale factor to optimal value.
                enum minFileSize = 256; // minimum size of file for discardal.
                immutable bool doBist = theRegFile.size > minFileSize;
                immutable bool doNGram = (_useNGrams &&
                                          (!keyAsSymbol) &&
                                          theRegFile.size > minFileSize);
                immutable bool doBitStatus = true;

                // Chunked Calculation of CStat in one pass. TODO: call async.
                theRegFile.calculateCStatInChunks(_scanChunkSize,
                                                  gstats.showContentDups,
                                                  doBist,
                                                  doBitStatus,
                                                  gstats.filesByContId);

                // Match Bist of Keys with BistX of File
                bool[] bistHits;
                bool noBistMatch = false;
                if (doBist) {
                    const theHist = theRegFile.bistogram8;
                    auto hitsHist = keysBists.map!(a =>
                                                   ((a.value() & theHist.value()) ==
                                                    a.value())); // TODO: Functionize to x.subsetOf(y) or reuse std.algorithm: setDifference or similar
                    bistHits = hitsHist.map!"a == true".array;
                    noBistMatch = hitsHist.all!"a == false";
                }
                /* int kix = 0; */
                /* foreach (hit; bistHits) { if (!hit) { debug dln("Assert key " ~ keys[kix] ~ " not in file " ~ theRegFile.path); } ++kix; } */

                bool allXGramsMiss = false;
                if (doNGram) {
                    ulong keysXGramUnionMatch = keysXGramsUnion.matchDenser(theRegFile.xgram);
                    debug dln(theRegFile.path,
                              " sized ", theRegFile.size, " : ",
                              keysXGramsUnion.length, ", ",
                              theRegFile.xgram.length,
                              " gave match:", keysXGramUnionMatch);
                    allXGramsMiss = keysXGramUnionMatch == 0;
                }

                immutable binFlag = isBinary(term, theRegFile, ext, subIndex);

                if (binFlag || noBistMatch || allXGramsMiss) // or no hits possible. TODO: Maybe more efficient to do histogram discardal first
                {
                    results.noBytesSkipped += theRegFile.size;
                } else {

                    // Search if not Binary

                    // If Source file is ok
                    auto src = theRegFile.readOnlyContents[];

                    results.noBytesScanned += theRegFile.size;

                    if (keys) {
                        // Fast discardal of files with no match
                        bool fastOk = true;
                        if (!_caseFold) { // if no relaxation of search
                            if (_keyAsAcronym) { // if no relaxation of search
                                /* TODO: Reuse findAcronym in algorith_ex. */
                            } else { // if no relaxation of search
                                switch (keys.length) {
                                default: break;
                                case 1: immutable hit1 = src.find(keys[0]); fastOk = !hit1.empty; break;
                                    // case 2: immutable hit2 = src.find(keys[0], keys[1]); fastOk = !hit2[0].empty; break;
                                    // case 3: immutable hit3 = src.find(keys[0], keys[1], keys[2]); fastOk = !hit3[0].empty; break;
                                    // case 4: immutable hit4 = src.find(keys[0], keys[1], keys[2], keys[3]); fastOk = !hit4[0].empty; break;
                                    // case 5: immutable hit5 = src.find(keys[0], keys[1], keys[2], keys[3], keys[4]); fastOk = !hit5[0].empty; break;
                                }
                            }
                        }

                        // TODO: Continue search from hit1, hit2 etc.

                        if (fastOk) {
                            foreach (tag; addTags) gstats.ftags.addTag(theRegFile, tag);
                            foreach (tag; removeTags) gstats.ftags.removeTag(theRegFile, tag);

                            if (theRegFile.size >= 8192) {
                                /* if (theRegFile.xgram == null) { */
                                /*     theRegFile.xgram = cast(XGram*)core.stdc.stdlib.malloc(XGram.sizeof); */
                                /* } */
                                /* (*theRegFile.xgram).put(src); */
                                /* theRegFile.xgram.put(src); */
                                /* foreach (lix, ub0; line) { // for each ubyte in line */
                                /*     if (lix + 1 < line.length) { */
                                /*         immutable ub1 = line[lix + 1]; */
                                /*         immutable dix = (cast(ushort)ub0 | */
                                /*                          cast(ushort)ub1*256); */
                                /*         (*theRegFile.xgram)[dix] = true; */
                                /*     } */
                                /* } */
                                auto shallowDenseness = theRegFile.bistogram8.denseness;
                                auto deepDenseness = theRegFile.xgramDeepDenseness;
                                // assert(deepDenseness >= 1);
                                gstats.shallowDensenessSum += shallowDenseness;
                                gstats.deepDensenessSum += deepDenseness;
                                ++gstats.densenessCount;
                                /* dln(theRegFile.path, ":", theRegFile.size, */
                                /*     ", length:", theRegFile.xgram.length, */
                                /*     ", deepDenseness:", deepDenseness); */
                            }

                            theRegFile._cstat.hitCount = scanForKeys(term,
                                                                     topDir, cast(NotNull!File)theRegFile, parentDir,
                                                                     fromSymlinks,
                                                                     src, keys, bistHits,
                                                                     ScanContext.fileContent);
                        }
                    }
                }

            } catch (FileException) {
                handleError(term, theRegFile, false, subIndex);
            } catch (ErrnoException) {
                handleError(term, theRegFile, false, subIndex);
            }
            theRegFile.freeContents;
        }
    }

    /** Scan Symlink $(D symlink) at $(D parentDir) for $(D keys)
        Put results in $(D results). */
    void scanSymlink(ref Term term,
                     NotNull!Dir topDir,
                     NotNull!Symlink theSymlink,
                     NotNull!Dir parentDir,
                     in string[] keys,
                     ref Symlink[] fromSymlinks)
    {
        // check for symlink cycles
        if (!fromSymlinks.find(theSymlink).empty) {
            if (gstats.showSymlinkCycles) {
                import std.range: back;
                ppln(term, outFile, doHTML, colorFlag,
                     "Cycle of symbolic links: " ~ to!string(fromSymlinks.map!"a.path") ~ " -> " ~ to!string(fromSymlinks.back.target));
            }
            return;
        }

        // Scan name
        if ((_scanContext == ScanContext.all ||
             _scanContext == ScanContext.fileName ||
             _scanContext == ScanContext.symlinkName) &&
            !keys.empty) {
            scanForKeys(term,
                        topDir, cast(NotNull!File)theSymlink, enforceNotNull(theSymlink.parent),
                        fromSymlinks,
                        theSymlink.name, keys, [], ScanContext.fileName);
        }

        // try {
        //     results.noBytesTotal += dent.size;
        // } catch (Exception) {
        //     dln("Could not get size of ",  dir.name);
        // }
        if (gstats.followSymlinks == SymlinkFollowContext.none) { return; }

        import std.range: popBackN;
        fromSymlinks ~= theSymlink;
        immutable targetPath = theSymlink.absoluteNormalizedTargetPath;
        if (targetPath.exists) {
            if (_topDirNames.all!(a => !targetPath.startsWith(a))) { // if target path lies outside of all rootdirs
                auto targetDent = DirEntry(targetPath);
                auto targetFile = getFile(enforceNotNull(_rootDir), targetPath, targetDent);

                if (showTree) {
                    term.setFace(stdFace, colorFlag); pp(term, outFile, doHTML, colorFlag, "│  ".repeat(parentDir.depth + 1).join("") ~ "├" ~ "─ ");
                    term.setFace(symlinkFace, colorFlag); pp(term, outFile, doHTML, colorFlag, theSymlink.name);
                    term.setFace(timeFace, colorFlag); pp(term, outFile, doHTML, colorFlag, " modified ",
                                                              shortDurationString(_currTime - theSymlink.timeLastModified), " ago");

                    term.setFace(stdFace, colorFlag); pp(term, outFile, doHTML, colorFlag, " -> ");

                    term.setFace(targetFile.face, colorFlag); pp(term, outFile, doHTML, colorFlag, theSymlink.target);

                    term.setFace(infoFace, colorFlag); pp(term, outFile, doHTML, colorFlag, " lying outside of " ~ (_topDirNames.length == 1 ? "tree " : "all trees "));
                    term.setFace(dirFace, colorFlag); pp(term, outFile, doHTML, colorFlag, _topDirNames.reduce!"a ~ ',' ~ b");
                    term.setFace(infoFace, colorFlag); ppln(term, outFile, doHTML, colorFlag, " is followed");
                }

                ++gstats.noScannedSymlinks;
                ++gstats.noScannedFiles;

                if      (auto targetRegFile = cast(RegFile)targetFile) {
                    scanRegFile(term, topDir, assumeNotNull(targetRegFile), parentDir, keys, fromSymlinks, 0);
                }
                else if (auto targetDir = cast(Dir)targetFile) {
                    scanDir(term, topDir, assumeNotNull(targetDir), keys, fromSymlinks);
                }
                else if (auto targetSymlink = cast(Symlink)targetFile) { // target is a Symlink
                    scanSymlink(term, topDir, assumeNotNull(targetSymlink), enforceNotNull(targetSymlink.parent), keys, fromSymlinks);
                }
            }
        } else {
            if (gstats.showBrokenSymlinks) {
                _brokenSymlinks ~= theSymlink;

                foreach (ix, fromSymlink; fromSymlinks) {
                    if (showTree && ix == 0) {
                        immutable intro = "├";
                        term.setFace(stdFace, colorFlag);
                        pp(term, outFile, doHTML, colorFlag,
                           "│  ".repeat(theSymlink.parent.depth + 1).join("") ~ intro ~ "─ ");
                        term.setFace(symlinkFace, colorFlag);
                        pp(term, outFile, doHTML, colorFlag,
                           asPath(doHTML, theSymlink.path, theSymlink.name, false));
                    }
                    else {
                        term.setFace(symlinkFace, colorFlag);
                        pp(term, outFile, doHTML, colorFlag,
                           asPath(doHTML, fromSymlink.path, fromSymlink.path, false));
                    }
                    term.setFace(stdFace, colorFlag); pp(term, outFile, doHTML, colorFlag, " -> ");
                }

                term.setFace(errorFace, colorFlag); pp(term, outFile, doHTML, colorFlag, theSymlink.target);
                term.setFace(warnFace, colorFlag); pp(term, outFile, doHTML, colorFlag, " is missing");
                ppln(term, outFile, doHTML, colorFlag);
            }
        }
        fromSymlinks.popBackN(1);
    }

    /** Scan Directory $(D parentDir) for $(D keys). */
    void scanDir(ref Term term,
                 NotNull!Dir topDir,
                 NotNull!Dir theDir,
                 in string[] keys,
                 Symlink[] fromSymlinks = [],
                 int maxDepth = -1) {
        if (theDir.isRoot)  { results.reset(); }

        // Scan name
        if ((_scanContext == ScanContext.all ||
             _scanContext == ScanContext.fileName ||
             _scanContext == ScanContext.dirName) &&
            !keys.empty) {
            scanForKeys(term,
                        topDir,
                        cast(NotNull!File)theDir,
                        enforceNotNull(theDir.parent),
                        fromSymlinks,
                        theDir.name, keys, [], ScanContext.fileName);
        }

        try {
            size_t subIndex = 0;
            if (showTree) {
                immutable intro = subIndex == theDir.subs.length - 1 ? "└" : "├";
                term.setFace(stdFace, colorFlag); pp(term, outFile, doHTML, colorFlag, "│  ".repeat(theDir.depth).join("") ~ intro ~
                                                     "─ ");
                immutable dirName = theDir.isRoot ? dirSeparator : theDir.name;
                term.setFace(dirFace, colorFlag); pp(term, outFile, doHTML, colorFlag, asPath(doHTML, theDir.path, dirName, true));
                term.setFace(timeFace, colorFlag); pp(term, outFile, doHTML, colorFlag, " modified ",
                                                          shortDurationString(_currTime - theDir.timeLastModified), " ago");
                if (gstats.showUsage) {
                    term.setFace(timeFace, colorFlag);
                    pp(term, outFile, doHTML, colorFlag, " of Tree-Size ", theDir.treeSize);
                }
                if (gstats.showSHA1) {
                    pp(term, outFile, doHTML, colorFlag, " with Tree-Content-Id ", theDir.treeContId);
                }
                endl(term, outFile, doHTML, colorFlag);
            }

            ++gstats.noScannedDirs;
            ++gstats.noScannedFiles;

            auto subsSorted = theDir.subsSorted(subsSorting);
            foreach (key, sub; subsSorted) {
                if (auto regfile = cast(RegFile)sub) {
                    scanRegFile(term, topDir, assumeNotNull(regfile), theDir, keys, fromSymlinks, subIndex);
                }
                else if (auto subDir = cast(Dir)sub) {
                    if (maxDepth == -1 || // if either all levels or
                        maxDepth >= 1) { // levels left
                        // Version Control System Directories
                        if (sub.name in skippedDirKindsMap)  {
                            if (_showSkipped) {
                                if (showTree) {
                                    immutable intro = subIndex == theDir.subs.length - 1 ? "└" : "├";
                                    term.setFace(stdFace, colorFlag);
                                    pp(term, outFile, doHTML, colorFlag, "│  ".repeat(theDir.depth + 1).join("") ~ intro ~ "─ ");
                                }
                                term.setFace(dirFace, colorFlag);
                                pp(term, outFile, doHTML, colorFlag,
                                   asPath(doHTML, subDir.path, showTree ? subDir.name : subDir.path, true));

                                term.setFace(timeFace, colorFlag); pp(term, outFile, doHTML, colorFlag, " modified ",
                                                                      shortDurationString(_currTime - subDir.timeLastModified), " ago");

                                term.setFace(infoFace, colorFlag); ppln(term, outFile, doHTML, colorFlag, ": Skipped Directory of type ", skippedDirKindsMap[sub.name].kindName);
                                term.setFace(stdFace, colorFlag);
                            }
                        } else {
                            scanDir(term, topDir, assumeNotNull(subDir), keys, fromSymlinks, maxDepth >= 0 ? --maxDepth : maxDepth);
                        }
                    }
                }
                else if (auto subSymlink = cast(Symlink)sub) {
                    scanSymlink(term, topDir, assumeNotNull(subSymlink), theDir, keys, fromSymlinks);
                }
                else {
                    if (showTree) { ppln(term, outFile, doHTML, colorFlag); }
                }
                ++subIndex;

                if (ctrlC) {
                    ppln(term, outFile, doHTML, colorFlag, "Ctrl-C pressed: Aborting scan of ", theDir);
                    break;
                }
            }
        } catch (FileException) {
            handleError(term, theDir, true, 0);
        }
    }

    /* isIncludedKind(cast(NotNull!File)dupFile, */
    /*                dupFile.name.extension.chompPrefix("."), */
    /*                incKinds) */

    // Filter out $(D files) that lie under any of the directories $(D dirPaths).
    F[] filterUnderAnyOfPaths(F)(F[] files,
                                 string[] dirPaths,
                                 FKind[] incKinds) {
        import std.algorithm: any;
        import std.array: array;
        auto dupFilesUnderAnyTopDirName = (files
                                           .filter!(dupFile =>
                                                    dirPaths.any!(dirPath =>
                                                                  dupFile.path.startsWith(dirPath)))
                                           .array // evaluate to array to get .length below
            );
        F[] hits;
        final switch (duplicatesContext) {
        case DuplicatesContext.internal:
            if (dupFilesUnderAnyTopDirName.length >= 2)
                hits = dupFilesUnderAnyTopDirName;
            break;
        case DuplicatesContext.external:
            if (dupFilesUnderAnyTopDirName.length >= 1)
                hits = files;
            break;
        }
        return hits;
    }

    /** Show Statistics. */
    void showStats(ref Term term)
    {
        /* Duplicates */

        /* Name Duplicates */
        if (gstats.showNameDups) {
            foreach (digest, dupFiles; gstats.filesByName) {
                auto dupFilesOk = filterUnderAnyOfPaths(dupFiles, _topDirNames, incKinds);
                if (!dupFilesOk.empty) {
                    term.setFace(infoFace, colorFlag);
                    ppln(term, outFile, doHTML, colorFlag, "Files with same name: ", dupFilesOk[0].name);
                    foreach (dupFile; dupFilesOk) {
                        ppln(term, outFile, doHTML, colorFlag, " ", dupFile);
                    }
                }
            }
        }

        /* Link Duplicates */
        if (gstats.showLinkDups) {
            foreach (inode, dupFiles; gstats.filesByInode) {
                auto dupFilesOk = filterUnderAnyOfPaths(dupFiles, _topDirNames, incKinds);
                if (dupFilesOk.length >= 2) {
                    term.setFace(infoFace, colorFlag);
                    ppln(term, outFile, doHTML, colorFlag, "Files with same inode (hardlinks): ", inode);
                    foreach (dupFile; dupFilesOk) {
                        ppln(term, outFile, doHTML, colorFlag, " ", dupFile);
                    }
                }
            }
        }

        /* Content Duplicates */
        if (gstats.showContentDups) {
            foreach (digest, dupFiles; gstats.filesByContId) {
                auto dupFilesOk = filterUnderAnyOfPaths(dupFiles, _topDirNames, incKinds);
                if (dupFilesOk.length >= 2) {
                    term.setFace(infoFace, colorFlag);
                    immutable typeName = cast(RegFile)dupFilesOk[0] ? "Files" : "Directories";
                    pp(term, outFile, doHTML, colorFlag,
                       typeName,
                       " with same content");
                    if (gstats.showSHA1)
                        pp(term, outFile, doHTML, colorFlag,
                           " (", digest, ")");
                    ppln(term, outFile, doHTML, colorFlag,
                         " of size ", dupFilesOk[0].size);
                    foreach (dupFile; dupFilesOk) {
                        ppln(term, outFile, doHTML, colorFlag, " ", dupFile);
                    }
                }
            }
        }

        /* Broken Symlinks */
        if (gstats.showBrokenSymlinks &&
            !_brokenSymlinks.empty) {
            term.setFace(infoFace, colorFlag);
            ppln(term, outFile, doHTML, colorFlag, "Broken Symlinks ");
            foreach (bsl; _brokenSymlinks) {
                ppln(term, outFile, doHTML, colorFlag, " ", bsl);
            }
            term.setFace(stdFace, colorFlag);
        }

        /* Counts */
        pp(term, outFile, doHTML, colorFlag, "Scanned ");
        pp(term, outFile, doHTML, colorFlag, gstats.noScannedDirs, " Dirs, ");
        pp(term, outFile, doHTML, colorFlag, gstats.noScannedRegFiles, " Regular Files, ");
        pp(term, outFile, doHTML, colorFlag, gstats.noScannedSymlinks, " Symbolic Links, ");
        pp(term, outFile, doHTML, colorFlag, gstats.noScannedSpecialFiles, " Special Files, ");
        ppln(term, outFile, doHTML, colorFlag, "totalling ", gstats.noScannedFiles, " Files"); // on extra because of lack of root

        if (gstats.densenessCount) {
            ppln(term, outFile, doHTML, colorFlag, "Average Byte Bistogram (Binary Histogram) Denseness ",
                 cast(real)(100*gstats.shallowDensenessSum / gstats.densenessCount), " Percent");
            ppln(term, outFile, doHTML, colorFlag, "Average Byte ", NGramOrder, "-Gram Denseness ",
                 cast(real)(100*gstats.deepDensenessSum / gstats.densenessCount), " Percent");
        }

        ppln(term, outFile, doHTML, colorFlag, "Scanned ", results.noBytesScanned);
        ppln(term, outFile, doHTML, colorFlag, "Skipped ", results.noBytesSkipped);
        ppln(term, outFile, doHTML, colorFlag, "Unreadable ", results.noBytesUnreadable);
        ppln(term, outFile, doHTML, colorFlag, "Total Contents ", results.noBytesTotalContents);
        ppln(term, outFile, doHTML, colorFlag, "Total ", results.noBytesTotal);
        ppln(term, outFile, doHTML, colorFlag, "Total number of hits ", results.numTotalHits);
        ppln(term, outFile, doHTML, colorFlag, "Number of Files with hits ", results.numFilesWithHits);
    }
}

Scanner!Term scanner(Term)(string[] args, ref Term term)
{
    return new Scanner!Term(args, term);
}

void main(string[] args)
{
    // Register the SIGINT signal with the signalHandler function call:
    version(linux) {
        signal(SIGABRT, &signalHandler);
        signal(SIGTERM, &signalHandler);
        signal(SIGQUIT, &signalHandler);
        signal(SIGINT, &signalHandler);
    }

    import std.stdio: stderr;
    /* backtrace.backtrace.install(stderr); */

    auto term = Terminal(ConsoleOutputType.linear);

    // term.setTitle("Basic I/O");
    // auto input = RealTimeConsoleInput(term, &term,
    //                                   ConsoleInputFlags.raw |
    //                                   ConsoleInputFlags.mouse |
    //                                   ConsoleInputFlags.paste);
    // term.write("test some long string to see if it wraps or what because i dont really know what it is going to do so i just want to test i think it will wrap but gotta be sure lolololololololol");
    // term.writefln("%d %d", term.cursorX, term.cursorY);
    // term.writeln("fdsfdfsfsfdf");

    auto s = scanner(args, term);
}
