#!/usr/bin/env rdmd-dev-module

/** ConceptNet 5.
    Reads data from CN5 into a Hypergraph.

    Data: http://conceptnet5.media.mit.edu/downloads/current/

    See also: https://en.wikipedia.org/wiki/Hypergraph
    See also: https://github.com/commonsense/conceptnet5/wiki
    See also: http://forum.dlang.org/thread/fysokgrgqhplczgmpfws@forum.dlang.org#post-fysokgrgqhplczgmpfws:40forum.dlang.org

    TODO: Functionize front and popFront and make use of it

    TODO: If ever will need to sort indexes we should use my radixSort

    TODO: Add Net members
    - byNode
    - byLink
    - Concept getNode(LinkIx)
    - Link getLink(NodeIx)

 */
module conceptnet5;

import languages;
import std.traits: isSomeString, isFloatingPoint;
import std.conv: to;
import std.stdio;
import std.algorithm: findSplitBefore, findSplitAfter;
import std.container: Array;
import algorithm_ex: findPopBefore;

auto clamp(T1, T2, T3)(T1 val, T2 lower, T3 upper)
{
    import std.algorithm: min, max;
    return max(lower, min(upper, val));
}

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

    synonym, /* A and B have very similar meanings. This is the synonym relation
                in WordNet as well. */

    antonym, /* A and B are opposites in some relevant way, such as being
                opposite ends of a scale, or fundamentally similar things with a
                key difference between them. Counterintuitively, two concepts
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

    translationOf, /* A and B are concepts (or assertions) in different
                      languages, and overlap in meaning in such a way that they
                      can be considered translations of each other. (This
                      cannot, of course be taken as an exact equivalence.) */

    definedAs, /* A and B overlap considerably in meaning, and B is a more
                  explanatory version of A. (This is similar to TranslationOf,
                  but within one language.) */

    instanceOf,

    inheritsFrom,
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
        TODO: Where is strength decided and what purpose does it have?
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
        TODO: Where is strongness decided and what purpose does it have?
    */
    bool isWeak(Relation relation)
    {
        with (Relation)
        {
            return (relation == isA ||
                    relation == locationOf);
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
        case Relation.causes: return Thematic.causal;
        case Relation.entails: return Thematic.causal;
        case Relation.hasSubevent: return Thematic.events;
        case Relation.hasFirstSubevent: return Thematic.events;
        case Relation.hasLastSubevent: return Thematic.events;
        case Relation.hasPrerequisite: return Thematic.causal; // TODO: Use events, causal, functional
        case Relation.hasProperty: return Thematic.things;
        case Relation.attribute: return Thematic.things;
        case Relation.motivatedByGoal: return Thematic.affective;
        case Relation.obstructedBy: return Thematic.causal;
        case Relation.desires: return Thematic.affective;
        case Relation.causesDesire: return Thematic.affective;
        case Relation.desireOf: return Thematic.affective;

        case Relation.createdBy: return Thematic.agents;

        case Relation.synonym: return Thematic.synonym;
        case Relation.antonym: return Thematic.antonym;
        case Relation.retronym: return Thematic.retronym;

        case Relation.derivedFrom: return Thematic.things;
        case Relation.compoundDerivedFrom: return Thematic.things;
        case Relation.etymologicallyDerivedFrom: return Thematic.things;
        case Relation.translationOf: return Thematic.synonym;

        case Relation.definedAs: return Thematic.things;

        case Relation.instanceOf: return Thematic.things;
        case Relation.inheritsFrom: return Thematic.things;
    }
}

enum Source:ubyte
{
    dbpedia37,
    dbpediaen,
    wordnet30,
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
    TODO: Use DCD, stringcache, slice ubyte[] allocator
    TODO: Call GC.disable/enable around construction and search.
*/
class Net(bool hashedStorage = true,
          bool useArray = true)
{
    import std.file, std.algorithm, std.range, std.string, std.path, std.array;
    import dbg;

    /** Ix Precision.
        Set this to $(D uint) if we get low on memory.
        Set this to $(D ulong) when number of link nodes exceed Ix.
    */
    alias Ix = uint; // TODO: Change this to size_t when we have more concepts and memory.
    struct LinkIx { Ix ix; } /* alias LinkIx = Ix; */
    static if (useArray)
        alias LinkIxes = Array!LinkIx;
    else
        alias LinkIxes = LinkIx[];

    /** Concept Node/Vertex. */
    struct Concept
    {
        this(const string concept, HLang hlang)
        {
            static if (!hashedStorage)
                this.concept = concept; // in-place of hash-key
            this.hlang = hlang;
        }
    private:
        LinkIxes outIxes; // into Net.links
        LinkIxes inIxes; // into Net.links
        static if (!hashedStorage)
            immutable string concept; // in-place of hash-key
        HLang hlang;
    }

    struct NodeIx { Ix ix; } /* alias NodeIx = Ix; */
    alias NodeIxes = Array!NodeIx;

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
        NodeIxes startIxes; // into Net.nodes
        NodeIxes endIxes; // into Net.nodes
        ubyte weight;
        Relation relation;
        //bool negation;
        HLang hlang;
        Source source;
    }

