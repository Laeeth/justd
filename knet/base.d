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
import std.algorithm: findSplit, sort, skipOver, filter, canFind, count, min, max, joiner, strip, until;
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
import combinations;
import permutations;

import knet.separators;
import knet.languages;
import knet.origins;
import knet.thematics;
import knet.senses;
import knet.relations;
import knet.roles;
import knet.decodings;
import knet.lemmas;

// make often used stuff public for convenience
public import std.range: front, empty;
public import std.conv: to;
public import std.algorithm.iteration: splitter, map, filter, joiner;
public import std.algorithm.searching: startsWith, endsWith;
public import knet.separators;
public import knet.senses: Sense;
public import knet.languages: Lang;
public import knet.relations: Rel;
public import knet.roles: Role;
public import knet.origins: Origin;

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

import stdx.container.sorted: Sorted;
/// Sorted References to Nodes.
alias SortedNds = Sorted!(Nds, "a.ix < b.ix");
/// Sorted References to Links.
alias SortedLns = Sorted!(Lns, "a.ix < b.ix");

/// WordNet.
alias SynSet = Array!Nd;        /// WordNet Synonym Set
alias SynSetOffset = uint;      /// WordNet Synonym Set Offset (Id)

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
            import std.conv: ConvException;
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
                catch (ConvException e)
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

struct LazilySorted(T)
{
    T storage;
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

auto ins (in Link link) { return link.actors[].filter!(nd => nd.dir() == RelDir.backward).map!(nd => nd.raw); }
auto outs(in Link link) { return link.actors[].filter!(nd => nd.dir() == RelDir.forward ).map!(ln => ln.raw); }

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

    SynSet[SynSetOffset] synsetByOffset;

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

    Nd ndByLemmaMaybe(in Lemma lemma) pure
    {
        return get(db.ndByLemma, lemma, typeof(return).init);
    }

    /** Try to Get Single Node related to $(D word) in the interpretation
        (semantic context) $(D sense).
    */
    Nds ndsByLemmaDirect(S)(S expr,
                            Lang lang,
                            Sense sense,
                            Ctx context) pure if (isSomeString!S)
    {
        typeof(return) nodes;
        const lemma = Lemma(expr, lang, sense, context);
        if (const lemmaNd = lemma in db.ndByLemma)
        {
            nodes ~= *lemmaNd; // use it
        }
        else
        {
            static if (false) // TODO Enable this logic by moving findWordsSplit to Graph
            {
                // try to lookup parts of word
                const wordsSplit = wordnet.findWordsSplit(expr, [lang]); // split in parts
                if (wordsSplit.length >= 2)
                {
                    import std.algorithm.iteration: joiner;
                    if (const lemmaFixedNd = Lemma(wordsSplit.joiner(`_`).to!S,
                                                   lang, sense, context) in db.ndByLemma)
                    {
                        nodes ~= *lemmaFixedNd;
                    }
                }
            }
        }
        return nodes;
    }

