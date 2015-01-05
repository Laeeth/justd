module krels;

import grammars: Lang, negationIn;
import std.conv: to;
import predicates: of;

/** Conceptnet Semantic Relation Type Code.
    See also: https://github.com/commonsense/conceptnet5/wiki/Relations
*/
enum Rel:ubyte
{
    relatedTo, /* The most general relation. There is some positive relationship
                * between A and B, but ConceptNet can't determine what that * relationship
                is based on the data. This was called * "ConceptuallyRelatedTo" in
                ConceptNet 2 through 4.  */
    any = relatedTo,

    isA, /* A is a subtype or a specific instance of B; every A is a B. (We do
          * not make the type-token distinction, because people don't usually
          * make that distinction.) This is the hyponym relation in
          * WordNet. /r/IsA /c/en/car /c/en/vehicle ; /r/IsA /c/en/chicago
          * /c/en/city */
    mayBeA,

    partOf, /* A is a part of B. This is the part meronym relation in
               WordNet. /r/PartOf /c/en/gearshift /c/en/car */

    memberOf, /* A is a member of B; B is a group that includes A. This is the
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

    hasA, /* B belongs to A, either as an inherent part or due to a social
             construct of possession. HasA is often the reverse of PartOf. /r/HasA
             /c/en/bird /c/en/wing ; /r/HasA /c/en/pen /c/en/ink */

    uses, /* reverse of usedFor: A is used for B; the purpose of A is B. /r/UsedFor /c/en/bridge
                /c/en/cross_water */
    usesLanguage,
    usesTool,

    capableOf, /* Something that A can typically do is B. /r/CapableOf
                  /c/en/knife /c/en/cut */

    // or locatedNear?
    atLocation, /* A is a typical location for B, or A is the inherent location
                   of B. Some instances of this would be considered meronyms in
                   WordNet. /r/AtLocation /c/en/butter /c/en/refrigerator; /r/AtLocation
                   /c/en/boston /c/en/massachusetts */
    hasCitizenship, livesIn = hasCitizenship,
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

    locatedNear,                // TODO or AtLocation?
    borderedBy,

    controls,

    causes, /* A and B are events, and it is typical for A to cause B. */
    entails = causes, /* TODO same as causes? */
    leadsTo = causes,
    causesSideEffect,

    decreasesRiskOf,
    treats,

    hasSubevent, /* A and B are events, and B happens as a subevent of A. */
    hasFirstSubevent, /* A is an event that begins with subevent B. */
    hasLastSubevent, /* A is an event that concludes with subevent B. */

    hasPrerequisite, /* In order for A to happen, B needs to happen; B is a
                        dependency of A. /r/HasPrerequisite/ /c/en/drive/ /c/en/get_in_car/ */

    beganAtTime,
    endedAtTime,

    beganBefore,
    beganAfter,
    endedBefore,
    endedAfter,

    hasProperty, /* A has B as a property; A can be described as
                    B. /r/HasProperty /c/en/ice /c/en/solid
                    See also: https://english.stackexchange.com/questions/150529/what-is-the-difference-between-property-and-attribute
                    */
    hasAttribute = hasProperty,
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
    hasCurrency,

    hasEmotion, // TODO remove this and use "love" isA "emotion"?

    motivatedByGoal, /* Someone does A because they want result B; A is a step
                        toward accomplishing the goal B. */
    obstructedBy, /* A is a goal that can be prevented by B; B is an obstacle in
                     the way of A. */

    causesDesire,

    desires, /* A is a conscious entity that typically wants B. Many assertions
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

    creates, /* B is a process that creates A. /r/CreatedBy /c/en/cake
                /c/en/bake */
    develops,
    produces,
    writes,

    receivesAction,

    shorthandFor,

    synonymFor, /* A and B have very similar meanings. This is the synonym relation
                in WordNet as well. */
    synonym = synonymFor,

    antonymFor, oppositeOf = antonymFor, /* A and B are opposites in some relevant way, such as being
                opposite ends of a scale, or fundamentally similar things with a
                key difference between them. Counterintuitively, two _concepts
                must be quite similar before people consider them antonyms. This
                is the antonym relation in WordNet as well. /r/Antonym
                /c/en/black /c/en/white; /r/Antonym /c/en/hot /c/en/cold */
    antonym = antonymFor,
    reversionOf,