    private
    {
        static if (hashedStorage)
        {
            /** Concepts by WordKind */
            Concept[][string] conceptsByNoun;
            Concept[][string] conceptsByVerb;
            Concept[][string] conceptsByAdjective;
            Concept[][string] conceptsByAdverb;
            Concept[][string] conceptsByOther;
        }
        else
        {
            Concept[] concepts;
        }
    }

    private Link[] links;

    import wordnet: WordNet;

    WordNet wordnet;

    /** Get Concepts related to $(D word) in the interpretation (semantic
        context) $(D category).
        If no category given return all possible.
    */
    static if (hashedStorage)
    {
        Concept[] conceptsByWord(S)(S word,
                                    WordKind category = WordKind.unknown) if (isSomeString!S)
        {
            if (category == WordKind.unknown)
            {
                const meanings = this.wordnet.meaningsOf(word);
                if (!meanings.empty)
                {
                    category = meanings.front.category; // TODO: Pick union of all meanings
                }
            }
            if      (category.isNoun)      return conceptsByNoun[word];
            else if (category.isVerb)      return conceptsByVerb[word];
            else if (category.isAdjective) return conceptsByAdjective[word];
            else if (category.isAdverb)    return conceptsByAdverb[word];
            else                           return conceptsByOther[word];
        }
    }

    size_t[Relation.max + 1] relationCounts;
    size_t[Source.max + 1] sourceCounts;
    size_t[HLang.max + 1] hlangCounts;
    size_t assertionCount;

    // is there a Phobos structure for this?
    real weightMin = real.max;
    real weightMax = real.min_normal;
    real weightSum = 0; // Sum of all link weights.

    this(string dirPath)
    {
        this.wordnet = new WordNet("~/Knowledge/wordnet/WordNet-3.0/dict");
        // GC.disabled had no noticeble effect here: import core.memory: GC;
        foreach (file; dirPath.expandTilde
                              .buildNormalizedPath
                              .dirEntries(SpanMode.shallow)
                              .filter!(name => name.extension == ".csv")) // I love D :)
        {
            readCSV(file);
        }
    }

    /** Store $(D concept) at $(D lemma) index. */
    auto ref store(S)(S lemma, Concept concept) if (isSomeString!S)
    {
        static if (hashedStorage)
        {
            if      (wordnet.canMean(lemma, WordKind.noun))      { conceptsByNoun[lemma]      ~= concept; }
            else if (wordnet.canMean(lemma, WordKind.verb))      { conceptsByVerb[lemma]      ~= concept; }
            else if (wordnet.canMean(lemma, WordKind.adjective)) { conceptsByAdjective[lemma] ~= concept; }
            else if (wordnet.canMean(lemma, WordKind.adverb))    { conceptsByAdverb[lemma]    ~= concept; }
            else                                                     { conceptsByOther[lemma]     ~= concept; }
        }
        else
        {
            concepts ~= concept;
        }
        return this;
    }

