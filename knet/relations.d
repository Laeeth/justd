module knet.relations;

import std.algorithm.comparison: among;

/** Semantic Relation Type Code.
    See also: https://github.com/commonsense/conceptnet5/wiki/Relations
*/
enum Rel:ubyte
{
    relatedTo, /**< he most general relation. There is some positive relationship
                * between A and B, but ConceptNet can't determine what that * relationship
                is based on the data. This was called * "ConceptuallyRelatedTo" in
                ConceptNet 2 through 4.  */
    any = relatedTo,

    hypernymOf, ///< WordNet. Reversion of isA
    superordinateOf = hypernymOf, ///< WordNet. Use reversion of isA instead.

    instanceHypernymOf, ///< WordNet.

    isA, /**< A is a subtype or a specific instance of B; every A is a B. (We do
          * not make the type-token distinction, because people don't usually
          * make that distinction.) This is the hyponym relation in WordNet. */
    hyponymOf = isA, ///< WordNet. Use isA instead.
    subordinateOf = hyponymOf, ///< WordNet. Use isA instead.
    subclasses = subordinateOf,
    subclassOf = subclasses,

    instanceHyponymOf, ///< WordNet.

    mayBeA,

    partOf, /**< A is a part of B. This is the part meronym relation in
               WordNet. /r/PartOf /c/en/gearshift /c/en/car */
    meronym = partOf,

    memberOf, /**< A is a member of B; B is a group that includes A. This is the
                 member meronym relation in WordNet. */

    memberHolonym,             ///< WordNet.
    substanceHolonym,          ///< WordNet.
    partHolonym,               ///< WordNet.
    attribute,                 ///< WordNet. A noun for which adjectives express values. The noun weight is an attribute, for which the adjectives light and heavy express values.
    derivationallyRelatedForm, ///< WordNet.

    topicDomainOfSynset,       ///< WordNet.
    memberOfTopicDomain,       ///< WordNet.

    regionDomainOfSynset,      ///< WordNet.
    memberOfRegionDomain,      ///< WordNet.

    usageDomainOfSynset,       ///< WordNet.
    memberOfUsageDomain,       ///< WordNet.

    alsoSee,                   ///< WordNet.
    pertainym,                 ///< WordNet.

    memberOfEconomicSector,
    participatesIn,
    growsIn,
    attends,
    worksFor,
    worksInAcademicField,
    writesForPublication,

    leaderOf,
    coaches,
    ceoOf,
    represents,
    concerns, // TODO relate

    multipleOf,

    writtenAboutInPublication,

    plays,
    playsInstrument,
    playsIn,
    playsFor,

    shapes,
    cutsInto,
    breaksInto,

    wins,
    loses,

    contributesTo,
    topMemberOf, // TODO Infers leads

    hasA, /**< B belongs to A, either as an inherent part or due to a social
             construct of possession. HasA is often the reverse of PartOf. /r/HasA
             /c/en/bird /c/en/wing ; /r/HasA /c/en/pen /c/en/ink */

    uses, /**< everse of usedFor: A is used for B; the purpose of A is B. /r/UsedFor /c/en/bridge
             /c/en/cross_water */
    usesLanguage,
    usesTool,

    capableOf, /**< Something that A can typically do is B. /r/CapableOf
                  /c/en/knife /c/en/cut */

    // or locatedNear?
    atLocation, /**< A is a typical location for B, or A is the inherent location
                   of B. Some instances of this would be considered meronyms in
                   WordNet. /r/AtLocation /c/en/butter /c/en/refrigerator; /r/AtLocation
                   /c/en/boston /c/en/massachusetts */
    locatedAt = atLocation,
    hasCitizenship,
    livesIn = hasCitizenship,

    hasEthnicity,
    hasResidenceIn,
    hasHome,
    languageSchoolInCity,
    grownAtLocation,
    producedAtLocation,
    inRoom,

    bornInLocation,
    diedInLocation,

    hasOfficeIn,
    headquarteredIn,

    hasContext,
    slangFor,
    idiomFor,

    locatedNear,                // TODO or AtLocation?
    borderedBy,

    controls,

    causes, /**< A and B are events, and it is typical for A to cause B. */
    leadsTo = causes,

    // entails,                    /**< opposite of causes */
    causesSideEffect,

