module knet.relations;

import knet.senses: Sense;

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
    hasMeaning,
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
import predicates: of;

/** Relation Direction. */
enum RelDir
{
    any,                        /// Any direction wildcard used in Dir-matchers.
    backward,                   /// Forward.
    forward                     /// Backward.
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
    /* TODO Used to infer that
       - X and Y are sisters => (hasSister(X,Y) && hasSister(Y,X))
    */
    bool isSymmetric(const Rel rel)
    {
        with (Rel) return rel.of(relatedTo,
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
                                 formOfAdjective);
    }

    /** Return true if $(D relation) is a transitive relation that can used to
        inference new relations (knowledge).

        A relation R from A to B is transitive if A >=R=> B and B >=R=> C
        infers A >=R=> C.
    */
    bool isTransitive(const Rel rel)
    {
        with (Rel) return (rel.isSymmetric ||
                           rel.of(abbreviationFor,
                                  shorthandFor,
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
                                  hasEmotion));
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
        with (Rel) return rel.of(hasProperty,
                                 hasShape,
                                 hasColor,
                                 hasAge,
                                 motivatedByGoal);
    }

    /** Return true if $(D rel) is a weak.
        TODO Where is strongness decided and what purpose does it have?
    */
    bool isWeak(Rel rel)
    {
        with (Rel) return rel.of(isA,
                                 locatedNear);
    }

}

