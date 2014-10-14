#!/usr/bin/env rdmd-dev-module

/** Knowledge Database.

    Reads data from DBpedia, Freebase, Yago, BabelNet, ConceptNet, Nell,
    Wikidata, WikiTaxonomy into a Knowledge Graph.

    Data: http://conceptnet5.media.mit.edu/downloads/current/

    See also: https://en.wikipedia.org/wiki/Hypergraph
    See also: https://github.com/commonsense/conceptnet5/wiki
    See also: http://forum.dlang.org/thread/fysokgrgqhplczgmpfws@forum.dlang.org#post-fysokgrgqhplczgmpfws:40forum.dlang.org
    See also: http://www.eturner.net/omcsnetcpp/

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
import std.algorithm: findSplitBefore, findSplitAfter;
import std.container: Array;

import grammars;
import rcstring;
import msgpack;

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
    unknown,
    relatedTo, /* The most general relation. There is some positive relationship
                * between A and B, but ConceptNet can't determine what that * relationship
                is based on the data. This was called * "ConceptuallyRelatedTo" in
                ConceptNet 2 through 4.  */
    conceptuallyRelatedTo = relatedTo,

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

    entails,

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
            return Relation.unknown;
    }
}

/** NELL Concept Category.
    Typically named NELL.08m.734.categories.csv
*/
enum NELLCategory:ushort
{
    book,
    celltype,
    physicalaction,
    species,
    muscle,
    abstractthing,
    eventoutcome,
    retailstore,
    mlconference,
    bird,
    grain,
    color,
    school,
    personcanada,
    mountain,
    poem,
    dayofweek,
    agriculturalproduct,
    date,
    monarch,
    astronaut,
    fish,
    personeurope,
    cave,
    programminglanguage,
    olympics,
    personus,
    protein,
    visualartist,
    chemical,
    buildingmaterial,
    event,
    url,
    televisionnetwork,
    landscapefeatures,
    hallwayitem,
    mldataset,
    lyrics,
    nerve,
    researchproject,
    weapon,
    braintissue,
    creditunion,
    personmexico,
    nut,
    hospital,
    politicsissue,
    boardgame,
    musicinstrument,
    gamescore,
    transportation,
    cardgame,
    currency,
    condiment,
    politicsblog,
    geopoliticalentity,
    terroristorganization,
    religion,
    economicsector,
    videogamesystem,
    nonneginteger,
    politicsbill,
    year,
    reptile,
    physicsterm,
    fruit,
    politicalparty,
    lake,
    product,
    bakedgood,
    agent,
    furniture,
    country,
    parlourgame,
    charactertrait,
    personaustralia,
    musicalbum,
    room,
    model,
    scientist,
    musicgenre,
    professionalorganization,
    legume,
    personnorthamerica,
    tool,
    trainstation,
    physicalcharacteristic,
    organization,
    farm,
    personafrica,
    conference,
    planet,
    politicsgroup,
    tableitem,
    journalist,
    convention,
    automobilemaker,
    female,
    actor,
    automobilemodel,
    professor,
    geolocatablething,
    dateliteral,
    nondiseasecondition,
    mediatype,
    nongovorganization,
    attraction,
    politicaloffice,
    mlsoftware,
    placeofworship,
    clothing,
    stadiumoreventvenue,
    lymphnode,
    musicartist,
    island,
    visualartmovement,
    bedroomitem,
    geometricshape,
    sportsteam,
    software,
    personalcareitem,
    musicsong,
    humanagent,
    televisionshow,
    bank,
    insect,
    personsouthamerica,
    sport,
    animal,
    bodypart,
    wine,
    hobby,
    director,
    museum,
    vertebrate,
    emotion,
    mammal,
    crimeorcharge,
    movie,
    perceptionaction,
    county,
    aquarium,
    language,
    newspaper,
    architect,
    invertebrate,
    person,
    sociopolitical,
    recipe,
    disease,
    street,
    month,
    vehicle,
    filmfestival,
    politicianus,
    perceptionevent,
    airport,
    sportsleague,
    arthropod,
    zoo,
    shoppingmall,
    athlete,
    musician,
    artery,
    mlmetric,
    chef,
    archaea,
    male,
    zipcode,
    personbylocation,
    crustacean,
    medicalprocedure,
    item,
    awardtrophytournament,
    company,
    arachnid,
    personasia,
    beverage,
    vegetable,
    sportsteamposition,
    kitchenitem,
    highschool,
    stateorprovince,
    port,
    buildingfeature,
    beach,
    llcoordinate,
    academicfield,
    tradeunion,
    geopoliticalorganization,
    geopoliticallocation,
    mlarea,
    amphibian,
    ethnicgroup,
    writer,
    ceo,
    videogame,
    judge,
    game,
    nonprofitorganization,
    building,
    musicfestival,
    flooritem,
    publication,
    creativework,
    food,
    consumerelectronicitem,
    bridge,
    continent,
    bacteria,
    hotel,
    personantarctica,
    radiostation,
    winery,
    televisionstation,
    fungus,
    blog,
    bathroomitem,
    restaurant,
    plant,
    race,
    trail,
    sportsequipment,
    recordlabel,
    drug,
    university,
    mlauthor,
    governmentorganization,
    jobposition,
    wallitem,
    website,
    coach,
    celebrity,
    mollusk,
    visualartform,
    weatherphenomenon,
    election,
    mediacompany,
    householditem,
    skiarea,
    traditionalgame,
    grandprix,
    river,
    sportsevent,
    sportsgame,
    officeitem,
    city,
    location,
    biotechcompany,
    highway,
    vein,
    cheese,
    militaryeventtype,
    automobileengine,
    comedian,
    cognitiveactions,
    mlalgorithm,
    bone,
    physiologicalcondition,
    politician,
    meat,
    magazine,
    skyscraper,
    park,
    militaryconflict,
    monument,
    criminal,
    mountainrange,
    candy,
    profession,
}

