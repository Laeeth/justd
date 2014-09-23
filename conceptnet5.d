#!/usr/bin/env rdmd-dev-module

/** ConceptNet 5 Commonsense Knowledge Database.

    Reads data from CN5 into a Hypergraph.

    Data: http://conceptnet5.media.mit.edu/downloads/current/

    See also: https://en.wikipedia.org/wiki/Hypergraph
    See also: https://github.com/commonsense/conceptnet5/wiki
    See also: http://forum.dlang.org/thread/fysokgrgqhplczgmpfws@forum.dlang.org#post-fysokgrgqhplczgmpfws:40forum.dlang.org
    See also: http://www.eturner.net/omcsnetcpp/

    TODO Template on NodeData and rename Concept to Node. Instantiate with
    NodeData begin Concept and break out Concept outside.

    TODO Profile read
    TODO Read/Write msgpack. Needs msgpack for RCXString.
    TODO Use containers.HashMap
    TODO Call GC.disable/enable around construction and search.
 */
module conceptnet5;

import std.traits: isSomeString, isFloatingPoint;
import std.conv: to;
import std.stdio;
import std.algorithm: findSplitBefore, findSplitAfter;
import std.container: Array;

import grammars;
import rcstring;
import msgpack;

/* import stdx.allocator; */
/* import memory.allocators; */
/* import containers: HashMap; */