/** Convert $(D rel) to Human Language Representation. */
auto toHuman(const Rel rel,
             const RelDir dir,
             const bool negation = false,
             const Lang targetLang = Lang.en, // present statement in this language
             const Lang srcLang = Lang.en, // TODO use
             const Lang dstLang = Lang.en) // TODO use
    @safe pure
{
    string[] words;
    import std.algorithm: array, joiner;

    auto not = negation ? negationIn(targetLang) : null;
    switch (rel) with (Rel) with (Lang)
    {
        case relatedTo:
            switch (targetLang)
            {
                case sv: words = ["är", not, "relaterat till"]; break;
                case en:
                default: words = ["is", not, "related to"]; break;
            }
            break;
        case translationOf:
            switch (targetLang)
            {
                case sv: words = ["kan", not, "översättas till"]; break;
                case en:
                default: words = ["is", not, "translated to"]; break;
            }
            break;
        case reversionOf:
            switch (targetLang)
            {
                case sv: words = ["är", not, "en omvändning av"]; break;
                case en:
                default: words = ["is", not, "a reversion of"]; break;
            }
            break;
        case synonymFor:
            switch (targetLang)
            {
                case sv: words = ["är", not, "synonym med"]; break;
                case en:
                default: words = ["is", not, "a synonym for"]; break;
            }
            break;
        case homophoneFor:
            switch (targetLang)
            {
                case sv: words = ["är", not, "homofon med"]; break;
                case en:
                default: words = ["is", not, "a homophone for"]; break;
            }
            break;
        case obsolescentFor:
            switch (targetLang)
            {
                case sv: words = ["är", not, "ålderdomlig synonym med"]; break;
                case en:
                default: words = ["is", not, "an obsolescent word for"]; break;
            }
            break;
        case antonymFor:
            switch (targetLang)
            {
                case sv: words = ["är", not, "motsatsen till"]; break;
                case en:
                default: words = ["is", not, "the opposite of"]; break;
            }
            break;
        case similarSizeTo:
            switch (targetLang)
            {
                case sv: words = ["är", not, "lika stor som"]; break;
                case en:
                default: words = ["is", not, "similar in size to"]; break;
            }
            break;
        case similarTo:
            switch (targetLang)
            {
                case sv: words = ["är", not, "likvärdig med"]; break;
                case en:
                default: words = ["is", not, "similar to"]; break;
            }
            break;
        case looksLike:
            switch (targetLang)
            {
                case sv: words = ["ser", not, "ut som"]; break;
                case en:
                default: words = ["does", not, "look like"]; break;
            }
            break;
        case isA:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["är", not, "en"]; break;
                    case de: words = ["ist", not, "ein"]; break;
                    case en:
                    default: words = ["is", not, "a"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["kan", not, "vara en"]; break;
                    case de: words = ["can", not, "sein ein"]; break;
                    case en:
                    default: words = ["can", not, "be a"]; break;
                }
            }
            break;
        case mayBeA:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["kan", not, "vara en"]; break;
                    case en:
                    default: words = ["may", not, "be a"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["kan", not, "vara en"]; break;
                    case en:
                    default: words = ["may", not, "be a"]; break;
                }
            }
            break;
        case partOf:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["är", not, "en del av"]; break;
                    case en:
                    default: words = ["is", not, "a part of"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["har", not, "del"]; break;
                    case en:
                    default: words = ["does", not, "have art"]; break;
                }
            }
            break;
        case madeOf:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["är", not, "gjord av"]; break;
                    case en:
                    default: words = ["is", not, "made of"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["används", not, "till att göra"]; break;
                    case en:
                    default: words = [not, "used to make"]; break;
                }
            }
            break;
        case madeBy:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["är", not, "skapad av"]; break;
                    case en:
                    default: words = ["is", not, "made of"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["används", not, "till att skapa"]; break;
                    case en:
                    default: words = [not, "used to make"]; break;
                }
            }
            break;
        case memberOf:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["är", not, "en medlem av"]; break;
                    case de: words = ["ist", not, "ein Mitglied von"]; break;
                    case en:
                    default: words = ["is", not, "a member of"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["har", not, "medlem"]; break;
                    case de: words = ["hat", not, "Mitgleid"]; break;
                    case en:
                    default: words = ["have", not, "member"]; break;
                }
            }
            break;
        case topMemberOf:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["är", not, "huvudmedlem av"]; break;
                    case en:
                    default: words = ["is", not, "the top member of"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["har", not, "toppmedlem"]; break;
                    case en:
                    default: words = ["have", not, "top member"]; break;
                }
            }
            break;
        case participatesIn:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["deltog", not, "i"]; break;
                    case en:
                    default: words = ["participate", not, "in"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["har", not, "deltagare"]; break;
                    case en:
                    default: words = ["have", not, "participant"]; break;
                }
            }
            break;
        case worksFor:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["arbetar", not, "för"]; break;
                    case de: words = ["arbeitet", not, "für"]; break;
                    case en:
                    default: words = ["works", not, "for"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["har", not, "arbetare"]; break;
                    case de: words = ["hat", not, "Arbeiter"]; break;
                    case en:
                    default: words = ["has", not, "employee"]; break;
                }
            }
            break;
        case playsIn:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["spelar", not, "i"]; break;
                    case de: words = ["spielt", not, "in"]; break;
                    case en:
                    default: words = ["plays", not, "in"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["har", not, "spelare"]; break;
                    case de: words = ["hat", not, "Spieler"]; break;
                    case en:
                    default: words = ["have", not, "player"]; break;
                }
            }
            break;
        case plays:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["spelar", not]; break;
                    case de: words = ["spielt", not]; break;
                    case en:
                    default: words = ["plays", not]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["spelas", not, "av"]; break;
                    case en:
                    default: words = ["played", not, "by"]; break;
                }
            }
            break;
        case contributesTo:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["bidrar", not, "till"]; break;
                    case en:
                    default: words = ["contributes", not, "to"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["har", not, "bidragare"]; break;
                    case en:
                    default: words = ["has", not, "contributor"]; break;
                }
            }
            break;
        case leaderOf:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["leder", not]; break;
                    case en:
                    default: words = ["leads", not]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["leds", not, "av"]; break;
                    case en:
                    default: words = ["is lead", not, "by"]; break;
                }
            }
            break;
        case coaches:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["coachar", not]; break;
                    case en:
                    default: words = ["does", not, "coache"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["coachad", not, "av"]; break;
                    case en:
                    default: words = ["is", not, "coached", "by"]; break;
                }
            }
            break;
        case represents:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["representerar", not]; break;
                    case en:
                    default: words = ["does", not, "represents"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["representeras", not, "av"]; break;
                    case en:
                    default: words = ["is represented", not, "by"]; break;
                }
            }
            break;
        case ceoOf:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["är", not, "VD för"]; break;
                    case en:
                    default: words = ["is", not, "CEO of"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["is", not, "led by"]; break;
                    case en:
                    default: words = ["leds", not, "av"]; break;
                }
            }
            break;
        case hasA:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["har", not, "en"]; break;
                    case de: words = ["hat", not, "ein"]; break;
                    case en:
                    default: words = ["has", not, "a"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["tillhör", not]; break;
                    case en:
                    default: words = ["does", not, "belongs to"]; break;
                }
            }
            break;
        case atLocation:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["kan hittas", not, "vid"]; break;
                    case en:
                    default: words = ["can", not, "be found at location"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["kan", not, "innehålla"]; break;
                    case en:
                    default: words = ["may", not, "contain"]; break;
                }
            }
            break;
        case causes:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["leder", not, "till"]; break;
                    case en:
                    default: words = ["does", not, "cause"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["kan", not, "orsakas av"]; break;
                    case en:
                    default: words = ["can", not, "be caused by"]; break;
                }
            }
            break;
        case creates:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["skapar", not]; break;
                    case de: words = ["schafft", not]; break;
                    case en:
                    default: words = ["does", not, "create"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["kan", not, "skapas av"]; break;
                    case en:
                    default: words = ["can", not, "be created by"]; break;
                }
            }
            break;
        case foundedIn:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["grundades", not]; break;
                    case en:
                    default: words = ["was", not, "founded"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["grundades", not]; break;
                    case en:
                    default: words = [not, "founded"]; break;
                }
            }
            break;
        case eats:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["äter", not]; break;
                    case en:
                    default: words = ["does", not, "eat"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["kan", not, "ätas av"]; break;
                    case en:
                    default: words = ["can", not, "be eaten by"]; break;
                }
            }
            break;
        case atTime:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["inträffar", not, "vid tidpunkt"]; break;
                    case en:
                    default: words = [not, "at time"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["har", not, "händelse"]; break;
                    case en:
                    default: words = ["has", not, "event"]; break;
                }
            }
            break;
        case capableOf:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["är ", not, "kapabel till"]; break;
                    case en:
                    default: words = ["is", not, "capable of"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["kan", not, "orsakas av"]; break;
                    case en:
                    default: words = ["can", not, "be caused by"]; break;
                }
            }
            break;
        case definedAs:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["definieras", not, "som"]; break;
                    case en:
                    default: words = [not, "defined as"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["kan", not, "definiera"]; break;
                    case en:
                    default: words = ["can", not, "define"]; break;
                }
            }
            break;
        case derivedFrom:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["härleds", not, "från"]; break;
                    case en:
                    default: words = ["is", not, "derived from"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["härleder", not]; break;
                    case en:
                    default: words = ["does", not, "derive"]; break;
                }
            }
            break;
        case compoundDerivedFrom:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["härleds sammansatt", not, "från"]; break;
                    case en:
                    default: words = ["is", not, "compound derived from"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["härleder sammansatt", not]; break;
                    case en:
                    default: words = ["does", not, "compound derive"]; break;
                }
            }
            break;
        case etymologicallyDerivedFrom:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["härleds", not, "etymologiskt från"]; break;
                    case en:
                    default: words = ["is", not, "etymologically derived from"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["härleder etymologiskt", not]; break;
                    case en:
                    default: words = ["does", not, "etymologically derive"]; break;
                }
            }
            break;
        case hasProperty:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["har", not, "egenskap"]; break;
                    case en:
                    default: words = ["has", not, "property"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["är", not, "egenskap av"]; break;
                    case en:
                    default: words = ["is", not, "property of"]; break;
                }
            }
            break;
        case hasAttribute:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["har", not, "attribut"]; break;
                    case en:
                    default: words = ["has", not, "attribute"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["är", not, "attribut av"]; break;
                    case en:
                    default: words = ["is", not, "attribute of"]; break;
                }
            }
            break;
        case hasEmotion:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["har", not, "känsla"]; break;
                    case en:
                    default: words = ["has", not, "emotion"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["kan", not, "uttryckas med"]; break;
                    case en:
                    default: words = ["can", not, "be expressed by"]; break;
                }
            }
            break;
        case hasBrother:
            switch (targetLang)
            {
                case sv: words = ["har", not, "bror"]; break;
                case de: words = ["hat", not, "Bruder"]; break;
                case en:
                default: words = ["has", not, "brother"]; break;
            }
            break;
        case hasSister:
            switch (targetLang)
            {
                case sv: words = ["har", not, "syster"]; break;
                case de: words = ["hat", not, "Schwester"]; break;
                case en:
                default: words = ["has", not, "sister"]; break;
            }
            break;
        case hasFamilyMember:
            switch (targetLang)
            {
                case sv: words = ["har", not, "familjemedlem"]; break;
                case en:
                default: words = ["does", not, "have family member"]; break;
            }
            break;
        case hasSibling:
            switch (targetLang)
            {
                case sv: words = ["har", not, "syskon"]; break;
                case en:
                default: words = ["does", not, "have sibling"]; break;
            }
            break;
        case hasSpouse:
            switch (targetLang)
            {
                case sv: words = ["har", not, "gemål"]; break;
                case en:
                default: words = ["has", not, "spouse"]; break;
            }
            break;
        case hasParent:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["har", not, "förälder"]; break;
                    case en:
                    default: words = ["has", not, "parent"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["är", not, "förälder till"]; break;
                    case en:
                    default: words = ["is", not, "parent of"]; break;
                }
            }
            break;
        case hasChild:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["har", not, "barn"]; break;
                    case en:
                    default: words = ["has", not, "child"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["är", not, "barn till"]; break;
                    case en:
                    default: words = ["is", not, "child of"]; break;
                }
            }
            break;
        case hasHusband:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["har", not, "make"]; break;
                    case en:
                    default: words = ["has", not, "husband"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["är", not, "make till"]; break;
                    case en:
                    default: words = ["is", not, "husband of"]; break;
                }
            }
            break;
        case hasWife:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["har", not, "maka"]; break;
                    case en:
                    default: words = ["has", not, "wife"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["är", not, "maka till"]; break;
                    case en:
                    default: words = ["is", not, "wife of"]; break;
                }
            }
            break;
        case hasOfficeIn:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["har", not, "kontor i"]; break;
                    case en:
                    default: words = ["has", not, "office in"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["har", not, "ett kontor för"]; break;
                    case en:
                    default: words = ["does", not, "have an office for"]; break;
                }
            }
            break;
        case causesDesire:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["skapar", not, "begär"]; break;
                    case en:
                    default: words = ["does", not, "cause", "desire"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = [not, "begär skapad av"]; break;
                    case en:
                    default: words = ["desire", not, "caused by"]; break;
                }
            }
            break;
        case proxyFor:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["är", not, "en ställföreträdare för"]; break;
                    case en:
                    default: words = ["is ", not, "a mutual proxy for"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["har", not, "ställföreträdare"]; break;
                    case en:
                    default: words = ["does", not, "have proxy"]; break;
                }
            }
            break;
        case instanceOf:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["är", not, "en instans av"]; break;
                    case en:
                    default: words = ["is", not, "an instance of"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["har", not, "instans"]; break;
                    case en:
                    default: words = ["does", not, "have instance"]; break;
                }
            }
            break;
        case decreasesRiskOf:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["minskar", not, "risken av"]; break;
                    case en:
                    default: words = ["does ", not, "decrease risk of"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["blir", not, "mindre sannolik av"]; break;
                    case en:
                    default: words = ["does", not, "become less likely by"]; break;
                }
            }
            break;
        case desires:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["önskar", not]; break;
                    case en:
                    default: words = ["does", not, "desire"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["önskas", not, "av"]; break;
                    case en:
                    default: words = ["is", not, "desired by"]; break;
                }
            }
            break;
        case uses:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["använder", not]; break;
                    case en:
                    default: words = ["does", not, "use"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["används", not, "av"]; break;
                    case en:
                    default: words = ["is", not, "used by"]; break;
                }
            }
            break;
        case controls:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["kontrollerar", not]; break;
                    case en:
                    default: words = ["does", not, "control"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["kontrolleras", not, "av"]; break;
                    case en:
                    default: words = ["is", not, "controlled by"]; break;
                }
            }
            break;
        case treats:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["hanteras", not]; break;
                    case en:
                    default: words = ["does", not, "treat"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["hanteras", not, "av"]; break;
                    case en:
                    default: words = ["is", not, "treated by"]; break;
                }
            }
            break;
        case togetherWritingFor:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["är", not, "en ihopskrivning för"]; break;
                    case en:
                    default: words = ["is", not, "a together writing for"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["har", not, "ihopskrivning"]; break;
                    case en:
                    default: words = ["does", not, "have together writing"]; break;
                }
            }
            break;
        case symbolFor:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["är", not, "en symbol för"]; break;
                    case en:
                    default: words = ["is", not, "a symbol for"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["har", not, "symbolen"]; break;
                    case en:
                    default: words = ["does", not, "have symbol"]; break;
                }
            }
            break;
        case abbreviationFor:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["är", not, "en förkortning för"]; break;
                    case en:
                    default: words = ["is", not, "an abbreviation for"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["har", not, "förkortning"]; break;
                    case en:
                    default: words = ["does", not, "have abbreviation"]; break;
                }
            }
            break;
        case contractionFor:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["är", not, "en sammandragning av"]; break;
                    case en:
                    default: words = ["is", not, "a contraction for"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["har", not, "sammandragningen"]; break;
                    case en:
                    default: words = ["does", not, "have contraction"]; break;
                }
            }
            break;
        case acronymFor:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["är", not, "en acronym för"]; break;
                    case en:
                    default: words = ["is", not, "an acronym for"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["har", not, "acronym"]; break;
                    case en:
                    default: words = ["does", not, "have acronym"]; break;
                }
            }
            break;
        case emoticonFor:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["är", not, "en emotikon för"]; break;
                    case en:
                    default: words = ["is", not, "an emoticon for"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["har", not, "emotikon"]; break;
                    case en:
                    default: words = ["does", not, "have emoticon"]; break;
                }
            }
            break;
        case playsInstrument:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["spelar", not, "instrument"]; break;
                    case en:
                    default: words = ["does", not, "play instrument"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["är", not, "ett instrument som spelas av"]; break;
                    case en:
                    default: words = ["is", not, "an instrument played by"]; break;
                }
            }
            break;
        case hasNameDay:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["har", not, "namnsdag"]; break;
                    case en:
                    default: words = ["does", not, "have name day"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["är", not, "namnsdag för"]; break;
                    case en:
                    default: words = ["is", not, "name day for"]; break;
                }
            }
            break;
        case hasOrigin:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["har", not, "ursprung"]; break;
                    case en:
                    default: words = ["does", not, "have origin"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["är", not, "ursprung för"]; break;
                    case en:
                    default: words = ["is", not, "origin for"]; break;
                }
            }
            break;
        case hasMeaning:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["har", not, "betydelsen"]; break;
                    case en:
                    default: words = ["does", not, "have meaning"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["kan", not, "beskrivas av"]; break;
                    case en:
                    default: words = ["can", not, "be described by"]; break;
                }
            }
            break;
        // case hasPronounciation:
        //     if (dir == RelDir.forward)
        //     {
        //         switch (targetLang)
        //         {
        //             case sv: words = ["utalas", not]; break;
        //             case en:
        //             default: words = ["does", not, "have pronouncation"]; break;
        //         }
        //     }
        //     else
        //     {
        //         switch (targetLang)
        //         {
        //             case sv: words = ["kan", not, "vara uttal av"]; break;
        //             case en:
        //             default: words = ["can", not, "be pronouncation of"]; break;
        //         }
        //     }
        //     break;
        case slangFor:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["är", not, "slang för"]; break;
                    case en:
                    default: words = ["is", not, "slang for"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["är", not, "en beskrivning av slang"]; break;
                    case en:
                    default: words = ["is", not, "an explanation of the slang"]; break;
                }
            }
            break;
        case idiomFor:
            if (dir == RelDir.forward)
            {
                switch (targetLang)
                {
                    case sv: words = ["är", not, "idiom för"]; break;
                    case en:
                    default: words = ["is", not, "an idiom for"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["är", not, "en beskrivning av idiomet"]; break;
                    case en:
                    default: words = ["is", not, "an explanation of the idiom"]; break;
                }
            }
            break;
        case mutualProxyFor:
            switch (targetLang)
            {
                case sv: words = ["är", not, "en ömsesidig ställföreträdare för"]; break;
                case en:
                default: words = ["is ", not, "a mutual proxy for"]; break;
            }
            break;
        case formOfWord:
            switch (targetLang)
            {
                case sv: words = ["har", not, "ord form"]; break;
                case en:
                default: words = ["has ", not, "word form"]; break;
            }
            break;
        case formOfVerb:
            switch (targetLang)
            {
                case sv: words = ["har", not, "verb form"]; break;
                case en:
                default: words = ["has", not, "verb form"]; break;
            }
            break;
        case formOfNoun:
            switch (targetLang)
            {
                case sv: words = ["har", not, "substantiv form"]; break;
                case en:
                default: words = ["has", not, "noun form"]; break;
            }
            break;
        case formOfAdjective:
            switch (targetLang)
            {
                case sv: words = ["har", not, "adjektiv form"]; break;
                case en:
                default: words = ["has", not, "adjective form"]; break;
            }
            break;
        case cookedWith:
            switch (targetLang)
            {
                case sv: words = ["kan", not, "lagas med"]; break;
                case en:
                default: words = ["can be", not, "cooked with"]; break;
            }
            break;
        case servedWith:
            switch (targetLang)
            {
                case sv: words = ["kan", not, "serveras med"]; break;
                case en:
                default: words = ["can be", not, "served with"]; break;
            }
            break;
        case competesWith:
            switch (targetLang)
            {
                case sv: words = ["tävlar", not, "med"]; break;
                case en:
                default: words = ["does", not, "compete with"]; break;
            }
            break;
        case collaboratesWith:
            switch (targetLang)
            {
                case sv: words = ["samarbetar", not, "med"]; break;
                case en:
                default: words = ["does", not, "collaborate with"]; break;
            }
            break;
        default:
            import std.conv: to;
            const ordered = !rel.isSymmetric;
            const prefix = (ordered && dir == RelDir.backward ? `<` : ``);
            const suffix = (ordered && dir == RelDir.forward ? `>` : ``);
            words = [prefix ~ `-` ~ rel.to!string ~ `-` ~ suffix];
            break;
    }

    import std.algorithm.iteration: filter;
    return words.filter!(word => word !is null) // strip not
                .joiner(" "); // add space
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
        case hasFamilyMember: return special.of(hasSpouse,
                                                hasSibling,
                                                hasParent,
                                                hasChild,
                                                hasPet);
        case hasSpouse: return special.of(hasWife,
                                          hasHusband);
        case hasSibling: return special.of(hasBrother,
                                           hasSister);
        case hasParent: return special.of(hasFather,
                                          hasMother);
        case hasChild: return special.of(hasSon,
                                         hasDaugther);
        case hasScore: return special.of(hasLoserScore,
                                         hasWinnerScore);
        case isA: return !special.of(isA,
                                     relatedTo);
        case worksFor: return special.of(ceoOf,
                                         writesForPublication,
                                         worksInAcademicField);
        case creates: return special.of(writes,
                                        develops,
                                        produces);
        case leaderOf: return special.of(ceoOf);
        case plays: return special.of(playsInstrument);
        case memberOf: return special.of(participatesIn,
                                         worksFor,
                                         playsFor,
                                         memberOfEconomicSector,
                                         topMemberOf,
                                         attends,
                                         hasEthnicity);
        case hasProperty: return special.of(hasAge,

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
                                            hasEmotion);
        case derivedFrom: return special.of(acronymFor,
                                            abbreviationFor,
                                            contractionFor,
                                            emoticonFor);
        case abbreviationFor: return special.of(acronymFor, contractionFor);
        case symbolFor: return special.of(emoticonFor);
        case atLocation: return special.of(bornInLocation,
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
                                           inRoom);
        case buys: return special.of(acquires);
        case shapes: return special.of(cutsInto, breaksInto);
        case desires: return special.of(eats, buys, acquires);
        case similarTo: return special.of(similarSizeTo,
                                          similarAppearanceTo);
        case injures: return special.of(selfinjures);
        case causes: return special.of(causesSideEffect);
        case uses: return special.of(usesLanguage,
                                     usesTool);
        case physicallyConnectedWith: return special.of(arisesFrom);
        case locatedNear: return special.of(borderedBy);
        case hasWebsite: return special.of(hasOfficialWebsite);
        case hasSubevent: return special.of(hasFirstSubevent,
                                            hasLastSubevent);
        case formOfWord: return special.of(formOfVerb,
                                         participleOfVerb,
                                         formOfNoun,
                                         formOfAdjective);
        case synonymFor: return special.of(abbreviationFor,
                                           togetherWritingFor,
                                           shorthandFor);
        case instanceHypernymOf: return special.of(instanceOf,
                                                   hypernymOf);
        case instanceHyponymOf: return special.of(instanceOf,
                                                  hyponymOf);
        default: return special == general;
    }
}