    decreasesRiskOf,
    treats,

    hasSubevent, /**< A and B are events, and B happens as a subevent of A. */
    hasFirstSubevent, /**< A is an event that begins with subevent B. */
    hasLastSubevent, /**< A is an event that concludes with subevent B. */

    hasPrerequisite, /**< In order for A to happen, B needs to happen; B is a
                        dependency of A. /r/HasPrerequisite/ /c/en/drive/ /c/en/get_in_car/ */

    beganAtTime,
    endedAtTime,

    beganBefore,
    beganAfter,
    endedBefore,
    endedAfter,

    hasProperty, /**< A has B as a property; A can be described as
                    B. /r/HasProperty /c/en/ice /c/en/solid
                    See also: https://english.stackexchange.com/questions/150529/what-is-the-difference-between-property-and-attribute
                 */
    hasAttribute,

    // TODO replace with hasProperty and hasAttribute
    hasShape,
    hasColor,
    hasSize,
    hasDiameter,
    hasArea,
    hasLength,
    hasHeight,
    hasWidth,
    hasThickness,
    hasWeight,
    hasAge,
    hasWebsite,
    hasOfficialWebsite,
    hasJobPosition, hasEmployment = hasJobPosition,
    hasTeamPosition,
    hasTournament,
    hasCapital,
    hasExpert,
    hasLanguage,
    hasOrigin,
    hasCurrency,

    hasEmotion, // TODO remove this and use "love" isA "emotion"?

    motivatedByGoal, /**< Someone does A because they want result B; A is a step
                        toward accomplishing the goal B. */
    obstructedBy, /**< A is a goal that can be prevented by B; B is an obstacle in
                     the way of A. */

    causesDesire,

    desires, /**< A is a conscious entity that typically wants B. Many assertions
                of this type use the appropriate language's word for "person" as
                A. /r/Desires /c/en/person /c/en/love */
    eats,
    owns,

    starts,
    begins = starts,

    ends,
    finishes = ends,
    terminates = ends,
    kills,

    injures,
    selfinjures,

    buys, // TODO buys => owns
    acquires,
    affiliatesWith,

    hires,
    sponsors, // TODO related

    creates, /**< B is a process that creates A. /r/CreatedBy /c/en/cake
                /c/en/bake */
    develops,
    produces,
    writes,

    receivesAction,

    synonymFor, /**< A and B have very similar meanings. This is the synonym relation
                in WordNet as well. */
    synonym = synonymFor,

    obsolescentFor,

    antonymFor, oppositeOf = antonymFor, /**< A and B are opposites in some relevant way, such as being
                opposite ends of a scale, or fundamentally similar things with a
                key difference between them. Counterintuitively, two _concepts
                must be quite similar before people consider them antonyms. This
                is the antonym relation in WordNet as well. /r/Antonym
                /c/en/black /c/en/white; /r/Antonym /c/en/hot /c/en/cold */
    antonym = antonymFor,

    homonymFor, // Word with same spelling and pronounciation, but different meaning

    contronymFor,  // Word with same spelling but with different pronounciation and meaning
    contranymFor = contronymFor,
    autoantonymFor = contranymFor,
    homographFor = autoantonymFor,

    homophoneFor, // Word with same pronounication, but different spelling and meaning

    reversionOf,

    retronymFor, differentation = retronymFor, // $(EM acoustic) guitar. https://en.wikipedia.org/wiki/Retronym

    togetherWritingFor,

    symbolFor,
    abbreviationFor, shorthandFor = abbreviationFor,
    contractionFor,  // sammandragning

    acronymFor,
    emoticonFor,

    physicallyConnectedWith,
    arisesFrom,
    emptiesInto,

    derivedFrom, /**< A is a word or phrase that appears within B and contributes
                    to B's meaning. /r/DerivedFrom /c/en/pocketbook /c/en/book
                 */

    compoundDerivedFrom,

    etymologicallyDerivedFrom,

    translationOf, /**< A and B are _concepts (or assertions) in different
                      languages, and overlap in meaning in such a way that they
                      can be considered translations of each other. (This
                      cannot, of course be taken as an exact equivalence.) */

    definedAs, /**< A and B overlap considerably in meaning, and B is a more
                  explanatory version of A. (This is similar to TranslationOf,
                  but within one language.) */