    retronymFor, differentation = retronymFor, // $(EM acoustic) guitar. https://en.wikipedia.org/wiki/Retronym

    abbreviationFor,
    acronymFor,
    emoticonFor,

    physicallyConnectedWith,
    arisesFrom,
    emptiesInto,

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

    wordForm,
    verbForm,
    nounForm,
    adjectiveForm,

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

/** Relation Direction. */
enum RelDir
{
    any,                        /// Any direction wildcard used in Dir-matchers.
    backward,                   /// Forward.
    forward                     /// Backward.
}

/** Convert $(D rel) to Human Language Representation. */
auto toHuman(const Rel rel,
             const RelDir dir,
             const bool negation = false,
             const Lang lang = Lang.en)
    @safe pure
{
    string[] words;
    import std.algorithm: array, filter, joiner;

    with (Rel)
    {
        with (Lang)
        {
            auto not = negation ? negationIn(lang) : null;
            switch (rel)
            {
                case relatedTo:
                    switch (lang)
                    {
                        case sv: words = ["är", not, "relaterat till"]; break;
                        case en:
                        default: words = ["is", not, "related to"]; break;
                    }
                    break;
                case translationOf:
                    switch (lang)
                    {
                        case sv: words = ["kan", not, "översättas till"]; break;
                        case en:
                        default: words = ["is", not, "translated to"]; break;
                    }
                    break;
                case reversionOf:
                    switch (lang)
                    {
                        case sv: words = ["är", not, "en omvändning av"]; break;
                        case en:
                        default: words = ["is", not, "a reversion of"]; break;
                    }
                    break;
                case synonymFor:
                    switch (lang)
                    {
                        case sv: words = ["är", not, "synonym med"]; break;
                        case en:
                        default: words = ["is", not, "a synonym for"]; break;
                    }
                    break;
                case antonymFor:
                    switch (lang)
                    {
                        case sv: words = ["är", not, "motsatsen till"]; break;
                        case en:
                        default: words = ["is", not, "the opposite of"]; break;
                    }
                    break;
                case similarSizeTo:
                    switch (lang)
                    {
                        case sv: words = ["är", not, "lika stor som"]; break;
                        case en:
                        default: words = ["is", not, "similar in size to"]; break;
                    }
                    break;
                case similarTo:
                    switch (lang)
                    {
                        case sv: words = ["är", not, "likvärdig med"]; break;
                        case en:
                        default: words = ["is", not, "similar to"]; break;
                    }
                    break;
                case looksLike:
                    switch (lang)
                    {
                        case sv: words = ["ser", not, "ut som"]; break;
                        case en:
                        default: words = ["does", not, "look like"]; break;
                    }
                    break;
                case isA:
                    if (dir == RelDir.forward)
                    {
                        switch (lang)
                        {
                            case sv: words = ["är", not, "en"]; break;
                            case de: words = ["ist", not, "ein"]; break;
                            case en:
                            default: words = ["is", not, "a"]; break;
                        }
                    }
                    else
                    {
                        switch (lang)
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
                        switch (lang)
                        {
                            case sv: words = ["kan", not, "vara en"]; break;
                            case en:
                            default: words = ["may", not, "be a"]; break;
                        }
                    }
                    else
                    {
                        switch (lang)
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
                        switch (lang)
                        {
                            case sv: words = ["är", not, "en del av"]; break;
                            case en:
                            default: words = ["is", not, "a part of"]; break;
                        }
                    }
                    else
                    {
                        switch (lang)
                        {
                            case sv: words = ["innehåller", not]; break;
                            case de: words = ["enthält", not]; break;
                            case en:
                            default: words = [not, "contains"]; break;
                        }
                    }
                    break;
                case madeOf:
                    if (dir == RelDir.forward)
                    {
                        switch (lang)
                        {
                            case sv: words = ["är", not, "gjord av"]; break;
                            case en:
                            default: words = ["is", not, "made of"]; break;
                        }
                    }
                    else
                    {
                        switch (lang)
                        {
                            case sv: words = ["används", not, "till att göra"]; break;
                            case en:
                            default: words = [not, "used to make"]; break;
                        }
                    }
                    break;
                case memberOf:
                    if (dir == RelDir.forward)
                    {
                        switch (lang)
                        {
                            case sv: words = ["är", not, "en medlem av"]; break;
                            case de: words = ["ist", not, "ein Mitglied von"]; break;
                            case en:
                            default: words = ["is", not, "a member of"]; break;
                        }
                    }
                    else
                    {
                        switch (lang)
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
                        switch (lang)
                        {
                            case sv: words = ["är", not, "huvudmedlem av"]; break;
                            case en:
                            default: words = ["is", not, "the top member of"]; break;
                        }
                    }
                    else
                    {
                        switch (lang)
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
                        switch (lang)
                        {
                            case sv: words = ["deltog", not, "i"]; break;
                            case en:
                            default: words = ["participate", not, "in"]; break;
                        }
                    }
                    else
                    {
                        switch (lang)
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
                        switch (lang)
                        {
                            case sv: words = ["arbetar", not, "för"]; break;
                            case de: words = ["arbeitet", not, "für"]; break;
                            case en:
                            default: words = ["works", not, "for"]; break;
                        }
                    }
                    else
                    {
                        switch (lang)
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
                        switch (lang)
                        {
                            case sv: words = ["spelar", not, "i"]; break;
                            case de: words = ["spielt", not, "in"]; break;
                            case en:
                            default: words = ["plays", not, "in"]; break;
                        }
                    }
                    else
                    {
                        switch (lang)
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
                        switch (lang)
                        {
                            case sv: words = ["spelar", not]; break;
                            case de: words = ["spielt", not]; break;
                            case en:
                            default: words = ["plays", not]; break;
                        }
                    }
                    else
                    {
                        switch (lang)
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
                        switch (lang)
                        {
                            case sv: words = ["bidrar", not, "till"]; break;
                            case en:
                            default: words = ["contributes", not, "to"]; break;
                        }
                    }
                    else
                    {
                        switch (lang)
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
                        switch (lang)
                        {
                            case sv: words = ["leder", not]; break;
                            case en:
                            default: words = ["leads", not]; break;
                        }
                    }
                    else
                    {
                        switch (lang)
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
                        switch (lang)
                        {
                            case sv: words = ["coachar", not]; break;
                            case en:
                            default: words = ["does", not, "coache"]; break;
                        }
                    }
                    else
                    {
                        switch (lang)
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
                        switch (lang)
                        {
                            case sv: words = ["representerar", not]; break;
                            case en:
                            default: words = ["does", not, "represents"]; break;
                        }
                    }
                    else
                    {
                        switch (lang)
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
                        switch (lang)
                        {
                            case sv: words = ["är", not, "VD för"]; break;
                            case en:
                            default: words = ["is", not, "CEO of"]; break;
                        }
                    }
                    else
                    {
                        switch (lang)
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
                        switch (lang)
                        {
                            case sv: words = ["har", not, "en"]; break;
                            case de: words = ["hat", not, "ein"]; break;
                            case en:
                            default: words = ["has", not, "a"]; break;
                        }
                    }
                    else
                    {
                        switch (lang)
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
                        switch (lang)
                        {
                            case sv: words = ["kan hittas", not, "vid"]; break;
                            case en:
                            default: words = ["can", not, "be found at location"]; break;
                        }
                    }
                    else
                    {
                        switch (lang)
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
                        switch (lang)
                        {
                            case sv: words = ["leder", not, "till"]; break;
                            case en:
                            default: words = ["does", not, "cause"]; break;
                        }
                    }
                    else
                    {
                        switch (lang)
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
                        switch (lang)
                        {
                            case sv: words = ["skapar", not]; break;
                            case de: words = ["schafft", not]; break;
                            case en:
                            default: words = ["does", not, "create"]; break;
                        }
                    }
                    else
                    {
                        switch (lang)
                        {
                            case sv: words = ["kan", not, "skapas av"]; break;
                            case en:
                            default: words = ["can", not, "be created by"]; break;
                        }
                    }
                    break;
                case generalizes:
                    if (dir == RelDir.forward)
                    {
                        switch (lang)
                        {
                            case sv: words = ["generaliserar", not]; break;
                            case en:
                            default: words = ["does", not, "generalize"]; break;
                        }
                    }
                    else
                    {
                        switch (lang)
                        {
                            case sv: words = ["kan", not, "generaliseras av"]; break;
                            case en:
                            default: words = ["can", not, "be generalized by"]; break;
                        }
                    }
                    break;
                case specializes:
                    if (dir == RelDir.forward)
                    {
                        switch (lang)
                        {
                            case sv: words = ["specialiserar", not]; break;
                            case en:
                            default: words = ["does", not, "specialize"]; break;
                        }
                    }
                    else
                    {
                        switch (lang)
                        {
                            case sv: words = ["kan", not, "specialiseras av"]; break;
                            case en:
                            default: words = ["can", not, "be specialized by"]; break;
                        }
                    }
                    break;
                case eats:
                    if (dir == RelDir.forward)
                    {
                        switch (lang)
                        {
                            case sv: words = ["äter", not]; break;
                            case en:
                            default: words = ["does", not, "eat"]; break;
                        }
                    }
                    else
                    {
                        switch (lang)
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
                        switch (lang)
                        {
                            case sv: words = ["inträffar", not, "vid tidpunkt"]; break;
                            case en:
                            default: words = [not, "at time"]; break;
                        }
                    }
                    else
                    {
                        switch (lang)
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
                        switch (lang)
                        {
                            case sv: words = ["är ", not, "kapabel till"]; break;
                            case en:
                            default: words = ["is", not, "capable of"]; break;
                        }
                    }
                    else
                    {
                        switch (lang)
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
                        switch (lang)
                        {
                            case sv: words = ["definieras", not, "som"]; break;
                            case en:
                            default: words = [not, "defined as"]; break;
                        }
                    }
                    else
                    {
                        switch (lang)
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
                        switch (lang)
                        {
                            case sv: words = ["härleds", not, "från"]; break;
                            case en:
                            default: words = ["is", not, "derived from"]; break;
                        }
                    }
                    else
                    {
                        switch (lang)
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
                        switch (lang)
                        {
                            case sv: words = ["härleds sammansatt", not, "från"]; break;
                            case en:
                            default: words = ["is", not, "compound derived from"]; break;
                        }
                    }
                    else
                    {
                        switch (lang)
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
                        switch (lang)
                        {
                            case sv: words = ["härleds", not, "etymologiskt från"]; break;
                            case en:
                            default: words = ["is", not, "etymologically derived from"]; break;
                        }
                    }
                    else
                    {
                        switch (lang)
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
                        switch (lang)
                        {
                            case sv: words = ["har", not, "egenskap"]; break;
                            case en:
                            default: words = ["has", not, "property"]; break;
                        }
                    }
                    else
                    {
                        switch (lang)
                        {
                            case sv: words = ["är", not, "egenskap av"]; break;
                            case en:
                            default: words = ["is", not, "property of"]; break;
                        }
                    }
                    break;
                case hasEmotion:
                    if (dir == RelDir.forward)
                    {
                        switch (lang)
                        {
                            case sv: words = ["har", not, "känsla"]; break;
                            case en:
                            default: words = ["has", not, "emotion"]; break;
                        }
                    }
                    else
                    {
                        switch (lang)
                        {
                            case sv: words = ["kan", not, "uttryckas med"]; break;
                            case en:
                            default: words = ["can", not, "be expressed by"]; break;
                        }
                    }
                    break;
                case hasBrother:
                    switch (lang)
                    {
                        case sv: words = ["har", not, "bror"]; break;
                        case de: words = ["hat", not, "Bruder"]; break;
                        case en:
                        default: words = ["has", not, "brother"]; break;
                    }
                    break;
                case hasSister:
                    switch (lang)
                    {
                        case sv: words = ["har", not, "syster"]; break;
                        case de: words = ["hat", not, "Schwester"]; break;
                        case en:
                        default: words = ["has", not, "sister"]; break;
                    }
                    break;
                case hasSpouse:
                    switch (lang)
                    {
                        case sv: words = ["har", not, "gemål"]; break;
                        case en:
                        default: words = ["has", not, "spouse"]; break;
                    }
                    break;
                case hasHusband:
                    if (dir == RelDir.forward)
                    {
                        switch (lang)
                        {
                            case sv: words = ["har", not, "make"]; break;
                            case en:
                            default: words = ["has", not, "husband"]; break;
                        }
                    }
                    else
                    {
                        switch (lang)
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
                        switch (lang)
                        {
                            case sv: words = ["har", not, "maka"]; break;
                            case en:
                            default: words = ["has", not, "wife"]; break;
                        }
                    }
                    else
                    {
                        switch (lang)
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
                        switch (lang)
                        {
                            case sv: words = ["har", not, "kontor i"]; break;
                            case en:
                            default: words = ["has", not, "office in"]; break;
                        }
                    }
                    else
                    {
                        switch (lang)
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
                        switch (lang)
                        {
                            case sv: words = ["skapar", not, "begär"]; break;
                            case en:
                            default: words = ["does", not, "cause", "desire"]; break;
                        }
                    }
                    else
                    {
                        switch (lang)
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
                        switch (lang)
                        {
                            case sv: words = ["är", not, "en ställföreträdare för"]; break;
                            case en:
                            default: words = ["is ", not, "a mutual proxy for"]; break;
                        }
                    }
                    else
                    {
                        switch (lang)
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
                        switch (lang)
                        {
                            case sv: words = ["är", not, "en instans av"]; break;
                            case en:
                            default: words = ["is ", not, "an instance of"]; break;
                        }
                    }
                    else
                    {
                        switch (lang)
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
                        switch (lang)
                        {
                            case sv: words = ["minskar", not, "risken av"]; break;
                            case en:
                            default: words = ["does ", not, "decrease risk of"]; break;
                        }
                    }
                    else
                    {
                        switch (lang)
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
                        switch (lang)
                        {
                            case sv: words = ["önskar", not]; break;
                            case en:
                            default: words = ["does", not, "desire"]; break;
                        }
                    }
                    else
                    {
                        switch (lang)
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
                        switch (lang)
                        {
                            case sv: words = ["använder", not]; break;
                            case en:
                            default: words = ["does", not, "use"]; break;
                        }
                    }
                    else
                    {
                        switch (lang)
                        {
                            case sv: words = ["används", not, "av"]; break;
                            case en:
                            default: words = ["is", not, "used by"]; break;
                        }
                    }
                    break;
                case shorthandFor:
                    if (dir == RelDir.forward)
                    {
                        switch (lang)
                        {
                            case sv: words = ["är", not, "en ihopskrivning för"]; break;
                            case en:
                            default: words = ["is", not, "a shorthand for"]; break;
                        }
                    }
                    else
                    {
                        switch (lang)
                        {
                            case sv: words = ["har", not, "ihopskrivning"]; break;
                            case en:
                            default: words = ["does", not, "have shorthand"]; break;
                        }
                    }
                    break;
                case abbreviationFor:
                    if (dir == RelDir.forward)
                    {
                        switch (lang)
                        {
                            case sv: words = ["är", not, "förkortning för"]; break;
                            case en:
                            default: words = ["is", not, "an abbreviation for"]; break;
                        }
                    }
                    else
                    {
                        switch (lang)
                        {
                            case sv: words = ["har", not, "förkortning"]; break;
                            case en:
                            default: words = ["does", not, "have abbreviation"]; break;
                        }
                    }
                    break;
                case acronymFor:
                    if (dir == RelDir.forward)
                    {
                        switch (lang)
                        {
                            case sv: words = ["är", not, "en acronym för"]; break;
                            case en:
                            default: words = ["is", not, "an acronym for"]; break;
                        }
                    }
                    else
                    {
                        switch (lang)
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
                        switch (lang)
                        {
                            case sv: words = ["är", not, "en emotikon för"]; break;
                            case en:
                            default: words = ["is", not, "an emoticon for"]; break;
                        }
                    }
                    else
                    {
                        switch (lang)
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
                        switch (lang)
                        {
                            case sv: words = ["spelar", not, "instrument"]; break;
                            case en:
                            default: words = ["does", not, "play instrument"]; break;
                        }
                    }
                    else
                    {
                        switch (lang)
                        {
                            case sv: words = ["är", not, "ett instrument som spelas av"]; break;
                            case en:
                            default: words = ["is", not, "an instrument played by"]; break;
                        }
                    }
                    break;
                case hasMeaning:
                    if (dir == RelDir.forward)
                    {
                        switch (lang)
                        {
                            case sv: words = ["har", not, "betydelsen"]; break;
                            case en:
                            default: words = ["does", not, "have meaning"]; break;
                        }
                    }
                    else
                    {
                        switch (lang)
                        {
                            case sv: words = ["kan", not, "beskrivas av"]; break;
                            case en:
                            default: words = ["can", not, "be described by"]; break;
                        }
                    }
                    break;
                case mutualProxyFor:
                    switch (lang)
                    {
                        case sv: words = ["är", not, "en ömsesidig ställföreträdare för"]; break;
                        case en:
                        default: words = ["is ", not, "a mutual proxy for"]; break;
                    }
                    break;
                case wordForm:
                    switch (lang)
                    {
                        case sv: words = ["har", not, "ord form"]; break;
                        case en:
                        default: words = ["has ", not, "word form"]; break;
                    }
                    break;
                case verbForm:
                    switch (lang)
                    {
                        case sv: words = ["har", not, "verb form"]; break;
                        case en:
                        default: words = ["has", not, "verb form"]; break;
                    }
                    break;
                case nounForm:
                    switch (lang)
                    {
                        case sv: words = ["har", not, "substantiv form"]; break;
                        case en:
                        default: words = ["has", not, "noun form"]; break;
                    }
                    break;
                case adjectiveForm:
                    switch (lang)
                    {
                        case sv: words = ["har", not, "adjektiv form"]; break;
                        case en:
                        default: words = ["has", not, "adjective form"]; break;
                    }
                    break;
                case cookedWith:
                    switch (lang)
                    {
                        case sv: words = ["kan", not, "lagas med"]; break;
                        case en:
                        default: words = ["can be", not, "cooked with"]; break;
                    }
                    break;
                case servedWith:
                    switch (lang)
                    {
                        case sv: words = ["kan", not, "serveras med"]; break;
                        case en:
                        default: words = ["can be", not, "served with"]; break;
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
        }
    }

    return words.filter!(word => word !is null) // strip not
                .joiner(" "); // add space
}

/** Return true if $(D special) is a more specialized relation than $(D general).
    TODO extend to apply specialization in several steps:
    If A specializes B and B specializes C then A specializes C
*/
bool specializes(Rel special,
                 Rel general)
    @safe @nogc pure nothrow
{
    with (Rel) {
        switch (general)
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
                                                hasCurrency,
                                                hasEmotion);
            case derivedFrom: return special.of(acronymFor,
                                                abbreviationFor,
                                                emoticonFor);
            case abbreviationFor: return special.of(acronymFor, emoticonFor);
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
            case wordForm: return special.of(verbForm,
                                             nounForm,
                                             adjectiveForm);
            case synonymFor: return special.of(shorthandFor);
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
    /* TODO Used to infer that
       - X and Y are sisters => (hasSister(X,Y) && hasSister(Y,X))
    */
    bool isSymmetric(const Rel rel)
    {
        with (Rel)
            return rel.of(relatedTo,
                          translationOf,
                          synonymFor,
                          antonymFor,
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
                          cookedWith,
                          servedWith,
                          physicallyConnectedWith,

                          mutualProxyFor,

                          wordForm,
                          verbForm,
                          nounForm,
                          adjectiveForm);
    }

    /** Return true if $(D relation) is a transitive relation that can used to
        inference new relations (knowledge).

        A relation R from A to B is transitive if A >=R=> B and B >=R=> C
        infers A >=R=> C.
    */
    bool isTransitive(const Rel rel)
    {
        with (Rel)
            return (rel.isSymmetric ||
                    rel.of(generalizes,
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
                           entails,
                           hasSubevent,
                           hasPrerequisite,
                           hasShape,
                           hasEmotion));
    }

    bool oppositeOf(const Rel a,
                    const Rel b)
    {
        with (Rel)
            return (a == hasEnemy  && b == hasFriend ||
                    a == hasFriend && b == hasEnemy);
    }
    alias areOpposites = oppositeOf;

    /** Return true if $(D rel) is a strong.
        TODO Where is strength decided and what purpose does it have?
    */
    bool isStrong(Rel rel)
    {
        with (Rel)
            return rel.of(hasProperty,
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
        with (Rel)
            return rel.of(isA,
                          locatedNear);
    }

}
