#!/usr/bin/env rdmd-dev-module

/** ConceptNet 5.
    Reads data from CN5 into a Hypergraph.

    See also: https://en.wikipedia.org/wiki/Hypergraph
    See also: https://github.com/commonsense/conceptnet5/wiki

    TODO: If ever will need to sort indexes we should use my radixSort

    TODO: Stricter typing:
          - Only allow Net.nodes to be indexed by NodeIndex
          - Only allow Net.edges to be indexed by EdgeIndex

    TODO: Add Net members
    - byNode
    - byEdge
    - Concept getNode(EdgeIndex)
    - Link getEdge(NodeIndex)

 */
module conceptnet5;

import languages;
import std.conv: to;
import std.stdio;
import std.algorithm: findSplitBefore, findSplitAfter;
import algorithm_ex: findPopBefore;

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
    locationOf,

    causes, /* A and B are events, and it is typical for A to cause B. */

    hasSubevent, /* A and B are events, and B happens as a subevent of A. */

    hasFirstSubevent, /* A is an event that begins with subevent B. */

    hasLastSubevent, /* A is an event that concludes with subevent B. */

    hasPrerequisite, /* In order for A to happen, B needs to happen; B is a
                        dependency of A. /r/HasPrerequisite/ /c/en/drive/ /c/en/get_in_car/ */

    hasProperty, /* A has B as a property; A can be described as
                    B. /r/HasProperty /c/en/ice /c/en/solid */

    motivatedByGoal, /* Someone does A because they want result B; A is a step
                        toward accomplishing the goal B. */
    obstructedBy, /* A is a goal that can be prevented by B; B is an obstacle in
                     the way of A. */

    desires, /* A is a conscious entity that typically wants B. Many assertions
                of this type use the appropriate language's word for "person" as
                A. /r/Desires /c/en/person /c/en/love */

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

    translationOf, /* A and B are concepts (or assertions) in different
                      languages, and overlap in meaning in such a way that they
                      can be considered translations of each other. (This
                      cannot, of course be taken as an exact equivalence.) */

    definedAs, /* A and B overlap considerably in meaning, and B is a more
                  explanatory version of A. (This is similar to TranslationOf,
                  but within one language.) */
}

/** Return true if $(D relation) is transitive. */
bool isTransitive(Relation relation)
    @safe @nogc pure nothrow
{
    with (Relation)
    {
        return (relation == partOf ||
                relation == isA ||
                relation == memberOf ||
                relation == atLocation ||
                relation == hasSubevent ||
                relation == synonym ||
                relation == hasPrerequisite ||
                relation == hasProperty ||
                relation == translationOf);
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
        case Relation.locationOf: return Thematic.spatial;
        case Relation.causes: return Thematic.causal;
        case Relation.hasSubevent: return Thematic.events;
        case Relation.hasFirstSubevent: return Thematic.events;
        case Relation.hasLastSubevent: return Thematic.events;
        case Relation.hasPrerequisite: return Thematic.causal; // TODO: Use events, causal, functional
        case Relation.hasProperty: return Thematic.things;
        case Relation.motivatedByGoal: return Thematic.affective;
        case Relation.obstructedBy: return Thematic.causal;
        case Relation.desires: return Thematic.affective;
        case Relation.createdBy: return Thematic.agents;

        case Relation.synonym: return Thematic.synonym;
        case Relation.antonym: return Thematic.antonym;
        case Relation.retronym: return Thematic.retronym;

        case Relation.derivedFrom: return Thematic.things;
        case Relation.translationOf: return Thematic.synonym;

        case Relation.definedAs: return Thematic.things;
    }
}

/** WordNet Semantic Relation Type Code.
    See also: conceptnet5.Relation
*/
enum WordNetRelation:ubyte
{
    unknown,
    attribute,
    causes,
    classifiedByRegion,
    classifiedByUsage,
    classifiedByTopic,
    entails,
    hyponymOf, // also called hyperonymy, hyponymy,
    instanceOf,
    memberMeronymOf,
    partMeronymOf,
    sameVerbGroupAs,
    similarTo,
    substanceMeronymOf,
    antonymOf,
    derivationallyRelated,
    pertainsTo,
    seeAlso,
}

enum Source:ubyte
{
    dbpedia37,
    dbpediaen,
    wordnet30,
}

TokenId to(T:TokenId)(char x)
    @safe @nogc pure nothrow
{
    switch (x)
    {
        case 'n': return TokenId.noun;
        case 'v': return TokenId.verb;
        case 'a': return TokenId.adjective;
        case 'r': return TokenId.adverb;
    }
}

/** Inference Algorithm. */
void infer(T...)(relations)
{
}

/** Index Precision.
    Set this to $(D uint) if we get low on memory.
*/
alias Index = size_t;

alias EdgeIndex = Index;

/** Concept. */
struct Concept
{
    EdgeIndex[] outIndexes; // into Net.edges
    EdgeIndex[] inIndexes; // into Net.edges
    string concept;
    HLang hlang;
}

alias NodeIndex = Index;

/** Network Hyper Link.
    Its called Hyper because it connects many to many.
 */
