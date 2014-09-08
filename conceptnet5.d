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
    - Node getNode(EdgeIndex)
    - Edge getEdge(NodeIndex)
 */
module conceptnet5;

import languages: HumanLang, HumanTokenId;

/** Semantic Relation Type Code.
    See also: https://github.com/commonsense/conceptnet5/wiki/Relations
*/
enum Relation:ubyte
{
    unknown,
    relatedTo, /* The most general relation. There is some positive relationship
                * between A and B, but ConceptNet can't determine what that
                * relationship is based on the data. This was called
                * "ConceptuallyRelatedTo" in ConceptNet 2 through 4.  */
    isA, /* A is a subtype or a specific instance of B; every A is a B. (We do
          * not make the type-token distinction, because people don't usually
          * make that distinction.) This is the hyponym relation in
          * WordNet. /r/IsA /c/en/car /c/en/vehicle ; /r/IsA /c/en/chicago
          * /c/en/city */
    partOf, /* A is a part of B. This is the part meronym relation in WordNet.	/r/PartOf /c/en/gearshift /c/en/car */
    memberOf, /* A is a member of B; B is a group that includes A. This is the member meronym relation in WordNet. */
    hasA, /* B belongs to A, either as an inherent part or due to a social construct of possession. HasA is often the reverse of PartOf.	/r/HasA /c/en/bird /c/en/wing ; /r/HasA /c/en/pen /c/en/ink */

    usedFor, /* A is used for B; the purpose of A is B.	/r/UsedFor /c/en/bridge /c/en/cross_water */
    capableOf, /* Something that A can typically do is B.	/r/CapableOf /c/en/knife /c/en/cut */

    atLocation, /* A is a typical location for B, or A is the inherent location of B. Some instances of this would be considered meronyms in WordNet.	/r/AtLocation /c/en/butter /c/en/refrigerator; /r/AtLocation /c/en/boston /c/en/massachusetts */
    causes, /* A and B are events, and it is typical for A to cause B. */

    hasSubevent, /* A and B are events, and B happens as a subevent of A. */

    hasFirstSubevent, /* A is an event that begins with subevent B. */

    hasLastSubevent, /* A is an event that concludes with subevent B. */

    hasPrerequisite, /* In order for A to happen, B needs to happen; B is a dependency of A.	/r/HasPrerequisite/ /c/en/drive/ /c/en/get_in_car/ */

    hasProperty, /* A has B as a property; A can be described as B.	/r/HasProperty /c/en/ice /c/en/solid */

    motivatedByGoal, /* Someone does A because they want result B; A is a step toward accomplishing the goal B. */
    obstructedBy, /* A is a goal that can be prevented by B; B is an obstacle in the way of A. */

    desires, /* A is a conscious entity that typically wants B. Many assertions of this type use the appropriate language's word for "person" as A.	/r/Desires /c/en/person /c/en/love */

    dreatedBy, /* B is a process that creates A.	/r/CreatedBy /c/en/cake /c/en/bake */

    synonym, /* A and B have very similar meanings. This is the synonym relation in WordNet as well. */

    antonym, /* A and B are opposites in some relevant way, such as being opposite ends of a scale, or fundamentally similar things with a key difference between them. Counterintuitively, two concepts must be quite similar before people consider them antonyms. This is the antonym relation in WordNet as well.	/r/Antonym /c/en/black /c/en/white; /r/Antonym /c/en/hot /c/en/cold */

    derivedFrom, /* A is a word or phrase that appears within B and contributes to B's meaning.	/r/DerivedFrom /c/en/pocketbook /c/en/book */


    translationOf, /* A and B are concepts (or assertions) in different languages, and overlap in meaning in such a way that they can be considered translations of each other. (This cannot, of course be taken as an exact equivalence.) */

    definedAs, /* A and B overlap considerably in meaning, and B is a more explanatory version of A. (This is similar to TranslationOf, but within one language.) */
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

HumanTokenId to(T:HumanTokenId)(char x)
{
    switch (x)
    {
        case 'n': return HumanTokenId.noun;
        case 'v': return HumanTokenId.verb;
        case 'a': return HumanTokenId.adjective;
        case 'r': return HumanTokenId.adverb;
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

/** Network Node. */
struct Node
{
    EdgeIndex[] outIndexes; // into Net.edges
    EdgeIndex[] inIndexes; // into Net.edges
    string concept;
    HumanLang hlang;
}

alias NodeIndex = Index;

/** Network Hyper Edge.
    Its called Hyper because it connects many to many.
 */
struct Edge
{
    NodeIndex[] startIndexes; // into Net.nodes
    NodeIndex[] endIndexes; // into Net.nodes
    Relation rel; // TODO: packed
    bool negation; // TODO: packed
    HumanLang hlang; // TODO: packed
    byte weight; // TODO: normalized
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

/** Main Net. */
class Net
{
    Node[] nodes;
    Edge[] edges;

    import std.mmfile;
    import dbg;

    this(string filename)
    {
        enum ulong mmfile_size = 0; // 100*1024
        _mmfile = new MmFile(filename, MmFile.Mode.read,
                             mmfile_size, null, pageSize());
        auto data = cast(ubyte[])_mmfile[];
        foreach (ix, e; data)
        {
            dln(ix);
        }
    }

    bool freeContents()
    {
        if (_mmfile)
        {
            delete _mmfile;
            _mmfile = null;
            return true;
        }
        else
        {
            return false;
        }
    }

    private MmFile _mmfile = null;
}

unittest
{
    auto net = new Net(`/home/per/conceptnet5/assertions/part_00.csv`);
}
