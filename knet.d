#!/usr/bin/env rdmd-dev-module

/** Knowledge Graph Database.

    Reads data from DBpedia, Freebase, Yago, BabelNet, ConceptNet, Nell,
    Wikidata, WikiTaxonomy into a Knowledge Graph.

    Applications:
    - Emotion Detection
    - Translate text to use age-relevant words. Use pre-train child book word
      histogram for specific ages.

    See also: www.oneacross.com/crosswords for inspiring applications
    See also: http://programmers.stackexchange.com/q/261163/38719
    See also: https://en.wikipedia.org/wiki/Hypergraph
    See also: https://github.com/commonsense/conceptnet5/wiki
    See also: http://forum.dlang.org/thread/fysokgrgqhplczgmpfws@forum.dlang.org#post-fysokgrgqhplczgmpfws:40forum.dlang.org
    See also: http://www.eturner.net/omcsnetcpp/
    See also: http://wwww.abbreviations.com

    Data: http://www.wordfrequency.info/
    Data: http://conceptnet5.media.mit.edu/downloads/current/
    Data: http://wiki.dbpedia.org/DBpediaAsTables
    Data: http://icon.shef.ac.uk/Moby/
    Data: http://www.dcs.shef.ac.uk/research/ilash/Moby/moby.tar.Z
    Data: http://extensions.openoffice.org/en/search?f%5B0%5D=field_project_tags%3A157
    Data: http://www.mpi-inf.mpg.de/departments/databases-and-information-systems/research/yago-naga/yago/
    Data: http://www.words-to-use.com/
    Data: http://www.ethnologue.com/browse/names

    People: Pat Winston, Jerry Sussman, Henry Liebermann (Knowledge base)

    TODO Google for Henry Liebermann's Open CommonSense Knowledge Base

    BUG book gets incorrect printing "is property of" instead of "has property"

    TODO At end of store() use convert Sense to string Rel.noun => "noun" and store it
         connect(secondRef, Rel.isA, store(groupName, firstLang, Sense.noun, origin), firstLang, origin, weight, false, false, true);

    TODO Replace comma in .txt files with some other ASCII separator

    TODO Learn: https://sv.wikipedia.org/wiki/Modalt_hj%C3%A4lpverb

    TODO If "X Y" gives no hits try "X-Y" then "XY"
    TODO If "X-Y" gives no hits try "X Y" then "XY"

    TODO Use http://www.wordfrequency.info/files/entriesWithoutCollocates.txt etc

    TODO Infer:
         - if X rel Y and assert(R.isSymmetric): Sense can be inferred in both directions if some Sense is unknown
         - shampoo atLocation bathroom, shampoo stored in bottles => bottles atLocation bathroom
         - sulfur synonymWith sulphur => sulfuric synonymWith sulphuric

    TODO Learn word meanings (WordNet) first. Then other higher rules can lookup these
         meanings before they are added.
    TODO For lemmas with Sense.unknown lookup its others lemmasOf. If only one
    other non-unknown Sense exists assume it to be its meaning.

    TODO NodeRef getEmotion(nodeRef start, Rel[] overRels) { walkNodeRefs(); }

    TODO Add randomness to traverser if normalized distance similarity between
    traversed nodes is smaller than a randomnessThreshold

    TODO Integrate Hits from Google: "list of word emotions" using new relations hasEmotionLove

    TODO See checkExisting in connect() to true only for Origin.manual

    TODO Make use of stealFront and stealBack

    TODO ansiktstvätt => facial_wash
    TODO biltvätt => findSplit [bil tvätt] => search("car wash") or search("car_wash") or search("carwash")
    TODO promote equal splits through weigthing sum_over_i(x[i].length^)2

    TODO Template on NodeData and rename Concept to Node. Instantiate with
    NodeData begin Concept and break out Concept outside.

    TODO Profile read
    TODO Use containers.HashMap
    TODO Call GC.disable/enable around construction and search.

    TODO Should we store acronyms and emoticons in lowercase or not?
    TODO Should we lowercase the key Lemma but not the Concept Lemma?

    TODO Extend Link with an array of relation types (Rel) for all its
         actors and context. We can then describe contextual knowledge.
         Perhaps Merge with NELL's CategoryIx.

    BUG Searching for good gives incorrect oppositeOf relations

    BUG No manual learning has been done for cry <oppositeOf> laugh
    > Line cry
    - in English
    - is the opposite of:  laugh(en:1.00@Manual),
    - is the opposite of:  laugh(en-verb:1.00@CN5),
    - is the opposite of:  laugh(en:1.00@Manual),

    BUG hate is learned twice. Add duplicate detection.
    < Concept(s) or ? for help: love
    > Line love
    - in English of sense nounUncountable
    - is a:  uncountable noun(en-nounUncountable:1.00@Manual),
    - in English
    - is the opposite of:  hate(en:1.00@CN5),
    - is the opposite of:  hate(en-verb:1.00@CN5),
    - is the opposite of:  hatred(en-noun:1.00@CN5),
    - is the opposite of:  hate(en:0.55@CN5),

    TODO Why can't File.byLine be used instead of readText?
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
import std.algorithm: findSplit, findSplitBefore, findSplitAfter, groupBy, sort, skipOver, filter, array, canFind, count, setUnion, setIntersection;
import std.container: Array;
import std.string: tr, toLower, toUpper;
import std.uni: isWhite, toLower;
import std.utf: byDchar, UTFException;
import std.typecons: Nullable, Tuple, tuple;
import std.file: readText;
alias rdT = readText;

import algorithm_ex: isPalindrome, either, append;
import range_ex: stealFront, stealBack, ElementType, byPair, pairs;
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

enum char asciiUS = '';       // ASCII Unit Separator
enum char asciiRS = '';       // ASCII Record Separator
enum char asciiGS = '';       // ASCII Group Separator
enum char asciiFS = '';       // ASCII File Separator

enum separator = asciiUS;
enum weightSeparator = '#';

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
    unknown,
    any = unknown,

    cn5,                        ///< ConceptNet5

    dbpedia,                    ///< DBPedia
    // dbpedia37,
    // dbpedia39Umbel,
    // dbpediaEn,

    wordnet,                    ///< WordNet

    umbel,                      ///< http://www.umbel.org/
    jmdict,                     ///< http://www.edrdg.org/jmdict/j_jmdict.html

    verbosity,                  ///< Verbosity
    wiktionary,                 ///< Wiktionary
    nell,                       ///< NELL
    yago,                       ///< Yago
    globalmind,                 ///< GlobalMind

    synlex, ///< Folkets synonymlexikon Synlex http://lexikon.nada.kth.se/synlex.html
    folketsLexikon,
    swesaurus, ///< Swesaurus: http://spraakbanken.gu.se/eng/resource/swesaurus

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
            // case dbpedia37: return "DBpedia37";
            // case dbpedia39Umbel: return "DBpedia39Umbel";
            // case dbpediaEn: return "DBpediaEnglish";

            case wordnet: return "WordNet";

            case umbel: return "umbel";
            case jmdict: return "JMDict";

            case verbosity: return "Verbosity";
            case wiktionary: return "Wiktionary";
            case nell: return "NELL";
            case yago: return "Yago";
            case globalmind: return "GlobalMind";
            case synlex: return "Synlex";
            case folketsLexikon: return "FolketsLexikon";
            case swesaurus: return "Swesaurus";
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

/// Correct Formatting of Lemma Expression $(D s).
auto ref correctLemmaExpr(S)(S s) if (isSomeString!S)
{
    switch (s)
    {
        case "honey be": return "honey bee";
        case "bath room": return "bathroom";
        case "bed room": return "bedroom";
        case "diningroom": return "dining room";
        case "livingroom": return "living room";
        default: return s;
    }
}

/** Main Knowledge Network.
*/
class Net(bool useArray = true,
          bool useRCString = true)
{
    import std.algorithm, std.range, std.path, std.array;
    import wordnet: WordNet;

    /// Normalized (Link) Weight.
    alias NWeight = real;

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

    /** Network Traverser. */
    class Traverser
    {
        this(NodeRef first_)
        {
            first = first_;
            current = first;
        }

        auto front()
        {
            return linkRefsOf(nodeAt(current));
        }

        NodeRef first;
        NodeRef current;
        NWeight[NodeRef] dists;
    }

    Traverser traverse(in Node node)
    {
        typeof(return) trav;
        return trav;
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
            // http://forum.dlang.org/thread/mevnosveagdiswkxtbrv@forum.dlang.org#post-zhndpadqtfareymbnfis:40forum.dlang.org
            this.actors.reserve(this.actors.length + 2);
            this.actors ~= srcRef.backward;
            this.actors ~= dstRef.forward;
            // this.actors.append(srcRef.backward,
            //                    dstRef.backward);
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
        size_t[Sense.max + 1] senseCounts;
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

    NodeRef nodeRefByLemmaMaybe(in Lemma lemma)
    {
        return (lemma in nodeRefByLemma ?
                         nodeRefByLemma[lemma] :
                         typeof(return).init);
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
        return expr in lemmasByExpr ? lemmasByExpr[expr] : typeof(return).init;
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
        const maxCount = quick ? 10000 : size_t.max;

        // Supervised Knowledge
        wordnet = new WordNet!(true, true)([Lang.en]);
        readSynlexFile("~/Knowledge/swesaurus/synpairs.xml".expandTilde.buildNormalizedPath);
        readFolketsFile("~/Knowledge/swesaurus/folkets_en_sv_public.xdxf".expandTilde.buildNormalizedPath, Lang.en, Lang.sv);
        readFolketsFile("~/Knowledge/swesaurus/folkets_sv_en_public.xdxf".expandTilde.buildNormalizedPath, Lang.sv, Lang.en);

        // Learn Absolute (Trusthful) Things before untrusted machine generated data is read
        learnPreciseThings();

        // Learn Less Absolute Things
        learnAssociativeThings();

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

    /** Learn Precise (Absolute) Thing.
     */
    void learnPreciseThings()
    {
        learnEnglishComputerKnowledge();

        learnEnglishIrregularVerbs();

        learnMath();

        learnEnglishOther();

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

        learnReversions();
        learnEtymologicallyDerivedFroms();

        learnSwedishVerbs();
        learnSwedishAdjectives();

        learnEmotions();
        learnEnglishFeelings();
        learnSwedishFeelings();

        // TODO functionize to learnGroup
        learnAttributes(Lang.en, rdT("../knowledge/en/compound_word.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `compound word`, Sense.unknown, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/noun.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `noun`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/people.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `people`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/pronoun.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `pronoun`, Sense.pronoun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/verbs.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `verb`, Sense.verb, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/interjection.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `interjection`, Sense.interjection, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/conjunction.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `conjunction`, Sense.conjunction, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/regular_verb.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `regular verb`, Sense.verb, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/adjective.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `adjective`, Sense.adjective, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/adverb.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `adverb`, Sense.adverb, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/determiner.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `determiner`, Sense.determiner, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/predeterminer.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `predeterminer`, Sense.predeterminer, Sense.noun);

        learnAttributes(Lang.en, rdT("../knowledge/en/dolch_word.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `dolch word`, Sense.unknown, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/personal_quality.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `personal quality`, Sense.adjective, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/adverbs.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `adverb`, Sense.adverb, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/prepositions.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `preposition`, Sense.preposition, Sense.noun);

        learnAttributes(Lang.en, rdT("../knowledge/en/color.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `color`, Sense.unknown, Sense.noun);

        learnAttributes(Lang.en, rdT("../knowledge/en/shapes.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `shape`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/fruits.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `fruit`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/plants.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `plant`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/trees.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `tree`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/shoes.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `shoe`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/dances.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `dance`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/landforms.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `landform`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/desserts.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `dessert`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/countries.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `country`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/us_states.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `us_state`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/furniture.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `furniture`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/good_luck_symbols.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `good luck symbol`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/leaders.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `leader`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/measurements.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `measurement`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/quantity.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `quantity`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/language.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `language`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/insect.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `insect`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/musical_instrument.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `musical instrument`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/weapon.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `weapon`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/hats.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `hat`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/rooms.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `room`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/containers.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `container`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/virtues.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `virtue`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/vegetables.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `vegetable`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/flower.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `flower`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/reptile.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `reptile`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/pair.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `pair`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/season.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `season`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/holiday.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `holiday`, Sense.noun, Sense.noun);

        learnAttributes(Lang.en, rdT("../knowledge/en/birthday.txt").splitter('\n').filter!(w => !w.empty), Rel.any, false, `birthday`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/biomes.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `biome`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/dogs.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `dog`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/rodent.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `rodent`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/fish.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `fish`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/birds.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `bird`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/amphibians.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `amphibian`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/animals.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `animal`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/mammals.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `mammal`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/foods.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `food`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/cars.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `car`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/buildings.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `building`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/housing.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `housing`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/occupation.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `occupation`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/cooking_tool.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `cooking tool`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/tool.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `tool`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/carparts.txt").splitter('\n').filter!(w => !w.empty), Rel.partOf, false, `car`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/bodyparts.txt").splitter('\n').filter!(w => !w.empty), Rel.partOf, false, `body`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/alliterations.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `alliteration`, Sense.unknown, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/positives.txt").splitter('\n').filter!(word => !word.empty), Rel.hasProperty, false, `positive`, Sense.unknown, Sense.adjective);
        learnAttributes(Lang.en, rdT("../knowledge/en/mineral.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `mineral`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/metal.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `metal`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/mineral_group.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `mineral group`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/major_mineral_group.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `major mineral group`, Sense.noun, Sense.noun);

        learnChemicalElements();

        // English
        learnPairs("../knowledge/en/shorthand.txt",
                   Sense.unknown, Lang.en,
                   Rel.shorthandFor,
                   Sense.unknown, Lang.en,
                   Origin.manual, 1.0);
        learnPairs("../knowledge/en/synonym.txt",
                   Sense.unknown, Lang.en,
                   Rel.synonymFor,
                   Sense.unknown, Lang.en,
                   Origin.manual, 1.0);
        learnPairs("../knowledge/en/noun_synonym.txt",
                   Sense.noun, Lang.en,
                   Rel.synonymFor,
                   Sense.noun, Lang.en,
                   Origin.manual, 1.0);
        learnPairs("../knowledge/en/adjective_synonym.txt",
                   Sense.adjective, Lang.en,
                   Rel.synonymFor,
                   Sense.adjective, Lang.en,
                   Origin.manual, 1.0);
        learnPairs("../knowledge/en/acronym.txt",
                   Sense.nounAcronym, Lang.en,
                   Rel.acronymFor,
                   Sense.unknown, Lang.en,
                   Origin.manual, 1.0);

        // Swedish
        learnPairs("../knowledge/sv/synonym.txt",
                   Sense.unknown, Lang.sv,
                   Rel.synonymFor,
                   Sense.unknown, Lang.sv,
                   Origin.manual, 0.5);

        // English-Swedish
        learnPairs("../knowledge/en-sv/noun_translation.txt",
                   Sense.noun, Lang.en,
                   Rel.translationOf,
                   Sense.noun, Lang.sv,
                   Origin.manual, 1.0);
        learnPairs("../knowledge/en-sv/phrase_translation.txt",
                   Sense.unknown, Lang.en,
                   Rel.translationOf,
                   Sense.unknown, Lang.sv,
                   Origin.manual, 1.0);

        learnOpposites();
    }

    /// Learn Assocative Things.
    void learnAssociativeThings()
    {
        // TODO lower weights on these are not absolute
        learnAttributes(Lang.en, rdT("../knowledge/en/constitution.txt").splitter('\n').filter!(w => !w.empty), Rel.any, false, `constitution`, Sense.unknown, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/election.txt").splitter('\n').filter!(w => !w.empty), Rel.any, false, `election`, Sense.unknown, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/weather.txt").splitter('\n').filter!(w => !w.empty), Rel.any, false, `weather`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/dentist.txt").splitter('\n').filter!(w => !w.empty), Rel.any, false, `dentist`, Sense.unknown, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/firefighting.txt").splitter('\n').filter!(w => !w.empty), Rel.any, false, `fire fighting`, Sense.unknown, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/driving.txt").splitter('\n').filter!(w => !w.empty), Rel.any, false, `drive`, Sense.unknown, Sense.verb);
        learnAttributes(Lang.en, rdT("../knowledge/en/art.txt").splitter('\n').filter!(w => !w.empty), Rel.any, false, `art`, Sense.unknown, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/astronomy.txt").splitter('\n').filter!(w => !w.empty), Rel.any, false, `astronomy`, Sense.unknown, Sense.noun);

        learnAttributes(Lang.en, rdT("../knowledge/en/vacation.txt").splitter('\n').filter!(w => !w.empty), Rel.any, false, `vacation`, Sense.unknown, Sense.noun);

        learnAttributes(Lang.en, rdT("../knowledge/en/autumn.txt").splitter('\n').filter!(w => !w.empty), Rel.any, false, `autumn`, Sense.unknown, Sense.nounSeason);
        learnAttributes(Lang.en, rdT("../knowledge/en/winter.txt").splitter('\n').filter!(w => !w.empty), Rel.any, false, `winter`, Sense.unknown, Sense.nounSeason);
        learnAttributes(Lang.en, rdT("../knowledge/en/spring.txt").splitter('\n').filter!(w => !w.empty), Rel.any, false, `spring`, Sense.unknown, Sense.nounSeason);

        learnAttributes(Lang.en, rdT("../knowledge/en/household_device.txt").splitter('\n').filter!(w => !w.empty), Rel.atLocation, false, `house`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/household_device.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `device`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/farm.txt").splitter('\n').filter!(w => !w.empty), Rel.atLocation, false, `farm`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/school.txt").splitter('\n').filter!(w => !w.empty), Rel.atLocation, false, `school`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/circus.txt").splitter('\n').filter!(w => !w.empty), Rel.atLocation, false, `circus`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/near_yard.txt").splitter('\n').filter!(w => !w.empty), Rel.atLocation, false, `yard`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/restaurant.txt").splitter('\n').filter!(w => !w.empty), Rel.atLocation, false, `restaurant`, Sense.noun, Sense.noun);

        learnAttributes(Lang.en, rdT("../knowledge/en/bathroom.txt").splitter('\n').filter!(w => !w.empty), Rel.atLocation, false, `bathroom`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/house.txt").splitter('\n').filter!(w => !w.empty), Rel.atLocation, false, `house`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/kitchen.txt").splitter('\n').filter!(w => !w.empty), Rel.atLocation, false, `kitchen`, Sense.noun, Sense.noun);

        learnAttributes(Lang.en, rdT("../knowledge/en/beach.txt").splitter('\n').filter!(w => !w.empty), Rel.atLocation, false, `beach`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/ocean.txt").splitter('\n').filter!(w => !w.empty), Rel.atLocation, false, `ocean`, Sense.noun, Sense.noun);

        learnAttributes(Lang.en, rdT("../knowledge/en/happy.txt").splitter('\n').filter!(w => !w.empty), Rel.similarTo, false, `happy`, Sense.adjective, Sense.adjective);
        learnAttributes(Lang.en, rdT("../knowledge/en/big.txt").splitter('\n').filter!(w => !w.empty), Rel.similarTo, false, `big`, Sense.adjective, Sense.adjective);
        learnAttributes(Lang.en, rdT("../knowledge/en/many.txt").splitter('\n').filter!(w => !w.empty), Rel.similarTo, false, `many`, Sense.adjective, Sense.adjective);
        learnAttributes(Lang.en, rdT("../knowledge/en/easily_upset.txt").splitter('\n').filter!(w => !w.empty), Rel.similarTo, false, `easily upset`, Sense.adjective, Sense.adjective);

        learnAttributes(Lang.en, rdT("../knowledge/en/roadway.txt").splitter('\n').filter!(w => !w.empty), Rel.any, false, `roadway`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/baseball.txt").splitter('\n').filter!(w => !w.empty), Rel.any, false, `baseball`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/boat.txt").splitter('\n').filter!(w => !w.empty), Rel.any, false, `boat`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/money.txt").splitter('\n').filter!(w => !w.empty), Rel.any, false, `money`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/family.txt").splitter('\n').filter!(w => !w.empty), Rel.any, false, `family`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/geography.txt").splitter('\n').filter!(w => !w.empty), Rel.any, false, `geography`, Sense.unknown, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/energy.txt").splitter('\n').filter!(w => !w.empty), Rel.any, false, `energy`, Sense.unknown, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/time.txt").splitter('\n').filter!(w => !w.empty), Rel.any, false, `time`, Sense.unknown, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/water.txt").splitter('\n').filter!(w => !w.empty), Rel.any, false, `water`, Sense.unknown, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/clothing.txt").splitter('\n').filter!(w => !w.empty), Rel.any, false, `clothing`, Sense.unknown, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/music_theory.txt").splitter('\n').filter!(w => !w.empty), Rel.any, false, `music theory`, Sense.unknown, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/happiness.txt").splitter('\n').filter!(w => !w.empty), Rel.any, false, `happiness`, Sense.unknown, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/pirate.txt").splitter('\n').filter!(w => !w.empty), Rel.any, false, `pirate`, Sense.unknown, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/monster.txt").splitter('\n').filter!(w => !w.empty), Rel.any, false, `monster`, Sense.unknown, Sense.noun);

        learnAttributes(Lang.en, rdT("../knowledge/en/halloween.txt").splitter('\n').filter!(w => !w.empty), Rel.any, false, `halloween`, Sense.unknown, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/christmas.txt").splitter('\n').filter!(w => !w.empty), Rel.any, false, `christmas`, Sense.unknown, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/thanksgiving.txt").splitter('\n').filter!(w => !w.empty), Rel.any, false, `thanksgiving`, Sense.unknown, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/camp.txt").splitter('\n').filter!(w => !w.empty), Rel.any, false, `camp`, Sense.unknown, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/cooking.txt").splitter('\n').filter!(w => !w.empty), Rel.any, false, `cooking`, Sense.unknown, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/sewing.txt").splitter('\n').filter!(w => !w.empty), Rel.any, false, `sewing`, Sense.unknown, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/military.txt").splitter('\n').filter!(w => !w.empty), Rel.any, false, `military`, Sense.unknown, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/science.txt").splitter('\n').filter!(w => !w.empty), Rel.any, false, `science`, Sense.unknown, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/computer.txt").splitter('\n').filter!(w => !w.empty), Rel.any, false, `computer`, Sense.unknown, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/math.txt").splitter('\n').filter!(w => !w.empty), Rel.any, false, `math`, Sense.unknown, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/transport.txt").splitter('\n').filter!(w => !w.empty), Rel.any, false, `transport`, Sense.unknown, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/rock.txt").splitter('\n').filter!(w => !w.empty), Rel.any, false, `rock`, Sense.unknown, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/doctor.txt").splitter('\n').filter!(w => !w.empty), Rel.any, false, `doctor`, Sense.unknown, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/st-patricks-day.txt").splitter('\n').filter!(w => !w.empty), Rel.any, false, `St. Patrick's Day`, Sense.unknown, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/new-years-eve.txt").splitter('\n').filter!(w => !w.empty), Rel.any, false, `New Year's Eve`, Sense.unknown, Sense.noun);

        learnAttributes(Lang.en, rdT("../knowledge/en/say.txt").splitter('\n').filter!(w => !w.empty), Rel.specializes, false, `say`, Sense.verb, Sense.verb);
        learnAttributes(Lang.en, rdT("../knowledge/en/book_property.txt").splitter('\n').filter!(w => !w.empty), Rel.hasProperty, true, `book`, Sense.adjective, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/informal.txt").splitter('\n').filter!(w => !w.empty), Rel.hasProperty, false, `informal`, Sense.adjective, Sense.noun);

        learnAttributes(Lang.en, rdT("../knowledge/en/literary_genre.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `literary genre`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/major_literary_form.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `major literary form`, Sense.noun, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/classic_major_literary_genre.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `classic major literary genre`, Sense.noun, Sense.noun);

        // English Names
        learnAttributes(Lang.en, rdT("../knowledge/en/female_name.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `female name`, Sense.nounNameFemale, Sense.noun);
        learnAttributes(Lang.en, rdT("../knowledge/en/male_name.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `male name`, Sense.nounNameMale, Sense.noun);

        // Swedish Names
        learnAttributes(Lang.sv, rdT("../knowledge/sv/female_name.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `female name`, Sense.nounNameFemale, Sense.noun);
        learnAttributes(Lang.sv, rdT("../knowledge/sv/male_name.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `male name`, Sense.nounNameMale, Sense.noun);
        learnAttributes(Lang.sv, rdT("../knowledge/sv/surname.txt").splitter('\n').filter!(w => !w.empty), Rel.isA, false, `surname`, Sense.nounNameSur, Sense.noun);

        learnPairs("../knowledge/en/color_adjective.txt",
                   Sense.adjective, Lang.en,
                   Rel.similarTo,
                   Sense.unknown, Lang.en,
                   Origin.manual, 0.5);
   }

    /// Learn Emotions.
    void learnEmotions()
    {
        const groups = ["basic", "positive", "negative", "strong", "medium", "light"];
        foreach (group; groups)
        {
            learnAttributes(Lang.en,
                            rdT("../knowledge/en/" ~ group ~ "_emotion.txt").splitter('\n').filter!(word => !word.empty),
                            Rel.isA, false, group ~ ` emotion`, Sense.unknown, Sense.noun);
        }
    }

    /// Learn English Feelings.
    void learnEnglishFeelings()
    {
        learnAttributes(Lang.en, rdT("../knowledge/en/feeling.txt").splitter('\n').filter!(word => !word.empty), Rel.isA, false, `feeling`, Sense.adjective, Sense.noun);
        const feelings = ["afraid", "alive", "angry", "confused", "depressed", "good", "happy",
                          "helpless", "hurt", "indifferent", "interested", "love",
                          "negative", "unpleasant",
                          "positive", "pleasant",
                          "open", "sad", "strong"];
        foreach (feeling; feelings)
        {
            const path = "../knowledge/en/" ~ feeling ~ "_feeling.txt";
            learnAssociations(path, Rel.similarTo, feeling.tr(`_`, ` `) ~ ` feeling`, Sense.adjective, Sense.adjective);
        }
    }

    /// Learn Swedish Feelings.
    void learnSwedishFeelings()
    {
        learnAttributes(Lang.sv,
                        rdT("../knowledge/sv/känsla.txt").splitter('\n').filter!(word => !word.empty),
                        Rel.isA, false, `känsla`, Sense.noun, Sense.noun);
    }

    /// Read and Learn Assocations.
    void learnAssociations(S)(string path,
                              Rel rel,
                              S attribute,
                              Sense wordSense = Sense.unknown,
                              Sense attributeSense = Sense.noun,
                              Lang lang = Lang.en,
                              Origin origin = Origin.manual) if (isSomeString!S)
    {
        foreach (expr; File(path).byLine)
        {
            if (expr.empty) { continue; }

            auto split = expr.findSplit([weightSeparator]); // TODO allow key to be ElementType of Range to prevent array creation here
            const name = split[0], weight = split[2];

            NWeight nweight = 1.0;
            if (!weight.empty)
            {
                const w = weight.to!NWeight;
                nweight = w/(1 + w); // normalized weight
            }

            connect(store(name.idup, lang, wordSense, origin),
                    rel,
                    store(attribute, lang, attributeSense, origin),
                    lang, origin, nweight);
        }
    }

    /// Learn Chemical Elements.
    void learnChemicalElements(Lang lang = Lang.en, Origin origin = Origin.manual)
    {
        foreach (expr; File("../knowledge/en/chemical_elements.txt").byLine)
        {
            if (expr.empty) { continue; }
            auto split = expr.findSplit([separator]); // TODO allow key to be ElementType of Range to prevent array creation here
            const name = split[0], abbr = split[2];
            NWeight weight = 1.0;
            connect(store(name.idup, lang, Sense.noun, origin),
                    Rel.isA,
                    store("chemical element", lang, Sense.noun, origin),
                    lang, origin, weight);
            connect(store(abbr.idup, lang, Sense.noun, origin), // TODO store capitalized?
                    Rel.abbreviationFor,
                    store(name.idup, lang, Sense.noun, origin),
                    lang, origin, weight);
        }
    }

    /// Learn Pairs of Words.
    void learnPairs(string path,
                    Sense firstSense, Lang firstLang,
                    Rel rel,
                    Sense secondSense, Lang secondLang,
                    Origin origin = Origin.manual,
                    NWeight weight = 0.5)
    {
        foreach (expr; File(path).byLine)
        {
            if (expr.empty) { continue; }
            auto split = expr.findSplit([separator]); // TODO allow key to be ElementType of Range to prevent array creation here
            const first = split[0], second = split[2];

            auto firstRef = store(first.idup, firstLang, firstSense, origin);

            if (!second.empty)
            {
                auto secondRef = store(second.idup, secondLang, secondSense, origin);
                connect(firstRef, rel, secondRef, secondLang, origin, weight, false, false, true);
            }
        }
    }

    /// Get Learn Possible Senses for $(D expr).
    auto sensesOf(S)(S expr) if (isSomeString!S)
    {
        return lemmasOf(expr).map!(lemma => lemma.sense).filter!(sense => sense != Sense.unknown);
    }

    /// Get Possible Common Sense for $(D a) and $(D b). TODO N-ary
    Sense commonSense(S1, S2)(S1 a, S2 b) if (isSomeString!S1 &&
                                              isSomeString!S2)
    {
        auto commonSenses = setIntersection(sensesOf(a).sorted,
                                            sensesOf(b).sorted);
        return commonSenses.count == 1 ? commonSenses.front : Sense.unknown;
    }

    /// Learn Opposites.
    void learnOpposites(Lang lang = Lang.en, Origin origin = Origin.manual)
    {
        foreach (expr; File("../knowledge/en/opposites.txt").byLine)
        {
            if (expr.empty) { continue; }
            auto split = expr.findSplit([separator]); // TODO allow key to be ElementType of Range to prevent array creation here
            const first = split[0], second = split[2];
            NWeight weight = 1.0;
            const sense = commonSense(first, second);
            connect(store(first.idup, lang, sense, origin),
                    Rel.oppositeOf,
                    store(second.idup, lang, sense, origin),
                    lang, origin, weight);
        }
    }

    /// Learn Reversions.
    void learnReversions()
    {
        // TODO Copy all from krels.toHuman
        learnReversion("is a", "can be", Lang.en);
        learnReversion("leads to", "can infer", Lang.en);
        learnReversion("is part of", "contains", Lang.en);
        learnReversion("is member of", "has member", Lang.en);
    }

    /// Learn Reversion.
    LinkRef[] learnReversion(S)(S forward,
                                S backward,
                                Lang lang = Lang.unknown) if (isSomeString!S)
    {
        const origin = Origin.manual;
        auto all = [store(forward, lang, Sense.verbInfinitive, origin),
                    store(backward, lang, Sense.verbPastParticiple, origin)];
        return connectAll(Rel.reversionOf, all.filter!(a => a.defined), lang, origin);
    }

    /// Learn Etymologically Derived Froms.
    void learnEtymologicallyDerivedFroms()
    {
        learnEtymologicallyDerivedFrom("holiday", Lang.en, "holy day", Lang.en, Sense.noun);
        learnEtymologicallyDerivedFrom("juletide", Lang.en, "juletid", Lang.sv, Sense.noun);
        learnEtymologicallyDerivedFrom("smorgosbord", Lang.en, "smörgåsbord", Lang.sv, Sense.noun);
    }

    /** Learn that $(D first) in language $(D firstLang) is etymologically
        derived from $(D second) in language $(D secondLang) both in sense $(D sense).
     */
    LinkRef learnEtymologicallyDerivedFrom(S)(S first, Lang firstLang,
                                              S second, Lang secondLang,
                                              Sense sense) if (isSomeString!S)
    {
        return connect(store(first, firstLang, Sense.noun, Origin.manual),
                       Rel.etymologicallyDerivedFrom,
                       store(second, secondLang, Sense.noun, Origin.manual),
                       Lang.unknown, Origin.manual, 1.0);
    }

    /** Learn English Irregular Verb.
     */
    LinkRef[] learnEnglishIrregularVerb(S1, S2, S3)(S1 infinitive,
                                                    S2 past,
                                                    S3 pastParticiple,
                                                    Origin origin = Origin.manual)
    {
        enum lang = Lang.en;
        NodeRef[] all;
        all ~= store(infinitive, lang, Sense.verbInfinitive, origin);
        all ~= store(past, lang, Sense.verbPast, origin);
        all ~= store(pastParticiple, lang, Sense.verbPastParticiple, origin);
        return connectAll(Rel.verbForm, all.filter!(a => a.defined), lang, origin);
    }

    /** Learn English Acronym.
     */
    LinkRef learnEnglishAcronym(S)(S acronym,
                                   S expr,
                                   NWeight weight = 1.0,
                                   Sense sense = Sense.unknown,
                                   Origin origin = Origin.manual) if (isSomeString!S)
    {
        enum lang = Lang.en;
        return connect(store(acronym.toLower, lang, Sense.nounAcronym, origin),
                       Rel.acronymFor,
                       store(expr.toLower, lang, sense, origin),
                       lang, origin, weight);
    }

    /** Learn English $(D words) related to attribute.
     */
    LinkRef[] learnAttributes(R, S)(Lang lang,
                                    R words,
                                    Rel rel, bool reversion,
                                    S attribute,
                                    Sense wordSense = Sense.unknown,
                                    Sense attributeSense = Sense.noun,
                                    NWeight weight = 0.5,
                                    Origin origin = Origin.manual) if (isInputRange!R &&
                                                                  (isSomeString!(ElementType!R)) &&
                                                                  isSomeString!S)
    {
        return connectMto1(store(words.map!toLower, lang, wordSense, origin),
                           rel, reversion,
                           store(attribute.toLower, lang, attributeSense, origin),
                           Lang.en, origin, weight);
    }

    /** Learn English Emoticon.
     */
    LinkRef[] learnEnglishEmoticon(S)(S[] emoticons,
                                      S[] exprs,
                                      NWeight weight = 1.0,
                                      Sense sense = Sense.unknown,
                                      Origin origin = Origin.manual) if (isSomeString!S)
    {
        return connectMtoN(store(emoticons.map!toLower, Lang.any, Sense.unknown, origin),
                           Rel.emoticonFor,
                           store(exprs.map!toLower, Lang.en, sense, origin),
                           Lang.en, origin, weight);
    }

    /** Learn English Computer Acronyms.
     */
    void learnEnglishComputerKnowledge()
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
        learnEnglishAcronym("AWT", "Asynchronous WriteThrough");
        learnEnglishAcronym("BGP", "Basic Graph Pattern");
        learnEnglishAcronym("BLOB", "Binary Large Object");
        learnEnglishAcronym("CBC", "Cipher Block Chaining");
        learnEnglishAcronym("CCA", "Control Center Agent");
        learnEnglishAcronym("CDATA", "Character DATA");
        learnEnglishAcronym("CDS", "Cell Directory Services");
        learnEnglishAcronym("CFS", "Cluster File System");
        learnEnglishAcronym("CIDR", "Classless Inter-Domain Routing");
        learnEnglishAcronym("CLOB", "Character Large OBject");
        learnEnglishAcronym("CMADMIN", "Connection Manager Administration");
        learnEnglishAcronym("CMGW", "Connection Manager GateWay");
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
        learnEnglishAcronym("DBA", "DataBase Administrator");
        learnEnglishAcronym("DBMS", "DataBase Management System");
        learnEnglishAcronym("DBPITR", "Database Point-In-Time Recovery");
        learnEnglishAcronym("DBW", "Database Writer");
        learnEnglishAcronym("DCE", "Distributed Computing Environment");
        learnEnglishAcronym("DCOM", "Distributed Component Object Model");
        learnEnglishAcronym("DDL LCR", "DDL Logical Change Record");
        learnEnglishAcronym("DHCP", "Dynamic Host Configuration Protocol");
        learnEnglishAcronym("DICOM", "Digital Imaging and Communications in Medicine");
        learnEnglishAcronym("DIT", "Directory Information Tree");
        learnEnglishAcronym("DLL", "Dynamic-Link Library");
        learnEnglishAcronym("DN", "Distinguished Name");
        learnEnglishAcronym("DNS", "Domain Name System");
        learnEnglishAcronym("DOM", "Document Object Model");
        learnEnglishAcronym("DTD", "Document Type Definition");
        learnEnglishAcronym("DTP", "Distributed Transaction Processing");
        learnEnglishAcronym("Dnnn", "Dispatcher Process");
        learnEnglishAcronym("DoS", "Denial-Of-Service");
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
        learnEnglishAcronym("GIS", "Geographic Information System");
        learnEnglishAcronym("GNS", "Grid Naming Service");
        learnEnglishAcronym("GNSD", "Grid Naming Service Daemon");
        learnEnglishAcronym("GPFS", "General Parallel File System");
        learnEnglishAcronym("GSD", "Global Services Daemon");
        learnEnglishAcronym("GV$", "global dynamic performance views");
        learnEnglishAcronym("HACMP", "High Availability Cluster Multi-Processing");
        learnEnglishAcronym("HBA", "Host Bus Adapter");
        learnEnglishAcronym("IDE", "Integrated Development Environment");
        learnEnglishAcronym("IPC", "Interprocess Communication");
        learnEnglishAcronym("IPv4", "IP Version 4");
        learnEnglishAcronym("IPv6", "IP Version 6");
        learnEnglishAcronym("ITL", "Interested Transaction List");
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
        learnEnglishAcronym("LCR", "Logical Change Record");
        learnEnglishAcronym("LDAP", "Lightweight Directory Access Protocol");
        learnEnglishAcronym("LDIF", "Lightweight Directory Interchange Format");
        learnEnglishAcronym("LGWR", "LoG WRiter");
        learnEnglishAcronym("LMD", "Global Enqueue Service Daemon");
        learnEnglishAcronym("LMON", "Global Enqueue Service Monitor");
        learnEnglishAcronym("LMSn", "Global Cache Service Processes");
        learnEnglishAcronym("LOB", "Large OBject");
        learnEnglishAcronym("LOBs", "Large Objects");
        learnEnglishAcronym("LRS Segment", "Geometric Segment");
        learnEnglishAcronym("LUN", "Logical Unit Number");
        learnEnglishAcronym("LUNs", "Logical Unit Numbers");
        learnEnglishAcronym("LVM", "Logical Volume Manager");
        learnEnglishAcronym("MAPI", "Messaging Application Programming Interface");
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
        learnEnglishAcronym("ASM", "Automatic Storage Management");
        learnEnglishAcronym("RAC", "Real Application Clusters");
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
        learnEnglishAcronym("SID", "System IDentifier");
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
        learnEnglishAcronym("UID", "Unique IDentifier");
        learnEnglishAcronym("UIX", "User Interface XML");
        learnEnglishAcronym("UNC", "Universal Naming Convention");
        learnEnglishAcronym("UTC", "Coordinated Universal Time");
        learnEnglishAcronym("VPD", "Virtual Private Database");
        learnEnglishAcronym("VSS", "Volume Shadow Copy Service");
        learnEnglishAcronym("W3C", "World Wide Web Consortium");
        learnEnglishAcronym("WG", "Working Group");
        learnEnglishAcronym("WebDAV", "World Wide Web Distributed Authoring and Versioning");
        learnEnglishAcronym("Winsock", "Windows sockets");
        learnEnglishAcronym("XDK", "XML Developer's Kit");
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

        // TODO Context: Digital Communications
    	learnEnglishAcronym("AAMOF", "as a matter of fact");
	learnEnglishAcronym("ABFL", "a big fat lady");
	learnEnglishAcronym("ABT", "about");
	learnEnglishAcronym("ADN", "any day now");
	learnEnglishAcronym("AFAIC", "as far as I’m concerned");
	learnEnglishAcronym("AFAICT", "as far as I can tell");
	learnEnglishAcronym("AFAICS", "as far as I can see");
	learnEnglishAcronym("AFAIK", "as far as I know");
	learnEnglishAcronym("AFAYC", "as far as you’re concerned");
	learnEnglishAcronym("AFK", "away from keyboard");
	learnEnglishAcronym("AH", "asshole");
	learnEnglishAcronym("AISI", "as I see it");
	learnEnglishAcronym("AIUI", "as I understand it");
	learnEnglishAcronym("AKA", "also known as");
	learnEnglishAcronym("AML", "all my love");
	learnEnglishAcronym("ANFSCD", "and now for something completely different");
	learnEnglishAcronym("ASAP", "as soon as possible");
	learnEnglishAcronym("ASL", "assistant section leader");
	learnEnglishAcronym("ASL", "age, sex, location");
	learnEnglishAcronym("ASLP", "age, sex, location, picture");
	learnEnglishAcronym("A/S/L", "age/sex/location");
	learnEnglishAcronym("ASOP", "assistant system operator");
	learnEnglishAcronym("ATM", "at this moment");
	learnEnglishAcronym("AWA", "as well as");
	learnEnglishAcronym("AWHFY", "are we having fun yet?");
	learnEnglishAcronym("AWGTHTGTTA", "are we going to have to go trough this again?");
	learnEnglishAcronym("AWOL", "absent without leave");
	learnEnglishAcronym("AWOL", "away without leave");
	learnEnglishAcronym("AYOR", "at your own risk");
	learnEnglishAcronym("AYPI", "?	and your point is?");

	learnEnglishAcronym("B4", "before");
	learnEnglishAcronym("BAC", "back at computer");
	learnEnglishAcronym("BAG", "busting a gut");
	learnEnglishAcronym("BAK", "back at the keyboard");
	learnEnglishAcronym("BBIAB", "be back in a bit");
	learnEnglishAcronym("BBL", "be back later");
	learnEnglishAcronym("BBLBNTSBO", "be back later but not to soon because of");
	learnEnglishAcronym("BBR", "burnt beyond repair");
	learnEnglishAcronym("BBS", "be back soon");
	learnEnglishAcronym("BBS", "bulletin board system");
	learnEnglishAcronym("BC", "be cool");
	learnEnglishAcronym("B", "/C	because");
	learnEnglishAcronym("BCnU", "be seeing you");
	learnEnglishAcronym("BEG", "big evil grin");
	learnEnglishAcronym("BF", "boyfriend");
	learnEnglishAcronym("B/F", "boyfriend");
	learnEnglishAcronym("BFN", "bye for now");
	learnEnglishAcronym("BG", "big grin");
	learnEnglishAcronym("BION", "believe it or not");
	learnEnglishAcronym("BIOYIOB", "blow it out your I/O port");
	learnEnglishAcronym("BITMT", "but in the meantime");
	learnEnglishAcronym("BM", "bite me");
	learnEnglishAcronym("BMB", "bite my bum");
	learnEnglishAcronym("BMTIPG", "brilliant minds think in parallel gutters");
	learnEnglishAcronym("BKA", "better known as");
	learnEnglishAcronym("BL", "belly laughing");
	learnEnglishAcronym("BOB", "back off bastard");
	learnEnglishAcronym("BOL", "be on later");
	learnEnglishAcronym("BOM", "bitch of mine");
	learnEnglishAcronym("BOT", "back on topic");
	learnEnglishAcronym("BRB", "be right back");
	learnEnglishAcronym("BRBB", "be right back bitch");
	learnEnglishAcronym("BRBS", "be right back soon");
	learnEnglishAcronym("BRH", "be right here");
	learnEnglishAcronym("BRS", "big red switch");
	learnEnglishAcronym("BS", "big smile");
	learnEnglishAcronym("BS", "bull shit");
	learnEnglishAcronym("BSF", "but seriously folks");
	learnEnglishAcronym("BST", "but seriously though");
	learnEnglishAcronym("BTA", "but then again");
	learnEnglishAcronym("BTAIM", "be that as it may");
	learnEnglishAcronym("BTDT", "been there done that");
	learnEnglishAcronym("BTOBD", "be there or be dead");
	learnEnglishAcronym("BTOBS", "be there or be square");
	learnEnglishAcronym("BTSOOM", "beats the shit out of me");
	learnEnglishAcronym("BTW", "by the way");
	learnEnglishAcronym("BUDWEISER", "because you deserve what every individual should ever receive");
	learnEnglishAcronym("BWQ", "buzz word quotient");
	learnEnglishAcronym("BWTHDIK", "but what the heck do I know");
	learnEnglishAcronym("BYOB", "bring your own bottle");
	learnEnglishAcronym("BYOH", "Bat You Onna Head");

	learnEnglishAcronym("C&G", "chuckle and grin");
	learnEnglishAcronym("CAD", "ctrl-alt-delete");
	learnEnglishAcronym("CADET", "can’t add, doesn’t even try");
	learnEnglishAcronym("CDIWY", "couldn’t do it without you");
	learnEnglishAcronym("CFV", "call for votes");
	learnEnglishAcronym("CFS", "care for secret?");
	learnEnglishAcronym("CFY", "calling for you");
	learnEnglishAcronym("CID", "crying in disgrace");
	learnEnglishAcronym("CIM", "CompuServe information manager");
	learnEnglishAcronym("CLM", "career limiting move");
	learnEnglishAcronym("CM@TW", "catch me at the web");
	learnEnglishAcronym("CMIIW", "correct me if I’m wrong");
	learnEnglishAcronym("CNP", "continue in next post");
	learnEnglishAcronym("CO", "conference");
	learnEnglishAcronym("CRAFT", "can’t remember a f**king thing");
	learnEnglishAcronym("CRS", "can’t remember shit");
	learnEnglishAcronym("CSG", "chuckle snicker grin");
	learnEnglishAcronym("CTS", "changing the subject");
	learnEnglishAcronym("CU", "see you");
	learnEnglishAcronym("CU2", "see you too");
	learnEnglishAcronym("CUL", "see you later");
	learnEnglishAcronym("CUL8R", "see you later");
	learnEnglishAcronym("CWOT", "complete waste of time");
	learnEnglishAcronym("CWYL", "chat with you later");
	learnEnglishAcronym("CYA", "see ya");
	learnEnglishAcronym("CYA", "cover your ass");
	learnEnglishAcronym("CYAL8R", "see ya later");
	learnEnglishAcronym("CYO", "see you online");

	learnEnglishAcronym("DBA", "doing business as");
	learnEnglishAcronym("DCed", "disconnected");
	learnEnglishAcronym("DFLA", "disenhanced four-letter acronym");
	learnEnglishAcronym("DH", "darling husband");
	learnEnglishAcronym("DIIK", "darn if i know");
	learnEnglishAcronym("DGA", "digital guardian angel");
	learnEnglishAcronym("DGARA", "don’t give a rats ass");
	learnEnglishAcronym("DIKU", "do I know you?");
	learnEnglishAcronym("DIRTFT", "do it right the first time");
	learnEnglishAcronym("DITYID", "did I tell you I’m distressed");
	learnEnglishAcronym("DIY", "do it yourself");
	learnEnglishAcronym("DL", "download");
	learnEnglishAcronym("DL", "dead link");
	learnEnglishAcronym("DLTBBB", "don’t let the bad bugs bite");
	learnEnglishAcronym("DMMGH", "don’t make me get hostile");
	learnEnglishAcronym("DQMOT", "don’t quote me on this");
	learnEnglishAcronym("DND", "do not disturb");
	learnEnglishAcronym("DTC", "damn this computer");
	learnEnglishAcronym("DTRT", "do the right thing");
	learnEnglishAcronym("DUCT", "did you see that?");
	learnEnglishAcronym("DWAI", "don’t worry about it");
	learnEnglishAcronym("DWIM", "do what I mean");
	learnEnglishAcronym("DWIMC", "do what I mean, correctly");
	learnEnglishAcronym("DWISNWID", "do what I say, not what I do");
	learnEnglishAcronym("DYJHIW", "don’t you just hate it when...");
	learnEnglishAcronym("DYK", "do you know");

	learnEnglishAcronym("EAK", "eating at keyboard");
	learnEnglishAcronym("EIE", "enough is enough");
	learnEnglishAcronym("EG", "evil grin");
	learnEnglishAcronym("EMFBI", "excuse me for butting in");
	learnEnglishAcronym("EMFJI", "excuse me for jumping in");
	learnEnglishAcronym("EMSG", "email message");
	learnEnglishAcronym("EOD", "end of discussion");
	learnEnglishAcronym("EOF", "end of file");
	learnEnglishAcronym("EOL", "end of lecture");
	learnEnglishAcronym("EOM", "end of message");
	learnEnglishAcronym("EOS", "end of story");
	learnEnglishAcronym("EOT", "end of thread");
	learnEnglishAcronym("ETLA", "extended three letter acronym");
	learnEnglishAcronym("EYC", "excitable, yet calm");

	learnEnglishAcronym("F", "female");
	learnEnglishAcronym("F/F", "face to face");
	learnEnglishAcronym("F2F", "face to face");
	learnEnglishAcronym("FAQ", "frequently asked questions");
	learnEnglishAcronym("FAWC", "for anyone who cares");
	learnEnglishAcronym("FBOW", "for better or worse");
	learnEnglishAcronym("FBTW", "fine, be that way");
	learnEnglishAcronym("FCFS", "first come, first served");
	learnEnglishAcronym("FCOL", "for crying out loud");
	learnEnglishAcronym("FIFO", "first in, first out");
	learnEnglishAcronym("FISH", "first in, still here");
	learnEnglishAcronym("FLA", "four-letter acronym");
	learnEnglishAcronym("FOAD", "f**k off and die");
	learnEnglishAcronym("FOAF", "friend of a friend");
	learnEnglishAcronym("FOB", "f**k off bitch");
	learnEnglishAcronym("FOC", "free of charge");
	learnEnglishAcronym("FOCL", "falling of chair laughing");
	learnEnglishAcronym("FOFL", "falling on the floor laughing");
	learnEnglishAcronym("FOS", "freedom of speech");
	learnEnglishAcronym("FOTCL", "falling of the chair laughing");
	learnEnglishAcronym("FTF", "face to face");
	learnEnglishAcronym("FTTT", "from time to time");
	learnEnglishAcronym("FU", "f**ked up");
	learnEnglishAcronym("FUBAR", "f**ked up beyond all recognition");
	learnEnglishAcronym("FUDFUCT", "fear, uncertainty and doubt");
	learnEnglishAcronym("FUCT", "failed under continuas testing");
	learnEnglishAcronym("FURTB", "full up ready to burst (about hard disk drives)");
	learnEnglishAcronym("FW", "freeware");
	learnEnglishAcronym("FWIW", "for what it’s worth");
	learnEnglishAcronym("FYA", "for your amusement");
	learnEnglishAcronym("FYE", "for your entertainment");
	learnEnglishAcronym("FYEO", "for your eyes only");
	learnEnglishAcronym("FYI", "for your information");

	learnEnglishAcronym("G", "grin");
	learnEnglishAcronym("G2B","going to bed");
	learnEnglishAcronym("G&BIT", "grin & bear it");
        learnEnglishAcronym("G2G", "got to go");
        learnEnglishAcronym("G2GGS2D", "got to go get something to drink");
	learnEnglishAcronym("G2GTAC", "got to go take a crap");
        learnEnglishAcronym("G2GTAP", "got to go take a pee");
	learnEnglishAcronym("GA", "go ahead");
	learnEnglishAcronym("GA", "good afternoon");
	learnEnglishAcronym("GAFIA", "get away from it all");
	learnEnglishAcronym("GAL", "get a life");
	learnEnglishAcronym("GAS", "greetings and salutations");
	learnEnglishAcronym("GBH", "great big hug");
	learnEnglishAcronym("GBH&K", "great big huh and kisses");
	learnEnglishAcronym("GBR", "garbled beyond recovery");
	learnEnglishAcronym("GBY", "god bless you");
	learnEnglishAcronym("GD", "&H	grinning, ducking and hiding");
	learnEnglishAcronym("GD&R", "grinning, ducking and running");
	learnEnglishAcronym("GD&RAFAP", "grinning, ducking and running as fast as possible");
	learnEnglishAcronym("GD&REF&F", "grinning, ducking and running even further and faster");
	learnEnglishAcronym("GD&RF", "grinning, ducking and running fast");
	learnEnglishAcronym("GD&RVF", "grinning, ducking and running very");
	learnEnglishAcronym("GD&W", "grin, duck and wave");
	learnEnglishAcronym("GDW", "grin, duck and wave");
	learnEnglishAcronym("GE", "good evening");
	learnEnglishAcronym("GF", "girlfriend");
	learnEnglishAcronym("GFETE", "grinning from ear to ear");
	learnEnglishAcronym("GFN", "gone for now");
	learnEnglishAcronym("GFU", "good for you");
	learnEnglishAcronym("GG", "good game");
	learnEnglishAcronym("GGU", "good game you two");
	learnEnglishAcronym("GIGO", "garbage in garbage out");
	learnEnglishAcronym("GJ", "good job");
	learnEnglishAcronym("GL", "good luck");
	learnEnglishAcronym("GL&GH", "good luck and good hunting");
	learnEnglishAcronym("GM", "good morning / good move / good match");
	learnEnglishAcronym("GMAB", "give me a break");
	learnEnglishAcronym("GMAO", "giggling my ass off");
	learnEnglishAcronym("GMBO", "giggling my butt off");
	learnEnglishAcronym("GMTA", "great minds think alike");
	learnEnglishAcronym("GN", "good night");
	learnEnglishAcronym("GOK", "god only knows");
	learnEnglishAcronym("GOWI", "get on with it");
	learnEnglishAcronym("GPF", "general protection fault");
	learnEnglishAcronym("GR8", "great");
	learnEnglishAcronym("GR&D", "grinning, running and ducking");
	learnEnglishAcronym("GtG", "got to go");
	learnEnglishAcronym("GTSY", "glad to see you");

	learnEnglishAcronym("H", "hug");
	learnEnglishAcronym("H/O", "hold on");
	learnEnglishAcronym("H&K", "hug and kiss");
	learnEnglishAcronym("HAK", "hug and kiss");
	learnEnglishAcronym("HAGD", "have a good day");
	learnEnglishAcronym("HAGN", "have a good night");
	learnEnglishAcronym("HAGS", "have a good summer");
	learnEnglishAcronym("HAG1", "have a good one");
	learnEnglishAcronym("HAHA", "having a heart attack");
	learnEnglishAcronym("HAND", "have a nice day");
	learnEnglishAcronym("HB", "hug back");
	learnEnglishAcronym("HB", "hurry back");
	learnEnglishAcronym("HDYWTDT", "how do you work this dratted thing");
	learnEnglishAcronym("HF", "have fun");
	learnEnglishAcronym("HH", "holding hands");
	learnEnglishAcronym("HHIS", "hanging head in shame");
	learnEnglishAcronym("HHJK", "ha ha, just kidding");
	learnEnglishAcronym("HHOJ", "ha ha, only joking");
	learnEnglishAcronym("HHOK", "ha ha, only kidding");
	learnEnglishAcronym("HHOS", "ha ha, only seriously");
	learnEnglishAcronym("HIH", "hope it helps");
	learnEnglishAcronym("HILIACACLO", "help I lapsed into a coma and can’t log off");
	learnEnglishAcronym("HIWTH", "hate it when that happens");
	learnEnglishAcronym("HLM", "he loves me");
	learnEnglishAcronym("HMS", "home made smiley");
	learnEnglishAcronym("HMS", "hanging my self");
	learnEnglishAcronym("HMT", "here’s my try");
	learnEnglishAcronym("HMWK", "homework");
	learnEnglishAcronym("HOAS", "hold on a second");
	learnEnglishAcronym("HSIK", "how should i know");
	learnEnglishAcronym("HTH", "hope this helps");
	learnEnglishAcronym("HTHBE", "hope this has been enlightening");
	learnEnglishAcronym("HYLMS", "hate you like my sister");

	learnEnglishAcronym("IAAA", "I am an accountant");
	learnEnglishAcronym("IAAL", "I am a lawyer");
	learnEnglishAcronym("IAC", "in any case");
	learnEnglishAcronym("IC", "I see");
	learnEnglishAcronym("IAE", "in any event");
	learnEnglishAcronym("IAG", "it’s all good");
	learnEnglishAcronym("IAG", "I am gay");
	learnEnglishAcronym("IAIM", "in an Irish minute");
	learnEnglishAcronym("IANAA", "I am not an accountant");
	learnEnglishAcronym("IANAL", "I am not a lawyer");
	learnEnglishAcronym("IBN", "I’m bucked naked");
	learnEnglishAcronym("ICOCBW", "I could of course be wrong");
	learnEnglishAcronym("IDC", "I don’t care");
	learnEnglishAcronym("IDGI", "I don’t get it");
	learnEnglishAcronym("IDGARA", "I don’t give a rat’s ass");
	learnEnglishAcronym("IDGW", "in a good way");
	learnEnglishAcronym("IDI", "I doubt it");
	learnEnglishAcronym("IDK", "I don’t know");
	learnEnglishAcronym("IDTT", "I’ll drink to that");
	learnEnglishAcronym("IFVB", "I feel very bad");
	learnEnglishAcronym("IGP", "I gotta pee");
	learnEnglishAcronym("IGTP", "I get the point");
	learnEnglishAcronym("IHTFP", "I hate this f**king place");
	learnEnglishAcronym("IHTFP", "I have truly found paradise");
	learnEnglishAcronym("IHU", "I hate you");
	learnEnglishAcronym("IHY", "I hate you");
	learnEnglishAcronym("II", "I’m impressed");
	learnEnglishAcronym("IIT", "I’m impressed too");
	learnEnglishAcronym("IIR", "if I recall");
	learnEnglishAcronym("IIRC", "if I recall correctly");
	learnEnglishAcronym("IJWTK", "I just want to know");
	learnEnglishAcronym("IJWTS", "I just want to say");
	learnEnglishAcronym("IK", "I know");
	learnEnglishAcronym("IKWUM", "I know what you mean");
	learnEnglishAcronym("ILBCNU", "I’ll be seeing you");
	learnEnglishAcronym("ILU", "I love you");
	learnEnglishAcronym("ILY", "I love you");
	learnEnglishAcronym("ILYFAE", "I love you forever and ever");
	learnEnglishAcronym("IMAO", "in my arrogant opinion");
	learnEnglishAcronym("IMFAO", "in my f***ing arrogant opinion");
	learnEnglishAcronym("IMBO", "in my bloody opinion");
	learnEnglishAcronym("IMCO", "in my considered opinion");
	learnEnglishAcronym("IME", "in my experience");
	learnEnglishAcronym("IMHO", "in my humble opinion");
	learnEnglishAcronym("IMNSHO", "in my, not so humble opinion");
	learnEnglishAcronym("IMO", "in my opinion");
	learnEnglishAcronym("IMOBO", "in my own biased opinion");
	learnEnglishAcronym("IMPOV", "in my point of view");
	learnEnglishAcronym("IMP", "I might be pregnant");
	learnEnglishAcronym("INAL", "I’m not a lawyer");
	learnEnglishAcronym("INPO", "in no particular order");
	learnEnglishAcronym("IOIT", "I’m on Irish Time");
	learnEnglishAcronym("IOW", "in other words");
	learnEnglishAcronym("IRL", "in real life");
	learnEnglishAcronym("IRMFI", "I reply merely for information");
	learnEnglishAcronym("IRSTBO", "it really sucks the big one");
	learnEnglishAcronym("IS", "I’m sorry");
	learnEnglishAcronym("ISEN", "internet search environment number");
	learnEnglishAcronym("ISTM", "it seems to me");
	learnEnglishAcronym("ISTR", "I seem to recall");
	learnEnglishAcronym("ISWYM", "I see what you mean");
	learnEnglishAcronym("ITFA", "in the final analysis");
	learnEnglishAcronym("ITRO", "in the reality of");
	learnEnglishAcronym("ITRW", "in the real world");
	learnEnglishAcronym("ITSFWI", "if the shoe fits, wear it");
	learnEnglishAcronym("IVL", "in virtual live");
	learnEnglishAcronym("IWALY", "I will always love you");
	learnEnglishAcronym("IWBNI", "it would be nice if");
	learnEnglishAcronym("IYKWIM", "if you know what I mean");
	learnEnglishAcronym("IYSWIM", "if you see what I mean");

	learnEnglishAcronym("JAM", "just a minute");
	learnEnglishAcronym("JAS", "just a second");
	learnEnglishAcronym("JASE", "just another system error");
	learnEnglishAcronym("JAWS", "just another windows shell");
	learnEnglishAcronym("JIC", "just in case");
	learnEnglishAcronym("JJWY", "just joking with you");
	learnEnglishAcronym("JK", "just kidding");
	learnEnglishAcronym("J/K", "just kidding");
	learnEnglishAcronym("JMHO", "just my humble opinion");
	learnEnglishAcronym("JMO", "just my opinion");
	learnEnglishAcronym("JP", "just playing");
	learnEnglishAcronym("J/P", "just playing");
	learnEnglishAcronym("JTLYK", "just to let you know");
	learnEnglishAcronym("JW", "just wondering");

	learnEnglishAcronym("K", "OK");
	learnEnglishAcronym("K", "kiss");
	learnEnglishAcronym("KHYF", "know how you feel");
	learnEnglishAcronym("KB", "kiss back");
	learnEnglishAcronym("KISS", "keep it simple sister");
	learnEnglishAcronym("KIS(S)", "keep it simple (stupid)");
	learnEnglishAcronym("KISS", "keeping it sweetly simple");
	learnEnglishAcronym("KIT", "keep in touch");
	learnEnglishAcronym("KMA", "kiss my ass");
	learnEnglishAcronym("KMB", "kiss my butt");
	learnEnglishAcronym("KMSMA", "kiss my shiny metal ass");
	learnEnglishAcronym("KOTC", "kiss on the cheek");
	learnEnglishAcronym("KOTL", "kiss on the lips");
	learnEnglishAcronym("KUTGW", "keep up the good work");
	learnEnglishAcronym("KWIM", "know what I mean?");

	learnEnglishAcronym("L", "laugh");
	learnEnglishAcronym("L8R", "later");
	learnEnglishAcronym("L8R", "G8R	later gator");
	learnEnglishAcronym("LAB", "life’s a bitch");
	learnEnglishAcronym("LAM", "leave a message");
	learnEnglishAcronym("LBR", "little boys room");
	learnEnglishAcronym("LD", "long distance");
	learnEnglishAcronym("LIMH", "laughing in my head");
	learnEnglishAcronym("LG", "lovely greetings");
	learnEnglishAcronym("LIMH", "laughing in my head");
	learnEnglishAcronym("LGR", "little girls room");
	learnEnglishAcronym("LHM", "Lord help me");
	learnEnglishAcronym("LHU", "Lord help us");
	learnEnglishAcronym("LL&P", "live long & prosper");
	learnEnglishAcronym("LNK", "love and kisses");
	learnEnglishAcronym("LMA", "leave me alone");
	learnEnglishAcronym("LMABO", "laughing my ass back on");
	learnEnglishAcronym("LMAO", "laughing my ass off");
	learnEnglishAcronym("MBO", "laughing my butt off");
	learnEnglishAcronym("LMHO", "laughing my head off");
	learnEnglishAcronym("LMFAO", "laughing my fat ass off");
	learnEnglishAcronym("LMK", "let me know");
	learnEnglishAcronym("LOL", "laughing out loud");
	learnEnglishAcronym("LOL", "lots of love");
	learnEnglishAcronym("LOL", "lots of luck");
	learnEnglishAcronym("LOLA", "laughing out loud again");
	learnEnglishAcronym("LOML", "light of my life (or love of my life)");
	learnEnglishAcronym("LOMLILY", "light of my life, I love you");
	learnEnglishAcronym("LOOL", "laughing out outrageously loud");
	learnEnglishAcronym("LSHIPMP", "laughing so hard I pissed my pants");
	learnEnglishAcronym("LSHMBB", "laughing so hard my belly is bouncing");
	learnEnglishAcronym("LSHMBH", "laughing so hard my belly hurts");
	learnEnglishAcronym("LTNS", "long time no see");
	learnEnglishAcronym("LTR", "long term relationship");
	learnEnglishAcronym("LTS", "laughing to self");
	learnEnglishAcronym("LULAS", "love you like a sister");
	learnEnglishAcronym("LUWAMH", "love you with all my heart");
	learnEnglishAcronym("LY", "love ya");
	learnEnglishAcronym("LYK", "let you know");
	learnEnglishAcronym("LYL", "love ya lots");
	learnEnglishAcronym("LYLAB", "love ya like a brother");
	learnEnglishAcronym("LYLAS", "love ya like a sister");

	learnEnglishAcronym("M", "male");
	learnEnglishAcronym("MB", "maybe");
	learnEnglishAcronym("MYOB", "mind your own business");
	learnEnglishAcronym("M8", "mate");

	learnEnglishAcronym("N", "in");
	learnEnglishAcronym("N2M", "not too much");
	learnEnglishAcronym("N/C", "not cool");
	learnEnglishAcronym("NE1", "anyone");
	learnEnglishAcronym("NETUA", "nobody ever tells us anything");
	learnEnglishAcronym("NFI", "no f***ing idea");
	learnEnglishAcronym("NL", "not likely");
	learnEnglishAcronym("NM", "never mind / nothing much");
	learnEnglishAcronym("N/M", "never mind / nothing much");
	learnEnglishAcronym("NMH", "not much here");
	learnEnglishAcronym("NMJC", "nothing much, just chillin’");
	learnEnglishAcronym("NOM", "no offense meant");
	learnEnglishAcronym("NOTTOMH", "not of the top of my mind");
	learnEnglishAcronym("NOYB", "none of your business");
	learnEnglishAcronym("NOYFB", "none of your f***ing business");
	learnEnglishAcronym("NP", "no problem");
	learnEnglishAcronym("NPS", "no problem sweet(ie)");
	learnEnglishAcronym("NTA", "non-technical acronym");
	learnEnglishAcronym("N/S", "no shit");
	learnEnglishAcronym("NVM", "nevermind");

	learnEnglishAcronym("OBTW", "oh, by the way");
	learnEnglishAcronym("OIC", "oh, I see");
	learnEnglishAcronym("OF", "on fire");
	learnEnglishAcronym("OFIS", "on floor with stitches");
	learnEnglishAcronym("OK", "abbreviation of oll korrect (all correct)");
	learnEnglishAcronym("OL", "old lady (wife, girlfriend)");
	learnEnglishAcronym("OM", "old man (husband, boyfriend)");
	learnEnglishAcronym("OMG", "oh my god / gosh / goodness");
	learnEnglishAcronym("OOC", "out of character");
	learnEnglishAcronym("OT", "Off topic / other topic");
	learnEnglishAcronym("OTOH", "on the other hand");
	learnEnglishAcronym("OTTOMH", "off the top of my head");

	learnEnglishAcronym("P@H", "parents at home");
	learnEnglishAcronym("PAH", "parents at home");
	learnEnglishAcronym("PAW", "parents are watching");
	learnEnglishAcronym("PDS", "please don’t shoot");
	learnEnglishAcronym("PEBCAK", "problem exists between chair and keyboard");
	learnEnglishAcronym("PIZ", "parents in room");
	learnEnglishAcronym("PLZ", "please");
	learnEnglishAcronym("PM", "private message");
	learnEnglishAcronym("PMJI", "pardon my jumping in (Another way for PMFJI)");
	learnEnglishAcronym("PMFJI", "pardon me for jumping in");
	learnEnglishAcronym("PMP", "peed my pants");
	learnEnglishAcronym("POAHF", "put on a happy face");
	learnEnglishAcronym("POOF", "I have left the chat");
	learnEnglishAcronym("POTB", "pats on the back");
	learnEnglishAcronym("POS", "parents over shoulder");
	learnEnglishAcronym("PPL", "people");
	learnEnglishAcronym("PS", "post script");
	learnEnglishAcronym("PSA", "public show of affection");

	learnEnglishAcronym("Q4U", "question for you");
	learnEnglishAcronym("QSL", "reply");
	learnEnglishAcronym("QSO", "conversation");
	learnEnglishAcronym("QT", "cutie");

	learnEnglishAcronym("RCed", "reconnected");
	learnEnglishAcronym("RE", "hi again (same as re’s)");
	learnEnglishAcronym("RME", "rolling my eyses");
	learnEnglishAcronym("ROFL", "rolling on floor laughing");
	learnEnglishAcronym("ROFLAPMP", "rolling on floor laughing and peed my pants");
	learnEnglishAcronym("ROFLMAO", "rolling on floor laughing my ass off");
	learnEnglishAcronym("ROFLOLAY", "rolling on floor laughing out loud at you");
	learnEnglishAcronym("ROFLOLTSDMC", "rolling on floor laughing out loud tears streaming down my cheeks");
	learnEnglishAcronym("ROFLOLWTIME", "rolling on floor laughing out loud with tears in my eyes");
	learnEnglishAcronym("ROFLOLUTS", "rolling on floor laughing out loud unable to speak");
	learnEnglishAcronym("ROTFL", "rolling on the floor laughing");
	learnEnglishAcronym("RVD", "really very dumb");
	learnEnglishAcronym("RUTTM", "are you talking to me");
	learnEnglishAcronym("RTF", "read the FAQ");
	learnEnglishAcronym("RTFM", "read the f***ing manual");
	learnEnglishAcronym("RTSM", "read the stupid manual");

	learnEnglishAcronym("S2R", "send to receive");
	learnEnglishAcronym("SAMAGAL", "stop annoying me and get a live");
	learnEnglishAcronym("SCNR", "sorry, could not resist");
	learnEnglishAcronym("SETE", "smiling ear to ear");
	learnEnglishAcronym("SH", "so hot");
	learnEnglishAcronym("SH", "same here");
	learnEnglishAcronym("SHICPMP", "so happy I could piss my pants");
	learnEnglishAcronym("SHID", "slaps head in disgust");
	learnEnglishAcronym("SHMILY", "see how much I love you");
	learnEnglishAcronym("SNAFU", "situation normal, all F***ed up");
	learnEnglishAcronym("SO", "significant other");
	learnEnglishAcronym("SOHF", "sense of humor failure");
	learnEnglishAcronym("SOMY", "sick of me yet?");
	learnEnglishAcronym("SPAM", "stupid persons’ advertisement");
	learnEnglishAcronym("SRY", "sorry");
	learnEnglishAcronym("SSDD", "same shit different day");
	learnEnglishAcronym("STBY", "sucks to be you");
	learnEnglishAcronym("STFU", "shut the f*ck up");
	learnEnglishAcronym("STI", "stick(ing) to it");
	learnEnglishAcronym("STW", "search the web");
	learnEnglishAcronym("SWAK", "sealed with a kiss");
	learnEnglishAcronym("SWALK", "sweet, with all love, kisses");
	learnEnglishAcronym("SWL", "screaming with laughter");
	learnEnglishAcronym("SIM", "shit, it’s Monday");
	learnEnglishAcronym("SITWB", "sorry, in the wrong box");
	learnEnglishAcronym("S/U", "shut up");
	learnEnglishAcronym("SYS", "see you soon");
	learnEnglishAcronym("SYSOP", "system operator");

	learnEnglishAcronym("TA", "thanks again");
	learnEnglishAcronym("TCO", "taken care of");
	learnEnglishAcronym("TGIF", "thank god its Friday");
	learnEnglishAcronym("THTH", "to hot to handle");
	learnEnglishAcronym("THX", "thanks");
	learnEnglishAcronym("TIA", "thanks in advance");
	learnEnglishAcronym("TIIC", "the idiots in charge");
	learnEnglishAcronym("TJM", "that’s just me");
	learnEnglishAcronym("TLA", "three-letter acronym");
	learnEnglishAcronym("TMA", "take my advice");
	learnEnglishAcronym("TMI", "to much information");
	learnEnglishAcronym("TMS", "to much showing");
	learnEnglishAcronym("TNSTAAFL", "there’s no such thing as a free lunch");
	learnEnglishAcronym("TNX", "thanks");
	learnEnglishAcronym("TOH", "to other half");
	learnEnglishAcronym("TOY", "thinking of you");
	learnEnglishAcronym("TPTB", "the powers that be");
	learnEnglishAcronym("TSDMC", "tears streaming down my cheeks");
	learnEnglishAcronym("TT2T", "to tired to talk");
	learnEnglishAcronym("TTFN", "ta ta for now");
	learnEnglishAcronym("TTT", "thought that, too");
	learnEnglishAcronym("TTUL", "talk to you later");
	learnEnglishAcronym("TTYIAM", "talk to you in a minute");
	learnEnglishAcronym("TTYL", "talk to you later");
	learnEnglishAcronym("TTYLMF", "talk to you later my friend");
	learnEnglishAcronym("TU", "thank you");
	learnEnglishAcronym("TWMA", "till we meet again");
	learnEnglishAcronym("TX", "thanx");
	learnEnglishAcronym("TY", "thank you");
	learnEnglishAcronym("TYVM", "thank you very much");

	learnEnglishAcronym("U2", "you too");
	learnEnglishAcronym("UAPITA", "you’re a pain in the ass");
	learnEnglishAcronym("UR", "your");
	learnEnglishAcronym("UW", "you’re welcom");
	learnEnglishAcronym("URAQT!", "you are a cutie!");

	learnEnglishAcronym("VBG", "very big grin");
	learnEnglishAcronym("VBS", "very big smile");

	learnEnglishAcronym("W8", "wait");
	learnEnglishAcronym("W8AM", "wait a minute");
	learnEnglishAcronym("WAY", "what about you");
	learnEnglishAcronym("WAY", "who are you");
	learnEnglishAcronym("WB", "welcome back");
	learnEnglishAcronym("WBS", "write back soon");
	learnEnglishAcronym("WDHLM", "why doesn’t he love me");
	learnEnglishAcronym("WDYWTTA", "What Do You Want To Talk About");
	learnEnglishAcronym("WE", "whatever");
	learnEnglishAcronym("W/E", "whatever");
	learnEnglishAcronym("WFM", "works for me");
	learnEnglishAcronym("WNDITWB", "we never did it this way before");
	learnEnglishAcronym("WP", "wrong person");
	learnEnglishAcronym("WRT", "with respect to");
	learnEnglishAcronym("WTF", "what/who the F***?");
	learnEnglishAcronym("WTG", "way to go");
	learnEnglishAcronym("WTGP", "want to go private?");
	learnEnglishAcronym("WTH", "what/who the heck?");
	learnEnglishAcronym("WTMI", "way to much information");
	learnEnglishAcronym("WU", "what’s up?");
	learnEnglishAcronym("WUD", "what’s up dog?");
	learnEnglishAcronym("WUF", "where are you from?");
	learnEnglishAcronym("WUWT", "whats up with that");
	learnEnglishAcronym("WYMM", "will you marry me?");
	learnEnglishAcronym("WYSIWYG", "what you see is what you get");

	learnEnglishAcronym("XTLA", "extended three letter acronym");

	learnEnglishAcronym("Y", "why?");
	learnEnglishAcronym("Y2K", "you’re too kind");
	learnEnglishAcronym("YATB", "you are the best");
	learnEnglishAcronym("YBS", "you’ll be sorry");
	learnEnglishAcronym("YG", "young gentleman");
	learnEnglishAcronym("YHBBYBD", "you’d have better bet your bottom dollar");
	learnEnglishAcronym("YKYWTKM", "you know you want to kiss me");
	learnEnglishAcronym("YL", "young lady");
	learnEnglishAcronym("YL", "you ’ll live");
	learnEnglishAcronym("YM", "you mean");
	learnEnglishAcronym("YM", "young man");
	learnEnglishAcronym("YMMD", "you’ve made my day");
	learnEnglishAcronym("YMMV", "your mileage may vary");
	learnEnglishAcronym("YVM", "you’re very welcome");
	learnEnglishAcronym("YW", "you’re welcome");
	learnEnglishAcronym("YWIA", "you’re welcome in advance");
	learnEnglishAcronym("YWTHM", "you want to hug me");
	learnEnglishAcronym("YWTLM", "you want to love me");
	learnEnglishAcronym("YWTKM", "you want to kiss me");
	learnEnglishAcronym("YOYO", "you’re on your own");
	learnEnglishAcronym("YY4U", "two wise for you");

	learnEnglishAcronym("?", "huh?");
	learnEnglishAcronym("?4U", "question for you");
	learnEnglishAcronym(">U", "screw you!");
	learnEnglishAcronym("/myB", "kick my boobs");
	learnEnglishAcronym("2U2", "to you too");
	learnEnglishAcronym("2MFM", "to much for me");
	learnEnglishAcronym("4AYN", "for all you know");
	learnEnglishAcronym("4COL", "for crying out loud");
	learnEnglishAcronym("4SALE", "for sale");
	learnEnglishAcronym("4U", "for you");
	learnEnglishAcronym("=w=", "whatever");
	learnEnglishAcronym("*G*", "giggle or grin");
	learnEnglishAcronym("*H*", "hug");
	learnEnglishAcronym("*K*", "kiss");
	learnEnglishAcronym("*S*", "smile");
	learnEnglishAcronym("*T*", "tickle");
	learnEnglishAcronym("*W*", "wink");

        // https://en.wikipedia.org/wiki/List_of_emoticons
        learnEnglishEmoticon([":-)", ":)", ":)", ":o)", ":]", ":3", ":c)", ":>"],
                             ["Smiley", "Happy"]);
    }

    /** Learn English Irregular Verbs.
        TODO Move to irregular_verb.txt in format: bewas,werebeen
        TODO Merge with http://www.enchantedlearning.com/wordlist/irregularverbs.shtml
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

    /** Learn Math.
     */
    void learnMath()
    {
        const origin = Origin.manual;

        connect(store("π", Lang.math, Sense.nounIrrationalNumber, origin),
                Rel.translationOf,
                store("pi", Lang.en, Sense.nounIrrationalNumber, origin), // TODO other Langs?
                Lang.en, origin, 1.0);
        connect(store("e", Lang.math, Sense.nounIrrationalNumber, origin),
                Rel.translationOf,
                store("e", Lang.en, Sense.nounIrrationalNumber, origin), // TODO other Langs?
                Lang.en, origin, 1.0);

        /// http://www.geom.uiuc.edu/~huberty/math5337/groupe/digits.html
        connect(store("π", Lang.math, Sense.nounIrrationalNumber, origin),
                Rel.definedAs,
                store("3.14159265358979323846264338327950288419716939937510",
                      Lang.math, Sense.nounDecimal, origin),
                Lang.en, origin, 1.0);

        connect(store("e", Lang.math, Sense.nounIrrationalNumber, origin),
                Rel.definedAs,
                store("2.71828182845904523536028747135266249775724709369995",
                      Lang.math, Sense.nounDecimal, origin),
                Lang.en, origin, 1.0);
    }

    /** Learn English Irregular Verbs.
     */
    void learnEnglishOther()
    {
        connectMto1(store(["preserve food",
                           "cure illness",
                           "augment cosmetics"],
                          Lang.en, Sense.noun, Origin.manual),
                    Rel.uses, false,
                    store("herb", Lang.en, Sense.noun, Origin.manual),
                    Lang.en, Origin.manual, 1.0);

        connectMto1(store(["enrich taste of food",
                           "improve taste of food",
                           "increase taste of food"],
                          Lang.en, Sense.noun, Origin.manual),
                    Rel.uses, false,
                    store("spice", Lang.en, Sense.noun, Origin.manual),
                    Lang.en, Origin.manual, 1.0);

        connect1toM(store("herb", Lang.en, Sense.noun, Origin.manual),
                    Rel.madeOf,
                    store(["leaf", "plant"], Lang.en, Sense.noun, Origin.manual),
                    Lang.en, Origin.manual, 1.0);

        connect1toM(store("spice", Lang.en, Sense.noun, Origin.manual),
                    Rel.madeOf,
                    store(["root", "plant"], Lang.en, Sense.noun, Origin.manual),
                    Lang.en, Origin.manual, 1.0);
    }

    /** Learn Swedish Irregular Verb.
        See also: http://www.lardigsvenska.com/2010/10/oregelbundna-verb.html
    */
    void learnSwedishVerb(S)(S imperative,
                             S infinitive,
                             S present,
                             S past,
                             S pastParticiple) if (isSomeString!S) // pastParticiple
    {
        const lang = Lang.sv;
        const origin = Origin.manual;
        auto all = [tryStore(imperative, lang, Sense.verbImperative, origin),
                    tryStore(infinitive, lang, Sense.verbInfinitive, origin),
                    tryStore(present, lang, Sense.verbPresent, origin),
                    tryStore(past, lang, Sense.verbPast, origin),
                    tryStore(pastParticiple, lang, Sense.verbPastParticiple, origin)];
        connectAll(Rel.verbForm, all.filter!(a => a.defined), lang, origin);
    }

    /** Learn Swedish Irregular Verbs.
    */
    void learnSwedishVerbs()
    {
        learnSwedishVerb("ge", "ge", "ger", "gav", "gett/givit");
        learnSwedishVerb("ange", "ange", "anger", "angav", "angett/angivit");
        learnSwedishVerb("anse", "anse", "anser", "ansåg", "ansett");
        learnSwedishVerb("avgör", "avgöra", "avgör", "avgjorde", "avgjort");
        learnSwedishVerb("avstå", "avstå", "avstår", "avstod", "avstått");
        learnSwedishVerb("be", "be", "ber", "bad", "bett");
        learnSwedishVerb("bestå", "bestå", "består", "bestod", "bestått");
        learnSwedishVerb([], [], "bör", "borde", "bort");
        learnSwedishVerb("dra", "dra", "drar", "drog", "dragit");
        learnSwedishVerb([], "duga", "duger", "dög/dugde", "dugit");
        learnSwedishVerb("dyk", "dyka", "dyker", "dök/dykte", "dykit");
        learnSwedishVerb("dö", "dö", "dör", "dog", "dött");
        learnSwedishVerb("dölj", "dölja", "döljer", "dolde", "dolt");
        learnSwedishVerb("ersätt", "ersätta", "ersätter", "ersatte", "ersatt");
        learnSwedishVerb("fortsätt", "fortsätta", "fortsätter", "fortsatte", "fortsatt");
        learnSwedishVerb("framstå", "framstå", "framstår", "framstod", "framstått");
        learnSwedishVerb("få", "få", "får", "fick", "fått");
        learnSwedishVerb("förstå", "förstå", "förstår", "förstod", "förstått");
        learnSwedishVerb("förutsätt", "förutsätta", "förutsätter", "förutsatte", "förutsatt");
        learnSwedishVerb("gläd", "glädja", "gläder", "gladde", "glatt");
        learnSwedishVerb("gå", "gå", "går", "gick", "gått");
        learnSwedishVerb("gör", "göra", "gör", "gjorde", "gjort");
        learnSwedishVerb("ha", "ha", "har", "hade", "haft");
        learnSwedishVerb([], "heta", "heter", "hette", "hetat");
        learnSwedishVerb([], "ingå", "ingår", "ingick", "ingått");
        learnSwedishVerb("inse", "inse", "inser", "insåg", "insett");
        learnSwedishVerb("kom", "komma", "kommer", "kom", "kommit");
        learnSwedishVerb([], "kunna", "kan", "kunde", "kunnat");
        learnSwedishVerb("le", "le", "ler", "log", "lett");
        learnSwedishVerb("lev", "leva", "lever", "levde", "levt");
        learnSwedishVerb("ligg", "ligga", "ligger", "låg", "legat");
        learnSwedishVerb("lägg", "lägga", "lägger", "la", "lagt");
        learnSwedishVerb("missförstå", "missförstå", "missförstår", "missförstod", "missförstått");
        learnSwedishVerb([], [], "måste", "var tvungen", "varit tvungen");
        learnSwedishVerb("se", "se", "ser", "såg", "sett");
        learnSwedishVerb("skilj", "skilja", "skiljer", "skilde", "skilt");
        learnSwedishVerb([], [], "ska", "skulle", []);
        learnSwedishVerb("smaksätt", "smaksätta", "smaksätter", "smaksatte", "smaksatt");
        learnSwedishVerb("sov", "sova", "sover", "sov", "sovit");
        learnSwedishVerb("sprid", "sprida", "sprider", "spred", "spridit");
        learnSwedishVerb("stjäl", "stjäla", "stjäl", "stal", "stulit");
        learnSwedishVerb("stå", "stå", "står", "stod", "stått");
        learnSwedishVerb("stöd", "stödja", "stöder", "stödde", "stött");
        learnSwedishVerb("svälj", "svälja", "sväljer", "svalde", "svalt");
        learnSwedishVerb("säg", "säga", "säger", "sa", "sagt");
        learnSwedishVerb("sälj", "sälja", "säljer", "sålde", "sålt");
        learnSwedishVerb("sätt", "sätta", "sätter", "satte", "satt");
        learnSwedishVerb("ta", "ta", "tar", "tog", "tagit");
        learnSwedishVerb("tillsätt", "tillsätta", "tillsätter", "tillsatte", "tillsatt");
        learnSwedishVerb("umgås", "umgås", "umgås", "umgicks", "umgåtts");
        learnSwedishVerb("uppge", "uppge", "uppger", "uppgav", "uppgivit");
        learnSwedishVerb("utgå", "utgå", "utgår", "utgick", "utgått");
        learnSwedishVerb("var", "vara", "är", "var", "varit");
        learnSwedishVerb([], "veta", "vet", "visste", "vetat");
        learnSwedishVerb("vik", "vika", "viker", "vek", "vikt");
        learnSwedishVerb([], "vilja", "vill", "ville", "velat");
        learnSwedishVerb("välj", "välja", "väljer", "valde", "valt");
        learnSwedishVerb("vänj", "vänja", "vänjer", "vande", "vant");
        learnSwedishVerb("väx", "växa", "växer", "växte", "växt");
        learnSwedishVerb("återge", "återge", "återger", "återgav", "återgivit");
        learnSwedishVerb("översätt", "översätta", "översätter", "översatte", "översatt");
        learnSwedishVerb("tyng", "tynga", "tynger", "tyngde", "tyngt");
    }

    /** Learn Adjective in language $(D lang).
     */
    void learnAdjective(S)(Lang lang,
                           S nominative,
                           S comparative,
                           S superlative) if (isSomeString!S)
    {
        const origin = Origin.manual;
        auto all = [tryStore(nominative, lang, Sense.adjectiveNominative, origin),
                    tryStore(comparative, lang, Sense.adjectiveComparative, origin),
                    tryStore(superlative, lang, Sense.adjectiveSuperlative, origin)];
        connectAll(Rel.adjectiveForm, all.filter!(a => a.defined), lang, origin);
    }

    /** Learn Swedish Adjectives.
     */
    void learnSwedishAdjectives()
    {
        enum lang = Lang.sv;
        learnAdjective(lang, "tung", "tyngre", "tyngst");
    }

    /* TODO Add logic describing which Sense.nounX and CategoryIx that fulfills
     * isUncountable() and use it here. */
    void learnUncountableNouns(R)(Lang lang, R nouns) if (isSourceOf!(R, string))
    {
        const sense = Sense.nounUncountable;
        const origin = Origin.manual;
        connectMto1(nouns.map!(word => store(word, lang, sense, origin)),
                    Rel.isA, false,
                    store("uncountable_noun", lang, sense, origin),
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
                  Sense sense,
                  Origin origin,
                  CategoryIx categoryIx = CategoryIx.asUndefined) in { assert(!expr.empty); }
    body
    {
        const lemma = Lemma(expr, lang, sense, categoryIx);
        return store(lemma, Node(lemma, origin));
    }

    /** Try to Lookup-or-Store $(D Node) named $(D expr) in language $(D lang).
     */
    NodeRef tryStore(Expr expr,
                     Lang lang,
                     Sense sense,
                     Origin origin,
                     CategoryIx categoryIx = CategoryIx.asUndefined)
    {
        if (expr.empty)
            return NodeRef.asUndefined;
        return store(expr, lang, sense, origin, categoryIx);
    }

    NodeRef[] store(Exprs)(Exprs exprs,
                           Lang lang,
                           Sense sense,
                           Origin origin,
                           CategoryIx categoryIx = CategoryIx.asUndefined) if (isIterable!(Exprs))
    {
        typeof(return) nodeRefs;
        foreach (expr; exprs)
        {
            nodeRefs ~= store(expr, lang, sense, origin, categoryIx);
        }
        return nodeRefs;
    }

    /** Directed Connect Many Sources $(D srcs) to Many Destinations $(D dsts).
     */
    LinkRef[] connectMtoN(S, D)(S srcs,
                                Rel rel,
                                D dsts,
                                Lang lang,
                                Origin origin,
                                NWeight weight = 1.0) if (isIterableOf!(S, NodeRef) &&
                                                          isIterableOf!(D, NodeRef))
    {
        typeof(return) linkIxes;
        foreach (src; srcs)
        {
            foreach (dst; dsts)
            {
                linkIxes ~= connect(src, rel, dst, lang, origin, weight);
            }
        }
        return linkIxes;
    }

     /** Fully Connect Every-to-Every in $(D all).
        See also: http://forum.dlang.org/thread/iqkybajwdzcvdytakgvw@forum.dlang.org#post-iqkybajwdzcvdytakgvw:40forum.dlang.org
        See also: https://issues.dlang.org/show_bug.cgi?id=6788
    */
    LinkRef[] connectAll(R)(Rel rel,
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
    alias connectFully = connectAll;
    alias connectStar = connectAll;

    /** Fan-Out Connect $(D first) to Every in $(D rest). */
    LinkRef[] connect1toM(R)(NodeRef first,
                             Rel rel,
                             R rest,
                             Lang lang,
                             Origin origin, NWeight weight = 1.0) if (isIterableOf!(R, NodeRef))
    {
        typeof(return) linkIxes;
        foreach (you; rest)
        {
            if (first != you)
            {
                linkIxes ~= connect(first, rel, you, lang, origin, weight);
            }
        }
        return linkIxes;
    }
    alias connectFanOut = connect1toM;

    /** Fan-In Connect $(D first) to Every in $(D rest). */
    LinkRef[] connectMto1(R)(R rest,
                             Rel rel, bool reversion,
                             NodeRef first,
                             Lang lang,
                             Origin origin, NWeight weight = 1.0) if (isIterableOf!(R, NodeRef))
    {
        typeof(return) linkIxes;
        foreach (you; rest)
        {
            if (first != you)
            {
                linkIxes ~= connect(you, rel, first, lang, origin, weight, false, reversion);
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
                    bool checkExisting = false) in {
        assert(src != dst,
               nodeAt(src).lemma.expr ~
               " must not be equal to " ~
               nodeAt(dst).lemma.expr);
    }
    body
    {
        if (src == dst) { return LinkRef.asUndefined; } // Don't allow self-reference for now

        if (checkExisting)
        {
            if (auto existingIx = areConnected(src, rel, dst,
                                               negation))
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

    /** Read ConceptNet5 URI.
        See also: https://github.com/commonsense/conceptnet5/wiki/URI-hierarchy-5.0
    */
    NodeRef readCN5ConceptURI(T)(const T part)
    {
        auto items = part.splitter('/');

        const lang = items.front.decodeLang; items.popFront;
        ++hlangCounts[lang];

        static if (useRCString) { immutable expr = items.front.tr("_", " "); }
        else                    { immutable expr = items.front.tr("_", " ").idup; }

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
        ++senseCounts[sense];

        return store(expr.correctLemmaExpr, lang, sense, Origin.cn5, anyCategory);
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

        const lang = Lang.en;   // use English for now
        const sense = Sense.noun;

        /* name */
        // clean cases such as concept:language:english_language
        immutable entityName = (entity.front.endsWith("_" ~ categoryName) ?
                                entity.front[0 .. $ - (categoryName.length + 1)] :
                                entity.front).idup;
        entity.popFront;

        auto entityIx = store(entityName.tr(`_`, ` `).correctLemmaExpr, lang, sense, Origin.nell, categoryIx);

        return tuple(entityIx,
                     categoryName,
                     connect(entityIx,
                             Rel.isA,
                             store(categoryName.tr(`_`, ` `).correctLemmaExpr, lang, sense, Origin.nell, categoryIx),
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

        if (show) writeln;
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
                case `/s/dbpedia/3.7`:
                case `/s/dbpedia/3.9/umbel`:
                case `/d/dbpedia/en`:
                    lang = Lang.en;
                    return dbpedia;

                case `/d/wordnet/3.0`: return wordnet;
                case `/s/wordnet/3.0`: return wordnet;
                case `/d/umbel`: return umbel;
                case `/d/jmdict`: return jmdict;

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
                        dln("Could not decode origin ", part);
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
            dst.defined &&
            src != dst)
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

    /** Read SynLex Synonyms File $(D path) in XML format.
     */
    void readSynlexFile(string path, size_t maxCount = size_t.max)
    {
        import std.xml: DocumentParser, ElementParser, Element;
        size_t lnr = 0;
        writeln("Reading SynLex from ", path, " ...");

        enum lang = Lang.sv;
        enum origin = Origin.synlex;
        const str = cast(string)std.file.read(path);
        auto doc = new DocumentParser(str);
        doc.onStartTag["syn"] = (ElementParser elp)
        {
            const level = elp.tag.attr["level"].to!real; // level on a scale from 1 to 5
            const weight = level/5.0; // normalized weight
            string w1, w2;
            elp.onEndTag["w1"] = (in Element e) { w1 = e.text.toLower.correctLemmaExpr; };
            elp.onEndTag["w2"] = (in Element e) { w2 = e.text.toLower.correctLemmaExpr; };

            elp.parse;

            if (w1 != w2) // there might be a bug in the xml...
            {
                connect(store(w1, lang, Sense.unknown, origin),
                        Rel.synonymFor,
                        store(w2, lang, Sense.unknown, origin),
                        lang, origin, weight, false, false, true);
                ++lnr;
            }
        };
        doc.parse;

        writeln("Read SynLex ", path, ` having `, lnr, ` lines`);
        if (lnr >= 1) { showRelations; }
    }

    /** Read Folkets Lexikon Synonyms File $(D path) in XML format.
     */
    void readFolketsFile(string path,
                         Lang srcLang,
                         Lang dstLang,
                         size_t maxCount = size_t.max)
    {
        import std.xml: DocumentParser, ElementParser, Element;
        size_t lnr = 0;
        writeln("Reading Folkets Lexikon from ", path, " ...");

        enum origin = Origin.folketsLexikon;
        const str = cast(string)std.file.read(path);
        auto doc = new DocumentParser(str);
        doc.onStartTag["ar"] = (ElementParser elp)
        {
            string src, gr;
            string[] dsts;
            elp.onEndTag["k"] = (in Element e) { src = e.text.correctLemmaExpr; };
            elp.onEndTag["gr"] = (in Element e) { gr = e.text.correctLemmaExpr; };
            elp.onEndTag["dtrn"] = (in Element e) { dsts ~= e.text; };

            elp.parse;

            Sense[] senses;
            switch (gr)
            {
                case "":        // ok for unknown
                case "latin":
                    senses ~= Sense.unknown;
                break;
                case "prefix": senses ~= Sense.prefix; break;
                case "suffix": senses ~= Sense.suffix; break;
                case "pm": senses ~= Sense.nounName; break;
                case "nn": senses ~= Sense.noun; break;
                case "vb": senses ~= Sense.verb; break;
                case "hjälpverb": senses ~= Sense.auxiliaryVerb; break;
                case "jj": senses ~= Sense.adjective; break;
                case "pc": senses ~= Sense.adjective; break; // TODO can be either adjective or verb
                case "ab": senses ~= Sense.adverb; break;
                case "pp": senses ~= Sense.preposition; break;
                case "pn": senses ~= Sense.pronoun; break;
                case "kn": senses ~= Sense.conjunction; break;
                case "in": senses ~= Sense.interjection; break;
                case "abbrev": senses ~= Sense.nounAbbrevation; break;
                case "nn, abbrev":
                case "abbrev, nn":
                    senses ~= Sense.nounAbbrevation; break;
                case "article": senses ~= Sense.article; break;
                case "rg": senses ~= Sense.nounInteger; break;
                case "ro": senses ~= Sense.ordinalNumber; break;
                case "in, nn": senses ~= [Sense.interjection, Sense.noun]; break;
                case "jj, nn": senses ~= [Sense.adjective, Sense.noun]; break;
                case "jj, pp": senses ~= [Sense.adjective, Sense.preposition]; break;
                case "nn, jj": senses ~= [Sense.noun, Sense.adjective]; break;
                case "jj, nn, ab": senses ~= [Sense.adjective, Sense.noun, Sense.adverb]; break;
                case "ab, jj": senses ~= [Sense.adverb, Sense.adjective]; break;
                case "jj, ab": senses ~= [Sense.adjective, Sense.adverb]; break;
                case "ab, pp": senses ~= [Sense.adverb, Sense.preposition]; break;
                case "ab, pn": senses ~= [Sense.adverb, Sense.pronoun]; break;
                case "pp, ab": senses ~= [Sense.preposition, Sense.adverb]; break;
                case "pp, kn": senses ~= [Sense.preposition, Sense.conjunction]; break;
                case "ab, kn": senses ~= [Sense.adverb, Sense.conjunction]; break;
                case "vb, nn": senses ~= [Sense.verb, Sense.noun]; break;
                case "nn, vb": senses ~= [Sense.noun, Sense.verb]; break;
                case "vb, abbrev": senses ~= [Sense.verbAbbrevation]; break;
                case "jj, abbrev": senses ~= [Sense.adjectiveAbbrevation]; break;
                default: dln(`warning: TODO "`, src, `" have sense "`, gr, `"`); break;
            }

            foreach (sense; senses)
            {
                foreach (dst; dsts)
                {
                    if (dst.empty)
                    {
                        dln(`warning: empty dst for "`, src, `"`);
                        continue;
                    }
                    connect(store(src, srcLang, sense, origin),
                            Rel.translationOf,
                            store(dst, dstLang, sense, origin),
                            Lang.unknown, origin, 1.0, false, false, true);
                }
            }
        };
        doc.parse;

        writeln("Read SynLex ", path, ` having `, lnr, ` lines`);
        if (lnr >= 1) { showRelations; }
    }

    /** Read NELL File $(D path) in CSV format.
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
        foreach (source; Origin.min .. Origin.max)
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
                writeln(indent, lang.toHuman, ` (`, lang.to!string, `) : `, count);
            }
        }

        writeln(`Node Count by Word Kind:`);
        foreach (sense; Sense.min..Sense.max)
        {
            const count = senseCounts[sense];
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

        writeln(indent, `Lemmas Expression Count: `, lemmasByExpr.length);

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
        TODO warn about negation and reversion on existing rels
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
        if (node.lemma.expr)
            write(` "`, node.lemma.expr, // .tr(`_`, ` `)
                  `"`);

        write(` (`); // open

        if (node.lemma.lang != Lang.unknown)
        {
            write(node.lemma.lang);
        }
        if (node.lemma.sense != Sense.unknown)
        {
            write(`:`, node.lemma.sense);
        }
        if (node.lemma.categoryIx != CategoryIx.asUndefined)
        {
            write(`:`, categoryNameByIx[node.lemma.categoryIx]);
        }

        writef(`:%.0f%%-%s),`, 100*weight, node.origin.toNice); // close
    }

    void showLinkNode(in Node node,
                      Rel rel,
                      NWeight weight,
                      RelDir dir)
    {
        showLink(rel, dir);
        showNode(node, weight);
        writeln;
    }

    void showNodeRefs(R)(R nodeRefs,
                         Rel rel = Rel.any,
                         bool negation = false)
    {
        foreach (nodeRef; nodeRefs)
        {
            const lineNode = nodeAt(nodeRef);

            write(`  - in `, lineNode.lemma.lang.toHuman);
            if (lineNode.lemma.sense != Sense.unknown)
            {
                write(` of sense `, lineNode.lemma.sense);
            }
            writeln;

            // TODO Why is cast needed here?
            auto linkRefs = cast(LinkRefs)linkRefsOf(lineNode, RelDir.any, rel, negation);

            linkRefs[].sort!((a, b) => (linkAt(a).normalizedWeight >
                                        linkAt(b).normalizedWeight));
            foreach (linkRef; linkRefs)
            {
                auto link = linkAt(linkRef);
                showLinkRef(linkRef);
                foreach (linkedNode; link.actors[]
                                         .filter!(actorNodeRef => (actorNodeRef.ix !=
                                                                   nodeRef.ix)) // don't self reference
                                         .map!(nodeRef => nodeAt(nodeRef)))
                {
                    showNode(linkedNode, link.normalizedWeight);
                }
                writeln;
            }
        }
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
        auto normLine = line.strip.tr(std.ascii.whitespace, ` `, `s`).toLower;
        if (normLine.empty)
            return;

        writeln(`> Line "`, normLine, `"`);

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
        else if (normLine.skipOver(`synonymsof(`))
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
        else if (normLine.skipOver(`translationsof(`))
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
        else if (normLine.skipOver(`languagesof(`))
        {
            normLine.skipOver(" "); // TODO all space using skipOver!isSpace
            auto split = normLine.findSplitBefore(`)`);
            const arg = split[0];
            if (!arg.empty)
            {
                auto hist = languagesOf(arg.splitter(" "));
                showTopLanguages(hist);
            }
        }

        if (normLine.empty)
            return;

        // queried line nodes
        auto lineNodeRefs = nodeRefsOf(normLine, lang, sense);

        // as is
        showNodeRefs(lineNodeRefs);

        if (lineNodeRefs.empty)
        {
            auto parts = normLine.splitter(" ");
            if (parts.count >= 2)
            {
                const joinedLine = parts.joiner.to!string;
                writeln(`> Joined to `, joinedLine);
                showNodes(joinedLine, lang, sense, lineSeparator);
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
        showNodeRefs(nodes, Rel.synonymFor); // TODO traverse synonyms
        return nodes;
    }

    /** Get Possible Languages of $(D text) sorted by falling strength.
        TODO Weight hits with word node connectedness relative to average word
        connectedness in that language.
     */
    NWeight[Lang] languagesOf(R)(R text) if (isIterable!R &&
                                             isSomeString!(ElementType!R))
    {
        typeof(return) hist;
        foreach (word; text)
        {
            foreach (lemma; lemmasOf(word))
            {
                ++hist[lemma.lang];
            }
        }
        return hist;
    }

    /** Show Languages Sorted By Falling Weight. */
    void showTopLanguages(NWeight[Lang] hist)
    {
        foreach (e; hist.pairs.sort!((a, b) => (a[1] > b[1])))
        {
            writeln("  - ", e[0].toHuman, ": ", e[1], " #hits");
        }
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
        showNodeRefs(nodes, Rel.translationOf); // TODO traverse synonyms and translations

        // en => sv:
        // en-en => sv-sv
        /* auto translations = nodes.map!(node => linkRefsOf(node, RelDir.any, rel, false))/\* .joiner *\/; */
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