struct Link
{
    NodeIndex[] startIndexes; // into Net.nodes
    NodeIndex[] endIndexes; // into Net.nodes
    float weight;
    Relation relation;
    bool negation;
    HLang hlang;
    Source source;
    // sources;
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
    TODO: Call GC.disable/enable around construction and search.
 */
class Net
{
    /** Concepts by WordCategory */
    Concept[][string] conceptsByNoun;
    Concept[][string] conceptsByVerb;
    Concept[][string] conceptsByAdjective;
    Concept[][string] conceptsByAdverb;
    Concept[][string] conceptsByOther;

    import wordnet: WordNet;

    WordNet wordnet;

    /** Get Concepts related to $(D word) in the interpretation (semantic
        context) $(D category).
        If no category given return all possible.
    */
    Concept[] conceptsByWord(string word,
                             WordCategory category = WordCategory.unknown)
        @safe pure
    {
        if (category == WordCategory.unknown)
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

    Link[] links;

    size_t[Relation.max + 1] relationCounts;
    size_t[Source.max + 1] sourceCounts;
    size_t[HLang.max + 1] hlangCounts;
    size_t assertionCount;
    real weightSum = 0; // Sum of all link weights.

    import std.file, std.algorithm, std.range, std.string, std.path, std.mmfile, std.array, std.uni;
    import dbg;

    this(string dirPath)
    {
        this.wordnet = new WordNet("~/Knowledge/wordnet/WordNet-3.0/dict");
        foreach (file; dirPath.expandTilde
                              .buildNormalizedPath
                              .dirEntries(SpanMode.shallow)
                              .filter!(name => name.extension == ".csv")) // I love D :)
        {
            readCSV(file);
        }
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
                        case "RelatedTo":        link.relation = Relation.relatedTo; break;
                        case "IsA":              link.relation = Relation.isA; break;
                        case "PartOf":           link.relation = Relation.partOf; break;
                        case "MemberOf":         link.relation = Relation.memberOf; break;
                        case "HasA":             link.relation = Relation.hasA; break;
                        case "UsedFor":          link.relation = Relation.usedFor; break;
                        case "CapableOf":        link.relation = Relation.capableOf; break;
                        case "AtLocation":       link.relation = Relation.atLocation; break;
                        case "LocationOf":       link.relation = Relation.locationOf; break;
                        case "Causes":           link.relation = Relation.causes; break;
                        case "HasSubevent":      link.relation = Relation.hasSubevent; break;
                        case "HasFirstSubevent": link.relation = Relation.hasFirstSubevent; break;
                        case "HasPrerequisite":  link.relation = Relation.hasPrerequisite; break;
                        case "MotivatedByGoal":  link.relation = Relation.motivatedByGoal; break;
                        case "ObstructedBy":     link.relation = Relation.obstructedBy; break;
                        case "Desires":          link.relation = Relation.desires; break;
                        case "CreatedBy":        link.relation = Relation.createdBy; break;
                        case "Synonym":          link.relation = Relation.synonym; break;
                        case "Antonym":          link.relation = Relation.antonym; break;
                        case "Retronym":         link.relation = Relation.retronym; break;
                        case "DerivedFrom":      link.relation = Relation.derivedFrom; break;
                        case "TranslationOf":    link.relation = Relation.translationOf; break;
                        case "DefinedAs":        link.relation = Relation.definedAs; break;
                        default:                 link.relation = Relation.unknown; break;
                    }

                    this.relationCounts[link.relation]++;
                    break;
                case 2:
                    if (part.skipOver(`/c/`))
                    {
                        const srcLang = part.findPopBefore(`/`).decodeHumanLang;
                        hlangCounts[srcLang]++;
                    }
                    else
                    {
                        dln(part);
                    }
                    break;
                case 3:
                    if (part.skipOver(`/c/`))
                    {
                        const dstLang = part.findPopBefore(`/`).decodeHumanLang;
                        hlangCounts[dstLang]++;
                    }
                    else
                    {
                        dln(part);
                    }
                    break;
                case 4:
                    if (part != `/ctx/all`)
                    {
                        dln(part);
                    }
                    break;
                case 5:
                    this.weightSum += link.weight = part.to!float;
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
        size_t lnr;
        /* TODO: Functionize and merge with wordnet.readIndex */
        if (useMmFile)
        {
            auto mmf= new MmFile(fileName, MmFile.Mode.read, 0, null, pageSize);
            auto data = cast(ubyte[])mmf[];
            import algorithm_ex: byLine, Newline;
            foreach (line; data.byLine!(Newline.native)) // TODO: Compare with File.byLine
            {
                //readCSVLine(line, lnr);
                lnr++;
            }
        }
        else
        {
            foreach (line; File(fileName).byLine)
            {
                readCSVLine(line, lnr);
                lnr++;
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
        writeln("- Sum of weights: ", this.weightSum);
        writeln("- Number of assertions: ", this.assertionCount);
    }

    /** ConceptNet Relatedness.
        Sum of all paths relating a to b where each path is the path weight
        product.
    */
    real relatedness(NodeIndex a,
                     NodeIndex b) @safe @nogc pure nothrow
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
    auto net = new Net(`~/Knowledge/conceptnet5-downloads-20140905/data/assertions/`);
    //auto net = new Net(`/home/per/Knowledge/conceptnet5/assertions`);
}
