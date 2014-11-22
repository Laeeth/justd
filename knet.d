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

/* version = msgpack; */

import core.exception: UnicodeException;
import std.traits: isSomeString, isFloatingPoint, EnumMembers;
import std.conv: to, emplace;
import std.stdio;
import std.algorithm: findSplit, findSplitBefore, findSplitAfter, groupBy, sort, skipOver, filter, array, canFind;
import std.container: Array;
import std.string: tr;
import std.uni: isWhite, toLower;
import std.utf: byDchar;
import std.typecons: Nullable, Tuple, tuple;

import algorithm_ex: isPalindrome, either;
import range_ex: stealFront, stealBack;
import sort_ex: sortBy, rsortBy, sorted;
import skip_ex: skipOverBack, skipOverShortestOf, skipOverBackShortestOf;
import porter;
import dbg;
import grammars;
import rcstring;
import krels;
version(msgpack) import msgpack;

/* import stdx.allocator; */
/* import memory.allocators; */
/* import containers: HashMap; */

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

/** Drop $(D prefixes) in $(D s).
    TODO Use multi-argument skipOver when it becomes available http://forum.dlang.org/thread/bug-12335-3@https.d.puremagic.com%2Fissues%2F
 */
void skipOverPrefixes(R, A)(ref R s, in A prefixes)
{
    foreach (prefix; prefixes)
    {
        if (s.length > prefix.length &&
            s.skipOver(prefix)) { break; }
    }
}

/** Drop $(D suffixes) in $(D s). */
void skipOverSuffixes(R, A)(ref R s, in A suffixes)
{
    foreach (suffix; suffixes)
    {
        if (s.length > suffix.length &&
            s.endsWith(suffix)) { s = s[0 .. $ - suffix.length]; break; }
    }
}

void skipOverNELLNouns(R, A)(ref R s, in A agents)
{
    s.skipOverPrefixes(agents);
    s.skipOverSuffixes(agents);
}

/** Decode Relation $(D s) together with its possible $(D negation) and
    $(D reversion). */
