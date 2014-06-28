#!/usr/bin/env rdmd-dev

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

   TODO: Sort file duplicates

   TODO: Visualize hits using existingFileHitContext.asH!1 followed by a table:
         ROW_NR | hit string in <code lang=LANG></code>

   TODO: Parse and Sort GCC/Clang Compiler Messages on WARN_TYPE FILE:LINE:COL:MSG[WARN_TYPE] and use Collapsable HTML Widgets:
         http://api.jquerymobile.com/collapsible/
         when presenting them

   TODO: Prevent rescans of duplicates

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

   TODO: Perhaps use http://www.chartjs.org/ to visualize stuff

   TODO: Make use of @nonPacked in version(msgpack).
*/
module fs;

version = msgpack; // Use msgpack serialization
/* version = cerealed; // Use cerealed serialization */

import std.stdio: ioFile = File, stdout;
import std.typecons: Tuple, tuple;
import std.algorithm: find, map, filter, reduce, max, min, uniq, all, joiner;
import std.string: representation;
import std.stdio: write, writeln;
import std.path: baseName, dirName, isAbsolute, dirSeparator;
import std.datetime;
import std.file: FileException;
import std.digest.sha: sha1Of, toHexString;
import std.range: repeat, array, empty, cycle;
import std.stdint: uint64_t;
import std.traits: Unqual, isInstanceOf, isIterable;
//import std.allocator;
import core.memory: GC;
import core.exception;
import std.functional: memoize;

import assert_ex;
import traits_ex;
import getopt_ex;
import digest_ex;
import algorithm_ex;
import codec;
import csunits;
alias Bytes64 = Bytes!ulong;
import arsd.terminal;
import sregex;
import english;
import bitset;
import dbg;
import tempfs;
import rational: Rational;
import ngram;
import notnull;
import pprint;
import elf;

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
    import core.atomic: atomicOp;
    if (signo == 2)
    {
        core.atomic.atomicOp!"+="(ctrlC, 1);
    }
    // throw new SignalCaughtException(signo);
}

alias signalHandler_t = void function(int);
extern (C) signalHandler_t signal(int signal, signalHandler_t handler);

version(msgpack)
{
    import msgpack;
}
version(cerealed)
{
    /* import cerealed.cerealiser; */
    /* import cerealed.decerealiser; */
    /* import cerealed.cereal; */
}

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

    dirName,     // Name of directory being scanned
    dir = dirName,

    fileName,    // Name of file being scanned
    name = fileName,

    regularFileName,    // Name of file being scanned
    symlinkName, // Name of symbolic linke being scanned

    fileContent, // Contents of file being scanned
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
    none,

    checkSyntax,
    lint = checkSyntax,

    compile, // Compile
    byteCompile, // Byte compile
    run, // Run (Execute)

    /* VCS Operations */
    vcStatus,
}

/** Directory Operation Type Code. */
enum DirOp
{
    /* VCS Operations */
    vcStatus,
}

/** Shell Command.
 */
alias ShCmd = string; // Just simply a string for now.

/** Pair of Delimiters.
    Used to desribe for example comment and string delimiter syntax.
 */
struct Delim
{
    this(string intro)
    {
        this.intro = intro;
        this.finish = finish.init;
    }
    this(string intro, string finish)
    {
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
        static if (is(T == string))
        {
            this.baseNaming = lit(baseNaming_);
        }
        else static if (isArrayOf!(T, string))
        {
            // TODO: Move to a factory function strs(x)
            auto alt_ = alt();
            foreach (ext; baseNaming_)  // add each string as an alternative
            {
                alt_.alts ~= lit(ext);
            }
            this.baseNaming = alt_;
        }
        else static if (is(T == Patt))
        {
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
            detection_ == FileKindDetection.equalsWhatsGiven)
        {
            // relax matching of sourcecode to only need name until we have complete parsers
            this.detection = FileKindDetection.equalsName;
        }
        else
        {
            this.detection = detection_;
        }

        this.superKind = superKind;
        this.subKinds = subKinds;
        this.description = description;
        this.wikiURL = wikiURL;
    }

    override string toString() const @property @trusted pure nothrow { return kindName; }

