#!/usr/bin/env rdmd-dev-module

/** Knowledge Graph Database.

    Reads data from SUMO, DBpedia, Freebase, Yago, BabelNet, ConceptNet, Nell,
    Wikidata, WikiTaxonomy, Wordnik into a Knowledge Graph.

    Applications:

    - Baby Naming: Enter words you like the baby to represent and then search
      over synonyms, translations, etc until you find the most releveant node of
      type nameMale or nameFemale. Also show "how" they are related (show network walk).
    - Translate text to use age-relevant words. Use pre-train child book word
      histogram for specific ages.
    - Find dubious words:
      - Swedish:
        - trumpétare - trúm-petare
        - tómtén - tómten
        - tunnelbánan - tunnel-banán
    - Emotion Detection

    People: Pat Winston, Jerry Sussman, Henry Liebermann (Knowledge base)

    Data Resources:
    - http://meta-guide.com/software-meta-guide/100-best-ai-nlp-resources-aiml/
    - https://www.wordnik.com/
    - Open Multilingual Wordnet: http://compling.hss.ntu.edu.sg/omw/
    - Svensk Etymologisk Ordbok: http://runeberg.org/svetym/
    - WordNets: http://globalwordnet.org/wordnets-in-the-world/
    - WordNet 3: http://eb.lv/dict/
    - http://www.clres.com/dict.html
    - http://www.adampease.org/OP/
    - http://www.wordfrequency.info/
    - http://conceptnet5.media.mit.edu/downloads/current/
    - http://wiki.dbpedia.org/DBpediaAsTables
    - http://icon.shef.ac.uk/Moby/
    - http://www.dcs.shef.ac.uk/research/ilash/Moby/moby.tar.Z
    - http://extensions.openoffice.org/en/search?f%5B0%5D=field_project_tags%3A157
    - http://www.mpi-inf.mpg.de/departments/databases-and-information-systems/research/yago-naga/yago/
    - http://www.words-to-use.com/
    - http://www.slangopedia.se/
    - http://www.learn-english-today.com/idioms/
    - http://www.smart-words.org/list-of-synonyms/
    - http://www.thefreedictionary.com/
    - http://www.paengelska.com/engelska_uttryck_a.htm
    - http://www.ego4u.com/en/cram-up/grammar/prepositions
    - http://www.woxikon.se/

    English Phrases: http://www.talkenglish.com
    Names: http://www.nordicnames.de/
    Names: http://www.behindthename.com/
    Names: http://www.ethnologue.com/browse/names
    Names: http://www.20000-names.com/
    Names: http://surnames.behindthename.com
    Names: http://www.urbandictionary.com/

    See also: http://stevehanov.ca/blog/index.php?id=8
    See also: http://www.mindmachineproject.org/proj/omcs/
    See also: https://github.com/commonsense/conceptnet5/wiki
    See also: https://en.wikipedia.org/wiki/Hypergraph
    See also: http://forum.dlang.org/thread/fysokgrgqhplczgmpfws@forum.dlang.org#post-fysokgrgqhplczgmpfws:40forum.dlang.org
    See also: http://www.eturner.net/omcsnetcpp/
    See also: http://wwww.abbreviations.com
    See also: www.oneacross.com/crosswords for inspiring applications
    See also: http://programmers.stackexchange.com/q/261163/38719
    See also: http://www.mindmachineproject.org/proj/prop/
*/

module knet.base;

import core.exception: UnicodeException;
import core.memory: GC; // GC.disable;

import std.traits: isSomeString, isFloatingPoint, EnumMembers, isDynamicArray, isIterable, Unqual;
import std.conv: to, emplace;
import std.stdio: writeln, File, write, writef;
import std.algorithm: findSplit, findSplitBefore, findSplitAfter, sort, multiSort, skipOver, filter, canFind, count, setUnion, setIntersection, min, max, joiner, strip, until, dropOne, dropBackOne;
import std.math: abs;
import std.container: Array;
import std.string: tr, toLower, toUpper, capitalize, representation;
import std.array: array, replace;
import std.uni: isWhite, toLower;
import std.utf: byDchar, UTFException;
import std.typecons: Nullable, Tuple, tuple;
import std.file: readText, exists, dirEntries, SpanMode;
import std.bitmanip: bitfields;
import mmfile_ex;
alias rdT = readText;

import std.range: front, split, isInputRange, back, chain;
import std.path: buildPath, buildNormalizedPath, expandTilde, extension, baseName;
import wordnet: WordNet;

import algorithm_ex: isPalindrome, either, append;
import ixes: commonSuffixCount;
import range_ex: stealFront, stealBack, ElementType, byPair, pairs;
import traits_ex: isSourceOf, isSourceOfSomeString, isIterableOf, enumMembers, packedBitSizeOf;
import sort_ex: sortBy, rsortBy, sorted;
import skip_ex: skipOverBack, skipOverShortestOf, skipOverBackShortestOf, skipOverPrefixes, skipOverSuffixes;
import predicates: allEqual;
import dbg;

import stemming;
import grammars;

import knet.separators;
import combinations;
import permutations;

import knet.languages;
import knet.origins;
import knet.thematics;
import knet.senses;
import knet.relations;
import knet.roles;
import knet.decodings;
import knet.lemmas;

import knet.cn5;
import knet.nell;
import knet.wordnet;
import knet.moby;
import knet.synlex;
import knet.folklex;
import knet.swesaurus;
import knet.lectures.all;

/* import stdx.allocator; */
/* import memory.allocators; */
/* import containers: HashMap; */

static if (__VERSION__ >= 2067)
{
    import std.algorithm: clamp;
}
else
{
    auto clamp(T, TLow, THigh)(T x, TLow lower, THigh upper)
    @safe pure nothrow
    in { assert(lower <= upper, `lower > upper`); }
    body
    {
        import std.algorithm: min, max;
        return min(max(x, lower), upper);
    }

    unittest {
        assert((-1).clamp(0, 2) == 0);
        assert(0.clamp(0, 2) == 0);
        assert(1.clamp(0, 2) == 1);
        assert(2.clamp(0, 2) == 2);
        assert(3.clamp(0, 2) == 2);
    }
}

void skipOverNELLNouns(R, A)(ref R s, in A agents)
{
    s.skipOverPrefixes(agents);
    s.skipOverSuffixes(agents);
}

/** Check if $(D s) contains more than one word. */
bool isMultiWord(S)(S s) if (isSomeString!S)
{
    return s.canFind(`_`, ` `) >= 1;
}

/// Normalized (Link) Weight.
alias NWeight = real;

/** Context or Ontology Category Index (currently from NELL). */
struct Ctx
{
    @safe @nogc pure nothrow:
    static Ctx asUndefined() { return Ctx(0); }
    bool defined() const { return this != Ctx.asUndefined; }
    /* auto opCast(T : bool)() { return defined; } */
private:
    ushort _ix = 0;
}

enum anyContext = Ctx.asUndefined; // reserve 0 for anyContext (unknown)

// TODO Use in Lemma.
enum MeaningVariant { unknown = 0, first = 1, second = 2, third = 3 }

enum useArray = false;
enum useRCString = false;

static if (useRCString)
{
    import rcstring;
}

struct Location
{
    double latitude;
    double longitude;
}

/** Word. */
static if (useRCString) { alias Word = RCXString!(immutable char, 16-1); }
else                    { alias Word = immutable string; }
static if (useRCString) { alias MutWord = RCXString!(char, 16-1); }
else                    { alias MutWord = string; }

/** Expression, two or more Words joined by space. */
static if (useRCString) { alias Expr = RCXString!(immutable char, 24-1); }
else                    { alias Expr = immutable string; }
static if (useRCString) { alias MutExpr = RCXString!(char, 24-1); }
else                    { alias MutExpr = string; }

/// Reference to Node.
alias Nd = Ref!Node;

/// Reference to Link.
alias Ln = Ref!Link;

alias Step = Tuple!(Ln, Nd); // steps from Node
alias Path = Step[]; // path of steps from Node

/// References to Nodes.
static if (useArray) { alias Nds = Array!Nd; }
else                 { alias Nds = Nd[]; }

/// References to Links.
static if (useArray) { alias Lns = Array!Ln; }
else                 { alias Lns = Ln[]; }

/** Node Concept Lemma. */
struct Lemma
{
    @safe // @nogc
    pure // nothrow
    :

    this(S)(S expr,
            Lang lang,
            Sense sense,
            Ctx context = Ctx.asUndefined,
            Manner manner = Manner.formal,
            bool isRegexp = false,
            ubyte meaningNr = 0,
            bool normalizeExpr = true,
            bool hasUniqueSense = false) if (isSomeString!S) in { assert(meaningNr <= MeaningNrMax); }
    body
    {
        // check if regular expression
        if (normalizeExpr)
        {
            this.isRegexp = expr.skipOver(`regex:`) ? true : isRegexp;
        }

        if (normalizeExpr &&
            expr.length >= 2 &&
            expr[$ - 2] == meaningNrSeparator)
        {
            const ubyte nrCharByte = expr.representation.back;
            assert(nrCharByte >= '0' &&
                   nrCharByte <= '9');
            this.meaningNr = cast(ubyte)(nrCharByte - '0');
            expr = expr[0 .. $ - 2]; // skip meaning number suffix
            assert(meaningNr == 0,
                   `Can't override already decoded meaning number`
                   /* ~ this.meaningNr.to!string */);
        }
        else
        {
            this.meaningNr = meaningNr;
        }

        this.lang = lang;
        this.sense = sense;
        this.manner = manner;
        this.context = context;
        this.hasUniqueSense = hasUniqueSense;

        if (normalizeExpr)
        {
            auto split = expr.findSplit(meaningNrSeparatorString);
            if (!split[1].empty) // if a split was found
            {
                try
                {
                    const exprSense = split[0].to!Sense;
                    expr = split[2];
                    if (sense == Sense.unknown ||
                        exprSense.specializes(sense))
                    {
                        sense = exprSense;
                    }
                    else if (sense != exprSense &&
                             !sense.specializes(exprSense))
                    {
                        debug writeln(`warning: Can't override `, expr, `'s parameterized sense `, sense,
                                ` with `, exprSense);
                    }
                }
                catch (std.conv.ConvException e)
                {
                    /* ok to not be able to downcase */
                }
            }
        }

        this.expr = expr.to!(typeof(this.expr)); // do this at the end to minimize size of allocated string
    }

    MutExpr expr;
    /* The following three are used to disambiguate different semantics
     * meanings of the same word in different languages. */

    // TODO bitfields
    Lang lang = Lang.unknown;
    Sense sense = Sense.unknown;
    Ctx context = Ctx.asUndefined; // TODO bitfield
    bool hasUniqueSense = false; // Expr has unique Sense in Lang

    enum bitsizeOfManner = packedBitSizeOf!Manner;
    enum bitsizeOfMeaningNr = 8 - bitsizeOfManner - 1;
    enum MeaningNrMax = 2^^bitsizeOfMeaningNr - 1;

    mixin(bitfields!(Manner, `manner`, bitsizeOfManner,
                     ubyte, `meaningNr`, bitsizeOfMeaningNr,
                     bool, `isRegexp`, 1 // true if $(D expr) is a regular expression
              ));
}

/** Concept Node/Vertex. */
struct Node
{
    /* @safe @nogc pure nothrow: */
    this(in Lemma lemma,
         Origin origin = Origin.unknown,
         Lns links = Lns.init)
    {
        this.lemma = lemma;
        this.origin = origin;
        this.links = links;
    }
    Lns links;
    Lemma lemma;
    Origin origin;
}

alias PWeight = ubyte; // link weight pack type

/** Many-Nodes-to-Many-Nodes Link (Edge).
 */
struct Link
{
    alias WeightHistogram = size_t[PWeight];

    /* @safe @nogc pure nothrow: */

    this(Nd src,
         Role role,
         Nd dst,
         Origin origin = Origin.unknown) in { assert(src.defined && dst.defined); }
    body
    {
        // http://forum.dlang.org/thread/mevnosveagdiswkxtbrv@forum.dlang.org#post-zhndpadqtfareymbnfis:40forum.dlang.org
        // this.actors.append(src.backward,
        //                    dst.forward);
        this.actors.reserve(this.actors.length + 2);
        this.actors ~= src.backward;
        this.actors ~= dst.forward;

        this.role = role;
        this.origin = origin;
    }

    this(Origin origin = Origin.unknown)
    {
        this.origin = origin;
    }

    /** Set ConceptNet5 PWeight $(weight). */
    void setCN5Weight(T)(T weight) if (isFloatingPoint!T)
    {
        // pack from 0..about10 to PWeight to save memory
        pweight = cast(PWeight)(weight.clamp(0,10)/10*PWeight.max);
    }

    /** Set NELL Probability PWeight $(weight). */
    void setNELLWeight(T)(T weight) if (isFloatingPoint!T)
    {
        // pack from 0..1 to PWeight to save memory
        pweight = cast(PWeight)(weight.clamp(0, 1)*PWeight.max);
    }

    /** Set Manual Probability PWeight $(weight). */
    void setManualWeight(T)(T weight) if (isFloatingPoint!T)
    {
        // pack from 0..1 to PWeight to save memory
        pweight = cast(PWeight)(weight.clamp(0, 1)*PWeight.max);
    }

    /** Get Normalized Link PWeight. */
    @property NWeight nweight() const
    {
        return ((cast(typeof(return))pweight)/
                (cast(typeof(return))PWeight.max));
    }

    Nds actors;
    PWeight pweight;
    Role role;
    Origin origin;
}

/** Binary Relation Link.
 */
struct Link2
{
    Nd first;
    Nd second;
    PWeight pweight;
    Role role;
    Origin origin;
}

/** Ternary Relation Link.
 */
struct Link3
{
    Nd first;
    Nd second;
    Nd third;
    PWeight pweight;
    Role role;
    Origin origin;
}

/** Quarnary Relation Link.
 */
struct Link4
{
    Nd first;
    Nd second;
    Nd third;
    Nd fourth;
    PWeight pweight;
    Role role;
    Origin origin;
}

/* static if (useArray) { alias Nodes = Array!Node; } */
/* else                 { alias Nodes = Node[]; } */
alias Nodes = Node[]; // no need to use std.container.Array here

static if (false) { alias Lemmas = Array!Lemma; }
else              { alias Lemmas = Lemma[]; }

static if (useArray) { alias Links = Array!Link; }
else                 { alias Links = Link[]; }

static if (false)
{
    pragma(msg, `Expr.sizeof: `, Expr.sizeof);
    pragma(msg, `Role.sizeof: `, Role.sizeof);
    pragma(msg, `Lemma.sizeof: `, Lemma.sizeof);
    pragma(msg, `Node.sizeof: `, Node.sizeof);
    pragma(msg, `Lns.sizeof: `, Lns.sizeof);
    pragma(msg, `Nds.sizeof: `, Nds.sizeof);
    pragma(msg, `Link2.sizeof: `, Link2.sizeof);
    pragma(msg, `Link3.sizeof: `, Link3.sizeof);
    pragma(msg, `Link4.sizeof: `, Link4.sizeof);
    pragma(msg, `Link.sizeof: `, Link.sizeof);
}

struct Db
{
    // Data
    Nodes allNodes;
    Links allLinks;
    // TODO Nds[Lang.max + 1] ndsByLang;

    // Indexes
    Location[Nd] locations;
    Nd[Lemma] ndByLemma;
    Lemmas[Word] lemmasByWord; // Lemmas index by word of expression has more than one word
    Lemmas[Expr] lemmasByExpr; // Two or More Words
    Lemmas[ubyte] lemmasBySyllableCount; // TODO

    string[Ctx] contextNameByCtx; /** Ontology Context Names by Index. */
    Ctx[string] ctxByName; /** Ontology Context Indexes by Name. */
}

struct Stat
{
    ushort ctxCounter = Ctx.asUndefined._ix + 1; // 1 because 0 is reserved for anyContext (unknown)

    size_t multiWordNodeLemmaCount = 0; // number of nodes that whose lemma contain several expr

    size_t symmetricRelCount = 0; /// Symmetric Relation Count.
    size_t transitiveRelCount = 0; /// Transitive Relation Count.

    size_t[Rel.max + 1] relCounts; /// Link Counts by Relation Type.
    size_t[Origin.max + 1] linkSourceCounts;
    size_t[Lang.max + 1] nodeCountByLang;
    size_t[Sense.max + 1] nodeCountBySense; /// Node Counts by Sense Type.
    size_t nodeStringLengthSum = 0;

    // Connectedness
    size_t nodeConnectednessSum = 0;
    size_t linkConnectednessSum = 0;

    size_t exprWordCountSum = 0;

    // TODO Group to WeightsStatistics
    NWeight weightMinCN5 = NWeight.max;
    NWeight weightMaxCN5 = NWeight.min_normal;
    NWeight weightSumCN5 = 0; // Sum of all link weights.
    Link.WeightHistogram pweightHistogramCN5; // CN5 Packed Weight Histogram

    // TODO Group to WeightsStatistics
    NWeight weightMinNELL = NWeight.max;
    NWeight weightMaxNELL = NWeight.min_normal;
    NWeight weightSumNELL = 0; // Sum of all link weights.
    Link.WeightHistogram pweightHistogramNELL; // NELL Packed Weight Histogram
}

/** Main Knowledge Network Graph.
*/
class Graph
{
    /** Get Links Refs of $(D node) with direction $(D dir).
        TODO what to do with role.reversion here?
     */
    auto lnsOf(Node node,
               RelDir dir = RelDir.any,
               Role role = Role.init)
    {
        return node.links[]
                   .filter!(ln => (dir.of(RelDir.any, ln.dir) &&  // TODO functionize to match(RelDir, RelDir)
                                   at(ln).role.negation == role.negation &&
                                   (at(ln).role.rel == role.rel ||
                                    at(ln).role.rel.specializes(role.rel))));
    }

    auto linksOf(Node node,
                 RelDir dir = RelDir.any,
                 Role role = Role.init)
    {
        return lnsOf(node, dir, role).map!(ln => at(ln));
    }

    auto linksOf(Nd nd,
                 RelDir dir = RelDir.any,
                 Role role = Role.init)
    {
        return linksOf(at(nd), dir, role);
    }

    /** Network Walker (Input Range).
        TODO: Returns Path
     */
    class Walk
    {
        this(Nd first_)
        {
            first = first_;
            current = first;
        }

        auto front()
        {
            return lnsOf(at(current));
        }

        void popFront()
        {
        }

        bool empty() const { return true; }

        Nd first;
        Nd current;
        NWeight[Nd] dists;
    }

    Walk walk(in Node start)
    {
        typeof(return) walk;
        return walk;
    }
    alias traverse = walk;

    auto ins (in Link link)
    {
        return link.actors[].filter!(nd => nd.dir() == RelDir.backward).map!(nd => nd.raw);
    }
    auto outs(in Link link)
    {
        return link.actors[].filter!(nd => nd.dir() == RelDir.forward).map!(ln => ln.raw);
    }

    Db db;
    Stat stat;
    WordNet!(true) wordnet;


    @safe pure nothrow @nogc
    {
        ref inout(Node) at(const Nd nd) inout { return db.allNodes[nd.ix]; }
        ref inout(Link) at(const Ln ln) inout { return db.allLinks[ln.ix]; }

        ref inout(Node) opIndex(const Nd nd) inout { return at(nd); }
        ref inout(Link) opIndex(const Ln ln) inout { return at(ln); }

        ref inout(Node) opUnary(string s)(const Nd nd) inout if (s == `*`) { return at(nd); }
        ref inout(Link) opUnary(string s)(const Ln ln) inout if (s == `*`) { return at(ln); }
    }

    Nd nodeRefByLemmaMaybe(in Lemma lemma)
    {
        return get(db.ndByLemma, lemma, typeof(return).init);
    }

    /** Try to Get Single Node related to $(D word) in the interpretation
        (semantic context) $(D sense).
    */
    Nds ndsByLemmaDirect(S)(S expr,
                            Lang lang,
                            Sense sense,
                            Ctx context) if (isSomeString!S)
    {
        typeof(return) nodes;
        const lemma = Lemma(expr, lang, sense, context);
        if (const lemmaNd = lemma in db.ndByLemma)
        {
            nodes ~= *lemmaNd; // use it
        }
        else
        {
            // try to lookup parts of word
            auto wordsSplit = wordnet.findWordsSplit(expr, [lang]); // split in parts
            if (wordsSplit.length >= 2)
            {
                if (const lemmaFixedNd = Lemma(wordsSplit.joiner(`_`).to!S,
                                               lang, sense, context) in db.ndByLemma)
                {
                    nodes ~= *lemmaFixedNd;
                }
            }
        }
        return nodes;
    }

    /** Get All Node Indexes Indexed by a Lemma having expr $(D expr). */
    auto ndsOf(S)(S expr) if (isSomeString!S)
    {
        return lemmasOfExpr(expr).map!(lemma => db.ndByLemma[lemma]);
    }

    /** Get All Possible Nodes related to $(D word) in the interpretation
        (semantic context) $(D sense).
        If no sense given return all possible.
    */
    Nds ndsOf(S)(S expr,
                 Lang lang,
                 Sense sense = Sense.unknown,
                 Ctx context = anyContext) if (isSomeString!S)
    {
        typeof(return) nodes;

        if (lang != Lang.unknown &&
            sense != Sense.unknown &&
            context != anyContext) // if exact Lemma key can be used
        {
            return ndsByLemmaDirect(expr, lang, sense, context); // fast hash lookup
        }
        else
        {
            auto tmp = ndsOf(expr).filter!(a => (lang == Lang.unknown ||
                                                 at(a).lemma.lang == lang))
                                  .array;
            static if (useArray)
            {
                nodes = Nds(tmp); // TODO avoid allocations
            }
            else
            {
                nodes = tmp;
            }
        }

        if (nodes.empty)
        {
            /* writeln(`Lookup translation of individual expr; bil_tvätt => car-wash`); */
            /* foreach (word; expr.splitter(`_`)) */
            /* { */
            /*     writeln(`Translate word "`, word, `" from `, lang, ` to English`); */
            /* } */
        }
        return nodes;
    }

    alias meaningsOf = ndsOf;
    alias interpretationsOf = ndsOf;

    /** Get All Possible Lemmas related to Expression (set of words) $(D expr).
     */
    Lemmas lemmasOfExpr(S)(S expr) if (isSomeString!S)
    {
        static if (is(S == string)) // TODO Is there a prettier way to do this?
        {
            return db.lemmasByExpr.get(expr, typeof(return).init);
        }
        else
        {
            return db.lemmasByExpr.get(expr.dup, typeof(return).init); // TODO Why is dup needed here?
        }
    }

    /** Get All Possible Lemmas related to Word $(D word).
     */
    Lemmas lemmasOfWord(S)(S word) if (isSomeString!S)
    {
        static if (is(S == string)) // TODO Is there a prettier way to do this?
        {
            return db.lemmasByWord.get(word, typeof(return).init);
        }
        else
        {
            return db.lemmasByWord.get(word.dup, typeof(return).init); // TODO Why is dup needed here?
        }
    }

    /** Try Lookup Already Interned $(D expr.
     */
    auto tryReuseExpr(S)(S expr) @safe
    {
        if (auto lemmas = expr in db.lemmasByExpr)
        {
            return (*lemmas).front.expr;
        }
        return expr;
    }

    /** Internalize $(D Lemma) of $(D expr).
        Returns: either existing specialized lemma or a reference to the newly stored one.
     */
    ref Lemma internLemma(ref Lemma lemma,
                          bool hasUniqueSense = false) @safe // See also: http://wiki.dlang.org/DIP25 for doc on `return ref`
    {
        if (auto lemmas = lemma.expr in db.lemmasByExpr)
        {
            // reuse senses that specialize lemma.sense and modify lemma.sense to it
            foreach (ref existingLemma; *lemmas)
            {
                if (existingLemma.lang == lemma.lang &&
                    existingLemma.context == lemma.context &&
                    existingLemma.manner == lemma.manner &&
                    existingLemma.meaningNr == lemma.meaningNr &&
                    existingLemma.isRegexp == lemma.isRegexp &&
                    existingLemma.sense.specializes(lemma.sense))
                {
                    // dln(`Specializing sense of Lemma "`, lemma.expr, `"`,
                    //     ` from "`, lemma.sense, `"`
                    //     ` to "`, existingLemma.sense, `"`);
                    // lemma.sense = existingLemma.sense;
                    return existingLemma;
                }
            }
            const hitAlt = (*lemmas).canFind(lemma); // TODO is this really correct?
            if (!hitAlt) // TODO Make use of binary search
            {
                *lemmas ~= lemma;
            }
        }
        else
        {
            static if (!isDynamicArray!Lemmas)
            {
                db.lemmasByExpr[lemma.expr] = Lemmas.init; // TODO fix std.container.Array
            }
            db.lemmasByExpr[lemma.expr] ~= lemma;
        }
        return lemma;
    }

    this()
    {
    }

    /** Construct Network
        Read sources in order of decreasing reliability.
    */
    void initialize(string cachePath)
    {
        this.learnMobyEnglishPronounciations();
        return;
        learnDefault();
        showRelations;
    }

    void learnDefault()
    {
        const quick = true;
        const maxCount = quick ? 50000 : size_t.max; // 50000 doesn't crash CN5

        // Learn Absolute (Trusthful) Things before untrusted machine generated data is read
        learnPreciseThings();

        learnTrainedThings();

        // Learn Less Absolute Things
        learnAssociativeThings();

        // CN5 and NELL
        readCN5(this, `~/Knowledge/conceptnet5-5.3/data/assertions/`, maxCount);
        //readNELLFile(this, `~/Knowledge/nell/NELL.08m.895.esv.csv`, maxCount);

        // TODO msgpack fails to pack
        /* auto bytes = this.pack; */
        /* writefln(`Packed size: %.2f`, bytes.length/1.0e6); */
    }

    /// Learn Externally (Trained) Supervised Things.
    void learnTrainedThings()
    {
        // wordnet = new WordNet!(true, true)([Lang.en]); // TODO Remove
        readWordNet(this, `~/Knowledge/wordnet/dict-3.1`);
        readSwesaurus(this);
    }

