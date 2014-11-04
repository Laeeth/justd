#!/usr/bin/env rdmd-dev-module

/** Knowledge Graph Database.

    Reads data from DBpedia, Freebase, Yago, BabelNet, ConceptNet, Nell,
    Wikidata, WikiTaxonomy into a Knowledge Graph.

    See also: www.oneacross.com/crosswords for inspiring applications

    Data: http://conceptnet5.media.mit.edu/downloads/current/
    Data: http://wiki.dbpedia.org/DBpediaAsTables
    Data: http://icon.shef.ac.uk/Moby/
    Data: http://www.dcs.shef.ac.uk/research/ilash/Moby/moby.tar.Z
    Data: http://extensions.openoffice.org/en/search?f%5B0%5D=field_project_tags%3A157

    See also: http://programmers.stackexchange.com/q/261163/38719
    See also: https://en.wikipedia.org/wiki/Hypergraph
    See also: https://github.com/commonsense/conceptnet5/wiki
    See also: http://forum.dlang.org/thread/fysokgrgqhplczgmpfws@forum.dlang.org#post-fysokgrgqhplczgmpfws:40forum.dlang.org
    See also: http://www.eturner.net/omcsnetcpp/

    TODO Make use of stealFront and stealBack

    TODO ansiktstvätt => facial_wash
    TODO biltvätt => findSplit [bil tvätt] => search("car wash") or search("car_wash") or search("carwash")
    TODO promote equal splits through weigthing sum_over_i(x[i].length^)2

    TODO Template on NodeData and rename Concept to Node. Instantiate with
    NodeData begin Concept and break out Concept outside.

    TODO Profile read
    TODO Use containers.HashMap
    TODO Call GC.disable/enable around construction and search.
 */
module knet;

import std.traits: isSomeString, isFloatingPoint, EnumMembers;
import std.conv: to;
import std.stdio;
import std.algorithm: findSplitBefore, findSplitAfter, groupBy;
import std.container: Array;
import algorithm_ex: isPalindrome;
import range_ex: stealFront, stealBack;
import std.string: tr;

/* version = msgpack; */

import grammars;
import rcstring;
version(msgpack) import msgpack;

