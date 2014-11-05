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
import std.algorithm: findSplit, findSplitBefore, findSplitAfter, groupBy;
import std.container: Array;
import algorithm_ex: isPalindrome;
import range_ex: stealFront, stealBack;
import std.string: tr;
import std.uni: isWhite, toLower;

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

    causesDesire, // TODO redundant with desires
    desireOf, // TODO redundant with desires

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

    generalizes, // TODO Merge with other enumerator?

    hasRelative,

    hasFamilyMember, // can be a dog

    hasSpouse, // TODO specializes hasFamilyMember
    hasWife, // TODO specializes hasSpouse
    hasHusband, // TODO specializes hasSpouse

    hasSibling, // TODO specializes hasFamilyMember
    hasBrother, // TODO specializes hasSibling
    hasSister, // TODO specializes hasSibling

    hasGrandParent, // TODO specializes hasRelative
    hasParent, // TODO specializes hasFamilyMember
    hasFather, // TODO specializes hasParent
    hasMother, // TODO specializes hasParent

    hasGrandChild, // TODO specializes hasRelative
    hasChild, // TODO specializes hasFamilyMember
    hasSon, // TODO specializes hasChild
    hasDaugther, // TODO specializes hasChild

    wikipediaURL,
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
            auto neg = negation ? " " ~ negationIn(lang) : "";
            switch (relation)
            {
                case relatedTo:
                    switch (lang)
                    {
                        case sv: return "är" ~ neg ~ " relaterat till";
                        case en:
                        default: return "is" ~ neg ~ " related to";
                    }
                case translationOf:
                    switch (lang)
                    {
                        case sv: return "kan" ~ neg ~ " översättas till";
                        case en:
                        default: return "is" ~ neg ~ " translated to";
                    }
                case synonym:
                    switch (lang)
                    {
                        case sv: return "är" ~ neg ~ " synonym med";
                        case en:
                        default: return "is" ~ neg ~ " synonymous with";
                    }
                case antonym:
                    switch (lang)
                    {
                        case sv: return "är" ~ neg ~ " motsatsen till";
                        case en:
                        default: return "is" ~ neg ~ " the opposite of";
                    }
                case similarSize:
                    switch (lang)
                    {
                        case sv: return "är" ~ neg ~ " lika stor som";
                        case en:
                        default: return "is" ~ neg ~ " similar in size to";
                    }
                case similarTo:
                    switch (lang)
                    {
                        case sv: return "är" ~ neg ~ " likvärdig med";
                        case en:
                        default: return "is" ~ neg ~ " similar to";
                    }
                case isA:
                    if (linkDir == LinkDir.output)
                    {
                        switch (lang)
                        {
                            case sv: return "är" ~ neg ~ " en";
                            case de: return "ist" ~ neg ~ " ein";
                            case en:
                            default: return "is" ~ neg ~ " a";
                        }
                    }
                    else
                    {
                        switch (lang)
                        {
                            case sv: return "kan" ~ neg ~ " vara en";
                            case de: return "can" ~ neg ~ " sein ein";
                            case en:
                            default: return "can" ~ neg ~ " be a";
                        }
                    }
                case partOf:
                    if (linkDir == LinkDir.output)
                    {
                        switch (lang)
                        {
                            case sv: return "är" ~ neg ~ " en del av";
                            case en:
                            default: return "is" ~ neg ~ " a part of";
                        }
                    }
                    else
                    {
                        switch (lang)
                        {
                            case sv: return "innehåller" ~ neg;
                            case en:
                            default: return neg ~ "contains";
                        }
                    }
                case memberOf:
                    if (linkDir == LinkDir.output)
                    {
                        switch (lang)
                        {
                            case sv: return "är" ~ neg ~ " en medlem av";
                            case en:
                            default: return "is" ~ neg ~ " a member of";
                        }
                    }
                    else
                    {
                        switch (lang)
                        {
                            case sv: return "kan ha" ~ neg ~ " en medlem";
                            case en:
                            default: return "may" ~ neg ~ " have a member";
                        }
                    }
                case hasA:
                    if (linkDir == LinkDir.output)
                    {
                        switch (lang)
                        {
                            case sv: return "har" ~ neg ~ " en";
                            case en:
                            default: return "has" ~ neg ~ " a";
                        }
                    }
                    else
                    {
                        switch (lang)
                        {
                            case sv: return "tillhör" ~ neg;
                            case en:
                            default: return neg ~ "belongs to";
                        }
                    }
                default:
                    return (((!relation.isSymmetric) && linkDir == LinkDir.output ? `<` : ``) ~
                            `-` ~ relation.to!(typeof(return)) ~ `-` ~
                            ((!relation.isSymmetric) && linkDir == LinkDir.input ? `>` : ``));
            }
        }
    }
}


