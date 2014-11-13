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
    Data: http://www.mpi-inf.mpg.de/departments/databases-and-information-systems/research/yago-naga/yago/

    See also: http://programmers.stackexchange.com/q/261163/38719
    See also: https://en.wikipedia.org/wiki/Hypergraph
    See also: https://github.com/commonsense/conceptnet5/wiki
    See also: http://forum.dlang.org/thread/fysokgrgqhplczgmpfws@forum.dlang.org#post-fysokgrgqhplczgmpfws:40forum.dlang.org
    See also: http://www.eturner.net/omcsnetcpp/

    TODO Make use of stealFront and stealBack
    TODO Make LinkIx, ConceptIx inherit Nullable!(Ix, Ix.max)

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
import std.algorithm: findSplit, findSplitBefore, findSplitAfter, groupBy, sort, skipOver;
import std.container: Array;
import std.string: tr;
import std.uni: isWhite, toLower;
import algorithm_ex: isPalindrome;
import range_ex: stealFront, stealBack;
import sort_ex: sortBy, rsortBy;
import porter;
import dbg;

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
enum Rel:ubyte
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
    memberOfEconomicSector,
    participatesIn,
    growsIn,
    attends,
    worksFor,
    worksInAcademicField,
    writesForPublication,
    leaderOf,
    ceoOf,
    represents,
    concerns, // TODO relate

    multipleOf,

    writtenAboutInPublication,

    plays,
    playsInstrument,
    playsIn,
    playsFor,

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

    capableOf, /* Something that A can typically do is B. /r/CapableOf
                  /c/en/knife /c/en/cut */

    atLocation, /* A is a typical location for B, or A is the inherent location
                   of B. Some instances of this would be considered meronyms in
                   WordNet. /r/AtLocation /c/en/butter /c/en/refrigerator; /r/AtLocation
                   /c/en/boston /c/en/massachusetts */
    hasCitizenship, livesIn = hasCitizenship,
    hasResidenceIn,
    languageSchoolInCity,

    bornAtLocation,
    diedAtLocation,

    hasOfficeIn,
    headquarteredIn,

    hasContext,

    locatedNear,

    controls,

    causes, /* A and B are events, and it is typical for A to cause B. */
    entails = causes, /* TODO same as causes? */
    leadsTo = causes,
    causesSideEffect,

    decreasesRiskOf,

    hasSubevent, /* A and B are events, and B happens as a subevent of A. */

    hasFirstSubevent, /* A is an event that begins with subevent B. */

    hasLastSubevent, /* A is an event that concludes with subevent B. */

    hasPrerequisite, /* In order for A to happen, B needs to happen; B is a
                        dependency of A. /r/HasPrerequisite/ /c/en/drive/ /c/en/get_in_car/ */

    endedAt,

    hasProperty, /* A has B as a property; A can be described as
                    B. /r/HasProperty /c/en/ice /c/en/solid */
    hasShape,
    hasColor,
    hasAge,
    hasOfficialWebsite,
    hasJobPosition, hasEmployment = hasJobPosition,
    hasTeamPosition,
    hasTournament,
    hasCapital,
    hasExpert,
    hasLanguage,

    attribute,

    motivatedByGoal, /* Someone does A because they want result B; A is a step
                        toward accomplishing the goal B. */
    obstructedBy, /* A is a goal that can be prevented by B; B is an obstacle in
                     the way of A. */

    causesDesire,

    desires, /* A is a conscious entity that typically wants B. Many assertions
                of this type use the appropriate language's word for "person" as
                A. /r/Desires /c/en/person /c/en/love */
    eats,

    buys,
    acquires,

    hires,
    sponsors, // TODO related

    creates, /* B is a process that creates A. /r/CreatedBy /c/en/cake
                /c/en/bake */
    develops,
    produces,
    writes,

    receivesAction,

    synonymFor, /* A and B have very similar meanings. This is the synonym relation
                in WordNet as well. */

    antonymFor, oppositeOf = antonymFor, /* A and B are opposites in some relevant way, such as being
                opposite ends of a scale, or fundamentally similar things with a
                key difference between them. Counterintuitively, two _concepts
                must be quite similar before people consider them antonyms. This
                is the antonym relation in WordNet as well. /r/Antonym
                /c/en/black /c/en/white; /r/Antonym /c/en/hot /c/en/cold */

    retronymFor, differentation = retronymFor, // $(EM acoustic) guitar. https://en.wikipedia.org/wiki/Retronym

    acronymFor,

    physicallyConnectedWith,

    arisesFrom,

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

    generalizes, // TODO Merge with other enumerator?

    hasRelative,
    hasFamilyMember, // can be a dog

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

    atDate,
    proxyFor,
    mutualProxyFor,

    competesWith,
    involvedWith,
    collaboratesWith,

    graduatedFrom,
    agentCreated,

    bornIn,
    marriedIn,
    diedIn,
    diedAtAge,

    chargedWithCrime,

    movedTo, // TODO infers atLocation

    cookedWith,
    servedWith,
}

/** Relation Direction. */
enum RelDir
{
    backward,
    forward
}