/** Semantic Relation Type Code.
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

@safe @nogc pure nothrow
{
    bool isSymmetric(const Relation relation)
    {
        with (Relation)
        {
            return (relation == relatedTo ||
                    relation == synonym);
        }
    }

    /** Return true if $(D relation) is a transitive relation.
        A relation R from A to B is transitive
        if A => R => B and B => R => C infers A => R => C.
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
    dbpedia37,                  // dbpedia 3.7
    dbpediaEn,                  // dbpedia English
    wordnet30,                  // WordNet 3.0
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

/** Main Net.
*/
class Net(bool useArray = true,
          bool useRCString = true)
{
    import std.file, std.algorithm, std.range, std.string, std.path, std.array;
    import wordnet: WordNet;
    import dbg;

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

    /* String Storage */
    static if (useRCString)
    {
        /* use 31 because CN5 lemmas are on average length of 27 */
        alias Lemma = RCXString!(immutable char, 31);
    }
    else
    {
        alias Lemma = string;
    }

    /* const @safe @nogc pure nothrow */
    version(all) {
        Concept conceptByIndex(ConceptIx ix) { return _concepts[ix._cIx]; }
        Link    linkByIndex   (LinkIx ix) { return _links[ix._lIx]; }
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
        @safe @nogc pure nothrow:
        void setWeight(T)(T weight) if (isFloatingPoint!T)
        {
            this.weight = cast(ubyte)(weight.clamp(0,10)/10*255);
        }
        real normalizedWeight()
        {
            return cast(real)this.weight/25;
        }
    private:
        ConceptIx srcIx;
        ConceptIx dstIx;
        ubyte weight;
        Relation relation;
        bool negation; // relation negation
        Source source;
    }

    unittest
    {
        /* pragma(msg, "LinkIxes.sizeof: ", LinkIxes.sizeof); */
        /* pragma(msg, "ConceptIxes.sizeof: ", ConceptIxes.sizeof); */
        /* pragma(msg, "Concept.sizeof: ", Concept.sizeof); */
        /* pragma(msg, "Link.sizeof: ", Link.sizeof); */
    }

    static if (useArray) { alias Concepts = Array!Concept; }
    else                 { alias Concepts = Concept[]; }

    static if (useArray) { alias Links = Array!Link; }
    else                 { alias Links = Link[]; }

    private
    {
        ConceptIxes[Lemma] _conceptIxesByLemma;
        Concepts _concepts;
        Links _links;

        WordNet!(true, true) _wordnet;

        size_t[Relation.max + 1] relationCounts;
        size_t[Source.max + 1] sourceCounts;
        size_t[HLang.max + 1] hlangCounts;
        size_t _assertionCount = 0;
        size_t _lemmaLengthSum = 0;
        size_t _connectednessSum = 0;

        // is there a Phobos structure for this?
        real weightMin = real.max;
        real weightMax = real.min_normal;
        real weightSum = 0; // Sum of all link weights.
    }

    /** Get Concepts related to $(D word) in the interpretation (semantic
        context) $(D wordKind).
        If no wordKind given return all possible.
    */
    Concepts conceptsByLemma(S)(S lemma,
                                WordKind wordKind = WordKind.unknown) if (isSomeString!S)
    {
        if (wordKind == WordKind.unknown)
        {
            const meanings = this._wordnet.meaningsOf(lemma);
            if (!meanings.empty)
            {
                wordKind = meanings.front.wordKind; // TODO Pick union of all meanings
            }
        }
        _conceptIxesByLemma[lemma];
    }

    this(string dirPath)
    {
        this._wordnet = new WordNet!(true, true);
        // GC.disabled had no noticeble effect here: import core.memory: GC;
        foreach (file; dirPath.expandTilde
                              .buildNormalizedPath
                              .dirEntries(SpanMode.shallow)
                              .filter!(name => name.extension == ".csv")) // I love D :)
        {
            readCSV(file);
            break;
        }
    }

    /** Lookup Previous or Store New $(D concept) at $(D lemma) index. */
    ConceptIx lookupOrStore(S)(S lemma, Concept concept)
    {
        if (lemma in _conceptIxesByLemma)
        {
            // check if lemma with same meaning as in concept already stored
            foreach (cix; _conceptIxesByLemma[lemma])
            {
                const existingConcept = conceptByIndex(cix);
                if (existingConcept.hlang == concept.hlang &&
                    existingConcept.lemmaKind == concept.lemmaKind) // if lemma with same semantic meaning was stored before
                {
                    // dln("Reused index ", cix, " to concept for lemma ", lemma);
                    return cix; // reuse concept index
                }
            }
        }
        else
        {
            static if (useArray)
            {
                /* TODO why is this needed for Array!T but not for T[]?
                   A bug?
                   Or an overload missing? */
                _conceptIxesByLemma[lemma] = ConceptIxes.init;
            }
        }

        // store Concept
        const cix = ConceptIx(cast(Ix)_concepts.length);
        _concepts ~= concept; // .. new concept that is stored
        _conceptIxesByLemma[lemma] ~= cix; // lookupOrStore index to ..

        return cix;
    }

    void showLemmaConcepts(S)(S lemma) if (isSomeString!S)
    {
        if (lemma in _conceptIxesByLemma)
        {
            auto ixes = _conceptIxesByLemma[lemma];
            if (ixes.length >= 5)
            {
                dln("lemma ", lemma, " has multiple interpretations: ",
                    ixes[].map!(cix => (conceptByIndex(cix).hlang.to!string ~ ":" ~
                                        conceptByIndex(cix).lemmaKind.to!string)));
            }
        }
    }

    /** See also: https://github.com/commonsense/conceptnet5/wiki/URI-hierarchy-5.0 */
    ConceptIx readConceptURI(T)(T part)
    {
        auto items = part.splitter('/');

        const hlang = items.front.decodeHumanLang; items.popFront;
        hlangCounts[hlang]++;

        static if (useRCString) { immutable lemma = Lemma(items.front); }
        else                    { immutable lemma = items.front.idup; }

        items.popFront;
        WordKind lemmaKind;
        if (!items.empty)
        {
            const item = items.front;
            lemmaKind = item.decodeWordKind;
            if (lemmaKind == WordKind.unknown
                && item != "_")
            {
                dln("Unknown WordKind code ", items.front);
            }
        }
        _lemmaLengthSum += lemma.length;
        auto cix = this.lookupOrStore(lemma, Concept(hlang, lemmaKind));
        /* showLemmaConcepts(lemma); */
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
                    const relationString = part[3..$];

                    // TODO Functionize to parseRelation or x.to!Relation
                    switch (relationString)
                    {
                        case "RelatedTo":                 link.relation = Relation.relatedTo; break;
                        case "IsA":                       link.relation = Relation.isA; break;
                        case "PartOf":                    link.relation = Relation.partOf; break;
                        case "MemberOf":                  link.relation = Relation.memberOf; break;
                        case "HasA":                      link.relation = Relation.hasA; break;
                        case "UsedFor":                   link.relation = Relation.usedFor; break;
                        case "CapableOf":                 link.relation = Relation.capableOf; break;
                        case "AtLocation":                link.relation = Relation.atLocation; break;
                        case "HasContext":                link.relation = Relation.hasContext; break;
                        case "LocationOf":                link.relation = Relation.locationOf; break;
                        case "LocationOfAction":          link.relation = Relation.locationOfAction; break;
                        case "LocatedNear":               link.relation = Relation.locatedNear; break;
                        case "Causes":                    link.relation = Relation.causes; break;
                        case "Entails":                   link.relation = Relation.entails; break;
                        case "HasSubevent":               link.relation = Relation.hasSubevent; break;
                        case "HasFirstSubevent":          link.relation = Relation.hasFirstSubevent; break;
                        case "HasLastSubevent":           link.relation = Relation.hasLastSubevent; break;
                        case "HasPrerequisite":           link.relation = Relation.hasPrerequisite; break;
                        case "HasProperty":               link.relation = Relation.hasProperty; break;
                        case "Attribute":                 link.relation = Relation.attribute; break;
                        case "MotivatedByGoal":           link.relation = Relation.motivatedByGoal; break;
                        case "ObstructedBy":              link.relation = Relation.obstructedBy; break;
                        case "Desires":                   link.relation = Relation.desires; break;
                        case "CausesDesire":              link.relation = Relation.causesDesire; break;
                        case "DesireOf":                  link.relation = Relation.desireOf; break;
                        case "CreatedBy":                 link.relation = Relation.createdBy; break;
                        case "ReceivesAction":            link.relation = Relation.receivesAction; break;
                        case "Synonym":                   link.relation = Relation.synonym; break;
                        case "Antonym":                   link.relation = Relation.antonym; break;
                        case "Retronym":                  link.relation = Relation.retronym; break;
                        case "DerivedFrom":               link.relation = Relation.derivedFrom; break;
                        case "CompoundDerivedFrom":       link.relation = Relation.compoundDerivedFrom; break;
                        case "EtymologicallyDerivedFrom": link.relation = Relation.etymologicallyDerivedFrom; break;
                        case "TranslationOf":             link.relation = Relation.translationOf; break;
                        case "DefinedAs":                 link.relation = Relation.definedAs; break;
                        case "InstanceOf":                link.relation = Relation.instanceOf; break;
                        case "MadeOf":                    link.relation = Relation.madeOf; break;
                        case "InheritsFrom":              link.relation = Relation.inheritsFrom; break;
                        case "SimilarSize":               link.relation = Relation.similarSize; break;
                        case "SymbolOf":                  link.relation = Relation.symbolOf; break;
                        case "SimilarTo":                 link.relation = Relation.similarTo; break;
                        case "HasPainIntensity":          link.relation = Relation.hasPainIntensity; break;
                        case "HasPainCharacter":          link.relation = Relation.hasPainCharacter; break;
                            // negations
                        case "NotMadeOf":                 link.relation = Relation.madeOf; link.negation = true; break;
                        case "NotIsA":                    link.relation = Relation.isA; link.negation = true; break;
                        case "NotUsedFor":                link.relation = Relation.usedFor; link.negation = true; break;
                        case "NotHasA":                   link.relation = Relation.hasA; link.negation = true; break;
                        case "NotDesires":                link.relation = Relation.desires; link.negation = true; break;
                        case "NotCauses":                 link.relation = Relation.causes; link.negation = true; break;
                        case "NotCapableOf":              link.relation = Relation.capableOf; link.negation = true; break;
                        case "NotHasProperty":            link.relation = Relation.hasProperty; link.negation = true; break;

                        case "AdjectivePertainsTo":       link.relation = Relation.adjectivePertainsTo; link.negation = true; break;
                        case "AdverbPertainsTo":          link.relation = Relation.adverbPertainsTo; link.negation = true; break;
                        case "ParticipleOf":              link.relation = Relation.participleOf; link.negation = true; break;

                        default:
                        writeln("Unknown relationString ", relationString);
                        link.relation = Relation.unknown;
                        break;
                    }

                    this.relationCounts[link.relation]++;
                    break;
                case 2:         // source concept
                    if (part.skipOver(`/c/`))
                    {
                        link.srcIx = this.readConceptURI(part);
                        conceptByIndex(link.srcIx).inIxes ~= LinkIx(cast(Ix)_links.length);
                        _connectednessSum++;
                    }
                    else
                    dln(part);
                    break;
                case 3:         // destination concept
                    if (part.skipOver(`/c/`))
                    {
                        link.dstIx = this.readConceptURI(part);
                        conceptByIndex(link.dstIx).outIxes ~= LinkIx(cast(Ix)_links.length);
                        _connectednessSum++;
                    }
                    else
                    dln(part);
                    break;
                case 4:
                    if (part != `/ctx/all`)
                    {
                        dln(part);
                    }
                    break;
                case 5:
                    const weight = part.to!real;
                    link.setWeight(weight);
                    this.weightSum += weight;
                    this.weightMin = min(part.to!float, this.weightMin);
                    this.weightMax = max(part.to!float, this.weightMax);
                    this._assertionCount++;
                    break;
                case 6:
                    // TODO Use part.splitter('/')
                    switch (part)
                    {
                        case `/s/dbpedia/3.7`: link.source = Source.dbpedia37; break;
                        case `/d/dbpedia/en`:  link.source = Source.dbpediaEn; break;
                        case `/d/wordnet/3.0`: link.source = Source.wordnet30; break;
                        default: break;
                    }
                    this.sourceCounts[link.source]++;
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
                import algorithm_ex: byLine, Newline;
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
        writeln(fileName, " has ", lnr, " lines");
        showRelations;
    }

    void showRelations()
    {
        writeln("Relations:");
        foreach (relation; Relation.min..Relation.max)
        {
            const count = this.relationCounts[relation];
            if (count)
            {
                writeln("- ", relation.to!string, ": ", count);
            }
        }

        writeln("Sources:");
        foreach (source; Source.min..Source.max)
        {
            const count = this.sourceCounts[source];
            if (count)
            {
                writeln("- ", source.to!string, ": ", count);
            }
        }

        writeln("Languages:");
        foreach (hlang; HLang.min..HLang.max)
        {
            const count = this.hlangCounts[hlang];
            if (count)
            {
                writeln("- ", hlang.toName, " (", hlang.to!string, ") : ", count);
            }
        }

        writeln("Stats:");
        writeln("- Weights Min: ", this.weightMin);
        writeln("- Weights Max: ", this.weightMax);
        writeln("- Weights Sum: ", this.weightSum);
        writeln("- Number of assertions: ", this._assertionCount);
        writeln("- Concepts Count: ", _concepts.length);
        writeln("- Concept Lemma Length Average: ", cast(real)_lemmaLengthSum/_concepts.length);
        writeln("- Concept Connectedness Average: ", cast(real)_connectednessSum/_concepts.length);
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

    unittest
    {
        // assert(!new.contextOf(["gun", "mask", "money", "caught", "stole"]).find("robbery").empty);
    }
}

import backtrace.backtrace;

void rcstringPackHandler(ref Packer p, ref RCString rcstring)
{
    writeln("Packing ", p);
    p.pack(rcstring.toString);
}

/* void rcstringUnpackHandler(ref Unpacker u, ref RCString rcstring) */
/* { */
/*     /\* u.unpack(rcstring.toString); *\/ */
/* } */

unittest
{
    registerPackHandler!(RCString, rcstringPackHandler);
    /* registerUnpackHandler!(RCString, rcstringUnpackHandler); */

    writeln(RCString("").pack);
    return;

    import std.stdio: stderr;
    backtrace.backtrace.install(stderr);
    // TODO Add auto-download and unpack from http://conceptnet5.media.mit.edu/downloads/current/

    auto net = new Net!(true, true)(`~/Knowledge/conceptnet5-5.3/data/assertions/`);
    if (true)
    {
        auto netPack = net.pack;
        writeln("Packed to ", netPack.length, " bytes");
    }

    if (false) // just to make all variants of compile
    {
        /* auto netH = new Net!(!useHashedStorage)(`~/Knowledge/conceptnet5-5.3/data/assertions/`); */
    }

    write("Press enter to continue: ");
    readln();
}