Relation decodeRelation(S)(S s,
                           out bool negation,
                           out bool reverse) if (isSomeString!S)
{
    with (Relation)
    {
        switch (s.toLower)
        {
            case `relatedto`:                                    return relatedTo;
            case `isa`:                                          return isA;
            case `partof`:                                       return partOf;
            case `memberof`:                                     return memberOf;
            case `hasa`:                                         return hasA;
            case `usedfor`:                                      return usedFor;
            case `capableof`:                                    return capableOf;
            case `atlocation`:                                   return atLocation;
            case `hascontext`:                                   return hasContext;
            case `locationof`:                                   return locationOf;
            case `locationofaction`:                             return locationOfAction;
            case `locatednear`:                                  return locatedNear;
            case `causes`:                                       return causes;
            case `entails`:                                      return entails;
            case `hassubevent`:                                  return hasSubevent;
            case `hasfirstsubevent`:                             return hasFirstSubevent;
            case `haslastsubevent`:                              return hasLastSubevent;
            case `hasprerequisite`:                              return hasPrerequisite;
            case `hasproperty`:                                  return hasProperty;
            case `attribute`:                                    return attribute;
            case `motivatedbygoal`:                              return motivatedByGoal;
            case `obstructedby`:                                 return obstructedBy;
            case `desires`:                                      return desires;
            case `causesdesire`:                                 return causesDesire;
            case `desireof`:                                     return desireOf;
            case `createdby`:                                    return createdBy;
            case `receivesaction`:                               return receivesAction;
            case `synonym`:                                      return synonym;
            case `antonym`:                                      return antonym;
            case `retronym`:                                     return retronym;
            case `derivedfrom`:                                  return derivedFrom;
            case `compoundderivedfrom`:                          return compoundDerivedFrom;
            case `etymologicallyderivedfrom`:                    return etymologicallyDerivedFrom;
            case `translationof`:                                return translationOf;
            case `definedas`:                                    return definedAs;
            case `instanceof`:                                   return instanceOf;
            case `madeof`:                                       return madeOf;
            case `inheritsfrom`:                                 return inheritsFrom;
            case `similarsize`:                                  return similarSize;
            case `symbolof`:                                     return symbolOf;
            case `similarto`:                                    return similarTo;
            case `haspainintensity`:                             return hasPainIntensity;
            case `haspaincharacter`:                             return hasPainCharacter;

            case `notmadeof`:                   negation = true; return madeOf;
            case `notisa`:                      negation = true; return isA;
            case `notusedfor`:                  negation = true; return usedFor;
            case `nothasa`:                     negation = true; return hasA;
            case `notdesires`:                  negation = true; return desires;
            case `notcauses`:                   negation = true; return causes;
            case `notcapableof`:                negation = true; return capableOf;
            case `nothasproperty`:              negation = true; return hasProperty;

            case `wordnet/adjectivepertainsto`: negation = true; return adjectivePertainsTo;
            case `wordnet/adverbpertainsto`:    negation = true; return adverbPertainsTo;
            case `wordnet/participleof`:        negation = true; return participleOf;

                /* NELL: */
            case `hasfamilymember`:                              return hasFamilyMember;
            case `haswife`:                                      return hasWife;
            case `hashusband`:                                   return hasHusband;
            case `hasbrother`:                                   return hasBrother;
            case `hassister`:                                    return hasSister;
            case `hasspouse`:                                    return hasSpouse;
            case `hassibling`:                                   return hasSibling;

            case "haswikipediaurl": return wikipediaURL;
            case "latitudelongitude": return atLocation;
            case "subpartof": return partOf;
            case "synonymfor": return synonym;
            case "generalizations": return generalizes;
            case "specializationof": reverse = true; return generalizes;
            case "conceptprerequisiteof": reverse = true; return hasPrerequisite;
            case "sportusesequipment": reverse = true; return usedFor; // TODO sport, equipment?
            case "sportusesstadium": reverse = true; return usedFor; // TODO  sport, stadium?
            case "sportfansincountry": reverse = true; return locationOf; // TODO sportsfan, country?
            case "sportschoolincountry": reverse = true; return locationOf; // TODO sportsschool, country?
            case "bodypartcontainsbodypart": reverse = true; return partOf; // TODO bodypart, bodypart?

            default:
                writeln(`Unknown relationString `, s);
                return relatedTo;
        }
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
            case relatedTo:   return special != relatedTo;
            case hasRelative: return special == hasFamilyMember;
            case hasSpouse: return special.of(hasWife, hasHusband);
            case hasSibling: return special.of(hasBrother, hasSister);
            case hasParent: return special.of(hasFather, hasMother);
            case hasChild: return special.of(hasSon, hasDaugther);
            case isA: return !special.of(isA, relatedTo);
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
                               similarTo,
                               hasFamilyMember, hasSibling);
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
                               translationOf,
                               hasFamilyMember, hasSibling, hasBrother, hasSister);
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
    with (Relation)
    {
        final switch (relation)
        {
            case relatedTo: return Thematic.kLines;
            case isA: return Thematic.things;
            case partOf: return Thematic.things;
            case memberOf: return Thematic.things;
            case hasA: return Thematic.things;
            case usedFor: return Thematic.functional;
            case capableOf: return Thematic.agents;
            case atLocation: return Thematic.spatial;
            case hasContext: return Thematic.things;

            case locationOf: return Thematic.spatial;
            case locationOfAction: return Thematic.spatial;
            case locatedNear: return Thematic.spatial;

            case causes: return Thematic.causal;
            case hasSubevent: return Thematic.events;
            case hasFirstSubevent: return Thematic.events;
            case hasLastSubevent: return Thematic.events;
            case hasPrerequisite: return Thematic.causal; // TODO Use events, causal, functional
            case hasProperty: return Thematic.things;
            case attribute: return Thematic.things;
            case motivatedByGoal: return Thematic.affective;
            case obstructedBy: return Thematic.causal;
            case desires: return Thematic.affective;
            case causesDesire: return Thematic.affective;
            case desireOf: return Thematic.affective;

            case createdBy: return Thematic.agents;
            case receivesAction: return Thematic.agents;

            case synonym: return Thematic.synonym;
            case antonym: return Thematic.antonym;
            case retronym: return Thematic.retronym;

            case derivedFrom: return Thematic.things;
            case compoundDerivedFrom: return Thematic.things;
            case etymologicallyDerivedFrom: return Thematic.things;
            case translationOf: return Thematic.synonym;

            case definedAs: return Thematic.things;

            case instanceOf: return Thematic.things;
            case madeOf: return Thematic.things;
            case inheritsFrom: return Thematic.things;
            case similarSize: return Thematic.things;
            case symbolOf: return Thematic.kLines;
            case similarTo: return Thematic.kLines;
            case hasPainIntensity: return Thematic.kLines;
            case hasPainCharacter: return Thematic.kLines;

            case adjectivePertainsTo: return Thematic.unknown;
            case adverbPertainsTo: return Thematic.unknown;
            case participleOf: return Thematic.unknown;

            case generalizes: return Thematic.unknown;

            case hasFamilyMember: return Thematic.kLines;
            case hasWife: return Thematic.kLines;
            case hasHusband: return Thematic.kLines;
            case hasBrother: return Thematic.kLines;
            case hasSister: return Thematic.kLines;
            case hasSpouse: return Thematic.kLines;
            case hasSibling: return Thematic.kLines;

            case wikipediaURL: return Thematic.things;
        }
    }

}