string toHumanLang(const Rel rel,
                   const RelDir linkDir,
                   const bool negation = false,
                   const HLang lang = HLang.en)
    @safe pure
{
    with (Rel)
    {
        with (HLang)
        {
            auto neg = negation ? " " ~ negationIn(lang) : "";
            switch (rel)
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
                case synonymFor:
                    switch (lang)
                    {
                        case sv: return "är" ~ neg ~ " synonym med";
                        case en:
                        default: return "is" ~ neg ~ " synonymous with";
                    }
                case antonymFor:
                    switch (lang)
                    {
                        case sv: return "är" ~ neg ~ " motsatsen till";
                        case en:
                        default: return "is" ~ neg ~ " the opposite of";
                    }
                case similarSizeTo:
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
                case looksLike:
                    switch (lang)
                    {
                        case sv: return "ser" ~ neg ~ " ut som";
                        case en:
                        default: return "looks" ~ neg ~ " like";
                    }
                case isA:
                    if (linkDir == RelDir.forward)
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
                    if (linkDir == RelDir.forward)
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
                    if (linkDir == RelDir.forward)
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
                            case sv: return "har" ~ neg ~ " medlem";
                            case en:
                            default: return "have" ~ neg ~ " member";
                        }
                    }
                case topMemberOf:
                    if (linkDir == RelDir.forward)
                    {
                        switch (lang)
                        {
                            case sv: return "är" ~ neg ~ " huvudmedlem av";
                            case en:
                            default: return "is" ~ neg ~ " the top member of";
                        }
                    }
                    else
                    {
                        switch (lang)
                        {
                            case sv: return "har" ~ neg ~ " toppmedlem";
                            case en:
                            default: return "have" ~ neg ~ " top member";
                        }
                    }
                case participatesIn:
                    if (linkDir == RelDir.forward)
                    {
                        switch (lang)
                        {
                            case sv: return "deltog" ~ neg ~ " i";
                            case en:
                            default: return "participate" ~ neg ~ " in";
                        }
                    }
                    else
                    {
                        switch (lang)
                        {
                            case sv: return "har" ~ neg ~ " deltagare";
                            case en:
                            default: return "have" ~ neg ~ " participant";
                        }
                    }
                case worksFor:
                    if (linkDir == RelDir.forward)
                    {
                        switch (lang)
                        {
                            case sv: return "arbetar" ~ neg ~ " för";
                            case en:
                            default: return "works" ~ neg ~ " for";
                        }
                    }
                    else
                    {
                        switch (lang)
                        {
                            case sv: return "har " ~ neg ~ " arbetar";
                            case en:
                            default: return "has " ~ neg ~ " employee";
                        }
                    }
                case playsIn:
                    if (linkDir == RelDir.forward)
                    {
                        switch (lang)
                        {
                            case sv: return "spelar" ~ neg ~ " i";
                            case en:
                            default: return "plays" ~ neg ~ " in";
                        }
                    }
                    else
                    {
                        switch (lang)
                        {
                            case sv: return "har " ~ neg ~ " spelare";
                            case en:
                            default: return "have " ~ neg ~ " player";
                        }
                    }
                case plays:
                    if (linkDir == RelDir.forward)
                    {
                        switch (lang)
                        {
                            case sv: return "spelar" ~ neg;
                            case en:
                            default: return "plays" ~ neg;
                        }
                    }
                    else
                    {
                        switch (lang)
                        {
                            case sv: return "spelas " ~ neg ~ " av";
                            case en:
                            default: return "played " ~ neg ~ " by";
                        }
                    }
                case contributesTo:
                    if (linkDir == RelDir.forward)
                    {
                        switch (lang)
                        {
                            case sv: return "bidrar" ~ neg ~ " till";
                            case en:
                            default: return "contributes" ~ neg ~ " to";
                        }
                    }
                    else
                    {
                        switch (lang)
                        {
                            case sv: return "har " ~ neg ~ " bidragare";
                            case en:
                            default: return "has " ~ neg ~ " contributor";
                        }
                    }
                case leaderOf:
                    if (linkDir == RelDir.forward)
                    {
                        switch (lang)
                        {
                            case sv: return "leder" ~ neg;
                            case en:
                            default: return "leads" ~ neg;
                        }
                    }
                    else
                    {
                        switch (lang)
                        {
                            case sv: return "leds " ~ neg ~ " av";
                            case en:
                            default: return "is lead " ~ neg ~ " by";
                        }
                    }
                case represents:
                    if (linkDir == RelDir.forward)
                    {
                        switch (lang)
                        {
                            case sv: return "representerar" ~ neg;
                            case en:
                            default: return "represents" ~ neg;
                        }
                    }
                    else
                    {
                        switch (lang)
                        {
                            case sv: return "representeras " ~ neg ~ " av";
                            case en:
                            default: return "is represented " ~ neg ~ " by";
                        }
                    }
                case ceoOf:
                    if (linkDir == RelDir.forward)
                    {
                        switch (lang)
                        {
                            case sv: return "är" ~ neg ~ " VD för";
                            case en:
                            default: return "is" ~ neg ~ " CEO of";
                        }
                    }
                    else
                    {
                        switch (lang)
                        {
                            case sv: return "is " ~ neg ~ " led by";
                            case en:
                            default: return "leds " ~ neg ~ " av";
                        }
                    }
                case hasA:
                    if (linkDir == RelDir.forward)
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
                    return (((!rel.isSymmetric) && linkDir == RelDir.forward ? `<` : ``) ~
                            `-` ~ rel.to!(typeof(return)) ~ `-` ~
                            ((!rel.isSymmetric) && linkDir == RelDir.backward ? `>` : ``));
            }
        }
    }
}