    instanceOf,

    madeOf, // TODO Unite with instanceOf?
    madeBy,
    madeAt,

    inheritsFrom,

    // comparison. TODO generalize using adjectives and three way link
    isTallerThan,
    isLargerThan,
    isHeavierThan,
    isOlderThan,
    areMoreThan,

    symbolOf,

    similarTo,
    similarSizeTo,
    similarAppearanceTo,
    looksLike = similarAppearanceTo,

    hasPainIntensity,
    hasPainCharacter,

    adjectivePertainsTo,
    adverbPertainsTo,
    participleOf,

    formOfWord,
    formOfVerb,
    participleOfVerb,
    formOfNoun,
    formOfAdjective,

    hasNameDay,

    hasRelative,
    hasFamilyMember, // can be a dog

    hasFriend, // opposite of hasFriend
    hasTeamMate,
    hasEnemy,

    hasSpouse,
    hasWife,
    hasHusband,

    hasSibling,
    hasBrother,
    hasSister,

    hasGrandParent,
    hasParent,
    hasFather,
    hasMother,

    hasGrandChild,
    hasChild,
    hasSon,
    hasDaugther,
    hasPet, // TODO dst concept is animal

    hasScore,
    hasLoserScore,
    hasWinnerScore,

    wikipediaURL,

    atTime,
    proxyFor,
    mutualProxyFor,

    competesWith,
    involvedWith,
    collaboratesWith,

    graduatedFrom,
    agentCreated,

    createdAtDate,
    bornIn,
    foundedIn, // TODO replace by higher-order predicate: Skänninge city was founded at 1200
    marriedIn,
    diedIn,
    diedAtAge,

    chargedWithCrime,

    movedTo, // TODO infers atLocation

    cookedWith,
    servedWith,
    wornWith,
}

import grammars: Lang, negationIn;
import std.conv: to;
import std.algorithm.comparison: among;

/** Relation Direction. */
enum RelDir
{
    any,                        /// Any direction wildcard used in Dir-matchers.
    bwd,                        /// Forward.
    fwd                         /// Backward.
}

alias Rank = uint;

@safe @nogc pure nothrow
{
    /** Lower rank means higher relevance (priority). */
    Rank rank(const Rel rel)
    {
        with (Rel)
            switch (rel)
            {
                case synonymFor:
                    return 0;
                case isA:
                    return 1;
                case hypernymOf:
                    return 2;
                case partOf:
                case memberOf:
                    return 3;
                case oppositeOf:
                    return 4;
                default:
                    return Rank.max;
            }
    }

    double relevance(const Rel rel)
    {
        return 0.5;
        with (Rel)
            switch (rel)
            {
                case synonymFor:
                    return 0.95;
                case oppositeOf:
                    return 0.9;
                case isA:
                    return 0.8;
                case hypernymOf:
                    return 0.7;
                case translationOf:
                    return 0.5;
                default:
                    return 0.5;
            }
    }

    /* TODO Used to infer that
       - X and Y are sisters => (hasSister(X,Y) && hasSister(Y,X))
    */
    bool isSymmetric(const Rel rel)
    {
        with (Rel) return rel.among!(relatedTo,
                                     translationOf,
                                     synonymFor,
                                     antonymFor,
                                     contronymFor,
                                     homophoneFor,

                                     reversionOf,
                                     similarSizeTo,
                                     similarTo,
                                     similarAppearanceTo,

                                     hasFriend,
                                     hasTeamMate,
                                     hasEnemy,

                                     hasRelative,
                                     hasFamilyMember,
                                     hasSpouse,
                                     hasSibling,

                                     competesWith,
                                     collaboratesWith,
                                     cookedWith,
                                     servedWith,
                                     physicallyConnectedWith,

                                     mutualProxyFor,

                                     formOfWord,
                                     formOfVerb,
                                     formOfNoun,
                                     formOfAdjective) != 0;
    }

    /** Return true if $(D relation) is a transitive relation that can used to
        inference new relations (knowledge).

        A relation R from A to B is transitive if A >=R=> B and B >=R=> C
        infers A >=R=> C.
    */
    bool isTransitive(const Rel rel)
    {
        with (Rel) return (rel.isSymmetric ||
                           rel.among!(abbreviationFor,
                                      partOf,
                                      isA,
                                      memberOf,
                                      hasA,
                                      atLocation,
                                      hasContext,
                                      locatedNear,
                                      borderedBy,
                                      causes,
                                      hasSubevent,
                                      hasPrerequisite,
                                      hasShape,
                                      hasEmotion) != 0);
    }

    bool oppositeOfInOrder(const Rel a,
                           const Rel b)
    {
        with (Rel) return (a == hasFriend && b == hasEnemy ||
                           a == hypernymOf && b == hyponymOf);
    }
    bool oppositeOf(const Rel a,
                    const Rel b)
    {
        return (oppositeOfInOrder(a, b) ||
                oppositeOfInOrder(b, a));
    }
    alias areOpposites = oppositeOf;

    /** Return true if $(D rel) is a strong.
        TODO Where is strength decided and what purpose does it have?
    */
    bool isStrong(Rel rel)
    {
        with (Rel) return rel.among!(hasProperty,
                                     hasShape,
                                     hasColor,
                                     hasAge,
                                     motivatedByGoal) != 0;
    }

    /** Return true if $(D rel) is a weak.
        TODO Where is strongness decided and what purpose does it have?
    */
    bool isWeak(Rel rel)
    {
        with (Rel) return rel.among!(isA,
                                     locatedNear) != 0;
    }

}