enum Origin:ubyte
{
    unknown,
    cn5,
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
        @safe @nogc pure nothrow:
        static LinkIx undefined() { return LinkIx(Ix.max); }
        bool defined() const { return this != LinkIx.undefined; }
    private:
        Ix _lIx = Ix.max;
    }
    struct ConceptIx
    {
        @safe @nogc pure nothrow:
        static ConceptIx undefined() { return ConceptIx(Ix.max); }
        bool defined() const { return this != ConceptIx.undefined; }
    private:
        Ix _cIx = Ix.max;
    }

    /** String Storage */
    static if (useRCString) { alias Words = RCXString!(immutable char, 24-1); }
    else                    { alias Words = immutable string; }

    static if (useArray) { alias ConceptIxes = Array!ConceptIx; }
    else                 { alias ConceptIxes = ConceptIx[]; }
    static if (useArray) { alias LinkIxes = Array!LinkIx; }
    else                 { alias LinkIxes = LinkIx[]; }

    /** Ontology Category Index (currently from NELL). */
    struct CategoryIx
    {
        @safe @nogc pure nothrow:
        static CategoryIx undefined() { return CategoryIx(ushort.max); }
        bool defined() const { return this != CategoryIx.undefined; }
    private:
        ushort _cIx = ushort.max;
    }

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
             CategoryIx categoryIx,
             Origin origin = Origin.unknown,
             LinkIxes inIxes = LinkIxes.init,
             LinkIxes outIxes = LinkIxes.init)
        {
            this.words = words;
            this.lang = lang;
            this.lemmaKind = lemmaKind;
            this.categoryIx = categoryIx;

            this.origin = origin;

            this.inIxes = inIxes;
            this.outIxes = outIxes;
        }
    private:
        LinkIxes inIxes;
        LinkIxes outIxes;

        // TODO Make this Lemma
        Words words;
        HLang lang;
        WordKind lemmaKind;
        CategoryIx categoryIx;

        Origin origin;
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

        this(Relation relation,
             Origin origin = Origin.unknown)
        {
            this._relation = relation;
            this._origin = origin;
        }

        this(Origin origin = Origin.unknown)
        {
            this._origin = origin;
        }

        /** Set ConceptNet5 Weight $(weigth). */
        void setCN5Weight(T)(T weight) if (isFloatingPoint!T)
        {
            // pack from 0..about10 to Weight 0.255 to save memory
            _weight = cast(Weight)(weight.clamp(0,10)/10*Weight.max);
        }

        /** Set NELL Probability Weight $(weight). */
        void setNELLWeight(T)(T weight) if (isFloatingPoint!T)
        {
            _weight = cast(Weight)(weight.clamp(0, 1)*Weight.max);
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

        Origin _origin;
    }

    Concept src(Link link) { return conceptByIx(link._srcIx); }
    Concept dst(Link link) { return conceptByIx(link._dstIx); }

    pragma(msg, `Words.sizeof: `, Words.sizeof);
    pragma(msg, `Lemma.sizeof: `, Lemma.sizeof);
    pragma(msg, `Concept.sizeof: `, Concept.sizeof);
    pragma(msg, `LinkIxes.sizeof: `, LinkIxes.sizeof);
    pragma(msg, `ConceptIxes.sizeof: `, ConceptIxes.sizeof);
    pragma(msg, `Link.sizeof: `, Link.sizeof);

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
        size_t[Origin.max + 1] _linkSourceCounts;
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

    Nullable!Concept conceptByLemmaMaybe(in Lemma lemma)
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
        bool quick = true;
        const maxCount = quick ? 10000 : size_t.max;

        // WordNet
        _wordnet = new WordNet!(true, true)([HLang.en]);

        // NELL
        readNELLFile("~/Knowledge/nell/NELL.08m.880.esv.csv".expandTilde
                                                            .buildNormalizedPath,
                     maxCount);

        // ConceptNet
        // GC.disabled had no noticeble effect here: import core.memory: GC;
        const fixedPath = dirPath.expandTilde
                                 .buildNormalizedPath;
        import std.file: dirEntries, SpanMode;
        foreach (file; fixedPath.dirEntries(SpanMode.shallow)
                                .filter!(name => name.extension == `.csv`))
        {
            readCN5File(file, false, maxCount);
        }

        // TODO msgpack fails to pack
        /* auto bytes = this.pack; */
        /* writefln("Packed size: %.2f", bytes.length/1.0e6); */
    }

    /** Lookup Previous or Store New $(D concept) at $(D lemma) index.
     */
    ConceptIx lookupOrStore(in Lemma lemma,
                            Concept concept)
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

    /** Lookup or Store Concept named $(D words) in language $(D lang). */
    ConceptIx lookupOrStore(Words words,
                            HLang lang,
                            WordKind kind,
                            CategoryIx categoryIx)
    {
        return lookupOrStore(Lemma(words, lang, kind, categoryIx),
                             Concept(words, lang, kind, categoryIx));
    }

    /** Add Link from $(D src) to $(D dst) of type $(D relation) and weight $(D weight). */
    LinkIx connect(ConceptIx srcIx,
                   Relation relation,
                   ConceptIx dstIx,
                   Origin origin,
                   real weight = 1.0,
                   bool negation = false,
                   bool reverse = false)
    {
        LinkIx linkIx = LinkIx(cast(Ix)_links.length);
        auto link = Link(Relation.isA, Origin.nell);

        link._srcIx = reverse ? dstIx : srcIx;
        link._dstIx = reverse ? srcIx : dstIx;

        assert(_links.length <= Ix.max); conceptByIx(link._srcIx).inIxes ~= linkIx; _connectednessSum++;
        assert(_links.length <= Ix.max); conceptByIx(link._dstIx).outIxes ~= linkIx; _connectednessSum++;

        ++_relationCounts[relation];
        ++_linkSourceCounts[origin];

        if (origin == Origin.cn5)
        {
            link.setCN5Weight(weight);
            _weightSum += weight;
            _weightMin = min(weight, _weightMin);
            _weightMax = max(weight, _weightMax);
            _assertionCount++;
        }
        else
        {
            link.setNELLWeight(weight);
        }

        propagateLinkConcepts(link);

        _links ~= link;
        return linkIx; // _links.back;
    }
    alias relate = connect;

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

        return lookupOrStore(word, hlang, wordKind, anyCategory);
    }

    import std.algorithm: splitter;

    /** Read NELL CSV Line $(D line) at 0-offset line number $(D lnr). */
    void readNELLLine(R, N)(R line, N lnr)
    {
        Relation relation = Relation.any;
        bool negation = false;
        bool reverse = false;

        ConceptIx entityIx;
        ConceptIx entityCategoryIx;

        bool ignored = false;
        auto categoryIx = anyCategory;

        LinkIx entityCategoryLink;
        auto valueLink = Link(Origin.nell);
        auto mainLink = Link(Origin.nell);

        bool show = false;

        auto parts = line.splitter('\t');
        size_t ix;
        foreach (part; parts)
        {
            switch (ix)
            {
                case 0:
                    auto entity = part.splitter(':');
                    /* writeln(entity); */

                    if (entity.front == "concept")
                    {
                        entity.popFront; // ignore no-meaningful information
                    }
                    else
                    {
                        writeln("Columns ", parts);
                        return;
                    }

                    if (show) write("ENTITY:", entity);

                    /* category */
                    immutable categoryName = entity.front.idup; entity.popFront;
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

                    if (entity.empty)
                    {
                        if (show) writeln("TODO Handle category-only ", entity);
                        return;
                    }

                    const lang = HLang.unknown;
                    const kind = WordKind.noun;

                    /* name */
                    immutable entityName = entity.front.idup; entity.popFront;

                    entityCategoryLink = connect(entityIx = lookupOrStore(entityName, lang, kind, categoryIx),
                                                 Relation.isA,
                                                 entityCategoryIx = lookupOrStore(categoryName, lang, kind, categoryIx),
                                                 Origin.nell, 1.0);

                    break;
                case 1:
                    auto predicate = part.splitter(':');

                    if (predicate.front == "concept")
                        predicate.popFront; // ignore no-meaningful information
                    else
                        if (show) writeln("TODO Handle non-concept predicate ", predicate);

                    relation = predicate.front.decodeRelation(negation, reverse);
                    ignored = (relation == Relation.wikipediaURL);

                    switch (predicate.front)
                    {
                        // TODO reuse decodeRelation
                        default:
                            writeln(" PREDICATE:", predicate.front);
                            break;
                    }
                    break;
                case 2:
                    if (relation == Relation.atLocation)
                    {
                        const loc = part.findSplit(",");
                        if (!loc[1].empty)
                        {
                            writeln("LATLON: ", loc);
                            setLocation(entityIx,
                                        Location(loc[0].to!double,
                                                 loc[2].to!double));
                        }
                        else
                        {
                            auto value = part.splitter(':');
                            writeln("LOCATION: ", value);
                            if (value.front == "concept")
                            {
                                value.popFront; // ignore no-meaningful information
                            }
                            else
                            {
                                if (show) writeln("TODO Handle non-concept value ", value);
                            }

                        }
                    }
                    break;
                case 4:
                    mainLink.setNELLWeight(part.to!real);
                    break;
                default:
                    if (ix < 5 && !ignored)
                    {
                        if (show) write(" MORE:", part);
                    }
                    break;
            }
            ++ix;
        }

        /* propagateLinkConcepts(mainLink); */
        /* _links ~= mainLink; */

        if (show) writeln();
    }

    struct Location
    {
        double latitude;
        double longitude;
    }

    /** Concept Locations. */
    Location[ConceptIx] _locations;

    /** Set Location of Concept $(D cix) to $(D location) */
    void setLocation(ConceptIx cix, in Location location)
    {
        assert (cix !in _locations);
        _locations[cix] = location;
    }

    /** If $(D link) concept origins unknown propagate them from $(D link)
        itself. */
    bool propagateLinkConcepts(ref Link link)
    {
        bool done = false;
        if (link._origin != Origin.unknown)
        {
            // TODO prevent duplicate lookups to conceptByIx
            if (conceptByIx(link._srcIx).origin != Origin.unknown)
                conceptByIx(link._srcIx).origin = link._origin;
            if (conceptByIx(link._dstIx).origin != Origin.unknown)
                conceptByIx(link._dstIx).origin = link._origin;
            done = true;
        }
        return done;
    }

    /** Decode ConceptNet5 Origin $(D origin). */
    Origin decodeCN5Origin(char[] origin)
    {
        // TODO Use part.splitter('/')
        switch (origin)
        {
            case `/s/dbpedia/3.7`: return Origin.dbpedia37;
            case `/s/dbpedia/3.9/umbel`: return Origin.dbpedia39umbel;
            case `/d/dbpedia/en`:  return Origin.dbpediaEn;
            case `/d/wordnet/3.0`: return Origin.wordnet30;
            case `/s/wordnet/3.0`: return Origin.wordnet30;
            case `/s/site/verbosity`: return Origin.verbosity;
            default: return Origin.cn5; /* dln("Handle ", part); */
        }
    }

    /** Read ConceptNet5 CSV Line $(D line) at 0-offset line number $(D lnr). */
    LinkIx readCN5Line(R, N)(R line, N lnr)
    {
        Relation relation = Relation.any;
        bool negation = false;
        bool reverse = false;

        ConceptIx src;
        ConceptIx dst;
        real weight;
        Origin origin = Origin.unknown;

        auto parts = line.splitter('\t');
        size_t ix;
        foreach (part; parts)
        {
            switch (ix)
            {
                case 1:
                    relation = part[3..$].decodeRelation(negation, reverse); // TODO Handle case when part matches /r/_wordnet/X
                    break;
                case 2:         // source concept
                    if (part.skipOver(`/c/`)) { src = readCN5ConceptURI(part); }
                    else { /* dln("TODO ", part); */ }
                    break;
                case 3:         // destination concept
                    if (part.skipOver(`/c/`)) { dst = readCN5ConceptURI(part); }
                    else { /* dln("TODO ", part); */ }
                    break;
                case 4:
                    if (part != `/ctx/all`) { /* dln("TODO ", part); */ }
                    break;
                case 5:
                    weight = part.to!real;
                    break;
                case 6:
                    origin = decodeCN5Origin(part);
                    break;
                default:
                    break;
            }

            ix++;
        }

        if (src.defined && dst.defined)
        {
            return connect(src, relation, dst, origin, weight, negation, reverse);
        }
        else
        {
            return LinkIx.undefined;
        }
    }

    /** Read ConceptNet5 Assertions File $(D path) in CSV format.
        Setting $(D useMmFile) to true increases IO-bandwidth by about a magnitude.
     */
    void readCN5File(string path, bool useMmFile = false, size_t maxCount = size_t.max)
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
                    readCN5Line(line, lnr);
                    if (++lnr >= maxCount) break;
                }
            }
        }
        else
        {
            foreach (line; File(path).byLine)
            {
                readCN5Line(line, lnr);
                if (++lnr >= maxCount) break;
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

        }
        writeln("Read NELL ", path, ` having `, lnr, ` lines`);
    }

    /** Show Network Relations.
     */
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

        writeln(`Concept Count by Origin:`);
        foreach (source; Origin.min..Origin.max)
        {
            const count = _linkSourceCounts[source];
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
    LinkIx areRelated(in Lemma a,
                      in Lemma b)
    {
        if (a in _conceptIxByLemma &&
            b in _conceptIxByLemma)
        {
            return areRelated(_conceptIxByLemma[a],
                              _conceptIxByLemma[b]);
        }
        return typeof(return).undefined;
    }

    void showLinkRelation(Relation relation, LinkDir linkDir, bool negation = false,
                          HLang lang = HLang.en)
    {
        write(` - `, relation.toHumanLang(linkDir, negation, lang));
    }

    void showConcept(in Concept concept, real weight)
    {
        if (concept.words) write(` `, concept.words.tr("_", " "));
        write(`(`);
        if (concept.lang) write(concept.lang);
        if (concept.lemmaKind) write("-", concept.lemmaKind);
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
            write(`- in `, concept.lang.toName);
            write(` of sense `, concept.lemmaKind);
            writeln(` relates to `);

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