void skipOverNELLPrefixes(R, A)(ref R s, in A agents)
{
    foreach (agent; agents)
    {
        if (s.length > agent.length &&
            s.skipOver(agent)) { break; }
    }
}

void skipOverNELLSuffixes(R, A)(ref R s, in A agents)
{
    foreach (agent; agents)
    {
        if (s.length > agent.length &&
            s.endsWith(agent)) { s = s[0 .. $ - agent.length]; break; }
    }
}

void skipOverNELLNouns(R, A)(ref R s, in A agents)
{
    s.skipOverNELLPrefixes(agents);
    s.skipOverNELLSuffixes(agents);
}

/** Decode Relation $(D s) together with its possible $(D negation) and
    $(D reversion). */
Rel decodeRelation(S)(S s,
                      out bool negation,
                      out bool reversion) if (isSomeString!S)
{
    with (Rel)
    {
        switch (s)
        {
            case `companyeconomicsector`: return memberOfEconomicSector;
            case `headquarteredin`: return headquarteredIn;

            case `animalsuchasfish`: reversion = true; return memberOf;
            case `animalsuchasinsect`: reversion = true; return memberOf;
            case `animalsuchasinvertebrate`: reversion = true; return memberOf;
            case `archaeasuchasarchaea`: reversion = true; return memberOf;

            case `plantincludeplant`: reversion = true; return memberOf;
            case `plantgrowinginplant`: return growsIn;

            case `plantrepresentemotion`: return represents;

            case `musicianinmusicartist`: return memberOf;
            case `bookwriter`: reversion = true; return writes;
            case `politicianholdsoffice`: return hasJobPosition;

            case `sportsgamedate`: return atDate;
            case `sportsgamesport`: return plays;
            case `sportsgamewinner`: reversion = true; return wins;
            case `sportsgameloser`: reversion = true; return loses;
            case `sportsgameteam`: reversion = true; return participatesIn;
            case `sporthassportsteamposition`: return hasTeamPosition;

            case `sportsgamescore`: return hasScore;
            case `sportsgameloserscore`: return hasLoserScore;
            case `sportsgamewinnerscore`: return hasWinnerScore;

            case `awardtrophytournamentisthechampionshipgameofthenationalsport`: reversion = true; return hasTournament;
            case `politicsbillconcernsissue`: return concerns;
            case `politicsbillsponsoredbypoliticianus`: reversion = true; return sponsors;
            case `booksuchasbook`: reversion = true; return instanceOf;
            case `jobpositionusesacademicfield`: return memberOf;
            case `academicprogramatuniversity`: return partOf; // TODO Ok?
            case `academicfieldsuchasacademicfield`: return relatedTo;
            case `academicfieldhassubfield`: reversion = true; return partOf;
            case `academicfieldconcernssubject`: reversion = true; return partOf; // TODO Ok?
            case `academicfieldusedbyeconomicsector`: reversion = true; return uses;
            case `languageofcountry`: reversion = true; return hasLanguage;
            case `drughassideeffect`: return causesSideEffect;

            case `languageofcity`: reversion = true; return usesLanguage;
            case `languageofuniversity`: reversion = true; return usesLanguage;
            case `languageschoolincity`: return languageSchoolInCity;
            case `emotionassociatedwithdisease`: return relatedTo;
            case `bacteriaisthecausativeagentofphysiologicalcondition`: return causes;
            default: break;
        }

        enum nellAgents = [`object`, `agriculturalproduct`, `product`, `chemical`, `drug`, `concept`, `food`, `building`, `disease`, `bakedgood`,
                           `vegetableproduction`,
                           `agent`, `team`, `item`, `person`, `writer`, `musician`,
                           `athlete`,
                           `journalist`, `thing`, `bodypart`, `artery`, `sportschool`,
                           `sportfans`, `sport`, `event`, `scene`, `school`,
                           `vegetable`, `beverage`,
                           `bankbank`, // TODO bug in NELL?
                           `airport`, `bank`, `hotel`, `port`,

                           `skiarea`, `area`, `room`, `hall`, `island`, `city`, `country`, `office`,
                           `stateorprovince`, `state`, `province`, // TODO specialize from spatialregion
                           `headquarter`,

                           `geopoliticallocation`,
                           `geopoliticalorganization`,
                           `politicalorganization`,
                           `organization`,

                           `league`, `university`, `action`, `room`,
                           `animal`, `mammal`, `arthropod`, `insect`, `invertebrate`, `fish`, `mollusk`, `amphibian`, `arachnids`,
                           `location`, `creativework`, `equipment`, `profession`, `tool`,
                           `company`, `politician`,
                           `geometricshape`,
            ];
        S t = s;
        t.skipOverNELLNouns(nellAgents);

        t.skipOver(`that`);

        if (t.skipOver(`not`))
        {
            reversion = true;
        }

        switch (t.toLower)
        {
            case `relatedto`:                                      return relatedTo;
            case `andother`:                                      return relatedTo;

            case `isa`:                                            return isA;
            case `istypeof`:                                       return isA;

            case `ismultipleof`:                                   return multipleOf;

            case `partof`:                                         return partOf;

            case `memberof`:
            case `belongsto`:                                      return memberOf;

            case `include`:
            case `including`:
            case `suchas`:                       reversion = true; return memberOf;

            case `topmemberof`:                                    return topMemberOf;

            case `participatein`:
            case `participatedin`:                                 return participatesIn; // TODO past tense

            case `attends`:
            case `worksfor`:                                       return worksFor;
            case `writesforpublication`:                           return writesForPublication;
            case `inacademicfield`:                                return worksInAcademicField;

            case `ceoof`:                                          return ceoOf;
            case `plays`:                                          return plays;
            case `playsinstrument`:                                return playsInstrument;
            case `playsin`:                                        return playsIn;
            case `playsfor`:                                       return playsFor;
            case `competeswith`:
            case `playsagainst`:                                   return competesWith;

            case `contributesto`:                                  return contributesTo;
            case `contributedto`:                                  return contributesTo; // TODO past tense

            case `hasa`:                                           return hasA;
            case `usedfor`:                      reversion = true; return uses;
            case `use`:
            case `uses`:                                           return uses;
            case `capableof`:                                      return capableOf;

                // spatial
            case `at`:                assert(s == `atlocation`);   return atLocation;
            case `in`:
            case `foundin`:
            case `existsat`:
            case `locatedin`:
            case `attractionof`:
            case `headquarteredin`:
            case `latitudelongitude`:
            case `incountry`:
            case `actsin`:                                         return atLocation;
            case `movedto`:                                        return movedTo;

            case `locationof`:                   reversion = true; return atLocation;
            case `locatedwithin`:                                  return atLocation;

            case `hascontext`:                                     return hasContext;
            case `locatednear`:                                    return locatedNear;
            case `hasofficein`:                                    return hasOfficeIn;

                // membership
            case `hascitizenship`:                                 return hasCitizenship;
            case `hasresidencein`:                                 return hasResidenceIn;

            case `causes`:                                         return causes;
            case `cancause`:                                       return causes;
            case `leadsto`:                                        return causes;
            case `leadto`:                                         return causes;
            case `entails`:                                        return entails;

            case `decreasestheriskof`:                             return decreasesRiskOf;

                // time
            case `hassubevent`:                                    return hasSubevent;
            case `hasfirstsubevent`:                               return hasFirstSubevent;
            case `haslastsubevent`:                                return hasLastSubevent;
            case `hasprerequisite`:                                return hasPrerequisite;
            case `prerequisiteof`:               reversion = true; return hasPrerequisite;

                // properties
            case `hasproperty`:                                    return hasProperty;
            case `hasshape`:                                       return hasShape;
            case `hascolor`:                                       return hasColor;
            case `hasage`:                                         return hasAge;
            case `hasofficialwebsite`:                             return hasOfficialWebsite;
            case `attribute`:                                      return attribute;

            case `motivatedbygoal`:                                return motivatedByGoal;
            case `obstructedby`:                                   return obstructedBy;

            case `desires`:                                        return desires;
            case `desireof`:                     reversion = true; return desires;

            case `preyson`:
            case `eat`:                                            return eats;
            case `feedon`:                                         return eats;
            case `eats`:                                           return eats;
            case `causesdesire`:                                   return causesDesire;

            case `buy`:                                            return buys;
            case `buys`:                                           return buys;
            case `buyed`:                                          return buys; // TODO past tense
            case `acquires`:                                       return acquires;
            case `acquired`:                                       return acquires; // TODO past tense

            case `hired`:                                          return hires; // TODO past tense
            case `hiredBy`:                      reversion = true; return hires; // TODO past tense

            case `created`:                                        return creates; // TODO past tense
            case `createdby`:                    reversion = true; return creates;
            case `develop`:                                        return develops;
            case `produces`:                                       return produces;

            case `receivesaction`:                                 return receivesAction;

            case `called`:                                         return synonymFor; // TODO past tense
            case `synonym`:                                        return synonymFor;
            case `alsoknownas`:                                    return synonymFor;

            case `antonym`:                                        return antonymFor;
            case `retronym`:                                       return retronymFor;

            case `acronymhasname`:
            case `acronymfor`:                                     return acronymFor;

            case `derivedfrom`:                                    return derivedFrom;
            case `arisesfrom`:                                     return arisesFrom;

            case `compoundderivedfrom`:                            return compoundDerivedFrom;
            case `etymologicallyderivedfrom`:                      return etymologicallyDerivedFrom;
            case `translationof`:                                  return translationOf;
            case `definedas`:                                      return definedAs;
            case `instanceof`:                                     return instanceOf;
            case `madeof`:                                         return madeOf;
            case `madefrom`:                                       return madeOf;
            case `inheritsfrom`:                                   return inheritsFrom;
            case `similarsize`:                                    return similarSizeTo;
            case `symbolof`:                                       return symbolOf;
            case `similarto`:                                      return similarTo;
            case `lookslike`:                                      return looksLike;
            case `haspainintensity`:                               return hasPainIntensity;
            case `haspaincharacter`:                               return hasPainCharacter;

            case `wordnet/adjectivepertainsto`: negation = true;   return adjectivePertainsTo;
            case `wordnet/adverbpertainsto`:    negation = true;   return adverbPertainsTo;
            case `wordnet/participleof`:        negation = true;   return participleOf;

            case `hasfamilymember`:
            case `familymemberof`:                                 return hasFamilyMember; // symmetric

            case `haswife`:                                        return hasWife;
            case `wifeof`:                      negation = true;   return hasWife;

            case `hashusband`:                                     return hasHusband;
            case `husbandof`:                   negation = true;   return hasHusband;

            case `hasbrother`:
            case `brotherof`:                                      return hasBrother; // symmetric

            case `hassister`:
            case `sisterof`:                                       return hasSister; // symmetric

            case `hasspouse`:
            case `spouseof`:                                       return hasSpouse; // symmetric

            case `hassibling`:
            case `siblingof`:                                      return hasSibling; // symmetric

            case `haschild`:                                       return hasChild;
            case `childof`:                      reversion = true; return hasChild;

            case `hasparent`:                                      return hasParent;
            case `parentof`:                     reversion = true; return hasParent;

            case `hasfather`:                                      return hasFather;
            case `fatherof`:                     reversion = true; return hasFather;

            case `hasmother`:                                      return hasMother;
            case `motherof`:                     reversion = true; return hasMother;

            case `haswikipediaurl`:                                return wikipediaURL;
            case `subpartof`:                                      return partOf;
            case `synonymfor`:                                     return synonymFor;
            case `generalizations`:                                return generalizes;
            case `specializationof`: reversion = true;             return generalizes;
            case `conceptprerequisiteof`: reversion = true;        return hasPrerequisite;
            case `usesequipment`:                                  return uses;
            case `usesstadium`:                                    return uses;
            case `containsbodypart`: reversion = true;             return partOf;

            case `atdate`:                                         return atDate;
            case `dissolvedatdate`:                                return endedAt;
            case `proxyfor`:                                       return proxyFor;
            case `mutualproxyfor`:                                 return mutualProxyFor;

            case `hasjobposition`:                                 return hasJobPosition;

            case `graduated`: // TODO past tense
            case `graduatedfrom`:                                  return graduatedFrom; // TODO past tense

            case `involvedwith`:                                   return involvedWith;
            case `collaborateswith`:                               return collaboratesWith;

            case `contains`: reversion = true;                     return partOf;
            case `controls`:                                       return controls;
            case `leads`: reversion = true;                        return leaderOf;
            case `represents`:                                     return represents;
            case `chargedwithcrime`:                               return chargedWithCrime;

            case `wasbornin`:                                      return bornIn;
            case `bornin`:                                         return bornIn;
            case `marriedinyear`:
            case `marriedin`:                                      return marriedIn;
            case `diedin`:                                         return diedIn;
            case `diedatage`:                                      return diedAtAge;

            case `istallerthan`:                                   return isTallerThan;
            case `isshorterthan`:                reversion = true; return isTallerThan;

            case `islargerthan`:                                   return isLargerThan;
            case `issmallerthan`:                reversion = true; return isLargerThan;

            case `isheavierthan`:                                  return isHeavierThan;
            case `islighterthan`:                reversion = true; return isHeavierThan;

            case `isolderthan`:                                    return isOlderThan;
            case `isyoungerthan`:                reversion = true; return isOlderThan;

            case `aremorethan`:                                    return areMoreThan;
            case `arefewerthan`:                 reversion = true; return areMoreThan;

            case `hascapital`:                                     return hasCapital;
            case `capitalof`:                    reversion = true; return hasCapital;

            case `writtenaboutinpublication`:                      return writtenAboutInPublication;

            case `hasexpert`:
            case `mlareaexpert`:                                   return hasExpert;

            case `cookedwith`:                                     return cookedWith;
            case `servedwith`:                                     return servedWith;

            default:
                dln(`Unknown relationString `, t, ` originally `, s);
                                                                   return relatedTo;
        }
    }
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
                                             attends);
            case hasProperty: return special.of(hasAge,
                                                hasColor,
                                                hasShape,
                                                hasTeamPosition,
                                                hasTournament,
                                                hasCapital,
                                                hasExpert,
                                                hasJobPosition,
                                                hasOfficialWebsite,
                                                hasScore, hasLoserScore, hasWinnerScore,
                                                hasLanguage);
            case derivedFrom: return special.of(acronymFor);
            case atLocation: return special.of(bornAtLocation,
                                               hasCitizenship,
                                               hasResidenceIn,
                                               diedAtLocation,
                                               hasOfficeIn,
                                               headquarteredIn,
                                               languageSchoolInCity);
            case buys: return special.of(acquires);
            case desires: return special.of(eats, buys, acquires);
            case similarTo: return special.of(similarSizeTo,
                                              similarAppearanceTo);
            case causes: return special.of(causesSideEffect);
            case uses: return special.of(usesLanguage);
            case physicallyConnectedWith: return special.of(arisesFrom);
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
                          similarSizeTo,
                          similarTo,
                          similarAppearanceTo,
                          hasRelative,
                          hasFamilyMember,
                          hasSpouse,
                          hasSibling,
                          hasBrother,
                          hasSister,
                          competesWith,
                          cookedWith,
                          servedWith,
                          physicallyConnectedWith);
    }

    /** Return true if $(D relation) is a transitive relation that can used to
        inference new relations (knowledge).

        A relation R from A to B is transitive if A >=R=> B and B >=R=> C
        infers A >=R=> C.
    */
    bool isTransitive(const Rel rel)
    {
        with (Rel)
            return (rel.isSymmetric &&
                    rel.of(generalizes,
                           partOf,
                           isA,
                           memberOf,
                           hasA,
                           atLocation,
                           hasContext,
                           locatedNear,
                           causes,
                           entails,
                           hasSubevent,
                           hasPrerequisite));
    }

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