/** Return true if $(D special) is a more specialized relation than $(D general).
    TODO extend to apply specialization in several steps:
    If A specializes B and B specializes C then A specializes C
*/
bool specializes(Rel special, Rel general) @safe @nogc pure nothrow
{
    switch (general) with (Rel)
    {
        /* TODO Use static foreach over all enum members to generate all
         * relevant cases: */
        case relatedTo:   return special != relatedTo;
        case hasRelative: return special == hasFamilyMember;
        case hasFamilyMember: return special.among!(hasSpouse,
                                                    hasSibling,
                                                    hasParent,
                                                    hasChild,
                                                    hasPet) != 0;
        case hasSpouse: return special.among!(hasWife,
                                              hasHusband) != 0;
        case hasSibling: return special.among!(hasBrother,
                                               hasSister) != 0;
        case hasParent: return special.among!(hasFather,
                                              hasMother) != 0;
        case hasChild: return special.among!(hasSon,
                                             hasDaugther) != 0;
        case hasScore: return special.among!(hasLoserScore,
                                             hasWinnerScore) != 0;
        case isA: return !special.among!(isA,
                                         relatedTo) != 0;
        case worksFor: return special.among!(ceoOf,
                                             writesForPublication,
                                             worksInAcademicField) != 0;
        case creates: return special.among!(writes,
                                            develops,
                                            produces) != 0;
        case leaderOf: return special.among!(ceoOf) != 0;
        case plays: return special.among!(playsInstrument) != 0;
        case memberOf: return special.among!(participatesIn,
                                             worksFor,
                                             playsFor,
                                             memberOfEconomicSector,
                                             topMemberOf,
                                             attends,
                                             hasEthnicity) != 0;
        case hasProperty: return special.among!(hasAge,

                                                hasColor,
                                                hasShape,

                                                hasDiameter,
                                                hasArea,
                                                hasLength,
                                                hasHeight,
                                                hasWidth,
                                                hasThickness,
                                                hasWeight,

                                                hasTeamPosition,
                                                hasTournament,
                                                hasCapital,
                                                hasExpert,
                                                hasJobPosition,
                                                hasWebsite,
                                                hasOfficialWebsite,
                                                hasScore, hasLoserScore, hasWinnerScore,
                                                hasLanguage,
                                                hasOrigin,
                                                hasCurrency,
                                                hasEmotion) != 0;
        case derivedFrom: return special.among!(acronymFor,
                                                abbreviationFor,
                                                contractionFor,
                                                emoticonFor) != 0;
        case abbreviationFor: return special.among!(acronymFor,
                                                    contractionFor) != 0;
        case symbolFor: return special.among!(emoticonFor) != 0;
        case atLocation: return special.among!(bornInLocation,
                                               hasCitizenship,
                                               hasResidenceIn,
                                               hasHome,
                                               diedInLocation,
                                               hasOfficeIn,
                                               headquarteredIn,
                                               languageSchoolInCity,
                                               hasTeamPosition,
                                               grownAtLocation,
                                               producedAtLocation,
                                               inRoom) != 0;
        case buys: return special.among!(acquires) != 0;
        case shapes: return special.among!(cutsInto, breaksInto) != 0;
        case desires: return special.among!(eats, buys, acquires) != 0;
        case similarTo: return special.among!(similarSizeTo,
                                              similarAppearanceTo) != 0;
        case injures: return special.among!(selfinjures) != 0;
        case causes: return special.among!(causesSideEffect) != 0;
        case uses: return special.among!(usesLanguage,
                                         usesTool) != 0;
        case physicallyConnectedWith: return special.among!(arisesFrom) != 0;
        case locatedNear: return special.among!(borderedBy) != 0;
        case hasWebsite: return special.among!(hasOfficialWebsite) != 0;
        case hasSubevent: return special.among!(hasFirstSubevent,
                                                hasLastSubevent) != 0;
        case formOfWord: return special.among!(formOfVerb,
                                               participleOfVerb,
                                               formOfNoun,
                                               formOfAdjective) != 0;
        case synonymFor: return special.among!(abbreviationFor,
                                               togetherWritingFor) != 0;
        case instanceHypernymOf: return special.among!(instanceOf,
                                                       hypernymOf) != 0;
        case instanceHyponymOf: return special.among!(instanceOf,
                                                      hyponymOf) != 0;
        default: return special == general;
    }
}

