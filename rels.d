module rels;

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

    instanceHyponymOf, ///< WordNet.

    mayBeA,

    partOf, /**< A is a part of B. This is the part meronym relation in
               WordNet. /r/PartOf /c/en/gearshift /c/en/car */
    meronym = partOf,

    memberOf, /**< A is a member of B; B is a group that includes A. This is the
                 member meronym relation in WordNet. */

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

    antonymFor, oppositeOf = antonymFor, /**< A and B are opposites in some relevant way, such as being
                opposite ends of a scale, or fundamentally similar things with a
                key difference between them. Counterintuitively, two _concepts
                must be quite similar before people consider them antonyms. This
                is the antonym relation in WordNet as well. /r/Antonym
                /c/en/black /c/en/white; /r/Antonym /c/en/hot /c/en/cold */
    antonym = antonymFor,
    reversionOf,

    retronymFor, differentation = retronymFor, // $(EM acoustic) guitar. https://en.wikipedia.org/wiki/Retronym

    togetherWritingFor,

    abbreviationFor, shorthandFor = abbreviationFor,

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

    generalizes, // TODO Merge with other enumerator?
    specializes, // TODO reversionOf generalizes

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
    marriedIn,
    diedIn,
    diedAtAge,

    chargedWithCrime,

    movedTo, // TODO infers atLocation

    cookedWith,
    servedWith,
    wornWith,
}