/* Thematic toThematic(Rel rel) */
/*     @safe @nogc pure nothrow */
/* { */
/*     with (Rel) */
/*     { */
/*         final switch (rel) */
/*         { */
/*             case relatedTo: return Thematic.kLines; */
/*             case isA: return Thematic.things; */

/*             case partOf: return Thematic.things; */
/*             case memberOf: return Thematic.things; */
/*             case worksFor: return Thematic.unknown; */
/*             case leaderOf: return Thematic.unknown; */
/*             case ceoOf: return Thematic.unknown; */

/*             case hasA: return Thematic.things; */
/*             case usedFor: return Thematic.functional; */
/*             case capableOf: return Thematic.agents; */
/*             case atLocation: return Thematic.spatial; */
/*             case hasContext: return Thematic.things; */

/*             case locationOf: return Thematic.spatial; */
/*             case locatedNear: return Thematic.spatial; */

/*             case causes: return Thematic.causal; */
/*             case hasSubevent: return Thematic.events; */
/*             case hasFirstSubevent: return Thematic.events; */
/*             case hasLastSubevent: return Thematic.events; */
/*             case hasPrerequisite: return Thematic.causal; // TODO Use events, causal, functional */

/*             case hasProperty: return Thematic.things; */
/*             case hasColor: return Thematic.unknown; */
/*             case attribute: return Thematic.things; */

