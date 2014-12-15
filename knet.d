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

       BUG part_07.csv: lie <=Antonym=> stand_up. Not shown in prompt

       TODO Convert '_' to ' ' before storing Lemma

       TODO Make use of stealFront and stealBack

       TODO ansiktstvätt => facial_wash
       TODO biltvätt => findSplit [bil tvätt] => search("car wash") or search("car_wash") or search("carwash")
       TODO promote equal splits through weigthing sum_over_i(x[i].length^)2

       TODO Template on NodeData and rename Concept to Node. Instantiate with
       NodeData begin Concept and break out Concept outside.

       TODO Profile read
       TODO Use containers.HashMap
       TODO Call GC.disable/enable around construction and search.
   */

/* TODO
   spouse(X, Y)             :-  married(X, Y).
   husband(X, Y)            :-  male(X),       married(X, Y).
   wife(X, Y)               :-  female(X),     married(X, Y).
   father(X, Y)             :-  male(X),       parent(X, Y).
   mother(X, Y)             :-  female(X),     parent(X, Y).
   sibling(X, Y)            :-  father(Z, X),  father(Z, Y),
   mother(W, X),  mother(W, Y),    not(X = Y).
   brother(X, Y)            :-  male(X),       sibling(X, Y).
   sister(X, Y)             :-  female(X),     sibling(X, Y).
   grandparent(X, Z)        :-  parent(X, Y),  parent(Y, Z).
   grandfather(X, Z)        :-  male(X),       grandparent(X, Z).
   grandmother(X, Z)        :-  female(X),     grandparent(X, Z).
   grandchild(X, Z)         :-  grandparent(Z, X).
   grandson(X, Z)           :-  male(X),       grandchild(X, Z).
   granddaughter(X, Z)      :-  female(X),     grandchild(X, Z).
   ancestor(X,Y)            :-  parent(X,Y).
   ancestor(X,Y)           :-  parent(X, Z),  ancestor(Z, Y).
   child(Y, X)              :-  parent(X, Y).
   son(Y, X)                :-  male(Y),       child(Y, X).
   daughter(Y, X)           :-  female(Y),     child(Y, X).
   descendent(Y, X)         :-  ancestor(X, Y).
   auntOrUncle(X, W)        :-  sibling(X, Y), parent(Y, W).
   auntOrUncle(X, Z)        :-  married(X,Y),  sibling(Y,W),    parent(W,Z).
   uncle(X, W)              :-  male(X),       auntOrUncle(X, W).
   aunt(X, W)               :-  female(X),     auntOrUncle(X, W).
   cousin(X, Y)             :-  parent(Z, X),  auntOrUncle(Z, Y).
   nieceOrNephew(X, Y)      :-  parent(Z, X),  sibling(Z, Y).
   nephew(X, Y)             :-  male(X),       nieceOrNephew(X, Y).
   niece(X, Y)              :-  female(X),     nieceOrNephew(X, Y).
   greatGrandParent(X, Z)   :-  parent(X, Y),  grandparent(Y, Z).
   greatGrandFather(X, Z)   :-  male(X),       greatGrandParent(X, Z).
   greatGrandMother(X, Z)   :-  female(X),     greatGrandParent(X, Z).
   greatGrandChild(X, Z)    :-  child(X, Y),   grandchild(Y, Z).
   greatgrandson(X, Z)      :-  male(X),       greatGrandChild(X, Z).
   greatgranddaughter(X, Z) :-  female(X),     greatGrandChild(X, Z).
   parentInLaw(X, Y)        :-  married(Y, Z), parent(X, Z).
   fatherInLaw(X, Y)        :-  male(X),       parentInLaw(X, Y).
   motherInLaw(X, Y)        :-  female(X),     parentInLaw(X, Y).
   siblingInLaw(X, Y)       :-  married(Y, Z), sibling(X, Z).
   brotherInLaw(X, Y)       :-  male(X),       siblingInLaw(X, Y).
   sisterInLaw(X, Y)        :-  female(X),     siblingInLaw(X, Y).
   childInLaw(X, Y)         :-  married(X, Z), child(Z, Y).
   sonInLaw(X, Y)           :-  male(X),       childInLaw(X, Y).
   daughterInLaw(X, Y)      :-  female(X),     childInLaw(X, Y).
*/

module knet;

/* version = msgpack; */

import core.exception: UnicodeException;
import std.traits: isSomeString, isFloatingPoint, EnumMembers, isDynamicArray, isIterable;
import std.conv: to, emplace;
import std.stdio: writeln, File, write, writef;
import std.algorithm: findSplit, findSplitBefore, findSplitAfter, groupBy, sort, skipOver, filter, array, canFind, count;
import std.container: Array;
import std.string: tr, toLower, toUpper;
import std.uni: isWhite, toLower;
import std.utf: byDchar, UTFException;
import std.typecons: Nullable, Tuple, tuple;

import algorithm_ex: isPalindrome, either;
import range_ex: stealFront, stealBack, ElementType;
import traits_ex: isSourceOf, isSourceOfSomeString, isIterableOf;
import sort_ex: sortBy, rsortBy, sorted;
import skip_ex: skipOverBack, skipOverShortestOf, skipOverBackShortestOf;
import stemming;
import dbg;
import grammars;
import rcstring;
import krels;
import combinations;
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

/** Decode Relation $(D predicate) together with its possible $(D negation) and
    $(D reversion). */