Rel decodeRelation(S)(S predicate,
                      const S entity,
                      const S value,
                      const Origin origin,
                      out bool negation,
                      out bool reversion,
                      out Tense tense) if (isSomeString!S)
{
    with (Rel)
    {
        switch (predicate)
        {
            case `economicsector`:
            case `companyeconomicsector`: return memberOfEconomicSector;
            case `headquarteredin`: tense = Tense.pastMoment; return headquarteredIn;

            case `animalsuchasfish`: reversion = true; return memberOf;
            case `animalsuchasinsect`: reversion = true; return memberOf;
            case `animalsuchasinvertebrate`: reversion = true; return memberOf;
            case `archaeasuchasarchaea`: reversion = true; return memberOf;

            case `plantincludeplant`: reversion = true; return memberOf;
            case `plantgrowinginplant`: return growsIn;

            case `plantrepresentemotion`: return represents;

            case `musicianinmusicartist`: return memberOf;
            case `bookwriter`: reversion = true; return writes;

            case `politicianholdsoffice`:
            case `holdsoffice`: return hasJobPosition;

            case `attractionofcity`: return atLocation;

            case `sportsgamedate`: return atTime;
            case `sportsgamesport`: return plays;

            case `sportsgamewinner`: reversion = true; return wins;
            case `athletewinsawardtrophytournament`: return wins;

            case `sportsgameloser`: reversion = true; return loses;
            case `sportsgameteam`: reversion = true; return participatesIn;

            case `teamwontrophy`: reversion = true; tense = Tense.pastMoment; return wins;

            case `teammate`: return hasTeamMate;

            case `coachesteam`: return coaches;

            case `sporthassportsteamposition`:
            case `athleteplayssportsteamposition`: return hasTeamPosition;

            case `personhasethnicity`: return hasEthnicity;

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
            case `countrycurrency`: return hasCurrency;
            case `drughassideeffect`: return causesSideEffect;

            case `languageofcity`: reversion = true; return usesLanguage;
            case `languageofuniversity`: reversion = true; return usesLanguage;
            case `languageschoolincity`: return languageSchoolInCity;

            case `emotionassociatedwithdisease`: return relatedTo;
            case `drugpossiblytreatsphysiologicalcondition`: return treats; // TODO possibly

            case `bacteriaisthecausativeagentofphysiologicalcondition`: return causes;

            case `organizationterminatedperson`: return terminates;

            case `led`:
            case `athleteledsportsteam`: reversion = true; tense = Tense.pastMoment; return leaderOf;

            case `persondeathdate`: return diedIn;

            case `athleteinjuredhisbodypart`: tense = Tense.pastMoment; return selfinjures;

            case `organizationcreatedatdate`: tense = Tense.pastMoment; return createdAtDate;

            case `drugworkedonbyagent`: tense = Tense.pastMoment; reversion = true; return develops;

            case `agriculturalproductcutintogeometricshape`: return cutsInto;

            case `locationlocatedwithinlocation`: return atLocation;

            case `borninlocation`: return bornInLocation;

            default: break;
        }

        enum nellAgents = tuple(`object`, `thing`, `item`, `agent`, `organization`, `animal`, `scene`, `event`, `food`, `vegetable`,
                                `person`, `writer`, `creativework`, `building`, `school`, `bodypart`, `beverage`, `product`, `profession`);

        /* enum nellOldAgents = [`agriculturalproduct`, `chemical`, `drug`, `concept`, */
        /*                       `buildingfeature`, `buildingmaterial`, `furniture`, */
        /*                       `disease`, `bakedgood`, */
        /*                       `landscapefeatures`, */
        /*                       `economicsector`, */
        /*                       `vehicle`, `clothing`, `weapon`, */
        /*                       `vegetableproduction`, */
        /*                       `team`, `musician`, */
        /*                       `athlete`, */
        /*                       `journalist`, `artery`, `sportschool`, */
        /*                       `sportfans`, `sport`, */
        /*                       `protein`, */
        /*                       `bankbank`, // TODO bug in NELL? */
        /*                       `officebuildingroom`, */
        /*                       `farm`, `zipcode`, `street`, `mountain`, `lake`, `hospital`, `airport`, `bank`, `hotel`, `port`, `park`, `material`, */

        /*                       `skiarea`, `area`, `room`, `hall`, `island`, `city`, `river`, `country`, `office`, */
        /*                       `touristattraction`, `tourist`, `attraction`, `museum`, `aquarium`, `zoo`, `stadium`, */
        /*                       `newspaper`, `shoppingmall`, `restaurant`,  `bar`, `televisionstation`, `radiostation`, `transportation`, */
        /*                       `stateorprovince`, `state`, `province`, // TODO specialize from spatialregion */
        /*                       `headquarter`, */

        /*                       `geopoliticallocation`, */
        /*                       `geopoliticalorganization`, */
        /*                       `politicalorganization`, */

        /*                       `league`, `university`, `action`, `room`, */
        /*                       `mammal`, `arthropod`, `insect`, `vertebrate`, `invertebrate`, `fish`, `mollusk`, `amphibian`, `arachnids`, */
        /*                       `location`, `equipment`, `tool`, */
        /*                       `company`, `politician`, */
        /*                       `geometricshape`, */
        /*     ]; */

        S t = predicate;

        if (origin == Origin.nell)
        {
            t.skipOverShortestOf(nellAgents.expand);
            t.skipOverBackShortestOf(nellAgents.expand);
            if (t != predicate)
            {
                /* writeln("Skipped from ", predicate, " to ", t); */
            }
            t.skipOver(`that`);
        }

        if (t.skipOver(`not`))
        {
            reversion = true;
        }

        try
        {
            t = t.toLower;
        }
        catch (core.exception.UnicodeException e) { /* ok to not be able to downcase */ }

        switch (t)
        {
            case ``:            // TODO check original
            case `relatedto`:
            case `andother`:                                       return relatedTo;

            case `isa`:
            case `istypeof`:                                       return isA;

            case `ismultipleof`:                                   return multipleOf;

            case `of`:
            case `partof`:                                         return partOf;

            case `memberof`:
            case `belongsto`:                                      return memberOf;

            case `include`:
            case `including`:
            case `suchas`:                       reversion = true; return memberOf;

            case `topmemberof`:                                    return topMemberOf;

            case `participatein`:
            case `participatedin`: tense = Tense.pastMoment; return participatesIn;

            case `attends`:
            case `worksfor`:                                       return worksFor;
            case `writesforpublication`:                           return writesForPublication;
            case `inacademicfield`:                                return worksInAcademicField;

            case `ceoof`:                                          return ceoOf;
            case `plays`:                                          return plays;
            case `playsinstrument`:                                return playsInstrument;

            case `playsin`:
            case `playsinleague`:                                  return playsIn;

            case `playsfor`:
            case `playsforteam`:                                   return playsFor;

            case `competeswith`:
            case `playsagainst`:                                   return competesWith;

            case `contributesto`:                                  return contributesTo;
            case `contributedto`: tense = Tense.pastMoment; return contributesTo;

            case `has`:
            case `hasa`:                                           return hasA;
            case `usedfor`: reversion = true; tense = Tense.pastMoment; return uses;
            case `use`:
            case `uses`:                                           return uses;
            case `usestool`:                                       return usesTool;
            case `useslanguage`:                                   return usesLanguage;
            case `capableof`:                                      return capableOf;

                // spatial
            case `at`:
            case `atlocation`:                                     return atLocation;

            case `locatedin`:
            case `foundin`:
            case `headquarteredin`: tense = Tense.pastMoment; return atLocation;
            case `foundinroom`: tense = Tense.pastMoment; return inRoom;

            case `in`:
            case `existsat`:
            case `attractionof`:
            case `latitudelongitude`:
            case `incountry`:
            case `actsinlocation`:                                 return atLocation;
            case `grownin`:                                        return grownAtLocation;
            case `producedin`: tense = Tense.pastMoment; return producedAtLocation;
            case `movedto`: tense = Tense.pastMoment; return movedTo;

            case `locationof`:                   reversion = true; return atLocation;
            case `locatedwithin`:                                  return atLocation;
            case `home`:                                           return hasHome;

            case `hascontext`:                                     return hasContext;
            case `locatednear`:                                    return locatedNear;
            case `lieson`:                                         return locatedNear;
            case `isborderedby`:                                   return borderedBy;
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
            case `treats`:                                         return treats;

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
            case `haswebsite`:                                     return hasWebsite;
            case `hasofficialwebsite`:                             return hasOfficialWebsite;
            case `attribute`:                                      return hasAttribute;

            case `motivatedbygoal`:                                return motivatedByGoal;
            case `obstructedby`: tense = Tense.pastMoment; return obstructedBy;

            case `desires`:                                        return desires;
            case `desireof`:                     reversion = true; return desires;

            case `preyson`:
            case `eat`:                                            return eats;
            case `feedon`:                                         return eats;
            case `eats`:                                           return eats;
            case `causedesire`:                                    return causesDesire;
            case `causesdesire`:                                   return causesDesire;
            case `causeddesire`: tense = Tense.pastMoment; return causesDesire;

            case `buy`:
            case `buys`:
            case `buyed`: tense = Tense.pastMoment; return buys;
            case `acquires`:
            case `acquired`: tense = Tense.pastMoment; return acquires;
            case `affiliatedwith`: tense = Tense.pastMoment; return affiliatesWith;

            case `owns`:                                           return owns;

            case `hired`: tense = Tense.pastMoment; return hires;
            case `hiredBy`: reversion = true; tense = Tense.pastMoment; return hires;

            case `created`: tense = Tense.pastMoment; return creates;
            case `createdby`:                    reversion = true; return creates;
            case `develop`:                                        return develops;
            case `produces`:                                       return produces;

            case `receivesaction`:                                 return receivesAction;

            case `called`: tense = Tense.pastMoment; return synonymFor;
            case `synonym`:                                        return synonymFor;
            case `alsoknownas`:                                    return synonymFor;

            case `antonym`:                                        return antonymFor;
            case `retronym`:                                       return retronymFor;

            case `acronymhasname`:
            case `acronymfor`:                                     return acronymFor;

            case `derivedfrom`: tense = Tense.pastMoment; return derivedFrom;
            case `arisesfrom`:                                     return arisesFrom;
            case `emptiesinto`:                                    return emptiesInto;

            case `compoundderivedfrom`:                            return compoundDerivedFrom;
            case `etymologicallyderivedfrom`:                      return etymologicallyDerivedFrom;
            case `translationof`:                                  return translationOf;
            case `definedas`:                                      return definedAs;
            case `instanceof`:                                     return instanceOf;

            case `madeof`:
            case `madefrom`:
            case `comingfrom`:
            case `camefrom`:                                       return madeOf;

            case `madein`:                                         return madeAt;

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

            case `date`:
            case `atdate`:                                         return atTime;
            case `dissolvedatdate`: tense = Tense.pastMoment; return endedAtTime;
            case `proxyfor`:                                       return proxyFor;
            case `mutualproxyfor`:                                 return mutualProxyFor;

            case `hasjobposition`:                                 return hasJobPosition;

            case `graduated`:
            case `graduatedfrom`: tense = Tense.pastMoment; return graduatedFrom;

            case `involvedwith`: tense = Tense.pastMoment; return involvedWith;
            case `collaborateswith`:                               return collaboratesWith;

            case `contain`:
            case `contains`: reversion = true;                     return partOf;
            case `controls`:                                       return controls;
            case `leads`: reversion = true;                        return leaderOf;
            case `represents`:                                     return represents;
            case `chargedwithcrime`:                               return chargedWithCrime;

            case `wasbornin`:
            case `bornin`:
            case `birthdate`:                                      return bornIn;

            case `growingin`: return growsIn;

            case `marriedinyear`:
            case `marriedin`: tense = Tense.pastMoment; return marriedIn;

            case `diedin`: tense = Tense.pastMoment; return diedIn;
            case `diedatage`: tense = Tense.pastMoment; return diedAtAge;

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

            case `toattract`:                    reversion = true; return desires;

            case `hasexpert`:
            case `mlareaexpert`:                                   return hasExpert;

            case `cookedwith`: tense = Tense.pastMoment; return cookedWith;
            case `servedwith`: tense = Tense.pastMoment; return servedWith;
            case `togowith`:                                       return wornWith;

            default:
                /* dln(`Unknown relationString `, t, ` originally `, predicate); */
                                                                   return relatedTo;
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
bool defined(Origin origin) @safe @nogc pure nothrow { return origin != Origin.unknown; }

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

/** Check if $(D s) contains more than one word. */
bool isMultiWord(S)(S s) if (isSomeString!S)
{
    return s.canFind("_", " ") >= 1;
}

/** Main Knowledge Network.
*/
class Net(bool useArray = true,
          bool useRCString = true)
{
    import std.algorithm, std.range, std.path, std.array;
    import wordnet: WordNet;

    /** Ix Precision.
        Set this to $(D uint) if we get low on memory.
        Set this to $(D ulong) when number of link nodes exceed Ix.
    */
    alias Ix = uint; // TODO Change this to size_t when we have more _concepts and memory.

    /** Type-safe Index to $(D Link). */
    struct LinkIx
    {
        @safe @nogc pure nothrow:
        static LinkIx asUndefined() { return LinkIx(Ix.max); }
        bool defined() const { return this != LinkIx.asUndefined; }
        auto opCast(T : bool)() { return defined; }
    private:
        Ix _lIx = Ix.max;
    }

    /** Type-safe Index to $(D Concept). */
    struct ConceptIx
    {
        @safe @nogc pure nothrow:
        static ConceptIx asUndefined() { return ConceptIx(Ix.max); }
        bool defined() const { return this != ConceptIx.asUndefined; }
        auto opCast(T : bool)() { return defined; }
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
        auto opCast(T : bool)() { return defined; }
    private:
        ushort _cIx = ushort.max;
    }

    /** Concept Lemma. */
    struct Lemma
    {
        @safe @nogc pure nothrow:
        Words words;
        /* The following three are used to disambiguate different semantics
         * meanings of the same word in different languages. */
        HLang lang;
        WordKind wordKind;
        CategoryIx categoryIx;
        auto opCast(T : bool)() { return words !is null; }
    }

    /** Concept Node/Vertex. */
    struct Concept
    {
        /* @safe @nogc pure nothrow: */
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
             bool negation,
             Origin origin = Origin.unknown)
        {
            this._rel = rel;
            this._negation = negation;
            this._origin = origin;
        }

        this(Origin origin = Origin.unknown)
        {
            this._origin = origin;
        }

        /** Set ConceptNet5 Weight $(weigth). */
        void setCN5Weight(T)(T weight) if (isFloatingPoint!T)
        {
            // pack from 0..about10 to Weight to save memory
            _weight = cast(Weight)(weight.clamp(0,10)/10*Weight.max);
        }

        /** Set NELL Probability Weight $(weight). */
        void setNELLWeight(T)(T weight) if (isFloatingPoint!T)
        {
            // pack from 0..1 to Weight to save memory
            _weight = cast(Weight)(weight.clamp(0, 1)*Weight.max);
        }

        /** Get Normalized Link Weight. */
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

        enum anyCategory = CategoryIx(0); // reserve 0 for anyCategory (unknown)
        ushort _categoryIxCounter = 1; // 1 because 0 is reserved for anyCategory (unknown)

        size_t _multiWordConceptLemmaCount = 0; // number of concepts that whose lemma contain several words

        WordNet!(true, true) _wordnet;

        size_t[Rel.max + 1] _relCounts;
        size_t[Origin.max + 1] _linkSourceCounts;
        size_t[HLang.max + 1] _hlangCounts;
        size_t[WordKind.max + 1] _kindCounts;
        size_t _conceptStringLengthSum = 0;
        size_t _connectednessSum = 0;

        // is there a Phobos structure for this?
        real _weightMinCN5 = real.max;
        real _weightMaxCN5 = real.min_normal;
        real _weightSumCN5 = 0; // Sum of all link weights.

        real _weightMinNELL = real.max;
        real _weightMaxNELL = real.min_normal;
        real _weightSumNELL = 0; // Sum of all link weights.
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

    /** Try to Get Single Concept related to $(D word) in the interpretation
        (semantic context) $(D wordKind).
    */
    Concept[] conceptByWordsMaybe(S)(S words,
                                     HLang hlang = HLang.unknown,
                                     WordKind wordKind = WordKind.unknown,
                                     CategoryIx category = anyCategory) if (isSomeString!S)
    {
        typeof(return) concepts;
        auto lemma = Lemma(words, hlang, wordKind, category);
        if (lemma in _conceptIxByLemma) // if hashed lookup possible
        {
            concepts = [conceptByIx(_conceptIxByLemma[lemma])]; // use it
        }
        else
        {
            // try to lookup parts of word
            auto wordsSplit = _wordnet.findWordsSplit(words, [hlang]); // split in parts
            if (wordsSplit.length >= 2)
            {
                const wordsFixed = wordsSplit.joiner("_").to!S;
                /* dln("wordsFixed: ", wordsFixed, " in ", hlang, " as ", wordKind); */
                // TODO: Functionize
                auto lemmaFixed = Lemma(wordsFixed, hlang, wordKind, category);
                if (lemmaFixed in _conceptIxByLemma)
                {
                    concepts = [conceptByIx(_conceptIxByLemma[lemmaFixed])];
                }
            }
        }
        return concepts;
    }

    /** Get All Possible Concepts related to $(D word) in the interpretation
        (semantic context) $(D wordKind).
        If no wordKind given return all possible.
    */
    Concept[] conceptsByWords(S)(S words,
                                 HLang hlang = HLang.unknown,
                                 WordKind wordKind = WordKind.unknown,
                                 CategoryIx category = anyCategory) if (isSomeString!S)
    {
        typeof(return) concepts;
        if (hlang != HLang.unknown &&
            wordKind != WordKind.unknown &&
            category != anyCategory)
        {
            return conceptByWordsMaybe(words, hlang, wordKind, category);
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
                            foreach (ushort categoryCountGuess;
                                     0.._categoryIxCounter) // for each category including unknown
                            {
                                concepts ~= conceptByWordsMaybe(words,
                                                                hlangGuess,
                                                                wordKindGuess,
                                                                CategoryIx(categoryCountGuess));
                            }
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
        const maxCount = quick ? 100000 : size_t.max;

        // WordNet
        _wordnet = new WordNet!(true, true)([HLang.en]);

        // NELL
        readNELLFile("~/Knowledge/nell/NELL.08m.885.esv.csv".expandTilde
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
            auto wordsSplit = lemma.words.findSplit("_");
            if (!wordsSplit[1].empty) // TODO add implicit bool conversion to return of findSplit()
            {
                ++_multiWordConceptLemmaCount;
            }

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
                                   CategoryIx categoryIx,
                                   Origin origin)
    {
        return lookupOrStoreConcept(Lemma(words, lang, kind, categoryIx),
                                    Concept(words, lang, kind, categoryIx, origin));
    }

    /** Add Link from $(D src) to $(D dst) of type $(D rel) and weight $(D weight). */
    LinkIx lookupOrConnectLink(ConceptIx srcIx,
                               Rel rel,
                               ConceptIx dstIx,
                               Origin origin = Origin.unknown,
                               real weight = 1.0,
                               bool negation = false,
                               bool reversion = false)
    body
    {
        if (srcIx == dstIx) { return LinkIx.asUndefined; } // don't allow self-reference for now

        if (auto existingIx = areConnected(srcIx, rel, dstIx,
                                           negation, reversion)) // TODO warn about negation and reversion on existing rels
        {
            if (false)
            {
                dln("warning: Concepts ",
                    conceptByIx(srcIx), " and ",
                    conceptByIx(dstIx), " already related as ",
                    rel);
            }
            return existingIx;
        }

        auto lix  = LinkIx(cast(Ix)_links.length);
        auto link = Link(rel, negation, origin);

        link._srcIx = reversion ? dstIx : srcIx;
        link._dstIx = reversion ? srcIx : dstIx;

        assert(_links.length <= Ix.max); conceptByIx(link._srcIx).inIxes ~= lix; _connectednessSum++;
        assert(_links.length <= Ix.max); conceptByIx(link._dstIx).outIxes ~= lix; _connectednessSum++;

        ++_relCounts[rel];
        ++_linkSourceCounts[origin];

        if (origin == Origin.cn5)
        {
            link.setCN5Weight(weight);
            _weightSumCN5 += weight;
            _weightMinCN5 = min(weight, _weightMinCN5);
            _weightMaxCN5 = max(weight, _weightMaxCN5);
        }
        else
        {
            link.setNELLWeight(weight);
            _weightSumNELL += weight;
            _weightMinNELL = min(weight, _weightMinNELL);
            _weightMaxNELL = max(weight, _weightMaxNELL);
        }

        propagateLinkConcepts(link);

        /* if ((conceptByIx(link._srcIx).words == "wasp" && */
        /*      conceptByIx(link._dstIx).words == "arthropod") || */
        /*     (conceptByIx(link._dstIx).words == "wasp" && */
        /*      conceptByIx(link._srcIx).words == "arthropod")) */
        /* { */
        /*     dln("src: ", conceptByIx(link._srcIx).words, */
        /*         "dst: ", conceptByIx(link._dstIx).words, */
        /*         " rel:", rel, */
        /*         " origin:", origin, */
        /*         " negation:", negation, */
        /*         " reversion:", reversion); */
        /* } */

        _links ~= link; // TODO Avoid copying here

        return lix; // _links.back;
    }
    alias relate = lookupOrConnectLink;

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

        return lookupOrStoreConcept(word, hlang, wordKind, anyCategory, Origin.cn5);
    }

    import std.algorithm: splitter;

    /** Lookup Category by $(D name). */
    CategoryIx categoryByName(S)(S name) if (isSomeString!S)
    {
        auto categoryIx = anyCategory;
        if (name in _categoryIxByName)
        {
            categoryIx = _categoryIxByName[name];
        }
        else
        {
            assert(_categoryIxCounter != _categoryIxCounter.max);
            categoryIx._cIx = _categoryIxCounter++;
            _categoryNameByIx[categoryIx] = name;
            _categoryIxByName[name] = categoryIx;
        }
        return categoryIx;
    }

    /** Read NELL Entity from $(D part). */
    Tuple!(ConceptIx, string, LinkIx) readNELLEntity(S)(const S part)
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
        const categoryIx = categoryByName(categoryName);

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
                                             categoryIx,
                                             Origin.nell);

        return tuple(entityIx,
                     categoryName,
                     lookupOrConnectLink(entityIx,
                                         Rel.isA,
                                         lookupOrStoreConcept(categoryName,
                                                              lang,
                                                              kind,
                                                              categoryIx,
                                                              Origin.nell),
                                         Origin.nell, 1.0));
    }

    /** Read NELL CSV Line $(D line) at 0-offset line number $(D lnr). */
    void readNELLLine(R, N)(R line, N lnr)
    {
        auto rel = Rel.any;
        auto negation = false;
        auto reversion = false;
        auto tense = Tense.unknown;

        ConceptIx entityIx;
        ConceptIx valueIx;

        string entityCategoryName;
        char[] relationName;
        string valueCategoryName;

        auto ignored = false;
        real mainWeight;
        auto show = false;

        auto parts = line.splitter('\t');
        size_t ix;
        foreach (part; parts)
        {
            switch (ix)
            {
                case 0:
                    auto entity = readNELLEntity(part);
                    entityIx = entity[0];
                    entityCategoryName = entity[1];
                    if (!entityIx.defined) { return; }

                    break;
                case 1:
                    auto predicate = part.splitter(':');

                    if (predicate.front == "concept")
                        predicate.popFront; // ignore no-meaningful information
                    else
                        if (show) dln("TODO Handle non-concept predicate ", predicate);

                    relationName = predicate.front;

                    break;
                case 2:
                    if (relationName == "haswikipediaurl")
                    {
                        // TODO check if url is special compared to entity and
                        // store it only if it's not
                        ignored = true;
                    }
                    else
                    {
                        if (relationName == "latitudelongitude")
                        {
                            const loc = part.findSplit(",");
                            if (!loc[1].empty)
                            {
                                setLocation(entityIx,
                                            Location(loc[0].to!double,
                                                     loc[2].to!double));
                            }
                        }
                        else
                        {
                            auto value = readNELLEntity(part);
                            valueIx = value[0];
                            if (!valueIx.defined) { return; }
                            valueCategoryName = value[1];

                            relationName.skipOver(entityCategoryName); // strip dumb prefix
                            relationName.skipOverBack(valueCategoryName); // strip dumb suffix

                            rel = relationName.decodeRelation(entityCategoryName,
                                                              valueCategoryName,
                                                              Origin.nell,
                                                              negation, reversion, tense);
                        }
                    }
                    break;
                case 4:
                    mainWeight = part.to!real;
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

        if (entityIx.defined &&
            valueIx.defined)
        {
            auto mainLinkIx = lookupOrConnectLink(entityIx, rel, valueIx,
                                                  Origin.nell, mainWeight, negation, reversion);
        }

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
        if (!link._origin.defined)
        {
            // TODO prevent duplicate lookups to conceptByIx
            if (!conceptByIx(link._srcIx).origin.defined)
                conceptByIx(link._srcIx).origin = link._origin;
            if (!conceptByIx(link._dstIx).origin.defined)
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
        auto rel = Rel.any;
        auto negation = false;
        auto reversion = false;
        auto tense = Tense.unknown;

        ConceptIx src;
        ConceptIx dst;
        real weight;
        auto origin = Origin.unknown;

        auto parts = line.splitter('\t');
        size_t ix;
        foreach (part; parts)
        {
            switch (ix)
            {
                case 1:
                    // TODO Handle case when part matches /r/_wordnet/X
                    rel = part[3..$].decodeRelation(null, null, Origin.cn5,
                                                    negation, reversion, tense);
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

        if (src.defined &&
            dst.defined)
        {
            return lookupOrConnectLink(src, rel, dst, origin, weight, negation, reversion);
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
            if (++lnr >= maxCount) break;
        }
        writeln("Read NELL ", path, ` having `, lnr, ` lines`);
        showRelations;
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

        if (_weightSumCN5)
        {
            writeln(`- CN5 Weights Min,Max,Average: `, _weightMinCN5, ',', _weightMaxCN5, ',', cast(real)_weightSumCN5/_links.length);
        }
        if (_weightSumNELL)
        {
            writeln(`- NELL Weights Min,Max,Average: `, _weightMinNELL, ',', _weightMaxNELL, ',', cast(real)_weightSumNELL/_links.length);
        }

        writeln(`- Concept Count: `, _concepts.length);
        writeln(`- Multi Word Concept Count: `, _multiWordConceptLemmaCount);
        writeln(`- Link Count: `, _links.length);

        writeln(`- Concept Indexes by Lemma Count: `, _conceptIxByLemma.length);
        writeln(`- Concept String Length Average: `, cast(real)_conceptStringLengthSum/_concepts.length);
        writeln(`- Concept Connectedness Average: `, cast(real)_connectednessSum/2/_concepts.length);
    }

    /** Return Index to Link from $(D a) to $(D b) if present, otherwise LinkIx.max.
     */
    LinkIx areConnectedInOrder(ConceptIx a,
                               Rel rel,
                               ConceptIx b,
                               bool negation = false,
                               bool reversion = false)
    {
        const cA = conceptByIx(a); // TODO ref?
        foreach (ix; cA.inIxes)
        {
            const link = linkByIx(ix);
            if ((link._srcIx == b ||
                 link._dstIx == b) &&
                link._rel == rel &&
                link._negation == negation)
            {
                return ix;
            }
        }
        foreach (ix; cA.outIxes)
        {
            const link = linkByIx(ix);
            if ((link._srcIx == b ||
                 link._dstIx == b) &&
                link._rel == rel &&
                link._negation == negation)
            {
                return ix;
            }
        }
        return typeof(return).asUndefined;
    }

    /** Return Index to Link relating $(D a) to $(D b) in any direction if present, otherwise LinkIx.max.
     */
    LinkIx areConnected(ConceptIx a,
                        Rel rel,
                        ConceptIx b,
                        bool negation = false,
                        bool reversion = false)
    {
        return either(areConnectedInOrder(a, rel, b, negation, reversion),
                      areConnectedInOrder(b, rel, a, negation, reversion));
    }

    /** Return Index to Link relating if $(D a) and $(D b) if they are related. */
    LinkIx areConnected(in Lemma a,
                        Rel rel,
                        in Lemma b,
                        bool negation = false,
                        bool reversion = false)
    {
        if (a in _conceptIxByLemma && // both lemmas exist
            b in _conceptIxByLemma)
        {
            return areConnected(_conceptIxByLemma[a],
                                rel,
                                _conceptIxByLemma[b],
                                negation, reversion);
        }
        return typeof(return).asUndefined;
    }

    void showLinkRelation(Rel rel,
                          RelDir linkDir,
                          bool negation = false,
                          HLang lang = HLang.en)
    {
        write(` - `, rel.toHumanLang(linkDir, negation, lang), `: `);
    }

    void showConcept(in Concept concept, real weight)
    {
        if (concept.words) write(` `, concept.words.tr("_", " "));

        write(`(`); // open

        if (concept.lang != HLang.unknown)
        {
            write(concept.lang);
        }
        if (concept.lemmaKind != WordKind.unknown)
        {
            write("-", concept.lemmaKind);
        }

        writef(`:%.2f@%s),`, weight, concept.origin); // close
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
            writeln(` of sense `, concept.lemmaKind);

            // show forwards
            foreach (group; insByRelation(concept))
            {
                showLinkRelation(group.front[0]._rel, RelDir.forward);
                foreach (forwardLink, forwardConcept; group) // TODO sort on descending weights: .array.rsortBy!(a => a[0]._weight)
                {
                    showConcept(forwardConcept, forwardLink.normalizedWeight);
                }
                writeln();
            }

            // show backwards
            foreach (group; outsByRelation(concept))
            {
                showLinkRelation(group.front[0]._rel, RelDir.backward);
                foreach (backwardLink, backwardConcept; group) // TODO sort on descending weights: .array.rsortBy!(a => a[0]._weight)
                {
                    showConcept(backwardConcept, backwardLink.normalizedWeight);
                }
                writeln();
            }
        }

        if (normalizedLine == "palindrome")
        {
            foreach (palindromeConcept; _concepts.filter!(concept => concept.words.isPalindrome(3)))
            {
                showLinkConcept(palindromeConcept,
                                Rel.instanceOf,
                                real.infinity,
                                RelDir.backward);
            }
        }
        else if (normalizedLine.skipOver("anagramsof("))
        {
            auto split = normalizedLine.findSplitBefore(")");
            const arg = split[0];
            if (!arg.empty)
            {
                foreach (anagramConcept; anagramsOf(arg))
                {
                    showLinkConcept(anagramConcept,
                                    Rel.instanceOf,
                                    real.infinity,
                                    RelDir.backward);
                }
            }
        }
    }

    auto anagramsOf(S)(S word) if (isSomeString!S)
    {
        const lsWord = word.sorted; // letter-sorted word
        return _concepts.filter!(concept => (lsWord != concept.words && // don't include one-self
                                             lsWord == concept.words.sorted));
    }

    /** Get Synonyms of $(D word).
        Set withSameSyllableCount to true to get synonyms which can be used to
        help in translating songs with same rhythm.
     */
    void synonymsOf(S)(S word,
                       bool withSameSyllableCount = false) if (isSomeString!S)
    {
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