/*             case motivatedByGoal: return Thematic.affective; */
/*             case obstructedBy: return Thematic.causal; */
/*             case desires: return Thematic.affective; */
/*             case causesDesire: return Thematic.affective; */

/*             case createdBy: return Thematic.agents; */
/*             case receivesAction: return Thematic.agents; */

/*             case synonymFor: return Thematic.synonym; */
/*             case antonymFor: return Thematic.antonym; */
/*             case retronymFor: return Thematic.retronym; */

/*             case derivedFrom: return Thematic.things; */
/*             case compoundDerivedFrom: return Thematic.things; */
/*             case etymologicallyDerivedFrom: return Thematic.things; */
/*             case translationOf: return Thematic.synonym; */

/*             case definedAs: return Thematic.things; */

/*             case instanceOf: return Thematic.things; */
/*             case madeOf: return Thematic.things; */
/*             case inheritsFrom: return Thematic.things; */
/*             case similarSizeTo: return Thematic.things; */
/*             case symbolOf: return Thematic.kLines; */
/*             case similarTo: return Thematic.kLines; */
/*             case hasPainIntensity: return Thematic.kLines; */
/*             case hasPainCharacter: return Thematic.kLines; */

/*             case adjectivePertainsTo: return Thematic.unknown; */
/*             case adverbPertainsTo: return Thematic.unknown; */
/*             case participleOf: return Thematic.unknown; */