static if (__VERSION__ < 2067)
{
    auto clamp(T, TLow, THigh)(T x, TLow lower, THigh upper)
    @safe pure nothrow
    in { assert(lower <= upper, "lower > upper"); }
    body
    {
        import std.algorithm : min, max;
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

/* import stdx.allocator; */
/* import memory.allocators; */
/* import containers: HashMap; */

/** Conceptnet Semantic Relation Type Code.
    See also: https://github.com/commonsense/conceptnet5/wiki/Relations
*/
enum Relation:ubyte
{
    relatedTo, /* The most general relation. There is some positive relationship
                * between A and B, but ConceptNet can't determine what that * relationship
                is based on the data. This was called * "ConceptuallyRelatedTo" in
                ConceptNet 2 through 4.  */
    conceptuallyRelatedTo = relatedTo,
    any = relatedTo,

    isA, /* A is a subtype or a specific instance of B; every A is a B. (We do
          * not make the type-token distinction, because people don't usually
          * make that distinction.) This is the hyponym relation in
          * WordNet. /r/IsA /c/en/car /c/en/vehicle ; /r/IsA /c/en/chicago
          * /c/en/city */

    partOf, /* A is a part of B. This is the part meronym relation in
               WordNet. /r/PartOf /c/en/gearshift /c/en/car */

    memberOf, /* A is a member of B; B is a group that includes A. This is the
                 member meronym relation in WordNet. */

    hasA, /* B belongs to A, either as an inherent part or due to a social
             construct of possession. HasA is often the reverse of PartOf. /r/HasA
             /c/en/bird /c/en/wing ; /r/HasA /c/en/pen /c/en/ink */

    usedFor, /* A is used for B; the purpose of A is B. /r/UsedFor /c/en/bridge
                /c/en/cross_water */

    capableOf, /* Something that A can typically do is B. /r/CapableOf
                  /c/en/knife /c/en/cut */

    atLocation, /* A is a typical location for B, or A is the inherent location
                   of B. Some instances of this would be considered meronyms in
                   WordNet. /r/AtLocation /c/en/butter /c/en/refrigerator; /r/AtLocation
                   /c/en/boston /c/en/massachusetts */
    hasContext,
    locationOf,
    locationOfAction,

    locatedNear,

    causes, /* A and B are events, and it is typical for A to cause B. */
    entails = causes, /* TODO same as causes? */
    leadsTo = causes,

    hasSubevent, /* A and B are events, and B happens as a subevent of A. */

    hasFirstSubevent, /* A is an event that begins with subevent B. */

    hasLastSubevent, /* A is an event that concludes with subevent B. */

    hasPrerequisite, /* In order for A to happen, B needs to happen; B is a
                        dependency of A. /r/HasPrerequisite/ /c/en/drive/ /c/en/get_in_car/ */

    hasProperty, /* A has B as a property; A can be described as
                    B. /r/HasProperty /c/en/ice /c/en/solid */

    attribute,

    motivatedByGoal, /* Someone does A because they want result B; A is a step
                        toward accomplishing the goal B. */
    obstructedBy, /* A is a goal that can be prevented by B; B is an obstacle in
                     the way of A. */

    desires, /* A is a conscious entity that typically wants B. Many assertions
                of this type use the appropriate language's word for "person" as
                A. /r/Desires /c/en/person /c/en/love */

    causesDesire,

    desireOf,

    createdBy, /* B is a process that creates A. /r/CreatedBy /c/en/cake
                  /c/en/bake */
    receivesAction,

    synonym, /* A and B have very similar meanings. This is the synonym relation
                in WordNet as well. */

    antonym, /* A and B are opposites in some relevant way, such as being
                opposite ends of a scale, or fundamentally similar things with a
                key difference between them. Counterintuitively, two _concepts
                must be quite similar before people consider them antonyms. This
                is the antonym relation in WordNet as well. /r/Antonym
                /c/en/black /c/en/white; /r/Antonym /c/en/hot /c/en/cold */
    oppositeOf = antonym,

    retronym, // $(EM acoustic) guitar. https://en.wikipedia.org/wiki/Retronym
    differentation = retronym,

    derivedFrom, /* A is a word or phrase that appears within B and contributes
                    to B's meaning. /r/DerivedFrom /c/en/pocketbook /c/en/book
                 */

    compoundDerivedFrom,

    etymologicallyDerivedFrom,

    translationOf, /* A and B are _concepts (or assertions) in different
                      languages, and overlap in meaning in such a way that they
                      can be considered translations of each other. (This
                      cannot, of course be taken as an exact equivalence.) */

    definedAs, /* A and B overlap considerably in meaning, and B is a more
                  explanatory version of A. (This is similar to TranslationOf,
                  but within one language.) */

    instanceOf,

    madeOf, // TODO Unite with instanceOf

    inheritsFrom,

    similarSize,

    symbolOf,

    similarTo,

    hasPainIntensity,
    hasPainCharacter,

    adjectivePertainsTo,
    adverbPertainsTo,
    participleOf,
}

string negationIn(HLang lang = HLang.en)
    @safe pure nothrow
{
    with (HLang)
        switch (lang)
        {
            case en: return "not";
            case sv: return "inte";
            case de: return "nicht";
            default: return "not";
        }
}

/** Link Direction. */
enum LinkDir
{
    input,
    output
}

string toHumanLang(const Relation relation,
                   const LinkDir linkDir,
                   const bool negation = false,
                   const HLang lang = HLang.en)
    @safe pure
{
    with (Relation)
    {
        with (HLang)
        {
            auto neg = negation ? negationIn(lang) : "";
            switch (relation)
            {
                case relatedTo:
                    switch (lang)
                    {
                        case en: return "is" ~ neg ~ " related to";
                        case sv: return "är" ~ neg ~ " relaterat till";
                        default: return "is" ~ neg ~ " related to";
                    }
                case translationOf:
                    switch (lang)
                    {
                        case en: return "is" ~ neg ~ " translated to";
                        case sv: return "kan" ~ neg ~ " översättas till";
                        default: return "is" ~ neg ~ " translated to";
                    }
                case synonym:
                    switch (lang)
                    {
                        case en: return "is" ~ neg ~ " synonynoms with";
                        case sv: return "är" ~ neg ~ " synonym med";
                        default: return "is" ~ neg ~ " synonynoms with";
                    }
                case antonym:
                    switch (lang)
                    {
                        case en: return "is" ~ neg ~ " the opposite of";
                        case sv: return "är" ~ neg ~ " motsatsen till";
                        default: return "is" ~ neg ~ " the opposite of";
                    }
                case similarSize:
                    switch (lang)
                    {
                        case en: return "is" ~ neg ~ " similar in size to";
                        case sv: return "är" ~ neg ~ " lika stor som";
                        default: return "is" ~ neg ~ " similar in size to";
                    }
                case similarTo:
                    switch (lang)
                    {
                        case en: return "is" ~ neg ~ " similar to";
                        case sv: return "är" ~ neg ~ " likvärdig med";
                        default: return "is" ~ neg ~ " similar to";
                    }
                case isA:
                    if (linkDir == LinkDir.output)
                    {
                        switch (lang)
                        {
                            case en: return "is" ~ neg ~ " a";
                            case sv: return "är" ~ neg ~ " en";
                            case de: return "ist" ~ neg ~ " ein";
                            default: return "is" ~ neg ~ " a";
                        }
                    }
                    else
                    {
                        switch (lang)
                        {
                            case en: return "can" ~ neg ~ " be a";
                            case sv: return "kan" ~ neg ~ " vara en";
                            case de: return "can" ~ neg ~ " sein ein";
                            default: return "can" ~ neg ~ " be a";
                        }
                    }
                default: return relation.to!(typeof(return));
            }
        }
    }
}


Relation decodeRelation(S)(S s,
                           out bool negation) if (isSomeString!S)
{
    switch (s)
    {
        case `RelatedTo`:                   return Relation.relatedTo;
        case `IsA`:                         return Relation.isA;
        case `PartOf`:                      return Relation.partOf;
        case `MemberOf`:                    return Relation.memberOf;
        case `HasA`:                        return Relation.hasA;
        case `UsedFor`:                     return Relation.usedFor;
        case `CapableOf`:                   return Relation.capableOf;
        case `AtLocation`:                  return Relation.atLocation;
        case `HasContext`:                  return Relation.hasContext;
        case `LocationOf`:                  return Relation.locationOf;
        case `LocationOfAction`:            return Relation.locationOfAction;
        case `LocatedNear`:                 return Relation.locatedNear;
        case `Causes`:                      return Relation.causes;
        case `Entails`:                     return Relation.entails;
        case `HasSubevent`:                 return Relation.hasSubevent;
        case `HasFirstSubevent`:            return Relation.hasFirstSubevent;
        case `HasLastSubevent`:             return Relation.hasLastSubevent;
        case `HasPrerequisite`:             return Relation.hasPrerequisite;
        case `HasProperty`:                 return Relation.hasProperty;
        case `Attribute`:                   return Relation.attribute;
        case `MotivatedByGoal`:             return Relation.motivatedByGoal;
        case `ObstructedBy`:                return Relation.obstructedBy;
        case `Desires`:                     return Relation.desires;
        case `CausesDesire`:                return Relation.causesDesire;
        case `DesireOf`:                    return Relation.desireOf;
        case `CreatedBy`:                   return Relation.createdBy;
        case `ReceivesAction`:              return Relation.receivesAction;
        case `Synonym`:                     return Relation.synonym;
        case `Antonym`:                     return Relation.antonym;
        case `Retronym`:                    return Relation.retronym;
        case `DerivedFrom`:                 return Relation.derivedFrom;
        case `CompoundDerivedFrom`:         return Relation.compoundDerivedFrom;
        case `EtymologicallyDerivedFrom`:   return Relation.etymologicallyDerivedFrom;
        case `TranslationOf`:               return Relation.translationOf;
        case `DefinedAs`:                   return Relation.definedAs;
        case `InstanceOf`:                  return Relation.instanceOf;
        case `MadeOf`:                      return Relation.madeOf;
        case `InheritsFrom`:                return Relation.inheritsFrom;
        case `SimilarSize`:                 return Relation.similarSize;
        case `SymbolOf`:                    return Relation.symbolOf;
        case `SimilarTo`:                   return Relation.similarTo;
        case `HasPainIntensity`:            return Relation.hasPainIntensity;
        case `HasPainCharacter`:            return Relation.hasPainCharacter;
            // negations
        case `NotMadeOf`:                   negation = true; return Relation.madeOf;
        case `NotIsA`:                      negation = true; return Relation.isA;
        case `NotUsedFor`:                  negation = true; return Relation.usedFor;
        case `NotHasA`:                     negation = true; return Relation.hasA;
        case `NotDesires`:                  negation = true; return Relation.desires;
        case `NotCauses`:                   negation = true; return Relation.causes;
        case `NotCapableOf`:                negation = true; return Relation.capableOf;
        case `NotHasProperty`:              negation = true; return Relation.hasProperty;

        case `wordnet/adjectivePertainsTo`: negation = true; return Relation.adjectivePertainsTo;
        case `wordnet/adverbPertainsTo`:    negation = true; return Relation.adverbPertainsTo;
        case `wordnet/participleOf`:        negation = true; return Relation.participleOf;

        default:
            writeln(`Unknown relationString `, s);
            return Relation.relatedTo;
    }
}

/** Return true if $(D special) is a more specialized relation than $(D general). */
bool specializes(Relation special,
                 Relation general)
    @safe @nogc pure nothrow
{
    with (Relation) {
        switch (general)
        {
            /* TODO Use static foreach over all enum members to generate all
             * relevant cases: */
            case relatedTo:
                return special != relatedTo;
            case isA:
                return !special.of(isA, relatedTo);
            default: return special == general;
        }
    }
}

/** Return true if $(D general) is a more general relation than $(D special). */
bool generalizes(T)(T general,
                    T special)
{
    return specializes(special, general);
}

@safe @nogc pure nothrow
{
    bool isSymmetric(const Relation relation)
    {
        with (Relation)
            return relation.of(relatedTo,
                               translationOf,
                               synonym,
                               antonym,
                               similarSize,
                               similarTo);
    }

    /** Return true if $(D relation) is a transitive relation that can used to
        inference new relations (knowledge).

        A relation R from A to B is transitive if A >=R=> B and B >=R=> C
        infers A >=R=> C.
    */
    bool isTransitive(const Relation relation)
    {
        with (Relation)
            return relation.of(partOf,
                               relatedTo,
                               isA,
                               memberOf,
                               hasA,
                               atLocation,
                               hasContext,
                               locationOf,
                               locatedNear,
                               causes,
                               entails,
                               hasSubevent,
                               synonym,
                               hasPrerequisite,
                               hasProperty,
                               translationOf);
    }

    /** Return true if $(D relation) is a strong.
        TODO Where is strength decided and what purpose does it have?
    */
    bool isStrong(Relation relation)
    {
        with (Relation)
            return relation.of(hasProperty,
                               motivatedByGoal);
    }

    /** Return true if $(D relation) is a weak.
        TODO Where is strongness decided and what purpose does it have?
    */
    bool isWeak(Relation relation)
    {
        with (Relation)
            return relation.of(isA,
                               locationOf,
                               locationOfAction,
                               locatedNear);
    }

}

/** ConceptNet Thematic. */
enum Thematic:ubyte
{
    unknown,
    kLines,
    things,
    agents,
    events,
    spatial,
    causal,
    functional,
    affective,
    synonym,
    antonym,
    retronym,
}

Thematic toThematic(Relation relation)
    @safe @nogc pure nothrow
{
    final switch (relation)
    {
        case Relation.relatedTo: return Thematic.kLines;
        case Relation.isA: return Thematic.things;
        case Relation.partOf: return Thematic.things;
        case Relation.memberOf: return Thematic.things;
        case Relation.hasA: return Thematic.things;
        case Relation.usedFor: return Thematic.functional;
        case Relation.capableOf: return Thematic.agents;
        case Relation.atLocation: return Thematic.spatial;
        case Relation.hasContext: return Thematic.things;

        case Relation.locationOf: return Thematic.spatial;
        case Relation.locationOfAction: return Thematic.spatial;
        case Relation.locatedNear: return Thematic.spatial;

        case Relation.causes: return Thematic.causal;
        case Relation.hasSubevent: return Thematic.events;
        case Relation.hasFirstSubevent: return Thematic.events;
        case Relation.hasLastSubevent: return Thematic.events;
        case Relation.hasPrerequisite: return Thematic.causal; // TODO Use events, causal, functional
        case Relation.hasProperty: return Thematic.things;
        case Relation.attribute: return Thematic.things;
        case Relation.motivatedByGoal: return Thematic.affective;
        case Relation.obstructedBy: return Thematic.causal;
        case Relation.desires: return Thematic.affective;
        case Relation.causesDesire: return Thematic.affective;
        case Relation.desireOf: return Thematic.affective;

        case Relation.createdBy: return Thematic.agents;
        case Relation.receivesAction: return Thematic.agents;

        case Relation.synonym: return Thematic.synonym;
        case Relation.antonym: return Thematic.antonym;
        case Relation.retronym: return Thematic.retronym;

        case Relation.derivedFrom: return Thematic.things;
        case Relation.compoundDerivedFrom: return Thematic.things;
        case Relation.etymologicallyDerivedFrom: return Thematic.things;
        case Relation.translationOf: return Thematic.synonym;

        case Relation.definedAs: return Thematic.things;

        case Relation.instanceOf: return Thematic.things;
        case Relation.madeOf: return Thematic.things;
        case Relation.inheritsFrom: return Thematic.things;
        case Relation.similarSize: return Thematic.things;
        case Relation.symbolOf: return Thematic.kLines;
        case Relation.similarTo: return Thematic.kLines;
        case Relation.hasPainIntensity: return Thematic.kLines;
        case Relation.hasPainCharacter: return Thematic.kLines;

        case Relation.adjectivePertainsTo: return Thematic.unknown;
        case Relation.adverbPertainsTo: return Thematic.unknown;
        case Relation.participleOf: return Thematic.unknown;
    }
}

enum Source:ubyte
{
    dbpedia37,
    dbpedia39umbel,
    dbpediaEn,
    wordnet30,
    verbosity,
    nell,
}

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

/** Main Knowledge Network.
*/
class Net(bool useArray = true,
          bool useRCString = true)
{
    import std.algorithm, std.range, std.path, std.array;
    import wordnet: WordNet;
    import dbg;
    import std.typecons: Nullable;

    /** Ix Precision.
        Set this to $(D uint) if we get low on memory.
        Set this to $(D ulong) when number of link nodes exceed Ix.
    */
    alias Ix = uint; // TODO Change this to size_t when we have more _concepts and memory.

    /* These LinkIx and ConceptIx are structs intead of aliases for type-safe
     * indexing. */
    struct LinkIx
    {
        Ix _lIx;
        static LinkIx undefined() { return LinkIx(Ix.max); }
    }
    struct ConceptIx
    {
        Ix _cIx;
        static ConceptIx undefined() { return ConceptIx(Ix.max); }
    }

    /** String Storage */
    static if (useRCString) { alias Words = RCXString!(immutable char, 24-1); }
    else                    { alias Words = immutable string; }

    static if (useArray) { alias ConceptIxes = Array!ConceptIx; }
    else                 { alias ConceptIxes = ConceptIx[]; }
    static if (useArray) { alias LinkIxes = Array!LinkIx; }
    else                 { alias LinkIxes = LinkIx[]; }

    /** Ontology Category Index (currently from NELL). */
    struct CategoryIx { ushort _cIx; }

    /** Concept Lemma. */
    struct Lemma
    {
        Words words;
        /* The following three are used to disambiguate different semantics
         * meanings of the same word in different languages. */
        HLang lang;
        WordKind wordKind;
        CategoryIx categoryIx;
    }

    /** Concept Node/Vertex. */
    struct Concept
    {
        this(Words words,
             HLang lang,
             WordKind lemmaKind,
             LinkIxes inIxes = LinkIxes.init,
             LinkIxes outIxes = LinkIxes.init)
        {
            this.words = words;
            this.lang = lang;
            this.lemmaKind = lemmaKind;
            this.inIxes = inIxes;
            this.outIxes = outIxes;
        }
    private:
        Words words;
        LinkIxes inIxes;
        LinkIxes outIxes;
        HLang lang;
        WordKind lemmaKind;
    }

    /** Get Ingoing Links of $(D concept). */
    auto  inLinksOf(in Concept concept) { return concept. inIxes[].map!(ix => linkByIx(ix)); }
    /** Get Outgoing Links of $(D concept). */
    auto outLinksOf(in Concept concept) { return concept.outIxes[].map!(ix => linkByIx(ix)); }

    /** Get Ingoing Relations of (range of tuple(Link, Concept)) of $(D concept). */
    auto  insOf(in Concept concept) { return  inLinksOf(concept).map!(link => tuple(link, dst(link))); }
    /** Get Outgoing Relations of (range of tuple(Link, Concept)) of $(D concept). */
    auto outsOf(in Concept concept) { return outLinksOf(concept).map!(link => tuple(link, src(link))); }

    auto inLinksGroupedByRelation(in Concept concept)
    {
        return inLinksOf(concept).array.groupBy!((a, b) => // TODO array needed?
                                                 (a._negation == b._negation &&
                                                  a._relation == b._relation));
    }
    auto outLinksGroupedByRelation(in Concept concept)
    {
        return outLinksOf(concept).array.groupBy!((a, b) => // TODO array needed?
                                                  (a._negation == b._negation &&
                                                   a._relation == b._relation));
    }

    auto insByRelation(in Concept concept)
    {
        return insOf(concept).array.groupBy!((a, b) => // TODO array needed?
                                             (a[0]._negation == b[0]._negation &&
                                              a[0]._relation == b[0]._relation));
    }
    auto outsByRelation(in Concept concept)
    {
        return outsOf(concept).array.groupBy!((a, b) => // TODO array needed?
                                              (a[0]._negation == b[0]._negation &&
                                               a[0]._relation == b[0]._relation));
    }

    static if (useArray) { alias ConceptIxes = Array!ConceptIx; }
    else                 { alias ConceptIxes = ConceptIx[]; }

    /** Many-Concepts-to-Many-Concepts Link (Edge).
     */
    struct Link
    {
        alias Weight = ubyte; // link weight pack type
        @safe @nogc pure nothrow:
        void setWeight(T)(T weight) if (isFloatingPoint!T)
        {
            // pack from 0..about10 to Weight 0.255 to save memory
            _weight = cast(Weight)(weight.clamp(0,10)/10*Weight.max);
        }
        @property real normalizedWeight() const
        {
            return cast(real)_weight/(cast(real)Weight.max/10);
        }
    private:
        ConceptIx _srcIx;
        ConceptIx _dstIx;

        Weight _weight;

        Relation _relation;
        bool _negation; // relation negation

        Source _origin;
    }

    Concept src(Link link) { return conceptByIx(link._srcIx); }
    Concept dst(Link link) { return conceptByIx(link._dstIx); }

    pragma(msg, `LinkIxes.sizeof: `, LinkIxes.sizeof);
    pragma(msg, `ConceptIxes.sizeof: `, ConceptIxes.sizeof);
    pragma(msg, `Concept.sizeof: `, Concept.sizeof);
    pragma(msg, `Link.sizeof: `, Link.sizeof);
    pragma(msg, `Lemma.sizeof: `, Lemma.sizeof);

    /* static if (useArray) { alias Concepts = Array!Concept; } */
    /* else                 { alias Concepts = Concept[]; } */
    alias Concepts = Concept[]; // no need to use std.container.Array here

    static if (useArray) { alias Links = Array!Link; }
    else                 { alias Links = Link[]; }

    private
    {
        ConceptIx[Lemma] _conceptIxByLemma;
        Concepts _concepts;
        Links _links;

        string[CategoryIx] _categoryNameByIx; /** Ontology Category Names by Index. */
        CategoryIx[string] _categoryIxByName; /** Ontology Category Indexes by Name. */
        enum anyCategory = CategoryIx(0);
        ushort _categoryIxCounter = 1;

        WordNet!(true, true) _wordnet;

        size_t[Relation.max + 1] _relationCounts;
        size_t[Source.max + 1] _sourceCounts;
        size_t[HLang.max + 1] _hlangCounts;
        size_t[WordKind.max + 1] _kindCounts;
        size_t _assertionCount = 0;
        size_t _conceptStringLengthSum = 0;
        size_t _connectednessSum = 0;

        // is there a Phobos structure for this?
        real _weightMin = real.max;
        real _weightMax = real.min_normal;
        real _weightSum = 0; // Sum of all link weights.
    }

    @safe pure nothrow
    {
        ref inout(Link) linkByIx(LinkIx ix) inout { return _links[ix._lIx]; }
        ref inout(Link)  opIndex(LinkIx ix) inout { return linkByIx(ix); }

        ref inout(Concept) conceptByIx(ConceptIx ix) inout @nogc { return _concepts[ix._cIx]; }
        ref inout(Concept)     opIndex(ConceptIx ix) inout @nogc { return conceptByIx(ix); }
    }

    Nullable!Concept conceptByLemmaMaybe(Lemma lemma)
    {
        if (lemma in _conceptIxByLemma)
        {
            return typeof(return)(conceptByIx(_conceptIxByLemma[lemma]));
        }
        else
        {
            return typeof(return).init;
        }
    }

    Concept[] foo(S)(S words,
                     HLang hlang = HLang.unknown,
                     WordKind wordKind = WordKind.unknown) if (isSomeString!S)
    {
        typeof(return) concepts;
        auto lemma = Lemma(words, hlang, wordKind, anyCategory);
        if (lemma in _conceptIxByLemma) // if hashed lookup possible
        {
            concepts = [conceptByIx(_conceptIxByLemma[lemma])]; // use it
        }
        else
        {
            auto wordsSplit = _wordnet.findWordsSplit(words, [hlang]); // split in parts
            if (wordsSplit.length >= 2)
            {
                const wordsFixed = wordsSplit.joiner("_").to!S;
                dln("wordsFixed: ", wordsFixed, " in ", hlang, " as ", wordKind);
                // TODO: Functionize
                auto lemmaFixed = Lemma(wordsFixed, hlang, wordKind, anyCategory);
                if (lemmaFixed in _conceptIxByLemma)
                {
                    concepts = [conceptByIx(_conceptIxByLemma[lemmaFixed])];
                }
            }
        }
        return concepts;
    }

    /** Get Concepts related to $(D word) in the interpretation (semantic
        context) $(D wordKind).
        If no wordKind given return all possible.
    */
    Concept[] conceptsByWords(S)(S words,
                                 HLang hlang = HLang.unknown,
                                 WordKind wordKind = WordKind.unknown) if (isSomeString!S)
    {
        typeof(return) concepts;
        if (hlang != HLang.unknown &&
            wordKind != WordKind.unknown)
        {
            return foo(words, hlang, wordKind);
        }
        else
        {
            foreach (hlangGuess; EnumMembers!HLang) // for each language
            {
                if (_hlangCounts[hlangGuess])
                {
                    foreach (wordKindGuess; EnumMembers!WordKind) // for each meaning
                    {
                        if (_kindCounts[wordKindGuess])
                        {
                            concepts ~= foo(words, hlangGuess, wordKindGuess);
                        }
                    }
                }
            }
        }
        if (concepts.empty)
        {
            writeln(`Lookup translation of individual words; bil_tvätt => car-wash`);
            foreach (word; words.splitter(`_`))
            {
                writeln(`Translate word "`, word, `" from `, hlang, ` to English`);
            }
        }
        return concepts;
    }

    /** Construct Network */
    this(string dirPath)
    {
        // WordNet
        _wordnet = new WordNet!(true, true)([HLang.en]);

        // NELL
        readNELLFile("~/Knowledge/nell/NELL.08m.880.esv.csv".expandTilde
                                                            .buildNormalizedPath);

        // ConceptNet
        // GC.disabled had no noticeble effect here: import core.memory: GC;
        const fixedPath = dirPath.expandTilde
                                 .buildNormalizedPath;
        import std.file: dirEntries, SpanMode;
        foreach (file; fixedPath.dirEntries(SpanMode.shallow)
                                .filter!(name => name.extension == `.csv`))
        {
            readCN5File(file);
            break;
        }

        // TODO msgpack fails to pack
        /* auto bytes = this.pack; */
        /* writefln("Packed size: %.2f", bytes.length/1.0e6); */
    }

    /** Lookup Previous or Store New $(D concept) at $(D lemma) index.
     */
    ConceptIx lookupOrStore(Lemma lemma, Concept concept)
    {
        if (lemma in _conceptIxByLemma)
        {
            return _conceptIxByLemma[lemma];
        }
        // store Concept
        assert(_concepts.length <= Ix.max);
        const cix = ConceptIx(cast(Ix)_concepts.length);
        _concepts ~= concept; // .. new concept that is stored
        _conceptIxByLemma[lemma] = cix; // lookupOrStore index to ..
        _conceptStringLengthSum += lemma.words.length;
        return cix;
    }

    /** Read ConceptNet5 URI.
        See also: https://github.com/commonsense/conceptnet5/wiki/URI-hierarchy-5.0
    */
    ConceptIx readCN5ConceptURI(T)(T part)
    {
        auto items = part.splitter('/');

        const hlang = items.front.decodeHumanLang; items.popFront;
        ++_hlangCounts[hlang];

        static if (useRCString) { immutable word = items.front; }
        else                    { immutable word = items.front.idup; }

        items.popFront;
        auto wordKind = WordKind.unknown;
        if (!items.empty)
        {
            const item = items.front;
            wordKind = item.decodeWordKind;
            if (wordKind == WordKind.unknown && item != `_`)
            {
                dln(`Unknown WordKind code `, items.front);
            }
            /* if (wordKind != WordKind.unknown) */
            /* { */
            /*     dln(word, ` has kind `, wordKind); */
            /* } */
        }
        ++_kindCounts[wordKind];

        return lookupOrStore(Lemma(word, hlang, wordKind, anyCategory),
                             Concept(word, hlang, wordKind));
    }

    import std.algorithm: splitter;

    /** Read NELL CSV Line $(D line) at 0-offset line number $(D lnr). */
    void readNELLLine(R, N)(R line, N lnr)
    {
        bool ignored = false;
        auto categoryConceptIx = ConceptIx.undefined;
        auto subjectConceptIx = ConceptIx.undefined;
        auto categoryIx = anyCategory;
        Link link;
        link._origin = Source.nell;

        bool show = false;

        auto parts = line.splitter('\t');
        size_t ix;
        foreach (part; parts)
        {
            switch (ix)
            {
                case 0:
                    auto subject = part.splitter(':');
                    /* writeln(subject); */

                    if (subject.front == "concept")
                    {
                        subject.popFront; // ignore no-meaningful information
                    }
                    else
                    {
                        if (show) writeln("TODO Handle non-concept ", subject);
                        return;
                    }

                    if (show) std.stdio.write("SUBJECT:", subject);

                    /* category */
                    immutable categoryName = subject.front.idup; subject.popFront;
                    if (categoryName in _categoryIxByName)
                    {
                        categoryIx = _categoryIxByName[categoryName];
                    }
                    else
                    {
                        assert(_categoryIxCounter != _categoryIxCounter.max);
                        categoryIx._cIx = _categoryIxCounter++;
                        _categoryNameByIx[categoryIx] = categoryName;
                        _categoryIxByName[categoryName] = categoryIx;
                    }

                    if (subject.empty)
                    {
                        if (show) writeln("TODO Handle category-only ", subject);
                        return;
                    }

                    /* name */
                    immutable subjectName = subject.front.idup; subject.popFront;

                    /* TODO functionize */
                    link._srcIx = subjectConceptIx = lookupOrStore(Lemma(subjectName, HLang.unknown, WordKind.noun, categoryIx),
                                                                   Concept(subjectName, HLang.unknown, WordKind.noun));
                    assert(_links.length <= Ix.max); conceptByIx(link._srcIx).inIxes ~= LinkIx(cast(Ix)_links.length); _connectednessSum++;

                    /* TODO functionize */
                    link._dstIx = categoryConceptIx = lookupOrStore(Lemma(categoryName, HLang.unknown, WordKind.noun, categoryIx),
                                                                    Concept(categoryName, HLang.unknown, WordKind.noun));
                    assert(_links.length <= Ix.max); conceptByIx(link._dstIx).outIxes ~= LinkIx(cast(Ix)_links.length); _connectednessSum++;

                    link._relation = Relation.isA;

                    break;
                case 1:
                    auto predicate = part.splitter(':');
                    if (predicate.front == "concept")
                        predicate.popFront; // ignore no-meaningful information
                    else
                        if (show) writeln("TODO Handle non-concept predicate ", predicate);
                    switch (predicate.front)
                    {
                        case "haswikipediaurl": ignored = true; break;
                        default: if (show) std.stdio.write(" PREDICATE:", part); break;
                    }
                    break;
                default:
                    if (ix < 5 && !ignored)
                    {
                        if (show) std.stdio.write(" MORE:", part);
                    }
                    break;
            }
            ++ix;
        }

        _links ~= link;
        if (show) writeln();
    }

    /** Read ConceptNet CSV Line $(D line) at 0-offset line number $(D lnr). */
    void readCN5Line(R, N)(R line, N lnr)
    {
        auto parts = line.splitter('\t');

        Link link;

        size_t ix;
        foreach (part; parts)
        {
            switch (ix)
            {
                case 1:
                    // TODO Handle case when part matches /r/_wordnet/X
                    link._relation = part[3..$].decodeRelation(link._negation);
                    _relationCounts[link._relation]++;
                    break;
                case 2:         // source concept
                    if (part.skipOver(`/c/`))
                    {
                        link._srcIx = readCN5ConceptURI(part); // TODO use Concept returned from readCN5ConceptURI
                        assert(_links.length <= Ix.max); conceptByIx(link._srcIx).inIxes ~= LinkIx(cast(Ix)_links.length); _connectednessSum++;
                    }
                    else
                    {
                        /* dln("TODO ", part); */
                    }
                    break;
                case 3:         // destination concept
                    if (part.skipOver(`/c/`))
                    {
                        link._dstIx = readCN5ConceptURI(part); // TODO use Concept returned from readCN5ConceptURI
                        assert(_links.length <= Ix.max); conceptByIx(link._dstIx).outIxes ~= LinkIx(cast(Ix)_links.length); _connectednessSum++;
                    }
                    else
                    {
                        /* dln("TODO ", part); */
                    }
                    break;
                case 4:
                    if (part != `/ctx/all`)
                    {
                        /* dln("TODO ", part); */
                    }
                    break;
                case 5:
                    const weight = part.to!real;
                    link.setWeight(weight);
                    _weightSum += weight;
                    _weightMin = min(part.to!float, _weightMin);
                    _weightMax = max(part.to!float, _weightMax);
                    _assertionCount++;
                    break;
                case 6:
                    // TODO Use part.splitter('/')
                    switch (part)
                    {
                        case `/s/dbpedia/3.7`: link._origin = Source.dbpedia37; break;
                        case `/s/dbpedia/3.9/umbel`: link._origin = Source.dbpedia39umbel; break;
                        case `/d/dbpedia/en`:  link._origin = Source.dbpediaEn; break;
                        case `/d/wordnet/3.0`: link._origin = Source.wordnet30; break;
                        case `/s/wordnet/3.0`: link._origin = Source.wordnet30; break;
                        case `/s/site/verbosity`: link._origin = Source.verbosity; break;
                        default: /* dln("Handle ", part); */ break;
                    }
                    _sourceCounts[link._origin]++;
                    break;
                default:
                    break;
            }

            ix++;
        }

        _links ~= link;
    }

    /** Read ConceptNet5 Assertions File $(D path) in CSV format.
        Setting $(D useMmFile) to true increases IO-bandwidth by about a magnitude.
     */
    void readCN5File(string path, bool useMmFile = false)
    {
        writeln("Reading ConceptNet from ", path, " ...");
        size_t lnr = 0;
        /* TODO Functionize and merge with _wordnet.readIx */
        if (useMmFile)
        {
            version(none)
            {
                import std.mmfile: MmFile;
                auto mmf = new MmFile(path, MmFile.Mode.read, 0, null, pageSize);
                auto data = cast(ubyte[])mmf[];
                /* import algorithm_ex: byLine, Newline; */
                foreach (line; data.byLine!(Newline.native)) // TODO Compare with File.byLine
                {
                    readCN5Line(line, lnr); ++lnr;
                }
            }
        }
        else
        {
            foreach (line; File(path).byLine)
            {
                readCN5Line(line, lnr); ++lnr;
            }
        }
        writeln("Reading ConceptNet from ", path, ` having `, lnr, ` lines`);
        showRelations;
    }

    /** Read NELL File $(D fileName) in CSV format.
    */
    void readNELLFile(string path, size_t maxCount = size_t.max)
    {
        writeln("Reading NELL from ", path, " ...");
        size_t lnr = 0;
        foreach (line; File(path).byLine)
        {
            readNELLLine(line, lnr);
            ++lnr;
            if (lnr >= maxCount) break;
        }
        writeln("Read NELL ", path, ` having `, lnr, ` lines`);
    }

    void showRelations()
    {
        writeln(`Relation Count by Type:`);
        foreach (relation; Relation.min .. Relation.max)
        {
            const count = _relationCounts[relation];
            if (count)
            {
                writeln(`- `, relation.to!string, `: `, count);
            }
        }

        writeln(`Concept Count by Source:`);
        foreach (source; Source.min..Source.max)
        {
            const count = _sourceCounts[source];
            if (count)
            {
                writeln(`- `, source.to!string, `: `, count);
            }
        }

        writeln(`Concept Count by Language:`);
        foreach (hlang; HLang.min..HLang.max)
        {
            const count = _hlangCounts[hlang];
            if (count)
            {
                writeln(`- `, hlang.toName, ` (`, hlang.to!string, `) : `, count);
            }
        }

        writeln(`Concept Count by Word Kind:`);
        foreach (wordKind; WordKind.min..WordKind.max)
        {
            const count = _kindCounts[wordKind];
            if (count)
            {
                writeln(`- `, wordKind, ` (`, wordKind.to!string, `) : `, count);
            }
        }

        writeln(`Stats:`);
        writeln(`- Weights Min,Max,Average: `,
                _weightMin, ',', _weightMax, ',', cast(real)_weightSum/_links.length);
        writeln(`- Number of assertions: `, _assertionCount);
        writeln(`- Concept Count: `, _concepts.length);
        writeln(`- Link Count: `, _links.length);
        writeln(`- Concept Indexes by Lemma Count: `, _conceptIxByLemma.length);
        writeln(`- Concept String Length Average: `, cast(real)_conceptStringLengthSum/_concepts.length);
        writeln(`- Concept Connectedness Average: `, cast(real)_connectednessSum/2/_concepts.length);
    }

    /** Return Index to Link from $(D a) to $(D b) if present, otherwise LinkIx.max.
     */
    LinkIx areRelatedInOrder(ConceptIx a,
                             ConceptIx b)
    {
        const cA = conceptByIx(a);
        const cB = conceptByIx(b);
        foreach (inIx; cA.inIxes)
        {
            const inLink = linkByIx(inIx);
            if (inLink._srcIx == b ||
                inLink._dstIx == b)
            {
                return inIx;
            }
        }
        foreach (outIx; cA.outIxes)
        {
            const outLink = linkByIx(outIx);
            if (outLink._srcIx == b ||
                outLink._dstIx == b)
            {
                return outIx;
            }
        }
        return typeof(return).undefined;
    }

    /** Return Index to Link relating $(D a) to $(D b) in any direction if present, otherwise LinkIx.max.
     */
    LinkIx areRelated(ConceptIx a,
                      ConceptIx b)
    {
        const ab = areRelatedInOrder(a, b);
        if (ab != typeof(return).undefined)
        {
            return ab;
        }
        else
        {
            return areRelatedInOrder(b, a);
        }
    }

    /** Return Index to Link relating if $(D a) and $(D b) if they are related. */
    LinkIx areRelated(Lemma a,
                      Lemma b)
    {
        if (a in _conceptIxByLemma &&
            b in _conceptIxByLemma)
        {
            return areRelated(_conceptIxByLemma[a],
                              _conceptIxByLemma[b]);
        }
        return typeof(return).undefined;
    }

    void showLinkRelation(Relation relation, LinkDir linkDir)
    {
        std.stdio.write(` - `,
                        ((!relation.isSymmetric) && linkDir == LinkDir.output ? `<` : ``),
                        `=`, relation, `=`,
                        ((!relation.isSymmetric) && linkDir == LinkDir.input ? `>` : ``));
    }

    void showConcept(in Concept concept, real weight)
    {
        if (concept.words)
            std.stdio.write(` `, concept.words.tr("_", " "));
        std.stdio.write(`(`);
        if (concept.lang)
            std.stdio.write(concept.lang);
        if (concept.lemmaKind)
            std.stdio.write("-", concept.lemmaKind);
        writef(`:%.2f),`, weight);
    }

    void showLinkConcept(in Concept concept, Relation relation, real weight, LinkDir linkDir)
    {
        showLinkRelation(relation, linkDir);
        showConcept(concept, weight);
        writeln();
    }

    /** Show concepts and their relations matching content in $(D line). */
    void showConcepts(S)(S line,
                         HLang hlang = HLang.unknown,
                         WordKind wordKind = WordKind.unknown,
                         S lineSeparator = "_") if (isSomeString!S)
    {
        import std.uni: isWhite, toLower;
        import std.ascii: whitespace;
        import std.algorithm: splitter;
        import std.string: strip;

        // auto normalizedLine = line.strip.splitter!isWhite.filter!(a => !a.empty).joiner(lineSeparator).to!S;
        // See also: http://forum.dlang.org/thread/pyabxiraeabfxujiyamo@forum.dlang.org#post-euqwxskfypblfxiqqtga:40forum.dlang.org
        auto normalizedLine = line.strip.tr(std.ascii.whitespace, "_", "s").toLower;

        writeln(`Line `, normalizedLine);
        foreach (concept; conceptsByWords(normalizedLine,
                                          hlang,
                                          wordKind))
        {
            writeln(`- in `, concept.lang.toName,
                    ` of sense `, concept.lemmaKind, ` relates to `);

            foreach (inGroup; insByRelation(concept))
            {
                showLinkRelation(inGroup.front[0]._relation, LinkDir.input);
                foreach (inLink, inConcept; inGroup)
                {
                    showConcept(inConcept, inLink.normalizedWeight);
                }
                writeln();
            }

            foreach (outGroup; outsByRelation(concept))
            {
                showLinkRelation(outGroup.front[0]._relation, LinkDir.input);
                foreach (outLink, outConcept; outGroup)
                {
                    showConcept(outConcept, outLink.normalizedWeight);
                }
                writeln();
            }

            /* foreach (ix; concept.inIxes) */
            /* { */
            /*     const link = linkByIx(ix); */
            /*     showLinkConcept(conceptByIx(link._dstIx), */
            /*                     link._relation, */
            /*                     link.normalizedWeight, */
            /*                     LinkDir.input); */
            /* } */
            /* foreach (ix; concept.outIxes) */
            /* { */
            /*     const link = linkByIx(ix); */
            /*     showLinkConcept(conceptByIx(link._srcIx), */
            /*                     link._relation, */
            /*                     link.normalizedWeight, */
            /*                     LinkDir.output); */
            /* } */
        }

        if (normalizedLine == "palindrome")
        {
            import std.algorithm: filter;
            import std.utf: byDchar;
            foreach (palindromeConcept; _concepts.filter!(concept => concept.words.isPalindrome(3)))
            {
                showLinkConcept(palindromeConcept,
                                Relation.instanceOf,
                                real.infinity,
                                LinkDir.input);
            }
        }
    }

    /** ConceptNet Relatedness.
        Sum of all paths relating a to b where each path is the path weight
        product.
    */
    real relatedness(ConceptIx a,
                     ConceptIx b) const @safe @nogc pure nothrow
    {
        typeof(return) value;
        return value;
    }

    /** Get Concept with strongest relatedness to $(D keywords).
        TODO Compare with function Context() in ConceptNet API.
     */
    Concept contextOf(string[] keywords) const @safe @nogc pure nothrow
    {
        return typeof(return).init;
    }
    alias topicOf = contextOf;
}