    /** Learn Precise (Absolute) Thing.
     */
    void learnPreciseThings()
    {
        learnEnumMemberNameHierarchy!Sense(Sense.nounSingular);

        // TODO replace with automatics
        learnMto1(Lang.en, rdT(`../knowledge/en/uncountable_noun.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `uncountable`, Sense.nounUncountable, Sense.noun, 1.0);
        learnMto1(Lang.sv, rdT(`../knowledge/sv/uncountable_noun.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `uncountable`, Sense.nounUncountable, Sense.noun, 1.0);

        // Part of Speech (PoS)
        learnPartOfSpeech();

        learnPunctuation();

        learnEnglishComputerKnowledge();

        learnMath();
        learnPhysics();
        learnComputers();

        learnEnglishOther();

        learnVerbReversions();
        learnEtymologicallyDerivedFroms();

        learnSwedishGrammar();

        learnNames();

        learnMto1(Lang.en, rdT(`../knowledge/en/people.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `people`, Sense.noun, Sense.nounUncountable, 1.0);

        // TODO functionize to learnGroup
        learnMto1(Lang.en, rdT(`../knowledge/en/compound_word.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `compound word`, Sense.unknown, Sense.nounSingular, 1.0);

        // Other

        // See also: https://en.wikipedia.org/wiki/Dolch_word_list
        learnMto1(Lang.en, rdT(`../knowledge/en/dolch_singular_noun.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `dolch word`, Sense.nounSingular, Sense.nounSingular, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/dolch_preprimer.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `dolch pre-primer word`, Sense.unknown, Sense.nounSingular, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/dolch_primer.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `dolch primer word`, Sense.unknown, Sense.nounSingular, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/dolch_1st_grade.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `dolch 1-st grade word`, Sense.unknown, Sense.nounSingular, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/dolch_2nd_grade.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `dolch 2-nd grade word`, Sense.unknown, Sense.nounSingular, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/dolch_3rd_grade.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `dolch 3-rd grade word`, Sense.unknown, Sense.nounSingular, 1.0);

        learnMto1(Lang.en, rdT(`../knowledge/en/personal_quality.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `personal quality`, Sense.adjective, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/color.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `color`, Sense.unknown, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/shapes.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `shape`, Sense.noun, Sense.noun, 1.0);

        learnMto1(Lang.en, rdT(`../knowledge/en/fruits.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `fruit`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/plants.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `plant`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/trees.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `tree`, Sense.noun, Sense.plant, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/spice.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `spice`, Sense.spice, Sense.food, 1.0);

        learnMto1(Lang.en, rdT(`../knowledge/en/shoes.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `shoe`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/dances.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `dance`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/landforms.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `landform`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/desserts.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `dessert`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/countries.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `country`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/us_states.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `us_state`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/furniture.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `furniture`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/good_luck_symbols.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `good luck symbol`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/leaders.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `leader`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/measurements.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `measurement`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/quantity.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `quantity`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/language.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `language`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/insect.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `insect`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/musical_instrument.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `musical instrument`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/weapon.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `weapon`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/hats.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `hat`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/rooms.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `room`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/containers.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `container`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/virtues.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `virtue`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/vegetables.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `vegetable`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/flower.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `flower`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/reptile.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `reptile`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/famous_pair.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `pair`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/season.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `season`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/holiday.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `holiday`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/birthday.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `birthday`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/biomes.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `biome`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/dogs.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `dog`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/rodent.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `rodent`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/fish.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `fish`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/birds.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `bird`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/amphibians.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `amphibian`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/animals.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `animal`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/mammals.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `mammal`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/food.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `food`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/cars.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `car`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/building.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `building`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/housing.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `housing`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/occupation.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `occupation`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/cooking_tool.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `cooking tool`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/tool.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `tool`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/carparts.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.partOf), `car`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/bodyparts.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.partOf), `body`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/alliterations.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `alliteration`, Sense.unknown, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/positives.txt`).splitter('\n').filter!(word => !word.empty), Role(Rel.hasAttribute), `positive`, Sense.unknown, Sense.adjective, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/mineral.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `mineral`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/metal.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `metal`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/mineral_group.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `mineral group`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/major_mineral_group.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `major mineral group`, Sense.noun, Sense.noun, 1.0);

        // Swedish
        learnMto1(Lang.sv, rdT(`../knowledge/sv/house.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `hus`, Sense.noun, Sense.noun, 1.0);

        learnChemicalElements();

        foreach (dirEntry; dirEntries("../knowledge/", SpanMode.shallow))
        {
            const langString = dirEntry.name.baseName;
            try
            {
                const lang = langString.to!Lang;
                const dirPath = `../knowledge/` ~ langString; // TODO reuse dirEntry

                // Male Name
                learnMtoNMaybe(buildPath(dirPath, `male_name.txt`), // TODO isA male name
                               Sense.nameMale, lang,
                               Role(Rel.hasMeaning),
                               Sense.unknown, lang,
                               Origin.manual, 1.0);

                // Female Name
                learnMtoNMaybe(buildPath(dirPath, `female_name.txt`), // TODO isA female name
                               Sense.nameFemale, lang,
                               Role(Rel.hasMeaning),
                               Sense.unknown, lang,
                               Origin.manual, 1.0);

                // Irregular Noun
                learnMtoNMaybe(buildPath(dirPath, `irregular_noun.txt`),
                               Sense.nounSingular, lang,
                               Role(Rel.formOfNoun),
                               Sense.nounPlural, lang,
                               Origin.manual, 1.0);

                // Abbrevation
                learnMtoNMaybe(buildPath(dirPath, `abbrevation.txt`),
                               Sense.unknown, lang,
                               Role(Rel.abbreviationFor),
                               Sense.unknown, lang,
                               Origin.manual, 1.0);
                learnMtoNMaybe(buildPath(dirPath, `noun_abbrevation.txt`),
                               Sense.noun, lang,
                               Role(Rel.abbreviationFor),
                               Sense.noun, lang,
                               Origin.manual, 1.0);

                // Synonym
                learnMtoNMaybe(buildPath(dirPath, `synonym.txt`),
                               Sense.unknown, lang, Role(Rel.synonymFor),
                               Sense.unknown, lang, Origin.manual, 1.0);
                learnMtoNMaybe(buildPath(dirPath, `obsolescent_synonym.txt`),
                               Sense.unknown, lang, Role(Rel.obsolescentFor),
                               Sense.unknown, lang, Origin.manual, 1.0);
                learnMtoNMaybe(buildPath(dirPath, `noun_synonym.txt`),
                               Sense.noun, lang, Role(Rel.synonymFor),
                               Sense.noun, lang, Origin.manual, 0.5);
                learnMtoNMaybe(buildPath(dirPath, `adjective_synonym.txt`),
                               Sense.adjective, lang, Role(Rel.synonymFor),
                               Sense.adjective, lang, Origin.manual, 1.0);

                // Homophone
                learnMtoNMaybe(buildPath(dirPath, `homophone.txt`),
                               Sense.unknown, lang, Role(Rel.homophoneFor),
                               Sense.unknown, lang, Origin.manual, 1.0);

                // Abbrevation
                learnMtoNMaybe(buildPath(dirPath, `cardinal_direction_abbrevation.txt`),
                               Sense.unknown, lang, Role(Rel.abbreviationFor),
                               Sense.unknown, lang, Origin.manual, 1.0);
                learnMtoNMaybe(buildPath(dirPath, `language_abbrevation.txt`),
                               Sense.language, lang, Role(Rel.abbreviationFor),
                               Sense.language, lang, Origin.manual, 1.0);

                // Noun
                learnMto1Maybe(lang, buildPath(dirPath, `concrete_noun.txt`),
                               Role(Rel.hasAttribute), `concrete`,
                               Sense.nounConcrete, Sense.adjective, 1.0);
                learnMto1Maybe(lang, buildPath(dirPath, `abstract_noun.txt`),
                               Role(Rel.hasAttribute), `abstract`,
                               Sense.nounAbstract, Sense.adjective, 1.0);
                learnMto1Maybe(lang, buildPath(dirPath, `masculine_noun.txt`),
                               Role(Rel.hasAttribute), `masculine`,
                               Sense.noun, Sense.adjective, 1.0);
                learnMto1Maybe(lang, buildPath(dirPath, `feminine_noun.txt`),
                               Role(Rel.hasAttribute), `feminine`,
                               Sense.noun, Sense.adjective, 1.0);

                // Acronym
                learnMtoNMaybe(buildPath(dirPath, `acronym.txt`),
                               Sense.nounAcronym, lang, Role(Rel.acronymFor),
                               Sense.unknown, lang, Origin.manual, 1.0);
                learnMtoNMaybe(buildPath(dirPath, `newspaper_acronym.txt`),
                               Sense.newspaper, lang,
                               Role(Rel.acronymFor),
                               Sense.newspaper, lang,
                               Origin.manual, 1.0);

                // Idioms
                learnMtoNMaybe(buildPath(dirPath, `idiom_meaning.txt`),
                               Sense.idiom, lang,
                               Role(Rel.idiomFor),
                               Sense.unknown, lang,
                               Origin.manual, 0.7);

                // Slang
                learnMtoNMaybe(buildPath(dirPath, `slang_meaning.txt`),
                               Sense.unknown, lang,
                               Role(Rel.slangFor),
                               Sense.unknown, lang,
                               Origin.manual, 0.7);

                // Slang Adjectives
                learnMtoNMaybe(buildPath(dirPath, `slang_adjective_meaning.txt`),
                               Sense.adjective, lang,
                               Role(Rel.slangFor),
                               Sense.unknown, lang,
                               Origin.manual, 0.7);

                // Name
                learnMtoNMaybe(buildPath(dirPath, `male_name_meaning.txt`),
                               Sense.nameMale, lang,
                               Role(Rel.hasMeaning),
                               Sense.unknown, lang,
                               Origin.manual, 0.7);
                learnMtoNMaybe(buildPath(dirPath, `female_name_meaning.txt`),
                               Sense.nameFemale, lang,
                               Role(Rel.hasMeaning),
                               Sense.unknown, lang,
                               Origin.manual, 0.7);
                learnMtoNMaybe(buildPath(dirPath, `name_day.txt`),
                               Sense.name, lang,
                               Role(Rel.hasNameDay),
                               Sense.nounDate, Lang.en,
                               Origin.manual, 1.0);
                learnMtoNMaybe(buildPath(dirPath, `surname_languages.txt`),
                               Sense.surname, Lang.unknown,
                               Role(Rel.hasOrigin),
                               Sense.language, Lang.en,
                               Origin.manual, 1.0);

                // City
                try
                {
                    foreach (entry; rdT(buildPath(dirPath, `city.txt`)).splitter('\n').filter!(w => !w.empty))
                    {
                        const items = entry.split(roleSeparator);
                        const cityName = items[0];
                        const population = items[1];
                        const yearFounded = items[2];
                        const city = store(cityName, lang, Sense.city, Origin.manual);
                        connect(city, Role(Rel.hasAttribute),
                                store(population, lang, Sense.population, Origin.manual), Origin.manual, 1.0);
                        connect(city, Role(Rel.foundedIn),
                                store(yearFounded, lang, Sense.year, Origin.manual), Origin.manual, 1.0);
                    }
                }
                catch (std.file.FileException e) {}

                try { learnMto1(lang, rdT(buildPath(dirPath, `vehicle.txt`)).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `vehicle`, Sense.noun, Sense.noun, 1.0); }
                catch (std.file.FileException e) {}

                try { learnMto1(lang, rdT(buildPath(dirPath, `lowercase_letter.txt`)).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `lowercase letter`, Sense.letterLowercase, Sense.noun, 1.0); }
                catch (std.file.FileException e) {}

                try { learnMto1(lang, rdT(buildPath(dirPath, `uppercase_letter.txt`)).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `uppercase letter`, Sense.letterUppercase, Sense.noun, 1.0); }
                catch (std.file.FileException e) {}

                try { learnMto1(lang, rdT(buildPath(dirPath, `old_proverb.txt`)).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `old proverb`, Sense.unknown, Sense.noun, 1.0); }
                catch (std.file.FileException e) {}

                try { learnMto1(lang, rdT(buildPath(dirPath, `contronym.txt`)).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `contronym`, Sense.unknown, Sense.noun, 1.0); }
                catch (std.file.FileException e) {}

                try { learnOpposites(lang); }
                catch (std.exception.ErrnoException e) {}
            }
            catch (std.conv.ConvException e)
            {
                // handle knowledge/X-Y/*.txt such as knowledge/en-sv/*.txt
                const split = dirEntry.name.baseName.findSplit(`-`);
                if (!split[1].empty) // if subdirectory of knowledge container space
                {
                    // try decoding them as iso language codes
                    const srcLang = split[0].to!Lang;
                    const dstLang = split[2].to!Lang;
                    foreach (txtFile; dirEntries(dirEntry.name, SpanMode.shallow))
                    {
                        Sense sense = Sense.unknown;
                        Rel rel;
                        switch (txtFile.name.baseName)
                        {
                            case "translation.txt":              sense = Sense.unknown;      rel = Rel.translationOf; break;
                            case "noun_translation.txt":         sense = Sense.noun;         rel = Rel.translationOf; break;
                            case "phrase_translation.txt":       sense = Sense.phrase;       rel = Rel.translationOf; break;
                            case "idiom_translation.txt":        sense = Sense.idiom;        rel = Rel.translationOf; break;
                            case "interjection_translation.txt": sense = Sense.interjection; rel = Rel.translationOf; break;
                            default:
                                writeln("Don't know how to decode sense and rel of ", txtFile.name);
                                sense = Sense.unknown;
                                break;
                        }

                        learnMtoNMaybe(txtFile.name,
                                       sense, srcLang, Role(rel),
                                       sense, dstLang,
                                       Origin.manual, 1.0);
                    }
                }
                else
                {
                    writeln("TODO Process ", dirEntry.name);
                }
            }
        }

        learnEmotions();
        learnEnglishFeelings();
        learnSwedishFeelings();

        learnEnglishWordUsageRanks();
    }

    void learnEnglishWordUsageRanks()
    {
        const path = `../knowledge/en/word_usage_rank.txt`;
        foreach (line; File(path).byLine)
        {
            auto split = line.splitter(roleSeparator);
            const rank = split.front.idup; split.popFront;
            const word = split.front;
            connect(store(word, Lang.en, Sense.unknown, Origin.manual), Role(Rel.hasAttribute),
                    store(rank, Lang.en, Sense.rank, Origin.manual), Origin.manual, 1.0);
        }
    }

    void learnPartOfSpeech()
    {
        this.learnPronouns();
        this.learnAdjectives();
        this.learnAdverbs();
        this.learnUndefiniteArticles();
        this.learnDefiniteArticles();
        this.learnPartitiveArticles();
        this.learnConjunctions();
        this.learnInterjections();
        this.learnTime();

        // Verb
        this.learnMto1(Lang.en, rdT(`../knowledge/en/regular_verb.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `regular verb`, Sense.verbRegular, Sense.noun, 1.0);

        this.learnMto1(Lang.en, rdT(`../knowledge/en/determiner.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `determiner`, Sense.determiner, Sense.noun, 1.0);
        this.learnMto1(Lang.en, rdT(`../knowledge/en/predeterminer.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `predeterminer`, Sense.predeterminer, Sense.noun, 1.0);
        this.learnMto1(Lang.en, rdT(`../knowledge/en/adverbs.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `adverb`, Sense.adverb, Sense.noun, 1.0);
        this.learnMto1(Lang.en, rdT(`../knowledge/en/preposition.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `preposition`, Sense.preposition, Sense.noun, 1.0);

        this.learnMto1(Lang.en, [`since`, `ago`, `before`, `past`], Role(Rel.instanceOf), `time preposition`, Sense.prepositionTime, Sense.noun, 1.0);

        this.learnMobyPoS();

        // learn these after Moby as Moby is more specific
        this.learnNouns();
        this.learnVerbs();

        this.learnMto1(Lang.en, rdT(`../knowledge/en/figure_of_speech.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `figure of speech`, Sense.unknown, Sense.noun, 1.0);

        this.learnMobyEnglishPronounciations();
    }

    void learnEnumMemberNameHierarchy(T)(Sense memberSense = Sense.unknown) if (is(T == enum))
    {
        const origin = Origin.manual;
        foreach (i; enumMembers!T)
        {
            foreach (j; enumMembers!T)
            {
                if (i != T.unknown &&
                    j != T.unknown &&
                    i != j)
                {
                    if (i.specializes(j))
                    {
                        connect(store(i.toHuman, Lang.en, memberSense, origin), Role(Rel.isA),
                                store(j.toHuman, Lang.en, memberSense, origin), origin, 1.0);
                    }
                }
            }
        }
    }

    void learnNouns()
    {
        writeln(`Reading Nouns ...`);

        const origin = Origin.manual;

        connect(store(`male`, Lang.en, Sense.noun, origin), Role(Rel.hasAttribute),
                store(`masculine`, Lang.en, Sense.adjective, origin), origin, 1.0);
        connect(store(`female`, Lang.en, Sense.noun, origin), Role(Rel.hasAttribute),
                store(`feminine`, Lang.en, Sense.adjective, origin), origin, 1.0);

        learnEnglishNouns();
        learnSwedishNouns();
    }

    void learnEnglishNouns()
    {
        writeln(`Reading English Nouns ...`);
        learnMto1(Lang.en, rdT(`../knowledge/en/collective_noun.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `collective noun`, Sense.nounCollective, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT(`../knowledge/en/noun.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `noun`, Sense.noun, Sense.noun, 1.0);
    }

    void learnSwedishNouns()
    {
        writeln(`Reading Swedish Nouns ...`);
        learnMto1(Lang.sv, rdT(`../knowledge/sv/collective_noun.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `collective noun`, Sense.nounCollective, Sense.noun, 1.0);
    }

    void learnPronouns()
    {
        writeln(`Reading Pronouns ...`);
        learnEnglishPronouns();
        learnSwedishPronouns();
    }

    void learnEnglishPronouns()
    {
        enum lang = Lang.en;

        // Singular
        learnMto1(lang, [`I`, `me`], Role(Rel.instanceOf), `singular personal pronoun`, Sense.pronounPersonalSingular1st, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`you`], Role(Rel.instanceOf), `singular personal pronoun`, Sense.pronounPersonalSingular2nd, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`it`], Role(Rel.instanceOf), `singular personal pronoun`, Sense.pronounPersonalSingular, Sense.nounPhrase, 1.0);

        learnMto1(lang, [`he`], Role(Rel.instanceOf), `1st-person male singular personal pronoun`, Sense.pronounPersonalSingularMale1st, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`him`], Role(Rel.instanceOf), `2nd-person male singular personal pronoun`, Sense.pronounPersonalSingularMale2nd, Sense.nounPhrase, 1.0);

        learnMto1(lang, [`she`], Role(Rel.instanceOf), `1st-person female singular personal pronoun`, Sense.pronounPersonalSingularFemale1st, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`her`], Role(Rel.instanceOf), `2nd-person female singular personal pronoun`, Sense.pronounPersonalSingularFemale2nd, Sense.nounPhrase, 1.0);

        learnMto1(lang, [`we`, `us`], Role(Rel.instanceOf), `1st-person plural personal pronoun`, Sense.pronounPersonalPlural1st, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`you`], Role(Rel.instanceOf), `2nd-person plural personal pronoun`, Sense.pronounPersonalPlural2nd, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`they`, `they`], Role(Rel.instanceOf), `3rd-person plural personal pronoun`, Sense.pronounPersonalPlural3rd, Sense.nounPhrase, 1.0);

        learnMto1(lang, [`this`, `that`], Role(Rel.instanceOf), `singular demonstrative pronoun`, Sense.pronounDemonstrativeSingular, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`these`, `those`], Role(Rel.instanceOf), `plural demonstrative pronoun`, Sense.pronounDemonstrativePlural, Sense.nounPhrase, 1.0);

        // Possessive
        learnMto1(lang, [`my`, `your`], Role(Rel.instanceOf), `singular possessive adjective`, Sense.adjectivePossessiveSingular, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`our`, `their`], Role(Rel.instanceOf), `plural possessive adjective`, Sense.adjectivePossessivePlural, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`mine`, `yours`], Role(Rel.instanceOf), `singular possessive pronoun`, Sense.pronounPossessiveSingular, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`his`], Role(Rel.instanceOf), `male singular possessive pronoun`, Sense.pronounPossessiveSingularMale, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`hers`], Role(Rel.instanceOf), `female singular possessive pronoun`, Sense.pronounPossessiveSingularFemale, Sense.nounPhrase, 1.0);

        learnMto1(lang, [`ours`], Role(Rel.instanceOf), `1st-person plural possessive pronoun`, Sense.pronounPossessivePlural1st, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`yours`], Role(Rel.instanceOf), `2nd-person plural possessive pronoun`, Sense.pronounPossessivePlural2nd, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`theirs`], Role(Rel.instanceOf), `3rd-person plural possessive pronoun`, Sense.pronounPossessivePlural3rd, Sense.nounPhrase, 1.0);

        learnMto1(lang, [`who`, `whom`, `what`, `which`, `whose`, `whoever`, `whatever`, `whichever`], Role(Rel.instanceOf), `interrogative pronoun`, Sense.pronounInterrogative, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`myself`, `yourself`, `himself`, `herself`, `itself`], Role(Rel.instanceOf), `singular reflexive pronoun`, Sense.pronounReflexiveSingular, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`ourselves`, `yourselves`, `themselves`], Role(Rel.instanceOf), `plural reflexive pronoun`, Sense.pronounReflexivePlural, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`each other`, `one another`], Role(Rel.instanceOf), `reciprocal pronoun`, Sense.pronounReciprocal, Sense.nounPhrase, 1.0);

        learnMto1(lang, [`who`, `whom`, // generally only for people
                               `whose`, // possession
                               `which`, // things
                               `that` // things and people
                            ], Role(Rel.instanceOf), `relative pronoun`, Sense.pronounRelative, Sense.nounPhrase, 1.0);

        learnMto1(lang, [`all`, `any`, `more`, `most`, `none`, `some`, `such`], Role(Rel.instanceOf), `indefinite pronoun`, Sense.pronounIndefinitePlural, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`another`, `anybody`, `anyone`, `anything`, `each`, `either`, `enough`,
                         `everybody`, `everyone`, `everything`, `less`, `little`, `much`, `neither`,
                         `nobody`, `noone`, `one`, `other`,
                         `somebody`, `someone`,
                         `something`, `you`], Role(Rel.instanceOf), `singular indefinite pronoun`, Sense.pronounIndefiniteSingular, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`both`, `few`, `fewer`, `many`, `others`, `several`, `they`], Role(Rel.instanceOf), `plural indefinite pronoun`, Sense.pronounIndefinitePlural, Sense.nounPhrase, 1.0);

        // Rest
        learnMto1(lang, rdT(`../knowledge/en/pronoun.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `pronoun`, Sense.pronoun, Sense.nounSingular, 1.0); // TODO Remove?
    }

    void learnSwedishPronouns()
    {
        enum lang = Lang.sv;

        // Personal
        learnMto1(lang, [`jag`, `mig`], Role(Rel.instanceOf), `1st-person singular personal pronoun`, Sense.pronounPersonalSingular1st, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`du`, `dig`], Role(Rel.instanceOf), `2nd-person singular personal pronoun`, Sense.pronounPersonalSingular2nd, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`den`, `det`], Role(Rel.instanceOf), `3rd-person singular personal pronoun`, Sense.pronounPersonalSingular3rd, Sense.nounPhrase, 1.0);

        learnMto1(lang, [`han`], Role(Rel.instanceOf), `1st-person male singular personal pronoun`, Sense.pronounPersonalSingularMale1st, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`honom`], Role(Rel.instanceOf), `2nd-person male singular personal pronoun`, Sense.pronounPersonalSingularMale2nd, Sense.nounPhrase, 1.0);

        learnMto1(lang, [`hon`], Role(Rel.instanceOf), `1st-person female singular personal pronoun`, Sense.pronounPersonalSingularFemale1st, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`henne`], Role(Rel.instanceOf), `2nd-person female singular personal pronoun`, Sense.pronounPersonalSingularFemale2nd, Sense.nounPhrase, 1.0);

        learnMto1(lang, [`hen`], Role(Rel.instanceOf), `androgyn singular personal pronoun`, Sense.pronounPersonalSingular, Sense.nounPhrase, 1.0);

        learnMto1(lang, [`vi`, `oss`], Role(Rel.instanceOf), `1st-person plural personal pronoun`, Sense.pronounPersonalPlural1st, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`ni`], Role(Rel.instanceOf), `2nd-person plural personal pronoun`, Sense.pronounPersonalPlural2nd, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`de`, `dem`], Role(Rel.instanceOf), `3rd-person plural personal pronoun`, Sense.pronounPersonalPlural3rd, Sense.nounPhrase, 1.0);

        // Possessive
        learnMto1(lang, [`min`], Role(Rel.instanceOf), `1st-person singular possessive adjective`, Sense.pronounPossessiveSingular1st, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`din`], Role(Rel.instanceOf), `2nd-person possessive adjective`, Sense.pronounPossessiveSingular2nd, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`hans`], Role(Rel.instanceOf), `male singular possessive pronoun`, Sense.pronounPossessiveSingularMale, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`hennes`], Role(Rel.instanceOf), `female singular possessive pronoun`, Sense.pronounPossessiveSingularFemale, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`hens`], Role(Rel.instanceOf), `singular possessive pronoun`, Sense.pronounPossessiveSingular, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`dens`, `dets`], Role(Rel.instanceOf), `singular possessive pronoun`, Sense.pronounPossessiveSingularNeutral, Sense.nounPhrase, 1.0);

        learnMto1(lang, [`vår`], Role(Rel.instanceOf), `1st-person plural possessive pronoun`, Sense.pronounPossessivePlural1st, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`er`], Role(Rel.instanceOf), `2nd-person plural possessive pronoun`, Sense.pronounPossessivePlural2nd, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`deras`], Role(Rel.instanceOf), `3rd-person plural possessive pronoun`, Sense.pronounPossessivePlural3rd, Sense.nounPhrase, 1.0);

        // Demonstrative
        learnMto1(lang, [`den här`, `den där`], Role(Rel.instanceOf), `singular demonstrative pronoun`, Sense.pronounDemonstrativeSingular, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`de här`, `de där`], Role(Rel.instanceOf), `plural demonstrative pronoun`, Sense.pronounDemonstrativePlural, Sense.nounPhrase, 1.0);

        learnMto1(lang, [`den`, `det`], Role(Rel.instanceOf),
                        `singular determinative pronoun`,
                        Sense.pronounDeterminativeSingular, Sense.nounPhrase, 1.0);

        learnMto1(lang, [`de`, `dem`], Role(Rel.instanceOf),
                        `singular determinative pronoun`,
                        Sense.pronounDeterminativePlural, Sense.nounPhrase, 1.0);

        learnMto1(lang, [`en sådan`], Role(Rel.instanceOf),
                        `singular determinative pronoun`,
                        Sense.pronounDeterminativeSingular, Sense.nounPhrase, 1.0);

        learnMto1(lang, [`sådant`, `sådana`], Role(Rel.instanceOf),
                        `singular determinative pronoun`,
                        Sense.pronounDeterminativePlural, Sense.nounPhrase, 1.0);

        // Other
        learnMto1(lang, [`vem`, `som`, `vad`, `vilken`, `vems`], Role(Rel.instanceOf), `interrogative pronoun`, Sense.pronounInterrogative, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`mig själv`, `dig själv`, `han själv`, `henne själv`, `hen själv`, `den själv`, `det själv`], Role(Rel.instanceOf), `singular reflexive pronoun`, Sense.pronounReflexiveSingular, Sense.nounPhrase, 1.0); // TODO person
        learnMto1(lang, [`oss själva`, `er själva`, `dem själva`], Role(Rel.instanceOf), `plural reflexive pronoun`, Sense.pronounReflexivePlural, Sense.nounPhrase, 1.0); // TODO person
        learnMto1(lang, [`varandra`], Role(Rel.instanceOf), `reciprocal pronoun`, Sense.pronounReciprocal, Sense.nounPhrase, 1.0);
    }

    void learnVerbs()
    {
        writeln(`Reading Verbs ...`);
        learnSwedishRegularVerbs();
        learnSwedishIrregularVerbs();
        learnEnglishVerbs();
    }

    void learnAdjectives()
    {
        writeln(`Reading Adjectives ...`);
        learnSwedishAdjectives();
        learnEnglishAdjectives();
        learnGermanIrregularAdjectives();
    }

    void learnEnglishVerbs()
    {
        writeln(`Reading English Verbs ...`);
        learnEnglishIrregularVerbs();
        learnMto1(Lang.en, rdT(`../knowledge/en/verbs.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `verb`, Sense.verb, Sense.noun, 1.0);
    }

    void learnAdverbs()
    {
        writeln(`Reading Adverbs ...`);
        learnEnglishAdverbs();
        learnSwedishAdverbs();
        learnMto1(Lang.en, rdT(`../knowledge/en/adverb.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `adverb`, Sense.adverb, Sense.noun, 1.0);
    }

    void learnSwedishAdverbs()
    {
        writeln(`Reading Swedish Adverbs ...`);
        enum lang = Lang.sv;

        learnMto1(lang,
                        [`i går`, `i dag,`, `i morgon`,
                         `i kväll`, `i natt`,
                         `i går kväll`, `i går natt`, `i går morgon`
                         `nästa dag`, `nästnästa dag`
                         `nästa vecka`, `nästnästa vecka`
                         `nästa månad`, `nästnästa månad`
                         `nästa år`, `nästnästa år`
                         `nu`, `omedelbart`
                         `sedan`, `senare`, `nyligen`, `just nu`, `på sistone`, `snart`,
                         `redan`, `fortfarande`, `ännu`, `förr`, `förut`],
                        Role(Rel.instanceOf), `time adverb`, Sense.timeAdverb, Sense.nounPhrase, 1.0);

        learnMto1(lang,
                        [`här`, `där`, `där borta`, `överallt`, `var som helst`,
                         `ingenstans`, `hem`, `bort`, `ut`],
                        Role(Rel.instanceOf), `place adverb`, Sense.placeAdverb, Sense.nounPhrase, 1.0);

        learnMto1(lang,
                        [`alltid`, `ofta`, `vanligen`, `ibland`, `emellanåt`, `sällan`, `aldrig`],
                        Role(Rel.instanceOf), `frequency adverb`, Sense.frequencyAdverb, Sense.nounPhrase, 1.0);

        learnMto1(lang,
                        [`ja`, `japp`, `överallt`, `alltid`],
                        Role(Rel.instanceOf), `affirming adverb`, Sense.affirmingAdverb, Sense.nounPhrase, 1.0);

        learnMto1(lang,
                        [`ej`, `inte`, `icke`],
                        Role(Rel.instanceOf), `negating adverb`, Sense.negatingAdverb, Sense.nounPhrase, 1.0);

        learnMto1(Lang.sv,
                        [`emellertid`, `däremot`, `dock`, `likväl`, `ändå`,
                         `trots det`, `trots detta`],
                        Role(Rel.instanceOf), `adverb`, Sense.adverb, Sense.nounPhrase, 1.0);
    }

    void learnEnglishAdverbs()
    {
        writeln(`Reading English Adverbs ...`);

        enum lang = Lang.en;

        learnMto1(lang,
                        [`yesterday`, `today`, `tomorrow`, `tonight`, `last night`, `this morning`,
                         `previous week`, `next week`,
                         `previous year`, `next year`,
                         `now`, `then`, `later`, `right now`, `already`,
                         `recently`, `lately`, `soon`, `immediately`,
                         `still`, `yet`, `ago`],
                        Role(Rel.instanceOf), `time adverb`, Sense.timeAdverb, Sense.nounPhrase, 1.0);

        learnMto1(lang,
                        [`here`, `there`, `over there`, `out there`, `in there`,
                         `everywhere`, `anywhere`, `nowhere`, `home`, `away`, `out`],
                        Role(Rel.instanceOf), `place adverb`, Sense.placeAdverb, Sense.nounPhrase, 1.0);

        learnMto1(lang,
                        [`always`, `frequently`, `usually`, `sometimes`, `occasionally`, `seldom`,
                         `rarely`, `never`],
                        Role(Rel.instanceOf), `frequency adverb`, Sense.frequencyAdverb, Sense.nounPhrase, 1.0);

        learnMto1(lang,
                        [`accordingly`, `additionally`, `again`, `almost`,
                         `although`, `anyway`, `as a result`, `besides`,
                         `certainly`, `comparatively`, `consequently`,
                         `contrarily`, `conversely`, `elsewhere`, `equally`,
                         `eventually`, `finally`, `further`, `furthermore`,
                         `hence`, `henceforth`, `however`, `in addition`,
                         `in comparison`, `in contrast`, `in fact`, `incidentally`,
                         `indeed`, `instead`, `just as`, `likewise`,
                         `meanwhile`, `moreover`, `namely`, `nevertheless`,
                         `next`, `nonetheless`, `notably`, `now`, `otherwise`,
                         `rather`, `similarly`, `still`, `subsequently`, `that is`,
                         `then`, `thereafter`, `therefore`, `thus`,
                         `undoubtedly`, `uniquely`, `on the other hand`, `also`,
                         `for example`, `for instance`, `of course`, `on the contrary`,
                         `so far`, `until now`, `thus` ],
                        Role(Rel.instanceOf), `conjunctive adverb`,
                        Sense.conjunctiveAdverb, Sense.nounPhrase, 1.0);

        learnMto1(lang,
                        [`no`, `not`, `never`, `nowhere`, `none`, `nothing`],
                        Role(Rel.instanceOf), `negating adverb`, Sense.negatingAdverb, Sense.nounPhrase, 1.0);

        learnMto1(lang,
                        [`yes`, `yeah`],
                        Role(Rel.instanceOf), `affirming adverb`, Sense.affirmingAdverb, Sense.nounPhrase, 1.0);
    }

    void learnDefiniteArticles()
    {
        writeln(`Reading Definite Articles ...`);

        learnMto1(Lang.en, [`the`],
                        Role(Rel.instanceOf), `definite article`, Sense.articleDefinite, Sense.nounPhrase, 1.0);
        learnMto1(Lang.de, [`der`, `die`, `das`, `des`, `dem`, `den`],
                        Role(Rel.instanceOf), `definite article`, Sense.articleDefinite, Sense.nounPhrase, 1.0);
        learnMto1(Lang.fr, [`le`, `la`, `l'`, `les`],
                        Role(Rel.instanceOf), `definite article`, Sense.articleDefinite, Sense.nounPhrase, 1.0);
        learnMto1(Lang.sv, [`den`, `det`],
                        Role(Rel.instanceOf), `definite article`, Sense.articleDefinite, Sense.nounPhrase, 1.0);
    }

    void learnUndefiniteArticles()
    {
        writeln(`Reading Undefinite Articles ...`);

        learnMto1(Lang.en, [`a`, `an`],
                        Role(Rel.instanceOf), `undefinite article`, Sense.articleIndefinite, Sense.nounPhrase, 1.0);
        learnMto1(Lang.de, [`ein`, `eine`, `eines`, `einem`, `einen`, `einer`],
                        Role(Rel.instanceOf), `undefinite article`, Sense.articleIndefinite, Sense.nounPhrase, 1.0);
        learnMto1(Lang.fr, [`un`, `une`, `des`],
                        Role(Rel.instanceOf), `undefinite article`, Sense.articleIndefinite, Sense.nounPhrase, 1.0);
        learnMto1(Lang.sv, [`en`, `ena`, `ett`],
                        Role(Rel.instanceOf), `undefinite article`, Sense.articleIndefinite, Sense.nounPhrase, 1.0);
    }

    void learnPartitiveArticles()
    {
        writeln(`Reading Partitive Articles ...`);

        learnMto1(Lang.en, [`some`],
                        Role(Rel.instanceOf), `partitive article`, Sense.articlePartitive, Sense.nounPhrase, 1.0);
        learnMto1(Lang.fr, [`du`, `de`, `la`, `de`, `l'`, `des`],
                        Role(Rel.instanceOf), `partitive article`, Sense.articlePartitive, Sense.nounPhrase, 1.0);
    }

    void learnNames()
    {
        writeln(`Reading Names ...`);

        // Surnames
        learnMto1(Lang.en, rdT(`../knowledge/en/surname.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `surname`, Sense.surname, Sense.nounSingular, 1.0);
        learnMto1(Lang.sv, rdT(`../knowledge/sv/surname.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `surname`, Sense.surname, Sense.nounSingular, 1.0);
    }

    void learnConjunctions()
    {
        writeln(`Reading Conjunctions ...`);

        // TODO merge with conjunctions?
        // TODO categorize like http://www.grammarbank.com/connectives-list.html
        enum connectives = [`the`, `of`, `and`, `to`, `a`, `in`, `that`, `is`,
                            `was`, `he`, `for`, `it`, `with`, `as`, `his`,
                            `on`, `be`, `at`, `by`, `i`, `this`, `had`, `not`,
                            `are`, `but`, `from`, `or`, `have`, `an`, `they`,
                            `which`, `one`, `you`, `were`, `her`, `all`, `she`,
                            `there`, `would`, `their`, `we him`, `been`, `has`,
                            `when`, `who`, `will`, `more`, `no`, `if`, `out`,
                            `so`, `said`, `what`, `up`, `its`, `about`, `into`,
                            `than them`, `can`, `only`, `other`, `new`, `some`,
                            `could`, `time`, `these`, `two`, `may`, `then`,
                            `do`, `first`, `any`, `my`, `now`, `such`, `like`,
                            `our`, `over`, `man`, `me`, `even`, `most`, `made`,
                            `after`, `also`, `did`, `many`, `before`, `must`,
                            `through back`, `years`, `where`, `much`, `your`,
                            `way`, `well`, `down`, `should`, `because`, `each`,
                            `just`, `those`, `people mr`, `how`, `too`,
                            `little`, `state`, `good`, `very`, `make`, `world`,
                            `still`, `own`, `see`, `men`, `work`, `long`, `get`,
                            `here`, `between`, `both`, `life`, `being`, `under`,
                            `never`, `day`, `same`, `another`, `know`, `while`,
                            `last`, `might us`, `great`, `old`, `year`, `off`,
                            `come`, `since`, `against`, `go`, `came`, `right`,
                            `used`, `take`, `three`];

        // Coordinating Conjunction
        connect(store(`coordinating conjunction`, Lang.en, Sense.nounPhrase, Origin.manual),
                Role(Rel.uses),
                store(`connect independent sentence parts`, Lang.en, Sense.unknown, Origin.manual),
                Origin.manual, 1.0);
        learnMto1(Lang.en, [`and`, `or`, `but`, `nor`, `so`, `for`, `yet`],
                  Role(Rel.instanceOf), `coordinating conjunction`, Sense.conjunctionCoordinating, Sense.nounPhrase, 1.0);
        learnMto1(Lang.sv, [`och`, `eller`, `men`, `så`, `för`, `ännu`],
                  Role(Rel.instanceOf), `coordinating conjunction`, Sense.conjunctionCoordinating, Sense.nounPhrase, 1.0);
        learnMto1(Lang.en, [`that`],
                  Role(Rel.instanceOf), `coordinating conjunction`, Sense.conjunctionSubordinating, Sense.nounPhrase, 1.0);
        learnMto1(Lang.en, [`though`, `although`, `eventhough`, `even though`, `while`],
                  Role(Rel.instanceOf), `coordinating concession conjunction`, Sense.conjunctionSubordinatingConcession, Sense.nounPhrase, 1.0);
        learnMto1(Lang.en, [`if`, `only if`, `unless`, `until`, `provided that`, `assuming that`, `even if`, `in case`, `in case that`, `lest`],
                  Role(Rel.instanceOf), `coordinating condition conjunction`, Sense.conjunctionSubordinatingCondition, Sense.nounPhrase, 1.0);
        learnMto1(Lang.en, [`than`, `rather than`, `whether`, `as much as`, `whereas`],
                  Role(Rel.instanceOf), `coordinating comparison conjunction`, Sense.conjunctionSubordinatingComparison, Sense.nounPhrase, 1.0);
        learnMto1(Lang.en, [`after`, `as long as`, `as soon as`, `before`, `by the time`, `now that`, `once`, `since`, `till`, `until`, `when`, `whenever`, `while`],
                  Role(Rel.instanceOf), `coordinating time conjunction`, Sense.conjunctionSubordinatingTime, Sense.nounPhrase, 1.0);
        learnMto1(Lang.en, [`because`, `since`, `so that`, `in order`, `in order that`, `why`],
                  Role(Rel.instanceOf), `coordinating reason conjunction`, Sense.conjunctionSubordinatingReason, Sense.nounPhrase, 1.0);
        learnMto1(Lang.en, [`how`, `as though`, `as if`],
                  Role(Rel.instanceOf), `coordinating manner conjunction`, Sense.conjunctionSubordinatingManner, Sense.nounPhrase, 1.0);
        learnMto1(Lang.en, [`where`, `wherever`],
                  Role(Rel.instanceOf), `coordinating place conjunction`, Sense.conjunctionSubordinatingPlace, Sense.nounPhrase, 1.0);
        learnMto1(Lang.en, [`as {*} as`,
                            `just as {*} so`,
                            `both {*} and`,
                            `hardly {*} when`,
                            `scarcely {*} when`,
                            `either {*} or`,
                            `neither {*} nor`,
                            `if {*} then`,
                            `not {*} but`,
                            `what with {*} and`,
                            `whether {*} or`,
                            `not only {*} but also`,
                            `no sooner {*} than`,
                            `rather {*} than`],
                        Role(Rel.instanceOf), `correlative conjunction`, Sense.conjunctionCorrelative, Sense.nounPhrase, 1.0);

        // Subordinating Conjunction
        connect(store(`subordinating conjunction`, Lang.en, Sense.nounPhrase, Origin.manual),
                Role(Rel.uses),
                store(`establish the relationship between the dependent clause and the rest of the sentence`,
                      Lang.en, Sense.unknown, Origin.manual),
                Origin.manual, 1.0);

        // Conjunction
        learnMto1(Lang.en, rdT(`../knowledge/en/conjunction.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `conjunction`, Sense.conjunction, Sense.nounSingular, 1.0);

        enum swedishConjunctions = [`alldenstund`, `allenast`, `ante`, `antingen`, `att`, `bara`, `blott`, `bå`, `båd'`, `både`, `dock`, `att`, `där`, `därest`, `därför`, `att`, `då`, `eftersom`, `ehur`, `ehuru`, `eller`, `emedan`, `enär`, `ety`, `evad`, `fast`, `fastän`, `för`, `förrän`, `försåvida`, `försåvitt`, `fȧst`, `huruvida`, `hvarför`, `hvarken`, `hvarpå`, `ifall`, `innan`, `ity`, `ity`, `att`, `liksom`, `medan`, `medans`, `men`, `mens`, `när`, `närhelst`, `oaktat`, `och`, `om`, `om`, `och`, `endast`, `om`, `plus`, `att`, `samt`, `sedan`, `som`, `sä`, `så`, `såframt`, `såsom`, `såvida`, `såvitt`, `såväl`, `sö`, `tast`, `tills`, `ty`, `utan`, `varför`, `varken`, `än`, `ändock`, `änskönt`, `ävensom`, `å`];
        learnMto1(Lang.sv, swedishConjunctions, Role(Rel.instanceOf), `conjunction`, Sense.conjunction, Sense.nounSingular, 1.0);
    }

    void learnInterjections()
    {
        writeln(`Reading Interjections ...`);

        learnMto1(Lang.en,
                        rdT(`../knowledge/en/interjection.txt`).splitter('\n').filter!(word => !word.empty),
                        Role(Rel.instanceOf), `interjection`, Sense.interjection, Sense.nounSingular, 1.0);
    }

    void learnTime()
    {
        writeln(`Reading Time ...`);

        learnMto1(Lang.en, [`monday`, `tuesday`, `wednesday`, `thursday`, `friday`, `saturday`, `sunday`],    Role(Rel.instanceOf), `weekday`, Sense.weekday, Sense.nounSingular, 1.0);
        learnMto1(Lang.de, [`montag`, `dienstag`, `mittwoch`, `donnerstag`, `freitag`, `samstag`, `sonntag`], Role(Rel.instanceOf), `weekday`, Sense.weekday, Sense.nounSingular, 1.0);
        learnMto1(Lang.sv, [`montag`, `dienstag`, `mittwoch`, `donnerstag`, `freitag`, `samstag`, `sonntag`], Role(Rel.instanceOf), `weekday`, Sense.weekday, Sense.nounSingular, 1.0);

        learnMto1(Lang.en, [`january`, `february`, `mars`, `april`, `may`, `june`, `july`, `august`, `september`, `oktober`, `november`, `december`], Role(Rel.instanceOf), `month`, Sense.month, Sense.nounSingular, 1.0);
        learnMto1(Lang.de, [`Januar`, `Februar`, `März`, `April`, `Mai`, `Juni`, `Juli`, `August`, `September`, `Oktober`, `November`, `Dezember`], Role(Rel.instanceOf), `month`, Sense.month, Sense.nounSingular, 1.0);
        learnMto1(Lang.sv, [`januari`, `februari`, `mars`, `april`, `maj`, `juni`, `juli`, `augusti`, `september`, `oktober`, `november`, `december`], Role(Rel.instanceOf), `month`, Sense.month, Sense.nounSingular, 1.0);

        learnMto1(Lang.en, [`time period`], Role(Rel.isA), `noun`, Sense.noun, Sense.nounSingular, 1.0);
        learnMto1(Lang.en, [`month`], Role(Rel.isA), `time period`, Sense.noun, Sense.nounSingular, 1.0);
    }

    /// Learn Assocative Things.
    void learnAssociativeThings()
    {
        writeln(`Reading Associative Things ...`);

        // TODO lower weights on these are not absolute
        learnMto1(Lang.en, rdT(`../knowledge/en/constitution.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `constitution`, Sense.unknown, Sense.nounSingular);
        learnMto1(Lang.en, rdT(`../knowledge/en/election.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `election`, Sense.unknown, Sense.nounSingular);
        learnMto1(Lang.en, rdT(`../knowledge/en/weather.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `weather`, Sense.noun, Sense.nounSingular);
        learnMto1(Lang.en, rdT(`../knowledge/en/dentist.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `dentist`, Sense.unknown, Sense.nounSingular);
        learnMto1(Lang.en, rdT(`../knowledge/en/firefighting.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `fire fighting`, Sense.unknown, Sense.nounSingular);
        learnMto1(Lang.en, rdT(`../knowledge/en/driving.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `drive`, Sense.unknown, Sense.verb);
        learnMto1(Lang.en, rdT(`../knowledge/en/art.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `art`, Sense.unknown, Sense.nounSingular);
        learnMto1(Lang.en, rdT(`../knowledge/en/astronomy.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `astronomy`, Sense.unknown, Sense.nounSingular);

        learnMto1(Lang.en, rdT(`../knowledge/en/vacation.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `vacation`, Sense.unknown, Sense.nounSingular);

        learnMto1(Lang.en, rdT(`../knowledge/en/autumn.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `autumn`, Sense.unknown, Sense.season);
        learnMto1(Lang.en, rdT(`../knowledge/en/winter.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `winter`, Sense.unknown, Sense.season);
        learnMto1(Lang.en, rdT(`../knowledge/en/spring.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `spring`, Sense.unknown, Sense.season);

        learnMto1(Lang.en, rdT(`../knowledge/en/summer_noun.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.atTime), `summer`, Sense.noun, Sense.season);
        learnMto1(Lang.en, rdT(`../knowledge/en/summer_adjective.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.atTime), `summer`, Sense.adjective, Sense.season);
        learnMto1(Lang.en, rdT(`../knowledge/en/summer_verb.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.atTime), `summer`, Sense.verb, Sense.season);

        learnMto1(Lang.en, rdT(`../knowledge/en/household_device.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.atLocation), `house`, Sense.noun, Sense.nounSingular);
        learnMto1(Lang.en, rdT(`../knowledge/en/household_device.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `device`, Sense.noun, Sense.nounSingular);
        learnMto1(Lang.en, rdT(`../knowledge/en/farm.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.atLocation), `farm`, Sense.noun, Sense.nounSingular);
        learnMto1(Lang.en, rdT(`../knowledge/en/school.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.atLocation), `school`, Sense.noun, Sense.nounSingular);
        learnMto1(Lang.en, rdT(`../knowledge/en/circus.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.atLocation), `circus`, Sense.noun, Sense.nounSingular);
        learnMto1(Lang.en, rdT(`../knowledge/en/near_yard.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.atLocation), `yard`, Sense.noun, Sense.nounSingular);
        learnMto1(Lang.en, rdT(`../knowledge/en/restaurant.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.atLocation), `restaurant`, Sense.noun, Sense.nounSingular);

        learnMto1(Lang.en, rdT(`../knowledge/en/bathroom.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.atLocation), `bathroom`, Sense.noun, Sense.nounSingular);
        learnMto1(Lang.en, rdT(`../knowledge/en/house.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.atLocation), `house`, Sense.noun, Sense.nounSingular);
        learnMto1(Lang.en, rdT(`../knowledge/en/kitchen.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.atLocation), `kitchen`, Sense.noun, Sense.nounSingular);

        learnMto1(Lang.en, rdT(`../knowledge/en/beach.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.atLocation), `beach`, Sense.noun, Sense.nounSingular);
        learnMto1(Lang.en, rdT(`../knowledge/en/ocean.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.atLocation), `ocean`, Sense.noun, Sense.nounSingular);

        learnMto1(Lang.en, rdT(`../knowledge/en/happy.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.similarTo), `happy`, Sense.adjective, Sense.adjective);
        learnMto1(Lang.en, rdT(`../knowledge/en/big.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.similarTo), `big`, Sense.adjective, Sense.adjective);
        learnMto1(Lang.en, rdT(`../knowledge/en/many.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.similarTo), `many`, Sense.adjective, Sense.adjective);
        learnMto1(Lang.en, rdT(`../knowledge/en/easily_upset.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.similarTo), `easily upset`, Sense.adjective, Sense.adjective);

        learnMto1(Lang.en, rdT(`../knowledge/en/roadway.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `roadway`, Sense.noun, Sense.nounSingular);
        learnMto1(Lang.en, rdT(`../knowledge/en/baseball.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `baseball`, Sense.noun, Sense.nounSingular);
        learnMto1(Lang.en, rdT(`../knowledge/en/boat.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `boat`, Sense.noun, Sense.nounSingular);
        learnMto1(Lang.en, rdT(`../knowledge/en/money.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `money`, Sense.noun, Sense.nounUncountable);
        learnMto1(Lang.en, rdT(`../knowledge/en/family.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `family`, Sense.noun, Sense.nounCollective);
        learnMto1(Lang.en, rdT(`../knowledge/en/geography.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `geography`, Sense.unknown, Sense.nounUncountable);
        learnMto1(Lang.en, rdT(`../knowledge/en/energy.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `energy`, Sense.unknown, Sense.nounUncountable);
        learnMto1(Lang.en, rdT(`../knowledge/en/time.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `time`, Sense.unknown, Sense.nounUncountable);
        learnMto1(Lang.en, rdT(`../knowledge/en/water.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `water`, Sense.unknown, Sense.nounUncountable);
        learnMto1(Lang.en, rdT(`../knowledge/en/clothing.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `clothing`, Sense.unknown, Sense.nounUncountable);
        learnMto1(Lang.en, rdT(`../knowledge/en/music_theory.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `music theory`, Sense.unknown, Sense.nounSingular);
        learnMto1(Lang.en, rdT(`../knowledge/en/happiness.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `happiness`, Sense.unknown, Sense.nounUncountable);
        learnMto1(Lang.en, rdT(`../knowledge/en/pirate.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `pirate`, Sense.unknown, Sense.nounSingular);
        learnMto1(Lang.en, rdT(`../knowledge/en/monster.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `monster`, Sense.unknown, Sense.nounSingular);

        learnMto1(Lang.en, rdT(`../knowledge/en/halloween.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `halloween`, Sense.unknown, Sense.nounUncountable);
        learnMto1(Lang.en, rdT(`../knowledge/en/christmas.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `christmas`, Sense.unknown, Sense.nounUncountable);
        learnMto1(Lang.en, rdT(`../knowledge/en/thanksgiving.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `thanksgiving`, Sense.unknown, Sense.nounUncountable);
        learnMto1(Lang.en, rdT(`../knowledge/en/camp.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `camping`, Sense.unknown, Sense.nounUncountable);
        learnMto1(Lang.en, rdT(`../knowledge/en/cooking.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `cooking`, Sense.unknown, Sense.nounUncountable);
        learnMto1(Lang.en, rdT(`../knowledge/en/sewing.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `sewing`, Sense.unknown, Sense.nounUncountable);
        learnMto1(Lang.en, rdT(`../knowledge/en/military.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `military`, Sense.unknown, Sense.nounUncountable);
        learnMto1(Lang.en, rdT(`../knowledge/en/science.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `science`, Sense.unknown, Sense.nounUncountable);
        learnMto1(Lang.en, rdT(`../knowledge/en/computer.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `computing`, Sense.unknown, Sense.nounUncountable);
        learnMto1(Lang.en, rdT(`../knowledge/en/math.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `math`, Sense.unknown, Sense.nounUncountable);

        learnMto1(Lang.en, rdT(`../knowledge/en/transport.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `transportation`, Sense.unknown, Sense.nounUncountable);

        learnMto1(Lang.en, rdT(`../knowledge/en/rock.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `rock`, Sense.unknown, Sense.nounUncountable);
        learnMto1(Lang.en, rdT(`../knowledge/en/doctor.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `doctor`, Sense.unknown, Sense.nounSingular);
        learnMto1(Lang.en, rdT(`../knowledge/en/st-patricks-day.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `St. Patrick's Day`, Sense.unknown, Sense.nounUncountable);
        learnMto1(Lang.en, rdT(`../knowledge/en/new-years-eve.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.any), `New Year's Eve`, Sense.unknown, Sense.nounUncountable);

        learnMto1(Lang.en, rdT(`../knowledge/en/say.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `say`, Sense.verb, Sense.verbIrregularInfinitive);
        learnMto1(Lang.en, rdT(`../knowledge/en/book_property.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.hasProperty, true), `book`, Sense.adjective, Sense.nounSingular);
        learnMto1(Lang.en, rdT(`../knowledge/en/informal.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.hasAttribute), `informal`, Sense.adjective, Sense.adjective);

        // Red Wine
        learnMto1(Lang.en, rdT(`../knowledge/en/red_wine_color.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `red wine color`, Sense.noun, Sense.nounSingular);
        learnMto1(Lang.en, rdT(`../knowledge/en/red_wine_flavor.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `red wine flavor`, Sense.noun, Sense.nounSingular);
        learnMto1(Lang.en, rdT(`../knowledge/en/red_wine_food.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.servedWith), `red wine`, Sense.noun, Sense.nounSingular);

        learnMto1(Lang.en, rdT(`../knowledge/en/literary_genre.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `literary genre`, Sense.noun, Sense.nounSingular);
        learnMto1(Lang.en, rdT(`../knowledge/en/major_literary_form.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `major literary form`, Sense.noun, Sense.nounSingular);
        learnMto1(Lang.en, rdT(`../knowledge/en/classic_major_literary_genre.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `classic major literary genre`, Sense.noun, Sense.nounSingular);

        // Female Names
        learnMto1(Lang.en, rdT(`../knowledge/en/female_name.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `female name`, Sense.nameFemale, Sense.nounSingular, 1.0);
        learnMto1(Lang.sv, rdT(`../knowledge/sv/female_name.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `female name`, Sense.nameFemale, Sense.nounSingular, 1.0);
    }

    /// Learn Emotions.
    void learnEmotions()
    {
        enum groups = [`basic`, `positive`, `negative`, `strong`, `medium`, `light`];
        foreach (group; groups)
        {
            learnMto1(Lang.en,
                      rdT(`../knowledge/en/` ~ group ~ `_emotion.txt`).splitter('\n').filter!(word => !word.empty),
                      Role(Rel.instanceOf), group ~ ` emotion`, Sense.unknown, Sense.nounSingular);
        }
    }

    /// Learn English Feelings.
    void learnEnglishFeelings()
    {
        learnMto1(Lang.en, rdT(`../knowledge/en/feeling.txt`).splitter('\n').filter!(word => !word.empty), Role(Rel.instanceOf), `feeling`, Sense.adjective, Sense.nounSingular);
        enum feelings = [`afraid`, `alive`, `angry`, `confused`, `depressed`, `good`, `happy`,
                         `helpless`, `hurt`, `indifferent`, `interested`, `love`,
                         `negative`, `unpleasant`,
                         `positive`, `pleasant`,
                         `open`, `sad`, `strong`];
        foreach (feeling; feelings)
        {
            const path = `../knowledge/en/` ~ feeling ~ `_feeling.txt`;
            learnAssociations(path, Rel.similarTo, feeling.replace(`_`, ` `) ~ ` feeling`, Sense.adjective, Sense.adjective);
        }
    }

    /// Learn Swedish Feelings.
    void learnSwedishFeelings()
    {
        learnMto1(Lang.sv,
                  rdT(`../knowledge/sv/känsla.txt`).splitter('\n').filter!(word => !word.empty),
                  Role(Rel.instanceOf), `känsla`, Sense.noun, Sense.nounSingular);
    }

    /// Read and Learn Assocations.
    void learnAssociations(S)(string path,
                              Rel rel,
                              S attribute,
                              Sense wordSense = Sense.unknown,
                              Sense attributeSense = Sense.noun,
                              Lang lang = Lang.en,
                              Origin origin = Origin.manual) if (isSomeString!S)
    {
        foreach (expr; File(path).byLine.filter!(a => !a.empty))
        {
            auto split = expr.findSplit([countSeparator]); // TODO allow key to be ElementType of Range to prevent array creation here
            const name = split[0], count = split[2];

            if (expr == `ack#2`)
            {
                dln(name, `, `, count);
            }

            NWeight nweight = 1.0;
            if (!count.empty)
            {
                const w = count.to!NWeight;
                nweight = w/(1 + w); // count to normalized weight
            }

            connect(store(name.idup, lang, wordSense, origin),
                    Role(rel),
                    store(attribute, lang, attributeSense, origin),
                    origin, nweight);
        }
    }

    /// Learn Chemical Elements.
    void learnChemicalElements(Lang lang = Lang.en, Origin origin = Origin.manual)
    {
        foreach (expr; File(`../knowledge/en/chemical_elements.txt`).byLine.filter!(a => !a.empty))
        {
            auto split = expr.findSplit([roleSeparator]); // TODO allow key to be ElementType of Range to prevent array creation here
            const name = split[0], sym = split[2];
            NWeight weight = 1.0;

            connect(store(name.idup, lang, Sense.nounUncountable, origin),
                    Role(Rel.instanceOf),
                    store(`chemical element`, lang, Sense.nounSingular, origin),
                    origin, weight);

            connect(store(sym.idup, lang, Sense.noun, origin),
                    Role(Rel.symbolFor),
                    store(name.idup, lang, Sense.noun, origin),
                    origin, weight);
        }
    }

    void learnMtoNMaybe(const string path,
                        const Sense firstSense, const Lang firstLang,
                        const Role role,
                        const Sense secondSense, const Lang secondLang,
                        const Origin origin = Origin.manual,
                        const NWeight weight = 0.5)
    {
        try
        {
            foreach (line; File(path).byLine.filter!(a => !a.empty))
            {
                auto senseFact = line.findSplit([qualifierSeparator]);
                const senseCode = senseFact[0];

                Sense firstSpecializedSense = firstSense;
                Sense secondSpecializedSense = secondSense;

                if (role.rel.infersSense &&
                    !senseCode.empty)
                {
                    try
                    {
                        import std.conv: to;
                        const sense = senseCode.to!Sense;
                        if (firstSense  == Sense.unknown) { firstSpecializedSense = sense; }
                        if (secondSense == Sense.unknown) { secondSpecializedSense = sense; }
                    }
                    catch (std.conv.ConvException e)
                    {
                        /* ok for now */
                    }
                }
                auto split = line.findSplit([roleSeparator]); // TODO allow key to be ElementType of Range to prevent array creation here
                const first = split[0], second = split[2];
                auto firstRefs = store(first.splitter(alternativesSeparator).map!idup,
                                       firstLang, firstSpecializedSense, origin);
                if (!first.empty &&
                    !second.empty)
                {
                    auto secondRefs = store(second.splitter(alternativesSeparator).map!idup,
                                            secondLang, secondSpecializedSense, origin);
                    connectMtoN(firstRefs, role, secondRefs, origin, weight, true);
                }
            }
        }
        catch (std.exception.ErrnoException e)
        {
            writeln(`Could not open file `, path);
        }
    }

    /// Get Learn Possible Senses for $(D expr).
    auto sensesOfExpr(S)(S expr) if (isSomeString!S)
    {
        return lemmasOfExpr(expr).map!(lemma => lemma.sense).filter!(sense => sense != Sense.unknown);
    }

    /// Get Possible Common Sense for $(D a) and $(D b). TODO N-ary
    Sense commonSense(S1, S2)(S1 a, S2 b) if (isSomeString!S1 &&
                                              isSomeString!S2)
    {
        auto commonSenses = setIntersection(sensesOfExpr(a).sorted,
                                            sensesOfExpr(b).sorted);
        return commonSenses.count == 1 ? commonSenses.front : Sense.unknown;
    }

    /// Learn Opposites.
    void learnOpposites(Lang lang, Origin origin = Origin.manual)
    {
        foreach (expr; File(`../knowledge/` ~ lang.to!string ~ `/opposites.txt`).byLine.filter!(a => !a.empty))
        {
            auto split = expr.findSplit([roleSeparator]); // TODO allow key to be ElementType of Range to prevent array creation here
            const auto first = split[0], second = split[2];
            NWeight weight = 1.0;
            const sense = commonSense(first, second);
            connect(store(first.idup, lang, sense, origin),
                    Role(Rel.oppositeOf),
                    store(second.idup, lang, sense, origin),
                    origin, weight);
        }
    }

    /// Learn Verb Reversions.
    void learnVerbReversions()
    {
        // TODO Copy all from krels.toHuman
        learnVerbReversion(`is a`, `can be`, Lang.en);
        learnVerbReversion(`leads to`, `can infer`, Lang.en);
        learnVerbReversion(`is part of`, `contains`, Lang.en);
        learnVerbReversion(`is member of`, `has member`, Lang.en);
    }

    /// Learn Verb Reversion.
    Ln[] learnVerbReversion(S)(S forward,
                               S backward,
                               Lang lang = Lang.unknown) if (isSomeString!S)
    {
        const origin = Origin.manual;
        auto all = [store(forward, lang, Sense.verbInfinitive, origin),
                    store(backward, lang, Sense.verbPastParticiple, origin)];
        return connectAll(Role(Rel.reversionOf), all.filter!(a => a.defined), lang, origin);
    }

    /// Learn Etymologically Derived Froms.
    void learnEtymologicallyDerivedFroms()
    {
        learnEtymologicallyDerivedFrom(`holiday`, Lang.en, Sense.noun,
                                       `holy day`, Lang.en, Sense.noun);
        learnEtymologicallyDerivedFrom(`juletide`, Lang.en, Sense.noun,
                                       `juletid`, Lang.sv, Sense.noun);
        learnEtymologicallyDerivedFrom(`smorgosbord`, Lang.en, Sense.noun,
                                       `smörgåsbord`, Lang.sv, Sense.noun);
        learnEtymologicallyDerivedFrom(`förgätmigej`, Lang.sv, Sense.noun,
                                       `förgät mig ej`, Lang.sv, Sense.unknown); // TODO uppmaning
        learnEtymologicallyDerivedFrom(`OK`, Lang.en, Sense.unknown,
                                       `Old Kinderhook`, Lang.en, Sense.unknown);
    }

    /** Learn that $(D first) in language $(D firstLang) is etymologically
        derived from $(D second) in language $(D secondLang) both in sense $(D sense).
     */
    Ln learnEtymologicallyDerivedFrom(S1, S2)(S1 first, Lang firstLang, Sense firstSense,
                                              S2 second, Lang secondLang, Sense secondSense)
    {
        return connect(store(first, firstLang, Sense.noun, Origin.manual),
                       Role(Rel.etymologicallyDerivedFrom),
                       store(second, secondLang, Sense.noun, Origin.manual),
                       Origin.manual, 1.0);
    }

    /** Learn English Irregular Verb.
     */
    Ln[] learnEnglishIrregularVerb(S1, S2, S3)(S1 infinitive, // base form
                                               S2 pastSimple,
                                               S3 pastParticiple,
                                               Origin origin = Origin.manual)
    {
        enum lang = Lang.en;
        Nd[] all;
        all ~= store(infinitive, lang, Sense.verbIrregularInfinitive, origin);
        all ~= store(pastSimple, lang, Sense.verbIrregularPast, origin);
        all ~= store(pastParticiple, lang, Sense.verbIrregularPastParticiple, origin);
        return connectAll(Role(Rel.formOfVerb), all.filter!(a => a.defined), lang, origin);
    }

    /** Learn English Acronym.
     */
    Ln learnEnglishAcronym(S)(S acronym,
                              S expr,
                              NWeight weight = 1.0,
                              Sense sense = Sense.unknown,
                              Origin origin = Origin.manual) if (isSomeString!S)
    {
        enum lang = Lang.en;
        return connect(store(acronym, lang, Sense.nounAcronym, origin),
                       Role(Rel.acronymFor),
                       store(expr.toLower, lang, sense, origin),
                       origin, weight);
    }

    /** Learn English $(D words) related to attribute.
     */
    Ln[] learnMto1(R, S)(Lang lang,
                         R words,
                         Role role,
                         S attribute,
                         Sense wordSense = Sense.unknown,
                         Sense attributeSense = Sense.noun,
                         NWeight weight = 0.5,
                         Origin origin = Origin.manual) if (isInputRange!R &&
                                                            (isSomeString!(ElementType!R)) &&
                                                            isSomeString!S)
    {
        return connectMto1(store(words, lang, wordSense, origin),
                           role,
                           store(attribute, lang, attributeSense, origin),
                           origin, weight);
    }

    Ln[] learnMto1Maybe(S)(Lang lang,
                           string wordsPath,
                           Role role,
                           S attribute,
                           Sense wordSense = Sense.unknown,
                           Sense attributeSense = Sense.noun,
                           NWeight weight = 0.5,
                           Origin origin = Origin.manual) if (isSomeString!S)
    {
        try
        {
            return learnMto1(lang,
                             rdT(wordsPath).splitter('\n').filter!(w => !w.empty),
                             role,
                             attribute,
                             wordSense,
                             attributeSense,
                             weight,
                             origin);
        }
        catch (std.file.FileException e)
        {
            return typeof(return).init; /* OK: If file doesn't exist */
        }
    }

    /** Learn English Emoticon.
     */
    Ln[] learnEnglishEmoticon(S)(S[] emoticons,
                                 S[] exprs,
                                 NWeight weight = 1.0,
                                 Sense sense = Sense.unknown,
                                 Origin origin = Origin.manual) if (isSomeString!S)
    {
        return connectMtoN(store(emoticons, Lang.any, Sense.unknown, origin),
                           Role(Rel.emoticonFor),
                           store(exprs, Lang.en, sense, origin),
                           origin, weight);
    }

    /** Learn English Computer Acronyms.
     */
    void learnEnglishComputerKnowledge()
    {
        // TODO Context: Computer
        learnEnglishAcronym(`IETF`, `Internet Engineering Task Force`, 0.9);
        learnEnglishAcronym(`RFC`, `Request For Comments`, 0.8);
        learnEnglishAcronym(`FYI`, `For Your Information`, 0.7);
        learnEnglishAcronym(`BCP`, `Best Current Practise`, 0.6);
        learnEnglishAcronym(`LGTM`, `Looks Good To Me`, 0.9);

        learnEnglishAcronym(`AJAX`, `Asynchronous Javascript And XML`, 1.0); // 5-star
        learnEnglishAcronym(`AJAX`, `Associação De Jogadores Amadores De Xadrez`, 0.5); // 1-star

        // TODO Context: (Orakel) Computer
        learnEnglishAcronym(`3NF`, `Third Normal Form`, 0.5);
        learnEnglishAcronym(`ACID`, `Atomicity, Consistency, Isolation, and Durability`, 0.5);
        learnEnglishAcronym(`ACL`, `Access Control List`, 0.5);
        learnEnglishAcronym(`ACLs`, `Access Control Lists`, 0.5);
        learnEnglishAcronym(`ADDM`, `Automatic Database Diagnostic Monitor`, 0.5);
        learnEnglishAcronym(`ADR`, `Automatic Diagnostic Repository`, 0.5);
        learnEnglishAcronym(`ASM`, `Automatic Storage Management`, 0.5);
        learnEnglishAcronym(`AWR`, `Automatic Workload Repository`, 0.5);
        learnEnglishAcronym(`AWT`, `Asynchronous WriteThrough`, 0.5);
        learnEnglishAcronym(`BGP`, `Basic Graph Pattern`, 0.5);
        learnEnglishAcronym(`BLOB`, `Binary Large Object`, 0.5);
        learnEnglishAcronym(`CBC`, `Cipher Block Chaining`, 0.5);
        learnEnglishAcronym(`CCA`, `Control Center Agent`, 0.5);
        learnEnglishAcronym(`CDATA`, `Character DATA`, 0.5);
        learnEnglishAcronym(`CDS`, `Cell Directory Services`, 0.5);
        learnEnglishAcronym(`CFS`, `Cluster File System`, 0.5);
        learnEnglishAcronym(`CIDR`, `Classless Inter-Domain Routing`, 0.5);
        learnEnglishAcronym(`CLOB`, `Character Large OBject`, 0.5);
        learnEnglishAcronym(`CMADMIN`, `Connection Manager Administration`, 0.5);
        learnEnglishAcronym(`CMGW`, `Connection Manager GateWay`, 0.5);
        learnEnglishAcronym(`COM`, `Component Object Model`, 0.8);
        learnEnglishAcronym(`CORBA`, `Common Object Request Broker API`, 0.8);
        learnEnglishAcronym(`CORE`, `Common Oracle Runtime Environment`, 0.3);
        learnEnglishAcronym(`CRL`, `certificate revocation list`, 0.5);
        learnEnglishAcronym(`CRSD`, `Cluster Ready Services Daemon`, 0.5);
        learnEnglishAcronym(`CSS`, `Cluster Synchronization Services`, 0.5);
        learnEnglishAcronym(`CT`, `Code Template`, 0.2);
        learnEnglishAcronym(`CVU`, `Cluster Verification Utility`, 0.3);
        learnEnglishAcronym(`CWM`, `Common Warehouse Metadata`, 0.5);
        learnEnglishAcronym(`DAS`, `Direct Attached Storage`, 0.5);
        learnEnglishAcronym(`DBA`, `DataBase Administrator`, 0.5);
        learnEnglishAcronym(`DBMS`, `DataBase Management System`, 0.8);
        learnEnglishAcronym(`DBPITR`, `Database Point-In-Time Recovery`, 0.5);
        learnEnglishAcronym(`DBW`, `Database Writer`, 0.5);
        learnEnglishAcronym(`DCE`, `Distributed Computing Environment`, 0.3);
        learnEnglishAcronym(`DCOM`, `Distributed Component Object Model`, 0.7);
        learnEnglishAcronym(`DDL LCR`, `DDL Logical Change Record`, 0.5);
        learnEnglishAcronym(`DHCP`, `Dynamic Host Configuration Protocol`, 0.9);
        learnEnglishAcronym(`DICOM`, `Digital Imaging and Communications in Medicine`, 0.5);
        learnEnglishAcronym(`DIT`, `Directory Information Tree`, 0.5);
        learnEnglishAcronym(`DLL`, `Dynamic-Link Library`, 0.8);
        learnEnglishAcronym(`DN`, `Distinguished Name`, 0.5);
        learnEnglishAcronym(`DNS`, `Domain Name System`, 0.5);
        learnEnglishAcronym(`DOM`, `Document Object Model`, 0.6);
        learnEnglishAcronym(`DTD`, `Document Type Definition`, 0.8);
        learnEnglishAcronym(`DTP`, `Distributed Transaction Processing`, 0.5);
        learnEnglishAcronym(`Dnnn`, `Dispatcher Process`, 0.5);
        learnEnglishAcronym(`DoS`, `Denial-Of-Service`, 0.9);
        learnEnglishAcronym(`EJB`, `Enterprise JavaBean`, 0.5);
        learnEnglishAcronym(`EMCA`, `Enterprise Manager Configuration Assistant`, 0.5);
        learnEnglishAcronym(`ETL`, `Extraction, Transformation, and Loading`, 0.5);
        learnEnglishAcronym(`EVM`, `Event Manager`, 0.5);
        learnEnglishAcronym(`EVMD`, `Event Manager Daemon`, 0.5);
        learnEnglishAcronym(`FAN`, `Fast Application Notification`, 0.5);
        learnEnglishAcronym(`FIPS`, `Federal Information Processing Standard`, 0.5);
        learnEnglishAcronym(`GAC`, `Global Assembly Cache`, 0.5);
        learnEnglishAcronym(`GCS`, `Global Cache Service`, 0.5);
        learnEnglishAcronym(`GDS`, `Global Directory Service`, 0.5);
        learnEnglishAcronym(`GES`, `Global Enqueue Service`, 0.5);
        learnEnglishAcronym(`GIS`, `Geographic Information System`, 0.5);
        learnEnglishAcronym(`GNS`, `Grid Naming Service`, 0.5);
        learnEnglishAcronym(`GNSD`, `Grid Naming Service Daemon`, 0.5);
        learnEnglishAcronym(`GPFS`, `General Parallel File System`, 0.5);
        learnEnglishAcronym(`GSD`, `Global Services Daemon`, 0.5);
        learnEnglishAcronym(`GV$`, `global dynamic performance views`, 0.5);
        learnEnglishAcronym(`HACMP`, `High Availability Cluster Multi-Processing`, 0.5);
        learnEnglishAcronym(`HBA`, `Host Bus Adapter`, 0.5);
        learnEnglishAcronym(`IDE`, `Integrated Development Environment`, 0.5);
        learnEnglishAcronym(`IPC`, `Interprocess Communication`, 0.5);
        learnEnglishAcronym(`IPv4`, `IP Version 4`, 0.5);
        learnEnglishAcronym(`IPv6`, `IP Version 6`, 0.5);
        learnEnglishAcronym(`ITL`, `Interested Transaction List`, 0.5);
        learnEnglishAcronym(`J2EE`, `Java 2 Platform, Enterprise Edition`, 0.5);
        learnEnglishAcronym(`JAXB`, `Java Architecture for XML Binding`, 0.5);
        learnEnglishAcronym(`JAXP`, `Java API for XML Processing`, 0.5);
        learnEnglishAcronym(`JDBC`, `Java Database Connectivity`, 0.5);
        learnEnglishAcronym(`JDK`, `Java Developer's Kit`, 0.5);
        learnEnglishAcronym(`JNDI`,`Java Naming and Directory Interface`, 0.5);
        learnEnglishAcronym(`JRE`,`Java Runtime Environment`, 0.5);
        learnEnglishAcronym(`JSP`,`JavaServer Pages`, 0.5);
        learnEnglishAcronym(`JSR`,`Java Specification Request`, 0.5);
        learnEnglishAcronym(`JVM`,`Java Virtual Machine`, 0.8);
        learnEnglishAcronym(`KDC`,`Key Distribution Center`, 0.5);
        learnEnglishAcronym(`KWIC`, `Key Word in Context`, 0.5);
        learnEnglishAcronym(`LCR`, `Logical Change Record`, 0.5);
        learnEnglishAcronym(`LDAP`, `Lightweight Directory Access Protocol`, 0.5);
        learnEnglishAcronym(`LDIF`, `Lightweight Directory Interchange Format`, 0.5);
        learnEnglishAcronym(`LGWR`, `LoG WRiter`, 0.5);
        learnEnglishAcronym(`LMD`, `Global Enqueue Service Daemon`, 0.5);
        learnEnglishAcronym(`LMON`, `Global Enqueue Service Monitor`, 0.5);
        learnEnglishAcronym(`LMSn`, `Global Cache Service Processes`, 0.5);
        learnEnglishAcronym(`LOB`, `Large OBject`, 0.5);
        learnEnglishAcronym(`LOBs`, `Large Objects`, 0.5);
        learnEnglishAcronym(`LRS Segment`, `Geometric Segment`, 0.5);
        learnEnglishAcronym(`LUN`, `Logical Unit Number`, 0.5);
        learnEnglishAcronym(`LUNs`, `Logical Unit Numbers`, 0.5);
        learnEnglishAcronym(`LVM`, `Logical Volume Manager`, 0.5);
        learnEnglishAcronym(`MAPI`, `Messaging Application Programming Interface`, 0.5);
        learnEnglishAcronym(`MBR`, `Master Boot Record`, 0.5);
        learnEnglishAcronym(`MS DTC`, `Microsoft Distributed Transaction Coordinator`, 0.5);
        learnEnglishAcronym(`MTTR`, `Mean Time To Recover`, 0.5);
        learnEnglishAcronym(`NAS`, `Network Attached Storage`, 0.5);
        learnEnglishAcronym(`NCLOB`, `National Character Large Object`, 0.5);
        learnEnglishAcronym(`NFS`, `Network File System`, 0.5);
        learnEnglishAcronym(`NI`, `Network Interface`, 0.5);
        learnEnglishAcronym(`NIC`, `Network Interface Card`, 0.5);
        learnEnglishAcronym(`NIS`, `Network Information Service`, 0.5);
        learnEnglishAcronym(`NIST`, `National Institute of Standards and Technology`, 0.5);
        learnEnglishAcronym(`NPI`, `Network Program Interface`, 0.5);
        learnEnglishAcronym(`NS`, `Network Session`, 0.5);
        learnEnglishAcronym(`NTP`, `Network Time Protocol`, 0.5);
        learnEnglishAcronym(`OASIS`, `Organization for the Advancement of Structured Information`, 0.5);
        learnEnglishAcronym(`OCFS`, `Oracle Cluster File System`, 0.5);
        learnEnglishAcronym(`OCI`, `Oracle Call Interface`, 0.5);
        learnEnglishAcronym(`OCR`, `Oracle Cluster Registry`, 0.5);
        learnEnglishAcronym(`ODBC`, `Open Database Connectivity`, 0.5);
        learnEnglishAcronym(`ODBC INI`, `ODBC Initialization File`, 0.5);
        learnEnglishAcronym(`ODP NET`, `Oracle Data Provider for .NET`, 0.5);
        learnEnglishAcronym(`OFA`, `optimal flexible architecture`, 0.5);
        learnEnglishAcronym(`OHASD`, `Oracle High Availability Services Daemon`, 0.5);
        learnEnglishAcronym(`OIFCFG`, `Oracle Interface Configuration Tool`, 0.5);
        learnEnglishAcronym(`OLM`, `Object Link Manager`, 0.5);
        learnEnglishAcronym(`OLTP`, `online transaction processing`, 0.5);
        learnEnglishAcronym(`OMF`, `Oracle Managed Files`, 0.5);
        learnEnglishAcronym(`ONS`, `Oracle Notification Services`, 0.5);
        learnEnglishAcronym(`OO4O`, `Oracle Objects for OLE`, 0.5);
        learnEnglishAcronym(`OPI`, `Oracle Program Interface`, 0.5);
        learnEnglishAcronym(`ORDBMS`, `object-relational database management system`, 0.5);
        learnEnglishAcronym(`OSI`, `Open Systems Interconnection`, 0.5);
        learnEnglishAcronym(`OUI`, `Oracle Universal Installer`, 0.5);
        learnEnglishAcronym(`OraMTS`, `Oracle Services for Microsoft Transaction Server`, 0.5);
        learnEnglishAcronym(`ASM`, `Automatic Storage Management`, 0.5);
        learnEnglishAcronym(`RAC`, `Real Application Clusters`, 0.5);
        learnEnglishAcronym(`PCDATA`, `Parsed Character Data`, 0.5);
        learnEnglishAcronym(`PGA`, `Program Global Area`, 0.5);
        learnEnglishAcronym(`PKI`, `Public Key Infrastructure`, 0.5);
        learnEnglishAcronym(`RAID`, `Redundant Array of Inexpensive Disks`, 0.5);
        learnEnglishAcronym(`RDBMS`, `Relational Database Management System`, 0.5);
        learnEnglishAcronym(`RDN`, `Relative Distinguished Name`, 0.5);
        learnEnglishAcronym(`RM`, `Resource Manager`, 0.5);
        learnEnglishAcronym(`RMAN`, `Recovery Manager`, 0.5);
        learnEnglishAcronym(`ROI`, `Return On Investment`, 0.5);
        learnEnglishAcronym(`RPO`, `Recovery Point Objective`, 0.5);
        learnEnglishAcronym(`RTO`, `Recovery Time Objective`, 0.5);
        learnEnglishAcronym(`SAN`, `Storage Area Network`, 0.5);
        learnEnglishAcronym(`SAX`, `Simple API for XML`, 0.5);
        learnEnglishAcronym(`SCAN`, `Single Client Access Name`, 0.5);
        learnEnglishAcronym(`SCN`, `System Change Number`, 0.5);
        learnEnglishAcronym(`SCSI`, `Small Computer System Interface`, 0.5);
        learnEnglishAcronym(`SDU`, `Session Data Unit`, 0.5);
        learnEnglishAcronym(`SGA`, `System Global Area`, 0.5);
        learnEnglishAcronym(`SGML`, `Structured Generalized Markup Language`, 0.5);
        learnEnglishAcronym(`SHA`, `Secure Hash Algorithm`, 0.5);
        learnEnglishAcronym(`SID`, `System IDentifier`, 0.5);
        learnEnglishAcronym(`SKOS`, `Simple Knowledge Organization System`, 0.5);
        learnEnglishAcronym(`SOA`, `Service-Oriented Architecture`, 0.5);
        learnEnglishAcronym(`SOAP`, `Simple Object Access Protocol`, 0.5);
        learnEnglishAcronym(`SOP`, `Service Object Pair`, 0.5);
        learnEnglishAcronym(`SQL`, `Structured Query Language`, 0.5);
        learnEnglishAcronym(`SRVCTL`, `Server Control`, 0.5);
        learnEnglishAcronym(`SSH`, `Secure Shell`, 0.5);
        learnEnglishAcronym(`SSL`, `Secure Sockets Layer`, 0.5);
        learnEnglishAcronym(`SSO`, `Single Sign-On`, 0.5);
        learnEnglishAcronym(`STS`, `Sql Tuning Set`, 0.5);
        learnEnglishAcronym(`SWT`, `Synchronous WriteThrough`, 0.5);
        learnEnglishAcronym(`TAF`, `Transparent Application Failover`, 0.5);
        learnEnglishAcronym(`TCO`, `Total Cost of Ownership`, 0.5);
        learnEnglishAcronym(`TNS`, `Transparent Network Substrate`, 0.5);
        learnEnglishAcronym(`TSPITR`, `Tablespace Point-In-Time Recovery`, 0.5);
        learnEnglishAcronym(`TTC`, `Two-Task Common`, 0.5);
        learnEnglishAcronym(`UGA`, `User Global Area`, 0.5);
        learnEnglishAcronym(`UID`, `Unique IDentifier`, 0.5);
        learnEnglishAcronym(`UIX`, `User Interface XML`, 0.5);
        learnEnglishAcronym(`UNC`, `Universal Naming Convention`, 0.5);
        learnEnglishAcronym(`UTC`, `Coordinated Universal Time`, 0.5);
        learnEnglishAcronym(`VPD`, `Virtual Private Database`, 0.5);
        learnEnglishAcronym(`VSS`, `Volume Shadow Copy Service`, 0.5);
        learnEnglishAcronym(`W3C`, `World Wide Web Consortium`, 0.5);
        learnEnglishAcronym(`WG`, `Working Group`, 0.5);
        learnEnglishAcronym(`WebDAV`, `World Wide Web Distributed Authoring and Versioning`, 0.5);
        learnEnglishAcronym(`Winsock`, `Windows sockets`, 0.5);
        learnEnglishAcronym(`XDK`, `XML Developer's Kit`, 0.5);
        learnEnglishAcronym(`XIDs`,`Transaction Identifiers`, 0.5);
        learnEnglishAcronym(`XML`,`eXtensible Markup Language`, 0.5);
        learnEnglishAcronym(`XQuery`,`XML Query`, 0.5);
        learnEnglishAcronym(`XSL`,`eXtensible Stylesheet Language`, 0.5);
        learnEnglishAcronym(`XSLFO`, `eXtensible Stylesheet Language Formatting Object`, 0.5);
        learnEnglishAcronym(`XSLT`, `eXtensible Stylesheet Language Transformation`, 0.5);
        learnEnglishAcronym(`XSU`, `XML SQL Utility`, 0.5);
        learnEnglishAcronym(`XVM`, `XSLT Virtual Machine`, 0.5);
        learnEnglishAcronym(`Approximate CSCN`, `Approximate Commit System Change Number`, 0.5);
        learnEnglishAcronym(`mDNS`, `Multicast Domain Name Server`, 0.5);
        learnEnglishAcronym(`row LCR`, `Row Logical Change Record`, 0.5);

        /* Use: atLocation (US) */

        /* Context: Non-animal methods for toxicity testing */

        learnEnglishAcronym(`3D`,`three dimensional`, 0.9);
        learnEnglishAcronym(`3RS`,`Replacement, Reduction, Refinement`, 0.5);
        learnEnglishAcronym(`AALAS`,`American Association for Laboratory Animal Science`, 0.8);
        learnEnglishAcronym(`ADI`,`Acceptable Daily Intake [human]`, 0.6);
        learnEnglishAcronym(`AFIP`,`Armed Forces Institute of Pathology`, 0.6);
        learnEnglishAcronym(`AHI`,`Animal Health Institute (US)`, 0.5);
        learnEnglishAcronym(`AIDS`,`Acquired Immune Deficiency Syndrome`, 0.95);
        learnEnglishAcronym(`ANDA`,`Abbreviated New Drug Application (US FDA)`, 0.5);
        learnEnglishAcronym(`AOP`,`Adverse Outcome Pathway`, 0.5);
        learnEnglishAcronym(`APHIS`,`Animal and Plant Health Inspection Service (USDA)`, 0.9);
        learnEnglishAcronym(`ARDF`,`Alternatives Research and Development Foundation`, 0.5);
        learnEnglishAcronym(`ATLA`,`Alternatives to Laboratory Animals`, 0.5);
        learnEnglishAcronym(`ATSDR`,`Agency for Toxic Substances and Disease Registry (US CDC)`, 0.5);
        learnEnglishAcronym(`BBMO`,`Biosensors Based on Membrane Organization to Replace Animal Testing`, 0.5);
        learnEnglishAcronym(`BCOP`,`Bovine Corneal Opacity and Permeability assay`, 0.5);
        learnEnglishAcronym(`BFR`,`German Federal Institute for Risk Assessment`, 0.5);
        learnEnglishAcronym(`BLA`,`Biological License Application (US FDA)`, 0.5);
        learnEnglishAcronym(`BRD`,`Background Review Document (ICCVAM)`, 0.5);
        learnEnglishAcronym(`BSC`,`Board of Scientific Counselors (US NTP)`, 0.5);
        learnEnglishAcronym(`BSE`,`Bovine Spongiform Encephalitis`, 0.5);
        learnEnglishAcronym(`CAAI`,`University of California Center for Animal Alternatives Information`, 0.5);
        learnEnglishAcronym(`CAAT`,`Johns Hopkins Center for Alternatives to Animal Testing`, 0.5);
        learnEnglishAcronym(`CAMVA`,`Chorioallantoic Membrane Vascularization Assay`, 0.5);
        learnEnglishAcronym(`CBER`,`Center for Biologics Evaluation and Research (US FDA)`, 0.5);
        learnEnglishAcronym(`CDC`,`Centers for Disease Control and Prevention (US)`, 0.5);
        learnEnglishAcronym(`CDER`,`Center for Drug Evaluation and Research (US FDA)`, 0.5);
        learnEnglishAcronym(`CDRH`,`Center for Devices and Radiological Health (US FDA)`, 0.5);
        learnEnglishAcronym(`CERHR`,`Center for the Evaluation of Risks to Human Reproduction (US NTP)`, 0.5);
        learnEnglishAcronym(`CFR`,`Code of Federal Regulations (US)`, 0.5);
        learnEnglishAcronym(`CFSAN`,`Center for Food Safety and Applied Nutrition (US FDA)`, 0.5);
        learnEnglishAcronym(`CHMP`,`Committees for Medicinal Products for Human Use`, 0.5);
        learnEnglishAcronym(`CMR`,`Carcinogenic, Mutagenic and Reprotoxic`, 0.5);
        learnEnglishAcronym(`CO2`,`Carbon Dioxide`, 0.5);
        learnEnglishAcronym(`COLIPA`,`European Cosmetic Toiletry & Perfumery Association`, 0.5);
        learnEnglishAcronym(`COMP`,`Committee for Orphan Medicinal Products`, 0.5);
        learnEnglishAcronym(`CORDIS`,`Community Research & Development Information Service`, 0.5);
        learnEnglishAcronym(`CORRELATE`,`European Reference Laboratory for Alternative Tests`, 0.5);
        learnEnglishAcronym(`CPCP`,`Chemical Prioritization Community of Practice (US EPA)`, 0.5);
        learnEnglishAcronym(`CPSC`,`Consumer Product Safety Commission (US)`, 0.5);
        learnEnglishAcronym(`CTA`,`Cell Transformation Assays`, 0.5);
        learnEnglishAcronym(`CVB`,`Center for Veterinary Biologics (USDA)`, 0.5);
        learnEnglishAcronym(`CVM`,`Center for Veterinary Medicine (US FDA)`, 0.5);
        learnEnglishAcronym(`CVMP`,`Committee for Medicinal Products for Veterinary Use`, 0.5);
        learnEnglishAcronym(`DARPA`,`Defense Advanced Research Projects Agency (US)`, 0.5);
        learnEnglishAcronym(`DG`,`Directorate General`, 0.5);
        learnEnglishAcronym(`DOD`,`Department of Defense (US)`, 0.5);
        learnEnglishAcronym(`DOT`,`Department of Transportation (US)`, 0.5);
        learnEnglishAcronym(`DRP`,`Detailed Review Paper (OECD)`, 0.5);
        learnEnglishAcronym(`EC`,`European Commission`, 0.5);
        learnEnglishAcronym(`ECB`,`European Chemicals Bureau`, 0.5);
        learnEnglishAcronym(`ECHA`,`European Chemicals Agency`, 0.5);
        learnEnglishAcronym(`ECOPA`,`European Consensus Platform for Alternatives`, 0.5);
        learnEnglishAcronym(`ECVAM`,`European Centre for the Validation of Alternative Methods`, 0.5);
        learnEnglishAcronym(`ED`,`Endocrine Disrupters`, 0.5);
        learnEnglishAcronym(`EDQM`,`European Directorate for Quality of Medicines & HealthCare`, 0.5);
        learnEnglishAcronym(`EEC`,`European Economic Commission`, 0.5);
        learnEnglishAcronym(`EFPIA`,`European Federation of Pharmaceutical Industries and Associations`, 0.5);
        learnEnglishAcronym(`EFSA`,`European Food Safety Authority`, 0.5);
        learnEnglishAcronym(`EFSAPPR`,`European Food Safety Authority Panel on plant protection products and their residues`, 0.5);
        learnEnglishAcronym(`EFTA`,`European Free Trade Association`, 0.5);
        learnEnglishAcronym(`ELINCS`,`European List of Notified Chemical Substances`, 0.5);
        learnEnglishAcronym(`ELISA`,`Enzyme-Linked ImmunoSorbent Assay`, 0.5);
        learnEnglishAcronym(`EMEA`,`European Medicines Agency`, 0.5);
        learnEnglishAcronym(`ENVI`,`European Parliament Committee on the Environment, Public Health and Food Safety`, 0.5);
        learnEnglishAcronym(`EO`,`Executive Orders (US)`, 0.5);
        learnEnglishAcronym(`EPA`,`Environmental Protection Agency (US)`, 0.5);
        learnEnglishAcronym(`EPAA`,`European Partnership for Alternative Approaches to Animal Testing`, 0.5);
        learnEnglishAcronym(`ESACECVAM`,`Scientific Advisory Committee (EU)`, 0.5);
        learnEnglishAcronym(`ESOCOC`,`Economic and Social Council (UN)`, 0.5);
        learnEnglishAcronym(`EU`,`European Union`, 0.5);
        learnEnglishAcronym(`EURL`,`ECVAM European Union Reference Laboratory on Alternatives to Animal Testing`, 0.5);
        learnEnglishAcronym(`EWG`,`Expert Working group`, 0.5);

        learnEnglishAcronym(`FAO`,`Food and Agriculture Organization of the United Nations`, 0.5);
        learnEnglishAcronym(`FDA`,`Food and Drug Administration (US)`, 0.5);
        learnEnglishAcronym(`FFDCA`,`Federal Food, Drug, and Cosmetic Act (US)`, 0.5);
        learnEnglishAcronym(`FHSA`,`Federal Hazardous Substances Act (US)`, 0.5);
        learnEnglishAcronym(`FIFRA`,`Federal Insecticide, Fungicide, and Rodenticide Act (US)`, 0.5);
        learnEnglishAcronym(`FP`,`Framework Program`, 0.5);
        learnEnglishAcronym(`FRAME`,`Fund for the Replacement of Animals in Medical Experiments`, 0.5);
        learnEnglishAcronym(`GCCP`,`Good Cell Culture Practice`, 0.5);
        learnEnglishAcronym(`GCP`,`Good Clinical Practice`, 0.5);
        learnEnglishAcronym(`GHS`,`Globally Harmonized System for Classification and Labeling of Chemicals`, 0.5);
        learnEnglishAcronym(`GJIC`,`Gap Junction Intercellular Communication [assay]`, 0.5);
        learnEnglishAcronym(`GLP`,`Good Laboratory Practice`, 0.5);
        learnEnglishAcronym(`GMO`,`Genetically Modified Organism`, 0.5);
        learnEnglishAcronym(`GMP`,`Good Manufacturing Practice`, 0.5);
        learnEnglishAcronym(`GPMT`,`Guinea Pig Maximization Test`, 0.5);
        learnEnglishAcronym(`HCE`,`Human corneal epithelial cells`, 0.5);
        learnEnglishAcronym(`HCE`,`T Human corneal epithelial cells`, 0.5);
        learnEnglishAcronym(`HESI`,`ILSI Health and Environmental Sciences Institute`, 0.5);
        learnEnglishAcronym(`HET`,`CAM Hen’s Egg Test – Chorioallantoic Membrane assay`, 0.5);
        learnEnglishAcronym(`HHS`,`Department of Health and Human Services (US)`, 0.5);
        learnEnglishAcronym(`HIV`,`Human Immunodeficiency Virus`, 0.5);
        learnEnglishAcronym(`HMPC`,`Committee on Herbal Medicinal Products`, 0.5);
        learnEnglishAcronym(`HPV`,`High Production Volume`, 0.5);
        learnEnglishAcronym(`HSUS`,`The Humane Society of the United States`, 0.5);
        learnEnglishAcronym(`HTS`,`High Throughput Screening`, 0.5);
        learnEnglishAcronym(`HGP`,`Human Genome Project`, 0.5);
        learnEnglishAcronym(`IARC`,`International Agency for Research on Cancer (WHO)`, 0.5);
        learnEnglishAcronym(`ICAPO`,`International Council for Animal Protection in OECD`, 0.5);
        learnEnglishAcronym(`ICCVAM`,`Interagency Coordinating Committee on the Validation of Alternative Methods (US)`, 0.5);
        learnEnglishAcronym(`ICE`,`Isolated Chicken Eye`, 0.5);
        learnEnglishAcronym(`ICH`,`International Conference on Harmonization of Technical Requirements for Registration of Pharmaceuticals for Human Use`, 0.5);
        learnEnglishAcronym(`ICSC`,`International Chemical Safety Cards`, 0.5);
        learnEnglishAcronym(`IFAH`,`EUROPE International Federation for Animal Health Europe`, 0.5);
        learnEnglishAcronym(`IFPMA`,`International Federation of Pharmaceutical Manufacturers & Associations`, 0.5);
        learnEnglishAcronym(`IIVS`,`Institute for In Vitro Sciences`, 0.5);
        learnEnglishAcronym(`ILAR`,`Institute for Laboratory Animal Research`, 0.5);
        learnEnglishAcronym(`ILO`,`International Labour Organization`, 0.5);
        learnEnglishAcronym(`ILSI`,`International Life Sciences Institute`, 0.5);
        learnEnglishAcronym(`IND`,`Investigational New Drug (US FDA)`, 0.5);
        learnEnglishAcronym(`INVITROM`,`International Society for In Vitro Methods`, 0.5);
        learnEnglishAcronym(`IOMC`,`Inter-Organization Programme for the Sound Management of Chemicals (WHO)`, 0.5);
        learnEnglishAcronym(`IPCS`,`International Programme on Chemical Safety (WHO)`, 0.5);
        learnEnglishAcronym(`IQF`,`International QSAR Foundation to Reduce Animal Testing`, 0.5);
        learnEnglishAcronym(`IRB`,`Institutional review board`, 0.5);
        learnEnglishAcronym(`IRE`,`Isolated rabbit eye`, 0.5);
        learnEnglishAcronym(`IWG`,`Immunotoxicity Working Group (ICCVAM)`, 0.5);
        learnEnglishAcronym(`JACVAM`,`Japanese Center for the Validation of Alternative Methods`, 0.5);
        learnEnglishAcronym(`JAVB`,`Japanese Association of Veterinary Biologics`, 0.5);
        learnEnglishAcronym(`JECFA`,`Joint FAO/WHO Expert Committee on Food Additives`, 0.5);
        learnEnglishAcronym(`JMAFF`,`Japanese Ministry of Agriculture, Forestry and Fisheries`, 0.5);
        learnEnglishAcronym(`JPMA`,`Japan Pharmaceutical Manufacturers Association`, 0.5);
        learnEnglishAcronym(`JRC`,`Joint Research Centre (EU)`, 0.5);
        learnEnglishAcronym(`JSAAE`,`Japanese Society for Alternatives to Animal Experiments`, 0.5);
        learnEnglishAcronym(`JVPA`,`Japanese Veterinary Products Association`, 0.5);

        learnEnglishAcronym(`KOCVAM`,`Korean Center for the Validation of Alternative Method`, 0.5);
        learnEnglishAcronym(`LIINTOP`,`Liver Intestine Optimization`, 0.5);
        learnEnglishAcronym(`LLNA`,`Local Lymph Node Assay`, 0.5);
        learnEnglishAcronym(`MAD`,`Mutual Acceptance of Data (OECD)`, 0.5);
        learnEnglishAcronym(`MEIC`,`Multicenter Evaluation of In Vitro Cytotoxicity`, 0.5);
        learnEnglishAcronym(`MEMOMEIC`,`Monographs on Time-Related Human Lethal Blood Concentrations`, 0.5);
        learnEnglishAcronym(`MEPS`,`Members of the European Parliament`, 0.5);
        learnEnglishAcronym(`MG`,`Milligrams [a unit of weight]`, 0.5);
        learnEnglishAcronym(`MHLW`,`Ministry of Health, Labour and Welfare (Japan)`, 0.5);
        learnEnglishAcronym(`MLI`,`Molecular Libraries Initiative (US NIH)`, 0.5);
        learnEnglishAcronym(`MSDS`,`Material Safety Data Sheets`, 0.5);

        learnEnglishAcronym(`MW`,`Molecular Weight`, 0.5);
        learnEnglishAcronym(`NC3RSUK`,`National Center for the Replacement, Refinement and Reduction of Animals in Research`, 0.5);
        learnEnglishAcronym(`NKCA`,`Netherlands Knowledge Centre on Alternatives to animal use`, 0.5);
        learnEnglishAcronym(`NCBI`,`National Center for Biotechnology Information (US)`, 0.5);
        learnEnglishAcronym(`NCEH`,`National Center for Environmental Health (US CDC)`, 0.5);
        learnEnglishAcronym(`NCGCNIH`,`Chemical Genomics Center (US)`, 0.5);
        learnEnglishAcronym(`NCI`,`National Cancer Institute (US NIH)`, 0.5);
        learnEnglishAcronym(`NCPDCID`,`National Center for Preparedness, Detection and Control of Infectious Diseases`, 0.5);
        learnEnglishAcronym(`NCCT`,`National Center for Computational Toxicology (US EPA)`, 0.5);
        learnEnglishAcronym(`NCTR`,`National Center for Toxicological Research (US FDA)`, 0.5);
        learnEnglishAcronym(`NDA`,`New Drug Application (US FDA)`, 0.5);
        learnEnglishAcronym(`NGO`,`Non-Governmental Organization`, 0.5);
        learnEnglishAcronym(`NIAID`,`National Institute of Allergy and Infectious Diseases`, 0.5);
        learnEnglishAcronym(`NICA`,`Nordic Information Center for Alternative Methods`, 0.5);
        learnEnglishAcronym(`NICEATM`,`National Toxicology Program Interagency Center for Evaluation of Alternative Toxicological Methods (US)`, 0.5);
        learnEnglishAcronym(`NIEHS`,`National Institute of Environmental Health Sciences (US NIH)`, 0.5);
        learnEnglishAcronym(`NIH`,`National Institutes of Health (US)`, 0.5);
        learnEnglishAcronym(`NIHS`,`National Institute of Health Sciences (Japan)`, 0.5);
        learnEnglishAcronym(`NIOSH`,`National Institute for Occupational Safety and Health (US CDC)`, 0.5);
        learnEnglishAcronym(`NITR`,`National Institute of Toxicological Research (Korea)`, 0.5);
        learnEnglishAcronym(`NOAEL`,`Nd-Observed Adverse Effect Level`, 0.5);
        learnEnglishAcronym(`NOEL`,`Nd-Observed Effect Level`, 0.5);
        learnEnglishAcronym(`NPPTAC`,`National Pollution Prevention and Toxics Advisory Committee (US EPA)`, 0.5);
        learnEnglishAcronym(`NRC`,`National Research Council`, 0.5);
        learnEnglishAcronym(`NTP`,`National Toxicology Program (US)`, 0.5);
        learnEnglishAcronym(`OECD`,`Organisation for Economic Cooperation and Development`, 0.5);
        learnEnglishAcronym(`OMCLS`,`Official Medicines Control Laboratories`, 0.5);
        learnEnglishAcronym(`OPPTS`,`Office of Prevention, Pesticides and Toxic Substances (US EPA)`, 0.5);
        learnEnglishAcronym(`ORF`,`open reading frame`, 0.5);
        learnEnglishAcronym(`OSHA`,`Occupational Safety and Health Administration (US)`, 0.5);
        learnEnglishAcronym(`OSIRIS`,`Optimized Strategies for Risk Assessment of Industrial Chemicals through the Integration of Non-test and Test Information`, 0.5);
        learnEnglishAcronym(`OT`,`Cover-the-counter [drug]`, 0.5);

        learnEnglishAcronym(`PBPK`,`Physiologically-Based Pharmacokinetic (modeling)`, 0.5);
        learnEnglishAcronym(`P&G`,` Procter & Gamble`, 0.5);
        learnEnglishAcronym(`PHRMA`,`Pharmaceutical Research and Manufacturers of America`, 0.5);
        learnEnglishAcronym(`PL`,`Public Law`, 0.5);
        learnEnglishAcronym(`POPS`,`Persistent Organic Pollutants`, 0.5);
        learnEnglishAcronym(`QAR`, `Quantitative Structure Activity Relationship`, 0.5);
        learnEnglishAcronym(`QSM`,`Quality, Safety and Efficacy of Medicines (WHO)`, 0.5);
        learnEnglishAcronym(`RA`,`Regulatory Acceptance`, 0.5);
        learnEnglishAcronym(`REACH`,`Registration, Evaluation, Authorization and Restriction of Chemicals`, 0.5);
        learnEnglishAcronym(`RHE`,`Reconstructed Human Epidermis`, 0.5);
        learnEnglishAcronym(`RIPSREACH`,`Implementation Projects`, 0.5);
        learnEnglishAcronym(`RNAI`,`RNA Interference`, 0.5);
        learnEnglishAcronym(`RLLNA`,`Reduced Local Lymph Node Assay`, 0.5);
        learnEnglishAcronym(`SACATM`,`Scientific Advisory Committee on Alternative Toxicological Methods (US)`, 0.5);
        learnEnglishAcronym(`SAICM`,`Strategic Approach to International Chemical Management (WHO)`, 0.5);
        learnEnglishAcronym(`SANCO`,`Health and Consumer Protection Directorate General`, 0.5);
        learnEnglishAcronym(`SCAHAW`,`Scientific Committee on Animal Health and Animal Welfare`, 0.5);
        learnEnglishAcronym(`SCCP`,`Scientific Committee on Consumer Products`, 0.5);
        learnEnglishAcronym(`SCENIHR`,`Scientific Committee on Emerging and Newly Identified Health Risks`, 0.5);
        learnEnglishAcronym(`SCFCAH`,`Standing Committee on the Food Chain and Animal Health`, 0.5);
        learnEnglishAcronym(`SCHER`,`Standing Committee on Health and Environmental Risks`, 0.5);
        learnEnglishAcronym(`SEPS`,`Special Emphasis Panels (US NTP)`, 0.5);
        learnEnglishAcronym(`SIDS`,`Screening Information Data Sets`, 0.5);
        learnEnglishAcronym(`SOT`,`Society of Toxicology`, 0.5);
        learnEnglishAcronym(`SPORT`,`Strategic Partnership on REACH Testing`, 0.5);
        learnEnglishAcronym(`TBD`,`To Be Determined`, 0.5);
        learnEnglishAcronym(`TDG`,`Transport of Dangerous Goods (UN committee)`, 0.5);
        learnEnglishAcronym(`TER`,`Transcutaneous Electrical Resistance`, 0.5);
        learnEnglishAcronym(`TEWG`,`Technical Expert Working Group`, 0.5);
        learnEnglishAcronym(`TG`,`Test Guideline (OECD)`, 0.5);
        learnEnglishAcronym(`TOBI`,`Toxin Binding Inhibition`, 0.5);
        learnEnglishAcronym(`TSCA`,`Toxic Substances Control Act (US)`, 0.5);
        learnEnglishAcronym(`TTC`,`Threshold of Toxicological Concern`, 0.5);

        learnEnglishAcronym(`UC`,`University of California`, 0.5);
        learnEnglishAcronym(`UCD`,`University of California Davis`, 0.5);
        learnEnglishAcronym(`UK`,`United Kingdom`, 0.5);
        learnEnglishAcronym(`UN`,`United Nations`, 0.5);
        learnEnglishAcronym(`UNECE`,`United Nations Economic Commission for Europe`, 0.5);
        learnEnglishAcronym(`UNEP`,`United Nations Environment Programme`, 0.5);
        learnEnglishAcronym(`UNITAR`,`United Nations Institute for Training and Research`, 0.5);
        learnEnglishAcronym(`USAMRICD`,`US Army Medical Research Institute of Chemical Defense`, 0.5);
        learnEnglishAcronym(`USAMRIID`,`US Army Medical Research Institute of Infectious Diseases`, 0.5);
        learnEnglishAcronym(`USAMRMC`,`US Army Medical Research and Material Command`, 0.5);
        learnEnglishAcronym(`USDA`,`United States Department of Agriculture`, 0.5);
        learnEnglishAcronym(`USUHS`,`Uniformed Services University of the Health Sciences`, 0.5);
        learnEnglishAcronym(`UV`,`ultraviolet`, 0.5);
        learnEnglishAcronym(`VCCEP`,`Voluntary Children’s Chemical Evaluation Program (US EPA)`, 0.5);
        learnEnglishAcronym(`VICH`,`International Cooperation on Harmonization of Technical Requirements for Registration of Veterinary Products`, 0.5);
        learnEnglishAcronym(`WHO`,`World Health Organization`, 0.5);
        learnEnglishAcronym(`WRAIR`,`Walter Reed Army Institute of Research`, 0.5);
        learnEnglishAcronym(`ZEBET`,`Centre for Documentation and Evaluation of Alternative Methods to Animal Experiments (Germany)`, 0.5);

        // TODO Context: Digital Communications
    	learnEnglishAcronym(`AAMOF`, `as a matter of fact`, 0.5);
	learnEnglishAcronym(`ABFL`, `a big fat lady`, 0.5);
	learnEnglishAcronym(`ABT`, `about`, 0.5);
	learnEnglishAcronym(`ADN`, `any day now`, 0.5);
	learnEnglishAcronym(`AFAIC`, `as far as I’m concerned`, 0.5);
	learnEnglishAcronym(`AFAICT`, `as far as I can tell`, 0.5);
	learnEnglishAcronym(`AFAICS`, `as far as I can see`, 0.5);
	learnEnglishAcronym(`AFAIK`, `as far as I know`, 0.5);
	learnEnglishAcronym(`AFAYC`, `as far as you’re concerned`, 0.5);
	learnEnglishAcronym(`AFK`, `away from keyboard`, 0.5);
	learnEnglishAcronym(`AH`, `asshole`, 0.5);
	learnEnglishAcronym(`AISI`, `as I see it`, 0.5);
	learnEnglishAcronym(`AIUI`, `as I understand it`, 0.5);
	learnEnglishAcronym(`AKA`, `also known as`, 0.5);
	learnEnglishAcronym(`AML`, `all my love`, 0.5);
	learnEnglishAcronym(`ANFSCD`, `and now for something completely different`, 0.5);
	learnEnglishAcronym(`ASAP`, `as soon as possible`, 0.5);
	learnEnglishAcronym(`ASL`, `assistant section leader`, 0.5);
	learnEnglishAcronym(`ASL`, `age, sex, location`, 0.5);
	learnEnglishAcronym(`ASLP`, `age, sex, location, picture`, 0.5);
	learnEnglishAcronym(`A/S/L`, `age/sex/location`, 0.5);
	learnEnglishAcronym(`ASOP`, `assistant system operator`, 0.5);
	learnEnglishAcronym(`ATM`, `at this moment`, 0.5);
	learnEnglishAcronym(`AWA`, `as well as`, 0.5);
	learnEnglishAcronym(`AWHFY`, `are we having fun yet?`, 0.5);
	learnEnglishAcronym(`AWGTHTGTTA`, `are we going to have to go trough this again?`, 0.5);
	learnEnglishAcronym(`AWOL`, `absent without leave`, 0.5);
	learnEnglishAcronym(`AWOL`, `away without leave`, 0.5);
	learnEnglishAcronym(`AYOR`, `at your own risk`, 0.5);
	learnEnglishAcronym(`AYPI`, `?	and your point is?`, 0.5);

	learnEnglishAcronym(`B4`, `before`, 0.5);
	learnEnglishAcronym(`BAC`, `back at computer`, 0.5);
	learnEnglishAcronym(`BAG`, `busting a gut`, 0.5);
	learnEnglishAcronym(`BAK`, `back at the keyboard`, 0.5);
	learnEnglishAcronym(`BBIAB`, `be back in a bit`, 0.5);
	learnEnglishAcronym(`BBL`, `be back later`, 0.5);
	learnEnglishAcronym(`BBLBNTSBO`, `be back later but not to soon because of`, 0.5);
	learnEnglishAcronym(`BBR`, `burnt beyond repair`, 0.5);
	learnEnglishAcronym(`BBS`, `be back soon`, 0.5);
	learnEnglishAcronym(`BBS`, `bulletin board system`, 0.5);
	learnEnglishAcronym(`BC`, `be cool`, 0.5);
	learnEnglishAcronym(`B`, `/C	because`, 0.5);
	learnEnglishAcronym(`BCnU`, `be seeing you`, 0.5);
	learnEnglishAcronym(`BEG`, `big evil grin`, 0.5);
	learnEnglishAcronym(`BF`, `boyfriend`, 0.5);
	learnEnglishAcronym(`B/F`, `boyfriend`, 0.5);
	learnEnglishAcronym(`BFN`, `bye for now`, 0.5);
	learnEnglishAcronym(`BG`, `big grin`, 0.5);
	learnEnglishAcronym(`BION`, `believe it or not`, 0.5);
	learnEnglishAcronym(`BIOYIOB`, `blow it out your I/O port`, 0.5);
	learnEnglishAcronym(`BITMT`, `but in the meantime`, 0.5);
	learnEnglishAcronym(`BM`, `bite me`, 0.5);
	learnEnglishAcronym(`BMB`, `bite my bum`, 0.5);
	learnEnglishAcronym(`BMTIPG`, `brilliant minds think in parallel gutters`, 0.5);
	learnEnglishAcronym(`BKA`, `better known as`, 0.5);
	learnEnglishAcronym(`BL`, `belly laughing`, 0.5);
	learnEnglishAcronym(`BOB`, `back off bastard`, 0.5);
	learnEnglishAcronym(`BOL`, `be on later`, 0.5);
	learnEnglishAcronym(`BOM`, `bitch of mine`, 0.5);
	learnEnglishAcronym(`BOT`, `back on topic`, 0.5);
	learnEnglishAcronym(`BRB`, `be right back`, 0.5);
	learnEnglishAcronym(`BRBB`, `be right back bitch`, 0.5);
	learnEnglishAcronym(`BRBS`, `be right back soon`, 0.5);
	learnEnglishAcronym(`BRH`, `be right here`, 0.5);
	learnEnglishAcronym(`BRS`, `big red switch`, 0.5);
	learnEnglishAcronym(`BS`, `big smile`, 0.5);
	learnEnglishAcronym(`BS`, `bull shit`, 0.5);
	learnEnglishAcronym(`BSF`, `but seriously folks`, 0.5);
	learnEnglishAcronym(`BST`, `but seriously though`, 0.5);
	learnEnglishAcronym(`BTA`, `but then again`, 0.5);
	learnEnglishAcronym(`BTAIM`, `be that as it may`, 0.5);
	learnEnglishAcronym(`BTDT`, `been there done that`, 0.5);
	learnEnglishAcronym(`BTOBD`, `be there or be dead`, 0.5);
	learnEnglishAcronym(`BTOBS`, `be there or be square`, 0.5);
	learnEnglishAcronym(`BTSOOM`, `beats the shit out of me`, 0.5);
	learnEnglishAcronym(`BTW`, `by the way`, 0.5);
	learnEnglishAcronym(`BUDWEISER`, `because you deserve what every individual should ever receive`, 0.5);
	learnEnglishAcronym(`BWQ`, `buzz word quotient`, 0.5);
	learnEnglishAcronym(`BWTHDIK`, `but what the heck do I know`, 0.5);
	learnEnglishAcronym(`BYOB`, `bring your own bottle`, 0.5);
	learnEnglishAcronym(`BYOH`, `Bat You Onna Head`, 0.5);

	learnEnglishAcronym(`C&G`, `chuckle and grin`, 0.5);
	learnEnglishAcronym(`CAD`, `ctrl-alt-delete`, 0.5);
	learnEnglishAcronym(`CADET`, `can’t add, doesn’t even try`, 0.5);
	learnEnglishAcronym(`CDIWY`, `couldn’t do it without you`, 0.5);
	learnEnglishAcronym(`CFV`, `call for votes`, 0.5);
	learnEnglishAcronym(`CFS`, `care for secret?`, 0.5);
	learnEnglishAcronym(`CFY`, `calling for you`, 0.5);
	learnEnglishAcronym(`CID`, `crying in disgrace`, 0.5);
	learnEnglishAcronym(`CIM`, `CompuServe information manager`, 0.5);
	learnEnglishAcronym(`CLM`, `career limiting move`, 0.5);
	learnEnglishAcronym(`CM@TW`, `catch me at the web`, 0.5);
	learnEnglishAcronym(`CMIIW`, `correct me if I’m wrong`, 0.5);
	learnEnglishAcronym(`CNP`, `continue in next post`, 0.5);
	learnEnglishAcronym(`CO`, `conference`, 0.5);
	learnEnglishAcronym(`CRAFT`, `can’t remember a f**king thing`, 0.5);
	learnEnglishAcronym(`CRS`, `can’t remember shit`, 0.5);
	learnEnglishAcronym(`CSG`, `chuckle snicker grin`, 0.5);
	learnEnglishAcronym(`CTS`, `changing the subject`, 0.5);
	learnEnglishAcronym(`CU`, `see you`, 0.5);
	learnEnglishAcronym(`CU2`, `see you too`, 0.5);
	learnEnglishAcronym(`CUL`, `see you later`, 0.5);
	learnEnglishAcronym(`CUL8R`, `see you later`, 0.5);
	learnEnglishAcronym(`CWOT`, `complete waste of time`, 0.5);
	learnEnglishAcronym(`CWYL`, `chat with you later`, 0.5);
	learnEnglishAcronym(`CYA`, `see ya`, 0.5);
	learnEnglishAcronym(`CYA`, `cover your ass`, 0.5);
	learnEnglishAcronym(`CYAL8R`, `see ya later`, 0.5);
	learnEnglishAcronym(`CYO`, `see you online`, 0.5);

	learnEnglishAcronym(`DBA`, `doing business as`, 0.5);
	learnEnglishAcronym(`DCed`, `disconnected`, 0.5);
	learnEnglishAcronym(`DFLA`, `disenhanced four-letter acronym`, 0.5);
	learnEnglishAcronym(`DH`, `darling husband`, 0.5);
	learnEnglishAcronym(`DIIK`, `darn if i know`, 0.5);
	learnEnglishAcronym(`DGA`, `digital guardian angel`, 0.5);
	learnEnglishAcronym(`DGARA`, `don’t give a rats ass`, 0.5);
	learnEnglishAcronym(`DIKU`, `do I know you?`, 0.5);
	learnEnglishAcronym(`DIRTFT`, `do it right the first time`, 0.5);
	learnEnglishAcronym(`DITYID`, `did I tell you I’m distressed`, 0.5);
	learnEnglishAcronym(`DIY`, `do it yourself`, 0.5);
	learnEnglishAcronym(`DL`, `download`, 0.5);
	learnEnglishAcronym(`DL`, `dead link`, 0.5);
	learnEnglishAcronym(`DLTBBB`, `don’t let the bad bugs bite`, 0.5);
	learnEnglishAcronym(`DMMGH`, `don’t make me get hostile`, 0.5);
	learnEnglishAcronym(`DQMOT`, `don’t quote me on this`, 0.5);
	learnEnglishAcronym(`DND`, `do not disturb`, 0.5);
	learnEnglishAcronym(`DTC`, `damn this computer`, 0.5);
	learnEnglishAcronym(`DTRT`, `do the right thing`, 0.5);
	learnEnglishAcronym(`DUCT`, `did you see that?`, 0.5);
	learnEnglishAcronym(`DWAI`, `don’t worry about it`, 0.5);
	learnEnglishAcronym(`DWIM`, `do what I mean`, 0.5);
	learnEnglishAcronym(`DWIMC`, `do what I mean, correctly`, 0.5);
	learnEnglishAcronym(`DWISNWID`, `do what I say, not what I do`, 0.5);
	learnEnglishAcronym(`DYJHIW`, `don’t you just hate it when...`, 0.5);
	learnEnglishAcronym(`DYK`, `do you know`, 0.5);

	learnEnglishAcronym(`EAK`, `eating at keyboard`, 0.5);
	learnEnglishAcronym(`EIE`, `enough is enough`, 0.5);
	learnEnglishAcronym(`EG`, `evil grin`, 0.5);
	learnEnglishAcronym(`EMFBI`, `excuse me for butting in`, 0.5);
	learnEnglishAcronym(`EMFJI`, `excuse me for jumping in`, 0.5);
	learnEnglishAcronym(`EMSG`, `email message`, 0.5);
	learnEnglishAcronym(`EOD`, `end of discussion`, 0.5);
	learnEnglishAcronym(`EOF`, `end of file`, 0.5);
	learnEnglishAcronym(`EOL`, `end of lecture`, 0.5);
	learnEnglishAcronym(`EOM`, `end of message`, 0.5);
	learnEnglishAcronym(`EOS`, `end of story`, 0.5);
	learnEnglishAcronym(`EOT`, `end of thread`, 0.5);
	learnEnglishAcronym(`ETLA`, `extended three letter acronym`, 0.5);
	learnEnglishAcronym(`EYC`, `excitable, yet calm`, 0.5);

	learnEnglishAcronym(`F`, `female`, 0.5);
	learnEnglishAcronym(`F/F`, `face to face`, 0.5);
	learnEnglishAcronym(`F2F`, `face to face`, 0.5);
	learnEnglishAcronym(`FAQ`, `frequently asked questions`, 0.5);
	learnEnglishAcronym(`FAWC`, `for anyone who cares`, 0.5);
	learnEnglishAcronym(`FBOW`, `for better or worse`, 0.5);
	learnEnglishAcronym(`FBTW`, `fine, be that way`, 0.5);
	learnEnglishAcronym(`FCFS`, `first come, first served`, 0.5);
	learnEnglishAcronym(`FCOL`, `for crying out loud`, 0.5);
	learnEnglishAcronym(`FIFO`, `first in, first out`, 0.5);
	learnEnglishAcronym(`FISH`, `first in, still here`, 0.5);
	learnEnglishAcronym(`FLA`, `four-letter acronym`, 0.5);
	learnEnglishAcronym(`FOAD`, `f**k off and die`, 0.5);
	learnEnglishAcronym(`FOAF`, `friend of a friend`, 0.5);
	learnEnglishAcronym(`FOB`, `f**k off bitch`, 0.5);
	learnEnglishAcronym(`FOC`, `free of charge`, 0.5);
	learnEnglishAcronym(`FOCL`, `falling of chair laughing`, 0.5);
	learnEnglishAcronym(`FOFL`, `falling on the floor laughing`, 0.5);
	learnEnglishAcronym(`FOS`, `freedom of speech`, 0.5);
	learnEnglishAcronym(`FOTCL`, `falling of the chair laughing`, 0.5);
	learnEnglishAcronym(`FTF`, `face to face`, 0.5);
	learnEnglishAcronym(`FTTT`, `from time to time`, 0.5);
	learnEnglishAcronym(`FU`, `f**ked up`, 0.5);
	learnEnglishAcronym(`FUBAR`, `f**ked up beyond all recognition`, 0.5);
	learnEnglishAcronym(`FUDFUCT`, `fear, uncertainty and doubt`, 0.5);
	learnEnglishAcronym(`FUCT`, `failed under continuas testing`, 0.5);
	learnEnglishAcronym(`FURTB`, `full up ready to burst (about hard disk drives)`, 0.5);
	learnEnglishAcronym(`FW`, `freeware`, 0.5);
	learnEnglishAcronym(`FWIW`, `for what it’s worth`, 0.5);
	learnEnglishAcronym(`FYA`, `for your amusement`, 0.5);
	learnEnglishAcronym(`FYE`, `for your entertainment`, 0.5);
	learnEnglishAcronym(`FYEO`, `for your eyes only`, 0.5);
	learnEnglishAcronym(`FYI`, `for your information`, 0.5);

	learnEnglishAcronym(`G`, `grin`, 0.5);
	learnEnglishAcronym(`G2B`,`going to bed`, 0.5);
	learnEnglishAcronym(`G&BIT`, `grin & bear it`, 0.5);
        learnEnglishAcronym(`G2G`, `got to go`, 0.5);
        learnEnglishAcronym(`G2GGS2D`, `got to go get something to drink`, 0.5);
	learnEnglishAcronym(`G2GTAC`, `got to go take a crap`, 0.5);
        learnEnglishAcronym(`G2GTAP`, `got to go take a pee`, 0.5);
	learnEnglishAcronym(`GA`, `go ahead`, 0.5);
	learnEnglishAcronym(`GA`, `good afternoon`, 0.5);
	learnEnglishAcronym(`GAFIA`, `get away from it all`, 0.5);
	learnEnglishAcronym(`GAL`, `get a life`, 0.5);
	learnEnglishAcronym(`GAS`, `greetings and salutations`, 0.5);
	learnEnglishAcronym(`GBH`, `great big hug`, 0.5);
	learnEnglishAcronym(`GBH&K`, `great big huh and kisses`, 0.5);
	learnEnglishAcronym(`GBR`, `garbled beyond recovery`, 0.5);
	learnEnglishAcronym(`GBY`, `god bless you`, 0.5);
	learnEnglishAcronym(`GD`, `&H	grinning, ducking and hiding`, 0.5);
	learnEnglishAcronym(`GD&R`, `grinning, ducking and running`, 0.5);
	learnEnglishAcronym(`GD&RAFAP`, `grinning, ducking and running as fast as possible`, 0.5);
	learnEnglishAcronym(`GD&REF&F`, `grinning, ducking and running even further and faster`, 0.5);
	learnEnglishAcronym(`GD&RF`, `grinning, ducking and running fast`, 0.5);
	learnEnglishAcronym(`GD&RVF`, `grinning, ducking and running very`, 0.5);
	learnEnglishAcronym(`GD&W`, `grin, duck and wave`, 0.5);
	learnEnglishAcronym(`GDW`, `grin, duck and wave`, 0.5);
	learnEnglishAcronym(`GE`, `good evening`, 0.5);
	learnEnglishAcronym(`GF`, `girlfriend`, 0.5);
	learnEnglishAcronym(`GFETE`, `grinning from ear to ear`, 0.5);
	learnEnglishAcronym(`GFN`, `gone for now`, 0.5);
	learnEnglishAcronym(`GFU`, `good for you`, 0.5);
	learnEnglishAcronym(`GG`, `good game`, 0.5);
	learnEnglishAcronym(`GGU`, `good game you two`, 0.5);
	learnEnglishAcronym(`GIGO`, `garbage in garbage out`, 0.5);
	learnEnglishAcronym(`GJ`, `good job`, 0.5);
	learnEnglishAcronym(`GL`, `good luck`, 0.5);
	learnEnglishAcronym(`GL&GH`, `good luck and good hunting`, 0.5);
	learnEnglishAcronym(`GM`, `good morning / good move / good match`, 0.5);
	learnEnglishAcronym(`GMAB`, `give me a break`, 0.5);
	learnEnglishAcronym(`GMAO`, `giggling my ass off`, 0.5);
	learnEnglishAcronym(`GMBO`, `giggling my butt off`, 0.5);
	learnEnglishAcronym(`GMTA`, `great minds think alike`, 0.5);
	learnEnglishAcronym(`GN`, `good night`, 0.5);
	learnEnglishAcronym(`GOK`, `god only knows`, 0.5);
	learnEnglishAcronym(`GOWI`, `get on with it`, 0.5);
	learnEnglishAcronym(`GPF`, `general protection fault`, 0.5);
	learnEnglishAcronym(`GR8`, `great`, 0.5);
	learnEnglishAcronym(`GR&D`, `grinning, running and ducking`, 0.5);
	learnEnglishAcronym(`GtG`, `got to go`, 0.5);
	learnEnglishAcronym(`GTSY`, `glad to see you`, 0.5);

	learnEnglishAcronym(`H`, `hug`, 0.5);
	learnEnglishAcronym(`H/O`, `hold on`, 0.5);
	learnEnglishAcronym(`H&K`, `hug and kiss`, 0.5);
	learnEnglishAcronym(`HAK`, `hug and kiss`, 0.5);
	learnEnglishAcronym(`HAGD`, `have a good day`, 0.5);
	learnEnglishAcronym(`HAGN`, `have a good night`, 0.5);
	learnEnglishAcronym(`HAGS`, `have a good summer`, 0.5);
	learnEnglishAcronym(`HAG1`, `have a good one`, 0.5);
	learnEnglishAcronym(`HAHA`, `having a heart attack`, 0.5);
	learnEnglishAcronym(`HAND`, `have a nice day`, 0.5);
	learnEnglishAcronym(`HB`, `hug back`, 0.5);
	learnEnglishAcronym(`HB`, `hurry back`, 0.5);
	learnEnglishAcronym(`HDYWTDT`, `how do you work this dratted thing`, 0.5);
	learnEnglishAcronym(`HF`, `have fun`, 0.5);
	learnEnglishAcronym(`HH`, `holding hands`, 0.5);
	learnEnglishAcronym(`HHIS`, `hanging head in shame`, 0.5);
	learnEnglishAcronym(`HHJK`, `ha ha, just kidding`, 0.5);
	learnEnglishAcronym(`HHOJ`, `ha ha, only joking`, 0.5);
	learnEnglishAcronym(`HHOK`, `ha ha, only kidding`, 0.5);
	learnEnglishAcronym(`HHOS`, `ha ha, only seriously`, 0.5);
	learnEnglishAcronym(`HIH`, `hope it helps`, 0.5);
	learnEnglishAcronym(`HILIACACLO`, `help I lapsed into a coma and can’t log off`, 0.5);
	learnEnglishAcronym(`HIWTH`, `hate it when that happens`, 0.5);
	learnEnglishAcronym(`HLM`, `he loves me`, 0.5);
	learnEnglishAcronym(`HMS`, `home made smiley`, 0.5);
	learnEnglishAcronym(`HMS`, `hanging my self`, 0.5);
	learnEnglishAcronym(`HMT`, `here’s my try`, 0.5);
	learnEnglishAcronym(`HMWK`, `homework`, 0.5);
	learnEnglishAcronym(`HOAS`, `hold on a second`, 0.5);
	learnEnglishAcronym(`HSIK`, `how should i know`, 0.5);
	learnEnglishAcronym(`HTH`, `hope this helps`, 0.5);
	learnEnglishAcronym(`HTHBE`, `hope this has been enlightening`, 0.5);
	learnEnglishAcronym(`HYLMS`, `hate you like my sister`, 0.5);

	learnEnglishAcronym(`IAAA`, `I am an accountant`, 0.5);
	learnEnglishAcronym(`IAAL`, `I am a lawyer`, 0.5);
	learnEnglishAcronym(`IAC`, `in any case`, 0.5);
	learnEnglishAcronym(`IC`, `I see`, 0.5);
	learnEnglishAcronym(`IAE`, `in any event`, 0.5);
	learnEnglishAcronym(`IAG`, `it’s all good`, 0.5);
	learnEnglishAcronym(`IAG`, `I am gay`, 0.5);
	learnEnglishAcronym(`IAIM`, `in an Irish minute`, 0.5);
	learnEnglishAcronym(`IANAA`, `I am not an accountant`, 0.5);
	learnEnglishAcronym(`IANAL`, `I am not a lawyer`, 0.5);
	learnEnglishAcronym(`IBN`, `I’m bucked naked`, 0.5);
	learnEnglishAcronym(`ICOCBW`, `I could of course be wrong`, 0.5);
	learnEnglishAcronym(`IDC`, `I don’t care`, 0.5);
	learnEnglishAcronym(`IDGI`, `I don’t get it`, 0.5);
	learnEnglishAcronym(`IDGARA`, `I don’t give a rat’s ass`, 0.5);
	learnEnglishAcronym(`IDGW`, `in a good way`, 0.5);
	learnEnglishAcronym(`IDI`, `I doubt it`, 0.5);
	learnEnglishAcronym(`IDK`, `I don’t know`, 0.5);
	learnEnglishAcronym(`IDTT`, `I’ll drink to that`, 0.5);
	learnEnglishAcronym(`IFVB`, `I feel very bad`, 0.5);
	learnEnglishAcronym(`IGP`, `I gotta pee`, 0.5);
	learnEnglishAcronym(`IGTP`, `I get the point`, 0.5);
	learnEnglishAcronym(`IHTFP`, `I hate this f**king place`, 0.5);
	learnEnglishAcronym(`IHTFP`, `I have truly found paradise`, 0.5);
	learnEnglishAcronym(`IHU`, `I hate you`, 0.5);
	learnEnglishAcronym(`IHY`, `I hate you`, 0.5);
	learnEnglishAcronym(`II`, `I’m impressed`, 0.5);
	learnEnglishAcronym(`IIT`, `I’m impressed too`, 0.5);
	learnEnglishAcronym(`IIR`, `if I recall`, 0.5);
	learnEnglishAcronym(`IIRC`, `if I recall correctly`, 0.5);
	learnEnglishAcronym(`IJWTK`, `I just want to know`, 0.5);
	learnEnglishAcronym(`IJWTS`, `I just want to say`, 0.5);
	learnEnglishAcronym(`IK`, `I know`, 0.5);
	learnEnglishAcronym(`IKWUM`, `I know what you mean`, 0.5);
	learnEnglishAcronym(`ILBCNU`, `I’ll be seeing you`, 0.5);
	learnEnglishAcronym(`ILU`, `I love you`, 0.5);
	learnEnglishAcronym(`ILY`, `I love you`, 0.5);
	learnEnglishAcronym(`ILYFAE`, `I love you forever and ever`, 0.5);
	learnEnglishAcronym(`IMAO`, `in my arrogant opinion`, 0.5);
	learnEnglishAcronym(`IMFAO`, `in my f***ing arrogant opinion`, 0.5);
	learnEnglishAcronym(`IMBO`, `in my bloody opinion`, 0.5);
	learnEnglishAcronym(`IMCO`, `in my considered opinion`, 0.5);
	learnEnglishAcronym(`IME`, `in my experience`, 0.5);
	learnEnglishAcronym(`IMHO`, `in my humble opinion`, 0.5);
	learnEnglishAcronym(`IMNSHO`, `in my, not so humble opinion`, 0.5);
	learnEnglishAcronym(`IMO`, `in my opinion`, 0.5);
	learnEnglishAcronym(`IMOBO`, `in my own biased opinion`, 0.5);
	learnEnglishAcronym(`IMPOV`, `in my point of view`, 0.5);
	learnEnglishAcronym(`IMP`, `I might be pregnant`, 0.5);
	learnEnglishAcronym(`INAL`, `I’m not a lawyer`, 0.5);
	learnEnglishAcronym(`INPO`, `in no particular order`, 0.5);
	learnEnglishAcronym(`IOIT`, `I’m on Irish Time`, 0.5);
	learnEnglishAcronym(`IOW`, `in other words`, 0.5);
	learnEnglishAcronym(`IRL`, `in real life`, 0.5);
	learnEnglishAcronym(`IRMFI`, `I reply merely for information`, 0.5);
	learnEnglishAcronym(`IRSTBO`, `it really sucks the big one`, 0.5);
	learnEnglishAcronym(`IS`, `I’m sorry`, 0.5);
	learnEnglishAcronym(`ISEN`, `internet search environment number`, 0.5);
	learnEnglishAcronym(`ISTM`, `it seems to me`, 0.5);
	learnEnglishAcronym(`ISTR`, `I seem to recall`, 0.5);
	learnEnglishAcronym(`ISWYM`, `I see what you mean`, 0.5);
	learnEnglishAcronym(`ITFA`, `in the final analysis`, 0.5);
	learnEnglishAcronym(`ITRO`, `in the reality of`, 0.5);
	learnEnglishAcronym(`ITRW`, `in the real world`, 0.5);
	learnEnglishAcronym(`ITSFWI`, `if the shoe fits, wear it`, 0.5);
	learnEnglishAcronym(`IVL`, `in virtual live`, 0.5);
	learnEnglishAcronym(`IWALY`, `I will always love you`, 0.5);
	learnEnglishAcronym(`IWBNI`, `it would be nice if`, 0.5);
	learnEnglishAcronym(`IYKWIM`, `if you know what I mean`, 0.5);
	learnEnglishAcronym(`IYSWIM`, `if you see what I mean`, 0.5);

	learnEnglishAcronym(`JAM`, `just a minute`, 0.5);
	learnEnglishAcronym(`JAS`, `just a second`, 0.5);
	learnEnglishAcronym(`JASE`, `just another system error`, 0.5);
	learnEnglishAcronym(`JAWS`, `just another windows shell`, 0.5);
	learnEnglishAcronym(`JIC`, `just in case`, 0.5);
	learnEnglishAcronym(`JJWY`, `just joking with you`, 0.5);
	learnEnglishAcronym(`JK`, `just kidding`, 0.5);
	learnEnglishAcronym(`J/K`, `just kidding`, 0.5);
	learnEnglishAcronym(`JMHO`, `just my humble opinion`, 0.5);
	learnEnglishAcronym(`JMO`, `just my opinion`, 0.5);
	learnEnglishAcronym(`JP`, `just playing`, 0.5);
	learnEnglishAcronym(`J/P`, `just playing`, 0.5);
	learnEnglishAcronym(`JTLYK`, `just to let you know`, 0.5);
	learnEnglishAcronym(`JW`, `just wondering`, 0.5);

	learnEnglishAcronym(`K`, `OK`, 0.5);
	learnEnglishAcronym(`K`, `kiss`, 0.5);
	learnEnglishAcronym(`KHYF`, `know how you feel`, 0.5);
	learnEnglishAcronym(`KB`, `kiss back`, 0.5);
	learnEnglishAcronym(`KISS`, `keep it simple sister`, 0.5);
	learnEnglishAcronym(`KIS(S)`, `keep it simple (stupid)`, 0.5);
	learnEnglishAcronym(`KISS`, `keeping it sweetly simple`, 0.5);
	learnEnglishAcronym(`KIT`, `keep in touch`, 0.5);
	learnEnglishAcronym(`KMA`, `kiss my ass`, 0.5);
	learnEnglishAcronym(`KMB`, `kiss my butt`, 0.5);
	learnEnglishAcronym(`KMSMA`, `kiss my shiny metal ass`, 0.5);
	learnEnglishAcronym(`KOTC`, `kiss on the cheek`, 0.5);
	learnEnglishAcronym(`KOTL`, `kiss on the lips`, 0.5);
	learnEnglishAcronym(`KUTGW`, `keep up the good work`, 0.5);
	learnEnglishAcronym(`KWIM`, `know what I mean?`, 0.5);

	learnEnglishAcronym(`L`, `laugh`, 0.5);
	learnEnglishAcronym(`L8R`, `later`, 0.5);
	learnEnglishAcronym(`L8R`, `G8R	later gator`, 0.5);
	learnEnglishAcronym(`LAB`, `life’s a bitch`, 0.5);
	learnEnglishAcronym(`LAM`, `leave a message`, 0.5);
	learnEnglishAcronym(`LBR`, `little boys room`, 0.5);
	learnEnglishAcronym(`LD`, `long distance`, 0.5);
	learnEnglishAcronym(`LIMH`, `laughing in my head`, 0.5);
	learnEnglishAcronym(`LG`, `lovely greetings`, 0.5);
	learnEnglishAcronym(`LIMH`, `laughing in my head`, 0.5);
	learnEnglishAcronym(`LGR`, `little girls room`, 0.5);
	learnEnglishAcronym(`LHM`, `Lord help me`, 0.5);
	learnEnglishAcronym(`LHU`, `Lord help us`, 0.5);
	learnEnglishAcronym(`LL&P`, `live long & prosper`, 0.5);
	learnEnglishAcronym(`LNK`, `love and kisses`, 0.5);
	learnEnglishAcronym(`LMA`, `leave me alone`, 0.5);
	learnEnglishAcronym(`LMABO`, `laughing my ass back on`, 0.5);
	learnEnglishAcronym(`LMAO`, `laughing my ass off`, 0.5);
	learnEnglishAcronym(`MBO`, `laughing my butt off`, 0.5);
	learnEnglishAcronym(`LMHO`, `laughing my head off`, 0.5);
	learnEnglishAcronym(`LMFAO`, `laughing my fat ass off`, 0.5);
	learnEnglishAcronym(`LMK`, `let me know`, 0.5);
	learnEnglishAcronym(`LOL`, `laughing out loud`, 0.5);
	learnEnglishAcronym(`LOL`, `lots of love`, 0.5);
	learnEnglishAcronym(`LOL`, `lots of luck`, 0.5);
	learnEnglishAcronym(`LOLA`, `laughing out loud again`, 0.5);
	learnEnglishAcronym(`LOML`, `light of my life (or love of my life)`, 0.5);
	learnEnglishAcronym(`LOMLILY`, `light of my life, I love you`, 0.5);
	learnEnglishAcronym(`LOOL`, `laughing out outrageously loud`, 0.5);
	learnEnglishAcronym(`LSHIPMP`, `laughing so hard I pissed my pants`, 0.5);
	learnEnglishAcronym(`LSHMBB`, `laughing so hard my belly is bouncing`, 0.5);
	learnEnglishAcronym(`LSHMBH`, `laughing so hard my belly hurts`, 0.5);
	learnEnglishAcronym(`LTNS`, `long time no see`, 0.5);
	learnEnglishAcronym(`LTR`, `long term relationship`, 0.5);
	learnEnglishAcronym(`LTS`, `laughing to self`, 0.5);
	learnEnglishAcronym(`LULAS`, `love you like a sister`, 0.5);
	learnEnglishAcronym(`LUWAMH`, `love you with all my heart`, 0.5);
	learnEnglishAcronym(`LY`, `love ya`, 0.5);
	learnEnglishAcronym(`LYK`, `let you know`, 0.5);
	learnEnglishAcronym(`LYL`, `love ya lots`, 0.5);
	learnEnglishAcronym(`LYLAB`, `love ya like a brother`, 0.5);
	learnEnglishAcronym(`LYLAS`, `love ya like a sister`, 0.5);

	learnEnglishAcronym(`M`, `male`, 0.5);
	learnEnglishAcronym(`MB`, `maybe`, 0.5);
	learnEnglishAcronym(`MYOB`, `mind your own business`, 0.5);
	learnEnglishAcronym(`M8`, `mate`, 0.5);

	learnEnglishAcronym(`N`, `in`, 0.5);
	learnEnglishAcronym(`N2M`, `not too much`, 0.5);
	learnEnglishAcronym(`N/C`, `not cool`, 0.5);
	learnEnglishAcronym(`NE1`, `anyone`, 0.5);
	learnEnglishAcronym(`NETUA`, `nobody ever tells us anything`, 0.5);
	learnEnglishAcronym(`NFI`, `no f***ing idea`, 0.5);
	learnEnglishAcronym(`NL`, `not likely`, 0.5);
	learnEnglishAcronym(`NM`, `never mind / nothing much`, 0.5);
	learnEnglishAcronym(`N/M`, `never mind / nothing much`, 0.5);
	learnEnglishAcronym(`NMH`, `not much here`, 0.5);
	learnEnglishAcronym(`NMJC`, `nothing much, just chillin’`, 0.5);
	learnEnglishAcronym(`NOM`, `no offense meant`, 0.5);
	learnEnglishAcronym(`NOTTOMH`, `not of the top of my mind`, 0.5);
	learnEnglishAcronym(`NOYB`, `none of your business`, 0.5);
	learnEnglishAcronym(`NOYFB`, `none of your f***ing business`, 0.5);
	learnEnglishAcronym(`NP`, `no problem`, 0.5);
	learnEnglishAcronym(`NPS`, `no problem sweet(ie)`, 0.5);
	learnEnglishAcronym(`NTA`, `non-technical acronym`, 0.5);
	learnEnglishAcronym(`N/S`, `no shit`, 0.5);
	learnEnglishAcronym(`NVM`, `nevermind`, 0.5);

	learnEnglishAcronym(`OBTW`, `oh, by the way`, 0.5);
	learnEnglishAcronym(`OIC`, `oh, I see`, 0.5);
	learnEnglishAcronym(`OF`, `on fire`, 0.5);
	learnEnglishAcronym(`OFIS`, `on floor with stitches`, 0.5);
	learnEnglishAcronym(`OK`, `abbreviation of oll korrect (all correct)`, 0.5);
	learnEnglishAcronym(`OL`, `old lady (wife, girlfriend)`, 0.5);
	learnEnglishAcronym(`OM`, `old man (husband, boyfriend)`, 0.5);
	learnEnglishAcronym(`OMG`, `oh my god / gosh / goodness`, 0.5);
	learnEnglishAcronym(`OOC`, `out of character`, 0.5);
	learnEnglishAcronym(`OT`, `Off topic / other topic`, 0.5);
	learnEnglishAcronym(`OTOH`, `on the other hand`, 0.5);
	learnEnglishAcronym(`OTTOMH`, `off the top of my head`, 0.5);

	learnEnglishAcronym(`P@H`, `parents at home`, 0.5);
	learnEnglishAcronym(`PAH`, `parents at home`, 0.5);
	learnEnglishAcronym(`PAW`, `parents are watching`, 0.5);
	learnEnglishAcronym(`PDS`, `please don’t shoot`, 0.5);
	learnEnglishAcronym(`PEBCAK`, `problem exists between chair and keyboard`, 0.5);
	learnEnglishAcronym(`PIZ`, `parents in room`, 0.5);
	learnEnglishAcronym(`PLZ`, `please`, 0.5);
	learnEnglishAcronym(`PM`, `private message`, 0.5);
	learnEnglishAcronym(`PMJI`, `pardon my jumping in (Another way for PMFJI)`, 0.5);
	learnEnglishAcronym(`PMFJI`, `pardon me for jumping in`, 0.5);
	learnEnglishAcronym(`PMP`, `peed my pants`, 0.5);
	learnEnglishAcronym(`POAHF`, `put on a happy face`, 0.5);
	learnEnglishAcronym(`POOF`, `I have left the chat`, 0.5);
	learnEnglishAcronym(`POTB`, `pats on the back`, 0.5);
	learnEnglishAcronym(`POS`, `parents over shoulder`, 0.5);
	learnEnglishAcronym(`PPL`, `people`, 0.5);
	learnEnglishAcronym(`PS`, `post script`, 0.5);
	learnEnglishAcronym(`PSA`, `public show of affection`, 0.5);

	learnEnglishAcronym(`Q4U`, `question for you`, 0.5);
	learnEnglishAcronym(`QSL`, `reply`, 0.5);
	learnEnglishAcronym(`QSO`, `conversation`, 0.5);
	learnEnglishAcronym(`QT`, `cutie`, 0.5);

	learnEnglishAcronym(`RCed`, `reconnected`, 0.5);
	learnEnglishAcronym(`RE`, `hi again (same as re’s)`, 0.5);
	learnEnglishAcronym(`RME`, `rolling my eyses`, 0.5);
	learnEnglishAcronym(`ROFL`, `rolling on floor laughing`, 0.5);
	learnEnglishAcronym(`ROFLAPMP`, `rolling on floor laughing and peed my pants`, 0.5);
	learnEnglishAcronym(`ROFLMAO`, `rolling on floor laughing my ass off`, 0.5);
	learnEnglishAcronym(`ROFLOLAY`, `rolling on floor laughing out loud at you`, 0.5);
	learnEnglishAcronym(`ROFLOLTSDMC`, `rolling on floor laughing out loud tears streaming down my cheeks`, 0.5);
	learnEnglishAcronym(`ROFLOLWTIME`, `rolling on floor laughing out loud with tears in my eyes`, 0.5);
	learnEnglishAcronym(`ROFLOLUTS`, `rolling on floor laughing out loud unable to speak`, 0.5);
	learnEnglishAcronym(`ROTFL`, `rolling on the floor laughing`, 0.5);
	learnEnglishAcronym(`RVD`, `really very dumb`, 0.5);
	learnEnglishAcronym(`RUTTM`, `are you talking to me`, 0.5);
	learnEnglishAcronym(`RTF`, `read the FAQ`, 0.5);
	learnEnglishAcronym(`RTFM`, `read the f***ing manual`, 0.5);
	learnEnglishAcronym(`RTSM`, `read the stupid manual`, 0.5);

	learnEnglishAcronym(`S2R`, `send to receive`, 0.5);
	learnEnglishAcronym(`SAMAGAL`, `stop annoying me and get a live`, 0.5);
	learnEnglishAcronym(`SCNR`, `sorry, could not resist`, 0.5);
	learnEnglishAcronym(`SETE`, `smiling ear to ear`, 0.5);
	learnEnglishAcronym(`SH`, `so hot`, 0.5);
	learnEnglishAcronym(`SH`, `same here`, 0.5);
	learnEnglishAcronym(`SHICPMP`, `so happy I could piss my pants`, 0.5);
	learnEnglishAcronym(`SHID`, `slaps head in disgust`, 0.5);
	learnEnglishAcronym(`SHMILY`, `see how much I love you`, 0.5);
	learnEnglishAcronym(`SNAFU`, `situation normal, all F***ed up`, 0.5);
	learnEnglishAcronym(`SO`, `significant other`, 0.5);
	learnEnglishAcronym(`SOHF`, `sense of humor failure`, 0.5);
	learnEnglishAcronym(`SOMY`, `sick of me yet?`, 0.5);
	learnEnglishAcronym(`SPAM`, `stupid persons’ advertisement`, 0.5);
	learnEnglishAcronym(`SRY`, `sorry`, 0.5);
	learnEnglishAcronym(`SSDD`, `same shit different day`, 0.5);
	learnEnglishAcronym(`STBY`, `sucks to be you`, 0.5);
	learnEnglishAcronym(`STFU`, `shut the f*ck up`, 0.5);
	learnEnglishAcronym(`STI`, `stick(ing) to it`, 0.5);
	learnEnglishAcronym(`STW`, `search the web`, 0.5);
	learnEnglishAcronym(`SWAK`, `sealed with a kiss`, 0.5);
	learnEnglishAcronym(`SWALK`, `sweet, with all love, kisses`, 0.5);
	learnEnglishAcronym(`SWL`, `screaming with laughter`, 0.5);
	learnEnglishAcronym(`SIM`, `shit, it’s Monday`, 0.5);
	learnEnglishAcronym(`SITWB`, `sorry, in the wrong box`, 0.5);
	learnEnglishAcronym(`S/U`, `shut up`, 0.5);
	learnEnglishAcronym(`SYS`, `see you soon`, 0.5);
	learnEnglishAcronym(`SYSOP`, `system operator`, 0.5);

	learnEnglishAcronym(`TA`, `thanks again`, 0.5);
	learnEnglishAcronym(`TCO`, `taken care of`, 0.5);
	learnEnglishAcronym(`TGIF`, `thank god its Friday`, 0.5);
	learnEnglishAcronym(`THTH`, `to hot to handle`, 0.5);
	learnEnglishAcronym(`THX`, `thanks`, 0.5);
	learnEnglishAcronym(`TIA`, `thanks in advance`, 0.5);
	learnEnglishAcronym(`TIIC`, `the idiots in charge`, 0.5);
	learnEnglishAcronym(`TJM`, `that’s just me`, 0.5);
	learnEnglishAcronym(`TLA`, `three-letter acronym`, 0.5);
	learnEnglishAcronym(`TMA`, `take my advice`, 0.5);
	learnEnglishAcronym(`TMI`, `to much information`, 0.5);
	learnEnglishAcronym(`TMS`, `to much showing`, 0.5);
	learnEnglishAcronym(`TNSTAAFL`, `there’s no such thing as a free lunch`, 0.5);
	learnEnglishAcronym(`TNX`, `thanks`, 0.5);
	learnEnglishAcronym(`TOH`, `to other half`, 0.5);
	learnEnglishAcronym(`TOY`, `thinking of you`, 0.5);
	learnEnglishAcronym(`TPTB`, `the powers that be`, 0.5);
	learnEnglishAcronym(`TSDMC`, `tears streaming down my cheeks`, 0.5);
	learnEnglishAcronym(`TT2T`, `to tired to talk`, 0.5);
	learnEnglishAcronym(`TTFN`, `ta ta for now`, 0.5);
	learnEnglishAcronym(`TTT`, `thought that, too`, 0.5);
	learnEnglishAcronym(`TTUL`, `talk to you later`, 0.5);
	learnEnglishAcronym(`TTYIAM`, `talk to you in a minute`, 0.5);
	learnEnglishAcronym(`TTYL`, `talk to you later`, 0.5);
	learnEnglishAcronym(`TTYLMF`, `talk to you later my friend`, 0.5);
	learnEnglishAcronym(`TU`, `thank you`, 0.5);
	learnEnglishAcronym(`TWMA`, `till we meet again`, 0.5);
	learnEnglishAcronym(`TX`, `thanx`, 0.5);
	learnEnglishAcronym(`TY`, `thank you`, 0.5);
	learnEnglishAcronym(`TYVM`, `thank you very much`, 0.5);

	learnEnglishAcronym(`U2`, `you too`, 0.5);
	learnEnglishAcronym(`UAPITA`, `you’re a pain in the ass`, 0.5);
	learnEnglishAcronym(`UR`, `your`, 0.5);
	learnEnglishAcronym(`UW`, `you’re welcom`, 0.5);
	learnEnglishAcronym(`URAQT!`, `you are a cutie!`, 0.5);

	learnEnglishAcronym(`VBG`, `very big grin`, 0.5);
	learnEnglishAcronym(`VBS`, `very big smile`, 0.5);

	learnEnglishAcronym(`W8`, `wait`, 0.5);
	learnEnglishAcronym(`W8AM`, `wait a minute`, 0.5);
	learnEnglishAcronym(`WAY`, `what about you`, 0.5);
	learnEnglishAcronym(`WAY`, `who are you`, 0.5);
	learnEnglishAcronym(`WB`, `welcome back`, 0.5);
	learnEnglishAcronym(`WBS`, `write back soon`, 0.5);
	learnEnglishAcronym(`WDHLM`, `why doesn’t he love me`, 0.5);
	learnEnglishAcronym(`WDYWTTA`, `What Do You Want To Talk About`, 0.5);
	learnEnglishAcronym(`WE`, `whatever`, 0.5);
	learnEnglishAcronym(`W/E`, `whatever`, 0.5);
	learnEnglishAcronym(`WFM`, `works for me`, 0.5);
	learnEnglishAcronym(`WNDITWB`, `we never did it this way before`, 0.5);
	learnEnglishAcronym(`WP`, `wrong person`, 0.5);
	learnEnglishAcronym(`WRT`, `with respect to`, 0.5);
	learnEnglishAcronym(`WTF`, `what/who the F***?`, 0.5);
	learnEnglishAcronym(`WTG`, `way to go`, 0.5);
	learnEnglishAcronym(`WTGP`, `want to go private?`, 0.5);
	learnEnglishAcronym(`WTH`, `what/who the heck?`, 0.5);
	learnEnglishAcronym(`WTMI`, `way to much information`, 0.5);
	learnEnglishAcronym(`WU`, `what’s up?`, 0.5);
	learnEnglishAcronym(`WUD`, `what’s up dog?`, 0.5);
	learnEnglishAcronym(`WUF`, `where are you from?`, 0.5);
	learnEnglishAcronym(`WUWT`, `whats up with that`, 0.5);
	learnEnglishAcronym(`WYMM`, `will you marry me?`, 0.5);
	learnEnglishAcronym(`WYSIWYG`, `what you see is what you get`, 0.5);

	learnEnglishAcronym(`XTLA`, `extended three letter acronym`, 0.5);

	learnEnglishAcronym(`Y`, `why?`, 0.5);
	learnEnglishAcronym(`Y2K`, `you’re too kind`, 0.5);
	learnEnglishAcronym(`YATB`, `you are the best`, 0.5);
	learnEnglishAcronym(`YBS`, `you’ll be sorry`, 0.5);
	learnEnglishAcronym(`YG`, `young gentleman`, 0.5);
	learnEnglishAcronym(`YHBBYBD`, `you’d have better bet your bottom dollar`, 0.5);
	learnEnglishAcronym(`YKYWTKM`, `you know you want to kiss me`, 0.5);
	learnEnglishAcronym(`YL`, `young lady`, 0.5);
	learnEnglishAcronym(`YL`, `you ’ll live`, 0.5);
	learnEnglishAcronym(`YM`, `you mean`, 0.5);
	learnEnglishAcronym(`YM`, `young man`, 0.5);
	learnEnglishAcronym(`YMMD`, `you’ve made my day`, 0.5);
	learnEnglishAcronym(`YMMV`, `your mileage may vary`, 0.5);
	learnEnglishAcronym(`YVM`, `you’re very welcome`, 0.5);
	learnEnglishAcronym(`YW`, `you’re welcome`, 0.5);
	learnEnglishAcronym(`YWIA`, `you’re welcome in advance`, 0.5);
	learnEnglishAcronym(`YWTHM`, `you want to hug me`, 0.5);
	learnEnglishAcronym(`YWTLM`, `you want to love me`, 0.5);
	learnEnglishAcronym(`YWTKM`, `you want to kiss me`, 0.5);
	learnEnglishAcronym(`YOYO`, `you’re on your own`, 0.5);
	learnEnglishAcronym(`YY4U`, `two wise for you`, 0.5);

	learnEnglishAcronym(`?`, `huh?`, 0.5);
	learnEnglishAcronym(`?4U`, `question for you`, 0.5);
	learnEnglishAcronym(`>U`, `screw you!`, 0.5);
	learnEnglishAcronym(`/myB`, `kick my boobs`, 0.5);
	learnEnglishAcronym(`2U2`, `to you too`, 0.5);
	learnEnglishAcronym(`2MFM`, `to much for me`, 0.5);
	learnEnglishAcronym(`4AYN`, `for all you know`, 0.5);
	learnEnglishAcronym(`4COL`, `for crying out loud`, 0.5);
	learnEnglishAcronym(`4SALE`, `for sale`, 0.5);
	learnEnglishAcronym(`4U`, `for you`, 0.5);
	learnEnglishAcronym(`=w=`, `whatever`, 0.5);
	learnEnglishAcronym(`*G*`, `giggle or grin`, 0.5);
	learnEnglishAcronym(`*H*`, `hug`, 0.5);
	learnEnglishAcronym(`*K*`, `kiss`, 0.5);
	learnEnglishAcronym(`*S*`, `smile`, 0.5);
	learnEnglishAcronym(`*T*`, `tickle`, 0.5);
	learnEnglishAcronym(`*W*`, `wink`, 0.5);

        // https://en.wikipedia.org/wiki/List_of_emoticons
        learnEnglishEmoticon([`:-)`, `:)`, `:)`, `:o)`, `:]`, `:3`, `:c)`, `:>`],
                             [`Smiley`, `Happy`], 0.5);
    }

    /** Learn English Irregular Verbs.
        TODO Move to irregular_verb.txt in format: bewas,werebeen
        TODO Merge with http://www.enchantedlearning.com/wordlist/irregularverbs.shtml
    */
    void learnEnglishIrregularVerbs()
    {
        writeln(`Reading English Irregular Verbs ...`);
        /* base form	past simple	past participle	3rd person singular	present participle / gerund */
        learnEnglishIrregularVerb(`alight`, [`alit`, `alighted`], [`alit`, `alighted`]); // alights	alighting
        learnEnglishIrregularVerb(`arise`, `arose`, `arisen`); // arises	arising
        learnEnglishIrregularVerb(`awake`, `awoke`, `awoken`); // awakes	awaking
        learnEnglishIrregularVerb(`be`, [`was`, `were`], `been`); // is	being
        learnEnglishIrregularVerb(`bear`, `bore`, [`born`, `borne`]); // bears	bearing
        learnEnglishIrregularVerb(`beat`, `beat`, `beaten`); // beats	beating
        learnEnglishIrregularVerb(`become`, `became`, `become`); // becomes	becoming
        learnEnglishIrregularVerb(`begin`, `began`, `begun`); // begins	beginning
        learnEnglishIrregularVerb(`behold`, `beheld`, `beheld`); // beholds	beholding
        learnEnglishIrregularVerb(`bend`, `bent`, `bent`); // bends	bending
        learnEnglishIrregularVerb(`bet`, `bet`, `bet`); // bets	betting
        learnEnglishIrregularVerb(`bid`, `bade`, `bidden`); // bids	bidding
        learnEnglishIrregularVerb(`bid`, `bid`, `bid`); // bids	bidding
        learnEnglishIrregularVerb(`bind`, `bound`, `bound`); // binds	binding
        learnEnglishIrregularVerb(`bite`, `bit`, `bitten`); // bites	biting
        learnEnglishIrregularVerb(`bleed`, `bled`, `bled`); // bleeds	bleeding
        learnEnglishIrregularVerb(`blow`, `blew`, `blown`); // blows	blowing
        learnEnglishIrregularVerb(`break`, `broke`, `broken`); // breaks	breaking
        learnEnglishIrregularVerb(`breed`, `bred`, `bred`); // breeds	breeding
        learnEnglishIrregularVerb(`bring`, `brought`, `brought`); // brings	bringing
        learnEnglishIrregularVerb(`broadcast`, [`broadcast`, `broadcasted`], [`broadcast`, `broadcasted`]); // broadcasts	broadcasting
        learnEnglishIrregularVerb(`build`, `built`, `built`); // builds	building
        learnEnglishIrregularVerb(`burn`, [`burnt`, `burned`], [`burnt`, `burned`]); // burns	burning
        learnEnglishIrregularVerb(`burst`, `burst`, `burst`); // bursts	bursting
        learnEnglishIrregularVerb(`bust`, `bust`, `bust`); // busts	busting
        learnEnglishIrregularVerb(`buy`, `bought`, `bought`); // buys	buying
        learnEnglishIrregularVerb(`cast`, `cast`, `cast`); // casts	casting
        learnEnglishIrregularVerb(`catch`, `caught`, `caught`); // catches	catching
        learnEnglishIrregularVerb(`choose`, `chose`, `chosen`); // chooses	choosing
        learnEnglishIrregularVerb(`clap`, [`clapped`, `clapt`], [`clapped`, `clapt`]); // claps	clapping
        learnEnglishIrregularVerb(`cling`, `clung`, `clung`); // clings	clinging
        learnEnglishIrregularVerb(`clothe`, [`clad`, `clothed`], [`clad`, `clothed`]); // clothes	clothing
        learnEnglishIrregularVerb(`come`, `came`, `come`); // comes	coming
        learnEnglishIrregularVerb(`cost`, `cost`, `cost`); // costs	costing
        learnEnglishIrregularVerb(`creep`, `crept`, `crept`); // creeps	creeping
        learnEnglishIrregularVerb(`cut`, `cut`, `cut`); // cuts	cutting
        learnEnglishIrregularVerb(`dare`, [`dared`, `durst`], `dared`); // dares	daring
        learnEnglishIrregularVerb(`deal`, `dealt`, `dealt`); // deals	dealing
        learnEnglishIrregularVerb(`dig`, `dug`, `dug`); // digs	digging
        learnEnglishIrregularVerb(`dive`, [`dived`, `dove`], `dived`); // dives	diving
        learnEnglishIrregularVerb(`do`, `did`, `done`); // does	doing
        learnEnglishIrregularVerb(`draw`, `drew`, `drawn`); // draws	drawing
        learnEnglishIrregularVerb(`dream`, [`dreamt`, `dreamed`], [`dreamt`, `dreamed`]); // dreams	dreaming
        learnEnglishIrregularVerb(`drink`, `drank`, `drunk`); // drinks	drinking
        learnEnglishIrregularVerb(`drive`, `drove`, `driven`); // drives	driving
        learnEnglishIrregularVerb(`dwell`, `dwelt`, `dwelt`); // dwells	dwelling
        learnEnglishIrregularVerb(`eat`, `ate`, `eaten`); // eats	eating
        learnEnglishIrregularVerb(`fall`, `fell`, `fallen`); // falls	falling
        learnEnglishIrregularVerb(`feed`, `fed`, `fed`); // feeds	feeding
        learnEnglishIrregularVerb(`feel`, `felt`, `felt`); // feels	feeling
        learnEnglishIrregularVerb(`fight`, `fought`, `fought`); // fights	fighting
        learnEnglishIrregularVerb(`find`, `found`, `found`); // finds	finding
        learnEnglishIrregularVerb(`fit`, [`fit`, `fitted`], [`fit`, `fitted`]); // fits	fitting
        learnEnglishIrregularVerb(`flee`, `fled`, `fled`); // flees	fleeing
        learnEnglishIrregularVerb(`fling`, `flung`, `flung`); // flings	flinging
        learnEnglishIrregularVerb(`fly`, `flew`, `flown`); // flies	flying
        learnEnglishIrregularVerb(`forbid`, [`forbade`, `forbad`], `forbidden`); // forbids	forbidding
        learnEnglishIrregularVerb(`forecast`, [`forecast`, `forecasted`], [`forecast`, `forecasted`]); // forecasts	forecasting
        learnEnglishIrregularVerb(`foresee`, `foresaw`, `foreseen`); // foresees	foreseeing
        learnEnglishIrregularVerb(`foretell`, `foretold`, `foretold`); // foretells	foretelling
        learnEnglishIrregularVerb(`forget`, `forgot`, `forgotten`); // forgets	foregetting
        learnEnglishIrregularVerb(`forgive`, `forgave`, `forgiven`); // forgives	forgiving
        learnEnglishIrregularVerb(`forsake`, `forsook`, `forsaken`); // forsakes	forsaking
        learnEnglishIrregularVerb(`freeze`, `froze`, `frozen`); // freezes	freezing
        learnEnglishIrregularVerb(`frostbite`, `frostbit`, `frostbitten`); // frostbites	frostbiting
        learnEnglishIrregularVerb(`get`, `got`, [`got`, `gotten`]); // gets	getting
        learnEnglishIrregularVerb(`give`, `gave`, `given`); // gives	giving
        learnEnglishIrregularVerb(`go`, `went`, [`gone`, `been`]); // goes	going
        learnEnglishIrregularVerb(`grind`, `ground`, `ground`); // grinds	grinding
        learnEnglishIrregularVerb(`grow`, `grew`, `grown`); // grows	growing
        learnEnglishIrregularVerb(`handwrite`, `handwrote`, `handwritten`); // handwrites	handwriting
        learnEnglishIrregularVerb(`hang`, [`hung`, `hanged`], [`hung`, `hanged`]); // hangs	hanging
        learnEnglishIrregularVerb(`have`, `had`, `had`); // has	having
        learnEnglishIrregularVerb(`hear`, `heard`, `heard`); // hears	hearing
        learnEnglishIrregularVerb(`hide`, `hid`, `hidden`); // hides	hiding
        learnEnglishIrregularVerb(`hit`, `hit`, `hit`); // hits	hitting
        learnEnglishIrregularVerb(`hold`, `held`, `held`); // holds	holding
        learnEnglishIrregularVerb(`hurt`, `hurt`, `hurt`); // hurts	hurting
        learnEnglishIrregularVerb(`inlay`, `inlaid`, `inlaid`); // inlays	inlaying
        learnEnglishIrregularVerb(`input`, [`input`, `inputted`], [`input`, `inputted`]); // inputs	inputting
        learnEnglishIrregularVerb(`interlay`, `interlaid`, `interlaid`); // interlays	interlaying
        learnEnglishIrregularVerb(`keep`, `kept`, `kept`); // keeps	keeping
        learnEnglishIrregularVerb(`kneel`, [`knelt`, `kneeled`], [`knelt`, `kneeled`]); // kneels	kneeling
        learnEnglishIrregularVerb(`knit`, [`knit`, `knitted`], [`knit`, `knitted`]); // knits	knitting
        learnEnglishIrregularVerb(`know`, `knew`, `known`); // knows	knowing
        learnEnglishIrregularVerb(`lay`, `laid`, `laid`); // lays	laying
        learnEnglishIrregularVerb(`lead`, `led`, `led`); // leads	leading
        learnEnglishIrregularVerb(`lean`, [`leant`, `leaned`], [`leant`, `leaned`]); // leans	leaning
        learnEnglishIrregularVerb(`leap`, [`leapt`, `leaped`], [`leapt`, `leaped`]); // leaps	leaping
        learnEnglishIrregularVerb(`learn`, [`learnt`, `learned`], [`learnt`, `learned`]); // learns	learning
        learnEnglishIrregularVerb(`leave`, `left`, `left`); // leaves	leaving
        learnEnglishIrregularVerb(`lend`, `lent`, `lent`); // lends	lending
        learnEnglishIrregularVerb(`let`, `let`, `let`); // lets	letting
        learnEnglishIrregularVerb(`lie`, `lay`, `lain`); // lies	lying
        learnEnglishIrregularVerb(`light`, `lit`, `lit`); // lights	lighting
        learnEnglishIrregularVerb(`lose`, `lost`, `lost`); // loses	losing
        learnEnglishIrregularVerb(`make`, `made`, `made`); // makes	making
        learnEnglishIrregularVerb(`mean`, `meant`, `meant`); // means	meaning
        learnEnglishIrregularVerb(`meet`, `met`, `met`); // meets	meeting
        learnEnglishIrregularVerb(`melt`, `melted`, [`molten`, `melted`]); // melts	melting
        learnEnglishIrregularVerb(`mislead`, `misled`, `misled`); // misleads	misleading
        learnEnglishIrregularVerb(`mistake`, `mistook`, `mistaken`); // mistakes	mistaking
        learnEnglishIrregularVerb(`misunderstand`, `misunderstood`, `misunderstood`); // misunderstands	misunderstanding
        learnEnglishIrregularVerb(`miswed`, [`miswed`, `miswedded`], [`miswed`, `miswedded`]); // misweds	miswedding
        learnEnglishIrregularVerb(`mow`, `mowed`, `mown`); // mows	mowing
        learnEnglishIrregularVerb(`overdraw`, `overdrew`, `overdrawn`); // overdraws	overdrawing
        learnEnglishIrregularVerb(`overhear`, `overheard`, `overheard`); // overhears	overhearing
        learnEnglishIrregularVerb(`overtake`, `overtook`, `overtaken`); // overtakes	overtaking
        learnEnglishIrregularVerb(`partake`, `partook`, `partaken`);
        learnEnglishIrregularVerb(`pay`, `paid`, `paid`); // pays	paying
        learnEnglishIrregularVerb(`preset`, `preset`, `preset`); // presets	presetting
        learnEnglishIrregularVerb(`prove`, `proved`, [`proven`, `proved`]); // proves	proving
        learnEnglishIrregularVerb(`put`, `put`, `put`); // puts	putting
        learnEnglishIrregularVerb(`quit`, `quit`, `quit`); // quits	quitting
        learnEnglishIrregularVerb(`re-prove`, `re-proved`, `re-proven/re-proved`); // re-proves	re-proving
        learnEnglishIrregularVerb(`read`, `read`, `read`); // reads	reading
        learnEnglishIrregularVerb(`rend`, `rent`, `rent`);
        learnEnglishIrregularVerb(`rid`, [`rid`, `ridded`], [`rid`, `ridded`]); // rids	ridding
        learnEnglishIrregularVerb(`ride`, `rode`, `ridden`); // rides	riding
        learnEnglishIrregularVerb(`ring`, `rang`, `rung`); // rings	ringing
        learnEnglishIrregularVerb(`rise`, `rose`, `risen`); // rises	rising
        learnEnglishIrregularVerb(`rive`, `rived`, [`riven`, `rived`]); // rives	riving
        learnEnglishIrregularVerb(`run`, `ran`, `run`); // runs	running
        learnEnglishIrregularVerb(`saw`, `sawed`, [`sawn`, `sawed`]); // saws	sawing
        learnEnglishIrregularVerb(`say`, `said`, `said`); // says	saying
        learnEnglishIrregularVerb(`see`, `saw`, `seen`); // sees	seeing
        learnEnglishIrregularVerb(`seek`, `sought`, `sought`); // seeks	seeking
        learnEnglishIrregularVerb(`sell`, `sold`, `sold`); // sells	selling
        learnEnglishIrregularVerb(`send`, `sent`, `sent`); // sends	sending
        learnEnglishIrregularVerb(`set`, `set`, `set`); // sets	setting
        learnEnglishIrregularVerb(`sew`, `sewed`, [`sewn`, `sewed`]); // sews	sewing
        learnEnglishIrregularVerb(`shake`, `shook`, `shaken`); // shakes	shaking
        learnEnglishIrregularVerb(`shave`, `shaved`, [`shaven`, `shaved`]); // shaves	shaving
        learnEnglishIrregularVerb(`shear`, [`shore`, `sheared`], [`shorn`, `sheared`]); // shears	shearing
        learnEnglishIrregularVerb(`shed`, `shed`, `shed`); // sheds	shedding
        learnEnglishIrregularVerb(`shine`, `shone`, `shone`); // shines	shining
        learnEnglishIrregularVerb(`shoe`, `shod`, `shod`); // shoes	shoeing
        learnEnglishIrregularVerb(`shoot`, `shot`, `shot`); // shoots	shooting
        learnEnglishIrregularVerb(`show`, `showed`, `shown`); // shows	showing
        learnEnglishIrregularVerb(`shrink`, `shrank`, `shrunk`); // shrinks	shrinking
        learnEnglishIrregularVerb(`shut`, `shut`, `shut`); // shuts	shutting
        learnEnglishIrregularVerb(`sing`, `sang`, `sung`); // sings	singing
        learnEnglishIrregularVerb(`sink`, `sank`, `sunk`); // sinks	sinking
        learnEnglishIrregularVerb(`sit`, `sat`, `sat`); // sits	sitting
        learnEnglishIrregularVerb(`slay`, `slew`, `slain`); // slays	slaying
        learnEnglishIrregularVerb(`sleep`, `slept`, `slept`); // sleeps	sleeping
        learnEnglishIrregularVerb(`slide`, `slid`, [`slid`, `slidden`]); // slides	sliding
        learnEnglishIrregularVerb(`sling`, `slung`, `slung`); // slings	slinging
        learnEnglishIrregularVerb(`slink`, `slunk`, `slunk`); // slinks	slinking
        learnEnglishIrregularVerb(`slit`, `slit`, `slit`); // slits	slitting
        learnEnglishIrregularVerb(`smell`, [`smelt`, `smelled`], [`smelt`, `smelled`]); // smells	smelling
        learnEnglishIrregularVerb(`sneak`, [`sneaked`, `snuck`], [`sneaked`, `snuck`]); // sneaks	sneaking
        learnEnglishIrregularVerb(`soothsay`, `soothsaid`, `soothsaid`); // soothsays	soothsaying
        learnEnglishIrregularVerb(`sow`, `sowed`, `sown`); // sows	sowing
        learnEnglishIrregularVerb(`speak`, `spoke`, `spoken`); // speaks	speaking
        learnEnglishIrregularVerb(`speed`, [`sped`, `speeded`], [`sped`, `speeded`]); // speeds	speeding
        learnEnglishIrregularVerb(`spell`, [`spelt`, `spelled`], [`spelt`, `spelled`]); // spells	spelling
        learnEnglishIrregularVerb(`spend`, `spent`, `spent`); // spends	spending
        learnEnglishIrregularVerb(`spill`, [`spilt`, `spilled`], [`spilt`, `spilled`]); // spills	spilling
        learnEnglishIrregularVerb(`spin`, [`span`, `spun`], `spun`); // spins	spinning
        learnEnglishIrregularVerb(`spit`, [`spat`, `spit`], [`spat`, `spit`]); // spits	spitting
        learnEnglishIrregularVerb(`split`, `split`, `split`); // splits	splitting
        learnEnglishIrregularVerb(`spoil`, [`spoilt`, `spoiled`], [`spoilt`, `spoiled`]); // spoils	spoiling
        learnEnglishIrregularVerb(`spread`, `spread`, `spread`); // spreads	spreading
        learnEnglishIrregularVerb(`spring`, `sprang`, `sprung`); // springs	springing
        learnEnglishIrregularVerb(`stand`, `stood`, `stood`); // stands	standing
        learnEnglishIrregularVerb(`steal`, `stole`, `stolen`); // steals	stealing
        learnEnglishIrregularVerb(`stick`, `stuck`, `stuck`); // sticks	sticking
        learnEnglishIrregularVerb(`sting`, `stung`, `stung`); // stings	stinging
        learnEnglishIrregularVerb(`stink`, `stank`, `stunk`); // stinks	stinking
        learnEnglishIrregularVerb(`stride`, [`strode`, `strided`], `stridden`); // strides	striding
        learnEnglishIrregularVerb(`strike`, `struck`, [`struck`, `stricken`]); // strikes	striking
        learnEnglishIrregularVerb(`string`, `strung`, `strung`); // strings	stringing
        learnEnglishIrregularVerb(`strip`, [`stript`, `stripped`], [`stript`, `stripped`]); // strips	stripping
        learnEnglishIrregularVerb(`strive`, `strove`, `striven`); // strives	striving
        learnEnglishIrregularVerb(`sublet`, `sublet`, `sublet`); // sublets	subletting
        learnEnglishIrregularVerb(`sunburn`, [`sunburned`, `sunburnt`], [`sunburned`, `sunburnt`]); // sunburns	sunburning
        learnEnglishIrregularVerb(`swear`, `swore`, `sworn`); // swears	swearing
        learnEnglishIrregularVerb(`sweat`, [`sweat`, `sweated`], [`sweat`, `sweated`]); // sweats	sweating
        learnEnglishIrregularVerb(`sweep`, [`swept`, `sweeped`], [`swept`, `sweeped`]); // sweeps	sweeping
        learnEnglishIrregularVerb(`swell`, `swelled`, `swollen`); // swells	swelling
        learnEnglishIrregularVerb(`swim`, `swam`, `swum`); // swims	swimming
        learnEnglishIrregularVerb(`swing`, `swung`, `swung`); // swings	swinging
        learnEnglishIrregularVerb(`take`, `took`, `taken`); // takes	taking
        learnEnglishIrregularVerb(`teach`, `taught`, `taught`); // teaches	teaching
        learnEnglishIrregularVerb(`tear`, `tore`, `torn`); // tears	tearing
        learnEnglishIrregularVerb(`tell`, `told`, `told`); // tells	telling
        learnEnglishIrregularVerb(`think`, `thought`, `thought`); // thinks	thinking
        learnEnglishIrregularVerb(`thrive`, [`throve`, `thrived`], [`thriven`, `thrived`]); // thrives	thriving
        learnEnglishIrregularVerb(`throw`, `threw`, `thrown`); // throws	throwing
        learnEnglishIrregularVerb(`thrust`, `thrust`, `thrust`); // thrusts	thrusting
        learnEnglishIrregularVerb(`tread`, `trod`, [`trodden`, `trod`]); // treads	treading
        learnEnglishIrregularVerb(`undergo`, `underwent`, `undergone`); // undergoes	undergoing
        learnEnglishIrregularVerb(`understand`, `understood`, `understood`); // understands	understanding
        learnEnglishIrregularVerb(`undertake`, `undertook`, `undertaken`); // undertakes	undertaking
        learnEnglishIrregularVerb(`upsell`, `upsold`, `upsold`); // upsells	upselling
        learnEnglishIrregularVerb(`upset`, `upset`, `upset`); // upsets	upsetting
        learnEnglishIrregularVerb(`vex`, [`vext`, `vexed`], [`vext`, `vexed`]); // vexes	vexing
        learnEnglishIrregularVerb(`wake`, `woke`, `woken`); // wakes	waking
        learnEnglishIrregularVerb(`wear`, `wore`, `worn`); // wears	wearing
        learnEnglishIrregularVerb(`weave`, `wove`, `woven`); // weaves	weaving
        learnEnglishIrregularVerb(`wed`, [`wed`, `wedded`], [`wed`, `wedded`]); // weds	wedding
        learnEnglishIrregularVerb(`weep`, `wept`, `wept`); // weeps	weeping
        learnEnglishIrregularVerb(`wend`, [`wended`, `went`], [`wended`, `went`]); // wends	wending
        learnEnglishIrregularVerb(`wet`, [`wet`, `wetted`], [`wet`, `wetted`]); // wets	wetting
        learnEnglishIrregularVerb(`win`, `won`, `won`); // wins	winning
        learnEnglishIrregularVerb(`wind`, `wound`, `wound`); // winds	winding
        learnEnglishIrregularVerb(`withdraw`, `withdrew`, `withdrawn`); // withdraws	withdrawing
        learnEnglishIrregularVerb(`withhold`, `withheld`, `withheld`); // withholds	withholding
        learnEnglishIrregularVerb(`withstand`, `withstood`, `withstood`); // withstands	withstanding
        learnEnglishIrregularVerb(`wring`, `wrung`, `wrung`); // wrings	wringing
        learnEnglishIrregularVerb(`write`, `wrote`, `written`); // writes	writing
        learnEnglishIrregularVerb(`zinc`, [`zinced`, `zincked`], [`zinced`, `zincked`]); // zincs/zincks	zincking
        learnEnglishIrregularVerb(`abide`, [`abode`, `abided`], [`abode`, `abided`, `abidden`]); // abides	abiding
    }

    void learnMath()
    {
        const origin = Origin.manual;

        connect(store(`π`, Lang.math, Sense.numberIrrational, origin),
                Role(Rel.translationOf),
                store(`pi`, Lang.en, Sense.numberIrrational, origin), // TODO other Langs?
                origin, 1.0);
        connect(store(`e`, Lang.math, Sense.numberIrrational, origin),
                Role(Rel.translationOf),
                store(`e`, Lang.en, Sense.numberIrrational, origin), // TODO other Langs?
                origin, 1.0);

        /// http://www.geom.uiuc.edu/~huberty/math5337/groupe/digits.html
        connect(store(`π`, Lang.math, Sense.numberIrrational, origin),
                Role(Rel.definedAs),
                store(`3.14159265358979323846264338327950288419716939937510`,
                      Lang.math, Sense.decimal, origin),
                origin, 1.0);

        connect(store(`e`, Lang.math, Sense.numberIrrational, origin),
                Role(Rel.definedAs),
                store(`2.71828182845904523536028747135266249775724709369995`,
                      Lang.math, Sense.decimal, origin),
                origin, 1.0);

        learnMto1(Lang.en, [`quaternary`, `quinary`, `senary`, `octal`, `decimal`, `duodecimal`, `vigesimal`, `quadrovigesimal`, `duotrigesimal`, `sexagesimal`, `octogesimal`],
                  Role(Rel.hasProperty, true), `counting system`, Sense.adjective, Sense.noun, 1.0);
    }

    void learnPunctuation()
    {
        const origin = Origin.manual;

        connect(store(`:`, Lang.unknown, Sense.punctuation, origin),
                Role(Rel.definedAs),
                store(`colon`,
                      Lang.en, Sense.noun, origin),
                origin, 1.0);

        connect(store(`;`, Lang.unknown, Sense.punctuation, origin),
                Role(Rel.definedAs),
                store(`semicolon`,
                      Lang.en, Sense.noun, origin),
                origin, 1.0);

        connectMto1(store([`,`, `،`, `、`], Lang.unknown, Sense.punctuation, origin),
                    Role(Rel.definedAs),
                    store(`comma`,
                          Lang.en, Sense.noun, origin),
                    origin, 1.0);

        connectMtoN(store([`/`, `⁄`], Lang.unknown, Sense.punctuation, origin),
                    Role(Rel.definedAs),
                    store([`slash`, `stroke`, `solidus`],
                          Lang.en, Sense.noun, origin),
                    origin, 1.0);

        connect(store(`-`, Lang.unknown, Sense.punctuation, origin),
                Role(Rel.definedAs),
                store(`hyphen`, Lang.en, Sense.noun, origin),
                origin, 1.0);

        connect(store(`-`, Lang.unknown, Sense.punctuation, origin),
                Role(Rel.definedAs),
                store(`hyphen-minus`, Lang.en, Sense.noun, origin),
                origin, 1.0);

        connect(store(`?`, Lang.unknown, Sense.punctuation, origin),
                Role(Rel.definedAs),
                store(`question mark`, Lang.en, Sense.noun, origin),
                origin, 1.0);

        connect(store(`!`, Lang.unknown, Sense.punctuation, origin),
                Role(Rel.definedAs),
                store(`exclamation mark`, Lang.en, Sense.noun, origin),
                origin, 1.0);

        connect1toM(store(`.`, Lang.unknown, Sense.punctuation, origin),
                    Role(Rel.definedAs),
                    store([`full stop`, `period`], Lang.en, Sense.noun, origin),
                    origin, 1.0);

        connectMto1(store([`’`, `'`], Lang.unknown, Sense.punctuation, origin),
                    Role(Rel.definedAs),
                    store(`apostrophe`, Lang.en, Sense.noun, origin),
                    origin, 1.0);

        connectMto1(store([`‒`, `–`, `—`, `―`], Lang.unknown, Sense.punctuation, origin),
                    Role(Rel.definedAs),
                    store(`dash`, Lang.en, Sense.noun, origin),
                    origin, 1.0);

        connectMto1(store([`‘’`, `“”`, `''`, `""`], Lang.unknown, Sense.punctuation, origin),
                    Role(Rel.definedAs),
                    store(`quotation marks`, Lang.en, Sense.noun, origin),
                    origin, 1.0);

        connectMto1(store([`…`, `...`], Lang.unknown, Sense.punctuation, origin),
                    Role(Rel.definedAs),
                    store(`ellipsis`, Lang.en, Sense.noun, origin),
                    origin, 1.0);

        connect(store(`()`, Lang.unknown, Sense.punctuation, origin),
                Role(Rel.definedAs),
                store(`parenthesis`, Lang.en, Sense.noun, origin),
                origin, 1.0);

        connect(store(`{}`, Lang.unknown, Sense.punctuation, origin),
                Role(Rel.definedAs),
                store(`curly braces`, Lang.en, Sense.noun, origin),
                origin, 1.0);

        connectMto1(store([`[]`, `()`, `{}`, `⟨⟩`], Lang.unknown, Sense.punctuation, origin),
                    Role(Rel.definedAs),
                    store(`brackets`, Lang.en, Sense.noun, origin),
                    origin, 1.0);

        learnNumerals();
    }

    /// Learn Numerals (Groupings/Aggregates) (MÄngdmått)
    void learnNumerals()
    {
        learnRomanLatinNumerals();

        const origin = Origin.manual;

        connect(store(`single`, Lang.en, Sense.numeral, origin),
                Role(Rel.definedAs),
                store(`1`, Lang.math, Sense.integer, origin),
                origin, 1.0);
        connect(store(`pair`, Lang.en, Sense.numeral, origin),
                Role(Rel.definedAs),
                store(`2`, Lang.math, Sense.integer, origin),
                origin, 1.0);
        connect(store(`duo`, Lang.en, Sense.numeral, origin),
                Role(Rel.definedAs),
                store(`2`, Lang.math, Sense.integer, origin),
                origin, 1.0);
        connect(store(`triple`, Lang.en, Sense.numeral, origin),
                Role(Rel.definedAs),
                store(`3`, Lang.math, Sense.integer, origin),
                origin, 1.0);
        connect(store(`quadruple`, Lang.en, Sense.numeral, origin),
                Role(Rel.definedAs),
                store(`4`, Lang.math, Sense.integer, origin),
                origin, 1.0);
        connect(store(`quintuple`, Lang.en, Sense.numeral, origin),
                Role(Rel.definedAs),
                store(`5`, Lang.math, Sense.integer, origin),
                origin, 1.0);
        connect(store(`sextuple`, Lang.en, Sense.numeral, origin),
                Role(Rel.definedAs),
                store(`6`, Lang.math, Sense.integer, origin),
                origin, 1.0);
        connect(store(`septuple`, Lang.en, Sense.numeral, origin),
                Role(Rel.definedAs),
                store(`7`, Lang.math, Sense.integer, origin),
                origin, 1.0);

        // Greek Numbering
        // TODO Also Latin?
        connect(store(`tetra`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                store(`4`, Lang.math, Sense.integer, origin), origin, 1.0);
        connect(store(`penta`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                store(`5`, Lang.math, Sense.integer, origin), origin, 1.0);
        connect(store(`hexa`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                store(`6`, Lang.math, Sense.integer, origin), origin, 1.0);
        connect(store(`hepta`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                store(`7`, Lang.math, Sense.integer, origin), origin, 1.0);
        connect(store(`octa`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                store(`8`, Lang.math, Sense.integer, origin), origin, 1.0);
        connect(store(`nona`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                store(`9`, Lang.math, Sense.integer, origin), origin, 1.0);
        connect(store(`deca`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                store(`10`, Lang.math, Sense.integer, origin), origin, 1.0);
        connect(store(`hendeca`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                store(`11`, Lang.math, Sense.integer, origin), origin, 1.0);
        connect(store(`dodeca`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                store(`12`, Lang.math, Sense.integer, origin), origin, 1.0);
        connect(store(`trideca`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                store(`13`, Lang.math, Sense.integer, origin), origin, 1.0);
        connect(store(`tetradeca`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                store(`14`, Lang.math, Sense.integer, origin), origin, 1.0);
        connect(store(`pentadeca`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                store(`15`, Lang.math, Sense.integer, origin), origin, 1.0);
        connect(store(`hexadeca`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                store(`16`, Lang.math, Sense.integer, origin), origin, 1.0);
        connect(store(`heptadeca`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                store(`17`, Lang.math, Sense.integer, origin), origin, 1.0);
        connect(store(`octadeca`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                store(`18`, Lang.math, Sense.integer, origin), origin, 1.0);
        connect(store(`enneadeca`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                store(`19`, Lang.math, Sense.integer, origin), origin, 1.0);
        connect(store(`icosa`, Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                store(`20`, Lang.math, Sense.integer, origin), origin, 1.0);

        learnEnglishOrdinalShorthands();
        learnSwedishOrdinalShorthands();

        // Aggregate
        connect(store(`dozen`, Lang.en, Sense.numeral, origin),
                Role(Rel.definedAs),
                store(`12`, Lang.math, Sense.integer, origin),
                origin, 1.0);
        connect(store(`baker's dozen`, Lang.en, Sense.numeral, origin),
                Role(Rel.definedAs),
                store(`13`, Lang.math, Sense.integer, origin),
                origin, 1.0);
        connect(store(`tjog`, Lang.sv, Sense.numeral, origin),
                Role(Rel.definedAs),
                store(`20`, Lang.math, Sense.integer, origin),
                origin, 1.0);
        connect(store(`flak`, Lang.sv, Sense.numeral, origin),
                Role(Rel.definedAs),
                store(`24`, Lang.math, Sense.integer, origin),
                origin, 1.0);
        connect(store(`skock`, Lang.sv, Sense.numeral, origin),
                Role(Rel.definedAs),
                store(`60`, Lang.math, Sense.integer, origin),
                origin, 1.0);

        connectMto1(store([`dussin`, `tolft`], Lang.sv, Sense.numeral, origin),
                    Role(Rel.definedAs),
                    store(`12`, Lang.math, Sense.integer, origin),
                    origin, 1.0);

        connect(store(`gross`, Lang.en, Sense.numeral, origin),
                Role(Rel.definedAs),
                store(`144`, Lang.math, Sense.integer, origin),
                origin, 1.0);
        connect(store(`gross`, Lang.sv, Sense.numeral, origin), // TODO Support [Lang.en, Lang.sv]
                Role(Rel.definedAs),
                store(`144`, Lang.math, Sense.integer, origin),
                origin, 1.0);

        connect(store(`small gross`, Lang.en, Sense.numeral, origin),
                Role(Rel.definedAs),
                store(`120`, Lang.math, Sense.integer, origin),
                origin, 1.0);

        connect(store(`great gross`, Lang.en, Sense.numeral, origin),
                Role(Rel.definedAs),
                store(`1728`, Lang.math, Sense.integer, origin),
                origin, 1.0);
    }

    /** Learn Roman (Latin) Numerals.
        See also: https://en.wikipedia.org/wiki/Roman_numerals#Reading_Roman_numerals
        */
    void learnRomanLatinNumerals()
    {
        enum origin = Origin.manual;

        enum pairs = [tuple(`I`, `1`),
                      tuple(`V`, `5`),
                      tuple(`X`, `10`),
                      tuple(`L`, `50`),
                      tuple(`C`, `100`),
                      tuple(`D`, `500`),
                      tuple(`M`, `1000`)];
        foreach (pair; pairs)
        {
            connect(store(pair[0], Lang.la, Sense.numeral, origin), Role(Rel.definedAs),
                    store(pair[1], Lang.math, Sense.integer, origin), origin, 1.0);
        }

        connect(store(`ūnus`, Lang.la, Sense.numeralMasculine, origin), Role(Rel.definedAs),
                store(`1`, Lang.math, Sense.integer, origin), origin, 1.0);
        connect(store(`ūna`, Lang.la, Sense.numeralFeminine, origin), Role(Rel.definedAs),
                store(`1`, Lang.math, Sense.integer, origin), origin, 1.0);
        connect(store(`ūnum`, Lang.la, Sense.numeralNeuter, origin), Role(Rel.definedAs),
                store(`1`, Lang.math, Sense.integer, origin), origin, 1.0);

        connect(store(`duo`, Lang.la, Sense.numeralMasculine, origin), Role(Rel.definedAs),
                store(`2`, Lang.math, Sense.integer, origin), origin, 1.0);
        connect(store(`duae`, Lang.la, Sense.numeralFeminine, origin), Role(Rel.definedAs),
                store(`2`, Lang.math, Sense.integer, origin), origin, 1.0);
        connect(store(`duo`, Lang.la, Sense.numeralNeuter, origin), Role(Rel.definedAs),
                store(`2`, Lang.math, Sense.integer, origin), origin, 1.0);

        connect(store(`trēs`, Lang.la, Sense.numeralMasculine, origin), Role(Rel.definedAs),
                store(`3`, Lang.math, Sense.integer, origin), origin, 1.0);
        connect(store(`trēs`, Lang.la, Sense.numeralFeminine, origin), Role(Rel.definedAs),
                store(`3`, Lang.math, Sense.integer, origin), origin, 1.0);
        connect(store(`tria`, Lang.la, Sense.numeralNeuter, origin), Role(Rel.definedAs),
                store(`3`, Lang.math, Sense.integer, origin), origin, 1.0);

        connect(store(`quattuor`, Lang.la, Sense.numeral, origin), Role(Rel.definedAs),
                store(`4`, Lang.math, Sense.integer, origin), origin, 1.0);

        connect(store(`quīnque`, Lang.la, Sense.numeral, origin), Role(Rel.definedAs),
                store(`5`, Lang.math, Sense.integer, origin), origin, 1.0);

        connect(store(`sex`, Lang.la, Sense.numeral, origin), Role(Rel.definedAs),
                store(`6`, Lang.math, Sense.integer, origin), origin, 1.0);

        connect(store(`septem`, Lang.la, Sense.numeral, origin), Role(Rel.definedAs),
                store(`7`, Lang.math, Sense.integer, origin), origin, 1.0);

        connect(store(`octō`, Lang.la, Sense.numeral, origin), Role(Rel.definedAs),
                store(`8`, Lang.math, Sense.integer, origin), origin, 1.0);

        connect(store(`novem`, Lang.la, Sense.numeral, origin), Role(Rel.definedAs),
                store(`9`, Lang.math, Sense.integer, origin), origin, 1.0);

        connect(store(`decem`, Lang.la, Sense.numeral, origin), Role(Rel.definedAs),
                store(`10`, Lang.math, Sense.integer, origin), origin, 1.0);

        connect(store(`quīnquāgintā`, Lang.la, Sense.numeral, origin), Role(Rel.definedAs),
                store(`50`, Lang.math, Sense.integer, origin), origin, 1.0);

        connect(store(`Centum`, Lang.la, Sense.numeral, origin), Role(Rel.definedAs),
                store(`50`, Lang.math, Sense.integer, origin), origin, 1.0);

        connect(store(`Quīngentī`, Lang.la, Sense.numeral, origin), Role(Rel.definedAs),
                store(`100`, Lang.math, Sense.integer, origin), origin, 1.0);

        connect(store(`Mīlle`, Lang.la, Sense.numeral, origin), Role(Rel.definedAs),
                store(`500`, Lang.math, Sense.integer, origin), origin, 1.0);
    }

    /** Learn English Ordinal Number Shorthands.
     */
    void learnEnglishOrdinalShorthands()
    {
        enum pairs = [tuple(`1st`, `first`),
                      tuple(`2nd`, `second`),
                      tuple(`3rd`, `third`),
                      tuple(`4th`, `fourth`),
                      tuple(`5th`, `fifth`),
                      tuple(`6th`, `sixth`),
                      tuple(`7th`, `seventh`),
                      tuple(`8th`, `eighth`),
                      tuple(`9th`, `ninth`),
                      tuple(`10th`, `tenth`),
                      tuple(`11th`, `eleventh`),
                      tuple(`12th`, `twelfth`),
                      tuple(`13th`, `thirteenth`),
                      tuple(`14th`, `fourteenth`),
                      tuple(`15th`, `fifteenth`),
                      tuple(`16th`, `sixteenth`),
                      tuple(`17th`, `seventeenth`),
                      tuple(`18th`, `eighteenth`),
                      tuple(`19th`, `nineteenth`),
                      tuple(`20th`, `twentieth`),
                      tuple(`21th`, `twenty-first`),
                      tuple(`30th`, `thirtieth`),
                      tuple(`40th`, `fourtieth`),
                      tuple(`50th`, `fiftieth`),
                      tuple(`60th`, `sixtieth`),
                      tuple(`70th`, `seventieth`),
                      tuple(`80th`, `eightieth`),
                      tuple(`90th`, `ninetieth`),
                      tuple(`100th`, `one hundredth`),
                      tuple(`1000th`, `one thousandth`),
                      tuple(`1000000th`, `one millionth`),
                      tuple(`1000000000th`, `one billionth`)];
        foreach (pair; pairs)
        {
            const abbr = pair[0];
            const ordinal = pair[1];
            connect(store(abbr, Lang.en, Sense.numeralOrdinal, Origin.manual), Role(Rel.abbreviationFor),
                    store(ordinal, Lang.en, Sense.numeralOrdinal, Origin.manual), Origin.manual, 1.0);
            connect(store(abbr[0 .. $-2] ~ `:` ~ abbr[$-2 .. $],
                          Lang.sv, Sense.numeralOrdinal, Origin.manual), Role(Rel.abbreviationFor),
                    store(ordinal,
                          Lang.sv, Sense.numeralOrdinal, Origin.manual), Origin.manual, 0.5);
        }
    }

    /** Learn Swedish Ordinal Shorthands.
     */
    void learnSwedishOrdinalShorthands()
    {
        enum pairs = [tuple(`1:a`, `första`),
                      tuple(`2:a`, `andra`),
                      tuple(`3:a`, `tredje`),
                      tuple(`4:e`, `fjärde`),
                      tuple(`5:e`, `femte`),
                      tuple(`6:e`, `sjätte`),
                      tuple(`7:e`, `sjunde`),
                      tuple(`8:e`, `åttonde`),
                      tuple(`9:e`, `nionde`),
                      tuple(`10:e`, `tionde`),
                      tuple(`11:e`, `elfte`),
                      tuple(`12:e`, `tolfte`),
                      tuple(`13:e`, `trettonde`),
                      tuple(`14:e`, `fjortonde`),
                      tuple(`15:e`, `femtonde`),
                      tuple(`16:e`, `sextonde`),
                      tuple(`17:e`, `sjuttonde`),
                      tuple(`18:e`, `artonde`),
                      tuple(`19:e`, `nittonde`),
                      tuple(`20:e`, `tjugonde`),
                      tuple(`21:a`, `tjugoförsta`),
                      tuple(`22:a`, `tjugoandra`),
                      tuple(`23:e`, `tjugotredje`),
                      // ..
                      tuple(`30:e`, `trettionde`),
                      tuple(`40:e`, `fyrtionde`),
                      tuple(`50:e`, `femtionde`),
                      tuple(`60:e`, `sextionde`),
                      tuple(`70:e`, `sjuttionde`),
                      tuple(`80:e`, `åttionde`),
                      tuple(`90:e`, `nittionde`),
                      tuple(`100:e`, `hundrade`),
                      tuple(`1000:e`, `tusende`),
                      tuple(`1000000:e`, `miljonte`)];
        foreach (pair; pairs)
        {
            connect(store(pair[0], Lang.sv, Sense.numeralOrdinal, Origin.manual), Role(Rel.abbreviationFor),
                    store(pair[1], Lang.sv, Sense.numeralOrdinal, Origin.manual), Origin.manual, 1.0);
        }
    }

    /** Learn Math.
     */
    void learnPhysics()
    {
        learnMto1(Lang.en, rdT(`../knowledge/en/si_base_unit_name.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `SI base unit name noun`, Sense.baseSIUnit, Sense.noun, 1.0);
        // TODO Name Symbol, Quantity, In SI units, In Si base units
        learnMto1(Lang.en, rdT(`../knowledge/en/si_derived_unit_name.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `SI derived unit name noun`, Sense.derivedSIUnit, Sense.noun, 1.0);
    }

    void learnComputers()
    {
        learnMto1(Lang.en, rdT(`../knowledge/en/programming_language.txt`).splitter('\n').filter!(w => !w.empty),
                  Role(Rel.instanceOf), `programming language`, Sense.languageProgramming, Sense.language, 1.0);
        learnCode();
    }

    void learnCode()
    {
        learnCodeInGeneral();
        learnDCode;
    }

    void learnCodeInGeneral()
    {
        connect(store(`keyword`, Lang.en, Sense.adjective, Origin.manual), Role(Rel.synonymFor),
                store(`reserved word`, Lang.en, Sense.adjective, Origin.manual), Origin.manual, 1.0, true);
    }

    void learnDCode()
    {
        enum attributes = [`@property`, `@safe`, `@trusted`, `@system`, `@disable`];

        connectMto1(store(attributes, Lang.d, Sense.unknown, Origin.manual), Role(Rel.instanceOf),
                    store("attribute", Lang.d, Sense.nounAbstract, Origin.manual), Origin.manual, 1.0);

        enum keywords = [`abstract`, `alias`, `align`, `asm`,
                         `assert`, `auto`, `body`, `bool`,
                         `byte`, `case`, `cast`, `catch`,
                         `char`, `class`, `const`, `continue`,
                         `dchar`, `debug`, `default`, `delegate`,
                         `deprecated`, `do`, `double`, `else`,
                         `enum`, `export`, `extern`, `false`,
                         `final`, `finally`, `float`, `for`,
                         `foreach`, `function`, `goto`, `if`,
                         `import`, `in`, `inout`, `int`,
                         `interface`, `invariant`, `is`, `long`,
                         `macro`, `mixin`, `module`, `new`,
                         `null`, `out`, `override`, `package`,
                         `pragma`, `private`, `protected`, `public`,
                         `real`, `ref`, `return`, `scope`,
                         `short`, `static`, `struct`, `super`,
                         `switch`, `synchronized`, `template`, `this`,
                         `throw`, `true`, `try`, `typeid`,
                         `typeof`, `ubyte`, `uint`, `ulong`,
                         `union`, `unittest`, `ushort`, `version`,
                         `void`, `wchar`, `while`, `with` ];

        connectMto1(store(keywords, Lang.d, Sense.unknown, Origin.manual), Role(Rel.instanceOf),
                    store("keyword", Lang.d, Sense.nounAbstract, Origin.manual), Origin.manual, 1.0);

        enum elements = [ tuple(`AA`, `associative array`),
                          tuple(`AAs`, `associative arrays`),

                          tuple(`mut`, `mutable`),
                          tuple(`imm`, `immutable`),
                          tuple(`const`, `constant`),

                          tuple(`int`, `integer`),
                          tuple(`long`, `long integer`),
                          tuple(`short`, `short integer`),
                          tuple(`cent`, `cent integer`),

                          tuple(`uint`, `unsigned integer`),
                          tuple(`ulong`, `unsigned long integer`),
                          tuple(`ushort`, `unsigned short integer`),
                          tuple(`ucent`, `unsigned cent integer`),

                          tuple(`ctor`, `constructor`),
                          tuple(`dtor`, `destructor`),
                         ];

        foreach (e; elements)
        {
            connect(store(e[0], Lang.d, Sense.unknown, Origin.manual), Role(Rel.abbreviationFor),
                    store(e[1], Lang.d, Sense.unknown, Origin.manual), Origin.manual, 1.0);
        }
    }

    /** Learn English Irregular Verbs.
     */
    void learnEnglishOther()
    {
        connectMto1(store([`preserve food`,
                           `cure illness`,
                           `augment cosmetics`],
                          Lang.en, Sense.noun, Origin.manual),
                    Role(Rel.uses),
                    store(`herb`, Lang.en, Sense.noun, Origin.manual),
                    Origin.manual, 1.0);

        connectMto1(store([`enrich taste of food`,
                           `improve taste of food`,
                           `increase taste of food`],
                          Lang.en, Sense.noun, Origin.manual),
                    Role(Rel.uses),
                    store(`spice`, Lang.en, Sense.noun, Origin.manual),
                    Origin.manual, 1.0);

        connect1toM(store(`herb`, Lang.en, Sense.noun, Origin.manual),
                    Role(Rel.madeOf),
                    store([`leaf`, `plant`], Lang.en, Sense.noun, Origin.manual),
                    Origin.manual, 1.0);

        connect1toM(store(`spice`, Lang.en, Sense.noun, Origin.manual),
                    Role(Rel.madeOf),
                    store([`root`, `plant`], Lang.en, Sense.noun, Origin.manual),
                    Origin.manual, 1.0);
    }

    /** Learn Swedish Irregular Verb.
        See also: http://www.lardigsvenska.com/2010/10/oregelbundna-verb.html
    */
    void learnSwedishIrregularVerb(S)(S imperative,
                                      S infinitive,
                                      S present,
                                      S pastSimple,
                                      S pastParticiple) if (isSomeString!S) // pastParticiple
    {
        const lang = Lang.sv;
        const origin = Origin.manual;
        auto all = [tryStore(imperative, lang, Sense.verbImperative, origin),
                    tryStore(infinitive, lang, Sense.verbInfinitive, origin),
                    tryStore(present, lang, Sense.verbPresent, origin),
                    tryStore(pastSimple, lang, Sense.verbPast, origin),
                    tryStore(pastParticiple, lang, Sense.verbPastParticiple, origin)];
        connectAll(Role(Rel.formOfVerb), all.filter!(a => a.defined), lang, origin);
    }

    /** Learn Swedish (Regular) Verbs.
     */
    void learnSwedishRegularVerbs()
    {
        learnSwedishIrregularVerb(`kläd`, `kläda`, `kläder`, `klädde`, `klätt`);
        learnSwedishIrregularVerb(`pryd`, `pryda`, `pryder`, `prydde`, `prytt`);
    }

    /** Learn Swedish (Irregular) Verbs.
    */
    void learnSwedishIrregularVerbs()
    {
        learnSwedishIrregularVerb(`eka`, `eka`, `ekar`, `ekade`, `ekat`); // English:echo
        learnSwedishIrregularVerb(`ge`, `ge`, `ger`, `gav`, `gett`);
        learnSwedishIrregularVerb(`ge`, `ge`, `ger`, `gav`, `givit`);
        learnSwedishIrregularVerb(`ange`, `ange`, `anger`, `angav`, `angett`);
        learnSwedishIrregularVerb(`ange`, `ange`, `anger`, `angav`, `angivit`);
        learnSwedishIrregularVerb(`anse`, `anse`, `anser`, `ansåg`, `ansett`);
        learnSwedishIrregularVerb(`avgör`, `avgöra`, `avgör`, `avgjorde`, `avgjort`);
        learnSwedishIrregularVerb(`avstå`, `avstå`, `avstår`, `avstod`, `avstått`);
        learnSwedishIrregularVerb(`be`, `be`, `ber`, `bad`, `bett`);
        learnSwedishIrregularVerb(`bestå`, `bestå`, `består`, `bestod`, `bestått`);
        learnSwedishIrregularVerb([], [], `bör`, `borde`, `bort`);
        learnSwedishIrregularVerb(`dra`, `dra`, `drar`, `drog`, `dragit`);
        learnSwedishIrregularVerb([], `duga`, `duger`, `dög`, `dugit`); // TODO [`dög`, `dugde`]
        learnSwedishIrregularVerb([], `duga`, `duger`, `dugde`, `dugit`);
        learnSwedishIrregularVerb(`dyk`, `dyka`, `dyker`, `dök`, `dykit`); // TODO [`dök`, `dykte`]
        learnSwedishIrregularVerb(`dyk`, `dyka`, `dyker`, `dykte`, `dykit`);
        learnSwedishIrregularVerb(`dö`, `dö`, `dör`, `dog`, `dött`);
        learnSwedishIrregularVerb(`dölj`, `dölja`, `döljer`, `dolde`, `dolt`);
        learnSwedishIrregularVerb(`ersätt`, `ersätta`, `ersätter`, `ersatte`, `ersatt`);
        learnSwedishIrregularVerb(`fortsätt`, `fortsätta`, `fortsätter`, `fortsatte`, `fortsatt`);
        learnSwedishIrregularVerb(`framstå`, `framstå`, `framstår`, `framstod`, `framstått`);
        learnSwedishIrregularVerb(`få`, `få`, `får`, `fick`, `fått`);
        learnSwedishIrregularVerb(`förstå`, `förstå`, `förstår`, `förstod`, `förstått`);
        learnSwedishIrregularVerb(`förutsätt`, `förutsätta`, `förutsätter`, `förutsatte`, `förutsatt`);
        learnSwedishIrregularVerb(`gläd`, `glädja`, `gläder`, `gladde`, `glatt`);
        learnSwedishIrregularVerb(`gå`, `gå`, `går`, `gick`, `gått`);
        learnSwedishIrregularVerb(`gör`, `göra`, `gör`, `gjorde`, `gjort`);
        learnSwedishIrregularVerb(`ha`, `ha`, `har`, `hade`, `haft`);
        learnSwedishIrregularVerb([], `heta`, `heter`, `hette`, `hetat`);
        learnSwedishIrregularVerb([], `ingå`, `ingår`, `ingick`, `ingått`);
        learnSwedishIrregularVerb(`inse`, `inse`, `inser`, `insåg`, `insett`);
        learnSwedishIrregularVerb(`kom`, `komma`, `kommer`, `kom`, `kommit`);
        learnSwedishIrregularVerb([], `kunna`, `kan`, `kunde`, `kunnat`);
        learnSwedishIrregularVerb(`le`, `le`, `ler`, `log`, `lett`);
        learnSwedishIrregularVerb(`lev`, `leva`, `lever`, `levde`, `levt`);
        learnSwedishIrregularVerb(`ligg`, `ligga`, `ligger`, `låg`, `legat`);
        learnSwedishIrregularVerb(`lägg`, `lägga`, `lägger`, `la`, `lagt`);
        learnSwedishIrregularVerb(`missförstå`, `missförstå`, `missförstår`, `missförstod`, `missförstått`);
        learnSwedishIrregularVerb([], [], `måste`, `var tvungen`, `varit tvungen`);
        learnSwedishIrregularVerb(`se`, `se`, `ser`, `såg`, `sett`);
        learnSwedishIrregularVerb(`skilj`, `skilja`, `skiljer`, `skilde`, `skilt`);
        learnSwedishIrregularVerb([], [], `ska`, `skulle`, []);
        learnSwedishIrregularVerb(`smaksätt`, `smaksätta`, `smaksätter`, `smaksatte`, `smaksatt`);
        learnSwedishIrregularVerb(`sov`, `sova`, `sover`, `sov`, `sovit`);
        learnSwedishIrregularVerb(`sprid`, `sprida`, `sprider`, `spred`, `spridit`);
        learnSwedishIrregularVerb(`stjäl`, `stjäla`, `stjäl`, `stal`, `stulit`);
        learnSwedishIrregularVerb(`stå`, `stå`, `står`, `stod`, `stått`);
        learnSwedishIrregularVerb(`stöd`, `stödja`, `stöder`, `stödde`, `stött`);
        learnSwedishIrregularVerb(`svälj`, `svälja`, `sväljer`, `svalde`, `svalt`);
        learnSwedishIrregularVerb(`säg`, `säga`, `säger`, `sa`, `sagt`);
        learnSwedishIrregularVerb(`sälj`, `sälja`, `säljer`, `sålde`, `sålt`);
        learnSwedishIrregularVerb(`sätt`, `sätta`, `sätter`, `satte`, `satt`);
        learnSwedishIrregularVerb(`ta`, `ta`, `tar`, `tog`, `tagit`);
        learnSwedishIrregularVerb(`tillsätt`, `tillsätta`, `tillsätter`, `tillsatte`, `tillsatt`);
        learnSwedishIrregularVerb(`umgås`, `umgås`, `umgås`, `umgicks`, `umgåtts`);
        learnSwedishIrregularVerb(`uppge`, `uppge`, `uppger`, `uppgav`, `uppgivit`);
        learnSwedishIrregularVerb(`utgå`, `utgå`, `utgår`, `utgick`, `utgått`);
        learnSwedishIrregularVerb(`var`, `vara`, `är`, `var`, `varit`);
        learnSwedishIrregularVerb([], `veta`, `vet`, `visste`, `vetat`);
        learnSwedishIrregularVerb(`vik`, `vika`, `viker`, `vek`, `vikt`);
        learnSwedishIrregularVerb([], `vilja`, `vill`, `ville`, `velat`);
        learnSwedishIrregularVerb(`välj`, `välja`, `väljer`, `valde`, `valt`);
        learnSwedishIrregularVerb(`vänj`, `vänja`, `vänjer`, `vande`, `vant`);
        learnSwedishIrregularVerb(`väx`, `växa`, `växer`, `växte`, `växt`);
        learnSwedishIrregularVerb(`återge`, `återge`, `återger`, `återgav`, `återgivit`);
        learnSwedishIrregularVerb(`översätt`, `översätta`, `översätter`, `översatte`, `översatt`);
        learnSwedishIrregularVerb(`tyng`, `tynga`, `tynger`, `tyngde`, `tyngt`);
        learnSwedishIrregularVerb(`glöm`, `glömma`, `glömmer`, `glömde`, `glömt`);
        learnSwedishIrregularVerb(`förgät`, `förgäta`, `förgäter`, `förgat`, `förgätit`);

        // TODO Allow alternatives for all arguments
        static if (false)
        {
            learnSwedishIrregularVerb(`ids`, `idas`, [`ids`, `ides`], `iddes`, [`itts`, `idats`]);
            learnSwedishIrregularVerb(`gitt`, `gitta;1`, `gitter`, [`gitte`, `get`, `gat`], `gittat;1`);
        }

    }

    /** Learn Adjective in language $(D lang).
     */
    void learnAdjective(S)(Lang lang,
                           S nominative,
                           S comparative,
                           S superlative,
                           S elative = [],
                           S exzessive = []) if (isSomeString!S)
    {
        const origin = Origin.manual;
        auto all = [tryStore(nominative, lang, Sense.adjectiveNominative, origin),
                    tryStore(comparative, lang, Sense.adjectiveComparative, origin),
                    tryStore(superlative, lang, Sense.adjectiveSuperlative, origin),
                    tryStore(elative, lang, Sense.adjectiveElative, origin),
                    tryStore(exzessive, lang, Sense.adjectiveExzessive, origin)];
        connectAll(Role(Rel.formOfAdjective), all.filter!(a => a.defined), lang, origin);
    }

    void learnAdjective(S)(Lang lang,
                           S[3] forms) if (isSomeString!S)
    {
        return learnAdjective(lang, forms[0], forms[1], forms[2]);
    }


    /** Learn Swedish Adjectives.
     */
    void learnSwedishAdjectives()
    {
        enum lang = Lang.sv;
        learnAdjective(lang, `tung`, `tyngre`, `tyngst`);
        learnAdjective(lang, `få`, `färre`, `färst`);
        learnAdjective(lang, `många`, `fler`, `flest`);
        learnAdjective(lang, `bra`, `bättre`, `bäst`);
        learnAdjective(lang, `dålig`, `sämre`, `sämst`);
        learnAdjective(lang, `liten`, `mindre`, `minst`);
        learnAdjective(lang, `gammal`, `äldre`, `äldst`);
        learnAdjective(lang, `hög`, `högre`, `högst`);
        learnAdjective(lang, `låg`, `lägre`, `lägst`);
        learnAdjective(lang, `lång`, `längre`, `längst`);
        learnAdjective(lang, `stor`, `större`, `störst`);
        learnAdjective(lang, `tung`, `tyngre`, `tyngst`);
        learnAdjective(lang, `ung`, `yngre`, `yngst`);
        learnAdjective(lang, `mycket`, `mer`, `mest`);
        learnAdjective(lang, `gärna`, `hellre`, `helst`);
    }

    /** Learn English Adjectives.
     */
    void learnEnglishAdjectives()
    {
        learnEnglishIrregularAdjectives();
        const lang = Lang.en;
        connectMto1(store([`ablaze`, `abreast`, `afire`, `afloat`, `afraid`, `aghast`, `aglow`,
                           `alert`, `alike`, `alive`, `alone`, `aloof`, `ashamed`, `asleep`,
                           `awake`, `aware`, `fond`, `unaware`],
                          lang, Sense.adjectivePredicateOnly, Origin.manual),
                    Role(Rel.instanceOf),
                    store(`predicate only adjective`,
                          lang, Sense.noun, Origin.manual),
                    Origin.manual);
        learnMto1(Lang.en, rdT(`../knowledge/en/adjective.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `adjective`, Sense.adjective, Sense.noun, 1.0);
    }

    /** Learn English Irregular Adjectives.
     */
    void learnEnglishIrregularAdjectives()
    {
        enum lang = Lang.en;
        learnAdjective(lang, `good`, `better`, `best`);
        learnAdjective(lang, `well`, `better`, `best`);

        learnAdjective(lang, `bad`, `worse`, `worst`);

        learnAdjective(lang, `little`, `less`, `least`);
        learnAdjective(lang, `little`, `smaller`, `smallest`);

        learnAdjective(lang, `much`, `more`, `most`);
        learnAdjective(lang, `many`, `more`, `most`);

        learnAdjective(lang, `far`, `further`, `furthest`);
        learnAdjective(lang, `far`, `farther`, `farthest`);

        learnAdjective(lang, `big`, `larger`, `largest`);
        learnAdjective(lang, `big`, `bigger`, `biggest`);
        learnAdjective(lang, `large`, `larger`, `largest`);

        learnAdjective(lang, `old`, `older`, `oldest`);
        learnAdjective(lang, `old`, `elder`, `eldest`);
    }

    /** Learn German Irregular Adjectives.
     */
    void learnGermanIrregularAdjectives()
    {
        enum lang = Lang.de;

        learnAdjective(lang, `schön`, `schöner`, `schönste`);
        learnAdjective(lang, `wild`, `wilder`, `wildeste`);
        learnAdjective(lang, `groß`, `größer`, `größte`);

        learnAdjective(lang, `gut`, `besser`, `beste`);
        learnAdjective(lang, `viel`, `mehr`, `meiste`);
        learnAdjective(lang, `gern`, `lieber`, `liebste`);
        learnAdjective(lang, `hoch`, `höher`, `höchste`);
        learnAdjective(lang, `wenig`, `weniger`, `wenigste`);
        learnAdjective(lang, `wenig`, `minder`, `mindeste`);
        learnAdjective(lang, `nahe`, `näher`, `nähchste`);
    }

    /** Learn Swedish Grammar.
     */
    void learnSwedishGrammar()
    {
        enum lang = Lang.sv;
        connectMto1(store([`grundform`, `genitiv`], lang, Sense.noun, Origin.manual),
                    Role(Rel.instanceOf),
                    store(`kasus`, lang, Sense.noun, Origin.manual),
                    Origin.manual);
        connectMto1(store([`reale`, `neutrum`], lang, Sense.noun, Origin.manual),
                    Role(Rel.instanceOf),
                    store(`genus`, lang, Sense.noun, Origin.manual),
                    Origin.manual);
    }

    /** Lookup-or-Store $(D Node) named $(D expr) in language $(D lang). */
    Nd store(S)(S expr,
                Lang lang,
                Sense sense,
                Origin origin,
                Ctx context = Ctx.asUndefined,
                Manner manner = Manner.formal,
                bool isRegexp = false,
                ubyte meaningNr = 0,
                bool normalizeExpr = true) if (isSomeString!S)
        in { assert(!expr.empty); }
    body
    {
        auto lemma = Lemma(tryReuseExpr(expr), lang, sense, context, manner, isRegexp, meaningNr, normalizeExpr);
        if (const lemmaNd = lemma in db.ndByLemma)
        {
            return *lemmaNd; // lookup
        }
        else
        {
            const specializedLemma = internLemma(lemma);
            if (specializedLemma != lemma) // if an existing more specialized lemma was found
            {
                return db.ndByLemma[specializedLemma];
            }

            auto wordsSplit = lemma.expr.findSplit(expressionWordSeparator);
            if (!wordsSplit[1].empty) // TODO add implicit bool conversion to return of findSplit()
            {
                ++stat.multiWordNodeLemmaCount;
                stat.exprWordCountSum += lemma.expr.count(expressionWordSeparator) + 1;
            }
            else
            {
                stat.exprWordCountSum += 1;
            }

            // store
            assert(db.allNodes.length <= nullIx);
            const cix = Nd(cast(Ix)db.allNodes.length);
            db.allNodes ~= Node(lemma, origin); // .. new node that is stored

            db.ndByLemma[lemma] = cix; // store index to ..
            stat.nodeStringLengthSum += lemma.expr.length;

            ++stat.nodeCountByLang[lemma.lang];
            ++stat.nodeCountBySense[lemma.sense];

            return cix;
        }
    }

    /** Try to Lookup-or-Store $(D Node) named $(D expr) in language $(D lang).
     */
    Nd tryStore(Expr expr,
                Lang lang,
                Sense sense,
                Origin origin,
                Ctx context = Ctx.asUndefined)
    {
        if (expr.empty)
            return Nd.asUndefined;
        return store(expr, lang, sense, origin, context);
    }

    Nd[] store(Exprs)(Exprs exprs,
                      Lang lang,
                      Sense sense,
                      Origin origin,
                      Ctx context = Ctx.asUndefined) if (isIterable!Exprs &&
                                                                     isSomeString!(ElementType!Exprs))
    {
        typeof(return) nds;
        foreach (expr; exprs)
        {
            nds ~= store(expr, lang, sense, origin, context);
        }
        return nds;
    }

    /** Directed Connect Many Sources $(D srcs) to Many Destinations $(D dsts).
     */
    Ln[] connectMtoN(S, D)(S srcs,
                           Role role,
                           D dsts,
                           Origin origin,
                           NWeight weight = 1.0,
                           bool checkExisting = false) if (isIterableOf!(S, Nd) &&
                                                           isIterableOf!(D, Nd))
    {
        typeof(return) linkIxes;
        foreach (src; srcs)
        {
            foreach (dst; dsts)
            {
                linkIxes ~= connect(src, role, dst, origin, weight, checkExisting);
            }
        }
        return linkIxes;
    }
    alias connectFanInFanOut = connectMtoN;

    /** Fully Connect Every-to-Every in $(D all).
        See also: http://forum.dlang.org/thread/iqkybajwdzcvdytakgvw@forum.dlang.org#post-iqkybajwdzcvdytakgvw:40forum.dlang.org
        See also: https://issues.dlang.org/show_bug.cgi?id=6788
    */
    Ln[] connectAll(R)(Role role,
                       R all,
                       Lang lang,
                       Origin origin,
                       NWeight weight = 1.0) if (isIterableOf!(R, Nd))
        in { assert(role.rel.isSymmetric); }
    body
    {
        typeof(return) linkIxes;
        size_t i = 0;
        // TODO use combinations.pairwise() when ForwardRange support has been addded
        foreach (me; all)
        {
            size_t j = 0;
            foreach (you; all)
            {
                if (j >= i)
                {
                    break;
                }
                linkIxes ~= connect(me, role, you, origin, weight);
                ++j;
            }
            ++i;
        }
        return linkIxes;
    }
    alias connectMtoM = connectAll;
    alias connectFully = connectAll;
    alias connectStar = connectAll;

    /** Fan-Out Connect $(D first) to Every in $(D rest). */
    Ln[] connect1toM(R)(Nd first,
                        Role role,
                        R rest,
                        Origin origin, NWeight weight = 1.0) if (isIterableOf!(R, Nd))
    {
        typeof(return) linkIxes;
        foreach (you; rest)
        {
            if (first != you)
            {
                linkIxes ~= connect(first, role, you, origin, weight, false);
            }
        }
        return linkIxes;
    }
    alias connectFanOut = connect1toM;

    /** Fan-In Connect $(D first) to Every in $(D rest). */
    Ln[] connectMto1(R)(R rest,
                        Role role,
                        Nd first,
                        Origin origin, NWeight weight = 1.0) if (isIterableOf!(R, Nd))
    {
        typeof(return) linkIxes;
        foreach (you; rest)
        {
            if (first != you)
            {
                linkIxes ~= connect(you, role, first, origin, weight);
            }
        }
        return linkIxes;
    }
    alias connectFanIn = connectMto1;

    /** Cyclic Connect Every in $(D all). */
    void connectCycle(R)(Rel rel, R all) if (isIterableOf!(R, Nd))
    {
    }
    alias connectCircle = connectCycle;

    /** Add Link from $(D src) to $(D dst) of type $(D rel) and weight $(D weight).
        TODO checkExisting is currently set to false because searching
        existing links is currently too slow
     */
    Ln connect(Nd src,
               Role role,
               Nd dst,
               Origin origin = Origin.unknown,
               NWeight weight = 1.0, // 1.0 means absolutely true for Origin manual
               bool checkExisting = false,
               bool warnExisting = false) in
    {
        assert(src != dst, (at(src).lemma.to!string ~
                            ` must not be equal to ` ~
                            at(dst).lemma.to!string));
    }
    body
    {
        if (src == dst) { return Ln.asUndefined; } // Don't allow self-reference for now

        if (checkExisting)
        {
            if (const existingLn = areConnected(src, role, dst, origin, weight))
            {
                if (warnExisting)
                {
                    dln(`info: Nodes "`,
                        at(src).lemma.expr, `" and "`,
                        at(dst).lemma.expr, `" already related as `,
                        role.rel);
                }
                return existingLn;
            }
        }

        // TODO group these
        assert(db.allLinks.length <= nullIx);
        auto ln = Ln(cast(Ix)db.allLinks.length);

        auto link = Link(role.reversion ? dst : src,
                         Role(role.rel, false, role.negation),
                         role.reversion ? src : dst,
                         origin);

        stat.linkConnectednessSum += 2;

        at(src).links ~= ln.forward;
        at(dst).links ~= ln.backward;
        stat.nodeConnectednessSum += 2;

        stat.symmetricRelCount += role.rel.isSymmetric;
        stat.transitiveRelCount += role.rel.isTransitive;
        ++stat.relCounts[role.rel];
        ++stat.linkSourceCounts[origin];

        if (origin == Origin.cn5)
        {
            link.setCN5Weight(weight);
            stat.weightSumCN5 += weight;
            stat.weightMinCN5 = min(weight, stat.weightMinCN5);
            stat.weightMaxCN5 = max(weight, stat.weightMaxCN5);
            ++stat.pweightHistogramCN5[link.pweight];
        }
        else if (origin == Origin.nell)
        {
            link.setNELLWeight(weight);
            stat.weightSumNELL += weight;
            stat.weightMinNELL = min(weight, stat.weightMinNELL);
            stat.weightMaxNELL = max(weight, stat.weightMaxNELL);
            ++stat.pweightHistogramNELL[link.pweight];
        }
        else
        {
            link.setManualWeight(weight);
        }

        propagateLinkNodes(link, src, dst);

        if (false)
        {
            dln(` src:`, at(src).lemma.expr,
                ` dst:`, at(dst).lemma.expr,
                ` rel:`, role.rel,
                ` origin:`, origin,
                ` negation:`, role.negation,
                ` reversion:`, role.reversion);
        }

        db.allLinks ~= link; // TODO Avoid copying here

        return ln; // db.allLinks.back;
    }
    alias relate = connect;

    import std.algorithm: splitter;

    /** Lookup Context by $(D name). */
    Ctx contextOfName(S)(S name) if (isSomeString!S)
    {
        auto context = anyContext;
        if (const ctx = name in db.ctxByName)
        {
            context = *ctx;
        }
        else
        {
            assert(stat.ctxCounter != stat.ctxCounter.max);
            context._ix = stat.ctxCounter++;
            db.contextNameByCtx[context] = name;
            db.ctxByName[name] = context;
        }
        return context;
    }

    /** Set Location of Node $(D cix) to $(D location) */
    void setLocation(Nd nd, in Location location)
    {
        writeln(this[nd]);
        assert (nd !in db.locations);
        db.locations[nd] = location;
    }

    /** If $(D link) node origins unknown propagate them from $(D link)
        itself. */
    bool propagateLinkNodes(ref Link link,
                            Nd src,
                            Nd dst)
    {
        bool done = false;
        if (!link.origin.defined)
        {
            // TODO prevent duplicate lookups to at
            if (!at(src).origin.defined) at(src).origin = link.origin;
            if (!at(dst).origin.defined) at(dst).origin = link.origin;
            done = true;
        }
        return done;
    }

    /** Show Network Relations.
     */
    void showRelations(uint indent_depth = 2)
    {
        writeln(`Link Count by Relation Type:`);

        import std.range: cycle;
        auto indent = `- `; // TODO use clever range plus indent_depth

        foreach (rel; enumMembers!Rel)
        {
            const count = stat.relCounts[rel];
            if (count)
            {
                writeln(indent, rel.to!string, `: `, count);
            }
        }

        writeln(`Node Count: `, db.allNodes.length);

        writeln(`Node Count by Origin:`);
        foreach (source; enumMembers!Origin)
        {
            const count = stat.linkSourceCounts[source];
            if (count)
            {
                writeln(indent, source.toNice, `: `, count);
            }
        }

        writeln(`Node Count by Language:`);
        foreach (lang; enumMembers!Lang)
        {
            const count = stat.nodeCountByLang[lang];
            if (count)
            {
                writeln(indent, lang.toHuman, ` : `, count);
            }
        }

        writeln(`Node Count by Sense:`);
        foreach (sense; enumMembers!Sense)
        {
            const count = stat.nodeCountBySense[sense];
            if (count)
            {
                writeln(indent, sense.toHuman, ` : `, count);
            }
        }

        writeln(`Stats:`);

        if (stat.weightSumCN5)
        {
            writeln(indent, `CN5 Weights Min,Max,Average: `, stat.weightMinCN5, ',', stat.weightMaxCN5, ',', cast(NWeight)stat.weightSumCN5/db.allLinks.length);
            writeln(indent, `CN5 Packed Weights Histogram: `, stat.pweightHistogramCN5);
        }
        if (stat.weightSumNELL)
        {
            writeln(indent, `NELL Weights Min,Max,Average: `, stat.weightMinNELL, ',', stat.weightMaxNELL, ',', cast(NWeight)stat.weightSumNELL/db.allLinks.length);
            writeln(indent, `NELL Packed Weights Histogram: `, stat.pweightHistogramNELL);
        }

        writeln(indent, `Node Count (All/Multi-Word): `,
                db.allNodes.length,
                `/`,
                stat.multiWordNodeLemmaCount);
        writeln(indent, `Lemma Expression Word Length Average: `, cast(real)stat.exprWordCountSum/db.ndByLemma.length);
        writeln(indent, `Link Count: `, db.allLinks.length);
        writeln(indent, `Link Count By Group:`);
        writeln(indent, `- Symmetric: `, stat.symmetricRelCount);
        writeln(indent, `- Transitive: `, stat.transitiveRelCount);

        writeln(indent, `Lemmas Expression Count: `, db.lemmasByExpr.length);

        writeln(indent, `Node Indexes by Lemma Count: `, db.ndByLemma.length);
        writeln(indent, `Node String Length Average: `, cast(NWeight)stat.nodeStringLengthSum/db.allNodes.length);

        writeln(indent, `Node Connectedness Average: `, cast(NWeight)stat.nodeConnectednessSum/db.allNodes.length);
        writeln(indent, `Link Connectedness Average: `, cast(NWeight)stat.linkConnectednessSum/db.allLinks.length);
    }

    /** Return Index to Link from $(D a) to $(D b) if present, otherwise Ln.max.
     */
    Ln areConnectedInOrder(Nd a, Role role, Nd b,
                           Origin origin = Origin.unknown,
                           NWeight nweight = 1.0)
    {
        const dir = (role.rel.isSymmetric ?
                     RelDir.any :
                     RelDir.forward);

        // dln("role: ", role, " ", origin, " ", nweight, " ", dir);

        foreach (aLn; at(a).links[].map!(ln => ln.raw))
        {
            const aLink = at(aLn);

            // dln("aLink.role: ", aLink.role, " ", aLink.origin, " ", aLink.nweight, " aLn: ", aLn);
            // dln(aLink.role.rel == role.rel, ", ",
            //     aLink.role.negation == role.negation, ", ",
            //     aLink.origin == origin, ", ",
            //     (aLink.actors[].canFind(Nd(b, dir))), ", ",
            //     abs(aLink.nweight - nweight) < 1.0e-2);

            if (aLink.role.rel == role.rel &&
                aLink.role.negation == role.negation && // no need to check reversion (all links are bidirectional)
                aLink.origin == origin &&
                (aLink.actors[].canFind(Nd(b, dir))) &&
                abs(aLink.nweight - nweight) < 1.0e-2) // TODO adjust
            {
                return aLn;
            }
        }

        return typeof(return).asUndefined;
    }

    /** Return Index to Link relating $(D a) to $(D b) in any direction if present, otherwise Ln.max.
        TODO warn about negation and reversion on existing rels
     */
    Ln areConnected(Nd a, Role role, Nd b,
                    Origin origin = Origin.unknown,
                    NWeight weight = 1.0)
    {
        return either(areConnectedInOrder(a, role, b, origin, weight),
                      areConnectedInOrder(b, role, a, origin, weight));
    }

    /** Return Index to Link relating if $(D a) and $(D b) if they are related. */
    Ln areConnected(in Lemma a, Role role, in Lemma b,
                    Origin origin = Origin.unknown,
                    NWeight weight = 1.0)
    {
        if (a in db.ndByLemma && // both lemmas exist
            b in db.ndByLemma)
        {
            return areConnected(db.ndByLemma[a],
                                role,
                                db.ndByLemma[b],
                                origin, weight);
        }
        return typeof(return).asUndefined;
    }

    enum durationInMsecs = 1000; // duration in milliseconds

    enum fuzzyExprMatchMaximumRecursionDepth = 8;

    import std.datetime: StopWatch;
    StopWatch showNodesSW;

    auto anagramsOf(S)(S expr) if (isSomeString!S)
    {
        const lsWord = expr.sorted; // letter-sorted expr
        return db.allNodes.filter!(node => (lsWord != node.lemma.expr.toLower && // don't include one-self
                                         lsWord == node.lemma.expr.toLower.sorted));
    }

    /** TODO: http://rosettacode.org/wiki/Anagrams/Deranged_anagrams#D */
    auto derangedAnagramsOf(S)(S expr) if (isSomeString!S)
    {
        return anagramsOf(expr);
    }

    /** Get Synonyms of $(D word) optionally with Matching Syllable Count.
        Set withSameSyllableCount to true to get synonyms which can be used to
        help in translating songs with same rhythm.
     */
    auto synonymsOf(S)(S expr,
                       Lang lang = Lang.unknown,
                       Sense sense = Sense.unknown,
                       bool withSameSyllableCount = false) if (isSomeString!S)
    {
        auto nds = ndsOf(expr, lang, sense);
        return nds;
    }

    /** Get Links of $(D nd) type $(D rel) learned from $(D origins).
    */
    auto lnsOf(Nd nd,
               Rel rel,
               Origin[] origins = [])
    {
        return at(nd).links[]
                     .filter!(ln => (at(ln).role.rel == rel &&
                                     (origins.empty ||
                                      origins.canFind(at(ln).origin))))
                     .map!(ln => ln.raw);
    }

    /** Get Nearest Neighbours (Nears) of $(D nd) over links of type $(D rel)
        learned from $(D origins).
    */
    auto nnsOf(Nd nd,
               Rel rel,
               Lang[] dstLangs = [],
               Origin[] origins = [])
    {
        writeln("nd: ", nd);
        foreach (ln; lnsOf(nd, rel, origins))
        {
            writeln("ln: ", ln);
            foreach (nd2; at(ln).actors[])
            {
                writeln("nd2: ", nd2);
                if (nd2.ix != nd.ix) // no self-recursion
                {
                    writeln("differs");
                    writeln("node: ", at(nd));
                    writeln("lang: ", at(nd).lemma.lang);
                    writeln("dstLangs: ", dstLangs);
                    writeln("it: ", dstLangs.canFind(at(nd).lemma.lang));
                    if (dstLangs.empty ||
                        dstLangs.canFind(at(nd).lemma.lang)) // TODO functionize to Lemma.ofLang
                    {
                        writeln("nd2: ", nd);
                    }
                }
            }
        }
        writeln("xx");
        return lnsOf(nd, rel, origins).map!(ln =>
                                            at(ln).actors[]
                                                  .filter!(actor => (actor.ix != nd.ix &&
                                                                     (dstLangs.empty ||
                                                                      dstLangs.canFind(at(actor).lemma.lang)) // TODO functionize to Lemma.ofLang
                                                               )))
                                      .joiner(); // no self
    }

    /** Get Possible Rhymes of $(D text) sorted by falling rhymness (relevance).
        Set withSameSyllableCount to true to get synonyms which can be used to
        help in translating songs with same rhythm.
        See also: http://stevehanov.ca/blog/index.php?id=8
     */
    Nds rhymesOf(S)(S expr,
                    Lang[] langs = [],
                    Origin[] origins = [],
                    size_t commonPhonemeCountMin = 2,  // at least two phonenes in common at the end
                    bool withSameSyllableCount = false) if (isSomeString!S)
    {
        foreach (srcNd; ndsOf(expr)) // for each interpretation of expr
        {
            const srcNode = at(srcNd);

            if (langs.empty)
            {
                langs = [srcNode.lemma.lang]; // stay within language by default
            }

            dln("before");
            auto dstNds = nnsOf(srcNd, Rel.translationOf, [Lang.ipa], origins);
            dln("after");

            foreach (dstNd; dstNds) // translations to IPA-language
            {
                const dstNode = at(dstNd);
                auto hits = db.allNodes.filter!(a => langs.canFind(a.lemma.lang))
                                    .map!(a => tuple(a, commonSuffixCount(a.lemma.expr,
                                                                          at(srcNd).lemma.expr)))
                                    .filter!(a => a[1] >= commonPhonemeCountMin)
                                    // .sorted!((a, b) => false)
                ;
            }
        }
        return typeof(return).init;
    }

    /** Get Possible Languages of $(D text) sorted by falling strength.
        TODO Weight hits with word node connectedness relative to average word
        connectedness in that language.
     */
    NWeight[Lang] languagesOf(R)(R text) if (isIterable!R &&
                                             isSomeString!(ElementType!R))
    {
        typeof(return) hist;
        foreach (word; text)
        {
            foreach (lemma; lemmasOfExpr(word))
            {
                ++hist[lemma.lang];
            }
        }
        return hist;
    }

    /** Get Translations of $(D word) in language $(D lang).
        If several $(D toLangs) are specified pick the closest match (highest
        relation weight).
    */
    auto translationsOf(S)(S expr,
                           Lang lang = Lang.unknown,
                           Sense sense = Sense.unknown,
                           Lang[] toLangs = []) if (isSomeString!S)
    {
        auto nodes = ndsOf(expr, lang, sense);
        // en => sv:
        // en-en => sv-sv
        /* auto translations = nodes.map!(node => lnsOf(node, RelDir.any, rel, false))/\* .joiner *\/; */
        return nodes;
    }

    /** Get Node References whose Lemma Expr starts with $(D prefix). */
    auto canFind(S)(S part,
                    Lang lang = Lang.unknown,
                    Sense sense = Sense.unknown) if (isSomeString!S)
    {
        return db.ndByLemma.values.filter!(nd => at(nd).lemma.expr.canFind(part));
    }

    /** Get Node References whose Lemma Expr starts with $(D prefix). */
    auto startsWith(S)(S prefix,
                       Lang lang = Lang.unknown,
                       Sense sense = Sense.unknown) if (isSomeString!S)
    {
        return db.ndByLemma.values.filter!(nd => at(nd).lemma.expr.startsWith(prefix));
    }

    /** Get Node References whose Lemma Expr starts with $(D suffix). */
    auto endsWith(S)(S suffix,
                     Lang lang = Lang.unknown,
                     Sense sense = Sense.unknown) if (isSomeString!S)
    {
        return db.ndByLemma.values.filter!(nd => at(nd).lemma.expr.endsWith(suffix));
    }

    /** Relatedness.
        Sum of all paths relating a to b where each path is the path weight
        product.
    */
    real relatedness(Nd a,
                     Nd b) const @safe @nogc pure nothrow
    {
        typeof(return) value;
        return value;
    }

    /** Get Node with strongest relatedness to $(D text).
        TODO Compare with function Context() in ConceptNet API.
     */
    Node contextOf(R)(R text) const if (isSourceOfSomeString!R)
    {
        auto node = typeof(return).init;
        return node;
    }
    alias topicOf = contextOf;

    /** Guess Language of $(D text).
    */
    Lang guessLanguageOf(T)(R text) const if (isSourceOfSomeString!R)
    {
        auto lang = Lang.unknown;
        return lang;
    }
}