    /** Returns: Id Unique to matching behaviour of $(D this) FKind. If match
        behaviour of $(D this) FKind changes returned id will change.
        value is memoized.
        TODO: Make pure when msgpack.pack is made pure.
    */
    auto ref const(SHA1Digest) behaviorId() @property @safe
        out(result) { assert(!result.empty); }
    body
    {
        if (_behaviourDigest.empty) // if not yet defined
        {
            ubyte[] bytes;
            if (const magicLit = cast(Lit)magicData)
            {
                bytes = msgpack.pack(exts, magicLit.bytes, magicOffset, refPattern, keywords, content, detection);
            }
            else
            {
                dln("warning: Handle magicData of type ", kindName);
            }
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
    string[] builtins; // Builtin Functions
    Op[] opers; // Language Opers

    /* TODO: Move this to CompLang class */
    Delim[] strings; // String syntax.
    Delim[] comments; // Comment syntax.

    bool machineGenerated;

    Tuple!(FileOp, ShCmd)[] operations; // Operation and Corresponding Shell Command
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
    return (kind.matchFullName(full) ||
            kind.matchExtension(ext));
}

import std.range: hasSlicing;

/** Match (Magic) Contents of $(D kind) with $(D range).
    Returns: true iff match. */
bool matchContents(Range)(in FKind kind,
                          in Range range,
                          in RegFile regfile) pure nothrow if (hasSlicing!Range)
{
    const hit = kind.magicData.matchU(range, kind.magicOffset);
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

    if (regfile._cstat.kindId.defined &&
        (regfile._cstat.kindId in allKindsById) && // if kind is known
        allKindsById[regfile._cstat.kindId] is kind)  // if cached kind equals
    {
        return KindHit.cached;
    }

    if (kind.superKind)
    {
        immutable baseHit = regfile.ofKind(ext,
                                           enforceNotNull(kind.superKind),
                                           collectTypeHits,
                                           allKindsById);
        if (!baseHit)
        {
            return baseHit;
        }
    }

    bool hit = false;
    final switch (kind.detection)
    {
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
    if (hit)
    {
        if (collectTypeHits)
        {
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
         string kn)
    {
        this.fileName = fn;
        this.kindName = kn;
    }

    version(msgpack)
    {
        this(Unpacker)(ref Unpacker unpacker)
        {
            fromMsgpack(msgpack.Unpacker(unpacker));
        }
        void toMsgpack(Packer)(ref Packer packer) const
        {
            packer.beginArray(this.tupleof.length);
            packer.pack(this.tupleof);
        }
        void fromMsgpack(Unpacker)(auto ref Unpacker unpacker)
        {
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
    this(Dir parent)
    {
        this.parent = parent;
        if (parent) { ++parent.gstats.noFiles; }
    }
    this(string name, Dir parent, Bytes64 size,
         SysTime timeLastModified,
         SysTime timeLastAccessed)
    {
        this.name = name;
        this.parent = parent;
        this.size = size;
        this.timeLastModified = timeLastModified;
        this.timeLastAccessed = timeLastAccessed;
        if (parent) { ++parent.gstats.noFiles; }
    }

    Bytes64 treeSize() @property @trusted /* @safe pure nothrow */ { return size; }

    /** Content Digest of Tree under this Directory. */
    const(SHA1Digest) treeContentId() @property @trusted /* @safe pure nothrow */
    {
        return typeof(return).init; // default to undefined
    }

    Face!Color face() const @property @safe pure nothrow { return fileFace; }

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
            )
        {
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

        auto curr = parent; // current parent
        size_t pathLength = 1 + name.length; // returned path length
        Dir[] parents; // collected parents
        while (curr !is null &&
               !curr.isRoot)
        {
            pathLength += 1;
            pathLength += curr.name.length;
            parents ~= curr;
            curr = curr.parent;
        }

        // build path
        auto path_ = new char[pathLength];
        size_t i = 0; // index to path_
        import std.range: retro;
        foreach (currParent_; parents.retro)
        {
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
        Recursive Heap-active implementation, slower than $(D path()).
    */
    string pathRecursive() @property @trusted pure
    {
        if (parent)
        {
            static if (true)
            {
                import std.path: dirSeparator;
                // NOTE: This is more efficient than buildPath(parent.path,
                // name) because we can guarantee things about parent.path and
                // name
                immutable parentPath = parent.isRoot ? "" : parent.pathRecursive;
                return parentPath ~ dirSeparator ~ name;
            }
            else
            {
                import std.path: buildPath;
                return buildPath(parent.pathRecursive, name);
            }
        }
        else
        {
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

    /** Get Parenting Dirs starting from file system root downto containing
     * directory of $(D this). */
    auto parents()
    {
        auto curr = dir; // current parent
        Dir[] parents; // collected parents
        while (curr !is null && !curr.isRoot)
        {
            parents ~= curr;
            curr = curr.parent;
        }
        import std.range: retro;
        return parents.retro;
    }
    alias dirs = parents;     // SCons style alias

    Dir parent;               // Reference to parenting directory (or null if this is a root directory)
    alias dir = parent;       // SCons style alias

    string name;              // Empty if root directory
    Bytes64 size;             // Size of file in bytes
    SysTime timeLastModified; // Last modification time
    SysTime timeLastAccessed; // Last access time
}

/** Maps Files to their tags. */
class FileTags
{
    FileTags addTag(File file, in string tag) @safe pure /* nothrow */
    {
        if (file in _tags)
        {
            if (_tags[file].find(tag).empty)
            {
                _tags[file] ~= tag; // add it
            }
        }
        else
        {
            _tags[file] = [tag];
        }
        return this;
    }
    FileTags removeTag(File file, string tag) @safe pure
    {
        if (file in _tags)
        {
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
    auto passwd = getFile(root, "/etc/passwd", dent.isDir);
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

/** Symlink Target Status.
 */
enum SymlinkTargetStatus
{
    unknown,
    present,
    broken,
}

/** Symlink.
 */
class Symlink : File
{
    this(NotNull!Dir parent)
    {
        super(parent);
        ++parent.gstats.noSymlinks;
    }
    this(ref DirEntry dent, NotNull!Dir parent)
    {
        Bytes64 sizeBytes;
        SysTime modified, accessed;
        bool ok = true;
        try
        {
            sizeBytes = dent.size.Bytes64;
            modified = dent.timeLastModified;
            accessed = dent.timeLastAccessed;
        }
        catch (Exception)
        {
            ok = false;
        }
        // const attrs = getLinkAttributes(dent.name); // attributes of target file
        // super(dent.name.baseName, parent, 0.Bytes64, cast(SysTime)0, cast(SysTime)0);
        super(dent.name.baseName, parent, sizeBytes, modified, accessed);
        if (ok)
        {
            this.retarget(dent); // trigger lazy load
        }
        ++parent.gstats.noSymlinks;
    }

    override Face!Color face() const @property @safe pure nothrow
    {
        if (_targetStatus == SymlinkTargetStatus.broken)
            return symlinkBrokenFace;
        else
            return symlinkFace;
    }

    string retarget(ref DirEntry dent) @trusted
    {
        import std.file: readLink;
        return _target = readLink(dent);
    }

    /** Cached/Memoized/Lazy Lookup for target. */
    string target() @property @trusted
    {
        if (!_target)         // if target not yet read
        {
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

    version(msgpack)
    {
        /** Construct from msgpack $(D unpacker).  */
        this(Unpacker)(ref Unpacker unpacker)
        {
            fromMsgpack(msgpack.Unpacker(unpacker));
        }
        void toMsgpack(Packer)(ref Packer packer) const
        {
            /* writeln("Entering File.toMsgpack ", name); */
            packer.pack(name, size, timeLastModified.stdTime, timeLastAccessed.stdTime);
        }
        void fromMsgpack(Unpacker)(auto ref Unpacker unpacker)
        {
            unpacker.unpack(name, size);
            long stdTime;
            unpacker.unpack(stdTime); timeLastModified = SysTime(stdTime); // TODO: Functionize
            unpacker.unpack(stdTime); timeLastAccessed = SysTime(stdTime); // TODO: Functionize
        }
    }

    string _target;
    SymlinkTargetStatus _targetStatus = SymlinkTargetStatus.unknown;
}

/** Special File (Character or Block Device).
 */
class SpecFile : File
{
    this(NotNull!Dir parent)
    {
        super(parent);
        ++parent.gstats.noSpecialFiles;
    }
    this(ref DirEntry dent, NotNull!Dir parent)
    {
        super(dent.name.baseName, parent, 0.Bytes64, cast(SysTime)0, cast(SysTime)0);
        ++parent.gstats.noSpecialFiles;
    }

    override Face!Color face() const @property @safe pure nothrow { return specialFileFace; }

    version(msgpack)
    {
        /** Construct from msgpack $(D unpacker).  */
        this(Unpacker)(ref Unpacker unpacker)
        {
            fromMsgpack(msgpack.Unpacker(unpacker));
        }
        void toMsgpack(Packer)(ref Packer packer) const
        {
            /* writeln("Entering File.toMsgpack ", name); */
            packer.pack(name, size, timeLastModified.stdTime, timeLastAccessed.stdTime);
        }
        void fromMsgpack(Unpacker)(auto ref Unpacker unpacker)
        {
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
    this(NotNull!Dir parent)
    {
        super(parent);
        ++parent.gstats.noRegFiles;
    }
    this(ref DirEntry dent, NotNull!Dir parent)
    {
        this(dent.name.baseName, parent, dent.size.Bytes64,
             dent.timeLastModified, dent.timeLastAccessed);
    }
    this(string name, NotNull!Dir parent, Bytes64 size, SysTime timeLastModified, SysTime timeLastAccessed)
    {
        super(name, parent, size, timeLastModified, timeLastAccessed);
        ++parent.gstats.noRegFiles;
    }

    ~this() { _cstat.deallocate(false); }

    /** Returns: Content Id of $(D this). */
    override const(SHA1Digest) treeContentId() @property @trusted /* @safe pure nothrow */
    {
        calculateCStatInChunks(parent.gstats.filesByContentId);
        return _cstat._contId;
    }

    override Face!Color face() const @property @safe pure nothrow { return regFileFace; }

    /** Returns: SHA-1 of $(D this) $(D File) Contents at $(D src). */
    const(SHA1Digest) contId(inout (ubyte[]) src,
                             File[][SHA1Digest] filesByContentId)
        @property pure out(result) { assert(!result.empty); } // must have be defined
    body
    {
        if (_cstat._contId.empty) // if not yet defined
        {
            _cstat._contId = src.sha1Of;
            filesByContentId[_cstat._contId] ~= this;
            debug dln("Got SHA1 of " ~ path);
        }
        return _cstat._contId;
    }

    /** Returns: Cached/Memoized Binary Histogram of $(D this) $(D File). */
    auto ref bistogram8() @property @safe // ref needed here!
    {
        if (_cstat.bist.empty)
        {
            _cstat.bist.put(readOnlyContents); // memoized calculated
        }
        return _cstat.bist;
    }

    /** Returns: Cached/Memoized XGram of $(D this) $(D File). */
    auto ref xgram() @property @safe // ref needed here!
    {
        if (_cstat.xgram.empty)
        {
            _cstat.xgram.put(readOnlyContents); // memoized calculated
        }
        return _cstat.xgram;
    }

    /** Returns: Cached/Memoized XGram Deep Denseness of $(D this) $(D File). */
    auto ref xgramDeepDenseness() @property @safe
    {
        if (!_cstat._xgramDeepDenseness)
        {
            _cstat._xgramDeepDenseness = xgram.denseness(-1).numerator;
        }
        return Rational!ulong(_cstat._xgramDeepDenseness,
                              _cstat.xgram.noBins);
    }

    /** Process File in Cache Friendly Chunks. */
    void calculateCStatInChunks(NotNull!File[][SHA1Digest] filesByContentId,
                                size_t chunkSize = 32*pageSize(),
                                bool doSHA1 = false,
                                bool doBist = false,
                                bool doBitStatus = false) @safe
    {
        if (_cstat._contId.defined) { doSHA1 = false; }
        if (!_cstat.bist.empty) { doBist = false; }
        if (_cstat.bitStatus != BitStatus.unknown) { doBitStatus = false; }

        import std.digest.sha;
        SHA1 sha1;
        if (doSHA1) { sha1.start(); }

        bool isASCII = true;

        if (doSHA1 || doBist || doBitStatus)
        {
            import std.range: chunks;
            foreach (chunk; readOnlyContents.chunks(chunkSize))
            {
                if (doSHA1) { sha1.put(chunk); }
                if (doBist) { _cstat.bist.put(chunk); }
                if (doBitStatus)
                {
                    /* TODO: This can be parallelized using 64-bit wording!
                     * Write automatic parallelizing library for this? */
                    foreach (elt; chunk)
                    {
                        import bitop_ex: bt;
                        isASCII = isASCII && !elt.bt(7); // ASCII has no topmost bit set
                    }
                }
            }
        }

        if (doBitStatus)
        {
            _cstat.bitStatus = isASCII ? BitStatus.bits7 : BitStatus.bits8;
        }

        if (doSHA1)
        {
            _cstat._contId = sha1.finish();
            filesByContentId[_cstat._contId] ~= cast(NotNull!File)assumeNotNull(this);
        }
    }

    /** Clear/Reset Contents Statistics of $(D this) $(D File). */
    void clearCStat(File[][SHA1Digest] filesByContentId) @safe nothrow
    {
        // SHA1-digest
        if (_cstat._contId in filesByContentId)
        {
            auto dups = filesByContentId[_cstat._contId];
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
        this(Unpacker)(ref Unpacker unpacker)
        {
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
            if (xgramFlag)
            {
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
            if (!(_cstat.kindId in parent.gstats.allKindsById))
            {
                // kind database has changed since kindId was written to disk
                _cstat.kindId.reset; // forget it
            }
            unpacker.unpack(_cstat._contId); // Digest
            if (_cstat._contId)
            {
                parent.gstats.filesByContentId[_cstat._contId] ~= cast(NotNull!File)this;
            }

            // Bist
            bool bistFlag; unpacker.unpack(bistFlag);
            if (bistFlag)
            {
                unpacker.unpack(_cstat.bist);
            }

            // XGram
            bool xgramFlag; unpacker.unpack(xgramFlag);
            if (xgramFlag)
            {
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
    // } catch (InvalidMemoryOperationError) { viz.ppln(outFile, useHTML, "Failed to mmap ", dent.name); }
    // scope immutable src = cast(immutable ubyte[]) read(dent.name, upTo);
    immutable(ubyte[]) readOnlyContents(string file = __FILE__, int line = __LINE__)() @trusted
    {
        if (!_mmfile)
        {
            _mmfile = new MmFile(this.path, MmFile.Mode.read,
                                 mmfile_size, null, pageSize());
            if (parent.gstats.showMMaps)
            {
                writeln("Mapped ", path, " of size ", size);
            }
        }
        return cast(typeof(return))_mmfile[];
    }

    /** Returns: Read-Writable Contents of $(D this) Regular File. */
    // } catch (InvalidMemoryOperationError) { viz.ppln(outFile, useHTML, "Failed to mmap ", dent.name); }
    // scope immutable src = cast(immutable ubyte[]) read(dent.name, upTo);
    ubyte[] readWriteableContents() @trusted
    {
        if (!_mmfile)
        {
            _mmfile = new MmFile(this.path, MmFile.Mode.readWrite,
                                 mmfile_size, null, pageSize());
        }
        return cast(typeof(return))_mmfile[];
    }

    /** If needed Free Allocated Contents of $(D this) Regular File. */
    bool freeContents()
    {
        if (_mmfile) { delete _mmfile; _mmfile = null; return true; }
        else { return false; }
    }

    import std.mmfile;
    private MmFile _mmfile;
    private CStat _cstat;     // Statistics about the contents of this RegFile.
}

/** Traits */
enum isFile(T) = (is(T == File) || is(T == NotNull!File));
enum isDir(T) = (is(T == Dir) || is(T == NotNull!Dir));
enum isSymlink(T) = (is(T == Symlink) || is(T == NotNull!Symlink));
enum isRegFile(T) = (is(T == RegFile) || is(T == NotNull!RegFile));
enum isSpecialFile(T) = (is(T == SpecFile) || is(T == NotNull!SpecFile));
enum isAnyFile(T) = (isFile!T ||
                     isDir!T ||
                     isSymlink!T ||
                     isRegFile!T ||
                     isSpecialFile!T);

/** Return true if T is a class representing File IO. */
enum isFileIO(T) = (isAnyFile!T ||
                    is(T == ioFile));

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
    SHA1Digest _contId; // Content Identifier/Fingerprint.

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
    NotNull!File[][SHA1Digest] filesByContentId; // File(s) (Duplicates) Indexed on Contents SHA1.
    FileTags ftags;
    Bytes64[File] treeSizesByFile;

    FKind[SHA1Digest] incKindsById;    // Index Kinds by their behaviour
    FKind[SHA1Digest] allKindsById;    // Index Kinds by their behaviour

    bool showNameDups = false;
    bool showTreeContentDups = false;
    bool showFileContentDups = false;
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

version(cerealed)
{
    void grain(T)(ref Cereal cereal, ref SysTime systime)
    {
        auto stdTime = systime.stdTime;
        cereal.grain(stdTime);
        if (stdTime != 0)
        {
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
        if (_treeSize.untouched)
        {
            _treeSize = this.size + reduce!"a+b"(0.Bytes64,
                                                 _subs.byValue.map!"a.treeSize"); // recurse!
        }
        return _treeSize;
    }

    /** Returns: Directory Tree Content Id of $(D this). */
    override const(SHA1Digest) treeContentId() @property @trusted /* @safe pure nothrow */
    {
        if (_treeContentId.untouched)
        {
            _treeContentId = subs.byValue.map!"a.treeContentId".sha1Of;
            assert(_treeContentId, "Zero digest");
            if (this.path.startsWith("/home/per/tmp/.git/objects/cc"))
            {
                dln(path, ", ", subs.length, ", ", _treeContentId);
            }
            gstats.filesByContentId[_treeContentId] ~= assumeNotNull(cast(File)this); // TODO: Avoid cast when DMD and NotNull is fixed
        }
        return _treeContentId;
    }

    override Face!Color face() const @property @safe pure nothrow { return dirFace; }

    /** Return true if $(D this) is a file system root directory. */
    bool isRoot() @property @safe const pure nothrow { return !parent; }

    GStats gstats(GStats gstats) @property @safe pure /* nothrow */ {
        return this._gstats = gstats;
    }
    GStats gstats() @property @safe pure nothrow
    {
        if (!_gstats && this.parent)
        {
            _gstats = this.parent.gstats();
        }
        return _gstats;
    }

    /** Returns: Depth of Depth from File System root to this File. */
    override int depth() @property @safe pure nothrow
    {
        if (_depth ==- 1)
        {
            _depth = parent ? parent.depth + 1 : 0; // memoized depth
        }
        return _depth;
    }

    /** Scan $(D this) recursively for a non-diretory file with basename $(D name).
        TODO: Reuse range based algorithm this.tree(depthFirst|breadFirst)
     */
    File find(string name) @property
    {
        auto subs_ = subs();
        if (name in subs_)
        {
            auto hit = subs_[name];
            Dir hitDir = cast(Dir)hit;
            if (!hitDir) // if not a directory
                return hit;
        }
        else
        {
            foreach (sub; subs_)
            {
                Dir subDir = cast(Dir)sub;
                if (subDir)
                {
                    auto hit = subDir.find(name);
                    if (hit) // if not a directory
                        return hit;
                }
            }
        }
        return null;
    }

    /** Append Tree Statistics. */
    void addTreeStatsFromSub(F)(NotNull!F subFile, ref DirEntry subDent)
    {
        if (subDent.isFile)
        {
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
        if (localGStats)
        {
            if (localGStats.showNameDups)
            {
                localGStats.filesByName[subFile.name] ~= cast(NotNull!File)subFile;
            }
            if (localGStats.showLinkDups &&
                isRegFile)
            {
                import core.sys.posix.sys.stat;
                immutable stat_t stat = subDent.statBuf();
                if (stat.st_nlink >= 2)
                {
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
            !force)          // and not forced reload
        {
            return false;    // signal already scanned
        }

        // dln("Zeroing ", _treeSize, " of ", path);
        _treeSize.reset; // this.size;
        auto oldSubs = _subs;
        _subs.reset;
        assert(_subs.length == 0); // TODO: Remove when verified

        import std.file: dirEntries, SpanMode;
        auto entries = dirEntries(path, SpanMode.shallow, false); // false: skip symlinks
        foreach (dent; entries)
        {
            immutable basename = dent.name.baseName;
            File sub = null;
            if (basename in oldSubs)
            {
                sub = oldSubs[basename]; // reuse from previous cache
            }
            else
            {
                bool isRegFile = false;
                if (dent.isSymlink)
                {
                    sub = new Symlink(dent, assumeNotNull(this));
                }
                else if (dent.isDir)
                {
                    sub = new Dir(dent, this, gstats);
                }
                else if (dent.isFile)
                {
                    // TODO: Delay construction of and specific files such as
                    // CFile, ELFFile, after FKind-recognition has been made.
                    sub = new RegFile(dent, assumeNotNull(this));
                    isRegFile = true;
                }
                else
                {
                    sub = new SpecFile(dent, assumeNotNull(this));
                }
                updateStats(enforceNotNull(sub), dent, isRegFile);
            }
            auto nnsub = enforceNotNull(sub);
            addTreeStatsFromSub(nnsub, dent);
            _subs[basename] = nnsub;
        }
        _subs.rehash;           // optimize hash for faster lookups

        _obseleteDir = false;
        return true;
    }

    bool reload(int depth = 0) { return load(depth, true); }
    alias sync = reload;

    /* TODO: Can we get make this const to the outside world perhaps using inout? */
    ref NotNull!File[string] subs() @property { load(); return _subs; }

    NotNull!File[] subsSorted(DirSorting sorted = DirSorting.onTimeLastModified) @property
    {
        load();
        auto ssubs = _subs.values;
        /* TODO: Use radix sort to speed things up. */
        final switch (sorted)
        {
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

    File sub(Name)(Name sub_name)
    {
        load();
        return (sub_name in _subs) ? _subs[sub_name] : null;
    }
    File sub(File sub)
    {
        load();
        return (sub.path in _subs) != null ? sub : null;
    }

    version(cerealed)
    {
        void accept(Cereal cereal)
        {
            auto stdTime = timeLastModified.stdTime;
            cereal.grain(name, size, stdTime);
            timeLastModified = SysTime(stdTime);
        }
    }
    version(msgpack)
    {
        /** Construct from msgpack $(D unpacker).  */
        this(Unpacker)(ref Unpacker unpacker)
        {
            fromMsgpack(msgpack.Unpacker(unpacker));
        }

        void toMsgpack(Packer)(ref Packer packer) const
        {
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

            if (_subs.length >= 1)
            {
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

            foreach (sub; _subs)
            {
                if        (const regfile = cast(RegFile)sub)
                {
                    packer.pack("RegFile");
                    regfile.toMsgpack(packer);
                }
                else if (const dir = cast(Dir)sub)
                {
                    packer.pack("Dir");
                    dir.toMsgpack(packer);
                }
                else if (const symlink = cast(Symlink)sub)
                {
                    packer.pack("Symlink");
                    symlink.toMsgpack(packer);
                }
                else if (const special = cast(SpecFile)sub)
                {
                    packer.pack("SpecFile");
                    special.toMsgpack(packer);
                }
                else
                {
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

            ForwardDifferenceCode!(long[]) diffsLastModified,
                diffsLastAccessed;
            if (subs_length >= 1)
            {
                unpacker.unpack(diffsLastModified, diffsLastAccessed);
                /* auto x = diffsLastModified.decodeForwardDifference; */
            }

            foreach (ix; 0..subs_length) // repeat for subs_length times
            {
                string subClassName; unpacker.unpack(subClassName); // TODO: Functionize
                File sub = null;
                try
                {
                    switch (subClassName)
                    {
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
                    case "SpecFile":
                        auto SpecFile = assumeNotNull(new SpecFile(assumeNotNull(this)));
                        unpacker.unpack(SpecFile); sub = SpecFile;
                        break;
                    }
                    if (noPreviousSubs ||
                        !(sub.name in _subs))
                    {
                        _subs[sub.name] = enforceNotNull(sub);
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

    private NotNull!File[string] _subs; // Directory contents
    DirKind kind;               // Kind of this directory
    uint64_t hitCount = 0;
    private int _depth = -1;            // Memoized Depth
    private bool _obseleteDir = true;  // Flags that this is obselete
    GStats _gstats = null;

    /* TODO: Reuse Span and span in Phobos. (Span!T).init should be (T.max, T.min) */
    Interval!SysTime _timeModifiedInterval;
    Interval!SysTime _timeAccessedInterval;
    Bytes64 _treeSize; // Size of tree with this directory as root. Zero means undefined.
    SHA1Digest _treeContentId;
}

/** Externally Directory Memoized Calculation of Tree Size.
    Is it possible to make get any of @safe pure nothrow?
 */
Bytes64 treeSizeMemoized(NotNull!File file, Bytes64[File] cache) @trusted /* nothrow */
{
    typeof(return) sum = file.size;
    if (auto dir = cast(Dir)file)
    {
        if (file in cache)
        {
            sum = cache[file];
        }
        else
        {
            foreach (sub; dir.subs.byValue)
            {
                sum += treeSizeMemoized(sub, cache);
            }
            cache[file] = sum;
        }
    }
    return sum;
}

/** Save File System Tree Cache under Directory $(D rootDir).
    Returns: Serialized Byte Array.
*/
const(ubyte[]) saveRootDirTree(Viz viz,
                               Dir rootDir, string cacheFile) @trusted
{
    immutable tic = Clock.currTime;
    version(msgpack)
    {
        const data = rootDir.pack();
        import std.file: write;
    }
    else version(cerealed)
         {
             auto enc = new Cerealiser(); // encoder
             enc ~= rootDir;
             auto data = enc.bytes;
         }
    else
    {
        ubyte[] data;
    }
    cacheFile.write(data);
    immutable toc = Clock.currTime;

    viz.ppln("Cache Write".asH!2,
             "Wrote tree cache of size ",
             data.length.Bytes64, " to ",
             asPath(cacheFile),
             " in ",
             shortDurationString(toc - tic));

    return data;
}

/** Load File System Tree Cache from $(D cacheFile).
    Returns: Root Directory of Loaded Tree.
*/
Dir loadRootDirTree(Viz viz,
                    string cacheFile, GStats gstats) @trusted
{
    immutable tic = Clock.currTime;

    import std.file: read;
    try
    {
        const data = read(cacheFile);

        auto rootDir = new Dir(cast(Dir)null, gstats);
        version(msgpack)
        {
            unpack(cast(ubyte[])data, rootDir); /* Dir rootDir = new Dir(cast(const(ubyte)[])data); */
        }
        immutable toc = Clock.currTime;

        viz.pp("Cache Read".asH!2,
               "Read cache of size ",
               data.length.Bytes64, " from ",
               asPath(cacheFile),
               " in ",
               shortDurationString(toc - tic), " containing",
               asUList(asItem(gstats.noDirs, " Dirs,"),
                       asItem(gstats.noRegFiles, " Regular Files,"),
                       asItem(gstats.noSymlinks, " Symbolic Links,"),
                       asItem(gstats.noSpecialFiles, " Special Files,"),
                       asItem("totalling ", gstats.noFiles + 1, " Files")));
        assert(gstats.noDirs +
               gstats.noRegFiles +
               gstats.noSymlinks +
               gstats.noSpecialFiles == gstats.noFiles + 1);
        return rootDir;
    }
    catch (FileException)
    {
        viz.ppln("Failed to read cache from ", cacheFile);
        return null;
    }
}

Dir[] getDirs(NotNull!Dir rootDir, string[] topDirNames)
{
    Dir[] topDirs;
    foreach (topName; topDirNames)
    {
        Dir topDir = getDir(rootDir, topName);

        if (!topDir)
        {
            dln("Directory " ~ topName ~ " is missing");
        }
        else
        {
            topDirs ~= topDir;
        }
    }
    return topDirs;
}

/** (Cached) Lookup of File $(D filePath).
 */
File getFile(NotNull!Dir rootDir, string filePath,
             bool isDir = false,
             bool tolerant = false) @trusted
{
    if (isDir)
    {
        return getDir(rootDir, filePath);
    }
    else
    {
        auto parentDir = getDir(rootDir, filePath.dirName);
        if (parentDir)
        {
            auto hit = parentDir.sub(filePath.baseName);
            if (hit)
                return hit;
            else
            {
                dln("File path " ~ filePath ~ " doesn't exist. TODO: Query user to instead find it under "
                    ~ parentDir.path);
                parentDir.find(filePath.baseName);
            }
        }
        else
        {
            dln("Directory " ~ parentDir.path ~ " doesn't exist");
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
    foreach (part; dirPath.pathSplitter().drop(1)) // all but first
    {
        auto sub = currDir.sub(part);
        if        (auto subDir = cast(Dir)sub)
        {
            currDir = subDir;
        }
        else if (auto subSymlink = cast(Symlink)sub)
        {
            auto subDent = DirEntry(subSymlink.absoluteNormalizedTargetPath);
            if (subDent.isDir)
            {
                if (followedSymlinks.find(subSymlink))
                {
                    dln("Infinite recursion in ", subSymlink);
                    return null;
                }
                followedSymlinks ~= subSymlink;
                currDir = getDir(rootDir, subSymlink.absoluteNormalizedTargetPath, subDent, followedSymlinks); // TODO: Check for infinite recursion
            }
            else
            {
                dln("Loaded path " ~ dirPath ~ " is not a directory");
                return null;
            }
        }
        else
        {
            return null;
        }
    }
    return currDir;
}

/** (Cached) Lookup of Directory $(D dirPath). */
Dir getDir(NotNull!Dir rootDir, string dirPath) @trusted
{
    Symlink[] followedSymlinks;
    try
    {
        auto dirDent = DirEntry(dirPath);
        return getDir(rootDir, dirPath, dirDent, followedSymlinks);
    }
    catch (FileException)
    {
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
    version(linux)
    {
        import core.sys.posix.sys.shm: __getpagesize;
        return __getpagesize();
    }
    else
    {
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

/** Language Operator Associativity. */
enum OpAssoc { none,
               LR, // Left-to-Right
               RL, // Right-to-Left
}

/** Language Operator Arity. */
enum OpArity
{
    unknown,
    unaryPostfix, // 1-arguments
    unaryPrefix, // 1-arguments
    binary, // 2-arguments
    ternary, // 3-arguments
}

/** Language Operator. */
struct Op
{
    this(string op,
         OpArity arity = OpArity.unknown,
         OpAssoc assoc = OpAssoc.none,
         byte prec = -1,
         string desc = [])
    {
        this.op = op;
        this.arity = arity;
        this.assoc = assoc;
        this.prec = prec;
        this.desc = desc;
    }
    /** Make $(D this) an alias of $(D opOrig). */
    Op aliasOf(string opOrig)
    {
        // TODO: set relation in map from op to opOrig
        return this;
    }
    string op; // Operator. TODO: Optimize this storage using a value type?
    string desc; // Description
    OpAssoc assoc; // Associativity
    ubyte prec; // Precedence
    OpArity arity; // Arity
    bool overloadable; // Overloadable
}

/** Language Operator Alias. */
struct OpAlias
{
    this(string op, string opOrigin)
    {
        this.op = op;
        this.opOrigin = opOrigin;
    }
    string op;
    string opOrigin;
}

/** File System Scanner. */
class Scanner(Term)
{
    this(string[] args, ref Term term)
    {
        _scanChunkSize = 32*pageSize();
        loadDirKinds();
        loadFileKinds();
        prepare(args, term);
    }

    SysTime _currTime;
    import std.getopt;
    import std.string: toLower, toUpper, startsWith, CaseSensitive;
    import std.mmfile;
    import std.stdio: writeln, stdout, stderr, stdin, popen;
    import std.algorithm: find, count, countUntil, min, splitter;
    import std.range: join;
    import std.conv: to;

    import core.sys.posix.sys.mman;
    import core.sys.posix.pwd: passwd, getpwuid_r;
    version(linux)
    {
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
    void loadDirKinds()
    {
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
        foreach (k; skippedDirKinds)
        {
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

    void loadFileKinds()
    {
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

        auto keywordsC = [
            "auto", "const", "double", "float", "int", "short", "struct",
            "unsigned", "break", "continue", "else", "for", "long", "signed",
            "switch", "void", "case", "default", "enum", "goto", "register",
            "sizeof", "typedef", "volatile", "char", "do", "extern", "if",
            "return", "static", "union", "while",
            ];

        /* See also: https://en.wikipedia.org/wiki/Operators_in_C_and_C%2B%2B */
        auto opersCBasic = [
            // Arithmetic
            Op("+", OpArity.binary, OpAssoc.LR, 6, "Add"),
            Op("-", OpArity.binary, OpAssoc.LR, 6, "Subtract"),
            Op("*", OpArity.binary, OpAssoc.LR, 5, "Multiply"),
            Op("/", OpArity.binary, OpAssoc.LR, 5, "Divide"),
            Op("%", OpArity.binary, OpAssoc.LR, 5, "Remainder/Moduls"),

            Op("+", OpArity.unaryPrefix, OpAssoc.RL, 3, "Unary plus"),
            Op("-", OpArity.unaryPrefix, OpAssoc.RL, 3, "Unary minus"),

            Op("++", OpArity.unaryPostfix, OpAssoc.LR, 2, "Suffix increment"),
            Op("--", OpArity.unaryPostfix, OpAssoc.LR, 2, "Suffix decrement"),

            Op("++", OpArity.unaryPrefix, OpAssoc.RL, 3, "Prefix increment"),
            Op("--", OpArity.unaryPrefix, OpAssoc.RL, 3, "Prefix decrement"),

            // Assignment Arithmetic (binary)
            Op("=", OpArity.binary, OpAssoc.RL, 16, "Assign"),
            Op("+=", OpArity.binary, OpAssoc.RL, 16, "Assignment by sum"),
            Op("-=", OpArity.binary, OpAssoc.RL, 16, "Assignment by difference"),
            Op("*=", OpArity.binary, OpAssoc.RL, 16, "Assignment by product"),
            Op("/=", OpArity.binary, OpAssoc.RL, 16, "Assignment by quotient"),
            Op("%=", OpArity.binary, OpAssoc.RL, 16, "Assignment by remainder"),

            Op("&=", OpArity.binary, OpAssoc.RL, 16, "Assignment by bitwise AND"),
            Op("|=", OpArity.binary, OpAssoc.RL, 16, "Assignment by bitwise OR"),

            Op("^=", OpArity.binary, OpAssoc.RL, 16, "Assignment by bitwise XOR"),
            Op("<<=", OpArity.binary, OpAssoc.RL, 16, "Assignment by bitwise left shift"),
            Op(">>=", OpArity.binary, OpAssoc.RL, 16, "Assignment by bitwise right shift"),

            Op("==", OpArity.binary, OpAssoc.LR, 9, "Equal to"),
            Op("!=", OpArity.binary, OpAssoc.LR, 9, "Not equal to"),

            Op("<", OpArity.binary, OpAssoc.LR, 8, "Less than"),
            Op(">", OpArity.binary, OpAssoc.LR, 8, "Greater than"),
            Op("<=", OpArity.binary, OpAssoc.LR, 8, "Less than or equal to"),
            Op(">=", OpArity.binary, OpAssoc.LR, 8, "Greater than or equal to"),

            Op("&&", OpArity.binary, OpAssoc.LR, 13, "Logical AND"), // TODO: Convert to math in smallcaps AND
            Op("||", OpArity.binary, OpAssoc.LR, 14, "Logical OR"), // TODO: Convert to math in smallcaps OR

            Op("!", OpArity.unaryPrefix, OpAssoc.LR, 3, "Logical NOT"), // TODO: Convert to math in smallcaps NOT

            Op("&", OpArity.binary, OpAssoc.LR, 10, "Bitwise AND"),
            Op("^", OpArity.binary, OpAssoc.LR, 11, "Bitwise XOR (exclusive or)"),
            Op("|", OpArity.binary, OpAssoc.LR, 12, "Bitwise OR"),

            Op("<<", OpArity.binary, OpAssoc.LR, 7, "Bitwise left shift"),
            Op(">>", OpArity.binary, OpAssoc.LR, 7, "Bitwise right shift"),

            Op("~", OpArity.unaryPrefix, OpAssoc.LR, 3, "Bitwise NOT (One's Complement)"),
            Op(",", OpArity.binary, OpAssoc.LR, 18, "Comma"),
            Op("sizeof", OpArity.unaryPrefix, OpAssoc.LR, 3, "Size-of"),

            Op("->", OpArity.binary, OpAssoc.LR, 2, "Element selection through pointer"),
            Op(".", OpArity.binary, OpAssoc.LR, 2, "Element selection by reference"),

            ];

        /* See also: https://en.wikipedia.org/wiki/Iso646.h */
        auto opersC_ISO646 = [
            OpAlias("and", "&&"),
            OpAlias("or", "||"),
            OpAlias("and_eq", "&="),

            OpAlias("bitand", "&"),
            OpAlias("bitor", "|"),

            OpAlias("compl", "~"),
            OpAlias("not", "!"),
            OpAlias("not_eq", "!="),
            OpAlias("or_eq", "|="),
            OpAlias("xor", "^"),
            OpAlias("xor_eq", "^="),
            ];

        auto opersC = opersCBasic /* ~ opersC_ISO646 */;

        auto kindC = new FKind("C", [], ["c", "h"], [], 0, [],
                               keywordsC,
                               cCommentDelims,
                               defaultStringDelims,
                               FileContent.sourceCode, FileKindDetection.equalsWhatsGiven);
        srcFKinds ~= kindC;
        kindC.operations ~= tuple(FileOp.checkSyntax, "gcc -x c -fsyntax-only -c");
        kindC.operations ~= tuple(FileOp.checkSyntax, "clang -x c -fsyntax-only -c");
        kindC.opers = opersC;

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

        auto opersCxx = opersC ~ [
            Op("->*", OpArity.binary, OpAssoc.LR, 4, "Pointer to member"),
            Op(".*", OpArity.binary, OpAssoc.LR, 4, "Pointer to member"),
            Op("::", OpArity.binary, OpAssoc.none, 1, "Scope resolution"),
            Op("typeid", OpArity.unaryPrefix, OpAssoc.LR, 2, "Run-time type information (RTTI))"),
            //Op("alignof", OpArity.unaryPrefix, OpAssoc.LR, _, _),
            Op("new", OpArity.unaryPrefix, OpAssoc.RL, 3, "Dynamic memory allocation"),
            Op("delete", OpArity.unaryPrefix, OpAssoc.RL, 3, "Dynamic memory deallocation"),
            Op("delete[]", OpArity.unaryPrefix, OpAssoc.RL, 3, "Dynamic memory deallocation"),
            /* Op("noexcept", OpArity.unaryPrefix, OpAssoc.none, _, _), */

            Op("dynamic_cast", OpArity.unaryPrefix, OpAssoc.LR, 2, "Type cast"),
            Op("reinterpret_cast", OpArity.unaryPrefix, OpAssoc.LR, 2, "Type cast"),
            Op("static_cast", OpArity.unaryPrefix, OpAssoc.LR, 2, "Type cast"),
            Op("const_cast", OpArity.unaryPrefix, OpAssoc.LR, 2, "Type cast"),

            Op("throw", OpArity.unaryPrefix, OpAssoc.LR, 17, "Throw operator"),
            /* Op("catch", OpArity.unaryPrefix, OpAssoc.LR, _, _) */
            ];

        keywordsCxx = keywordsCxx.uniq.array;
        auto kindCxx = new FKind("C++", [], ["cpp", "hpp", "cxx", "hxx", "c++", "h++", "C", "H"], [], 0, [],
                                 keywordsCxx,
                                 cCommentDelims,
                                 defaultStringDelims,
                                 FileContent.sourceCode, FileKindDetection.equalsWhatsGiven);
        kindCxx.operations ~= tuple(FileOp.checkSyntax, "gcc -x c++ -fsyntax-only -c");
        kindCxx.operations ~= tuple(FileOp.checkSyntax, "clang -x c++ -fsyntax-only -c");
        kindCxx.opers = opersCxx;
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

        auto keywordsSwift = ["break", "class", "continue", "default", "do", "else", "for", "func", "if", "import",
                              "in", "let", "return", "self", "struct", "super", "switch", "unowned", "var", "weak", "while",
                              "mutating", "extension"];
        auto opersOverflowSwift = opersC ~ [Op("&+"), Op("&-"), Op("&*"), Op("&/"), Op("&%")];
        auto builtinsSwift = ["print", "println"];
        auto kindSwift = new FKind("Swift", [], ["swift"], [], 0, [],
                                   keywordsSwift,
                                   cCommentDelims,
                                   defaultStringDelims,
                                   FileContent.sourceCode, FileKindDetection.equalsWhatsGiven);
        kindSwift.builtins = builtinsSwift;
        kindSwift.opers = opersOverflowSwift;
        srcFKinds ~= kindSwift;

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

        auto opersD = [
            // Arithmetic
            Op("+", OpArity.binary, OpAssoc.LR, 10*2, "Add"),
            Op("-", OpArity.binary, OpAssoc.LR, 10*2, "Subtract"),
            Op("~", OpArity.binary, OpAssoc.LR, 10*2, "Concatenate"),

            Op("*", OpArity.binary, OpAssoc.LR, 11*2, "Multiply"),
            Op("/", OpArity.binary, OpAssoc.LR, 11*2, "Divide"),
            Op("%", OpArity.binary, OpAssoc.LR, 11*2, "Remainder/Moduls"),

            Op("++", OpArity.unaryPostfix, OpAssoc.LR, cast(int)(14.5*2), "Suffix increment"),
            Op("--", OpArity.unaryPostfix, OpAssoc.LR, cast(int)(14.5*2), "Suffix decrement"),

            Op("^^", OpArity.binary, OpAssoc.RL, 13*2, "Power"),

            Op("++", OpArity.unaryPrefix, OpAssoc.RL, 12*2, "Prefix increment"),
            Op("--", OpArity.unaryPrefix, OpAssoc.RL, 12*2, "Prefix decrement"),
            Op("&", OpArity.unaryPrefix, OpAssoc.RL, 12*2, "Address off"),
            Op("*", OpArity.unaryPrefix, OpAssoc.RL, 12*2, "Pointer Dereference"),
            Op("+", OpArity.unaryPrefix, OpAssoc.RL, 12*2, "Unary Plus"),
            Op("-", OpArity.unaryPrefix, OpAssoc.RL, 12*2, "Unary Minus"),
            Op("!", OpArity.unaryPrefix, OpAssoc.RL, 12*2, "Logical NOT"), // TODO: Convert to math in smallcaps NOT
            Op("~", OpArity.unaryPrefix, OpAssoc.LR, 12*2, "Bitwise NOT (One's Complement)"),

            // Bit shift
            Op("<<", OpArity.binary, OpAssoc.LR, 9*2, "Bitwise left shift"),
            Op(">>", OpArity.binary, OpAssoc.LR, 9*2, "Bitwise right shift"),

            // Comparison
            Op("==", OpArity.binary, OpAssoc.LR, 6*2, "Equal to"),
            Op("!=", OpArity.binary, OpAssoc.LR, 6*2, "Not equal to"),
            Op("<", OpArity.binary, OpAssoc.LR, 6*2, "Less than"),
            Op(">", OpArity.binary, OpAssoc.LR, 6*2, "Greater than"),
            Op("<=", OpArity.binary, OpAssoc.LR, 6*2, "Less than or equal to"),
            Op(">=", OpArity.binary, OpAssoc.LR, 6*2, "Greater than or equal to"),
            Op("in", OpArity.binary, OpAssoc.LR, 6*2, "In"),
            Op("!in", OpArity.binary, OpAssoc.LR, 6*2, "Not In"),
            Op("is", OpArity.binary, OpAssoc.LR, 6*2, "Is"),
            Op("!is", OpArity.binary, OpAssoc.LR, 6*2, "Not Is"),

            Op("&", OpArity.binary, OpAssoc.LR, 8*2, "Bitwise AND"),
            Op("^", OpArity.binary, OpAssoc.LR, 7*2, "Bitwise XOR (exclusive or)"),
            Op("|", OpArity.binary, OpAssoc.LR, 6*2, "Bitwise OR"),

            Op("&&", OpArity.binary, OpAssoc.LR, 5*2, "Logical AND"), // TODO: Convert to math in smallcaps AND
            Op("||", OpArity.binary, OpAssoc.LR, 4*2, "Logical OR"), // TODO: Convert to math in smallcaps OR

            // Assignment Arithmetic (binary)
            Op("=", OpArity.binary, OpAssoc.RL, 2*2, "Assign"),
            Op("+=", OpArity.binary, OpAssoc.RL, 2*2, "Assignment by sum"),
            Op("-=", OpArity.binary, OpAssoc.RL, 2*2, "Assignment by difference"),
            Op("*=", OpArity.binary, OpAssoc.RL, 2*2, "Assignment by product"),
            Op("/=", OpArity.binary, OpAssoc.RL, 2*2, "Assignment by quotient"),
            Op("%=", OpArity.binary, OpAssoc.RL, 2*2, "Assignment by remainder"),
            Op("&=", OpArity.binary, OpAssoc.RL, 2*2, "Assignment by bitwise AND"),
            Op("|=", OpArity.binary, OpAssoc.RL, 2*2, "Assignment by bitwise OR"),
            Op("^=", OpArity.binary, OpAssoc.RL, 2*2, "Assignment by bitwise XOR"),
            Op("<<=", OpArity.binary, OpAssoc.RL, 2*2, "Assignment by bitwise left shift"),
            Op(">>=", OpArity.binary, OpAssoc.RL, 2*2, "Assignment by bitwise right shift"),

            Op(",", OpArity.binary, OpAssoc.LR, 1*2, "Comma"),
            Op("..", OpArity.binary, OpAssoc.LR, cast(int)(0*2), "Range separator"),
            ];

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
        kindD.operations ~= tuple(FileOp.checkSyntax, "gdc -fsyntax-only");
        kindD.operations ~= tuple(FileOp.checkSyntax, "dmd -debug -wi -c -o-"); // TODO: Include paths
        srcFKinds ~= kindD;

        auto kindDi = new FKind("D Interface", [], ["di"],
                                magicForD, 0,
                                [],
                                keywordsD,
                                cCommentDelims,
                                defaultStringDelims,
                                FileContent.sourceCode,
                                FileKindDetection.equalsNameOrContents);
        kindDi.operations ~= tuple(FileOp.checkSyntax, "gdc -fsyntax-only");
        kindDi.operations ~= tuple(FileOp.checkSyntax, "dmd -debug -wi -c -o-"); // TODO: Include paths
        srcFKinds ~= kindDi;

        auto keywordsFortran77 = ["if", "else"];
        // TODO: Support .h files but require it to contain some Fortran-specific or be parseable.
        auto kindFortan = new FKind("Fortran", [], ["f", "fortran", "f77", "f90", "f95", "f03", "for", "ftn", "fpp"], [], 0, [], keywordsFortran77,
                                    [Delim("^C")], // TODO: Need beginning of line instead ^. seq(bol(), alt(lit('C'), lit('c'))); // TODO: Add chars chs("cC");
                                    defaultStringDelims,
                                    FileContent.sourceCode);
        kindFortan.operations ~= tuple(FileOp.checkSyntax, "gcc -x fortran -fsyntax-only");
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

        srcFKinds ~= new FKind("Python", [], ["py"],
                               shebangLine(lit("python")), 0,
                               [],
                               keywordsPython,
                               [Delim("#")], // TODO: Support multi-line triple-double quote strings
                               defaultStringDelims,
                               FileContent.scriptCode);
        srcFKinds ~= new FKind("Ruby", [], ["rb", "rhtml", "rjs", "rxml", "erb", "rake", "spec", ],
                               shebangLine(lit("ruby")), 0,
                               [], [],
                               [Delim("#"), Delim("=begin", "=end")],
                               defaultStringDelims,
                               FileContent.scriptCode);

        srcFKinds ~= new FKind("Scala", [], ["scala", ],
                               shebangLine(lit("scala")), 0,
                               [], [],
                               cCommentDelims,
                               defaultStringDelims,
                               FileContent.scriptCode);
        srcFKinds ~= new FKind("Scheme", [], ["scm", "ss"],
                               [], 0,
                               [], [],
                               [Delim(";")],
                               defaultStringDelims,
                               FileContent.scriptCode);

        srcFKinds ~= new FKind("Smalltalk", [], ["st"], [], 0, [], [],
                               [Delim("\"", "\"")],
                               defaultStringDelims,
                               FileContent.sourceCode);

        srcFKinds ~= new FKind("Perl", [], ["pl", "pm", "pm6", "pod", "t", "psgi", ],
                               shebangLine(lit("perl")), 0,
                               [], [],
                               [Delim("#")],
                               defaultStringDelims,
                               FileContent.scriptCode);
        srcFKinds ~= new FKind("PHP", [], ["php", "phpt", "php3", "php4", "php5", "phtml", ],
                               shebangLine(lit("php")), 0,
                               [], [],
                               [Delim("#")] ~ cCommentDelims,
                               defaultStringDelims,
                               FileContent.scriptCode);
        srcFKinds ~= new FKind("Plone", [], ["pt", "cpt", "metadata", "cpy", "py", ], [], 0, [], [],
                               [Delim("#")],
                               defaultStringDelims,
                               FileContent.scriptCode);

        srcFKinds ~= new FKind("Shell", [], ["sh"],
                               shebangLine(lit("sh")), 0,
                               [], [],
                               [Delim("#")],
                               defaultStringDelims,
                               FileContent.scriptCode);
        srcFKinds ~= new FKind("Bash", [], ["bash"],
                               shebangLine(lit("bash")), 0,
                               [], [],
                               [Delim("#")],
                               defaultStringDelims,
                               FileContent.scriptCode);
        srcFKinds ~= new FKind("Zsh", [], ["zsh"],
                               shebangLine(lit("zsh")), 0,
                               [], [],
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
        srcFKinds ~= new FKind("Viz Basic", [], ["bas", "cls", "frm", "ctl", "vb", "resx", ], [], 0, [], [],
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

        auto kindJava = new FKind("Java", [], ["java", "properties"], [], 0, [], [],
                                  cCommentDelims,
                                  defaultStringDelims,
                                  FileContent.sourceCode);
        srcFKinds ~= kindJava;
        kindJava.operations ~= tuple(FileOp.byteCompile, "javac");

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
        auto kindOctave = new FKind("Octave", [], ["m"], [], 0, [], [],
                                    [Delim("%{", "}%"), // TODO: Prio 1
                                     Delim("%"),
                                     Delim("#")],
                                    defaultStringDelims,
                                    FileContent.sourceCode);
        srcFKinds ~= kindOctave;
        kindOctave.operations ~= tuple(FileOp.byteCompile, "octave");

        srcFKinds ~= new FKind("Julia", [], ["jl"], [], 0, [], [],
                               [Delim("#")],
                               defaultStringDelims,
                               FileContent.sourceCode); // ((:execute "julia") (:evaluate "julia -e"))

        srcFKinds ~= new FKind("Erlang", [], ["erl", "hrl"], [], 0, [], [],
                               [Delim("%")],
                               defaultStringDelims,
                               FileContent.sourceCode);

        auto magicForElisp = seq(shebangLine(lit("emacs")),
                                 ws(),
                                 lit("--script"));
        auto kindElisp = new FKind("Emacs-Lisp", [],
                                   ["el", "lisp"],
                                   magicForElisp, 0, // Script Execution
                                   [], [],
                                   [Delim(";")],
                                   defaultStringDelims,
                                   FileContent.sourceCode);
        kindElisp.operations ~= tuple(FileOp.byteCompile, "emacs -batch -f batch-byte-compile");
        kindElisp.operations ~= tuple(FileOp.byteCompile, "emacs --script");
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

        // https://en.wikipedia.org/wiki/Diff
        auto diffKind = new FKind("Diff", [], ["diff", "patch"],
                                  "diff", 0,
                                  [], [],
                                  [], // N/A
                                  defaultStringDelims,
                                  FileContent.text);
        srcFKinds ~= diffKind;
        diffKind.wikiURL = "https://en.wikipedia.org/wiki/Diff";

        // Index Source Kinds by File extension
        FKind[][string] extSrcKinds;
        foreach (k; srcFKinds)
        {
            foreach (ext; k.exts)
            {
                extSrcKinds[ext] ~= k;
            }
        }
        extSrcKinds.rehash;

        // Index Source Kinds by kindName
        foreach (k; srcFKinds)
        {
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
        auto hdf4Kind = new FKind("HDF4", [], ["hdf", "h4", "hdf4", "he4"], x"0E031301", 0, [], [],
                                  [], // N/A
                                  defaultStringDelims,
                                  FileContent.numericalData);
        binFKinds ~= hdf4Kind;
        hdf4Kind.description = "Hierarchical Data Format version 4";

        auto hdf5Kind = new FKind("HDF5", "Hierarchical Data Format version 5", ["hdf", "h5", "hdf5", "he5"], x"894844460D0A1A0A", 0, [], [],
                                  [], // N/A
                                  defaultStringDelims,
                                  FileContent.numericalData);
        binFKinds ~= hdf5Kind;
        hdf5Kind.description = "Hierarchical Data Format version 5";

        binFKinds ~= new FKind("GNU GLOBAL Database", ["GTAGS", "GRTAGS", "GPATH", "GSYMS"], [], "b1\5\0", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.tagsDatabase, FileKindDetection.equalsContents);

        // SQLite
        auto extSQLite = ["sql", "sqlite", "sqlite3"];
        binFKinds ~= new FKind("MySQL table definition file", [], extSQLite, x"FE01", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.tagsDatabase, FileKindDetection.equalsContents);
        binFKinds ~= new FKind("MySQL MyISAM index file", [], extSQLite, x"FEFE07", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.tagsDatabase, FileKindDetection.equalsContents);
        binFKinds ~= new FKind("MySQL MyISAM compressed data file", [], extSQLite, x"FEFE08", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.tagsDatabase, FileKindDetection.equalsContents);
        binFKinds ~= new FKind("MySQL Maria index file", [], extSQLite, x"FFFFFF", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.tagsDatabase, FileKindDetection.equalsContents);
        binFKinds ~= new FKind("MySQL Maria compressed data file", [], extSQLite, x"FFFFFF", 0, [], [],
                               [], // N/A
                               defaultStringDelims,
                               FileContent.tagsDatabase, FileKindDetection.equalsContents);
        binFKinds ~= new FKind("SQLite format 3", [], extSQLite , "SQLite format 3", 0, [], [],
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

        binFKinds ~= new FKind("DS_Store", ".DS_Store", [], "Mac OS X Desktop Services Store ", 0, [], [],
                               [], // N/A
                               [],
                               FileContent.binary, FileKindDetection.equalsName);

        // By Extension
        foreach (kind; binFKinds)
        {
            foreach (ext; kind.exts)
            {
                binFKindsByExt[ext] ~= kind;
            }
        }
        binFKindsByExt.rehash;

        // By Magic
        foreach (kind; binFKinds)
        {
            if (kind.magicOffset == 0 && // only if zero-offset for now
                kind.magicData)
            {
                if (const magicLit = cast(Lit)kind.magicData)
                {
                    binFKindsByMagic[magicLit.bytes][magicLit.bytes.length] ~= kind;
                    binFKindsMagicLengths ~= magicLit.bytes.length; // add it
                }
            }
        }
        binFKindsMagicLengths = binFKindsMagicLengths.uniq.array; // remove duplicates
        binFKindsMagicLengths.sort; // and sort
        binFKindsByMagic.rehash;

        foreach (kind; binFKinds)
        {
            binFKindsById[kind.behaviorId] = kind;
        }
        binFKindsById.rehash;

        import std.range: chain;
        foreach (kind; chain(srcFKinds, binFKinds))
        {
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

    private {

        bool useHTML = false;
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

        FileOp _fileOp = FileOp.none;

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

    void prepare(string[] args, ref Term term)
    {
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
                                    "file-content-duplicates|scd", "\tDetect & Show file contents duplicates" ~ defaultDoc(gstats.showFileContentDups), &gstats.showFileContentDups,
                                    "tree-content-duplicates", "\tDetect & Show directory tree contents duplicates" ~ defaultDoc(gstats.showTreeContentDups), &gstats.showTreeContentDups,
                                    "duplicates|D", "\tDetect & Show file name and contents duplicates" ~ defaultDoc(gstats.showAnyDups), &gstats.showAnyDups,
                                    "duplicates-context", "\tDuplicates Detection Context. Either: " ~ enumDoc!DuplicatesContext, &duplicatesContext,
                                    "hardlink-content-duplicates", "\tConvert all content duplicates into hardlinks (common inode) if they reside on the same file system" ~ defaultDoc(gstats.linkContentDups), &gstats.linkContentDups,

                                    "usage", "\tShow disk usage (tree size) of scanned directories" ~ defaultDoc(gstats.showUsage), &gstats.showUsage,
                                    "sha1", "\tShow SHA1 content digests" ~ defaultDoc(gstats.showSHA1), &gstats.showSHA1,

                                    "mmaps", "\tShow when files are memory mapped (mmaped)" ~ defaultDoc(gstats.showMMaps), &gstats.showMMaps,

                                    "follow-symlinks|f", "\tFollow symbolic links" ~ defaultDoc(gstats.followSymlinks), &gstats.followSymlinks,
                                    "broken-symlinks|l", "\tDetect & Show broken symbolic links (target is non-existing file) " ~ defaultDoc(gstats.showBrokenSymlinks), &gstats.showBrokenSymlinks,
                                    "show-symlink-cycles|l", "\tDetect & Show symbolic links cycles" ~ defaultDoc(gstats.showSymlinkCycles), &gstats.showSymlinkCycles,

                                    "add-tag", "\tAdd tag string(s) to matching files" ~ defaultDoc(addTags), &addTags,
                                    "remove-tag", "\tAdd tag string(s) to matching files" ~ defaultDoc(removeTags), &removeTags,

                                    "tree|W", "\tShow Scanned Tree and Followed Symbolic Links" ~ defaultDoc(showTree), &showTree,
                                    "sort|S", "\tDirectory contents sorting order. Either: " ~ enumDoc!DirSorting, &subsSorting,
                                    "build", "\tBuild Source Code. Either: " ~ enumDoc!BuildType, &buildType,

                                    "path-format", "\tFormat of paths. Either: " ~ enumDoc!PathFormat ~ "." ~ defaultDoc(_pathFormat), &_pathFormat,

                                    "cache-file|F", "\tFile System Tree Cache File" ~ defaultDoc(_cacheFile), &_cacheFile,
                                    "recache", "\tSkip initial load of cache from disk" ~ defaultDoc(_recache), &_recache,

                                    "do", "\tOperation to perform on matching files. Either: " ~ enumDoc!FileOp, &_fileOp,

                                    "use-ngrams", "\tUse NGrams to cache statistics and thereby speed up search" ~ defaultDoc(_useNGrams), &_useNGrams,

                                    "html|H", "\tFormat output as HTML" ~ defaultDoc(useHTML), &useHTML,
                                    "browse|B", ("\tFormat output as HTML to a temporary file" ~
                                                 defaultDoc(_cacheFile) ~
                                                 " and open it with default Web browser" ~
                                                 defaultDoc(browseOutput)), &browseOutput,

                                    "author", "\tPrint name of\n"~"\tthe author",
                                    delegate() { writeln("Per Nordlöw"); }
            );

        if (gstats.showAnyDups)
        {
            gstats.showNameDups = true;
            gstats.showLinkDups = true;
            gstats.showFileContentDups = true;
            gstats.showTreeContentDups = true;
        }
        if (helpPrinted)
            return;

        _cacheFile = std.path.expandTilde(_cacheFile);

        if (_topDirNames.empty)
        {
            _topDirNames = ["."];
        }
        if (_topDirNames == ["."])
        {
            _pathFormat = PathFormat.relative;
        }
        else
        {
            _pathFormat = PathFormat.absolute;
        }
        foreach (ref topName; _topDirNames)
        {
            if (topName ==  ".")
            {
                topName = topName.absolutePath.buildNormalizedPath;
            }
            else
            {
                topName = topName.expandTilde.buildNormalizedPath;
            }
        }

        // Output Handling
        if (browseOutput)
        {
            useHTML = true;
            immutable ext = useHTML ? "html" : "results.txt";
            import std.uuid: randomUUID;
            outFile = ioFile("/tmp/fs-" ~ randomUUID().toString() ~
                             "." ~ ext,
                             "w");
            popen("firefox -new-tab " ~ outFile.name);
        }
        else
        {
            outFile = stdout;
        }

        auto cwd = getcwd();

        foreach (arg; args[1..$])
        {
            if (!arg.startsWith("-")) // if argument not a flag
            {
                keys ~= arg;
            }
        }

        // Calc stats
        keysBists = keys.map!bistogramOverRepresentation;
        keysXGrams = keys.map!(sparseUIntNGramOverRepresentation!NGramOrder);
        keysBistsUnion = reduce!"a | b"(typeof(keysBists.front).init, keysBists);
        keysXGramsUnion = reduce!"a + b"(typeof(keysXGrams.front).init, keysXGrams);

        auto viz = new Viz(outFile,
                           &term,
                           showTree,
                           useHTML ? VizForm.HTML : VizForm.textAsciiDocUTF8,
                           colorFlag,
                           !useHTML, // only use if HTML
                           true, // TODO: Only set if in debug mode
            );

        if (_useNGrams &&
            (!keys.empty) &&
            keysXGramsUnion.empty)
        {
            _useNGrams = false;
            viz.ppln("Keys must be at least of length " ~
                     to!string(NGramOrder + 1) ~
                     " in order for " ~
                     keysXGrams[0].typeName ~
                     " to be calculated");
        }

        // viz.ppln("<meta http-equiv=\"refresh\" content=\"1\"/>"); // refresh every second

        if (includedTypes)
        {
            foreach (lang; includedTypes.splitter(","))
            {
                if (lang in srcFKindsByName)
                {
                    incKinds ~= srcFKindsByName[lang];
                }
                else if (lang.toLower in srcFKindsByName)
                {
                    incKinds ~= srcFKindsByName[lang.toLower];
                }
                else if (lang.toUpper in srcFKindsByName)
                {
                    incKinds ~= srcFKindsByName[lang.toUpper];
                }
                else
                {
                    writeln("warning: Language ", lang, " not registered. Defaulting to all file types.");
                }
            }
        }

        // Maps extension string to Included FileKinds
        foreach (kind; incKinds)
        {
            foreach (ext; kind.exts)
            {
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
        if (keys)
        {
            incKindsNote = " in " ~ (incKinds ? incKinds.map!(a => a.kindName).join(",") ~ "-" : "all ") ~ "files";
            immutable underNote = " under \"" ~ (_topDirNames.reduce!"a ~ ',' ~ b") ~ "\"";
            const exactNote = _keyAsExact ? "exact " : "";
            string asNote;
            if (_keyAsAcronym)
            {
                asNote = (" as " ~ exactNote ~
                          (keyAsWord ? "word" : "symbol") ~
                          " acronym" ~ keysPluralExt);
            }
            else if (keyAsSymbol)
            {
                asNote = " as " ~ exactNote ~ "symbol" ~ keysPluralExt;
            }
            else if (keyAsWord)
            {
                asNote = " as " ~ exactNote ~ "word" ~ keysPluralExt;
            }
            else
            {
                asNote = "";
            }

            const title = ("Searching for \"" ~ commaedKeysString ~ "\"" ~
                           " case-" ~ (_caseFold ? "in" : "") ~"sensitively"
                           ~asNote ~incKindsNote ~underNote);
            if (viz.form == VizForm.HTML) // only needed for HTML output
            {
                viz.ppln(faze(title, titleFace));
            }

            viz.pp(asH!1("Searching for \"", commaedKeysString, "\"",
                         " case-", (_caseFold ? "in" : ""), "sensitively",
                         asNote, incKindsNote,
                         " under ", _topDirNames.map!(a => asPath(a))));
        }

        /* viz.pp("Source Kinds".asH!2, */
        /*        srcFKinds.asTable); */
        /* binFKinds.asTable, */

        if (_showSkipped)
        {
            viz.pp("Skipping files of type".asH!2,
                   asUList(binFKinds.map!(a => asItem(a.kindName.asBold,
                                                      ": ",
                                                      asCSL(a.exts.map!(b => b.asCode))))));
        }

        // if (key && key == key.toLower()) { // if search key is all lowercase
        //     _caseFold = true;               // we do case-insensitive search like in Emacs
        // }

        _uid = getuid();
        _gid = getgid();

        // Setup root directory
        if (!_recache)
        {
            GC.disable;
            _rootDir = loadRootDirTree(viz, _cacheFile, gstats);
            GC.enable;
        }
        if (!_rootDir) // if first time
        {
            _rootDir = new Dir("/", gstats); // filesystem root directory. TODO: Make this uncopyable?
        }

        // Scan for exact key match
        _topDirs = getDirs(enforceNotNull(_rootDir), _topDirNames);

        _currTime = Clock.currTime();

        GC.disable;
        scanTopDirs(viz, commaedKeysString);
        GC.enable;

        GC.disable;
        saveRootDirTree(viz, _rootDir, _cacheFile);
        GC.enable;

        // Print statistics
        showStats(viz);
    }

    void scanTopDirs(Viz viz,
                     string commaedKeysString)
    {
        viz.pp("Results".asH!2);
        if (_topDirs)
        {
            foreach (topIx, topDir; _topDirs)
            {
                scanDir(viz, assumeNotNull(topDir), assumeNotNull(topDir), keys);
                if (ctrlC)
                {
                    auto restDirs = _topDirs[topIx + 1..$];
                    if (!restDirs.empty)
                    {
                        debug dln("Ctrl-C pressed: Skipping search of " ~ to!string(restDirs));
                        break;
                    }
                }
            }

            viz.pp("Summary".asH!2);

            if ((gstats.noScannedFiles - gstats.noScannedDirs) == 0)
            {
                viz.ppln("No files with any content found");
            }
            else
            {
                // Scan for acronym key match
                if (keys && _hitsCountTotal == 0)  // if keys given but no hit found
                {
                    auto keysString = (keys.length >= 2 ? "s" : "") ~ " \"" ~ commaedKeysString;
                    if (_keyAsAcronym)
                    {
                        viz.ppln(("No acronym matches for key" ~ keysString ~ `"` ~
                                  (keyAsSymbol ? " as symbol" : "") ~
                                  " found in files of type"));
                    }
                    else if (!_keyAsExact)
                    {
                        viz.ppln(("No exact matches for key" ~ keysString ~ `"` ~
                                  (keyAsSymbol ? " as symbol" : "") ~
                                  " found" ~ incKindsNote ~
                                  ". Relaxing scan to" ~ (keyAsSymbol ? " symbol" : "") ~ " acronym match."));
                        _keyAsAcronym = true;

                        foreach (topDir; _topDirs)
                        {
                            scanDir(viz, assumeNotNull(topDir), assumeNotNull(topDir), keys);
                        }
                    }
                }
            }
        }

        assert(gstats.noScannedDirs +
               gstats.noScannedRegFiles +
               gstats.noScannedSymlinks +
               gstats.noScannedSpecialFiles == gstats.noScannedFiles);
    }

    version(linux)
    {
        @trusted bool readable(in stat_t stat, uid_t uid, gid_t gid, ref string msg)
        {
            immutable mode = stat.st_mode;
            immutable ok = ((stat.st_uid == uid) && (mode & S_IRUSR) ||
                            (stat.st_gid == gid) && (mode & S_IRGRP) ||
                            (mode & S_IROTH));
            if (!ok)
            {
                msg = " is not readable by you, but only by";
                bool can = false; // someone can access
                if (mode & S_IRUSR)
                {
                    can = true;
                    msg ~= " user id " ~ to!string(stat.st_uid);

                    // Lookup user name from user id
                    passwd pw;
                    passwd* pw_ret;
                    immutable size_t bufsize = 16384;
                    char* buf = cast(char*)core.stdc.stdlib.malloc(bufsize);
                    getpwuid_r(stat.st_uid, &pw, buf, bufsize, &pw_ret);
                    if (pw_ret != null)
                    {
                        string userName;
                        {
                            size_t n = 0;
                            while (pw.pw_name[n] != 0)
                            {
                                userName ~= pw.pw_name[n];
                                n++;
                            }
                        }
                        msg ~= " (" ~ userName ~ ")";

                        // string realName;
                        // {
                        //     size_t n = 0;
                        //     while (pw.pw_gecos[n] != 0)
                        //     {
                        //         realName ~= pw.pw_gecos[n];
                        //         n++;
                        //     }
                        // }
                    }
                    core.stdc.stdlib.free(buf);

                }
                if (mode & S_IRGRP)
                {
                    can = true;
                    if (msg != "")
                    {
                        msg ~= " or";
                    }
                    msg ~= " group id " ~ to!string(stat.st_gid);
                }
                if (!can)
                {
                    msg ~= " root";
                }
            }
            return ok;
        }
    }

    Results results;

    void handleError(F)(Viz viz,
                        NotNull!F file, bool isDir, size_t subIndex)
    {
        auto dent = DirEntry(file.path);
        immutable stat_t stat = dent.statBuf();
        string msg;
        if (!readable(stat, _uid, _gid, msg))
        {
            results.noBytesUnreadable += dent.size;
            if (_showSkipped)
            {
                if (showTree)
                {
                    auto parentDir = file.parent;
                    immutable intro = subIndex == parentDir.subs.length - 1 ? "└" : "├";
                    viz.pp("│  ".repeat(parentDir.depth + 1).join("") ~ intro ~ "─ ");
                }
                viz.ppln(file,
                         ":  ", isDir ? "Directory" : "File",
                         faze(msg, warnFace));
            }
        }
    }

    void printSkipped(Viz viz,
                      NotNull!RegFile regfile,
                      in string ext, size_t subIndex,
                      in NotNull!FKind kind, KindHit kindhit,
                      in string skipCause)
    {
        auto parentDir = regfile.parent;
        if (_showSkipped)
        {
            if (showTree)
            {
                immutable intro = subIndex == parentDir.subs.length - 1 ? "└" : "├";
                viz.pp("│  ".repeat(parentDir.depth + 1).join("") ~ intro ~ "─ ");
            }
            viz.pp(horizontalRuler,
                   asH!3(regfile,
                         ": Skipped ", kind, " file",
                         skipCause));
        }
    }

    KindHit isBinary(Viz viz,
                     NotNull!RegFile regfile,
                     in string ext, size_t subIndex)
    {
        auto hit = KindHit.none;

        auto parentDir = regfile.parent;

        // First Try with kindId as try
        if (regfile._cstat.kindId.defined) // kindId is already defined and uptodate
        {
            if (regfile._cstat.kindId in binFKindsById)
            {
                const kind = enforceNotNull(binFKindsById[regfile._cstat.kindId]);
                hit = KindHit.cached;
                printSkipped(viz, regfile, ext, subIndex, kind, hit,
                             " using cached KindId");
            }
            else
            {
                hit = KindHit.none;
            }
            return hit;
        }

        // First Try with extension lookup as guess
        if (!ext.empty &&
            ext in binFKindsByExt)
        {
            foreach (kindIndex, kind; binFKindsByExt[ext])
            {
                auto nnKind = enforceNotNull(kind);
                hit = regfile.ofKind(ext, nnKind, collectTypeHits, gstats.allKindsById);
                if (hit)
                {
                    printSkipped(viz, regfile, ext, subIndex, nnKind, hit,
                                 " (" ~ ext ~ ") at " ~ nthString(kindIndex + 1) ~ " extension try");
                    break;
                }
            }
        }

        if (!hit)               // If still no hit
        {
            foreach (kindIndex, kind; binFKinds) // Iterate each kind
            {
                auto nnKind = enforceNotNull(kind);
                hit = regfile.ofKind(ext, nnKind, collectTypeHits, gstats.allKindsById);
                if (hit)
                {
                    if (_showSkipped)
                    {
                        if (showTree)
                        {
                            immutable intro = subIndex == parentDir.subs.length - 1 ? "└" : "├";
                            viz.pp("│  ".repeat(parentDir.depth + 1).join("") ~ intro ~ "─ ");
                        }
                        viz.ppln(regfile, ": Skipped ", kind, " file at ",
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
        if (regfile._cstat.kindId.defined) // kindId is already defined and uptodate
        {
            if (regfile._cstat.kindId in gstats.incKindsById)
            {
                hitKind = gstats.incKindsById[regfile._cstat.kindId];
                kindHit = KindHit.cached;
                return kindHit;
            }
        }

        // Try with hash table first
        if (!ext.empty && // if file has extension and
            ext in incKindsByName) // and extensions may match specified included files
        {
            auto possibleKinds = incKindsByName[ext];
            foreach (kind; possibleKinds)
            {
                auto nnKind = enforceNotNull(kind);
                immutable hit = regfile.ofKind(ext, nnKind, collectTypeHits, gstats.allKindsById);
                if (hit)
                {
                    hitKind = nnKind;
                    kindHit = hit;
                    break;
                }
            }
        }

        if (!hitKind) // if no hit yet
        {
            // blindly try the rest
            foreach (kind; incKinds)
            {
                auto nnKind = enforceNotNull(kind);
                immutable hit = regfile.ofKind(ext, nnKind, collectTypeHits, gstats.allKindsById);
                if (hit)
                {
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
    size_t scanForKeys(Source, Keys)(Viz viz,
                                     NotNull!Dir topDir,
                                     NotNull!File theFile,
                                     NotNull!Dir parentDir,
                                     ref Symlink[] fromSymlinks,
                                     in Source src,
                                     in Keys keys,
                                     in bool[] bistHits = [],
                                     ScanContext ctx = ScanContext.standard)
    {
        bool anyFileHit = false; // will become true if any hit in this file

        typeof(return) hitCount = 0;

        import std.ascii: newline;

        auto thisFace = stdFace;
        if (colorFlag)
        {
            if (ScanContext.fileName)
            {
                thisFace = fileFace;
            }
        }

        // GNU Grep-Compatible File Name/Path Formatting
        immutable displayedFileName = ((_pathFormat == PathFormat.relative &&
                                        _topDirs.length == 1) ?
                                       "./" ~ theFile.name :
                                       theFile.path);

        size_t nL = 0; // line counter
        foreach (line; src.splitter(cast(immutable ubyte[])newline))
        {
            auto rest = cast(string)line; // rest of line as a string

            bool anyLineHit = false; // will become true if any hit on current line
            // Hit search loop
            while (!rest.empty)
            {
                // Find any key

                /* TODO: Convert these to a range. */
                ptrdiff_t offKB = -1;
                ptrdiff_t offKE = -1;

                foreach (uint ix, key; keys) // TODO: Call variadic-find instead to speed things up.
                {
                    /* Bistogram Discardal */
                    if ((!bistHits.empty) &&
                        !bistHits[ix]) // if neither exact nor acronym match possible
                    {
                        continue; // try next key
                    }

                    /* dln("key:", key, " line:", line); */
                    ptrdiff_t[] acronymOffsets;
                    if (_keyAsAcronym) // acronym search
                    {
                        auto hit = (cast(immutable ubyte[])rest).findAcronymAt(key,
                                                                               keyAsSymbol ? FindContext.inSymbol : FindContext.inWord);
                        if (!hit[0].empty)
                        {
                            acronymOffsets = hit[1];
                            offKB = hit[1][0];
                            offKE = hit[1][$-1] + 1;
                        }
                    }
                    else
                    { // normal search
                        import std.string: indexOf;
                        offKB = rest.indexOf(key,
                                             _caseFold ? CaseSensitive.no : CaseSensitive.yes); // hit begin offset
                        offKE = offKB + key.length; // hit end offset
                    }

                    if (offKB >= 0) // if hit
                    {
                        if (!showTree && ctx == ScanContext.fileName)
                        {
                            viz.pp(parentDir, dirSeparator);
                        }

                        // Check Context
                        if ((keyAsSymbol && !isSymbolASCII(rest, offKB, offKE)) ||
                            (keyAsWord   && !isWordASCII  (rest, offKB, offKE)))
                        {
                            rest = rest[offKE..$]; // move forward in line
                            continue;
                        }

                        if (ctx == ScanContext.fileContent &&
                            !anyLineHit) // if this is first hit
                        {
                            if (viz.form == VizForm.HTML)
                            {
                                if (!anyFileHit)
                                {
                                    viz.pp(horizontalRuler,
                                           displayedFileName.asPath.asH!3);
                                    viz.ppTagOpen(`table`, `border=1`);
                                    anyFileHit = true;
                                }
                            }
                            else
                            {
                                if (showTree)
                                {
                                    viz.pp("│  ".repeat(parentDir.depth + 1).join("") ~ "├" ~ "─ ");
                                }
                                else
                                {
                                    foreach (fromSymlink; fromSymlinks)
                                    {
                                        viz.pp(fromSymlink,
                                               " modified ",
                                               faze(shortDurationString(_currTime - fromSymlink.timeLastModified),
                                                    timeFace),
                                               " ago",
                                               " -> ");
                                    }
                                    // show file path/name
                                    viz.pp(asPath(displayedFileName)); // show path
                                }
                            }

                            // show line:column
                            if (viz.form == VizForm.HTML)
                            {
                                viz.ppTagOpen("tr");
                                viz.pp(to!string(nL+1).asCell,
                                       to!string(offKB+1).asCell);
                                viz.ppTagOpen("td");
                                viz.ppTagOpen("code");
                            }
                            else
                            {
                                viz.pp(faze(":" ~ to!string(nL+1) ~ ":" ~ to!string(offKB+1) ~ ":",
                                            contextFace));
                            }
                            anyLineHit = true;
                        }

                        // show content prefix
                        viz.pp(faze(to!string(rest[0..offKB]), thisFace));

                        // show hit part
                        if (!acronymOffsets.empty)
                        {
                            foreach (aIx, currOff; acronymOffsets) // TODO: Reuse std.algorithm: zip or lockstep? Or create a new kind say named conv.
                            {
                                // context before
                                if (aIx >= 1)
                                {
                                    immutable prevOff = acronymOffsets[aIx-1];
                                    if (prevOff + 1 < currOff) // at least one letter in between
                                    {
                                        viz.pp(asCtx(ix, to!string(rest[prevOff + 1 .. currOff])));
                                    }
                                }
                                // hit letter
                                viz.pp(asHit(ix, to!string(rest[currOff])));
                            }
                        }
                        else
                        {
                            viz.pp(asHit(ix, to!string(rest[offKB..offKE])));
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
            if (anyLineHit)
            {
                // show final context suffix
                viz.ppln(faze(rest, thisFace));
                if (viz.form == VizForm.HTML)
                {
                    viz.ppTagClose("code");
                    viz.ppTagClose("td");
                    viz.pplnTagClose("tr");
                }
            }
            nL++;
        }

        if (anyFileHit)
        {
            viz.pplnTagClose("table");
        }

        // Previous solution
        // version(none)
        // {
        //     ptrdiff_t offHit = 0;
        //     foreach(ix, key; keys)
        //     {
        //         scope immutable hit1 = src.find(key); // single key hit
        //         offHit = hit1.ptr - src.ptr;
        //         if (!hit1.empty)
        //         {
        //             scope immutable src0 = src[0..offHit]; // src beforce hi
        //             immutable rowHit = count(src0, newline);
        //             immutable colHit = src0.retro.countUntil(newline); // count backwards till beginning of rowHit
        //             immutable offBOL = offHit - colHit;
        //             immutable cntEOL = src[offHit..$].countUntil(newline); // count forwards to end of rowHit
        //             immutable offEOL = (cntEOL == -1 ? // if no hit
        //                                 src.length :   // end of file
        //                                 offHit + cntEOL); // normal case
        //             viz.pp(faze(asPath(useHTML, dent.name), pathFace));
        //             viz.ppln(":", rowHit + 1,
        //                                                                               ":", colHit + 1,
        //                                                                               ":", cast(string)src[offBOL..offEOL]);
        //         }
        //     }
        // }

        // switch (keys.length)
        // {
        // default:
        //     break;
        // case 0:
        //     break;
        // case 1:
        //     immutable hit1 = src.find(keys[0]);
        //     if (!hit1.empty)
        //     {
        //         viz.ppln(asPath(useHTML, dent.name[2..$]), ":1: HIT offset: ", hit1.length);
        //     }
        //     break;
        // // case 2:
        // //     immutable hit2 = src.find(keys[0], keys[1]); // find two keys
        // //     if (!hit2[0].empty) { viz.ppln(asPath(useHTML, dent.name[2..$]), ":1: HIT offset: ", hit2[0].length); }
        // //     if (!hit2[1].empty) { viz.ppln(asPath(useHTML, dent.name[2..$]) , ":1: HIT offset: ", hit2[1].length); }
        // //     break;
        // // case 3:
        // //     immutable hit3 = src.find(keys[0], keys[1], keys[2]); // find two keys
        // //     if (!hit3.empty)
        //        {
        // //         viz.ppln(asPath(useHTML, dent.name[2..$]) , ":1: HIT offset: ", hit1.length);
        // //     }
        // //     break;
        // }
        return hitCount;
    }

    /** Search for Keys $(D keys) in Regular File $(D theRegFile). */
    void scanRegFile(Viz viz,
                     NotNull!Dir topDir,
                     NotNull!RegFile theRegFile,
                     NotNull!Dir parentDir,
                     in string[] keys,
                     ref Symlink[] fromSymlinks,
                     size_t subIndex)
    {
        results.noBytesTotal += theRegFile.size;
        results.noBytesTotalContents += theRegFile.size;

        // Scan name
        if ((_scanContext == ScanContext.all ||
             _scanContext == ScanContext.fileName ||
             _scanContext == ScanContext.regularFileName) &&
            !keys.empty)
        {
            immutable hitCountInName = scanForKeys(viz,
                                                   topDir, cast(NotNull!File)theRegFile, parentDir,
                                                   fromSymlinks,
                                                   theRegFile.name, keys, [], ScanContext.fileName);
        }

        // Scan Contents
        if ((_scanContext == ScanContext.all ||
             _scanContext == ScanContext.fileContent) &&
            (gstats.showFileContentDups ||
             !keys.empty) &&
            theRegFile.size != 0)        // non-empty file
        {
            // immutable upTo = size_t.max;

            // TODO: Flag for readText
            try
            {

                ++gstats.noScannedRegFiles;
                ++gstats.noScannedFiles;

                immutable ext = theRegFile.name.extension.chompPrefix("."); // extension sans dot

                // Check included kinds first because they are fast.
                KindHit incKindHit = isIncludedKind(theRegFile, ext, incKinds);
                if (!incKinds.empty && // TODO: Do we really need this one?
                    !incKindHit)
                {
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
                theRegFile.calculateCStatInChunks(gstats.filesByContentId,
                                                  _scanChunkSize,
                                                  gstats.showFileContentDups,
                                                  doBist,
                                                  doBitStatus);

                // Match Bist of Keys with BistX of File
                bool[] bistHits;
                bool noBistMatch = false;
                if (doBist)
                {
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
                if (doNGram)
                {
                    ulong keysXGramUnionMatch = keysXGramsUnion.matchDenser(theRegFile.xgram);
                    debug dln(theRegFile.path,
                              " sized ", theRegFile.size, " : ",
                              keysXGramsUnion.length, ", ",
                              theRegFile.xgram.length,
                              " gave match:", keysXGramUnionMatch);
                    allXGramsMiss = keysXGramUnionMatch == 0;
                }

                immutable binFlag = isBinary(viz, theRegFile, ext, subIndex);

                if (binFlag || noBistMatch || allXGramsMiss) // or no hits possible. TODO: Maybe more efficient to do histogram discardal first
                {
                    results.noBytesSkipped += theRegFile.size;
                }
                else
                {
                    // Search if not Binary

                    // If Source file is ok
                    auto src = theRegFile.readOnlyContents[];

                    results.noBytesScanned += theRegFile.size;

                    if (keys)
                    {
                        // Fast discardal of files with no match
                        bool fastOk = true;
                        if (!_caseFold) { // if no relaxation of search
                            if (_keyAsAcronym) // if no relaxation of search
                            {
                                /* TODO: Reuse findAcronym in algorith_ex. */
                            }
                            else // if no relaxation of search
                            {
                                switch (keys.length)
                                {
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

                        if (fastOk)
                        {
                            foreach (tag; addTags) gstats.ftags.addTag(theRegFile, tag);
                            foreach (tag; removeTags) gstats.ftags.removeTag(theRegFile, tag);

                            if (theRegFile.size >= 8192)
                            {
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

                            theRegFile._cstat.hitCount = scanForKeys(viz,
                                                                     topDir, cast(NotNull!File)theRegFile, parentDir,
                                                                     fromSymlinks,
                                                                     src, keys, bistHits,
                                                                     ScanContext.fileContent);
                        }
                    }
                }

            }
            catch (FileException)
            {
                handleError(viz, theRegFile, false, subIndex);
            }
            catch (ErrnoException)
            {
                handleError(viz, theRegFile, false, subIndex);
            }
            theRegFile.freeContents;
        }
    }

    /** Scan Symlink $(D symlink) at $(D parentDir) for $(D keys)
        Put results in $(D results). */
    void scanSymlink(Viz viz,
                     NotNull!Dir topDir,
                     NotNull!Symlink theSymlink,
                     NotNull!Dir parentDir,
                     in string[] keys,
                     ref Symlink[] fromSymlinks)
    {
        // check for symlink cycles
        if (!fromSymlinks.find(theSymlink).empty)
        {
            if (gstats.showSymlinkCycles)
            {
                import std.range: back;
                viz.ppln("Cycle of symbolic links: ",
                         asPath(fromSymlinks),
                         " -> ",
                         fromSymlinks.back.target);
            }
            return;
        }

        // Scan name
        if ((_scanContext == ScanContext.all ||
             _scanContext == ScanContext.fileName ||
             _scanContext == ScanContext.symlinkName) &&
            !keys.empty)
        {
            scanForKeys(viz,
                        topDir, cast(NotNull!File)theSymlink, enforceNotNull(theSymlink.parent),
                        fromSymlinks,
                        theSymlink.name, keys, [], ScanContext.fileName);
        }

        // try {
        //     results.noBytesTotal += dent.size;
        // } catch (Exception)
        //   {
        //     dln("Could not get size of ",  dir.name);
        // }
        if (gstats.followSymlinks == SymlinkFollowContext.none) { return; }

        import std.range: popBackN;
        fromSymlinks ~= theSymlink;
        immutable targetPath = theSymlink.absoluteNormalizedTargetPath;
        if (targetPath.exists)
        {
            theSymlink._targetStatus = SymlinkTargetStatus.present;
            if (_topDirNames.all!(a => !targetPath.startsWith(a))) { // if target path lies outside of all rootdirs
                auto targetDent = DirEntry(targetPath);
                auto targetFile = getFile(enforceNotNull(_rootDir), targetPath, targetDent.isDir);

                if (showTree)
                {
                    viz.ppln("│  ".repeat(parentDir.depth + 1).join("") ~ "├" ~ "─ ",
                             theSymlink,
                             " modified ",
                             faze(shortDurationString(_currTime - theSymlink.timeLastModified),
                                  timeFace),
                             " ago", " -> ",
                             asPath(targetFile),
                             faze(" outside of " ~ (_topDirNames.length == 1 ? "tree " : "all trees "),
                                  infoFace),
                             asPath(_topDirs),
                             faze(" is followed", infoFace));
                }

                ++gstats.noScannedSymlinks;
                ++gstats.noScannedFiles;

                if      (auto targetRegFile = cast(RegFile)targetFile)
                {
                    scanRegFile(viz, topDir, assumeNotNull(targetRegFile), parentDir, keys, fromSymlinks, 0);
                }
                else if (auto targetDir = cast(Dir)targetFile)
                {
                    scanDir(viz, topDir, assumeNotNull(targetDir), keys, fromSymlinks);
                }
                else if (auto targetSymlink = cast(Symlink)targetFile) // target is a Symlink
                {
                    scanSymlink(viz, topDir,
                                assumeNotNull(targetSymlink),
                                enforceNotNull(targetSymlink.parent),
                                keys, fromSymlinks);
                }
            }
        }
        else
        {
            theSymlink._targetStatus = SymlinkTargetStatus.broken;

            if (gstats.showBrokenSymlinks)
            {
                _brokenSymlinks ~= theSymlink;

                foreach (ix, fromSymlink; fromSymlinks)
                {
                    if (showTree && ix == 0)
                    {
                        immutable intro = "├";
                        viz.pp("│  ".repeat(theSymlink.parent.depth + 1).join("") ~ intro ~ "─ ",
                               theSymlink);
                    }
                    else
                    {
                        viz.pp(fromSymlink);
                    }
                    viz.pp(" -> ");
                }

                viz.ppln(faze(theSymlink.target, errorFace),
                         faze(" is missing", warnFace));
            }
        }
        fromSymlinks.popBackN(1);
    }

    /** Scan Directory $(D parentDir) for $(D keys). */
    void scanDir(Viz viz,
                 NotNull!Dir topDir,
                 NotNull!Dir theDir,
                 in string[] keys,
                 Symlink[] fromSymlinks = [],
                 int maxDepth = -1)
    {
        if (theDir.isRoot)  { results.reset(); }

        // scan in directory name
        if ((_scanContext == ScanContext.all ||
             _scanContext == ScanContext.fileName ||
             _scanContext == ScanContext.dirName) &&
            !keys.empty)
        {
            scanForKeys(viz,
                        topDir,
                        cast(NotNull!File)theDir,
                        enforceNotNull(theDir.parent),
                        fromSymlinks,
                        theDir.name, keys, [], ScanContext.fileName);
        }

        try
        {
            size_t subIndex = 0;
            if (showTree)
            {
                immutable intro = subIndex == theDir.subs.length - 1 ? "└" : "├";

                viz.pp("│  ".repeat(theDir.depth).join("") ~ intro ~
                       "─ ", theDir, " modified ",
                       faze(shortDurationString(_currTime -
                                                theDir.timeLastModified),
                            timeFace),
                       " ago");

                if (gstats.showUsage)
                {
                    viz.pp(" of Tree-Size ", theDir.treeSize);
                }

                if (gstats.showSHA1)
                {
                    viz.pp(" with Tree-Content-Id ", theDir.treeContentId);
                }
                viz.ppendl();
            }

            ++gstats.noScannedDirs;
            ++gstats.noScannedFiles;

            auto subsSorted = theDir.subsSorted(subsSorting);
            foreach (key, sub; subsSorted)
            {
                /* TODO: Functionize to scanFile() */
                if (auto regfile = cast(RegFile)sub)
                {
                    scanRegFile(viz, topDir, assumeNotNull(regfile), theDir, keys, fromSymlinks, subIndex);
                }
                else if (auto subDir = cast(Dir)sub)
                {
                    if (maxDepth == -1 || // if either all levels or
                        maxDepth >= 1) { // levels left
                        // Version Control System Directories
                        if (sub.name in skippedDirKindsMap)
                        {
                            if (_showSkipped)
                            {
                                if (showTree)
                                {
                                    immutable intro = subIndex == theDir.subs.length - 1 ? "└" : "├";
                                    viz.pp("│  ".repeat(theDir.depth + 1).join("") ~ intro ~ "─ ");
                                }

                                viz.pp(subDir,
                                       " modified ",
                                       faze(shortDurationString(_currTime -
                                                                subDir.timeLastModified),
                                            timeFace),
                                       " ago",
                                       faze(": Skipped Directory of type ", infoFace),
                                       skippedDirKindsMap[sub.name].kindName);
                            }
                        }
                        else
                        {
                            scanDir(viz, topDir,
                                    assumeNotNull(subDir),
                                    keys,
                                    fromSymlinks,
                                    maxDepth >= 0 ? --maxDepth : maxDepth);
                        }
                    }
                }
                else if (auto subSymlink = cast(Symlink)sub)
                {
                    scanSymlink(viz, topDir, assumeNotNull(subSymlink), theDir, keys, fromSymlinks);
                }
                else
                {
                    if (showTree) { viz.ppendl(); }
                }
                ++subIndex;

                if (ctrlC)
                {
                    viz.ppln("Ctrl-C pressed: Aborting scan of ", theDir);
                    break;
                }
            }

            if (gstats.showTreeContentDups)
            {
                theDir.treeContentId; // better to put this after file scan for now
            }
        }
        catch (FileException)
        {
            handleError(viz, theDir, true, 0);
        }
    }

    /* isIncludedKind(cast(NotNull!File)dupFile, */
    /*                dupFile.name.extension.chompPrefix("."), */
    /*                incKinds) */

    // Filter out $(D files) that lie under any of the directories $(D dirPaths).
    F[] filterUnderAnyOfPaths(F)(F[] files,
                                 string[] dirPaths,
                                 FKind[] incKinds)
    {
        import std.algorithm: any;
        import std.array: array;
        auto dupFilesUnderAnyTopDirName = (files
                                           .filter!(dupFile =>
                                                    dirPaths.any!(dirPath =>
                                                                  dupFile.path.startsWith(dirPath)))
                                           .array // evaluate to array to get .length below
            );
        F[] hits;
        final switch (duplicatesContext)
        {
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
    void showStats(Viz viz)
    {
        /* Duplicates */

        if (gstats.showNameDups)
        {
            viz.pp("Name Duplicates".asH!2);
            foreach (digest, dupFiles; gstats.filesByName)
            {
                auto dupFilesOk = filterUnderAnyOfPaths(dupFiles, _topDirNames, incKinds);
                if (!dupFilesOk.empty)
                {
                    viz.pp(asH!3("Files with same name ",
                                 faze(dupFilesOk[0].name, fileFace)),
                           asUList(dupFilesOk.map!(x => x.asPath.asItem)));
                }
            }
        }

        if (gstats.showLinkDups)
        {
            viz.pp("Inode Duplicates (Hardlinks)".asH!2);
            foreach (inode, dupFiles; gstats.filesByInode)
            {
                auto dupFilesOk = filterUnderAnyOfPaths(dupFiles, _topDirNames, incKinds);
                if (dupFilesOk.length >= 2)
                {
                    viz.pp(asH!3("Files with same inode " ~ to!string(inode) ~
                                 " (hardlinks): "),
                           asUList(dupFilesOk.map!(x => x.asPath.asItem)));
                }
            }
        }

        if (gstats.showFileContentDups)
        {
            viz.pp("Content Duplicates".asH!2);
            foreach (digest, dupFiles; gstats.filesByContentId)
            {
                auto dupFilesOk = filterUnderAnyOfPaths(dupFiles, _topDirNames, incKinds);
                if (dupFilesOk.length >= 2) // non-empty file/directory
                {

                    auto firstDup = dupFilesOk[0];
                    immutable typeName = cast(RegFile)firstDup ? "Files" : "Directories";
                    viz.pp(asH!3(typeName ~ " with same content",
                                 " (", digest, ")",
                                 " of size ", firstDup.size));

                    // content. TODO: Functionize
                    auto dupRegFile = cast(RegFile)firstDup;
                    if (dupRegFile)
                    {
                        if (dupRegFile._cstat.kindId)
                        {
                            viz.pp(" is ",
                                   gstats.allKindsById[dupRegFile._cstat.kindId]);
                        }
                        viz.pp(" is ",
                               (dupRegFile._cstat.bitStatus == BitStatus.bits7) ? "ASCII" : ""
                            );
                    }

                    viz.pp(asUList(dupFilesOk.map!(x => x.asPath.asItem)));
                }
            }
        }

        /* Broken Symlinks */
        if (gstats.showBrokenSymlinks &&
            !_brokenSymlinks.empty)
        {
            viz.pp("Broken Symlinks ".asH!2,
                   asUList(_brokenSymlinks.map!(x => x.asPath.asItem)));
        }

        /* Counts */
        viz.pp("Scanned Types".asH!2,
               /* asUList(asItem(gstats.noScannedDirs, " Dirs, "), */
               /*         asItem(gstats.noScannedRegFiles, " Regular Files, "), */
               /*         asItem(gstats.noScannedSymlinks, " Symbolic Links, "), */
               /*         asItem(gstats.noScannedSpecialFiles, " Special Files, "), */
               /*         asItem("totalling ", gstats.noScannedFiles, " Files") // on extra because of lack of root */
               /*     ) */
               asTable(asRow(asCell(asBold("Scan Count")),
                             asCell(asBold("File Type"))),
                       asRow(asCell(gstats.noScannedDirs),
                             asCell(asItalic("Dirs"))),
                       asRow(asCell(gstats.noScannedRegFiles),
                             asCell(asItalic("Regular Files"))),
                       asRow(asCell(gstats.noScannedSymlinks),
                             asCell(asItalic("Symbolic Links"))),
                       asRow(asCell(gstats.noScannedSpecialFiles),
                             asCell(asItalic("Special Files"))),
                       asRow(asCell(gstats.noScannedFiles),
                             asCell(asItalic("Files")))
                   )
            );

        if (gstats.densenessCount)
        {
            viz.pp("Histograms".asH!2,
                   asUList(asItem("Average Byte Bistogram (Binary Histogram) Denseness ",
                                  cast(real)(100*gstats.shallowDensenessSum / gstats.densenessCount), " Percent"),
                           asItem("Average Byte ", NGramOrder, "-Gram Denseness ",
                                  cast(real)(100*gstats.deepDensenessSum / gstats.densenessCount), " Percent")));
        }

        viz.pp("Scanned Bytes".asH!2,
               asUList(asItem("Scanned ", results.noBytesScanned),
                       asItem("Skipped ", results.noBytesSkipped),
                       asItem("Unreadable ", results.noBytesUnreadable),
                       asItem("Total Contents ", results.noBytesTotalContents),
                       asItem("Total ", results.noBytesTotal),
                       asItem("Total number of hits ", results.numTotalHits),
                       asItem("Number of Files with hits ", results.numFilesWithHits)));
    }
}

void scanner(string[] args)
{
    // Register the SIGINT signal with the signalHandler function call:
    version(linux)
    {
        signal(SIGABRT, &signalHandler);
        signal(SIGTERM, &signalHandler);
        signal(SIGQUIT, &signalHandler);
        signal(SIGINT, &signalHandler);
    }

    auto term = Terminal(ConsoleOutputType.linear);
    auto scanner = new Scanner!Terminal(args, term);
}