    /** Get All Node Indexes Indexed by a Lemma having expr $(D expr). */
    auto ndsOf(S)(S expr) pure if (isSomeString!S)
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
                 Ctx context = anyContext) pure if (isSomeString!S)
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
            import std.range: front;
            return (*lemmas).front.expr;
        }
        return expr;
    }

    /** Internalize $(D Lemma) of $(D expr).
        Returns: either existing specialized lemma or a reference to the newly stored one.
     */
    ref Lemma internLemma(ref Lemma lemma,
                          bool hasUniqueSense = false) @safe pure // See also: http://wiki.dlang.org/DIP25 for doc on `return ref`
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
                auto senseFact = line.findSplit(qualifierSeparatorString);
                const senseCode = senseFact[0];

                Sense firstSpecializedSense = firstSense;
                Sense secondSpecializedSense = secondSense;

                if (role.rel.propagatesSense &&
                    !senseCode.empty)
                {
                    import std.conv: ConvException;
                    try
                    {
                        import std.conv: to;
                        const sense = senseCode.to!Sense;
                        if (firstSense  == Sense.unknown) { firstSpecializedSense = sense; }
                        if (secondSense == Sense.unknown) { secondSpecializedSense = sense; }
                    }
                    catch (ConvException e)
                    {
                        /* ok for now */
                    }
                }
                auto split = line.findSplit(roleSeparatorString); // TODO allow key to be ElementType of Range to prevent array creation here
                const first = split[0], second = split[2];
                auto firstRefs = store(first.splitter(alternativesSeparator),
                                       firstLang, firstSpecializedSense, origin);
                if (!first.empty &&
                    !second.empty)
                {
                    auto secondRefs = store(second.splitter(alternativesSeparator),
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
    auto sensesOfExpr(S)(S expr) @safe pure if (isSomeString!S)
    {
        return lemmasOfExpr(expr).map!(lemma => lemma.sense)
                                 .filter!(sense => sense != Sense.unknown);
    }

    /// Get Possible Common Sense for $(D a) and $(D b). TODO N-ary
    Sense commonSense(S1, S2)(S1 a, S2 b) @safe pure if (isSomeString!S1 &&
                                                         isSomeString!S2)
    {
        import std.algorithm: setIntersection;
        auto commonSenses = setIntersection(sensesOfExpr(a).sorted,
                                            sensesOfExpr(b).sorted);
        return commonSenses.count == 1 ? commonSenses.front : Sense.unknown;
    }

    /// Learn Opposites.
    void learnOpposites(Lang lang, Origin origin = Origin.manual)
    {
        foreach (expr; File(`../knowledge/` ~ lang.to!string ~ `/opposites.txt`).byLine.filter!(a => !a.empty))
        {
            auto split = expr.findSplit(roleSeparatorString); // TODO allow key to be ElementType of Range to prevent array creation here
            const auto first = split[0], second = split[2];
            NWeight weight = 1.0;
            const sense = commonSense(first, second);
            connect(store(first.idup, lang, sense, origin),
                    Role(Rel.oppositeOf),
                    store(second.idup, lang, sense, origin),
                    origin, weight);
        }
    }

    /// Learn Verb Reversion.
    Lns learnVerbReversion(S)(S forward,
                              S backward,
                              Lang lang = Lang.unknown) if (isSomeString!S)
    {
        const origin = Origin.manual;
        auto all = [store(forward, lang, Sense.verbInfinitive, origin),
                    store(backward, lang, Sense.verbPastParticiple, origin)];
        return connectAll(Role(Rel.reversionOf), all.filter!(a => a.defined), lang, origin);
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
    Lns learnEnglishIrregularVerb(S1, S2, S3)(S1 infinitive, // base form
                                              S2 pastSimple,
                                              S3 pastParticiple,
                                              Origin origin = Origin.manual)
    {
        enum lang = Lang.en;
        Nds all;
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
    Lns learnMto1(R, S)(Lang lang,
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

    Lns learnMto1Maybe(S)(Lang lang,
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
    Lns learnEnglishEmoticon(S)(S[] emoticons,
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
            assert(db.allNodes.length <= Nd.nullIx);
            const cix = Nd(cast(Nd.Ix)db.allNodes.length);
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

    Nds store(Exprs)(Exprs exprs,
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
    Lns connectMtoN(S, D)(S srcs,
                          Role role,
                          D dsts,
                          Origin origin,
                          NWeight weight = 1.0,
                          bool checkExisting = true,
                          bool skipSelfConnects = false) if (isIterableOf!(S, Nd) &&
                                                             isIterableOf!(D, Nd))
    {
        typeof(return) lns;
        foreach (src; srcs)
        {
            foreach (dst; dsts)
            {
                if ((!skipSelfConnects) ||
                    src != dst)
                {
                    lns ~= connect(src, role, dst, origin, weight, checkExisting);
                }
            }
        }
        return lns;
    }
    alias connectFanInFanOut = connectMtoN;

    /** Fully Connect Every-to-Every in $(D all).
        See also: http://forum.dlang.org/thread/iqkybajwdzcvdytakgvw@forum.dlang.org#post-iqkybajwdzcvdytakgvw:40forum.dlang.org
        See also: https://issues.dlang.org/show_bug.cgi?id=6788
    */
    Lns connectAll(R)(Role role,
                      R all,
                      Lang lang,
                      Origin origin,
                      NWeight weight = 1.0) if (isIterableOf!(R, Nd))
        in { assert(role.rel.isSymmetric); }
    body
    {
        typeof(return) lns;
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
                lns ~= connect(me, role, you, origin, weight);
                ++j;
            }
            ++i;
        }
        return lns;
    }
    alias connectMtoM = connectAll;
    alias connectFully = connectAll;
    alias connectStar = connectAll;

    /** Fan-Out Connect $(D first) to Every in $(D rest). */
    Lns connect1toM(R)(Nd first,
                       Role role,
                       R rest,
                       Origin origin, NWeight weight = 1.0) if (isIterableOf!(R, Nd))
    {
        typeof(return) lns;
        foreach (you; rest)
        {
            if (first != you)
            {
                lns ~= connect(first, role, you, origin, weight, false);
            }
        }
        return lns;
    }
    alias connectFanOut = connect1toM;

    /** Fan-In Connect $(D first) to Every in $(D rest). */
    Lns connectMto1(R)(R rest,
                       Role role,
                       Nd first,
                       Origin origin, NWeight weight = 1.0) if (isIterableOf!(R, Nd))
    {
        typeof(return) lns;
        foreach (you; rest)
        {
            if (first != you)
            {
                lns ~= connect(you, role, first, origin, weight);
            }
        }
        return lns;
    }
    alias connectFanIn = connectMto1;

    /** Cyclic Connect Every $(D ring) to a ring. */
    Lns connectCycle(R)(R ring,
                        Rel rel,
                        Origin origin,
                        NWeight weight = 1.0,
                        bool checkExisting = true) if (isIterableOf!(R, Nd))
    {
        typeof(return) lns;
        import std.range: hasLength;
        static if (hasLength!R)
        {
            const length = ring.length; // workaround because std.container.Array doesn't directly support count
        }
        else
        {
            const length = ring.count;
        }
        if (length >= 2)
        {
            for (size_t i = 0; i < length; ++i) // TODO reuse cycle?
            {
                const j = i == length - 1 ? 0 : i + 1;
                lns ~= connect(ring[i], Role(rel), ring[j], origin, weight, checkExisting);
            }
        }
        return lns;
    }
    alias connectCircle = connectCycle;
    alias connectRing = connectCycle;

    /** Add Link from $(D src) to $(D dst) of type $(D rel) and weight $(D weight).
        TODO checkExisting is currently set to false because searching
        existing links is currently too slow
     */
    Ln connect(Nd src,
               Role role,
               Nd dst,
               Origin origin = Origin.unknown,
               NWeight weight = 1.0, // 1.0 means absolutely true for Origin manual
               bool checkExisting = true,
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
        assert(db.allLinks.length <= Ln.nullIx);
        auto ln = Ln(cast(Ln.Ix)db.allLinks.length);

        auto link = Link(role.reversion ? dst : src,
                         Role(role.rel, false, role.negation),
                         role.reversion ? src : dst,
                         origin);

        stat.linkConnectednessSum += 2;

        at(src).links.reserve(at(src).links.length + 2);
        at(src).links ~= ln.forward;
        at(dst).links ~= ln.backward;
        // at(src).links.linearInsert([ln.forward, ln.backward]);
        // at(dst).links.linearInsert(ln.forward);
        // at(dst).links.linearInsert(ln.backward);
        // TODO Add variadic linearInsert() to Sorted

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
    void setLocation(Nd nd, in Location location) pure
    {
        assert (nd !in db.locations);
        db.locations[nd] = location;
    }

    /** If $(D link) node origins unknown propagate them from $(D link)
        itself. */
    bool propagateLinkNodes(ref Link link, Nd src, Nd dst) pure
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

    /** Return Index to Link from $(D a) to $(D b) if present, otherwise Ln.max.
     */
    Ln areConnectedInOrder(Nd a, Role role, Nd b,
                           Origin origin = Origin.unknown,
                           NWeight nweight = 1.0)
    {
        const dir = (role.rel.isSymmetric ?
                     RelDir.any :
                     RelDir.forward);

        foreach (aLn; at(a).links[].map!(ln => ln.raw))
        {
            const aLink = at(aLn);
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
        const aNd = a in db.ndByLemma;
        const bNd = b in db.ndByLemma;
        if (aNd && bNd)         // both lemmas exist
        {
            return areConnected(*aNd, role, *bNd, origin, weight);
        }
        return typeof(return).asUndefined;
    }

    enum durationInMsecs = 1000; // duration in milliseconds

    enum fuzzyExprMatchMaximumRecursionDepth = 8;

    import std.datetime: StopWatch;
    StopWatch showNodesSW;

    /** Get Node with strongest relatedness to $(D text).
        TODO Compare with function Context() in ConceptNet API.
     */
    Node contextOf(R)(R text) const if (isSourceOfSomeString!R)
    {
        auto node = typeof(return).init;
        return node;
    }
    alias topicOf = contextOf;

    /** Sort Lns on relevance.
        TODO Figure out how to put this in knet.sorting
    */
    void sortLns(Lns lns)
    {
        import std.algorithm: multiSort;
        lns.multiSort!((a, b) => (at(a).nweight >
                                  at(b).nweight),
                       (a, b) => (at(a).role.rel.rank <
                                  at(b).role.rel.rank),
                       (a, b) => (at(a).role.rel <
                                  at(b).role.rel));
    }

}