/*             case generalizes: return Thematic.unknown; */

/*             case hasRelative: return Thematic.unknown; */
/*             case hasFamilyMember: return Thematic.unknown; */
/*             case hasSpouse: return Thematic.unknown; */
/*             case hasWife: return Thematic.unknown; */
/*             case hasHusband: return Thematic.unknown; */
/*             case hasSibling: return Thematic.unknown; */
/*             case hasBrother: return Thematic.unknown; */
/*             case hasSister: return Thematic.unknown; */
/*             case hasGrandParent: return Thematic.unknown; */
/*             case hasParent: return Thematic.unknown; */
/*             case hasFather: return Thematic.unknown; */
/*             case hasMother: return Thematic.unknown; */
/*             case hasGrandChild: return Thematic.unknown; */
/*             case hasChild: return Thematic.unknown; */
/*             case hasSon: return Thematic.unknown; */
/*             case hasDaugther: return Thematic.unknown; */
/*             case hasPet: return Thematic.unknown; */

/*             case wikipediaURL: return Thematic.things; */
/*         } */
/*     } */

/* } */

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
    manual,
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
        static LinkIx asUndefined() { return LinkIx(Ix.max); }
        bool defined() const { return this != LinkIx.asUndefined; }
    private:
        Ix _lIx = Ix.max;
    }
    struct ConceptIx
    {
        @safe @nogc pure nothrow:
        static ConceptIx asUndefined() { return ConceptIx(Ix.max); }
        bool defined() const { return this != ConceptIx.asUndefined; }
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
        static CategoryIx asUndefined() { return CategoryIx(ushort.max); }
        bool defined() const { return this != CategoryIx.asUndefined; }
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
                                                  a._rel == b._rel));
    }
    auto outLinksGroupedByRelation(in Concept concept)
    {
        return outLinksOf(concept).array.groupBy!((a, b) => // TODO array needed?
                                                  (a._negation == b._negation &&
                                                   a._rel == b._rel));
    }

    auto insByRelation(in Concept concept)
    {
        return insOf(concept).array.groupBy!((a, b) => // TODO array needed?
                                             (a[0]._negation == b[0]._negation &&
                                              a[0]._rel == b[0]._rel));
    }
    auto outsByRelation(in Concept concept)
    {
        return outsOf(concept).array.groupBy!((a, b) => // TODO array needed?
                                              (a[0]._negation == b[0]._negation &&
                                               a[0]._rel == b[0]._rel));
    }

    static if (useArray) { alias ConceptIxes = Array!ConceptIx; }
    else                 { alias ConceptIxes = ConceptIx[]; }

    /** Many-Concepts-to-Many-Concepts Link (Edge).
     */
    struct Link
    {
        alias Weight = ubyte; // link weight pack type

        @safe @nogc pure nothrow:

        this(Rel rel,
             Origin origin = Origin.unknown)
        {
            this._rel = rel;
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

        Rel _rel;
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

        size_t[Rel.max + 1] _relCounts;
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
    ConceptIx lookupOrStoreConcept(in Lemma lemma,
                                   Concept concept)
    {
        if (lemma in _conceptIxByLemma)
        {
            return _conceptIxByLemma[lemma]; // lookup
        }
        else
        {
            // store
            assert(_concepts.length <= Ix.max);
            const cix = ConceptIx(cast(Ix)_concepts.length);
            _concepts ~= concept; // .. new concept that is stored
            _conceptIxByLemma[lemma] = cix; // lookupOrStoreConcept index to ..
            _conceptStringLengthSum += lemma.words.length;
            return cix;
        }
    }

    /** Lookup or Store Concept named $(D words) in language $(D lang). */
    ConceptIx lookupOrStoreConcept(Words words,
                                   HLang lang,
                                   WordKind kind,
                                   CategoryIx categoryIx)
    {
        return lookupOrStoreConcept(Lemma(words, lang, kind, categoryIx),
                                    Concept(words, lang, kind, categoryIx));
    }

    /** Add Link from $(D src) to $(D dst) of type $(D rel) and weight $(D weight). */
    LinkIx connect(ConceptIx srcIx,
                   Rel rel,
                   ConceptIx dstIx,
                   Origin origin = Origin.unknown,
                   real weight = 1.0,
                   bool negation = false,
                   bool reversion = false)
    {
        if (false)
        {
            LinkIx eix = areRelated(srcIx, dstIx); // existing Link Index
            if (eix != LinkIx.asUndefined)
            {
                auto existingLink = linkByIx(eix);
                if (existingLink._rel == rel)
                {
                    dln("warning: Concepts ",
                        conceptByIx(srcIx), " and ",
                        conceptByIx(dstIx), " already related as ",
                        rel);
                }
            }
        }

        auto lix  = LinkIx(cast(Ix)_links.length);
        auto link = Link(rel, origin);

        link._srcIx = reversion ? dstIx : srcIx;
        link._dstIx = reversion ? srcIx : dstIx;

        assert(_links.length <= Ix.max); conceptByIx(link._srcIx).inIxes ~= lix; _connectednessSum++;
        assert(_links.length <= Ix.max); conceptByIx(link._dstIx).outIxes ~= lix; _connectednessSum++;

        ++_relCounts[rel];
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
        return lix; // _links.back;
    }
    alias relate = connect;

    /** Read ConceptNet5 URI.
        See also: https://github.com/commonsense/conceptnet5/wiki/URI-hierarchy-5.0
    */
    ConceptIx readCN5ConceptURI(T)(const T part)
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

        return lookupOrStoreConcept(word, hlang, wordKind, anyCategory);
    }

    import std.algorithm: splitter;

    /** Read NELL Entity from $(D part). */
    Tuple!(ConceptIx, LinkIx) readNELLEntity(S)(const S part)
    {
        const show = false;

        auto entity = part.splitter(':');

        if (entity.front == "concept")
        {
            entity.popFront; // ignore no-meaningful information
        }

        if (show) dln("ENTITY:", entity);

        auto personCategorySplit = entity.front.findSplitAfter("person");
        if (!personCategorySplit[0].empty)
        {
            /* dln(personCategorySplit, " livesIn ", personCategorySplit[1]); */
            /* lookupOrStoreCategory(personCategorySplit[0]); */
        }
        else
        {
            /* lookupOrStoreCategory(entity.front); */
        }

        /* category */
        immutable categoryName = entity.front.idup; entity.popFront;
        auto categoryIx = anyCategory;
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
            return typeof(return).init;
        }

        const lang = HLang.unknown;
        const kind = WordKind.noun;

        /* name */
        // clean cases such as concept:language:english_language
        immutable entityName = (entity.front.endsWith("_" ~ categoryName) ?
                                entity.front[0 .. $ - (categoryName.length + 1)] :
                                entity.front).idup;
        entity.popFront;

        auto entityIx = lookupOrStoreConcept(entityName,
                                             lang,
                                             kind,
                                             categoryIx);

        return tuple(entityIx,
                     connect(entityIx,
                             Rel.isA,
                             lookupOrStoreConcept(categoryName,
                                                  lang,
                                                  kind,
                                                  categoryIx),
                             Origin.nell, 1.0));
    }

    /** Read NELL CSV Line $(D line) at 0-offset line number $(D lnr). */
    void readNELLLine(R, N)(R line, N lnr)
    {
        Rel rel = Rel.any;
        bool negation = false;
        bool reversion = false;

        ConceptIx entityIx;
        ConceptIx valueIx;

        bool ignored = false;

        auto mainLink = Link(Origin.nell);

        bool show = false;

        auto parts = line.splitter('\t');
        size_t ix;
        foreach (part; parts)
        {
            switch (ix)
            {
                case 0:
                    auto entity = readNELLEntity(part);
                    entityIx = entity[0];
                    if (!entityIx.defined) { return; }

                    break;
                case 1:
                    auto predicate = part.splitter(':');

                    if (predicate.front == "concept")
                        predicate.popFront; // ignore no-meaningful information
                    else
                        if (show) dln("TODO Handle non-concept predicate ", predicate);

                    rel = predicate.front.decodeRelation(negation, reversion);
                    ignored = (rel == Rel.wikipediaURL);

                    break;
                case 2:
                    if (rel == Rel.atLocation)
                    {
                        const loc = part.findSplit(",");
                        if (!loc[1].empty)
                        {
                            setLocation(entityIx,
                                        Location(loc[0].to!double,
                                                 loc[2].to!double));
                        }
                        else
                        {
                            auto value = readNELLEntity(part);
                            valueIx = value[0];
                            if (!valueIx.defined) { return; }
                        }
                    }
                    break;
                case 4:
                    mainLink.setNELLWeight(part.to!real);
                    break;
                default:
                    if (ix < 5 && !ignored)
                    {
                        if (show) dln(" MORE:", part);
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
        Rel rel = Rel.any;
        bool negation = false;
        bool reversion = false;

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
                    rel = part[3..$].decodeRelation(negation, reversion); // TODO Handle case when part matches /r/_wordnet/X
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
            return connect(src, rel, dst, origin, weight, negation, reversion);
        }
        else
        {
            return LinkIx.asUndefined;
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
        writeln(`Rel Count by Type:`);
        foreach (rel; Rel.min .. Rel.max)
        {
            const count = _relCounts[rel];
            if (count)
            {
                writeln(`- `, rel.to!string, `: `, count);
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
        return typeof(return).asUndefined;
    }

    /** Return Index to Link relating $(D a) to $(D b) in any direction if present, otherwise LinkIx.max.
     */
    LinkIx areRelated(ConceptIx a,
                      ConceptIx b)
    {
        const ab = areRelatedInOrder(a, b);
        if (ab != typeof(return).asUndefined)
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
        return typeof(return).asUndefined;
    }

    void showLinkRelation(Rel rel,
                          RelDir linkDir,
                          bool negation = false,
                          HLang lang = HLang.en)
    {
        write(` - `, rel.toHumanLang(linkDir, negation, lang));
    }

    void showConcept(in Concept concept, real weight)
    {
        if (concept.words) write(` `, concept.words.tr("_", " "));
        write(`(`);
        if (concept.lang) write(concept.lang);
        if (concept.lemmaKind) write("-", concept.lemmaKind);
        writef(`:%.2f),`, weight);
    }

    void showLinkConcept(in Concept concept,
                         Rel rel,
                         real weight,
                         RelDir linkDir)
    {
        showLinkRelation(rel, linkDir);
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
                showLinkRelation(inGroup.front[0]._rel, RelDir.backward);
                foreach (inLink, inConcept; inGroup) // TODO sort on descending weights: .array.rsortBy!(a => a[0]._weight)
                {
                    showConcept(inConcept, inLink.normalizedWeight);
                }
                writeln();
            }

            foreach (outGroup; outsByRelation(concept))
            {
                showLinkRelation(outGroup.front[0]._rel, RelDir.backward);
                foreach (outLink, outConcept; outGroup) // TODO sort on descending weights: .array.rsortBy!(a => a[0]._weight)
                {
                    showConcept(outConcept, outLink.normalizedWeight);
                }
                writeln();
            }

            /* foreach (ix; concept.inIxes) */
            /* { */
            /*     const link = linkByIx(ix); */
            /*     showLinkConcept(conceptByIx(link._dstIx), */
            /*                     link._rel, */
            /*                     link.normalizedWeight, */
            /*                     RelDir.backward); */
            /* } */
            /* foreach (ix; concept.outIxes) */
            /* { */
            /*     const link = linkByIx(ix); */
            /*     showLinkConcept(conceptByIx(link._srcIx), */
            /*                     link._rel, */
            /*                     link.normalizedWeight, */
            /*                     RelDir.forward); */
            /* } */
        }

        if (normalizedLine == "palindrome")
        {
            import std.algorithm: filter;
            import std.utf: byDchar;
            foreach (palindromeConcept; _concepts.filter!(concept => concept.words.isPalindrome(3)))
            {
                showLinkConcept(palindromeConcept,
                                Rel.instanceOf,
                                real.infinity,
                                RelDir.backward);
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