    /** See also: https://github.com/commonsense/conceptnet5/wiki/URI-hierarchy-5.0 */
    auto ref readConceptURI(T)(T part)
    {
        auto items = part.splitter('/');
        const srcLang = items.front.decodeHumanLang; items.popFront;
        hlangCounts[srcLang]++;
        immutable srcConcept = items.front.idup; items.popFront;
        this.store(srcConcept,
                   Concept(srcConcept, srcLang));
        if (!items.empty)
        {
            const category = items.front.parseWordKind;
            if (category == WordKind.unknown)
            {
                dln("Unknown WordKind code ", items.front);
            }
        }
        return srcConcept;
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
                    // TODO: Handle case when part matches /r/wordnet/X
                    const relationString = part[3..$];

                    // TODO: Functionize to parseRelation or x.to!Relation
                    switch (relationString)
                    {
                        case "RelatedTo":           link.relation = Relation.relatedTo; break;
                        case "IsA":                 link.relation = Relation.isA; break;
                        case "PartOf":              link.relation = Relation.partOf; break;
                        case "MemberOf":            link.relation = Relation.memberOf; break;
                        case "HasA":                link.relation = Relation.hasA; break;
                        case "UsedFor":             link.relation = Relation.usedFor; break;
                        case "CapableOf":           link.relation = Relation.capableOf; break;
                        case "AtLocation":          link.relation = Relation.atLocation; break;
                        case "HasContext":          link.relation = Relation.hasContext; break;
                        case "LocationOf":          link.relation = Relation.locationOf; break;
                        case "Causes":              link.relation = Relation.causes; break;
                        case "Entails":             link.relation = Relation.entails; break;
                        case "HasSubevent":         link.relation = Relation.hasSubevent; break;
                        case "HasFirstSubevent":    link.relation = Relation.hasFirstSubevent; break;
                        case "HasLastSubevent":     link.relation = Relation.hasLastSubevent; break;
                        case "HasPrerequisite":     link.relation = Relation.hasPrerequisite; break;
                        case "HasProperty":         link.relation = Relation.hasProperty; break;
                        case "Attribute":           link.relation = Relation.attribute; break;
                        case "MotivatedByGoal":     link.relation = Relation.motivatedByGoal; break;
                        case "ObstructedBy":        link.relation = Relation.obstructedBy; break;
                        case "Desires":             link.relation = Relation.desires; break;
                        case "CausesDesire":        link.relation = Relation.causesDesire; break;
                        case "DesireOf":            link.relation = Relation.desireOf; break;
                        case "CreatedBy":           link.relation = Relation.createdBy; break;
                        case "Synonym":             link.relation = Relation.synonym; break;
                        case "Antonym":             link.relation = Relation.antonym; break;
                        case "Retronym":            link.relation = Relation.retronym; break;
                        case "DerivedFrom":         link.relation = Relation.derivedFrom; break;
                        case "CompoundDerivedFrom": link.relation = Relation.compoundDerivedFrom; break;
                        case "EtymologicallyDerivedFrom": link.relation = Relation.etymologicallyDerivedFrom; break;
                        case "TranslationOf":       link.relation = Relation.translationOf; break;
                        case "DefinedAs":           link.relation = Relation.definedAs; break;
                        case "InstanceOf":          link.relation = Relation.instanceOf; break;
                        case "InheritsFrom":        link.relation = Relation.inheritsFrom; break;
                        default:
                            writeln("Unknown relationString ", relationString);
                            link.relation = Relation.unknown;
                            break;
                    }

                    this.relationCounts[link.relation]++;
                    break;
                case 2:
                    if (part.skipOver(`/c/`))
                        immutable srcConcept = this.readConceptURI(part);
                    else
                        dln(part);
                    break;
                case 3:
                    if (part.skipOver(`/c/`))
                        immutable dstConcept = this.readConceptURI(part);
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
                    this.assertionCount++;
                    break;
                case 6:
                    switch (part)
                    {
                        case `/s/dbpedia/3.7`: link.source = Source.dbpedia37; break;
                        case `/d/dbpedia/en`:  link.source = Source.dbpediaen; break;
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

        links ~= link;
    }

    /** Read ConceptNet5 Assertions File $(D fileName) in CSV format.
        Setting $(D useMmFile) to true increases IO-bandwidth by about a magnitude.
     */
    void readCSV(string fileName, bool useMmFile = false)
    {
        size_t lnr = 0;
        /* TODO: Functionize and merge with wordnet.readIx */
        if (useMmFile)
        {
            version(none)
            {
                import std.mmfile: MmFile;
                auto mmf = new MmFile(fileName, MmFile.Mode.read, 0, null, pageSize);
                auto data = cast(ubyte[])mmf[];
                import algorithm_ex: byLine, Newline;
                foreach (line; data.byLine!(Newline.native)) // TODO: Compare with File.byLine
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
        /* TODO: Functionize foreachs */

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
        writeln("- Number of assertions: ", this.assertionCount);

        static if (hashedStorage)
        {
            writeln("Concept Counts:");
            writeln("- by Nouns: ", conceptsByNoun.length);
            writeln("- by Verbs: ", conceptsByVerb.length);
            writeln("- by Adjectives: ", conceptsByAdjective.length);
            writeln("- by Adverbs: ", conceptsByAdverb.length);
            writeln("- by Others: ", conceptsByOther.length);
        }
    }

    /** ConceptNet Relatedness.
        Sum of all paths relating a to b where each path is the path weight
        product.
    */
    real relatedness(NodeIx a,
                     NodeIx b) @safe @nogc pure nothrow
    {
        typeof(return) value;
        return value;
    }

    /** Get Concept with strongest relatedness to $(D keywords).
        TODO: Compare with function Context() in ConceptNet API.
     */
    Concept contextOf(string[] keywords) @safe @nogc pure nothrow
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

unittest
{
    import std.stdio: stderr;
    backtrace.backtrace.install(stderr);
    // TODO: Add auto-download and unpack from http://conceptnet5.media.mit.edu/downloads/current/

    enum hashedStorage = true;
    auto net = new Net!(hashedStorage)(`~/Knowledge/conceptnet5-5.3/data/assertions/`);

    if (false) // just to make all variants of compile
    {
        auto netH = new Net!(!hashedStorage)(`~/Knowledge/conceptnet5-5.3/data/assertions/`);
    }
    //auto net = new Net(`/home/per/Knowledge/conceptnet5/assertions`);
}