@safe @nogc pure nothrow
{
    bool isSymmetric(const Relation relation)
    {
        with (Relation)
        {
            return (relation == relatedTo ||
                    relation == translationOf ||
                    relation == synonym);
        }
    }

    /** Return true if $(D relation) is a transitive relation that can used to
        inference new relations (knowledge).

        A relation R from A to B is transitive if A >=R=> B and B >=R=> C
        infers A >=R=> C.
    */
    bool isTransitive(const Relation relation)
    {
        with (Relation)
        {
            return (relation == partOf ||
                    relation == isA ||
                    relation == memberOf ||
                    relation == atLocation ||
                    relation == hasContext ||
                    relation == hasSubevent ||
                    relation == synonym ||
                    relation == hasPrerequisite ||
                    relation == hasProperty ||
                    relation == translationOf);
        }
    }

    /** Return true if $(D relation) is a strong.
        TODO Where is strength decided and what purpose does it have?
    */
    bool isStrong(Relation relation)
    {
        with (Relation)
        {
            return (relation == hasProperty ||
                    relation == motivatedByGoal);
        }
    }

    /** Return true if $(D relation) is a weak.
        TODO Where is strongness decided and what purpose does it have?
    */
    bool isWeak(Relation relation)
    {
        with (Relation)
        {
            return (relation == isA ||
                    relation == locationOf ||
                    relation == locationOfAction ||
                    relation == locatedNear);
        }
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
        case Relation.unknown: return Thematic.unknown;
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
        case Relation.entails: return Thematic.causal;
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
    import std.algorithm, std.range, std.string, std.path, std.array;
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
    struct LinkIx { Ix _lIx; }
    struct ConceptIx { Ix _cIx; }
    static if (useArray) { alias ConceptIxes = Array!ConceptIx; }
    else                 { alias ConceptIxes = ConceptIx[]; }
    static if (useArray) { alias LinkIxes = Array!LinkIx; }
    else                 { alias LinkIxes = LinkIx[]; }

    /** String Storage */
    static if (useRCString) { alias Words = RCXString!(immutable char, 24-1); }
    else                    { alias Words = immutable string; }

    /** Concept Lemma. */
    struct Lemma
    {
        Words words;
        HLang lang;
        WordKind wordKind;
    }

    /** Concept Node/Vertex. */
    struct Concept
    {
        this(HLang hlang,
             WordKind lemmaKind,
             LinkIxes inIxes = LinkIxes.init,
             LinkIxes outIxes = LinkIxes.init)
        {
            this.hlang = hlang;
            this.lemmaKind = lemmaKind;
            this.inIxes = inIxes;
            this.outIxes = outIxes;
        }
    private:
        LinkIxes inIxes;
        LinkIxes outIxes;
        HLang hlang;
        WordKind lemmaKind;
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
            this._weight = cast(Weight)(weight.clamp(0,10)/10*Weight.max);
        }
        real normalizedWeight()
        {
            return cast(real)this._weight/(cast(real)Weight.max/10);
        }
    private:
        ConceptIx _srcIx;
        ConceptIx _dstIx;
        Weight _weight;
        Relation _relation;
        bool _negation; // relation negation
        Source _origin;
    }

    unittest
    {
        pragma(msg, `LinkIxes.sizeof: `, LinkIxes.sizeof);
        pragma(msg, `ConceptIxes.sizeof: `, ConceptIxes.sizeof);
        pragma(msg, `Concept.sizeof: `, Concept.sizeof);
        pragma(msg, `Link.sizeof: `, Link.sizeof);
    }

    static if (useArray) { alias Concepts = Array!Concept; }
    else                 { alias Concepts = Concept[]; }

    static if (useArray) { alias Links = Array!Link; }
    else                 { alias Links = Link[]; }

    private
    {
        ConceptIx[Lemma] _conceptIxByLemma;
        Concepts _concepts;
        Links _links;

        WordNet!(true, true) _wordnet;

        size_t[Relation.max + 1] _relationCounts;
        size_t[Source.max + 1] _sourceCounts;
        size_t[HLang.max + 1] _hlangCounts;
        size_t _assertionCount = 0;
        size_t _conceptStringLengthSum = 0;
        size_t _connectednessSum = 0;

        // is there a Phobos structure for this?
        real _weightMin = real.max;
        real _weightMax = real.min_normal;
        real _weightSum = 0; // Sum of all link weights.
    }

    ref Link linkByIndex(LinkIx ix) { return _links[ix._lIx]; }

    /* const @safe @nogc pure nothrow */
    ref Concept conceptByIndex(ConceptIx ix) { return _concepts[ix._cIx]; }

    Nullable!Concept conceptByLemmaMaybe(Lemma lemma)
    {
        if (lemma in _conceptIxByLemma)
        {
            return typeof(return)(conceptByIndex(_conceptIxByLemma[lemma]));
        }
        else
        {
            return typeof(return).init;
        }
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
            auto lemma = Lemma(words, hlang, wordKind);
            if (lemma in _conceptIxByLemma)
                concepts = [conceptByIndex(_conceptIxByLemma[lemma])];
        }
        else
        {
            foreach (hlang_; EnumMembers!HLang)
            {
                foreach (wordKind_; EnumMembers!WordKind)
                {
                    auto lemma = Lemma(words, hlang_, wordKind_);
                    if (lemma in _conceptIxByLemma)
                        concepts ~= conceptByIndex(_conceptIxByLemma[lemma]);
                }
            }
            return concepts;
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

    this(string dirPath)
    {
        this._wordnet = new WordNet!(true, true)([HLang.en]);
        // GC.disabled had no noticeble effect here: import core.memory: GC;
        const fixedPath = dirPath.expandTilde
                                 .buildNormalizedPath;
        import std.file: dirEntries, SpanMode;
        foreach (file; fixedPath.dirEntries(SpanMode.shallow)
                                .filter!(name => name.extension == `.csv`))
        {
            readCSV(file);
            break;
        }
    }

    /** Lookup Previous or Store New $(D concept) at $(D lemma) index. */
    ConceptIx lookupOrStore(Lemma lemma, Concept concept)
    {
        if (lemma in _conceptIxByLemma)
        {
            return _conceptIxByLemma[lemma];
        }
        // store Concept
        const cix = ConceptIx(cast(Ix)_concepts.length);
        _concepts ~= concept; // .. new concept that is stored
        _conceptIxByLemma[lemma] = cix; // lookupOrStore index to ..
        _conceptStringLengthSum += lemma.words.length;
        return cix;
    }

    /** See also: https://github.com/commonsense/conceptnet5/wiki/URI-hierarchy-5.0 */
    ConceptIx readConceptURI(T)(T part)
    {
        auto items = part.splitter('/');

        const hlang = items.front.decodeHumanLang; items.popFront;
        _hlangCounts[hlang]++;

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

        auto cix = this.lookupOrStore(Lemma(word, hlang, wordKind),
                                      Concept(hlang, wordKind));
        return cix;
    }

    /** Read CSV Line $(D line) at 0-offset line number $(D lnr). */
    void readCSVLine(R, N)(R line, N lnr)
    {
        import std.algorithm: splitter;
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
                    this._relationCounts[link._relation]++;
                    break;
                case 2:         // source concept
                    if (part.skipOver(`/c/`))
                    {
                        link._srcIx = this.readConceptURI(part);
                        assert(_links.length < Ix.max);
                        conceptByIndex(link._srcIx).inIxes ~= LinkIx(cast(Ix)_links.length);
                        _connectednessSum++;
                    }
                    else
                    {
                        /* dln("TODO ", part); */
                    }
                    break;
                case 3:         // destination concept
                    if (part.skipOver(`/c/`))
                    {
                        link._dstIx = this.readConceptURI(part);
                        assert(_links.length < Ix.max);
                        conceptByIndex(link._dstIx).outIxes ~= LinkIx(cast(Ix)_links.length);
                        _connectednessSum++;
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
                    this._weightSum += weight;
                    this._weightMin = min(part.to!float, this._weightMin);
                    this._weightMax = max(part.to!float, this._weightMax);
                    this._assertionCount++;
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
                    this._sourceCounts[link._origin]++;
                    break;
                default:
                    break;
            }

            ix++;
        }

        _links ~= link;
    }

    /** Read ConceptNet5 Assertions File $(D fileName) in CSV format.
        Setting $(D useMmFile) to true increases IO-bandwidth by about a magnitude.
     */
    void readCSV(string fileName, bool useMmFile = false)
    {
        size_t lnr = 0;
        /* TODO Functionize and merge with _wordnet.readIx */
        if (useMmFile)
        {
            version(none)
            {
                import std.mmfile: MmFile;
                auto mmf = new MmFile(fileName, MmFile.Mode.read, 0, null, pageSize);
                auto data = cast(ubyte[])mmf[];
                /* import algorithm_ex: byLine, Newline; */
                foreach (line; data.byLine!(Newline.native)) // TODO Compare with File.byLine
                {
                    readCSVLine(line, lnr); lnr++;
                }
            }
        }
        else
        {
            foreach (line; File(fileName).byLine)
            {
                readCSVLine(line, lnr); lnr++;
            }
        }
        writeln(fileName, ` has `, lnr, ` lines`);
        showRelations;
    }

    void showRelations()
    {
        writeln(`Relation Count by Type:`);
        foreach (relation; Relation.min..Relation.max)
        {
            const count = this._relationCounts[relation];
            if (count)
            {
                writeln(`- `, relation.to!string, `: `, count);
            }
        }

        writeln(`Concept Count by Source:`);
        foreach (source; Source.min..Source.max)
        {
            const count = this._sourceCounts[source];
            if (count)
            {
                writeln(`- `, source.to!string, `: `, count);
            }
        }

        writeln(`Concept Count by Language:`);
        foreach (hlang; HLang.min..HLang.max)
        {
            const count = this._hlangCounts[hlang];
            if (count)
            {
                writeln(`- `, hlang.toName, ` (`, hlang.to!string, `) : `, count);
            }
        }

        writeln(`Stats:`);
        writeln(`- Weights Min,Max,Average: `,
                this._weightMin, ',', this._weightMax, ',', cast(real)this._weightSum/this._links.length);
        writeln(`- Number of assertions: `, this._assertionCount);
        writeln(`- Concept Count: `, _concepts.length);
        writeln(`- Link Count: `, _links.length);
        writeln(`- Concept Indexes by Lemma Count: `, _conceptIxByLemma.length);
        writeln(`- Concept String Length Average: `, cast(real)_conceptStringLengthSum/_concepts.length);
        writeln(`- Concept Connectedness Average: `, cast(real)_connectednessSum/2/_concepts.length);
    }

    /** Link Direction. */
    enum LinkDir
    {
        input,
        output
    }

    void showConceptLink(in Link link, LinkDir dir)
    {
        const linkConcept = conceptByIndex(link._dstIx);
        std.stdio.write(`  - `, dir, ` =`, link._relation, `=> `);
        if (linkConcept.hlang) std.stdio.write(` hlang:`, linkConcept.hlang);
        if (linkConcept.lemmaKind) std.stdio.write(` hlang:`, linkConcept.lemmaKind);
        writeln(` weight:`, link._weight);
    }

    /** Show concepts and their relations matching content in $(D line). */
    void showConcepts(S)(S line,
                         HLang hlang = HLang.unknown,
                         WordKind wordKind = WordKind.unknown,
                         S lineSeparator = "_") if (isSomeString!S)
    {
        import std.uni: isWhite;
        import std.algorithm: splitter;
        import std.string: strip;
        auto normalizedLine = line.strip.splitter!isWhite.joiner(lineSeparator).to!S;
        writeln(`Line `, normalizedLine);
        foreach (concept; this.conceptsByWords(normalizedLine,
                                               hlang,
                                               wordKind))
        {
            writeln(`- in `, concept.hlang.toName,
                    ` of sense `, concept.lemmaKind, ` relates to `);
            foreach (ix; concept.inIxes)
            {
                showConceptLink(linkByIndex(ix), LinkDir.input);
            }
            foreach (ix; concept.outIxes)
            {
                showConceptLink(linkByIndex(ix), LinkDir.output);
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