/** Return true if $(D general) is a more general relation than $(D special). */
bool generalizes(T)(T general,
                    T special)
{
    return specializes(special, general);
}

/** Check if $(D rel) infers Senses. */
Sense infersSense(Rel rel) @safe @nogc pure nothrow
{
    switch (rel) with (Rel) with (Sense)
    {
        case atLocation: return noun;
        default: return Sense.unknown;
    }
}

/** Check if $(D rel) propagates Sense(s). */
bool propagatesSense(Rel rel) @safe @nogc pure nothrow
{
    with (Rel) return rel.of(translationOf,
                             synonymFor,
                             antonymFor);
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
    string toString() const { return (ix().to!string ~
                                      `_` ~
                                      dir().to!string); }

    @nogc nothrow:

    this(Ix ix = nullIx, bool reversion = false) in { assert(ix <= nullIx); }
    body
    {
        this._ix = ix;
        if (reversion) { _ix.setTopBit; }
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
            case RelDir.backward: _ix.setTopBit; break;
            case RelDir.forward: _ix.resetTopBit; break;
            case RelDir.any:
                // TODO give warning: debug writeln(`Cannot use RelDir.any here`);
                break;
        }
    }

    Ref raw() const { return Ref(this, RelDir.forward); }
    Ref forward() const { return Ref(this, RelDir.forward); }
    Ref backward() const { return Ref(this, RelDir.backward); }

    static const(Ref) asUndefined() { return Ref(nullIx); }
    bool defined() const { return this.ix != nullIx; }
    auto opCast(U : bool)() const { return defined(); }

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
        if      (this.ix < y.ix) { return -1; }
        else if (this.ix > y.ix) { return +1; }
        else                     { return 0; }
    }

    /** Get Index. */
    const(Ix) ix() const { Ix ixCopy = _ix; ixCopy.resetTopBit; return ixCopy; }

    /** Get Direction. */
    const(RelDir) dir() const { return _ix.getTopBit ? RelDir.backward : RelDir.forward; }
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