Rel decodeRelationPredicate(S)(S predicate,
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

/** Knowledge Origin. */
enum Origin:ubyte
{
    unknown, any = unknown,
    cn5,

    dbpedia,
    dbpedia37,
    dbpedia39umbel,
    dbpediaEn,

    wordnet,
    wordnet30,

    verbosity,
    wiktionary,
    nell,
    yago,
    globalmind,

    manual,
}

bool defined(Origin origin) @safe @nogc pure nothrow { return origin != Origin.unknown; }

string toNice(Origin origin) @safe pure
{
    with (Origin)
        final switch (origin)
        {
            case unknown: return "Unknown";
            case cn5: return "CN5";
            case dbpedia: return "DBpedia";
            case dbpedia37: return "DBpedia37";
            case dbpedia39umbel: return "DBpedia39Umbel";
            case dbpediaEn: return "DBpediaEnglish";
            case wordnet: return "WordNet";
            case wordnet30: return "WordNet30";
            case verbosity: return "Verbosity";
            case wiktionary: return "Wiktionary";
            case nell: return "NELL";
            case yago: return "Yago";
            case globalmind: return "GlobalMind";
            case manual: return "Manual";
        }
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

    alias NWeight = real; // normalized weight

    /** Ix Precision.
        Set this to $(D uint) if we get low on memory.
        Set this to $(D ulong) when number of link nodes exceed Ix.
    */
    alias Ix = uint; // TODO Change this to size_t when we have more Concepts and memory.
    enum nullIx = Ix.max >> 1;

    enum expressionWordSeparator = "_"; // Lemma Expression Separator.

    /** Type-Safe Directed Reference to $(D T). */
    struct Ref(T)
    {
        import bitop_ex: setTopBit, getTopBit, resetTopBit;
        @safe @nogc pure nothrow:

        alias type = T;

        this(Ix ix_ = nullIx,
             bool reversion = true) in { assert(ix_ <= nullIx); }
        body
        {
            _ix = ix_;
            if (reversion) { _ix.setTopBit; }
        }

        this(Ref rhs, RelDir dir)
        {
            this._ix = rhs.ix;

            // TODO functionize to setDir()
            if (dir == RelDir.backward)
            {
                _ix.setTopBit;
            }
            else if (dir == RelDir.forward)
            {
                _ix.resetTopBit;
            }
        }

        Ref forward() { return Ref(this, RelDir.forward); }
        Ref backward() { return Ref(this, RelDir.backward); }

        static const(Ref) asUndefined() { return Ref(nullIx); }
        bool defined() const { return this.ix != nullIx; }
        auto opCast(U : bool)() { return defined(); }

        /** Get Index. */
        const(Ix) ix() const { Ix ixCopy = _ix; ixCopy.resetTopBit; return ixCopy; }

        /** Get Direction. */
        const(RelDir) dir() const { return _ix.getTopBit ? RelDir.backward : RelDir.forward; }
    private:
        Ix _ix = nullIx;
    }

    /// Reference to Node.
    alias NodeRef = Ref!Node;

    /// Reference to Link.
    alias LinkRef = Ref!Link;

    /** Expression (String). */
    static if (useRCString) { alias Expr = RCXString!(immutable char, 24-1); }
    else                    { alias Expr = immutable string; }

    /// References to Nodes.
    static if (useArray) { alias NodeRefs = Array!NodeRef; }
    else                 { alias NodeRefs = NodeRef[]; }

    /// References to Links.
    static if (useArray) { alias LinkRefs = Array!LinkRef; }
    else                 { alias LinkRefs = LinkRef[]; }

    /** Ontology Category Index (currently from NELL). */
    struct CategoryIx
    {
        @safe @nogc pure nothrow:
        static CategoryIx asUndefined() { return CategoryIx(0); }
        bool defined() const { return this != CategoryIx.asUndefined; }
        /* auto opCast(T : bool)() { return defined; } */
    private:
        ushort _ix = 0;
    }

    /** Node Concept Lemma. */
    struct Lemma
    {
        @safe @nogc pure nothrow:
        Expr expr;
        /* The following three are used to disambiguate different semantics
         * meanings of the same word in different languages. */
        Lang lang;
        Sense sense;
        CategoryIx categoryIx;
        /* auto opCast(T : bool)() { return expr !is null; } */
    }

    /** Concept Node/Vertex. */
    struct Node
    {
        /* @safe @nogc pure nothrow: */
        this(in Lemma lemma,
             Origin origin = Origin.unknown,
             LinkRefs links = LinkRefs.init)
        {
            this.lemma = lemma;
            this.origin = origin;
            this.links = links;
        }
    private:
        LinkRefs links;
        const(Lemma) lemma;
        Origin origin;
    }

    /** Get Links Refs of $(D node) with direction $(D dir). */
    auto linkRefsOf(in Node node,
                    RelDir dir = RelDir.any,
                    Rel rel = Rel.any,
                    bool negation = false)
    {
        return node.links[].filter!(linkRef => (dir.of(RelDir.any, linkRef.dir) &&  // TODO functionize to match(RelDir, RelDir)
                                                (linkAt(linkRef).rel == rel ||
                                                 linkAt(linkRef).rel.specializes(rel)) &&// TODO functionize to match(Rel, Rel)
                                                linkAt(linkRef).negation == negation));
    }

    /** Many-Nodes-to-Many-Nodes Link (Edge).
     */
    struct Link
    {
        alias PWeight = ubyte; // link weight pack type
        alias WeightHistogram = size_t[PWeight];

        /* @safe @nogc pure nothrow: */

        this(NodeRef srcRef,
             Rel rel,
             NodeRef dstRef,
             bool negation,
             Lang lang = Lang.unknown,
             Origin origin = Origin.unknown) in { assert(srcRef.defined && dstRef.defined); }
        body
        {
            this.actors ~= srcRef.backward;
            this.actors ~= dstRef.forward;
            this.rel = rel;
            this.negation = negation;
            this.origin = origin;
        }

        this(Origin origin = Origin.unknown)
        {
            this.origin = origin;
        }

        /** Set ConceptNet5 PWeight $(weight). */
        void setCN5Weight(T)(T weight) if (isFloatingPoint!T)
        {
            // pack from 0..about10 to PWeight to save memory
            packedWeight = cast(PWeight)(weight.clamp(0,10)/10*PWeight.max);
        }

        /** Set NELL Probability PWeight $(weight). */
        void setNELLWeight(T)(T weight) if (isFloatingPoint!T)
        {
            // pack from 0..1 to PWeight to save memory
            packedWeight = cast(PWeight)(weight.clamp(0, 1)*PWeight.max);
        }

        /** Set Manual Probability PWeight $(weight). */
        void setManualWeight(T)(T weight) if (isFloatingPoint!T)
        {
            // pack from 0..1 to PWeight to save memory
            packedWeight = cast(PWeight)(weight.clamp(0, 1)*PWeight.max);
        }

        /** Get Normalized Link PWeight. */
        @property NWeight normalizedWeight() const
        {
            return ((cast(typeof(return))packedWeight)/
                    (cast(typeof(return))PWeight.max));
        }

    private:
        NodeRefs actors;

        PWeight packedWeight;

        Rel rel;
        bool negation; /// relation negation

        Lang lang;

        Origin origin;
    }

    auto ins(in Link link) { return link.actors[].filter!(nodeRef =>
                                                          nodeRef.dir() == RelDir.backward); }
    auto outs(in Link link) { return link.actors[].filter!(nodeRef =>
                                                           nodeRef.dir() == RelDir.forward); }

    pragma(msg, `Expr.sizeof: `, Expr.sizeof);
    pragma(msg, `Lemma.sizeof: `, Lemma.sizeof);
    pragma(msg, `Node.sizeof: `, Node.sizeof);
    pragma(msg, `LinkRefs.sizeof: `, LinkRefs.sizeof);
    pragma(msg, `NodeRefs.sizeof: `, NodeRefs.sizeof);
    pragma(msg, `Link.sizeof: `, Link.sizeof);

    /* static if (useArray) { alias Nodes = Array!Node; } */
    /* else                 { alias Nodes = Node[]; } */
    alias Nodes = Node[]; // no need to use std.container.Array here

    static if (false) { alias Lemmas = Array!Lemma; }
    else              { alias Lemmas = Lemma[]; }

    static if (useArray) { alias Links = Array!Link; }
    else                 { alias Links = Link[]; }

    private
    {
        NodeRef[Lemma] nodeRefByLemma;
        Nodes allNodes;
        Links allLinks;

        Lemmas[string] lemmasByExpr;

        string[CategoryIx] categoryNameByIx; /** Ontology Category Names by Index. */
        CategoryIx[string] categoryIxByName; /** Ontology Category Indexes by Name. */

        enum anyCategory = CategoryIx.asUndefined; // reserve 0 for anyCategory (unknown)
        ushort categoryIxCounter = CategoryIx.asUndefined._ix + 1; // 1 because 0 is reserved for anyCategory (unknown)

        size_t multiWordNodeLemmaCount = 0; // number of nodes that whose lemma contain several expr

        WordNet!(true, true) wordnet;

        size_t[Rel.max + 1] linkCountsByRel; /// Link Counts by Relation Type.
        size_t symmetricRelCount = 0; /// Symmetric Relation Count.
        size_t transitiveRelCount = 0; /// Transitive Relation Count.
        size_t[Origin.max + 1] linkSourceCounts;
        size_t[Lang.max + 1] hlangCounts;
        size_t[Sense.max + 1] kindCounts;
        size_t nodeStringLengthSum = 0;
        size_t connectednessSum = 0;

        size_t exprWordCountSum = 0;

        // TODO Group to WeightsStatistics
        NWeight weightMinCN5 = NWeight.max;
        NWeight weightMaxCN5 = NWeight.min_normal;
        NWeight weightSumCN5 = 0; // Sum of all link weights.
        Link.WeightHistogram packedWeightHistogramCN5; // CN5 Packed Weight Histogram

        // TODO Group to WeightsStatistics
        NWeight weightMinNELL = NWeight.max;
        NWeight weightMaxNELL = NWeight.min_normal;
        NWeight weightSumNELL = 0; // Sum of all link weights.
        Link.WeightHistogram packedWeightHistogramNELL; // NELL Packed Weight Histogram
    }

    @safe pure nothrow
    {
        ref inout(Link) linkAt(LinkRef linkRef) inout { return allLinks[linkRef.ix]; }
        ref inout(Node) nodeAt(NodeRef cref) inout @nogc { return allNodes[cref.ix]; }
        alias linkByRef = linkAt;
        alias nodeByRef = nodeAt;
    }

    Nullable!Node nodeByLemmaMaybe(in Lemma lemma)
    {
        if (lemma in nodeRefByLemma)
        {
            return typeof(return)(nodeAt(nodeRefByLemma[lemma]));
        }
        else
        {
            return typeof(return).init;
        }
    }

    /** Try to Get Single Node related to $(D word) in the interpretation
        (semantic context) $(D sense).
    */
    NodeRefs nodeRefsByLemmaDirect(S)(S expr,
                                      Lang lang,
                                      Sense sense,
                                      CategoryIx category) if (isSomeString!S)
    {
        typeof(return) nodes;
        auto lemma = Lemma(expr, lang, sense, category);
        if (lemma in nodeRefByLemma) // if hashed lookup possible
        {
            nodes ~= nodeRefByLemma[lemma]; // use it
        }
        else
        {
            // try to lookup parts of word
            auto wordsSplit = wordnet.findWordsSplit(expr, [lang]); // split in parts
            if (wordsSplit.length >= 2)
            {
                const wordsFixed = wordsSplit.joiner("_").to!S;
                /* dln("wordsFixed: ", wordsFixed, " in ", lang, " as ", sense); */
                // TODO: Functionize
                auto lemmaFixed = Lemma(wordsFixed, lang, sense, category);
                if (lemmaFixed in nodeRefByLemma)
                {
                    nodes ~= nodeRefByLemma[lemmaFixed];
                }
            }
        }
        return nodes;
    }

    /** Get All Node Indexes Indexed by a Lemma having expr $(D expr). */
    auto nodeRefsOf(S)(S expr) if (isSomeString!S)
    {
        return lemmasOf(expr).map!(lemma => nodeRefByLemma[lemma]);
    }

    /** Get All Possible Lemmas related to $(D word).
     */
    Lemmas lemmasOf(S)(S expr) if (isSomeString!S)
    {
        return expr in lemmasByExpr ? lemmasByExpr[expr] : [];
    }

    /** Learn $(D Lemma) of $(D expr).
     */
    void learnLemma(S)(S expr, Lemma lemma) if (isSomeString!S)
    {
        if (expr in lemmasByExpr)
        {
            if (!lemmasByExpr[expr][].canFind(lemma)) // TODO Make use of binary search
            {
                lemmasByExpr[expr] ~= lemma;
            }
        }
        else
        {
            static if (!isDynamicArray!Lemmas)
            {
                lemmasByExpr[expr] = Lemmas.init; // TODO fix std.container.Array
            }
            lemmasByExpr[expr] ~= lemma;
        }
    }

    /** Get All Possible Nodes related to $(D word) in the interpretation
        (semantic context) $(D sense).
        If no sense given return all possible.
    */
    NodeRefs nodeRefsOf(S)(S expr,
                               Lang lang,
                               Sense sense,
                               CategoryIx category = anyCategory) if (isSomeString!S)
    {
        typeof(return) nodes;

        if (lang != Lang.unknown &&
            sense != Sense.unknown &&
            category != anyCategory) // if exact Lemma key can be used
        {
            return nodeRefsByLemmaDirect(expr, lang, sense, category); // fast hash lookup
        }
        else
        {
            nodes = NodeRefs(nodeRefsOf(expr).array); // TODO avoid allocations
        }

        if (nodes.empty)
        {
            /* writeln(`Lookup translation of individual expr; bil_tvätt => car-wash`); */
            /* foreach (word; expr.splitter(`_`)) */
            /* { */
            /*     writeln(`Translate word "`, word, `" from `, lang, ` to English`); */
            /* } */
        }
        return nodes;
    }

    /** Construct Network */
    this(string dirPath)
    {
        const quick = true;
        const maxCount = quick ? 200000 : size_t.max;

        // WordNet
        wordnet = new WordNet!(true, true)([Lang.en]);

        // Learn trusthful things before untrusted machine generated data is read
        learnTrustfulThings();

        // NELL
        readNELLFile("~/Knowledge/nell/NELL.08m.890.esv.csv".expandTilde
                                                            .buildNormalizedPath,
                     10000);

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

    /** Learn Trustful Thing.
     */
    void learnTrustfulThings()
    {
        learnEnglishComputerAcronyms();

        learnEnglishIrregularVerbs();
        learnUncountableNouns(Lang.en,
                              ["music", "art", "love", "happiness",
                               "math", "physics",
                               "advice", "information", "news",
                               "furniture", "luggage",
                               "rice", "sugar", "butter", // generalize to seed (grödor) or substance
                               "water", "rain", // generalize to fluids
                               "coffee", "wine", "beer", "whiskey", "milk", // generalize to beverage
                               "electricity", "gas", "power"
                               "money", "currency",
                               "crockery", "cutlery",
                               "luggage", "baggage", "glass", "sand"]);
        learnUncountableNouns(Lang.sv,
                              ["apotek", "hypotek", "bibliotek", "fonotek", "filmotek",
                               "pinaotek", "videotek", "diskotek", "mediatek", "datortek", "glyptotek"]);

        learnEnglishReversions();

        learnSwedishIrregularVerbs();
    }

    void learnEnglishReversions()
    {
        // TODO Copy all from krels.toHuman
        learnEnglishReversion("is a", "can be");
        learnEnglishReversion("leads to", "can infer");
        learnEnglishReversion("is part of", "contains");
        learnEnglishReversion("is member of", "has member");
    }

    /** Learn English Reversion.
     */
    LinkRef[] learnEnglishReversion(S)(S forward,
                                       S backward) if (isSomeString!S)
    {
        const lang = Lang.en;
        const category = CategoryIx.asUndefined;
        const origin = Origin.manual;
        auto all = [tryStore(forward, lang, Sense.verbInfinitive, category, origin),
                    tryStore(backward, lang, Sense.verbPastParticiple, category, origin)];
        return connectMtoM(Rel.reversionOf, all.filter!(a => a.defined), lang, origin);
    }

    /** Learn English Irregular Verb.
     */
    LinkRef[] learnEnglishIrregularVerb(S1, S2, S3)(S1 infinitive,
                                                    S2 past,
                                                    S3 pastParticiple)
    {
        const lang = Lang.en;
        const category = CategoryIx.asUndefined;
        const origin = Origin.manual;
        NodeRef[] all;
        all ~= tryStore(infinitive, lang, Sense.verbInfinitive, category, origin);
        all ~= tryStore(past, lang, Sense.verbPast, category, origin);
        all ~= tryStore(pastParticiple, lang, Sense.verbPastParticiple, category, origin);
        return connectMtoM(Rel.verbForm, all.filter!(a => a.defined), lang, origin);
    }

    /** Learn English Acronym.
     */
    LinkRef learnEnglishAcronym(S)(S acronym,
                                   S expr,
                                   NWeight weight = 1.0,
                                   Sense sense = Sense.noun,
                                   Origin origin = Origin.manual) if (isSomeString!S)
    {
        const lang = Lang.en;
        const category = CategoryIx.asUndefined;
        // TODO should we store acronym in lowercase or not?
        return connect(store(acronym.toLower, lang, Sense.nounAcronym, category, origin),
                       Rel.acronymFor,
                       store(expr.toLower, lang, sense, category, origin),
                       lang, origin, weight);
    }

    /** Learn English Computer Acronyms.
     */
    void learnEnglishComputerAcronyms()
    {
        // TODO Context: Computer
        learnEnglishAcronym("IETF", "Internet Engineering Task Force");
        learnEnglishAcronym("RFC", "Request For Comments");
        learnEnglishAcronym("FYI", "For Your Information");
        learnEnglishAcronym("BCP", "Best Current Practise");
        learnEnglishAcronym("LGTM", "Looks Good To Me");

        learnEnglishAcronym("AJAX", "Asynchronous Javascript And XML", 1.0); // 5-star
        learnEnglishAcronym("AJAX", "Associação De Jogadores Amadores De Xadrez", 0.2); // 1-star

        // TODO Context: (Orakel) Computer
        learnEnglishAcronym("3NF", "Third Normal Form");
        learnEnglishAcronym("ACID", "Atomicity, Consistency, Isolation, and Durability");
        learnEnglishAcronym("ACL", "Access Control List");
        learnEnglishAcronym("ACLs", "Access Control Lists");
        learnEnglishAcronym("ADDM", "Automatic Database Diagnostic Monitor");
        learnEnglishAcronym("ADR", "Automatic Diagnostic Repository");
        learnEnglishAcronym("ASM", "Automatic Storage Management");
        learnEnglishAcronym("AWR", "Automatic Workload Repository");
        learnEnglishAcronym("AWT", "asynchronous writethrough");
        learnEnglishAcronym("BGP", "basic graph pattern");
        learnEnglishAcronym("BLOB", "Binary Large Object");
        learnEnglishAcronym("CBC", "Cipher Block Chaining");
        learnEnglishAcronym("CCA", "Control Center Agent");
        learnEnglishAcronym("CDATA", "character data");
        learnEnglishAcronym("CDS", "Cell Directory Services");
        learnEnglishAcronym("CFS", "Cluster File System");
        learnEnglishAcronym("CIDR", "Classless Inter-Domain Routing");
        learnEnglishAcronym("CLOB", "character large object");
        learnEnglishAcronym("CMADMIN", "Oracle Connection Manager Administration");
        learnEnglishAcronym("CMGW", "Oracle Connection Manager gateway");
        learnEnglishAcronym("COM", "Component Object Model");
        learnEnglishAcronym("CORBA", "Common Object Request Broker API");
        learnEnglishAcronym("CORE", "Common Oracle Runtime Environment");
        learnEnglishAcronym("CRL", "certificate revocation list");
        learnEnglishAcronym("CRSD", "Cluster Ready Services Daemon");
        learnEnglishAcronym("CSS", "Cluster Synchronization Services");
        learnEnglishAcronym("CT", "Code Template");
        learnEnglishAcronym("CVU", "Cluster Verification Utility");
        learnEnglishAcronym("CWM", "Common Warehouse Metadata");
        learnEnglishAcronym("DAS", "Direct Attached Storage");
        learnEnglishAcronym("DBA", "database administrator");
        learnEnglishAcronym("DBMS", "database management system");
        learnEnglishAcronym("DBPITR", "database point-in-time recovery");
        learnEnglishAcronym("DBW", "database writer");
        learnEnglishAcronym("DCE", "Distributed Computing Environment");
        learnEnglishAcronym("DCOM", "Distributed Component Object Model");
        learnEnglishAcronym("DDL LCR", "DDL Logical Change Record");
        learnEnglishAcronym("DHCP", "Dynamic Host Configuration Protocol");
        learnEnglishAcronym("DICOM", "Digital Imaging and Communications in Medicine");
        learnEnglishAcronym("DIT", "directory information tree");
        learnEnglishAcronym("DLL", "dynamic-link library");
        learnEnglishAcronym("DN", "distinguished name");
        learnEnglishAcronym("DNS", "Domain Name System");
        learnEnglishAcronym("DOM", "Document Object Model");
        learnEnglishAcronym("DTD", "Document Type Definition");
        learnEnglishAcronym("DTP", "Distributed Transaction Processing");
        learnEnglishAcronym("Dnnn", "dispatcher process");
        learnEnglishAcronym("DoS", "denial-of-service");
        learnEnglishAcronym("EJB", "Enterprise JavaBean");
        learnEnglishAcronym("EMCA", "Enterprise Manager Configuration Assistant");
        learnEnglishAcronym("ETL", "Extraction, Transformation, and Loading");
        learnEnglishAcronym("EVM", "Event Manager");
        learnEnglishAcronym("EVMD", "Event Manager Daemon");
        learnEnglishAcronym("FAN", "Fast Application Notification");
        learnEnglishAcronym("FIPS", "Federal Information Processing Standard");
        learnEnglishAcronym("GAC", "Global Assembly Cache");
        learnEnglishAcronym("GCS", "Global Cache Service");
        learnEnglishAcronym("GDS", "Global Directory Service");
        learnEnglishAcronym("GES", "Global Enqueue Service");
        learnEnglishAcronym("GIS", "geographic information system");
        learnEnglishAcronym("GNS", "Grid Naming Service");
        learnEnglishAcronym("GNSD", "Oracle Grid Naming Service Daemon");
        learnEnglishAcronym("GPFS", "General Parallel File System");
        learnEnglishAcronym("GSD", "Global Services Daemon");
        learnEnglishAcronym("GV$", "global dynamic performance views");
        learnEnglishAcronym("HACMP", "High Availability Cluster Multi-Processing");
        learnEnglishAcronym("HBA", "host bus adapter");
        learnEnglishAcronym("IDE", "Integrated Development Environment");
        learnEnglishAcronym("IPC", "Interprocess Communication");
        learnEnglishAcronym("IPv4", "IP Version 4");
        learnEnglishAcronym("IPv6", "IP Version 6");
        learnEnglishAcronym("ITL", "interested transaction list");
        learnEnglishAcronym("J2EE", "Java 2 Platform, Enterprise Edition");
        learnEnglishAcronym("JAXB", "Java Architecture for XML Binding");
        learnEnglishAcronym("JAXP", "Java API for XML Processing");
        learnEnglishAcronym("JDBC", "Java Database Connectivity");
        learnEnglishAcronym("JDK", "Java Developer's Kit");
        learnEnglishAcronym("JNDI","Java Naming and Directory Interface");
        learnEnglishAcronym("JRE","Java Runtime Environment");
        learnEnglishAcronym("JSP","JavaServer Pages");
        learnEnglishAcronym("JSR","Java Specification Request");
        learnEnglishAcronym("JVM","Java Virtual Machine");
        learnEnglishAcronym("KDC","Key Distribution Center");
        learnEnglishAcronym("KWIC", "Key Word in Context");
        learnEnglishAcronym("LCR", "logical change record");
        learnEnglishAcronym("LDAP", "Lightweight Directory Access Protocol");
        learnEnglishAcronym("LDIF", "Lightweight Directory Interchange Format");
        learnEnglishAcronym("LGWR", "log writer");
        learnEnglishAcronym("LMD", "Global Enqueue Service Daemon");
        learnEnglishAcronym("LMON", "Global Enqueue Service Monitor");
        learnEnglishAcronym("LMSn", "Global Cache Service Processes");
        learnEnglishAcronym("LOB", "large object");
        learnEnglishAcronym("LOBs", "Large Objects");
        learnEnglishAcronym("LRS Segment", "Geometric Segment");
        learnEnglishAcronym("LUN", "Logical Unit Number");
        learnEnglishAcronym("LUNs", "logical unit numbers");
        learnEnglishAcronym("LVM", "logical volume manager");
        learnEnglishAcronym("MAPI", "messaging application programming interface");
        learnEnglishAcronym("MBR", "Master Boot Record");
        learnEnglishAcronym("MS DTC", "Microsoft Distributed Transaction Coordinator");
        learnEnglishAcronym("MTTR", "Mean Time To Recover");
        learnEnglishAcronym("NAS", "Network Attached Storage");
        learnEnglishAcronym("NCLOB", "National Character Large Object");
        learnEnglishAcronym("NFS", "Network File System");
        learnEnglishAcronym("NI", "Network Interface");
        learnEnglishAcronym("NIC", "Network Interface Card");
        learnEnglishAcronym("NIS", "Network Information Service");
        learnEnglishAcronym("NIST", "National Institute of Standards and Technology");
        learnEnglishAcronym("NPI", "Network Program Interface");
        learnEnglishAcronym("NS", "Network Session");
        learnEnglishAcronym("NTP", "Network Time Protocol");
        learnEnglishAcronym("OASIS", "Organization for the Advancement of Structured Information");
        learnEnglishAcronym("OCFS", "Oracle Cluster File System");
        learnEnglishAcronym("OCI", "Oracle Call Interface");
        learnEnglishAcronym("OCR", "Oracle Cluster Registry");
        learnEnglishAcronym("ODBC", "Open Database Connectivity");
        learnEnglishAcronym("ODBC INI", "ODBC Initialization File");
        learnEnglishAcronym("ODP NET", "Oracle Data Provider for .NET");
        learnEnglishAcronym("OFA", "optimal flexible architecture");
        learnEnglishAcronym("OHASD", "Oracle High Availability Services Daemon");
        learnEnglishAcronym("OIFCFG", "Oracle Interface Configuration Tool");
        learnEnglishAcronym("OLM", "Object Link Manager");
        learnEnglishAcronym("OLTP", "online transaction processing");
        learnEnglishAcronym("OMF", "Oracle Managed Files");
        learnEnglishAcronym("ONS", "Oracle Notification Services");
        learnEnglishAcronym("OO4O", "Oracle Objects for OLE");
        learnEnglishAcronym("OPI", "Oracle Program Interface");
        learnEnglishAcronym("ORDBMS", "object-relational database management system");
        learnEnglishAcronym("OSI", "Open Systems Interconnection");
        learnEnglishAcronym("OUI", "Oracle Universal Installer");
        learnEnglishAcronym("OraMTS", "Oracle Services for Microsoft Transaction Server");
        learnEnglishAcronym("Oracle ASM", "Oracle Automatic Storage Management");
        learnEnglishAcronym("Oracle RAC", "Oracle Real Application Clusters");
        learnEnglishAcronym("PCDATA", "Parsed Character Data");
        learnEnglishAcronym("PGA", "Program Global Area");
        learnEnglishAcronym("PKI", "Public Key Infrastructure");
        learnEnglishAcronym("RAID", "Redundant Array of Inexpensive Disks");
        learnEnglishAcronym("RDBMS", "Relational Database Management System");
        learnEnglishAcronym("RDN", "Relative Distinguished Name");
        learnEnglishAcronym("RM", "Resource Manager");
        learnEnglishAcronym("RMAN", "Recovery Manager");
        learnEnglishAcronym("ROI", "Return On Investment");
        learnEnglishAcronym("RPO", "Recovery Point Objective");
        learnEnglishAcronym("RTO", "Recovery Time Objective");
        learnEnglishAcronym("SAN", "Storage Area Network");
        learnEnglishAcronym("SAX", "Simple API for XML");
        learnEnglishAcronym("SCAN", "Single Client Access Name");
        learnEnglishAcronym("SCN", "System Change Number");
        learnEnglishAcronym("SCSI", "Small Computer System Interface");
        learnEnglishAcronym("SDU", "Session Data Unit");
        learnEnglishAcronym("SGA", "System Global Area");
        learnEnglishAcronym("SGML", "Structured Generalized Markup Language");
        learnEnglishAcronym("SHA", "Secure Hash Algorithm");
        learnEnglishAcronym("SID", "Oracle system identifier");
        learnEnglishAcronym("SKOS", "Simple Knowledge Organization System");
        learnEnglishAcronym("SOA", "Service-Oriented Architecture");
        learnEnglishAcronym("SOAP", "Simple Object Access Protocol");
        learnEnglishAcronym("SOP", "Service Object Pair");
        learnEnglishAcronym("SQL", "Structured Query Language");
        learnEnglishAcronym("SRVCTL", "Server Control");
        learnEnglishAcronym("SSH", "Secure Shell");
        learnEnglishAcronym("SSL", "Secure Sockets Layer");
        learnEnglishAcronym("SSO", "Single Sign-On");
        learnEnglishAcronym("STS", "Sql Tuning Set");
        learnEnglishAcronym("SWT", "Synchronous WriteThrough");
        learnEnglishAcronym("TAF", "Transparent Application Failover");
        learnEnglishAcronym("TCO", "Total Cost of Ownership");
        learnEnglishAcronym("TNS", "Transparent Network Substrate");
        learnEnglishAcronym("TSPITR", "Tablespace Point-In-Time Recovery");
        learnEnglishAcronym("TTC", "Two-Task Common");
        learnEnglishAcronym("UGA", "User Global Area");
        learnEnglishAcronym("UID", "Unique Identifier");
        learnEnglishAcronym("UIX", "User Interface XML");
        learnEnglishAcronym("UNC", "Universal Naming Convention");
        learnEnglishAcronym("UTC", "Coordinated Universal Time");
        learnEnglishAcronym("VPD", "Oracle Virtual Private Database");
        learnEnglishAcronym("VSS", "Volume Shadow Copy Service");
        learnEnglishAcronym("W3C", "World Wide Web Consortium");
        learnEnglishAcronym("WG", "Working Group");
        learnEnglishAcronym("WebDAV", "World Wide Web Distributed Authoring and Versioning");
        learnEnglishAcronym("Winsock", "Windows sockets");
        learnEnglishAcronym("XDK", "Oracle XML Developer's Kit");
        learnEnglishAcronym("XIDs","Transaction Identifiers");
        learnEnglishAcronym("XML","eXtensible Markup Language");
        learnEnglishAcronym("XQuery","XML Query");
        learnEnglishAcronym("XSL","eXtensible Stylesheet Language");
        learnEnglishAcronym("XSLFO", "eXtensible Stylesheet Language Formatting Object");
        learnEnglishAcronym("XSLT", "eXtensible Stylesheet Language Transformation");
        learnEnglishAcronym("XSU", "XML SQL Utility");
        learnEnglishAcronym("XVM", "XSLT Virtual Machine");
        learnEnglishAcronym("Approximate CSCN", "Approximate Commit System Change Number");
        learnEnglishAcronym("mDNS", "Multicast Domain Name Server");
        learnEnglishAcronym("row LCR", "Row Logical Change Record");

        /* Use: atLocation (US) */

        /* Context: Non-animal methods for toxicity testing */

        learnEnglishAcronym("3D","three dimensional");
        learnEnglishAcronym("3RS","Replacement, Reduction, Refinement");
        learnEnglishAcronym("AALAS","American Association for Laboratory Animal Science");
        learnEnglishAcronym("ADI","Acceptable Daily Intake [human]");
        learnEnglishAcronym("AFIP","Armed Forces Institute of Pathology");
        learnEnglishAcronym("AHI","Animal Health Institute (US)");
        learnEnglishAcronym("AIDS","Acquired Immune Deficiency Syndrome");
        learnEnglishAcronym("ANDA","Abbreviated New Drug Application (US FDA)");
        learnEnglishAcronym("AOP","Adverse Outcome Pathway");
        learnEnglishAcronym("APHIS","Animal and Plant Health Inspection Service (USDA)");
        learnEnglishAcronym("ARDF","Alternatives Research and Development Foundation");
        learnEnglishAcronym("ATLA","Alternatives to Laboratory Animals");
        learnEnglishAcronym("ATSDR","Agency for Toxic Substances and Disease Registry (US CDC)");
        learnEnglishAcronym("BBMO","Biosensors Based on Membrane Organization to Replace Animal Testing");
        learnEnglishAcronym("BCOP","Bovine Corneal Opacity and Permeability assay");
        learnEnglishAcronym("BFR","German Federal Institute for Risk Assessment");
        learnEnglishAcronym("BLA","Biological License Application (US FDA)");
        learnEnglishAcronym("BRD","Background Review Document (ICCVAM)");
        learnEnglishAcronym("BSC","Board of Scientific Counselors (US NTP)");
        learnEnglishAcronym("BSE","Bovine Spongiform Encephalitis");
        learnEnglishAcronym("CAAI","University of California Center for Animal Alternatives Information");
        learnEnglishAcronym("CAAT","Johns Hopkins Center for Alternatives to Animal Testing");
        learnEnglishAcronym("CAMVA","Chorioallantoic Membrane Vascularization Assay");
        learnEnglishAcronym("CBER","Center for Biologics Evaluation and Research (US FDA)");
        learnEnglishAcronym("CDC","Centers for Disease Control and Prevention (US)");
        learnEnglishAcronym("CDER","Center for Drug Evaluation and Research (US FDA)");
        learnEnglishAcronym("CDRH","Center for Devices and Radiological Health (US FDA)");
        learnEnglishAcronym("CERHR","Center for the Evaluation of Risks to Human Reproduction (US NTP)");
        learnEnglishAcronym("CFR","Code of Federal Regulations (US)");
        learnEnglishAcronym("CFSAN","Center for Food Safety and Applied Nutrition (US FDA)");
        learnEnglishAcronym("CHMP","Committees for Medicinal Products for Human Use");
        learnEnglishAcronym("CMR","Carcinogenic, Mutagenic and Reprotoxic");
        learnEnglishAcronym("CO2","Carbon Dioxide");
        learnEnglishAcronym("COLIPA","European Cosmetic Toiletry & Perfumery Association");
        learnEnglishAcronym("COMP","Committee for Orphan Medicinal Products");
        learnEnglishAcronym("CORDIS","Community Research & Development Information Service");
        learnEnglishAcronym("CORRELATE","European Reference Laboratory for Alternative Tests");
        learnEnglishAcronym("CPCP","Chemical Prioritization Community of Practice (US EPA)");
        learnEnglishAcronym("CPSC","Consumer Product Safety Commission (US)");
        learnEnglishAcronym("CTA","Cell Transformation Assays");
        learnEnglishAcronym("CVB","Center for Veterinary Biologics (USDA)");
        learnEnglishAcronym("CVM","Center for Veterinary Medicine (US FDA)");
        learnEnglishAcronym("CVMP","Committee for Medicinal Products for Veterinary Use");
        learnEnglishAcronym("DARPA","Defense Advanced Research Projects Agency (US)");
        learnEnglishAcronym("DG","Directorate General");
        learnEnglishAcronym("DOD","Department of Defense (US)");
        learnEnglishAcronym("DOT","Department of Transportation (US)");
        learnEnglishAcronym("DRP","Detailed Review Paper (OECD)");
        learnEnglishAcronym("EC","European Commission");
        learnEnglishAcronym("ECB","European Chemicals Bureau");
        learnEnglishAcronym("ECHA","European Chemicals Agency");
        learnEnglishAcronym("ECOPA","European Consensus Platform for Alternatives");
        learnEnglishAcronym("ECVAM","European Centre for the Validation of Alternative Methods");
        learnEnglishAcronym("ED","Endocrine Disrupters");
        learnEnglishAcronym("EDQM","European Directorate for Quality of Medicines & HealthCare");
        learnEnglishAcronym("EEC","European Economic Commission");
        learnEnglishAcronym("EFPIA","European Federation of Pharmaceutical Industries and Associations");
        learnEnglishAcronym("EFSA","European Food Safety Authority");
        learnEnglishAcronym("EFSAPPR","European Food Safety Authority Panel on plant protection products and their residues");
        learnEnglishAcronym("EFTA","European Free Trade Association");
        learnEnglishAcronym("ELINCS","European List of Notified Chemical Substances");
        learnEnglishAcronym("ELISA","Enzyme-Linked ImmunoSorbent Assay");
        learnEnglishAcronym("EMEA","European Medicines Agency");
        learnEnglishAcronym("ENVI","European Parliament Committee on the Environment, Public Health and Food Safety");
        learnEnglishAcronym("EO","Executive Orders (US)");
        learnEnglishAcronym("EPA","Environmental Protection Agency (US)");
        learnEnglishAcronym("EPAA","European Partnership for Alternative Approaches to Animal Testing");
        learnEnglishAcronym("ESACECVAM","Scientific Advisory Committee (EU)");
        learnEnglishAcronym("ESOCOC","Economic and Social Council (UN)");
        learnEnglishAcronym("EU","European Union");
        learnEnglishAcronym("EURL","ECVAM European Union Reference Laboratory on Alternatives to Animal Testing");
        learnEnglishAcronym("EWG","Expert Working group");

        learnEnglishAcronym("FAO","Food and Agriculture Organization of the United Nations");
        learnEnglishAcronym("FDA","Food and Drug Administration (US)");
        learnEnglishAcronym("FFDCA","Federal Food, Drug, and Cosmetic Act (US)");
        learnEnglishAcronym("FHSA","Federal Hazardous Substances Act (US)");
        learnEnglishAcronym("FIFRA","Federal Insecticide, Fungicide, and Rodenticide Act (US)");
        learnEnglishAcronym("FP","Framework Program");
        learnEnglishAcronym("FRAME","Fund for the Replacement of Animals in Medical Experiments");
        learnEnglishAcronym("GCCP","Good Cell Culture Practice");
        learnEnglishAcronym("GCP","Good Clinical Practice");
        learnEnglishAcronym("GHS","Globally Harmonized System for Classification and Labeling of Chemicals");
        learnEnglishAcronym("GJIC","Gap Junction Intercellular Communication [assay]");
        learnEnglishAcronym("GLP","Good Laboratory Practice");
        learnEnglishAcronym("GMO","Genetically Modified Organism");
        learnEnglishAcronym("GMP","Good Manufacturing Practice");
        learnEnglishAcronym("GPMT","Guinea Pig Maximization Test");
        learnEnglishAcronym("HCE","Human corneal epithelial cells");
        learnEnglishAcronym("HCE","T Human corneal epithelial cells");
        learnEnglishAcronym("HESI","ILSI Health and Environmental Sciences Institute");
        learnEnglishAcronym("HET","CAM Hen’s Egg Test – Chorioallantoic Membrane assay");
        learnEnglishAcronym("HHS","Department of Health and Human Services (US)");
        learnEnglishAcronym("HIV","Human Immunodeficiency Virus");
        learnEnglishAcronym("HMPC","Committee on Herbal Medicinal Products");
        learnEnglishAcronym("HPV","High Production Volume");
        learnEnglishAcronym("HSUS","The Humane Society of the United States");
        learnEnglishAcronym("HTS","High Throughput Screening");
        learnEnglishAcronym("HGP","Human Genome Project");
        learnEnglishAcronym("IARC","International Agency for Research on Cancer (WHO)");
        learnEnglishAcronym("ICAPO","International Council for Animal Protection in OECD");
        learnEnglishAcronym("ICCVAM","Interagency Coordinating Committee on the Validation of Alternative Methods (US)");
        learnEnglishAcronym("ICE","Isolated Chicken Eye");
        learnEnglishAcronym("ICH","International Conference on Harmonization of Technical Requirements for Registration of Pharmaceuticals for Human Use");
        learnEnglishAcronym("ICSC","International Chemical Safety Cards");
        learnEnglishAcronym("IFAH","EUROPE International Federation for Animal Health Europe");
        learnEnglishAcronym("IFPMA","International Federation of Pharmaceutical Manufacturers & Associations");
        learnEnglishAcronym("IIVS","Institute for In Vitro Sciences");
        learnEnglishAcronym("ILAR","Institute for Laboratory Animal Research");
        learnEnglishAcronym("ILO","International Labour Organization");
        learnEnglishAcronym("ILSI","International Life Sciences Institute");
        learnEnglishAcronym("IND","Investigational New Drug (US FDA)");
        learnEnglishAcronym("INVITROM","International Society for In Vitro Methods");
        learnEnglishAcronym("IOMC","Inter-Organization Programme for the Sound Management of Chemicals (WHO)");
        learnEnglishAcronym("IPCS","International Programme on Chemical Safety (WHO)");
        learnEnglishAcronym("IQF","International QSAR Foundation to Reduce Animal Testing");
        learnEnglishAcronym("IRB","Institutional review board");
        learnEnglishAcronym("IRE","Isolated rabbit eye");
        learnEnglishAcronym("IWG","Immunotoxicity Working Group (ICCVAM)");
        learnEnglishAcronym("JACVAM","Japanese Center for the Validation of Alternative Methods");
        learnEnglishAcronym("JAVB","Japanese Association of Veterinary Biologics");
        learnEnglishAcronym("JECFA","Joint FAO/WHO Expert Committee on Food Additives");
        learnEnglishAcronym("JMAFF","Japanese Ministry of Agriculture, Forestry and Fisheries");
        learnEnglishAcronym("JPMA","Japan Pharmaceutical Manufacturers Association");
        learnEnglishAcronym("JRC","Joint Research Centre (EU)");
        learnEnglishAcronym("JSAAE","Japanese Society for Alternatives to Animal Experiments");
        learnEnglishAcronym("JVPA","Japanese Veterinary Products Association");

        learnEnglishAcronym("KOCVAM","Korean Center for the Validation of Alternative Method");
        learnEnglishAcronym("LIINTOP","Liver Intestine Optimization");
        learnEnglishAcronym("LLNA","Local Lymph Node Assay");
        learnEnglishAcronym("MAD","Mutual Acceptance of Data (OECD)");
        learnEnglishAcronym("MEIC","Multicenter Evaluation of In Vitro Cytotoxicity");
        learnEnglishAcronym("MEMOMEIC","Monographs on Time-Related Human Lethal Blood Concentrations");
        learnEnglishAcronym("MEPS","Members of the European Parliament");
        learnEnglishAcronym("MG","Milligrams [a unit of weight]");
        learnEnglishAcronym("MHLW","Ministry of Health, Labour and Welfare (Japan)");
        learnEnglishAcronym("MLI","Molecular Libraries Initiative (US NIH)");
        learnEnglishAcronym("MSDS","Material Safety Data Sheets");

        learnEnglishAcronym("MW","Molecular Weight");
        learnEnglishAcronym("NC3RSUK","National Center for the Replacement, Refinement and Reduction of Animals in Research");
        learnEnglishAcronym("NKCA","Netherlands Knowledge Centre on Alternatives to animal use");
        learnEnglishAcronym("NCBI","National Center for Biotechnology Information (US)");
        learnEnglishAcronym("NCEH","National Center for Environmental Health (US CDC)");
        learnEnglishAcronym("NCGCNIH","Chemical Genomics Center (US)");
        learnEnglishAcronym("NCI","National Cancer Institute (US NIH)");
        learnEnglishAcronym("NCPDCID","National Center for Preparedness, Detection and Control of Infectious Diseases");
        learnEnglishAcronym("NCCT","National Center for Computational Toxicology (US EPA)");
        learnEnglishAcronym("NCTR","National Center for Toxicological Research (US FDA)");
        learnEnglishAcronym("NDA","New Drug Application (US FDA)");
        learnEnglishAcronym("NGO","Non-Governmental Organization");
        learnEnglishAcronym("NIAID","National Institute of Allergy and Infectious Diseases");
        learnEnglishAcronym("NICA","Nordic Information Center for Alternative Methods");
        learnEnglishAcronym("NICEATM","National Toxicology Program Interagency Center for Evaluation of Alternative Toxicological Methods (US)");
        learnEnglishAcronym("NIEHS","National Institute of Environmental Health Sciences (US NIH)");
        learnEnglishAcronym("NIH","National Institutes of Health (US)");
        learnEnglishAcronym("NIHS","National Institute of Health Sciences (Japan)");
        learnEnglishAcronym("NIOSH","National Institute for Occupational Safety and Health (US CDC)");
        learnEnglishAcronym("NITR","National Institute of Toxicological Research (Korea)");
        learnEnglishAcronym("NOAEL","No-Observed Adverse Effect Level");
        learnEnglishAcronym("NOEL","No-Observed Effect Level");
        learnEnglishAcronym("NPPTAC","National Pollution Prevention and Toxics Advisory Committee (US EPA)");
        learnEnglishAcronym("NRC","National Research Council");
        learnEnglishAcronym("NTP","National Toxicology Program (US)");
        learnEnglishAcronym("OECD","Organisation for Economic Cooperation and Development");
        learnEnglishAcronym("OMCLS","Official Medicines Control Laboratories");
        learnEnglishAcronym("OPPTS","Office of Prevention, Pesticides and Toxic Substances (US EPA)");
        learnEnglishAcronym("ORF","open reading frame");
        learnEnglishAcronym("OSHA","Occupational Safety and Health Administration (US)");
        learnEnglishAcronym("OSIRIS","Optimized Strategies for Risk Assessment of Industrial Chemicals through the Integration of Non-test and Test Information");
        learnEnglishAcronym("OT","Cover-the-counter [drug]");

        learnEnglishAcronym("PBPK","Physiologically-Based Pharmacokinetic (modeling)");
        learnEnglishAcronym("P&G"," Procter & Gamble");
        learnEnglishAcronym("PHRMA","Pharmaceutical Research and Manufacturers of America");
        learnEnglishAcronym("PL","Public Law");
        learnEnglishAcronym("POPS","Persistent Organic Pollutants");
        learnEnglishAcronym("QAR", "Quantitative Structure Activity Relationship");
        learnEnglishAcronym("QSM","Quality, Safety and Efficacy of Medicines (WHO)");
        learnEnglishAcronym("RA","Regulatory Acceptance");
        learnEnglishAcronym("REACH","Registration, Evaluation, Authorization and Restriction of Chemicals");
        learnEnglishAcronym("RHE","Reconstructed Human Epidermis");
        learnEnglishAcronym("RIPSREACH","Implementation Projects");
        learnEnglishAcronym("RNAI","RNA Interference");
        learnEnglishAcronym("RLLNA","Reduced Local Lymph Node Assay");
        learnEnglishAcronym("SACATM","Scientific Advisory Committee on Alternative Toxicological Methods (US)");
        learnEnglishAcronym("SAICM","Strategic Approach to International Chemical Management (WHO)");
        learnEnglishAcronym("SANCO","Health and Consumer Protection Directorate General");
        learnEnglishAcronym("SCAHAW","Scientific Committee on Animal Health and Animal Welfare");
        learnEnglishAcronym("SCCP","Scientific Committee on Consumer Products");
        learnEnglishAcronym("SCENIHR","Scientific Committee on Emerging and Newly Identified Health Risks");
        learnEnglishAcronym("SCFCAH","Standing Committee on the Food Chain and Animal Health");
        learnEnglishAcronym("SCHER","Standing Committee on Health and Environmental Risks");
        learnEnglishAcronym("SEPS","Special Emphasis Panels (US NTP)");
        learnEnglishAcronym("SIDS","Screening Information Data Sets");
        learnEnglishAcronym("SOT","Society of Toxicology");
        learnEnglishAcronym("SPORT","Strategic Partnership on REACH Testing");
        learnEnglishAcronym("TBD","To Be Determined");
        learnEnglishAcronym("TDG","Transport of Dangerous Goods (UN committee)");
        learnEnglishAcronym("TER","Transcutaneous Electrical Resistance");
        learnEnglishAcronym("TEWG","Technical Expert Working Group");
        learnEnglishAcronym("TG","Test Guideline (OECD)");
        learnEnglishAcronym("TOBI","Toxin Binding Inhibition");
        learnEnglishAcronym("TSCA","Toxic Substances Control Act (US)");
        learnEnglishAcronym("TTC","Threshold of Toxicological Concern");

        learnEnglishAcronym("UC","University of California");
        learnEnglishAcronym("UCD","University of California Davis");
        learnEnglishAcronym("UK","United Kingdom");
        learnEnglishAcronym("UN","United Nations");
        learnEnglishAcronym("UNECE","United Nations Economic Commission for Europe");
        learnEnglishAcronym("UNEP","United Nations Environment Programme");
        learnEnglishAcronym("UNITAR","United Nations Institute for Training and Research");
        learnEnglishAcronym("USAMRICD","US Army Medical Research Institute of Chemical Defense");
        learnEnglishAcronym("USAMRIID","US Army Medical Research Institute of Infectious Diseases");
        learnEnglishAcronym("USAMRMC","US Army Medical Research and Material Command");
        learnEnglishAcronym("USDA","United States Department of Agriculture");
        learnEnglishAcronym("USUHS","Uniformed Services University of the Health Sciences");
        learnEnglishAcronym("UV","ultraviolet");
        learnEnglishAcronym("VCCEP","Voluntary Children’s Chemical Evaluation Program (US EPA)");
        learnEnglishAcronym("VICH","International Cooperation on Harmonization of Technical Requirements for Registration of Veterinary Products");
        learnEnglishAcronym("WHO","World Health Organization");
        learnEnglishAcronym("WRAIR","Walter Reed Army Institute of Research");
        learnEnglishAcronym("ZEBET","Centre for Documentation and Evaluation of Alternative Methods to Animal Experiments (Germany)");
    }

    /** Learn English Irregular Verbs.
     */
    void learnEnglishIrregularVerbs()
    {
        learnEnglishIrregularVerb("arise", "arose", "arisen");
        learnEnglishIrregularVerb("rise", "rose", "risen");
        learnEnglishIrregularVerb("wake", ["woke", "awaked"], "woken");
        learnEnglishIrregularVerb("be", ["was", "were"], "been");
        learnEnglishIrregularVerb("bear", ["bore", "born"], "borne");
        learnEnglishIrregularVerb("beat", "beat", "beaten");
        learnEnglishIrregularVerb("become", "became", "become");
        learnEnglishIrregularVerb("begin", "began", "begun");
        learnEnglishIrregularVerb("bend", "bent", "bent");
        learnEnglishIrregularVerb("bet", "bet", "bet");
        learnEnglishIrregularVerb("bid", ["bid", "bade"], ["bid", "bidden"]);
        learnEnglishIrregularVerb("bind", "bound", "bound");
        learnEnglishIrregularVerb("bite", "bit", "bitten");
        learnEnglishIrregularVerb("bleed", "bled", "bled");
        learnEnglishIrregularVerb("blow", "blew", "blown");
        learnEnglishIrregularVerb("break", "broke", "broken");
        learnEnglishIrregularVerb("breed", "bred", "bred");
        learnEnglishIrregularVerb("bring", "brought", "brought");
        learnEnglishIrregularVerb("build", "built", "built");
        learnEnglishIrregularVerb("burn", ["burnt", "burned"], ["burnt", "burned"]);
        learnEnglishIrregularVerb("burst", "burst", "burst");
        learnEnglishIrregularVerb("buy", "bought", "bought");
        learnEnglishIrregularVerb("cast", "cast", "cast");
        learnEnglishIrregularVerb("catch", "caught", "caught");
        learnEnglishIrregularVerb("choose", "chose", "chosen");
        learnEnglishIrregularVerb("come", "came", "come");
        learnEnglishIrregularVerb("cost", "cost", "cost");
        learnEnglishIrregularVerb("creep", "crept", "crept");
        learnEnglishIrregularVerb("cut", "cut", "cut");
        learnEnglishIrregularVerb("deal", "dealt", "dealt");
        learnEnglishIrregularVerb("dig", "dug", "dug");
        learnEnglishIrregularVerb("dive", ["dived", "dove"], "dived");
        learnEnglishIrregularVerb("do", "did", "done");
        learnEnglishIrregularVerb("draw", "drew", "drawn");
        learnEnglishIrregularVerb("dream", ["dreamt", "dreamed"], ["dreamt", "dreamed"]);
        learnEnglishIrregularVerb("drink", "drank", "drunk");
        learnEnglishIrregularVerb("drive", "drove", "driven");
        learnEnglishIrregularVerb("dwell", "dwelt", "dwelt");
        learnEnglishIrregularVerb("eat", "ate", "eaten");
        learnEnglishIrregularVerb("fall", "fell", "fallen");
        learnEnglishIrregularVerb("feed", "fed", "fed");
        learnEnglishIrregularVerb("fight", "fought", "fought");
        learnEnglishIrregularVerb("find", "found", "found");
        learnEnglishIrregularVerb("flee", "fled", "fled");
        learnEnglishIrregularVerb("fly", "flew", "flown");
        learnEnglishIrregularVerb("forbid", ["forbade", "forbad"], "forbidden");
        learnEnglishIrregularVerb("forget", "forgot", "forgotten");
        learnEnglishIrregularVerb("forgive", "forgave", "forgiven");
        learnEnglishIrregularVerb("forsake", "forsook", "forsaken");
        learnEnglishIrregularVerb("freeze", "froze", "frozen");

        learnEnglishIrregularVerb("get", "got", ["gotten", "got"]);
        learnEnglishIrregularVerb("give", "gave", "given");
        learnEnglishIrregularVerb("go", "went", "gone");
        learnEnglishIrregularVerb("grind", "ground", "ground");
        learnEnglishIrregularVerb("grow", "grew", "grown");

        learnEnglishIrregularVerb("hang", ["hanged", "hung"], ["hanged", "hung"]);
        learnEnglishIrregularVerb("have", "had", "had");
        learnEnglishIrregularVerb("hear", "heard", "heard");
        learnEnglishIrregularVerb("hide", "hid", "hidden");
        learnEnglishIrregularVerb("hit", "hit", "hit");
        learnEnglishIrregularVerb("hold", "held", "held");
        learnEnglishIrregularVerb("hurt", "hurt", "hurt");

        learnEnglishIrregularVerb("keep", "kept", "kept");
        learnEnglishIrregularVerb("kneel", "knelt", "knelt");
        learnEnglishIrregularVerb("knit", ["knit", "knitted"], ["knit", "knitted"]);
        learnEnglishIrregularVerb("know", "knew", "known");

        learnEnglishIrregularVerb("lay", "laid", "laid");
        learnEnglishIrregularVerb("lead", "led", "led");

        learnEnglishIrregularVerb("lean", ["leaned", "leant"], ["leaned", "leant"]);
        learnEnglishIrregularVerb("leap", ["leaped", "leapt"], ["leaped", "leapt"]);

        learnEnglishIrregularVerb("learn", ["learned", "learnt"], ["learned", "learnt"]);
        learnEnglishIrregularVerb("leave", "left", "left");
        learnEnglishIrregularVerb("lend", "lent", "lent");
        learnEnglishIrregularVerb("let", "let", "let");
        learnEnglishIrregularVerb("lie", "lay", "lain");
        learnEnglishIrregularVerb("light", ["lighted", "lit"], ["lighted", "lit"]);
        learnEnglishIrregularVerb("lose", "lost", "lost");

        learnEnglishIrregularVerb("make", "made", "made");
        learnEnglishIrregularVerb("mean", "meant", "meant");
        learnEnglishIrregularVerb("meet", "met", "met");
        learnEnglishIrregularVerb("mistake", "mistook", "mistaken");

        learnEnglishIrregularVerb("partake", "partook", "partaken");
        learnEnglishIrregularVerb("pay", "paid", "paid");
        learnEnglishIrregularVerb("put", "put", "put");

        learnEnglishIrregularVerb("read", "read", "read");
        learnEnglishIrregularVerb("rend", "rent", "rent");
        learnEnglishIrregularVerb("rid", "rid", "rid");
        learnEnglishIrregularVerb("ride", "rode", "ridden");
        learnEnglishIrregularVerb("run", "ran", "run");

        learnEnglishIrregularVerb("say", "said", "said");
        learnEnglishIrregularVerb("see", "saw", "seen");
        learnEnglishIrregularVerb("seek", "sought", "sought");
        learnEnglishIrregularVerb("sell", "sold", "sold");
        learnEnglishIrregularVerb("send", "sent", "sent");
        learnEnglishIrregularVerb("set", "set", "set");
        learnEnglishIrregularVerb("shake", "shook", "shaken");
        learnEnglishIrregularVerb("shed", "shed", "shed");
        learnEnglishIrregularVerb("shine", "shone", "shone");
        learnEnglishIrregularVerb("shoot", "shot", "shot");
        learnEnglishIrregularVerb("shrink", "shrank", "shrunk");
        learnEnglishIrregularVerb("shut", "shut", "shut");
        learnEnglishIrregularVerb("sing", "sang", "sung");
        learnEnglishIrregularVerb("sink", "sank", "sank");
        learnEnglishIrregularVerb("sit", "sat", "sat");
        learnEnglishIrregularVerb("slay", "slew", "slain");
        learnEnglishIrregularVerb("sleep", "slept", "slept");
        learnEnglishIrregularVerb("sling", "slung", "slung");
        learnEnglishIrregularVerb("slit", "slit", "slit");
        learnEnglishIrregularVerb("speak", "spoke", "spoken");
        learnEnglishIrregularVerb("spin", "spun", "spun");
        learnEnglishIrregularVerb("spit", "spat", "spat");
        learnEnglishIrregularVerb("split", "split", "split");
        learnEnglishIrregularVerb("spring", "sprang", "sprung");
        learnEnglishIrregularVerb("stand", "stood", "stood");
        learnEnglishIrregularVerb("steal", "stole", "stolen");
        learnEnglishIrregularVerb("stick", "stuck", "stuck");
        learnEnglishIrregularVerb("sting", "stung", "stung");
        learnEnglishIrregularVerb("stink", "stank", "stunk");
        learnEnglishIrregularVerb("stride", "strode", "stridden");
        learnEnglishIrregularVerb("strive", "strove", "striven");
        learnEnglishIrregularVerb("swear", "swore", "sworn");
        learnEnglishIrregularVerb("sweep", "swept", "swept");
        learnEnglishIrregularVerb("swim", "swam", "swum");
        learnEnglishIrregularVerb("swing", "swung", "swung");

        learnEnglishIrregularVerb("slide", "slid", ["slid", "slidden"]);
        learnEnglishIrregularVerb("speed", ["sped", "speeded"], ["sped", "speeded"]);
        learnEnglishIrregularVerb("tread", "trod", ["trodden", "trod"]);

        learnEnglishIrregularVerb("take", "took", "taken");
        learnEnglishIrregularVerb("teach", "taught", "taught");
        learnEnglishIrregularVerb("tear", "tore", "torn");
        learnEnglishIrregularVerb("tell", "told", "told");
        learnEnglishIrregularVerb("think", "thought", "thought");
        learnEnglishIrregularVerb("throw", "threw", "thrown");

        learnEnglishIrregularVerb("understand", "understood", "understood");
        learnEnglishIrregularVerb("upset", "upset", "upset");

        learnEnglishIrregularVerb("wear", "wore", "worn");
        learnEnglishIrregularVerb("weave", "wove", "woven");
        learnEnglishIrregularVerb("weep", "wept", "wept");
        learnEnglishIrregularVerb("win", "won", "won");
        learnEnglishIrregularVerb("wind", "wound", "wound");
        learnEnglishIrregularVerb("wring", "wrung", "wrung");
        learnEnglishIrregularVerb("write", "wrote", "written");
    }

    /** Learn Swedish Irregular Verb.
        See also: http://www.lardigsvenska.com/2010/10/oregelbundna-verb.html
    */
    void learnSwedishIrregularVerb(S)(S imperative,
                                      S infinitive,
                                      S present,
                                      S past,
                                      S pastParticiple) if (isSomeString!S) // pastParticiple
    {
        const lang = Lang.sv;
        const category = CategoryIx.asUndefined;
        const origin = Origin.manual;
        auto all = [tryStore(imperative, lang, Sense.verbImperative, category, origin),
                    tryStore(infinitive, lang, Sense.verbInfinitive, category, origin),
                    tryStore(present, lang, Sense.verbPresent, category, origin),
                    tryStore(past, lang, Sense.verbPast, category, origin),
                    tryStore(pastParticiple, lang, Sense.verbPastParticiple, category, origin)];
        connectMtoM(Rel.verbForm, all.filter!(a => a.defined), lang, origin);
    }

    /** Learn Swedish Irregular Verbs.
    */
    void learnSwedishIrregularVerbs()
    {
        enum lang = Lang.sv;

        learnSwedishIrregularVerb("ge", "ge", "ger", "gav", "gett/givit");
        learnSwedishIrregularVerb("ange", "ange", "anger", "angav", "angett/angivit");
        learnSwedishIrregularVerb("anse", "anse", "anser", "ansåg", "ansett");
        learnSwedishIrregularVerb("avgör", "avgöra", "avgör", "avgjorde", "avgjort");
        learnSwedishIrregularVerb("avstå", "avstå", "avstår", "avstod", "avstått");
        learnSwedishIrregularVerb("be", "be", "ber", "bad", "bett");
        learnSwedishIrregularVerb("bestå", "bestå", "består", "bestod", "bestått");
        learnSwedishIrregularVerb([], [], "bör", "borde", "bort");
        learnSwedishIrregularVerb("dra", "dra", "drar", "drog", "dragit");
        learnSwedishIrregularVerb([], "duga", "duger", "dög/dugde", "dugit");
        learnSwedishIrregularVerb("dyk", "dyka", "dyker", "dök/dykte", "dykit");
        learnSwedishIrregularVerb("dö", "dö", "dör", "dog", "dött");
        learnSwedishIrregularVerb("dölj", "dölja", "döljer", "dolde", "dolt");
        learnSwedishIrregularVerb("ersätt", "ersätta", "ersätter", "ersatte", "ersatt");
        learnSwedishIrregularVerb("fortsätt", "fortsätta", "fortsätter", "fortsatte", "fortsatt");
        learnSwedishIrregularVerb("framstå", "framstå", "framstår", "framstod", "framstått");
        learnSwedishIrregularVerb("få", "få", "får", "fick", "fått");
        learnSwedishIrregularVerb("förstå", "förstå", "förstår", "förstod", "förstått");
        learnSwedishIrregularVerb("förutsätt", "förutsätta", "förutsätter", "förutsatte", "förutsatt");
        learnSwedishIrregularVerb("gläd", "glädja", "gläder", "gladde", "glatt");
        learnSwedishIrregularVerb("gå", "gå", "går", "gick", "gått");
        learnSwedishIrregularVerb("gör", "göra", "gör", "gjorde", "gjort");
        learnSwedishIrregularVerb("ha", "ha", "har", "hade", "haft");
        learnSwedishIrregularVerb([], "heta", "heter", "hette", "hetat");
        learnSwedishIrregularVerb([], "ingå", "ingår", "ingick", "ingått");
        learnSwedishIrregularVerb("inse", "inse", "inser", "insåg", "insett");
        learnSwedishIrregularVerb("kom", "komma", "kommer", "kom", "kommit");
        learnSwedishIrregularVerb([], "kunna", "kan", "kunde", "kunnat");
        learnSwedishIrregularVerb("le", "le", "ler", "log", "lett");
        learnSwedishIrregularVerb("lev", "leva", "lever", "levde", "levt");
        learnSwedishIrregularVerb("ligg", "ligga", "ligger", "låg", "legat");
        learnSwedishIrregularVerb("lägg", "lägga", "lägger", "la", "lagt");
        learnSwedishIrregularVerb("missförstå", "missförstå", "missförstår", "missförstod", "missförstått");
        learnSwedishIrregularVerb([], [], "måste", "var tvungen", "varit tvungen");
        learnSwedishIrregularVerb("se", "se", "ser", "såg", "sett");
        learnSwedishIrregularVerb("skilj", "skilja", "skiljer", "skilde", "skilt");
        learnSwedishIrregularVerb([], [], "ska", "skulle", []);
        learnSwedishIrregularVerb("smaksätt", "smaksätta", "smaksätter", "smaksatte", "smaksatt");
        learnSwedishIrregularVerb("sov", "sova", "sover", "sov", "sovit");
        learnSwedishIrregularVerb("sprid", "sprida", "sprider", "spred", "spridit");
        learnSwedishIrregularVerb("stjäl", "stjäla", "stjäl", "stal", "stulit");
        learnSwedishIrregularVerb("stå", "stå", "står", "stod", "stått");
        learnSwedishIrregularVerb("stöd", "stödja", "stöder", "stödde", "stött");
        learnSwedishIrregularVerb("svälj", "svälja", "sväljer", "svalde", "svalt");
        learnSwedishIrregularVerb("säg", "säga", "säger", "sa", "sagt");
        learnSwedishIrregularVerb("sälj", "sälja", "säljer", "sålde", "sålt");
        learnSwedishIrregularVerb("sätt", "sätta", "sätter", "satte", "satt");
        learnSwedishIrregularVerb("ta", "ta", "tar", "tog", "tagit");
        learnSwedishIrregularVerb("tillsätt", "tillsätta", "tillsätter", "tillsatte", "tillsatt");
        learnSwedishIrregularVerb("umgås", "umgås", "umgås", "umgicks", "umgåtts");
        learnSwedishIrregularVerb("uppge", "uppge", "uppger", "uppgav", "uppgivit");
        learnSwedishIrregularVerb("utgå", "utgå", "utgår", "utgick", "utgått");
        learnSwedishIrregularVerb("var", "vara", "är", "var", "varit");
        learnSwedishIrregularVerb([], "veta", "vet", "visste", "vetat");
        learnSwedishIrregularVerb("vik", "vika", "viker", "vek", "vikt");
        learnSwedishIrregularVerb([], "vilja", "vill", "ville", "velat");
        learnSwedishIrregularVerb("välj", "välja", "väljer", "valde", "valt");
        learnSwedishIrregularVerb("vänj", "vänja", "vänjer", "vande", "vant");
        learnSwedishIrregularVerb("väx", "växa", "växer", "växte", "växt");
        learnSwedishIrregularVerb("återge", "återge", "återger", "återgav", "återgivit");
        learnSwedishIrregularVerb("översätt", "översätta", "översätter", "översatte", "översatt");
    }

    /* TODO Add logic describing which Sense.nounX and CategoryIx that fulfills
     * isUncountable() and use it here. */
    void learnUncountableNouns(R)(Lang lang, R nouns) if (isSourceOf!(R, string))
    {
        const sense = Sense.nounUncountable;
        const categoryIx = CategoryIx.asUndefined;
        const origin = Origin.manual;
        connectMto1(nouns.map!(word => store(word, lang, sense, categoryIx, origin)),
                    Rel.isA,
                    store("uncountable_noun", lang, sense, categoryIx, origin),
                    lang, origin);
    }

    /** Lookup-or-Store $(D Node) at $(D lemma) index.
     */
    NodeRef store(in Lemma lemma,
                  Node node) in { assert(!lemma.expr.empty); }
    body
    {
        if (lemma in nodeRefByLemma)
        {
            return nodeRefByLemma[lemma]; // lookup
        }
        else
        {
            auto wordsSplit = lemma.expr.findSplit(expressionWordSeparator);
            if (!wordsSplit[1].empty) // TODO add implicit bool conversion to return of findSplit()
            {
                ++multiWordNodeLemmaCount;
                exprWordCountSum += max(0, lemma.expr.count(expressionWordSeparator) - 1);
            }

            // store
            assert(allNodes.length <= nullIx);
            const cix = NodeRef(cast(Ix)allNodes.length);
            allNodes ~= node; // .. new node that is stored
            nodeRefByLemma[lemma] = cix; // store index to ..
            nodeStringLengthSum += lemma.expr.length;

            learnLemma(lemma.expr, lemma);

            return cix;
        }
    }

    /** Lookup-or-Store $(D Node) named $(D expr) in language $(D lang). */
    NodeRef store(Expr expr,
                  Lang lang,
                  Sense kind,
                  CategoryIx categoryIx,
                  Origin origin) in { assert(!expr.empty); }
    body
    {
        const lemma = Lemma(expr, lang, kind, categoryIx);
        return store(lemma, Node(lemma, origin));
    }

    /** Try to Lookup-or-Store $(D Node) named $(D expr) in language $(D lang).
     */
    NodeRef tryStore(Expr expr,
                     Lang lang,
                     Sense kind,
                     CategoryIx categoryIx,
                     Origin origin)
    {
        if (expr.empty)
            return NodeRef.asUndefined;
        return store(expr, lang, kind, categoryIx, origin);
    }

    NodeRef[] tryStore(Exprs)(Exprs exprs,
                              Lang lang,
                              Sense kind,
                              CategoryIx categoryIx,
                              Origin origin) if (isIterable!(Exprs))
    {
        typeof(return) nodeRefs;
        foreach (expr; exprs)
        {
            nodeRefs ~= store(expr, lang, kind, categoryIx, origin);
        }
        return nodeRefs;
    }

    /** Fully Connect Every-to-Every in $(D all).
        See also: http://forum.dlang.org/thread/iqkybajwdzcvdytakgvw@forum.dlang.org#post-iqkybajwdzcvdytakgvw:40forum.dlang.org
        See also: https://issues.dlang.org/show_bug.cgi?id=6788
     */
    LinkRef[] connectMtoM(R)(Rel rel,
                             R all,
                             Lang lang,
                             Origin origin,
                             NWeight weight = 1.0) if (isIterableOf!(R, NodeRef))
        in { assert(rel.isSymmetric); }
    body
    {
        typeof(return) linkIxes;
        size_t i = 0;
        // TODO use combinations.pairwise() when ForwardRange support has been addded
        foreach (me; all)
        {
            size_t j = 0;
            foreach (you; all)
            {
                if (j >= i)
                {
                    break;
                }
                linkIxes ~= connect(me, rel, you, lang, origin, weight);
                ++j;
            }
            ++i;
        }
        return linkIxes;
    }
    alias connectFully = connectMtoM;

    /** Fan-Out Connect $(D first) to Every in $(D rest). */
    LinkRef[] connect1toM(R)(NodeRef first,
                             Rel rel,
                             R rest,
                             Origin origin, NWeight weight = 1.0) if (isIterableOf!(R, NodeRef))
    {
        typeof(return) linkIxes;
        foreach (you; rest)
        {
            if (first != you)
            {
                linkIxes ~= connect(first, rel, you, origin, weight);
            }
        }
        return linkIxes;
    }
    alias connectFanOut = connect1toM;

    /** Fan-In Connect $(D first) to Every in $(D rest). */
    LinkRef[] connectMto1(R)(R rest,
                             Rel rel,
                             NodeRef first,
                             Lang lang,
                             Origin origin, NWeight weight = 1.0) if (isIterableOf!(R, NodeRef))
    {
        typeof(return) linkIxes;
        foreach (you; rest)
        {
            if (first != you)
            {
                linkIxes ~= connect(you, rel, first, lang, origin, weight);
            }
        }
        return linkIxes;
    }
    alias connectFanIn = connectMto1;

    /** Cyclic Connect Every in $(D all). */
    void connectCycle(R)(Rel rel, R all) if (isIterableOf!(R, NodeRef))
    {
    }
    alias connectCircle = connectCycle;

    /** Add Link from $(D src) to $(D dst) of type $(D rel) and weight $(D weight).

        TODO checkExisting is currently set to false because searching
        existing links is currently too slow
     */
    LinkRef connect(NodeRef src,
                    Rel rel,
                    NodeRef dst,
                    Lang lang = Lang.unknown,
                    Origin origin = Origin.unknown,
                    NWeight weight = 1.0, // 1.0 means absolutely true for Origin manual
                    bool negation = false,
                    bool reversion = false,
                    bool checkExisting = false)
    body
    {
        if (src == dst) { return LinkRef.asUndefined; } // Don't allow self-reference for now

        if (checkExisting)
        {
            if (auto existingIx = areConnected(src, rel, dst,
                                               negation)) // TODO warn about negation and reversion on existing rels
            {
                if (false)
                {
                    dln("warning: Nodes ",
                        nodeAt(src).lemma.expr, " and ",
                        nodeAt(dst).lemma.expr, " already related as ",
                        rel);
                }
                return existingIx;
            }
        }

        // TODO group these
        assert(allLinks.length <= nullIx);
        auto linkRef = LinkRef(cast(Ix)allLinks.length);

        auto link = Link(reversion ? dst : src,
                         rel,
                         reversion ? src : dst,
                         negation,
                         lang,
                         origin);

        nodeAt(src).links ~= linkRef.forward;
        nodeAt(dst).links ~= linkRef.backward;
        connectednessSum += 2;

        symmetricRelCount += rel.isSymmetric;
        transitiveRelCount += rel.isTransitive;
        ++linkCountsByRel[rel];
        ++linkSourceCounts[origin];

        if (origin == Origin.cn5)
        {
            link.setCN5Weight(weight);
            weightSumCN5 += weight;
            weightMinCN5 = min(weight, weightMinCN5);
            weightMaxCN5 = max(weight, weightMaxCN5);
            ++packedWeightHistogramCN5[link.packedWeight];
        }
        else if (origin == Origin.nell)
        {
            link.setNELLWeight(weight);
            weightSumNELL += weight;
            weightMinNELL = min(weight, weightMinNELL);
            weightMaxNELL = max(weight, weightMaxNELL);
            ++packedWeightHistogramNELL[link.packedWeight];
        }
        else
        {
            link.setManualWeight(weight);
        }

        propagateLinkNodes(link, src, dst);

        if (false)
        {
            dln(" src:", nodeAt(src).lemma.expr,
                " dst:", nodeAt(dst).lemma.expr,
                " rel:", rel,
                " origin:", origin,
                " negation:", negation,
                " reversion:", reversion);
        }

        allLinks ~= link; // TODO Avoid copying here

        return linkRef; // allLinks.back;"
    }
    alias relate = connect;

    auto ref correctCN5Lemma(S)(S s) if (isSomeString!S)
    {
        switch (s)
        {
            case "honey_be": return "honey_bee";
            default: return s;
        }
    }

    /** Read ConceptNet5 URI.
        See also: https://github.com/commonsense/conceptnet5/wiki/URI-hierarchy-5.0
    */
    NodeRef readCN5ConceptURI(T)(const T part)
    {
        auto items = part.splitter('/');

        const lang = items.front.decodeLang; items.popFront;
        ++hlangCounts[lang];

        static if (useRCString) { immutable expr = items.front; }
        else                    { immutable expr = items.front.idup; }

        items.popFront;
        auto sense = Sense.unknown;
        if (!items.empty)
        {
            const item = items.front;
            sense = item.decodeWordKind;
            if (sense == Sense.unknown && item != `_`)
            {
                dln(`Unknown Sense code `, items.front);
            }
        }
        ++kindCounts[sense];

        return store(correctCN5Lemma(expr), lang, sense, anyCategory, Origin.cn5);
    }

    import std.algorithm: splitter;

    /** Lookup Category by $(D name). */
    CategoryIx categoryByName(S)(S name) if (isSomeString!S)
    {
        auto categoryIx = anyCategory;
        if (name in categoryIxByName)
        {
            categoryIx = categoryIxByName[name];
        }
        else
        {
            assert(categoryIxCounter != categoryIxCounter.max);
            categoryIx._ix = categoryIxCounter++;
            categoryNameByIx[categoryIx] = name;
            categoryIxByName[name] = categoryIx;
        }
        return categoryIx;
    }

    /** Read NELL Entity from $(D part). */
    Tuple!(NodeRef, string, LinkRef) readNELLEntity(S)(const S part)
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

        const lang = Lang.unknown;
        const kind = Sense.noun;

        /* name */
        // clean cases such as concept:language:english_language
        immutable entityName = (entity.front.endsWith("_" ~ categoryName) ?
                                entity.front[0 .. $ - (categoryName.length + 1)] :
                                entity.front).idup;
        entity.popFront;

        auto entityIx = store(entityName,
                              lang,
                              kind,
                              categoryIx,
                              Origin.nell);

        return tuple(entityIx,
                     categoryName,
                     connect(entityIx,
                             Rel.isA,
                             store(categoryName,
                                   lang,
                                   kind,
                                   categoryIx,
                                   Origin.nell),
                             lang,
                             Origin.nell, 1.0, false, false,
                             true)); // need to check duplicates here
    }

    /** Read NELL CSV Line $(D line) at 0-offset line number $(D lnr). */
    void readNELLLine(R, N)(R line, N lnr)
    {
        auto rel = Rel.any;
        auto negation = false;
        auto reversion = false;
        auto tense = Tense.unknown;

        NodeRef entityIx;
        NodeRef valueIx;

        string entityCategoryName;
        char[] relationName;
        string valueCategoryName;

        auto ignored = false;
        NWeight mainWeight;
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

                            rel = relationName.decodeRelationPredicate(entityCategoryName,
                                                              valueCategoryName,
                                                              Origin.nell,
                                                              negation, reversion, tense);
                        }
                    }
                    break;
                case 4:
                    mainWeight = part.to!NWeight;
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
            auto mainLinkRef = connect(entityIx, rel, valueIx,
                                       Lang.en,
                                       Origin.nell, mainWeight, negation, reversion);
        }

        if (show) writeln();
    }

    struct Location
    {
        double latitude;
        double longitude;
    }

    /** Node Locations. */
    Location[NodeRef] locations;

    /** Set Location of Node $(D cix) to $(D location) */
    void setLocation(NodeRef cix, in Location location)
    {
        assert (cix !in locations);
        locations[cix] = location;
    }

    /** If $(D link) node origins unknown propagate them from $(D link)
        itself. */
    bool propagateLinkNodes(ref Link link,
                               NodeRef srcRef,
                               NodeRef dstRef)
    {
        bool done = false;
        if (!link.origin.defined)
        {
            // TODO prevent duplicate lookups to nodeAt
            if (!nodeAt(srcRef).origin.defined)
                nodeAt(srcRef).origin = link.origin;
            if (!nodeAt(dstRef).origin.defined)
                nodeAt(dstRef).origin = link.origin;
            done = true;
        }
        return done;
    }

    Origin decodeCN5OriginDirect(char[] path, out Lang lang,
                                 Origin currentOrigin)
    {
        with (Origin)
            switch (path)
            {
                case `/s/dbpedia/3.7`: return dbpedia37;
                case `/s/dbpedia/3.9/umbel`: return dbpedia39umbel;
                case `/d/dbpedia/en`: lang = Lang.en; return dbpediaEn;
                case `/d/wordnet/3.0`: return wordnet30;
                case `/s/wordnet/3.0`: return wordnet30;
                case `/s/site/verbosity`: return verbosity;
                default: /* dln("Handle ", path); */ return unknown;
            }
    }

    /** Decode ConceptNet5 Origin $(D path). */
    Origin decodeCN5OriginPath(char[] path, out Lang lang,
                               Origin currentOrigin)
    {
        auto origin = decodeCN5OriginDirect(path, lang,
                                            currentOrigin);
        if (origin != Origin.unknown)
        {
            return origin;
        }

        bool fromSource = false;
        bool fromDictionary = false;
        bool fromSite = false;

        size_t ix = 0;
        foreach (part; path.splitter('/'))
        {
            switch (ix)
            {
                case 0:
                    break;
                case 1:
                    switch (part)
                    {
                        case "s": fromSource = true; break;
                        case "d": fromDictionary = true; break;
                        default: break;
                    }
                    break;
                case 2:
                    with (Origin)
                        switch (part)
                        {
                            case "dbpedia": origin = dbpedia; break;
                            case "wordnet": origin = wordnet; break;
                            case "wiktionary": origin = wiktionary; break;
                            case "globalmind": origin = globalmind; break;
                            case "conceptnet": origin = cn5; break;
                            case "verbosity": origin = verbosity; break;
                            case "site": fromSite = true; break;
                            default: break;
                        }
                    break;
                default:
                    break;
            }
            ++ix;
        }

        return origin;
    }

    /** Decode ConceptNet5 Relation $(D path). */
    Rel decodeCN5RelationPath(S)(S path,
                                 out bool negation,
                                 out bool reversion,
                                 out Tense tense) if (isSomeString!S)
    {
        return path[3..$].decodeRelationPredicate(null, null, Origin.cn5,
                                          negation, reversion, tense);
    }

    /** Read ConceptNet5 CSV Line $(D line) at 0-offset line number $(D lnr). */
    LinkRef readCN5Line(R, N)(R line, N lnr)
    {
        auto rel = Rel.any;
        auto negation = false;
        auto reversion = false;
        auto tense = Tense.unknown;

        NodeRef src, dst;
        NWeight weight;
        auto lang = Lang.unknown;
        auto origin = Origin.unknown;

        auto parts = line.splitter('\t');
        size_t ix;
        foreach (part; parts)
        {
            switch (ix)
            {
                case 1:
                    rel = decodeCN5RelationPath(part, negation, reversion, tense);
                    break;
                case 2:         // source concept
                    try
                    {
                        if (part.skipOver(`/c/`)) { src = readCN5ConceptURI(part); }
                        else { /* dln("TODO ", part); */ }
                        /* dln(part); */
                    }
                    catch (std.utf.UTFException e)
                    {
                        /* dln("UTFException when reading line:", line, */
                        /*     " part:", part, */
                        /*     " lnr:", lnr); */
                    }
                    break;
                case 3:         // destination concept
                    if (part.skipOver(`/c/`)) { dst = readCN5ConceptURI(part); }
                    else { /* dln("TODO ", part); */ }
                    break;
                case 4:
                    if (part != `/ctx/all`) { /* dln("TODO ", part); */ }
                    break;
                case 5:
                    weight = part.to!NWeight;
                    break;
                case 6:
                    origin = decodeCN5OriginPath(part, lang, origin);
                    break;
                case 7:
                    break;
                case 8:
                    if (origin.of(Origin.any)) // if still nothing special
                    {
                        origin = decodeCN5OriginPath(part, lang, origin);
                    }
                    if (origin.of(Origin.any)) // if still nothing special
                    {
                        dln("Could not decode relation ", part);
                    }
                    break;
                default:
                    break;
            }

            ix++;
        }

        if (origin.of(Origin.any)) // if still nothing special
        {
            origin = Origin.cn5;
        }

        if (src.defined &&
            dst.defined)
        {
            return connect(src, rel, dst, lang, origin, weight, negation, reversion);
        }
        else
        {
            return LinkRef.asUndefined;
        }
    }

    /** Read ConceptNet5 Assertions File $(D path) in CSV format.
        Setting $(D useMmFile) to true increases IO-bandwidth by about a magnitude.
     */
    void readCN5File(string path, bool useMmFile = false, size_t maxCount = size_t.max)
    {
        writeln("Reading ConceptNet from ", path, " ...");
        size_t lnr = 0;
        /* TODO Functionize and merge with wordnet.readIx */
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
    void showRelations(uint indent_depth = 2)
    {
        writeln(`Link Count by Relation Type:`);

        import std.range: cycle;
        auto indent = `- `; // TODO use clever range plus indent_depth

        foreach (rel; Rel.min .. Rel.max)
        {
            const count = linkCountsByRel[rel];
            if (count)
            {
                writeln(indent, rel.to!string, `: `, count);
            }
        }

        writeln(`Node Count: `, allNodes.length);

        writeln(`Node Count by Origin:`);
        foreach (source; Origin.min..Origin.max)
        {
            const count = linkSourceCounts[source];
            if (count)
            {
                writeln(indent, source.to!string, `: `, count);
            }
        }

        writeln(`Node Count by Language:`);
        foreach (lang; Lang.min..Lang.max)
        {
            const count = hlangCounts[lang];
            if (count)
            {
                writeln(indent, lang.toName, ` (`, lang.to!string, `) : `, count);
            }
        }

        writeln(`Node Count by Word Kind:`);
        foreach (sense; Sense.min..Sense.max)
        {
            const count = kindCounts[sense];
            if (count)
            {
                writeln(indent, sense, ` (`, sense.to!string, `) : `, count);
            }
        }

        writeln(`Stats:`);

        if (weightSumCN5)
        {
            writeln(indent, `CN5 Weights Min,Max,Average: `, weightMinCN5, ',', weightMaxCN5, ',', cast(NWeight)weightSumCN5/allLinks.length);
            writeln(indent, `CN5 Packed Weights Histogram: `, packedWeightHistogramCN5);
        }
        if (weightSumNELL)
        {
            writeln(indent, `NELL Weights Min,Max,Average: `, weightMinNELL, ',', weightMaxNELL, ',', cast(NWeight)weightSumNELL/allLinks.length);
            writeln(indent, `NELL Packed Weights Histogram: `, packedWeightHistogramNELL);
        }

        writeln(indent, `Node Count (All/Multi-Word): `,
                allNodes.length,
                `/`,
                multiWordNodeLemmaCount);
        writeln(indent, `Lemma Expression Word Length Average: `, exprWordCountSum/nodeRefByLemma.length);
        writeln(indent, `Link Count: `, allLinks.length);
        writeln(indent, `Link Count By Group:`);
        writeln(indent, `- Symmetric: `, symmetricRelCount);
        writeln(indent, `- Transitive: `, transitiveRelCount);

        writeln(indent, `Lemmas by Expr Count: `, lemmasByExpr.length);

        writeln(indent, `Node Indexes by Lemma Count: `, nodeRefByLemma.length);
        writeln(indent, `Node String Length Average: `, cast(NWeight)nodeStringLengthSum/allNodes.length);
        writeln(indent, `Node Connectedness Average: `, cast(NWeight)connectednessSum/2/allNodes.length);
    }

    /** Return Index to Link from $(D a) to $(D b) if present, otherwise LinkRef.max.
     */
    LinkRef areConnectedInOrder(NodeRef a,
                                Rel rel,
                                NodeRef b,
                                bool negation = false)
    {
        const bDir = (rel.isSymmetric ?
                      RelDir.any :
                      RelDir.forward);
        foreach (aLinkRef; nodeAt(a).links)
        {
            const aLink = linkAt(aLinkRef);
            if ((aLink.actors[]
                      .canFind(NodeRef(b, bDir))) &&
                aLink.rel == rel &&
                aLink.negation == negation) // no need to check reversion here because all links are bidirectional
            {
                return aLinkRef;
            }
        }

        return typeof(return).asUndefined;
    }

    /** Return Index to Link relating $(D a) to $(D b) in any direction if present, otherwise LinkRef.max.
     */
    LinkRef areConnected(NodeRef a,
                         Rel rel,
                         NodeRef b,
                         bool negation = false)
    {
        return either(areConnectedInOrder(a, rel, b, negation),
                      areConnectedInOrder(b, rel, a, negation));
    }

    /** Return Index to Link relating if $(D a) and $(D b) if they are related. */
    LinkRef areConnected(in Lemma a,
                        Rel rel,
                        in Lemma b,
                        bool negation = false)
    {
        if (a in nodeRefByLemma && // both lemmas exist
            b in nodeRefByLemma)
        {
            return areConnected(nodeRefByLemma[a],
                                rel,
                                nodeRefByLemma[b],
                                negation);
        }
        return typeof(return).asUndefined;
    }

    void showLink(Rel rel,
                  RelDir dir,
                  bool negation = false,
                  Lang lang = Lang.en)
    {
        auto indent = `    - `;
        write(indent, rel.toHuman(dir, negation, lang), `: `);
    }

    void showLinkRef(LinkRef linkRef)
    {
        auto link = linkAt(linkRef);
        showLink(link.rel, linkRef.dir, link.negation, link.lang);
    }

    void showNode(in Node node, NWeight weight)
    {
        if (node.lemma.expr) write(` `, node.lemma.expr.tr(`_`, ` `));

        write(`(`); // open

        if (node.lemma.lang != Lang.unknown)
        {
            write(node.lemma.lang);
        }
        if (node.lemma.sense != Sense.unknown)
        {
            write(`-`, node.lemma.sense);
        }

        writef(`:%.2f@%s),`, weight, node.origin.toNice); // close
    }

    void showLinkNode(in Node node,
                      Rel rel,
                      NWeight weight,
                      RelDir dir)
    {
        showLink(rel, dir);
        showNode(node, weight);
        writeln();
    }

    /** Show nodes and their relations matching content in $(D line). */
    void showNodes(S)(S line,
                      Lang lang = Lang.unknown,
                      Sense sense = Sense.unknown,
                      S lineSeparator = `_`) if (isSomeString!S)
    {
        import std.ascii: whitespace;
        import std.algorithm: splitter;
        import std.string: strip;

        // auto normLine = line.strip.splitter!isWhite.filter!(a => !a.empty).joiner(lineSeparator).to!S;
        // See also: http://forum.dlang.org/thread/pyabxiraeabfxujiyamo@forum.dlang.org#post-euqwxskfypblfxiqqtga:40forum.dlang.org
        auto normLine = line.strip.tr(std.ascii.whitespace, `_`, `s`).toLower;
        if (normLine.empty)
            return;

        writeln(`> Line `, normLine);

        if (normLine == `palindrome`)
        {
            foreach (palindromeNode; allNodes.filter!(node =>
                                                      node.lemma.expr.toLower.isPalindrome(3)))
            {
                showLinkNode(palindromeNode,
                             Rel.instanceOf,
                             NWeight.infinity,
                             RelDir.backward);
            }
        }
        else if (normLine.skipOver(`anagramsof(`))
        {
            auto split = normLine.findSplitBefore(`)`);
            const arg = split[0];
            if (!arg.empty)
            {
                foreach (anagramNode; anagramsOf(arg))
                {
                    showLinkNode(anagramNode,
                                 Rel.instanceOf,
                                 NWeight.infinity,
                                 RelDir.backward);
                }
            }
        }
        else if (normLine.skipOver(`synonymsOf(`))
        {
            auto split = normLine.findSplitBefore(`)`);
            const arg = split[0];
            if (!arg.empty)
            {
                foreach (synonymNode; synonymsOf(arg))
                {
                    showLinkNode(nodeAt(synonymNode),
                                 Rel.instanceOf,
                                 NWeight.infinity,
                                 RelDir.backward);
                }
            }
        }
        else if (normLine.skipOver(`translationsOf(`))
        {
            auto split = normLine.findSplitBefore(`)`);
            const arg = split[0];
            if (!arg.empty)
            {
                foreach (translationNode; translationsOf(arg))
                {
                    showLinkNode(nodeAt(translationNode),
                                 Rel.instanceOf,
                                 NWeight.infinity,
                                 RelDir.backward);
                }
            }
        }

        if (normLine.empty)
            return;

        // queried line nodes
        auto lineNodeRefs = nodeRefsOf(normLine, lang, sense);

        // as is
        foreach (lineNodeRef; lineNodeRefs)
        {
            const lineNode = nodeAt(lineNodeRef);

            write(`  - in `, lineNode.lemma.lang.toName);
            if (lineNode.lemma.sense != Sense.unknown)
            {
                write(` of sense `, lineNode.lemma.sense);
            }
            writeln();

            LinkRefs linkRefs = linkRefsOf(lineNode); // TODO why is this needed for Array?
            linkRefs[].sort!((a, b) => (linkAt(a).normalizedWeight >
                                        linkAt(b).normalizedWeight));
            foreach (linkRef; linkRefs)
            {
                auto link = linkAt(linkRef);
                showLinkRef(linkRef);
                foreach (linkedNode; link.actors[]
                                         .filter!(actorNodeRef => (actorNodeRef.ix !=
                                                                   lineNodeRef.ix)) // don't self reference
                                         .map!(nodeRef => nodeAt(nodeRef)))
                {
                    showNode(linkedNode, link.normalizedWeight);
                }
                writeln();
            }
        }

        // stemmed
        if (lineNodeRefs.empty)
        {
            while (true)
            {
                const stemStatus = normLine.stemize(lang);
                if (!stemStatus[0])
                    break;
                writeln(`> Stemmed to `, normLine, " in language ", stemStatus[1]);
                showNodes(normLine, lang, sense, lineSeparator);
            }
        }
    }

    auto anagramsOf(S)(S expr) if (isSomeString!S)
    {
        const lsWord = expr.sorted; // letter-sorted expr
        return allNodes.filter!(node => (lsWord != node.lemma.expr.toLower && // don't include one-self
                                         lsWord == node.lemma.expr.toLower.sorted));
    }

    /** TODO: http://rosettacode.org/wiki/Anagrams/Deranged_anagrams#D */
    auto derangedAnagramsOf(S)(S expr) if (isSomeString!S)
    {
        return anagramsOf(expr);
    }

    /** Get Synonyms of $(D word) optionally with Matching Syllable Count.
        Set withSameSyllableCount to true to get synonyms which can be used to
        help in translating songs with same rhythm.
     */
    auto synonymsOf(S)(S expr,
                       Lang lang = Lang.unknown,
                       Sense sense = Sense.unknown,
                       bool withSameSyllableCount = false) if (isSomeString!S)
    {
        auto nodes = nodeRefsOf(expr,
                                lang,
                                sense);
        // TODO tranverse over nodes synonyms
        return nodes;
    }

    /** Get Translations of $(D word) in language $(D lang).
        If several $(D toLangs) are specified pick the closest match (highest
        relation weight).
    */
    auto translationsOf(S)(S expr,
                           Lang lang = Lang.unknown,
                           Sense sense = Sense.unknown,
                           Lang[] toLangs = []) if (isSomeString!S)
    {
        auto nodes = nodeRefsOf(expr,
                                lang,
                                sense);
        const rel = Rel.translationOf;
        // TODO Use synonym transitivity and possibly traverse over synonyms
        // en => sv:
        // en-en => sv-sv
        if (false)
        {
            /* auto translations = nodes.map!(node => linkRefsOf(node, RelDir.any, rel, false))/\* .joiner *\/; */
        }
        return nodes;
    }

    /** Relatedness.
        Sum of all paths relating a to b where each path is the path weight
        product.
    */
    real relatedness(NodeRef a,
                     NodeRef b) const @safe @nogc pure nothrow
    {
        typeof(return) value;
        return value;
    }

    /** Get Node with strongest relatedness to $(D text).
        TODO Compare with function Context() in ConceptNet API.
     */
    Node contextOf(R)(R text) const if (isSourceOfSomeString!R)
    {
        auto node = typeof(return).init;
        return node;
    }
    alias topicOf = contextOf;

    /** Guess Language of $(D text).
    */
    Lang guessLanguageOf(T)(R text) const if (isSourceOfSomeString!R)
    {
        auto lang = Lang.unknown;
        return lang;
    }

}