/** Return true if $(D general) is a more general relation than $(D special). */
bool generalizes(T)(T general,
                    T special)
{
    return specializes(special, general);
}

/** Type-Safe Directed Reference to $(D T). */
struct Ref(T)
{
    /** Ix Precision.
        Set this to $(D uint) if we get low on memory.
        Set this to $(D ulong) when number of link nodes exceed Ix.
    */
    alias Ix = uint; // TODO Change this to size_t when we have more Concepts and memory.
    enum nullIx = Ix.max >> 1;

    import bitop_ex: setTopBit, getTopBit, resetTopBit;

    @safe pure:

    // TODO nothrow
    string toString() const { return (ix().to!string ~
                                      `_` ~
                                      dir().to!string); }

    @nogc nothrow:

    this(Ix ix = nullIx, bool reversed = false) in { assert(ix <= nullIx); }
    body
    {
        this._ix = ix;
        if (reversed) { _ix.setTopBit; }
    }

    this(Ref rhs, RelDir dir)
    {
        this._ix = rhs.ix;
        setDir(dir);
    }

    void setDir(RelDir dir)
    {
        final switch (dir)
        {
            case RelDir.bwd: _ix.setTopBit; break;
            case RelDir.fwd: _ix.resetTopBit; break;
            case RelDir.any:
                // TODO give warning: debug writeln(`Cannot use RelDir.any here`);
                break;
        }
    }

    Ref raw() const { return Ref(this, RelDir.fwd); }
    Ref fwd() const { return Ref(this, RelDir.fwd); }
    Ref bwd() const { return Ref(this, RelDir.bwd); }

    static const(Ref) asUndefined() { return Ref(nullIx); }
    bool defined() const { return this.ix != nullIx; }
    auto opCast(U : bool)() const { return defined(); }

    /** Needed for compatibility with IndexedBy. */
    size_t opCast(U : size_t)() const { return this.ix(); }

    // auto opEquals(const Ref y) const
    // {
    //     assert(this.dir == y.dir);
    //     return this.ix == y.ix;
    // }

    hash_t toHash() const @property
    {
        return this.ix;
    }

    auto opCmp(const Ref y) const
    {
        assert(this.dir == y.dir);
        if      (this._ix < y._ix) { return -1; }
        else if (this._ix > y._ix) { return +1; }
        else                       { return 0; }
    }

    /** Get Index. */
    const(Ix) ix() const { Ix ixCopy = _ix; ixCopy.resetTopBit; return ixCopy; }

    /** Get Direction. */
    const(RelDir) dir() const { return _ix.getTopBit ? RelDir.bwd : RelDir.fwd; }
private:
    Ix _ix = nullIx;
}

unittest
{
    alias T = Ref!int;
    T a, b;
    import std.algorithm: swap, sort;
    swap(a, b);
    T[] x;
    x.sort;
}
