#!/usr/bin/env rdmd-dev-module

/** Knowledge Graph Database.

    Reads data from SUMO, DBpedia, Freebase, Yago, BabelNet, ConceptNet, Nell,
    Wikidata, WikiTaxonomy into a Knowledge Graph.

    Applications:

    - Baby Naming: Enter words you like the baby to represent and then search
      over synonyms, translations, etc until you find the most releveant node of
      type nameMale or nameFemale. Also show "how" they are related (show network walk).
    - Translate text to use age-relevant words. Use pre-train child book word
      histogram for specific ages.
    - Find dubious words:
      - Swedish:
        - trumpétare - trúm-petare
        - tómtén - tómten
        - tunnelbánan - tunnel-banán
    - Emotion Detection

    See also: http://stevehanov.ca/blog/index.php?id=8
    See also: http://www.mindmachineproject.org/proj/omcs/
    See also: https://github.com/commonsense/conceptnet5/wiki
    See also: https://en.wikipedia.org/wiki/Hypergraph
    See also: http://forum.dlang.org/thread/fysokgrgqhplczgmpfws@forum.dlang.org#post-fysokgrgqhplczgmpfws:40forum.dlang.org
    See also: http://www.eturner.net/omcsnetcpp/
    See also: http://wwww.abbreviations.com
    See also: www.oneacross.com/crosswords for inspiring applications
    See also: http://programmers.stackexchange.com/q/261163/38719
    See also: http://www.mindmachineproject.org/proj/prop/

    Data:
    - Open Multilingual Wordnet: http://compling.hss.ntu.edu.sg/omw/
    - Svensk Etymologisk Ordbok: http://runeberg.org/svetym/
    - WordNets: http://globalwordnet.org/wordnets-in-the-world/
    - WordNet 3: http://eb.lv/dict/
    - http://www.clres.com/dict.html
    - http://www.adampease.org/OP/
    - http://www.wordfrequency.info/
    - http://conceptnet5.media.mit.edu/downloads/current/
    - http://wiki.dbpedia.org/DBpediaAsTables
    - http://icon.shef.ac.uk/Moby/
    - http://www.dcs.shef.ac.uk/research/ilash/Moby/moby.tar.Z
    - http://extensions.openoffice.org/en/search?f%5B0%5D=field_project_tags%3A157
    - http://www.mpi-inf.mpg.de/departments/databases-and-information-systems/research/yago-naga/yago/
    - http://www.words-to-use.com/
    - http://www.slangopedia.se/
    - http://www.learn-english-today.com/idioms/
    - http://www.smart-words.org/list-of-synonyms/
    - http://www.thefreedictionary.com/
    - http://www.paengelska.com/engelska_uttryck_a.htm
    - http://www.ego4u.com/en/cram-up/grammar/prepositions

    English Phrases: http://www.talkenglish.com
    Names: http://www.nordicnames.de/
    Names: http://www.behindthename.com/
    Names: http://www.ethnologue.com/browse/names
    Names: http://www.20000-names.com/
    Names: http://surnames.behindthename.com
    Names: http://www.urbandictionary.com/

    People: Pat Winston, Jerry Sussman, Henry Liebermann (Knowledge base)

    TODO Rename Role to Pred or Act or Conn? What does WordNet call it?

    TODO Reuse lemma expr because its immutable. This requires delaying call to
         expr.idup or expr.dup to as late as possible.

    BUG WordNet stores proper names in lowercase. This could be detected and
        fixed in learnLemma() if existing lemmas in uppercase and has sense that
        specializes noun.

    TODO Find dubious words:
         - Swedish: trumpetare - trum-petare
         - Swedish: tunnelbanan - tunnel-banan

    TODO rhymesOf() may reuse Walk.byNode walkOver(Rel.prounounciation)

    BUG Enable readNELLFile and fix bug in it

    TODO specializeUniquely John to name in English if first letter isUpper

    TODO "startsWith(larger than)" gives duplicate searches and takes long

    TODO Add Syllable into Phonemes using some special UTF-8 character middle-dot character.
    TODO Learn Syllables:
         - Extend syllables.d and test it against knowledge/moby/hyphentation.txt
         - Use Java at: https://stackoverflow.com/questions/405161/detecting-syllables-in-a-word
         - https://stackoverflow.com/questions/27889604/open-syllabification-database
         - lemmasByExpr[`one-liner`] => Lemma(`one-liner`) =>
         - May require bool checkSyllables = false;
         - if expr.canFind(syllableSeparator) use splitter(syllableSeparator) instead of findWordSplit()

    TODO Infer: {1} isA NOUN => {1} isA NOUN

    TODO If WordNet is loaded explicitly skip it when loading CN5.

    TODO Prompt Queries:
    TODO canA(NOUN, VERB), canA(bird, fly), canA(man, walk), canA(dead man, walk)
    TODO isA(NOUN, NOUN), canA(bird, animal)
    TODO is(NOUN, ADVERB), canA(bird, dead) infer from: {} hasProperty ADVERB
    TODO all(birds)
    TODO all(bird)
    TODO instancesOf(bird)
    TODO examplesOf(bird)
    TODO translateTo(EXPR, LANGUAGE)

    TODO Infer: x hasProperty dead => x is dead

    TODO Use pattern matching
    TODO {A} means one word referred to with {A}
    TODO {A B} means one word referred to with {A B}
    TODO {1} means one word
    TODO {2} means one word
    TODO {1,2} means one or two words
    TODO {*} means zero or more words
    TODO {+} means one or more words

    TODO In Swedish: *lig <=> *ligt can be inferred to adjective <=> adverb
    TODO In English: X <=> Xely can be inferred to adjective <=> adverb
    TODO In English: X <=> Xly can be inferred to adjective <=> adverb

    TODO Infer English-Swedish Translations: "[are|is] requirED = krävs" because of "require = kräva"

    TODO Use lemma.sense = lemma.expr.until(':').to!Sense.specialize(lemma.sense) in Lemma()

    TODO Make context a Nd such Nd("mammal") =>isA=> Nd("animal")

    TODO Infer senses of consecutive word when reading sorted word
    list. Requires knowledge of Language specfic ending grammar for verbs,
    nouns, adjectives, adverbs. Use (verb|noun|adjective)(Ir)Regular to indicate regularity
    - Swedish: "ersätt", "ersätta", "ersätter", "ersatte", "ersatt"

    TODO Move specific knowledge from wordnet.d to beginning of learnPreciseThings()

    TODO Show warning and then exceptions when adding a word as a language that
    doesn't support include its characters

    BUG Skriv in smärta i prompt: gives wrong relations: "[give" and "cause] pain; grieve"
    BUG reversion no effect for book_property.txt

    BUG Don't stem words containing non-English letters. Reuse variadic version
    of x.canFind(englishLetters...)

    TODO functionize uses of splitter-map-filter to convert CSV-strings to string[]

    TODO Replace comma in .txt files with some other ASCII separator

    TODO Learn Sense.nounUncountablesNouns first and then reuse and specializes "love" in Sense.noun

    TODO Google for Henry Liebermann's Open CommonSense Knowledge Base

    TODO At end of store() use convert Sense to string Rel.noun => "noun" and store it
         connect(secondRef, Rel.isA, store(groupName, firstLang, Sense.noun, origin), firstLang, origin, weight, false, false, true);

    TODO Learn: https://sv.wikipedia.org/wiki/Modalt_hj%C3%A4lpverb

    TODO Use http://www.wordfrequency.info/files/entriesWithoutCollocates.txt etc

    TODO CN5: Infer Sense from specific Rels such as instanceOf Ra
    TODO Infer Senses in both directions over synonymWith typically: plåga (unknown) synonymWith tortera (noun) => plåga must have sense here
    TODO CN5: Parse parens after "Ra (board game)" and put in context
    TODO Infer:
         - X isA Y and Y hasProperty Z => X hasProperty Z: expressed as X.getPropertyMaybe(Z)
         - if X rel Y and assert(R.isSymmetric): Sense can be inferred in both directions if some Sense is unknown
         - shampoo atLocation bathroom, shampoo stored in bottles => bottles atLocation bathroom
         - sulfur synonymWith sulphur => sulfuric synonymWith sulphuric

    TODO Learn word meanings (WordNet) first. Then other higher rules can lookup these
         meanings before they are added.
    TODO For lemmas with Sense.unknown lookup its others lemmasOf. If only one
    other non-unknown Sense exists assume it to be its meaning.

    TODO Nd getEmotion(Nd start, Rel[] overRels) { walkNds(); }

    TODO Add randomness to traverser if normalized distance similarity between
    traversed nodes is smaller than a randomnessThreshold

    TODO Integrate Hits from Google: "list of word emotions" using new relations hasEmotionLove

    TODO See checkExisting in connect() to true only for Origin.manual

    TODO Make use of stealFront and stealBack

    TODO ansiktstvätt => "facial wash"
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
         Perhaps Merge with NELL's ContextIx.

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
    - is a:  nounUncountable(en-nounUncountable:1.00@Manual),
    - in English
    - is the opposite of:  hate(en:1.00@CN5),
    - is the opposite of:  hate(en-verb:1.00@CN5),
    - is the opposite of:  hatred(en-noun:1.00@CN5),
    - is the opposite of:  hate(en:0.55@CN5),
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
import std.algorithm: findSplit, findSplitBefore, findSplitAfter, groupBy, sort, multiSort, skipOver, filter, array, canFind, count, setUnion, setIntersection, min, max;
import std.math: abs;
import std.container: Array;
import std.string: tr, toLower, toUpper, capitalize, representation;
import std.array: array, replace;
import std.uni: isWhite, toLower;
import std.utf: byDchar, UTFException;
import std.typecons: Nullable, Tuple, tuple;
import std.file: readText, exists;
import std.bitmanip: bitfields;
alias rdT = readText;

import algorithm_ex: isPalindrome, either, append, commonSuffixCount;
import range_ex: stealFront, stealBack, ElementType, byPair, pairs;
import traits_ex: isSourceOf, isSourceOfSomeString, isIterableOf, enumMembers, packedBitSizeOf;
import sort_ex: sortBy, rsortBy, sorted;
import skip_ex: skipOverBack, skipOverShortestOf, skipOverBackShortestOf;
import predicates: allEqual;
import dbg;

import rcstring;

import stemming;
import grammars;
import senses;
import krels;

import combinations;
import permutations;
version(msgpack) import msgpack;

enum char asciiUS = '';       // ASCII Unit Separator
enum char asciiRS = '';       // ASCII Record Separator
enum char asciiGS = '';       // ASCII Group Separator
enum char asciiFS = '';       // ASCII File Separator

enum syllableSeparator = asciiUS; // separates syllables
enum alternativesSeparator = asciiRS; // separates alternatives
enum roleSeparator = asciiFS; // separates subject from object, translations, etc.
enum qualifierSeparator = ':'; // noun:eka

enum meaningNrSeparator = ';'; // tomten;1 tomten;2
const meaningNrSeparatorString = `:`;

enum countSeparator = '#'; // gives occurrence count

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
            case `foundedin`: return foundedIn;

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

            case `attend`:
            case `attends`:
            case `worksfor`:                                       return worksFor;
            case `writesforpublication`:                           return writesForPublication;
            case `inacademicfield`:                                return worksInAcademicField;

            case `ceoof`:                                          return ceoOf;
            case `play`:
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

            case `cause`:
            case `causes`:
            case `cancause`:                                       return causes;

            case `leadto`:
            case `leadsto`:                                        return causes;

            case `entail`:
            case `entails`:                      reversion = true; return causes;

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

            case `desire`:
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

            case `acquire`:
            case `acquires`:
            case `acquired`: tense = Tense.pastMoment; return acquires;

            case `affiliatedwith`: tense = Tense.pastMoment; return affiliatesWith;

            case `own`:
            case `owns`:                                           return owns;

            case `hire`:
            case `hires`:
            case `hired`: tense = Tense.pastMoment; return hires;
            case `hiredBy`: reversion = true; tense = Tense.pastMoment; return hires;

            case `create`:
            case `creates`:
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
            case `generalizations`:              reversion = true; return isA;
            case `specializationof`:                               return isA;
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

            case `foundedIn`:                                      return foundedIn;

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
    moby,                       ///< Moby.

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
    final switch (origin) with (Origin)
    {
        case unknown: return "Unknown";
        case cn5: return "CN5";
        case dbpedia: return "DBpedia";
            // case dbpedia37: return "DBpedia37";
            // case dbpedia39Umbel: return "DBpedia39Umbel";
            // case dbpediaEn: return "DBpediaEnglish";

        case wordnet: return "WordNet";
        case moby: return "Moby";

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

static if (false)
Role decodeWordNetPointerSymbol(string sym, Sense sense)
{
    typeof(return) role;
    with (Rel)
    {
        switch (sym)
        {
            case `!`:  role = Role(antonymFor); break;
            case `@`:  role = Role(hypernymOf, true); break;
            case `@i`: role = Role(instanceHypernymOf, true); break;
            case `~`:  role = Role(hyponymOf); break;
            case `~i`: role = Role(instanceHyponymOf); break;
            case `*`:  role = Role(causes, true); break; // entailment.

            case `#m`: role = Role(memberHolonym); break;
            case `#s`: role = Role(substanceHolonym); break;
            case `#p`: role = Role(partHolonym); break;
            case `%m`: role = Role(memberOf); break;
            case `%s`: role = Role(madeOf); break;
            case `%p`: role = Role(partOf); break;

            case `=`:  role = Role(attribute); break;
            case `+`:  role = Role(derivationallyRelatedForm); break;
            case `;c`: role = Role(domainOfSynset); break; // TOPIC
            case `-c`: role = Role(memberOfThisDomain); break;  // TOPIC
            case `;r`: role = Role(domainOfSynset); break; // REGION
            case `-r`: role = Role(memberOfThisDomain); break; // REGION
            case `;u`: role = Role(domainOfSynset); break; // USAGE
            case `-u`: role = Role(memberOfThisDomain); break; // USAGE

            case `>`:  role = Role(causes); break;
            case `^`:  role = Role(alsoSee); break;
            case `$`:  role = Role(formOfVerb); break;

            case `&`:  role = Role(similarTo); break;
            case `<`:  role = Role(participleOfVerb); break;

            case `\`:  role = Role(pertainym); break; // pertains to noun
            case `=`:  role = Role(attribute); break;

            default:
                assert(false, `Unexpected relation type ` ~ sym);
                break;
        }
    }
    return role;
}

/** Decode Moby Pronounciation Code to IPA Language.
    See also: https://en.wikipedia.org/wiki/Moby_Project#Pronunciator
*/
auto decodeMobyIPA(S)(S code) if (isSomeString!S)
{
    switch (code)
    {
        case `&`: return `æ`;
        case `-`: return `ə`;
        case `@`: return `ʌ`; // both `ʌ` or `ə` are allowed
        case `[@]`: return `ɜ`; // undocumented?
        case `(@)`: return `eə`; // undocumented in Moby?
        case `@r`: return `ɜr`; // alt: `ər`
        case `A`: return `ɑː`;
        case `aI`: return `aɪ`;
        case `Ar`: return `ɑr`;
        case `AU`: return `aʊ`;
        case `b`: return `b`;
        case `d`: return `d`;
        case `D`: return `ð`;
        case `dZ`: return `dʒ`;
        case `E`: return `ɛ`;
        case `eI`: return `eɪ`;
        case `f`: return `f`;
        case `g`: return `ɡ`;
        case `h`: return `h`;
        case `hw`: return `hw`;
        case `i`: return `iː`;
        case `I`: return `ɪ`;
        case `j`: return `j`;
        case `k`: return `k`;
        case `l`: return `l`;
        case `m`: return `m`;
        case `n`: return `n`;
        case `N`: return `ŋ`;
        case `O`: return `ɔː`;
        case `Oi`: return `ɔɪ`;
        case `oU`: return `oʊ`;
        case `p`: return `p`;
        case `r`: return `r`;
        case `s`: return `s`;
        case `S`: return `ʃ`;
        case `t`: return `t`;
        case `T`: return `θ`;
        case `tS`: return `tʃ`;
        case `u`: return `uː`;
        case `U`: return `ʊ`;
        case `v`: return `v`;
        case `w`: return `w`;
        case `z`: return `z`;
        case `Z`: return `ʒ`;
        case `'`: return `'`; // primary stress on the following syllable
        case `,`: return `,`; // secondary stress on the following syllable
        default:
        // dln("warning: ", code);
        return code.idup;
    }
}

/** Decode Sense of Moby Part of Speech (PoS) Code.
*/
Sense decodeSenseOfMobyPoSCode(C)(C code) if (isSomeChar!C)
{
    switch (code) with (Sense)
    {
        case 'N': return nounSingular;
        case 'p': return nounPlural;
        case 'h': return nounPhrase;
        case 'V': return verb;
        case 't': return verbTransitive;
        case 'i': return verbIntransitive;
        case 'A': return adjective;
        case 'v': return adverb;
        case 'C': return conjunction;
        case 'P': return preposition;
        case '!': return interjection;
        case 'r': return pronoun;
        case 'D': return articleDefinite;
        case 'I': return articleIndefinite;
        case 'o': return nounNominative;
        default: dln("warning: Unknown code character " ~ code); return unknown;
    }
}

/** Main Knowledge Network.
*/
class Net(bool useArray = true,
          bool useRCString = true)
{
    import std.range: front, split, isInputRange, back;
    import std.algorithm: joiner, clamp;
    import std.path: buildNormalizedPath, expandTilde, extension;
    import std.algorithm: strip, array, until, dropOne, dropBackOne;
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
    alias Nd = Ref!Node;

    /// Reference to Link.
    alias Ln = Ref!Link;

    /** Expression (String). */
    static if (useRCString) { alias Expr = RCXString!(immutable char, 24-1); }
    else                    { alias Expr = immutable string; }

    /// References to Nodes.
    static if (useArray) { alias Nds = Array!Nd; }
    else                 { alias Nds = Nd[]; }

    /// References to Links.
    static if (useArray) { alias LinkRefs = Array!Ln; }
    else                 { alias LinkRefs = Ln[]; }

    /** Context or Ontology Category Index (currently from NELL). */
    struct ContextIx
    {
        @safe @nogc pure nothrow:
        static ContextIx asUndefined() { return ContextIx(0); }
        bool defined() const { return this != ContextIx.asUndefined; }
        /* auto opCast(T : bool)() { return defined; } */
    private:
        ushort _ix = 0;
    }

    // TODO Use in Lemma.
    enum MeaningVariant { unknown = 0, first = 1, second = 2, third = 3 }

    /** Node Concept Lemma. */
    struct Lemma
    {
        @safe // @nogc
        pure // nothrow
        :

        this(string expr,
             Lang lang,
             Sense sense,
             ContextIx context = ContextIx.asUndefined,
             Manner manner = Manner.formal,
             bool isRegexp = false,
             ubyte meaningNr = 0) in { assert(meaningNr <= MeaningNrMax); }
        body
        {
            this.isRegexp = expr.skipOver(`regex:`) ? true : isRegexp;
            if (expr.length >= 2 &&
                expr[$ - 2] == meaningNrSeparator)
            {
                const ubyte nrCharByte = expr.representation.back;
                assert(nrCharByte >= '0' &&
                       nrCharByte <= '9');
                this.meaningNr = cast(ubyte)(nrCharByte - '0');
                expr = expr[0 .. $ - 2]; // skip meaning number suffix
                assert(meaningNr == 0,
                       `Can't override already decoded meaning number`
                       /* ~ this.meaningNr.to!string */);
            }
            else
            {
                this.meaningNr = meaningNr;
            }

            this.lang = lang;
            this.sense = sense;
            this.manner = manner;
            this.context = context;

            auto split = expr.findSplit(meaningNrSeparatorString);
            if (!split[1].empty) // if a split was found
            {
                try
                {
                    this.sense = split[0].to!Sense;
                    assert(sense == Sense.unknown,
                           `Can't override sense argumented ` ~ sense
                           ~ ` with ` ~ this.sense);
                    expr = split[2];
                    dln(`Decoded expr `, expr, ` to have sense `, this.sense);
                }
                catch (std.conv.ConvException e)
                {
                    /* ok to not be able to downcase */
                }
            }

            this.expr = expr;
        }

        Expr expr;
        /* The following three are used to disambiguate different semantics
         * meanings of the same word in different languages. */
        Lang lang;
        Sense sense;
        ContextIx context;

        enum bitsizeOfManner = packedBitSizeOf!Manner;
        enum bitsizeOfMeaningNr = 8 - bitsizeOfManner - 1;
        enum MeaningNrMax = 2^^bitsizeOfMeaningNr - 1;

        mixin(bitfields!(Manner, `manner`, bitsizeOfManner,
                         ubyte, `meaningNr`, bitsizeOfMeaningNr,
                         bool, `isRegexp`, 1 // true if $(D expr) is a regular expression
                  ));
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

    /** Get Links Refs of $(D node) with direction $(D dir).
        TODO what to do with role.reversion here?
     */
    auto linkRefsOf(in Node node,
                    RelDir dir = RelDir.any,
                    Role role = Role.init)
    {
        return node.links[]
                   .filter!(ln => (dir.of(RelDir.any, ln.dir) &&  // TODO functionize to match(RelDir, RelDir)
                                   at(ln).role.negation == role.negation &&
                                   (at(ln).role.rel == role.rel ||
                                    at(ln).role.rel.specializes(role.rel))));
    }

    auto linksOf(in Node node,
                 RelDir dir = RelDir.any,
                 Role role = Role.init)
    {
        return linkRefsOf(node, dir, role).map!(ln => at(ln));
    }

    auto linksOf(Nd nd,
                 RelDir dir = RelDir.any,
                 Role role = Role.init)
    {
        return linksOf(at(nd), dir, role);
    }

    alias Step = Tuple!(Ln, Nd); // steps from Node
    alias Path = Step[]; // path of steps from Node

    /** Network Traverser.
        TODO: Returns Path
     */
    class Traverser
    {
        this(Nd first_)
        {
            first = first_;
            current = first;
        }

        auto front()
        {
            return linkRefsOf(at(current));
        }

        Nd first;
        Nd current;
        NWeight[Nd] dists;
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

        this(Nd src,
             Role role,
             Nd dst,
             Origin origin = Origin.unknown) in { assert(src.defined && dst.defined); }
        body
        {
            // http://forum.dlang.org/thread/mevnosveagdiswkxtbrv@forum.dlang.org#post-zhndpadqtfareymbnfis:40forum.dlang.org
            // this.actors.append(src.backward,
            //                    dst.forward);
            this.actors.reserve(this.actors.length + 2);
            this.actors ~= src.backward;
            this.actors ~= dst.forward;

            this.role = role;
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
        @property NWeight nweight() const
        {
            return ((cast(typeof(return))packedWeight)/
                    (cast(typeof(return))PWeight.max));
        }

    private:
        Nds actors;
        PWeight packedWeight;
        Role role;
        Origin origin;
    }

    auto ins (in Link link) { return link.actors[].filter!(nd => nd.dir() == RelDir.backward); }
    auto outs(in Link link) { return link.actors[].filter!(nd => nd.dir() == RelDir.forward); }

    pragma(msg, `Expr.sizeof: `, Expr.sizeof);
    pragma(msg, `Lemma.sizeof: `, Lemma.sizeof);
    pragma(msg, `Node.sizeof: `, Node.sizeof);
    pragma(msg, `LinkRefs.sizeof: `, LinkRefs.sizeof);
    pragma(msg, `Nds.sizeof: `, Nds.sizeof);
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
        Nd[Lemma] nodeRefByLemma;
        Nodes allNodes;
        Links allLinks;

        Lemmas[Expr] lemmasByExpr;

        string[ContextIx] contextNameByIx; /** Ontology Context Names by Index. */
        ContextIx[string] contextIxByName; /** Ontology Context Indexes by Name. */

        enum anyContext = ContextIx.asUndefined; // reserve 0 for anyContext (unknown)
        ushort contextIxCounter = ContextIx.asUndefined._ix + 1; // 1 because 0 is reserved for anyContext (unknown)

        size_t multiWordNodeLemmaCount = 0; // number of nodes that whose lemma contain several expr

        WordNet!(true, true) wordnet;

        size_t symmetricRelCount = 0; /// Symmetric Relation Count.
        size_t transitiveRelCount = 0; /// Transitive Relation Count.

        size_t[Rel.max + 1] relCounts; /// Link Counts by Relation Type.
        size_t[Origin.max + 1] linkSourceCounts;
        size_t[Lang.max + 1] nodeCountByLang;
        size_t[Sense.max + 1] nodeCountBySense; /// Node Counts by Sense Type.
        size_t nodeStringLengthSum = 0;

        // Connectedness
        size_t nodeConnectednessSum = 0;
        size_t linkConnectednessSum = 0;

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
        ref inout(Link) at(const Ln ln) inout { return allLinks[ln.ix]; }
        ref inout(Node) at(const Nd cref) inout @nogc { return allNodes[cref.ix]; }

        ref inout(Link) opIndex(const Ln ln) inout { return at(ln); }
        ref inout(Node) opIndex(const Nd nd) inout { return at(nd); }

        ref inout(Link) opUnary(string s)(const Ln ln) inout if (s == "*") { return at(ln); }
        ref inout(Node) opUnary(string s)(const Nd nd) inout if (s == "*") { return at(nd); }
    }

    Nd nodeRefByLemmaMaybe(in Lemma lemma)
    {
        return (lemma in nodeRefByLemma ?
                         nodeRefByLemma[lemma] :
                         typeof(return).init);
    }

    /** Try to Get Single Node related to $(D word) in the interpretation
        (semantic context) $(D sense).
    */
    Nds nodeRefsByLemmaDirect(S)(S expr,
                                 Lang lang,
                                 Sense sense,
                                 ContextIx context) if (isSomeString!S)
    {
        typeof(return) nodes;
        auto lemma = Lemma(expr, lang, sense, context);
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
                auto lemmaFixed = Lemma(wordsFixed, lang, sense, context);
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

    /** Get All Possible Nodes related to $(D word) in the interpretation
        (semantic context) $(D sense).
        If no sense given return all possible.
    */
    Nds nodeRefsOf(S)(S expr,
                      Lang lang,
                      Sense sense,
                      ContextIx context = anyContext) if (isSomeString!S)
    {
        typeof(return) nodes;

        if (lang != Lang.unknown &&
            sense != Sense.unknown &&
            context != anyContext) // if exact Lemma key can be used
        {
            return nodeRefsByLemmaDirect(expr, lang, sense, context); // fast hash lookup
        }
        else
        {
            nodes = Nds(nodeRefsOf(expr).filter!(a => (lang == Lang.unknown ||
                                                       at(a).lemma.lang == lang))
                                        .array); // TODO avoid allocations
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

    /** Get All Possible Lemmas related to $(D word).
     */
    Lemmas lemmasOf(S)(S expr) if (isSomeString!S)
    {
        static if (is(S == string)) // TODO Is there a prettier way to do this?
        {
            return lemmasByExpr.get(expr, typeof(return).init);
        }
        else
        {
            return lemmasByExpr.get(expr.dup, typeof(return).init);
        }
    }

    /** Learn $(D Lemma) of $(D expr).
        Returns: either existing specialized lemma or a reference to the newly stored one.
     */
    ref Lemma learnLemma(ref Lemma lemma) @safe
    {
        auto lemmas = lemma.expr in lemmasByExpr;
        if (lemmas)
        {
            // TODO lemma.expr = *lemmas.front.expr; // reuse already GC-stored Expr

            // reuse senses that specialize lemma.sense and modify lemma.sense to it
            foreach (ref existingLemma; *lemmas)
            {
                if (existingLemma.lang == lemma.lang &&
                    existingLemma.context == lemma.context &&
                    existingLemma.manner == lemma.manner &&
                    existingLemma.meaningNr == lemma.meaningNr &&
                    existingLemma.isRegexp == lemma.isRegexp &&
                    existingLemma.sense.specializes(lemma.sense))
                {
                    // dln(`Specializing sense of Lemma "`, lemma.expr, `"`,
                    //     ` from "`, lemma.sense, `"`
                    //     ` to "`, existingLemma.sense, `"`);
                    // lemma.sense = existingLemma.sense;
                    return existingLemma;
                }
            }

            const hitAlt = (*lemmas).canFind(lemma);
            if (!hitAlt) // TODO Make use of binary search
            {
                *lemmas ~= lemma;
            }
        }
        else
        {
            static if (!isDynamicArray!Lemmas)
            {
                lemmasByExpr[lemma.expr] = Lemmas.init; // TODO fix std.container.Array
            }
            lemmasByExpr[lemma.expr] ~= lemma;
        }
        return lemma;
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

    void readIndexLine(R, N)(const R line,
                             const N lnr,
                             const Lang lang = Lang.unknown,
                             Sense sense = Sense.unknown,
                             const bool useMmFile = false)
    {
        if (!line.empty &&
            !line.front.isWhite) // if first is not space. TODO move this check
        {
            static if (isSomeString!R) { const linestr = line; }
            else                       { const linestr = cast(string)line.idup; }
            /* pragma(msg, typeof(line).stringof); */
            /* pragma(msg, typeof(line.idup).stringof); */
            const words = linestr.split; // TODO Use splitter to optimize

            // const lemma = words[0].idup; // NOTE: Stuff fails if this is set
            static if (useRCString) { immutable Lemma lemma = words[0].replace("_", " "); }
            else                    { immutable lemma = words[0].replace("_", " ").idup; }

            const pos          = words[1]; // Part of Speech (PoS)
            const synset_cnt   = words[2].to!uint; // Synonym Set Counter
            const p_cnt        = words[3].to!uint;
            const ptr_symbol   = words[4 .. 4+p_cnt];

            // const sense_cnt    = words[4+p_cnt].to!uint; // same as synset_cnt above (redundant)
            // debug assert(synset_cnt == sense_cnt);

            const tagsense_cnt = words[5+p_cnt].to!uint;
            const synset_off   = words[6+p_cnt].to!uint;
            auto ids = words[6+p_cnt .. $].map!(a => a.to!uint); // relating ids

            const posSense = pos.decodeWordSense;
            if (sense == Sense.unknown) { sense = posSense; }
            if (posSense != sense) { assert(posSense == sense); }

            // const roles = ptr_symbol.map!(sym => sym.decodeWordNetPointerSymbol(sense));

            static if (useArray)
            {
                // auto links = Links(ids);
            }
            else
            {
                // auto links = ids.array;
            }

            auto node = store(lemma, Lang.en, sense, Origin.wordnet);

            // dln(at(node).lemma.expr, " has pointers ", ptr_symbol);
            // auto meaning = Entry!Links(words[1].front.decodeWordSense,
            //                            words[2].to!ubyte, links, lang);
            // _words[lemma] ~= meaning;
        }
    }

    /** Read WordNet Index File $(D fileName).
        Manual page: wndb
    */
    void readIndex(string fileName,
                   bool useMmFile = false,
                   Lang lang = Lang.unknown,
                   Sense sense = Sense.unknown)
    {
        size_t lnr;
        /* TODO Functionize and merge with conceptnet5.readCSV */
        if (useMmFile)
        {
            version (none)
            {
                import std.mmfile: MmFile;
                auto mmf = new MmFile(fileName, MmFile.Mode.read, 0, null, pageSize);
                const data = cast(ubyte[])mmf[];
                foreach (line; data.byLine)
                {
                    readIndexLine(line, lnr, lang, sense, useMmFile);
                    lnr++;
                }
            }
        }
        else
        {
            foreach (line; File(fileName).byLine)
            {
                readIndexLine(line, lnr, lang, sense);
                lnr++;
            }
        }
        writeln(`Read `, lnr, ` words from `, fileName);
    }

    /// Read WordNet Database (dict) in directory $(D dirPath).
    void readWordNet(const string dirPath)
    {
        // NOTE: Test both read variants through alternating uses of Mmfile or not
        const lang = Lang.en;
        readIndex(dirPath.buildNormalizedPath(`index.adj`), false, lang, Sense.adjective);
        readIndex(dirPath.buildNormalizedPath(`index.adv`), false, lang, Sense.adverb);
        readIndex(dirPath.buildNormalizedPath(`index.noun`), false, lang, Sense.noun);
        readIndex(dirPath.buildNormalizedPath(`index.verb`), false, lang, Sense.verb);
    }

    /** Construct Network
        Read sources in order of decreasing reliability.
     */
    this(string dirPath)
    {
        unittestMe();
        learnDefault(dirPath);
        // inferSpecializedSenses();
    }

    /** Run unittests.
    */
    void unittestMe()
    {
        const beInEnglish = store(`be`, Lang.en, Sense.verb, Origin.manual);
        const beInSwedish = store(`be`, Lang.sv, Sense.verb, Origin.manual);
        assert(at(beInEnglish).lemma.expr == at(beInSwedish).lemma.expr);
        // immutable expr should be reused
        // assert(&at(beInEnglish).lemma.expr == &at(beInSwedish).lemma.expr);
    }

    void learnDefault(string dirPath)
    {
        const quick = true;
        const maxCount = quick ? 10000 : size_t.max;

        // Learn Absolute (Trusthful) Things before untrusted machine generated data is read
        learnPreciseThings();

        if (true)
            learnTrainedThings();

        // Learn Less Absolute Things
        learnAssociativeThings();

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

        // NELL
        if (false)
        {
            readNELLFile("~/Knowledge/nell/NELL.08m.890.esv.csv".expandTilde
                                                                .buildNormalizedPath,
                         10000);
        }

        // TODO msgpack fails to pack
        /* auto bytes = this.pack; */
        /* writefln("Packed size: %.2f", bytes.length/1.0e6); */
    }

    /// Learn Externally (Trained) Supervised Things.
    void learnTrainedThings()
    {
        // wordnet = new WordNet!(true, true)([Lang.en]); // TODO Remove
        readWordNet(`~/Knowledge/wordnet/dict-3.1`.expandTilde);
        // readSwesaurus();
    }

    /** Learn Precise (Absolute) Thing.
     */
    void learnPreciseThings()
    {
        learnEnumMemberNameHierarchy!Sense(Sense.nounSingular);

        // TODO replace with automatics
        learnMto1(Lang.en, rdT("../knowledge/en/uncountable_noun.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `uncountable`, Sense.nounUncountable, Sense.noun, 1.0);
        learnMto1(Lang.sv, rdT("../knowledge/sv/uncountable_noun.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `uncountable`, Sense.nounUncountable, Sense.noun, 1.0);

        // Part of Speech (PoS)
        learnPartOfSpeech();

        learnPunctuation();

        learnEnglishComputerKnowledge();

        learnMath();
        learnPhysics();
        learnComputers();

        learnEnglishOther();

        learnVerbReversions();
        learnEtymologicallyDerivedFroms();

        learnSwedishGrammar();

        learnNames();

        learnMto1(Lang.en, rdT("../knowledge/en/people.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `people`, Sense.noun, Sense.nounUncountable, 1.0);

        // TODO functionize to learnGroup
        learnMto1(Lang.en, rdT("../knowledge/en/compound_word.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `compound word`, Sense.unknown, Sense.nounSingular, 1.0);

        // Other

        // See also: https://en.wikipedia.org/wiki/Dolch_word_list
        learnMto1(Lang.en, rdT("../knowledge/en/dolch_singular_noun.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `dolch word`, Sense.nounSingular, Sense.nounSingular, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/dolch_preprimer.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `dolch pre-primer word`, Sense.unknown, Sense.nounSingular, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/dolch_primer.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `dolch primer word`, Sense.unknown, Sense.nounSingular, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/dolch_1st_grade.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `dolch 1-st grade word`, Sense.unknown, Sense.nounSingular, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/dolch_2nd_grade.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `dolch 2-nd grade word`, Sense.unknown, Sense.nounSingular, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/dolch_3rd_grade.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `dolch 3-rd grade word`, Sense.unknown, Sense.nounSingular, 1.0);

        learnMto1(Lang.en, rdT("../knowledge/en/personal_quality.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `personal quality`, Sense.adjective, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/color.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `color`, Sense.unknown, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/shapes.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `shape`, Sense.noun, Sense.noun, 1.0);

        learnMto1(Lang.en, rdT("../knowledge/en/fruits.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `fruit`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/plants.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `plant`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/trees.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `tree`, Sense.noun, Sense.plant, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/spice.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `spice`, Sense.spice, Sense.food, 1.0);

        learnMto1(Lang.en, rdT("../knowledge/en/shoes.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `shoe`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/dances.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `dance`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/landforms.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `landform`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/desserts.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `dessert`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/countries.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `country`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/us_states.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `us_state`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/furniture.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `furniture`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/good_luck_symbols.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `good luck symbol`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/leaders.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `leader`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/measurements.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `measurement`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/quantity.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `quantity`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/language.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `language`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/insect.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `insect`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/musical_instrument.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `musical instrument`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/weapon.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `weapon`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/hats.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `hat`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/rooms.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `room`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/containers.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `container`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/virtues.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `virtue`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/vegetables.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `vegetable`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/flower.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `flower`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/reptile.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `reptile`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/famous_pair.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `pair`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/season.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `season`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/holiday.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `holiday`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/birthday.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.any), `birthday`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/biomes.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `biome`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/dogs.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `dog`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/rodent.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `rodent`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/fish.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `fish`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/birds.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `bird`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/amphibians.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `amphibian`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/animals.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `animal`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/mammals.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `mammal`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/food.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `food`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/cars.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `car`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/building.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `building`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/housing.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `housing`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/occupation.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `occupation`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/cooking_tool.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `cooking tool`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/tool.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `tool`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/carparts.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.partOf), `car`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/bodyparts.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.partOf), `body`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/alliterations.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `alliteration`, Sense.unknown, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/positives.txt").splitter('\n').filter!(word => !word.empty), Role(Rel.hasAttribute), `positive`, Sense.unknown, Sense.adjective, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/mineral.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `mineral`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/metal.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `metal`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/mineral_group.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `mineral group`, Sense.noun, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/major_mineral_group.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `major mineral group`, Sense.noun, Sense.noun, 1.0);

        // Swedish
        learnMto1(Lang.sv, rdT("../knowledge/sv/house.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `hus`, Sense.noun, Sense.noun, 1.0);

        learnChemicalElements();

        foreach (lang; enumMembers!Lang.filter!(lang =>
                                                ("../knowledge/" ~ lang.to!string).exists))
        {
            const langString = lang.to!string;
            const dirPath = "../knowledge/" ~ langString;

            // Male Name
            learnMtoNMaybe(dirPath ~ "/male_name.txt", // TODO isA male name
                           Sense.nameMale, lang,
                           Role(Rel.hasMeaning),
                           Sense.unknown, lang,
                           Origin.manual, 1.0);

            // Female Name
            learnMtoNMaybe(dirPath ~ "/female_name.txt", // TODO isA female name
                           Sense.nameFemale, lang,
                           Role(Rel.hasMeaning),
                           Sense.unknown, lang,
                           Origin.manual, 1.0);

            // Irregular Noun
            learnMtoNMaybe(dirPath ~ "/irregular_noun.txt",
                           Sense.nounSingular, lang,
                           Role(Rel.formOfNoun),
                           Sense.nounPlural, lang,
                           Origin.manual, 1.0);

            // Abbrevation
            learnMtoNMaybe(dirPath ~ "/abbrevation.txt",
                           Sense.unknown, lang,
                           Role(Rel.abbreviationFor),
                           Sense.unknown, lang,
                           Origin.manual, 1.0);
            learnMtoNMaybe(dirPath ~ "/noun_abbrevation.txt",
                           Sense.noun, lang,
                           Role(Rel.abbreviationFor),
                           Sense.noun, lang,
                           Origin.manual, 1.0);

            // Synonym
            learnMtoNMaybe(dirPath ~ "/synonym.txt",
                           Sense.unknown, lang, Role(Rel.synonymFor),
                           Sense.unknown, lang, Origin.manual, 1.0);
            learnMtoNMaybe(dirPath ~ "/obsolescent_synonym.txt",
                           Sense.unknown, lang, Role(Rel.obsolescentFor),
                           Sense.unknown, lang, Origin.manual, 1.0);
            learnMtoNMaybe(dirPath ~ "/noun_synonym.txt",
                           Sense.noun, lang, Role(Rel.synonymFor),
                           Sense.noun, lang, Origin.manual, 0.5);
            learnMtoNMaybe(dirPath ~ "/adjective_synonym.txt",
                           Sense.adjective, lang, Role(Rel.synonymFor),
                           Sense.adjective, lang, Origin.manual, 1.0);

            // Homophone
            learnMtoNMaybe(dirPath ~ "/homophone.txt",
                           Sense.unknown, lang, Role(Rel.homophoneFor),
                           Sense.unknown, lang, Origin.manual, 1.0);

            // Abbrevation
            learnMtoNMaybe(dirPath ~ "/cardinal_direction_abbrevation.txt",
                           Sense.unknown, lang, Role(Rel.abbreviationFor),
                           Sense.unknown, lang, Origin.manual, 1.0);
            learnMtoNMaybe(dirPath ~ "/language_abbrevation.txt",
                           Sense.language, lang, Role(Rel.abbreviationFor),
                           Sense.language, lang, Origin.manual, 1.0);

            // Noun
            learnMto1Maybe(lang, dirPath ~ "/concrete_noun.txt",
                           Role(Rel.hasAttribute), `concrete`,
                           Sense.nounConcrete, Sense.adjective, 1.0);
            learnMto1Maybe(lang, dirPath ~ "/abstract_noun.txt",
                           Role(Rel.hasAttribute), `abstract`,
                           Sense.nounAbstract, Sense.adjective, 1.0);
            learnMto1Maybe(lang, dirPath ~ "/masculine_noun.txt",
                           Role(Rel.hasAttribute), `masculine`,
                           Sense.noun, Sense.adjective, 1.0);
            learnMto1Maybe(lang, dirPath ~ "/feminine_noun.txt",
                           Role(Rel.hasAttribute), `feminine`,
                           Sense.noun, Sense.adjective, 1.0);

            // Acronym
            learnMtoNMaybe(dirPath ~ "/acronym.txt",
                           Sense.nounAcronym, lang, Role(Rel.acronymFor),
                           Sense.unknown, lang, Origin.manual, 1.0);
            learnMtoNMaybe(dirPath ~ "/newspaper_acronym.txt",
                           Sense.newspaper, lang,
                           Role(Rel.acronymFor),
                           Sense.newspaper, lang,
                           Origin.manual, 1.0);

            // Idioms
            learnMtoNMaybe(dirPath ~ "/idiom_meaning.txt",
                           Sense.idiom, lang,
                           Role(Rel.idiomFor),
                           Sense.unknown, lang,
                           Origin.manual, 0.7);

            // Slang
            learnMtoNMaybe(dirPath ~ "/slang_meaning.txt",
                           Sense.unknown, lang,
                           Role(Rel.slangFor),
                           Sense.unknown, lang,
                           Origin.manual, 0.7);

            // Slang Adjectives
            learnMtoNMaybe(dirPath ~ "/slang_adjective_meaning.txt",
                           Sense.adjective, lang,
                           Role(Rel.slangFor),
                           Sense.unknown, lang,
                           Origin.manual, 0.7);

            // Name
            learnMtoNMaybe(dirPath ~ "/male_name_meaning.txt",
                           Sense.nameMale, lang,
                           Role(Rel.hasMeaning),
                           Sense.unknown, lang,
                           Origin.manual, 0.7);
            learnMtoNMaybe(dirPath ~ "/female_name_meaning.txt",
                           Sense.nameFemale, lang,
                           Role(Rel.hasMeaning),
                           Sense.unknown, lang,
                           Origin.manual, 0.7);
            learnMtoNMaybe(dirPath ~ "/name_day.txt",
                           Sense.name, lang,
                           Role(Rel.hasNameDay),
                           Sense.nounDate, Lang.en,
                           Origin.manual, 1.0);
            learnMtoNMaybe(dirPath ~ "/surname_languages.txt",
                           Sense.surname, Lang.unknown,
                           Role(Rel.hasOrigin),
                           Sense.language, Lang.en,
                           Origin.manual, 1.0);

            // City
            try
            {
                foreach (entry; rdT(dirPath ~ "/city.txt").splitter('\n').filter!(w => !w.empty))
                {
                    const items = entry.split(roleSeparator);
                    const cityName = items[0];
                    const population = items[1];
                    const yearFounded = items[2];
                    const city = store(cityName, lang, Sense.city, Origin.manual);
                    connect(city, Role(Rel.hasAttribute),
                            store(population, lang, Sense.population, Origin.manual), Origin.manual, 1.0);
                    connect(city, Role(Rel.foundedIn),
                            store(yearFounded, lang, Sense.year, Origin.manual), Origin.manual, 1.0);
                }
            }
            catch (std.file.FileException e) {}

            try { learnMto1(lang, rdT(dirPath ~ "/vehicle.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `vehicle`, Sense.noun, Sense.noun, 1.0); }
            catch (std.file.FileException e) {}

            try { learnMto1(lang, rdT(dirPath ~ "/lowercase_letter.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `lowercase letter`, Sense.letterLowercase, Sense.noun, 1.0); }
            catch (std.file.FileException e) {}

            try { learnMto1(lang, rdT(dirPath ~ "/uppercase_letter.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `uppercase letter`, Sense.letterUppercase, Sense.noun, 1.0); }
            catch (std.file.FileException e) {}

            try { learnMto1(lang, rdT(dirPath ~ "/old_proverb.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `old proverb`, Sense.unknown, Sense.noun, 1.0); }
            catch (std.file.FileException e) {}

            try { learnMto1(lang, rdT(dirPath ~ "/contronym.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `contronym`, Sense.unknown, Sense.noun, 1.0); }
            catch (std.file.FileException e) {}
        }

        // Translation
        learnMtoNMaybe("../knowledge/en-sv/noun_translation.txt",
                       Sense.noun, Lang.en,
                       Role(Rel.translationOf),
                       Sense.noun, Lang.sv,
                       Origin.manual, 1.0);
        learnMtoNMaybe("../knowledge/en-sv/phrase_translation.txt",
                       Sense.unknown, Lang.en,
                       Role(Rel.translationOf),
                       Sense.unknown, Lang.sv,
                       Origin.manual, 1.0);
        learnMtoNMaybe("../knowledge/la-sv/phrase_translation.txt",
                       Sense.unknown, Lang.la,
                       Role(Rel.translationOf),
                       Sense.unknown, Lang.sv,
                       Origin.manual, 1.0);
        learnMtoNMaybe("../knowledge/la-en/phrase_translation.txt",
                       Sense.unknown, Lang.la,
                       Role(Rel.translationOf),
                       Sense.unknown, Lang.en,
                       Origin.manual, 1.0);
        learnMtoNMaybe("../knowledge/en-sv/idiom_translation.txt",
                       Sense.idiom, Lang.en,
                       Role(Rel.translationOf),
                       Sense.idiom, Lang.sv,
                       Origin.manual, 1.0);
        learnMtoNMaybe("../knowledge/en-sv/interjection_translation.txt",
                       Sense.interjection, Lang.en,
                       Role(Rel.translationOf),
                       Sense.interjection, Lang.sv,
                       Origin.manual, 1.0);
        learnMtoNMaybe("../knowledge/fr-en/phrase_translation.txt",
                       Sense.unknown, Lang.fr,
                       Role(Rel.translationOf),
                       Sense.unknown, Lang.en,
                       Origin.manual, 1.0);

        learnOpposites();

        learnEmotions();
        learnEnglishFeelings();
        learnSwedishFeelings();

        learnEnglishWordUsageRanks();
    }

    void learnEnglishWordUsageRanks()
    {
        const path = "../knowledge/en/word_usage_rank.txt";
        foreach (line; File(path).byLine)
        {
            auto split = line.splitter(roleSeparator);
            const rank = split.front.idup; split.popFront;
            const word = split.front.idup; split.popFront;
            connect(store(word, Lang.en, Sense.unknown, Origin.manual), Role(Rel.hasAttribute),
                    store(rank, Lang.en, Sense.rank, Origin.manual), Origin.manual, 1.0);
        }
    }

    void learnPartOfSpeech()
    {
        learnPronouns();
        learnAdjectives();
        learnAdverbs();
        learnUndefiniteArticles();
        learnDefiniteArticles();
        learnPartitiveArticles();
        learnConjunctions();
        learnInterjections();
        learnTime();

        // Verb
        learnMto1(Lang.en, rdT("../knowledge/en/regular_verb.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `regular verb`, Sense.verbRegular, Sense.noun, 1.0);

        learnMto1(Lang.en, rdT("../knowledge/en/determiner.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `determiner`, Sense.determiner, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/predeterminer.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `predeterminer`, Sense.predeterminer, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/adverbs.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `adverb`, Sense.adverb, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/preposition.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `preposition`, Sense.preposition, Sense.noun, 1.0);

        learnMto1(Lang.en, [`since`, `ago`, `before`, `past`], Role(Rel.isA), `time preposition`, Sense.prepositionTime, Sense.noun, 1.0);

        learnMobyPoS();

        // learn these after Moby as Moby is more specific
        learnNouns();
        learnVerbs();

        learnMto1(Lang.en, rdT("../knowledge/en/adjective.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `adjective`, Sense.adjective, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/adverb.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `adverb`, Sense.adverb, Sense.noun, 1.0);

        learnMto1(Lang.en, rdT("../knowledge/en/figure_of_speech.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `figure of speech`, Sense.unknown, Sense.noun, 1.0);

        learnMobyEnglishPronounciations();
    }

    /** Learn English Pronouncation Patterns from Moby.
        See also: https://en.wikipedia.org/wiki/Moby_Project#Hyphenator
     */
    void learnMobyEnglishPronounciations()
    {
        const path = "../knowledge/moby/pronounciation.txt";
        writeln("Reading Moby pronounciations from ", path, " ...");
        foreach (line; File(path).byLine)
        {
            auto split = line.splitter(' ');
            string expr;
            try
            {
                expr = split.front.replace(`_`, ` `).idup;
            }
            catch (core.exception.UnicodeException e)
            {
                expr = split.front.idup;
                dln("Couldn't decode expression ", expr);
            }
            split.popFront;
            string ipas;
            try
            {
                ipas = split.front
                            .splitter('_') // word separator
                            .map!(word =>
                                  word.splitter('/') // phoneme separator
                                      .map!(a => a.decodeMobyIPA)
                                      .joiner)
                            .joiner(` `)
                            .to!string;
            }
            catch (std.utf.UTFException e)
            {
                ipas = split.front.idup;
                dln("Couldn't decode IPA code ", ipas);
            }
            connect(store(expr, Lang.en, Sense.unknown, Origin.manual), Role(Rel.hasPronounciation),
                    store(ipas, Lang.ipa, Sense.unknown, Origin.manual), Origin.manual, 1.0);
        }
    }

    void learnMobyPoS()
    {
        const path = "../knowledge/moby/part_of_speech.txt";
        writeln("Reading Moby Part of Speech (PoS) from ", path, " ...");
        foreach (line; File(path).byLine)
        {
            auto split = line.splitter(roleSeparator);
            const expr = split.front.idup; split.popFront;
            foreach (sense; split.front.map!(a => a.decodeSenseOfMobyPoSCode))
            {
                store(expr, Lang.en, sense, Origin.moby);
            }
        }
    }

    void learnEnumMemberNameHierarchy(T)(Sense memberSense = Sense.unknown) if (is(T == enum))
    {
        const origin = Origin.manual;
        foreach (i; enumMembers!T)
        {
            foreach (j; enumMembers!T)
            {
                if (i != T.unknown &&
                    j != T.unknown &&
                    i != j)
                {
                    if (i.specializes(j))
                    {
                        connect(store(i.toHuman, Lang.en, memberSense, origin), Role(Rel.isA),
                                store(j.toHuman, Lang.en, memberSense, origin), origin, 1.0);
                    }
                }
            }
        }
    }

    void learnNouns()
    {
        const origin = Origin.manual;

        connect(store(`male`, Lang.en, Sense.noun, origin), Role(Rel.hasAttribute),
                store(`masculine`, Lang.en, Sense.adjective, origin), origin, 1.0);
        connect(store(`female`, Lang.en, Sense.noun, origin), Role(Rel.hasAttribute),
                store(`feminine`, Lang.en, Sense.adjective, origin), origin, 1.0);

        learnEnglishNouns();
        learnSwedishNouns();
    }

    void learnEnglishNouns()
    {
        learnMto1(Lang.en, rdT("../knowledge/en/collective_noun.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `collective noun`, Sense.nounCollective, Sense.noun, 1.0);
        learnMto1(Lang.en, rdT("../knowledge/en/noun.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `noun`, Sense.noun, Sense.noun, 1.0);
    }

    void learnSwedishNouns()
    {
        learnMto1(Lang.sv, rdT("../knowledge/sv/collective_noun.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `collective noun`, Sense.nounCollective, Sense.noun, 1.0);
    }

    void learnPronouns()
    {
        learnEnglishPronouns();
        learnSwedishPronouns();
    }

    void learnEnglishPronouns()
    {
        enum lang = Lang.en;

        // Singular
        learnMto1(lang, [`I`, `me`], Role(Rel.isA), `singular personal pronoun`, Sense.pronounPersonalSingular1st, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`you`], Role(Rel.isA), `singular personal pronoun`, Sense.pronounPersonalSingular2nd, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`it`], Role(Rel.isA), `singular personal pronoun`, Sense.pronounPersonalSingular, Sense.nounPhrase, 1.0);

        learnMto1(lang, [`he`], Role(Rel.isA), `1st-person male singular personal pronoun`, Sense.pronounPersonalSingularMale1st, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`him`], Role(Rel.isA), `2nd-person male singular personal pronoun`, Sense.pronounPersonalSingularMale2nd, Sense.nounPhrase, 1.0);

        learnMto1(lang, [`she`], Role(Rel.isA), `1st-person female singular personal pronoun`, Sense.pronounPersonalSingularFemale1st, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`her`], Role(Rel.isA), `2nd-person female singular personal pronoun`, Sense.pronounPersonalSingularFemale2nd, Sense.nounPhrase, 1.0);

        learnMto1(lang, [`we`, `us`], Role(Rel.isA), `1st-person plural personal pronoun`, Sense.pronounPersonalPlural1st, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`you`], Role(Rel.isA), `2nd-person plural personal pronoun`, Sense.pronounPersonalPlural2nd, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`they`, `they`], Role(Rel.isA), `3rd-person plural personal pronoun`, Sense.pronounPersonalPlural3rd, Sense.nounPhrase, 1.0);

        learnMto1(lang, [`this`, `that`], Role(Rel.isA), `singular demonstrative pronoun`, Sense.pronounDemonstrativeSingular, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`these`, `those`], Role(Rel.isA), `plural demonstrative pronoun`, Sense.pronounDemonstrativePlural, Sense.nounPhrase, 1.0);

        // Possessive
        learnMto1(lang, [`my`, `your`], Role(Rel.isA), `singular possessive adjective`, Sense.adjectivePossessiveSingular, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`our`, `their`], Role(Rel.isA), `plural possessive adjective`, Sense.adjectivePossessivePlural, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`mine`, `yours`], Role(Rel.isA), `singular possessive pronoun`, Sense.pronounPossessiveSingular, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`his`], Role(Rel.isA), `male singular possessive pronoun`, Sense.pronounPossessiveSingularMale, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`hers`], Role(Rel.isA), `female singular possessive pronoun`, Sense.pronounPossessiveSingularFemale, Sense.nounPhrase, 1.0);

        learnMto1(lang, [`ours`], Role(Rel.isA), `1st-person plural possessive pronoun`, Sense.pronounPossessivePlural1st, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`yours`], Role(Rel.isA), `2nd-person plural possessive pronoun`, Sense.pronounPossessivePlural2nd, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`theirs`], Role(Rel.isA), `3rd-person plural possessive pronoun`, Sense.pronounPossessivePlural3rd, Sense.nounPhrase, 1.0);

        learnMto1(lang, [`who`, `whom`, `what`, `which`, `whose`, `whoever`, `whatever`, `whichever`], Role(Rel.isA), `interrogative pronoun`, Sense.pronounInterrogative, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`myself`, `yourself`, `himself`, `herself`, `itself`], Role(Rel.isA), `singular reflexive pronoun`, Sense.pronounReflexiveSingular, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`ourselves`, `yourselves`, `themselves`], Role(Rel.isA), `plural reflexive pronoun`, Sense.pronounReflexivePlural, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`each other`, `one another`], Role(Rel.isA), `reciprocal pronoun`, Sense.pronounReciprocal, Sense.nounPhrase, 1.0);

        learnMto1(lang, [`who`, `whom`, // generally only for people
                               `whose`, // possession
                               `which`, // things
                               `that` // things and people
                            ], Role(Rel.isA), `relative pronoun`, Sense.pronounRelative, Sense.nounPhrase, 1.0);

        learnMto1(lang, [`all`, `any`, `more`, `most`, `none`, `some`, `such`], Role(Rel.isA), `indefinite pronoun`, Sense.pronounIndefinitePlural, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`another`, `anybody`, `anyone`, `anything`, `each`, `either`, `enough`,
                         `everybody`, `everyone`, `everything`, `less`, `little`, `much`, `neither`,
                         `nobody`, `noone`, `one`, `other`,
                         `somebody`, `someone`,
                         `something`, `you`], Role(Rel.isA), `singular indefinite pronoun`, Sense.pronounIndefiniteSingular, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`both`, `few`, `fewer`, `many`, `others`, `several`, `they`], Role(Rel.isA), `plural indefinite pronoun`, Sense.pronounIndefinitePlural, Sense.nounPhrase, 1.0);

        // Rest
        learnMto1(lang, rdT("../knowledge/en/pronoun.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `pronoun`, Sense.pronoun, Sense.nounSingular, 1.0); // TODO Remove?
    }

    void learnSwedishPronouns()
    {
        enum lang = Lang.sv;

        // Personal
        learnMto1(lang, [`jag`, `mig`], Role(Rel.isA), `1st-person singular personal pronoun`, Sense.pronounPersonalSingular1st, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`du`, `dig`], Role(Rel.isA), `2nd-person singular personal pronoun`, Sense.pronounPersonalSingular2nd, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`den`, `det`], Role(Rel.isA), `3rd-person singular personal pronoun`, Sense.pronounPersonalSingular3rd, Sense.nounPhrase, 1.0);

        learnMto1(lang, [`han`], Role(Rel.isA), `1st-person male singular personal pronoun`, Sense.pronounPersonalSingularMale1st, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`honom`], Role(Rel.isA), `2nd-person male singular personal pronoun`, Sense.pronounPersonalSingularMale2nd, Sense.nounPhrase, 1.0);

        learnMto1(lang, [`hon`], Role(Rel.isA), `1st-person female singular personal pronoun`, Sense.pronounPersonalSingularFemale1st, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`henne`], Role(Rel.isA), `2nd-person female singular personal pronoun`, Sense.pronounPersonalSingularFemale2nd, Sense.nounPhrase, 1.0);

        learnMto1(lang, [`hen`], Role(Rel.isA), `androgyn singular personal pronoun`, Sense.pronounPersonalSingular, Sense.nounPhrase, 1.0);

        learnMto1(lang, [`vi`, `oss`], Role(Rel.isA), `1st-person plural personal pronoun`, Sense.pronounPersonalPlural1st, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`ni`], Role(Rel.isA), `2nd-person plural personal pronoun`, Sense.pronounPersonalPlural2nd, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`de`, `dem`], Role(Rel.isA), `3rd-person plural personal pronoun`, Sense.pronounPersonalPlural3rd, Sense.nounPhrase, 1.0);

        // Possessive
        learnMto1(lang, [`min`], Role(Rel.isA), `1st-person singular possessive adjective`, Sense.pronounPossessiveSingular1st, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`din`], Role(Rel.isA), `2nd-person possessive adjective`, Sense.pronounPossessiveSingular2nd, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`hans`], Role(Rel.isA), `male singular possessive pronoun`, Sense.pronounPossessiveSingularMale, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`hennes`], Role(Rel.isA), `female singular possessive pronoun`, Sense.pronounPossessiveSingularFemale, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`hens`], Role(Rel.isA), `singular possessive pronoun`, Sense.pronounPossessiveSingular, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`dens`, `dets`], Role(Rel.isA), `singular possessive pronoun`, Sense.pronounPossessiveSingularNeutral, Sense.nounPhrase, 1.0);

        learnMto1(lang, [`vår`], Role(Rel.isA), `1st-person plural possessive pronoun`, Sense.pronounPossessivePlural1st, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`er`], Role(Rel.isA), `2nd-person plural possessive pronoun`, Sense.pronounPossessivePlural2nd, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`deras`], Role(Rel.isA), `3rd-person plural possessive pronoun`, Sense.pronounPossessivePlural3rd, Sense.nounPhrase, 1.0);

        // Demonstrative
        learnMto1(lang, [`den här`, `den där`], Role(Rel.isA), `singular demonstrative pronoun`, Sense.pronounDemonstrativeSingular, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`de här`, `de där`], Role(Rel.isA), `plural demonstrative pronoun`, Sense.pronounDemonstrativePlural, Sense.nounPhrase, 1.0);

        learnMto1(lang, [`den`, `det`], Role(Rel.isA),
                        `singular determinative pronoun`,
                        Sense.pronounDeterminativeSingular, Sense.nounPhrase, 1.0);

        learnMto1(lang, [`de`, `dem`], Role(Rel.isA),
                        `singular determinative pronoun`,
                        Sense.pronounDeterminativePlural, Sense.nounPhrase, 1.0);

        learnMto1(lang, [`en sådan`], Role(Rel.isA),
                        `singular determinative pronoun`,
                        Sense.pronounDeterminativeSingular, Sense.nounPhrase, 1.0);

        learnMto1(lang, [`sådant`, `sådana`], Role(Rel.isA),
                        `singular determinative pronoun`,
                        Sense.pronounDeterminativePlural, Sense.nounPhrase, 1.0);

        // Other
        learnMto1(lang, [`vem`, `som`, `vad`, `vilken`, `vems`], Role(Rel.isA), `interrogative pronoun`, Sense.pronounInterrogative, Sense.nounPhrase, 1.0);
        learnMto1(lang, [`mig själv`, `dig själv`, `han själv`, `henne själv`, `hen själv`, `den själv`, `det själv`], Role(Rel.isA), `singular reflexive pronoun`, Sense.pronounReflexiveSingular, Sense.nounPhrase, 1.0); // TODO person
        learnMto1(lang, [`oss själva`, `er själva`, `dem själva`], Role(Rel.isA), `plural reflexive pronoun`, Sense.pronounReflexivePlural, Sense.nounPhrase, 1.0); // TODO person
        learnMto1(lang, [`varandra`], Role(Rel.isA), `reciprocal pronoun`, Sense.pronounReciprocal, Sense.nounPhrase, 1.0);
    }

    void learnVerbs()
    {
        learnSwedishIrregularVerbs();
        learnEnglishVerbs();
    }

    void learnAdjectives()
    {
        learnSwedishAdjectives();
        learnEnglishAdjectives();
    }

    void learnEnglishVerbs()
    {
        learnEnglishIrregularVerbs();
        learnMto1(Lang.en, rdT("../knowledge/en/verbs.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `verb`, Sense.verb, Sense.noun, 1.0);
    }

    void learnAdverbs()
    {
        learnEnglishAdverbs();
        learnSwedishAdverbs();
    }

    void learnSwedishAdverbs()
    {
        enum lang = Lang.sv;

        learnMto1(lang,
                        [`i går`, `i dag,`, `i morgon`,
                         `i kväll`, `i natt`,
                         `i går kväll`, `i går natt`, `i går morgon`
                         `nästa dag`, `nästnästa dag`
                         `nästa vecka`, `nästnästa vecka`
                         `nästa månad`, `nästnästa månad`
                         `nästa år`, `nästnästa år`
                         `nu`, `omedelbart`
                         `sedan`, `senare`, `nyligen`, `just nu`, `på sistone`, `snart`,
                         `redan`, `fortfarande`, `ännu`, `förr`, `förut`],
                        Role(Rel.isA), `time adverb`, Sense.timeAdverb, Sense.nounPhrase, 1.0);

        learnMto1(lang,
                        [`här`, `där`, `där borta`, `överallt`, `var som helst`,
                         `ingenstans`, `hem`, `bort`, `ut`],
                        Role(Rel.isA), `place adverb`, Sense.placeAdverb, Sense.nounPhrase, 1.0);

        learnMto1(lang,
                        [`alltid`, `ofta`, `vanligen`, `ibland`, `emellanåt`, `sällan`, `aldrig`],
                        Role(Rel.isA), `frequency adverb`, Sense.frequencyAdverb, Sense.nounPhrase, 1.0);

        learnMto1(lang,
                        [`ja`, `japp`, `överallt`, `alltid`],
                        Role(Rel.isA), `affirming adverb`, Sense.affirmingAdverb, Sense.nounPhrase, 1.0);

        learnMto1(lang,
                        [`ej`, `inte`, `icke`],
                        Role(Rel.isA), `negating adverb`, Sense.negatingAdverb, Sense.nounPhrase, 1.0);

        learnMto1(Lang.sv,
                        [`emellertid`, `däremot`, `dock`, `likväl`, `ändå`,
                         `trots det`, `trots detta`],
                        Role(Rel.isA), `adverb`, Sense.adverb, Sense.nounPhrase, 1.0);
    }

    void learnEnglishAdverbs()
    {
        enum lang = Lang.en;

        learnMto1(lang,
                        [`yesterday`, `today`, `tomorrow`, `tonight`, `last night`, `this morning`,
                         `previous week`, `next week`,
                         `previous year`, `next year`,
                         `now`, `then`, `later`, `right now`, `already`,
                         `recently`, `lately`, `soon`, `immediately`,
                         `still`, `yet`, `ago`],
                        Role(Rel.isA), `time adverb`, Sense.timeAdverb, Sense.nounPhrase, 1.0);

        learnMto1(lang,
                        [`here`, `there`, `over there`, `out there`, `in there`,
                         `everywhere`, `anywhere`, `nowhere`, `home`, `away`, `out`],
                        Role(Rel.isA), `place adverb`, Sense.placeAdverb, Sense.nounPhrase, 1.0);

        learnMto1(lang,
                        [`always`, `frequently`, `usually`, `sometimes`, `occasionally`, `seldom`,
                         `rarely`, `never`],
                        Role(Rel.isA), `frequency adverb`, Sense.frequencyAdverb, Sense.nounPhrase, 1.0);

        learnMto1(lang,
                        [`accordingly`, `additionally`, `again`, `almost`,
                         `although`, `anyway`, `as a result`, `besides`,
                         `certainly`, `comparatively`, `consequently`,
                         `contrarily`, `conversely`, `elsewhere`, `equally`,
                         `eventually`, `finally`, `further`, `furthermore`,
                         `hence`, `henceforth`, `however`, `in addition`,
                         `in comparison`, `in contrast`, `in fact`, `incidentally`,
                         `indeed`, `instead`, `just as`, `likewise`,
                         `meanwhile`, `moreover`, `namely`, `nevertheless`,
                         `next`, `nonetheless`, `notably`, `now`, `otherwise`,
                         `rather`, `similarly`, `still`, `subsequently`, `that is`,
                         `then`, `thereafter`, `therefore`, `thus`,
                         `undoubtedly`, `uniquely`, `on the other hand`, `also`,
                         `for example`, `for instance`, `of course`, `on the contrary`,
                         `so far`, `until now`, `thus` ],
                        Role(Rel.isA), `conjunctive adverb`,
                        Sense.conjunctiveAdverb, Sense.nounPhrase, 1.0);

        learnMto1(lang,
                        [`no`, `not`, `never`, `nowhere`, `none`, `nothing`],
                        Role(Rel.isA), `negating adverb`, Sense.negatingAdverb, Sense.nounPhrase, 1.0);

        learnMto1(lang,
                        [`yes`, `yeah`],
                        Role(Rel.isA), `affirming adverb`, Sense.affirmingAdverb, Sense.nounPhrase, 1.0);
    }

    void learnDefiniteArticles()
    {
        learnMto1(Lang.en, [`the`],
                        Role(Rel.isA), `definite article`, Sense.articleDefinite, Sense.nounPhrase, 1.0);
        learnMto1(Lang.de, [`der`, `die`, `das`, `des`, `dem`, `den`],
                        Role(Rel.isA), `definite article`, Sense.articleDefinite, Sense.nounPhrase, 1.0);
        learnMto1(Lang.fr, [`le`, `la`, `l'`, `les`],
                        Role(Rel.isA), `definite article`, Sense.articleDefinite, Sense.nounPhrase, 1.0);
        learnMto1(Lang.sv, [`den`, `det`],
                        Role(Rel.isA), `definite article`, Sense.articleDefinite, Sense.nounPhrase, 1.0);
    }

    void learnUndefiniteArticles()
    {
        learnMto1(Lang.en, [`a`, `an`],
                        Role(Rel.isA), `undefinite article`, Sense.articleIndefinite, Sense.nounPhrase, 1.0);
        learnMto1(Lang.de, [`ein`, `eine`, `eines`, `einem`, `einen`, `einer`],
                        Role(Rel.isA), `undefinite article`, Sense.articleIndefinite, Sense.nounPhrase, 1.0);
        learnMto1(Lang.fr, [`un`, `une`, `des`],
                        Role(Rel.isA), `undefinite article`, Sense.articleIndefinite, Sense.nounPhrase, 1.0);
        learnMto1(Lang.sv, [`en`, `ena`, `ett`],
                        Role(Rel.isA), `undefinite article`, Sense.articleIndefinite, Sense.nounPhrase, 1.0);
    }

    void learnPartitiveArticles()
    {
        learnMto1(Lang.en, [`some`],
                        Role(Rel.isA), `partitive article`, Sense.articlePartitive, Sense.nounPhrase, 1.0);
        learnMto1(Lang.fr, [`du`, `de`, `la`, `de`, `l'`, `des`],
                        Role(Rel.isA), `partitive article`, Sense.articlePartitive, Sense.nounPhrase, 1.0);
    }

    void learnNames()
    {
        // Surnames
        learnMto1(Lang.en, rdT("../knowledge/en/surname.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `surname`, Sense.surname, Sense.nounSingular, 1.0);
        learnMto1(Lang.sv, rdT("../knowledge/sv/surname.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `surname`, Sense.surname, Sense.nounSingular, 1.0);
    }

    void learnConjunctions()
    {
        // TODO merge with conjunctions?
        // TODO categorize like http://www.grammarbank.com/connectives-list.html
        enum connectives = [`the`, `of`, `and`, `to`, `a`, `in`, `that`, `is`,
                            `was`, `he`, `for`, `it`, `with`, `as`, `his`,
                            `on`, `be`, `at`, `by`, `i`, `this`, `had`, `not`,
                            `are`, `but`, `from`, `or`, `have`, `an`, `they`,
                            `which`, `one`, `you`, `were`, `her`, `all`, `she`,
                            `there`, `would`, `their`, `we him`, `been`, `has`,
                            `when`, `who`, `will`, `more`, `no`, `if`, `out`,
                            `so`, `said`, `what`, `up`, `its`, `about`, `into`,
                            `than them`, `can`, `only`, `other`, `new`, `some`,
                            `could`, `time`, `these`, `two`, `may`, `then`,
                            `do`, `first`, `any`, `my`, `now`, `such`, `like`,
                            `our`, `over`, `man`, `me`, `even`, `most`, `made`,
                            `after`, `also`, `did`, `many`, `before`, `must`,
                            `through back`, `years`, `where`, `much`, `your`,
                            `way`, `well`, `down`, `should`, `because`, `each`,
                            `just`, `those`, `people mr`, `how`, `too`,
                            `little`, `state`, `good`, `very`, `make`, `world`,
                            `still`, `own`, `see`, `men`, `work`, `long`, `get`,
                            `here`, `between`, `both`, `life`, `being`, `under`,
                            `never`, `day`, `same`, `another`, `know`, `while`,
                            `last`, `might us`, `great`, `old`, `year`, `off`,
                            `come`, `since`, `against`, `go`, `came`, `right`,
                            `used`, `take`, `three`];

        // Coordinating Conjunction
        connect(store("coordinating conjunction", Lang.en, Sense.nounPhrase, Origin.manual),
                Role(Rel.uses),
                store("connect independent sentence parts", Lang.en, Sense.unknown, Origin.manual),
                Origin.manual, 1.0);
        learnMto1(Lang.en, [`and`, `or`, `but`, `nor`, `so`, `for`, `yet`],
                  Role(Rel.isA), `coordinating conjunction`, Sense.conjunctionCoordinating, Sense.nounPhrase, 1.0);
        learnMto1(Lang.sv, [`och`, `eller`, `men`, `så`, `för`, `ännu`],
                  Role(Rel.isA), `coordinating conjunction`, Sense.conjunctionCoordinating, Sense.nounPhrase, 1.0);
        learnMto1(Lang.en, [`that`],
                  Role(Rel.isA), `coordinating conjunction`, Sense.conjunctionSubordinating, Sense.nounPhrase, 1.0);
        learnMto1(Lang.en, [`though`, `although`, `eventhough`, `even though`, `while`],
                  Role(Rel.isA), `coordinating concession conjunction`, Sense.conjunctionSubordinatingConcession, Sense.nounPhrase, 1.0);
        learnMto1(Lang.en, [`if`, `only if`, `unless`, `until`, `provided that`, `assuming that`, `even if`, `in case`, `in case that`, `lest`],
                  Role(Rel.isA), `coordinating condition conjunction`, Sense.conjunctionSubordinatingCondition, Sense.nounPhrase, 1.0);
        learnMto1(Lang.en, [`than`, `rather than`, `whether`, `as much as`, `whereas`],
                  Role(Rel.isA), `coordinating comparison conjunction`, Sense.conjunctionSubordinatingComparison, Sense.nounPhrase, 1.0);
        learnMto1(Lang.en, [`after`, `as long as`, `as soon as`, `before`, `by the time`, `now that`, `once`, `since`, `till`, `until`, `when`, `whenever`, `while`],
                  Role(Rel.isA), `coordinating time conjunction`, Sense.conjunctionSubordinatingTime, Sense.nounPhrase, 1.0);
        learnMto1(Lang.en, [`because`, `since`, `so that`, `in order`, `in order that`, `why`],
                  Role(Rel.isA), `coordinating reason conjunction`, Sense.conjunctionSubordinatingReason, Sense.nounPhrase, 1.0);
        learnMto1(Lang.en, [`how`, `as though`, `as if`],
                  Role(Rel.isA), `coordinating manner conjunction`, Sense.conjunctionSubordinatingManner, Sense.nounPhrase, 1.0);
        learnMto1(Lang.en, [`where`, `wherever`],
                  Role(Rel.isA), `coordinating place conjunction`, Sense.conjunctionSubordinatingPlace, Sense.nounPhrase, 1.0);
        learnMto1(Lang.en, [`as {*} as`,
                            `just as {*} so`,
                            `both {*} and`,
                            `hardly {*} when`,
                            `scarcely {*} when`,
                            `either {*} or`,
                            `neither {*} nor`,
                            `if {*} then`,
                            `not {*} but`,
                            `what with {*} and`,
                            `whether {*} or`,
                            `not only {*} but also`,
                            `no sooner {*} than`,
                            `rather {*} than`],
                        Role(Rel.isA), `correlative conjunction`, Sense.conjunctionCorrelative, Sense.nounPhrase, 1.0);

        // Subordinating Conjunction
        connect(store("subordinating conjunction", Lang.en, Sense.nounPhrase, Origin.manual),
                Role(Rel.uses),
                store("establish the relationship between the dependent clause and the rest of the sentence",
                      Lang.en, Sense.unknown, Origin.manual),
                Origin.manual, 1.0);

        // Conjunction
        learnMto1(Lang.en, rdT("../knowledge/en/conjunction.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `conjunction`, Sense.conjunction, Sense.nounSingular, 1.0);

        enum swedishConjunctions = [`alldenstund`, `allenast`, `ante`, `antingen`, `att`, `bara`, `blott`, `bå`, `båd'`, `både`, `dock`, `att`, `där`, `därest`, `därför`, `att`, `då`, `eftersom`, `ehur`, `ehuru`, `eller`, `emedan`, `enär`, `ety`, `evad`, `fast`, `fastän`, `för`, `förrän`, `försåvida`, `försåvitt`, `fȧst`, `huruvida`, `hvarför`, `hvarken`, `hvarpå`, `ifall`, `innan`, `ity`, `ity`, `att`, `liksom`, `medan`, `medans`, `men`, `mens`, `när`, `närhelst`, `oaktat`, `och`, `om`, `om`, `och`, `endast`, `om`, `plus`, `att`, `samt`, `sedan`, `som`, `sä`, `så`, `såframt`, `såsom`, `såvida`, `såvitt`, `såväl`, `sö`, `tast`, `tills`, `ty`, `utan`, `varför`, `varken`, `än`, `ändock`, `änskönt`, `ävensom`, `å`];
        learnMto1(Lang.sv, swedishConjunctions, Role(Rel.isA), `conjunction`, Sense.conjunction, Sense.nounSingular, 1.0);
    }

    void learnInterjections()
    {
        learnMto1(Lang.en,
                        rdT("../knowledge/en/interjection.txt").splitter('\n').filter!(word => !word.empty),
                        Role(Rel.isA), `interjection`, Sense.interjection, Sense.nounSingular, 1.0);
    }

    void learnTime()
    {
        learnMto1(Lang.en, [`monday`, `tuesday`, `wednesday`, `thursday`, `friday`, `saturday`, `sunday`],    Role(Rel.isA), `weekday`, Sense.weekday, Sense.nounSingular, 1.0);
        learnMto1(Lang.de, [`montag`, `dienstag`, `mittwoch`, `donnerstag`, `freitag`, `samstag`, `sonntag`], Role(Rel.isA), `weekday`, Sense.weekday, Sense.nounSingular, 1.0);
        learnMto1(Lang.sv, [`montag`, `dienstag`, `mittwoch`, `donnerstag`, `freitag`, `samstag`, `sonntag`], Role(Rel.isA), `weekday`, Sense.weekday, Sense.nounSingular, 1.0);

        learnMto1(Lang.en, [`january`, `february`, `mars`, `april`, `may`, `june`, `july`, `august`, `september`, `oktober`, `november`, `december`], Role(Rel.isA), `month`, Sense.month, Sense.nounSingular, 1.0);
        learnMto1(Lang.sv, [`januari`, `februari`, `mars`, `april`, `maj`, `juni`, `juli`, `augusti`, `september`, `oktober`, `november`, `december`],    Role(Rel.isA), `month`, Sense.month, Sense.nounSingular, 1.0);

        learnMto1(Lang.en, [`time period`], Role(Rel.isA), `noun`, Sense.noun, Sense.nounSingular, 1.0);
        learnMto1(Lang.en, [`month`], Role(Rel.isA), `time period`, Sense.noun, Sense.nounSingular, 1.0);
    }

    /// Learn Assocative Things.
    void learnAssociativeThings()
    {
        // TODO lower weights on these are not absolute
        learnMto1(Lang.en, rdT("../knowledge/en/constitution.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.any), `constitution`, Sense.unknown, Sense.nounSingular);
        learnMto1(Lang.en, rdT("../knowledge/en/election.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.any), `election`, Sense.unknown, Sense.nounSingular);
        learnMto1(Lang.en, rdT("../knowledge/en/weather.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.any), `weather`, Sense.noun, Sense.nounSingular);
        learnMto1(Lang.en, rdT("../knowledge/en/dentist.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.any), `dentist`, Sense.unknown, Sense.nounSingular);
        learnMto1(Lang.en, rdT("../knowledge/en/firefighting.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.any), `fire fighting`, Sense.unknown, Sense.nounSingular);
        learnMto1(Lang.en, rdT("../knowledge/en/driving.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.any), `drive`, Sense.unknown, Sense.verb);
        learnMto1(Lang.en, rdT("../knowledge/en/art.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.any), `art`, Sense.unknown, Sense.nounSingular);
        learnMto1(Lang.en, rdT("../knowledge/en/astronomy.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.any), `astronomy`, Sense.unknown, Sense.nounSingular);

        learnMto1(Lang.en, rdT("../knowledge/en/vacation.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.any), `vacation`, Sense.unknown, Sense.nounSingular);

        learnMto1(Lang.en, rdT("../knowledge/en/autumn.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.any), `autumn`, Sense.unknown, Sense.season);
        learnMto1(Lang.en, rdT("../knowledge/en/winter.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.any), `winter`, Sense.unknown, Sense.season);
        learnMto1(Lang.en, rdT("../knowledge/en/spring.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.any), `spring`, Sense.unknown, Sense.season);

        learnMto1(Lang.en, rdT("../knowledge/en/summer_noun.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.atTime), `summer`, Sense.noun, Sense.season);
        learnMto1(Lang.en, rdT("../knowledge/en/summer_adjective.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.atTime), `summer`, Sense.adjective, Sense.season);
        learnMto1(Lang.en, rdT("../knowledge/en/summer_verb.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.atTime), `summer`, Sense.verb, Sense.season);

        learnMto1(Lang.en, rdT("../knowledge/en/household_device.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.atLocation), `house`, Sense.noun, Sense.nounSingular);
        learnMto1(Lang.en, rdT("../knowledge/en/household_device.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `device`, Sense.noun, Sense.nounSingular);
        learnMto1(Lang.en, rdT("../knowledge/en/farm.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.atLocation), `farm`, Sense.noun, Sense.nounSingular);
        learnMto1(Lang.en, rdT("../knowledge/en/school.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.atLocation), `school`, Sense.noun, Sense.nounSingular);
        learnMto1(Lang.en, rdT("../knowledge/en/circus.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.atLocation), `circus`, Sense.noun, Sense.nounSingular);
        learnMto1(Lang.en, rdT("../knowledge/en/near_yard.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.atLocation), `yard`, Sense.noun, Sense.nounSingular);
        learnMto1(Lang.en, rdT("../knowledge/en/restaurant.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.atLocation), `restaurant`, Sense.noun, Sense.nounSingular);

        learnMto1(Lang.en, rdT("../knowledge/en/bathroom.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.atLocation), `bathroom`, Sense.noun, Sense.nounSingular);
        learnMto1(Lang.en, rdT("../knowledge/en/house.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.atLocation), `house`, Sense.noun, Sense.nounSingular);
        learnMto1(Lang.en, rdT("../knowledge/en/kitchen.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.atLocation), `kitchen`, Sense.noun, Sense.nounSingular);

        learnMto1(Lang.en, rdT("../knowledge/en/beach.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.atLocation), `beach`, Sense.noun, Sense.nounSingular);
        learnMto1(Lang.en, rdT("../knowledge/en/ocean.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.atLocation), `ocean`, Sense.noun, Sense.nounSingular);

        learnMto1(Lang.en, rdT("../knowledge/en/happy.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.similarTo), `happy`, Sense.adjective, Sense.adjective);
        learnMto1(Lang.en, rdT("../knowledge/en/big.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.similarTo), `big`, Sense.adjective, Sense.adjective);
        learnMto1(Lang.en, rdT("../knowledge/en/many.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.similarTo), `many`, Sense.adjective, Sense.adjective);
        learnMto1(Lang.en, rdT("../knowledge/en/easily_upset.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.similarTo), `easily upset`, Sense.adjective, Sense.adjective);

        learnMto1(Lang.en, rdT("../knowledge/en/roadway.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.any), `roadway`, Sense.noun, Sense.nounSingular);
        learnMto1(Lang.en, rdT("../knowledge/en/baseball.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.any), `baseball`, Sense.noun, Sense.nounSingular);
        learnMto1(Lang.en, rdT("../knowledge/en/boat.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.any), `boat`, Sense.noun, Sense.nounSingular);
        learnMto1(Lang.en, rdT("../knowledge/en/money.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.any), `money`, Sense.noun, Sense.nounUncountable);
        learnMto1(Lang.en, rdT("../knowledge/en/family.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.any), `family`, Sense.noun, Sense.nounCollective);
        learnMto1(Lang.en, rdT("../knowledge/en/geography.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.any), `geography`, Sense.unknown, Sense.nounUncountable);
        learnMto1(Lang.en, rdT("../knowledge/en/energy.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.any), `energy`, Sense.unknown, Sense.nounUncountable);
        learnMto1(Lang.en, rdT("../knowledge/en/time.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.any), `time`, Sense.unknown, Sense.nounUncountable);
        learnMto1(Lang.en, rdT("../knowledge/en/water.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.any), `water`, Sense.unknown, Sense.nounUncountable);
        learnMto1(Lang.en, rdT("../knowledge/en/clothing.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.any), `clothing`, Sense.unknown, Sense.nounUncountable);
        learnMto1(Lang.en, rdT("../knowledge/en/music_theory.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.any), `music theory`, Sense.unknown, Sense.nounSingular);
        learnMto1(Lang.en, rdT("../knowledge/en/happiness.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.any), `happiness`, Sense.unknown, Sense.nounUncountable);
        learnMto1(Lang.en, rdT("../knowledge/en/pirate.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.any), `pirate`, Sense.unknown, Sense.nounSingular);
        learnMto1(Lang.en, rdT("../knowledge/en/monster.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.any), `monster`, Sense.unknown, Sense.nounSingular);

        learnMto1(Lang.en, rdT("../knowledge/en/halloween.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.any), `halloween`, Sense.unknown, Sense.nounUncountable);
        learnMto1(Lang.en, rdT("../knowledge/en/christmas.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.any), `christmas`, Sense.unknown, Sense.nounUncountable);
        learnMto1(Lang.en, rdT("../knowledge/en/thanksgiving.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.any), `thanksgiving`, Sense.unknown, Sense.nounUncountable);
        learnMto1(Lang.en, rdT("../knowledge/en/camp.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.any), `camping`, Sense.unknown, Sense.nounUncountable);
        learnMto1(Lang.en, rdT("../knowledge/en/cooking.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.any), `cooking`, Sense.unknown, Sense.nounUncountable);
        learnMto1(Lang.en, rdT("../knowledge/en/sewing.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.any), `sewing`, Sense.unknown, Sense.nounUncountable);
        learnMto1(Lang.en, rdT("../knowledge/en/military.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.any), `military`, Sense.unknown, Sense.nounUncountable);
        learnMto1(Lang.en, rdT("../knowledge/en/science.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.any), `science`, Sense.unknown, Sense.nounUncountable);
        learnMto1(Lang.en, rdT("../knowledge/en/computer.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.any), `computing`, Sense.unknown, Sense.nounUncountable);
        learnMto1(Lang.en, rdT("../knowledge/en/math.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.any), `math`, Sense.unknown, Sense.nounUncountable);

        learnMto1(Lang.en, rdT("../knowledge/en/transport.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.any), `transportation`, Sense.unknown, Sense.nounUncountable);

        learnMto1(Lang.en, rdT("../knowledge/en/rock.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.any), `rock`, Sense.unknown, Sense.nounUncountable);
        learnMto1(Lang.en, rdT("../knowledge/en/doctor.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.any), `doctor`, Sense.unknown, Sense.nounSingular);
        learnMto1(Lang.en, rdT("../knowledge/en/st-patricks-day.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.any), `St. Patrick's Day`, Sense.unknown, Sense.nounUncountable);
        learnMto1(Lang.en, rdT("../knowledge/en/new-years-eve.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.any), `New Year's Eve`, Sense.unknown, Sense.nounUncountable);

        learnMto1(Lang.en, rdT("../knowledge/en/say.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `say`, Sense.verb, Sense.verbIrregularInfinitive);
        learnMto1(Lang.en, rdT("../knowledge/en/book_property.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.hasProperty, true), `book`, Sense.adjective, Sense.nounSingular);
        learnMto1(Lang.en, rdT("../knowledge/en/informal.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.hasAttribute), `informal`, Sense.adjective, Sense.adjective);

        // Red Wine
        learnMto1(Lang.en, rdT("../knowledge/en/red_wine_color.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `red wine color`, Sense.noun, Sense.nounSingular);
        learnMto1(Lang.en, rdT("../knowledge/en/red_wine_flavor.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `red wine flavor`, Sense.noun, Sense.nounSingular);
        learnMto1(Lang.en, rdT("../knowledge/en/red_wine_food.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.servedWith), `red wine`, Sense.noun, Sense.nounSingular);

        learnMto1(Lang.en, rdT("../knowledge/en/literary_genre.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `literary genre`, Sense.noun, Sense.nounSingular);
        learnMto1(Lang.en, rdT("../knowledge/en/major_literary_form.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `major literary form`, Sense.noun, Sense.nounSingular);
        learnMto1(Lang.en, rdT("../knowledge/en/classic_major_literary_genre.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `classic major literary genre`, Sense.noun, Sense.nounSingular);

        // Female Names
        learnMto1(Lang.en, rdT("../knowledge/en/female_name.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `female name`, Sense.nameFemale, Sense.nounSingular, 1.0);
        learnMto1(Lang.sv, rdT("../knowledge/sv/female_name.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `female name`, Sense.nameFemale, Sense.nounSingular, 1.0);
    }

    /// Learn Emotions.
    void learnEmotions()
    {
        const groups = [`basic`, `positive`, `negative`, `strong`, `medium`, `light`];
        foreach (group; groups)
        {
            learnMto1(Lang.en,
                      rdT("../knowledge/en/" ~ group ~ "_emotion.txt").splitter('\n').filter!(word => !word.empty),
                      Role(Rel.isA), group ~ ` emotion`, Sense.unknown, Sense.nounSingular);
        }
    }

    /// Learn English Feelings.
    void learnEnglishFeelings()
    {
        learnMto1(Lang.en, rdT("../knowledge/en/feeling.txt").splitter('\n').filter!(word => !word.empty), Role(Rel.isA), `feeling`, Sense.adjective, Sense.nounSingular);
        const feelings = [`afraid`, `alive`, `angry`, `confused`, `depressed`, `good`, `happy`,
                          `helpless`, `hurt`, `indifferent`, `interested`, `love`,
                          `negative`, `unpleasant`,
                          `positive`, `pleasant`,
                          `open`, `sad`, `strong`];
        foreach (feeling; feelings)
        {
            const path = "../knowledge/en/" ~ feeling ~ "_feeling.txt";
            learnAssociations(path, Rel.similarTo, feeling.replace(`_`, ` `) ~ ` feeling`, Sense.adjective, Sense.adjective);
        }
    }

    /// Learn Swedish Feelings.
    void learnSwedishFeelings()
    {
        learnMto1(Lang.sv,
                  rdT("../knowledge/sv/känsla.txt").splitter('\n').filter!(word => !word.empty),
                  Role(Rel.isA), `känsla`, Sense.noun, Sense.nounSingular);
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
        foreach (expr; File(path).byLine.filter!(a => !a.empty))
        {
            auto split = expr.findSplit([countSeparator]); // TODO allow key to be ElementType of Range to prevent array creation here
            const name = split[0], count = split[2];

            if (expr == "ack#2")
            {
                dln(name, ", ", count);
            }

            NWeight nweight = 1.0;
            if (!count.empty)
            {
                const w = count.to!NWeight;
                nweight = w/(1 + w); // count to normalized weight
            }

            connect(store(name.idup, lang, wordSense, origin),
                    Role(rel),
                    store(attribute, lang, attributeSense, origin),
                    origin, nweight);
        }
    }

    /// Learn Chemical Elements.
    void learnChemicalElements(Lang lang = Lang.en, Origin origin = Origin.manual)
    {
        foreach (expr; File("../knowledge/en/chemical_elements.txt").byLine.filter!(a => !a.empty))
        {
            auto split = expr.findSplit([roleSeparator]); // TODO allow key to be ElementType of Range to prevent array creation here
            const name = split[0], sym = split[2];
            NWeight weight = 1.0;

            connect(store(name.idup, lang, Sense.nounUncountable, origin),
                    Role(Rel.isA),
                    store("chemical element", lang, Sense.nounSingular, origin),
                    origin, weight);

            connect(store(sym.idup, lang, Sense.noun, origin),
                    Role(Rel.symbolFor),
                    store(name.idup, lang, Sense.noun, origin),
                    origin, weight);
        }
    }

    void learnMtoNMaybe(string path,
                        Sense firstSense, Lang firstLang,
                        Role role,
                        Sense secondSense, Lang secondLang,
                        Origin origin = Origin.manual,
                        NWeight weight = 0.5)
    {
        try
        {
            foreach (expr; File(path).byLine.filter!(a => !a.empty))
            {
                auto split = expr.findSplit([roleSeparator]); // TODO allow key to be ElementType of Range to prevent array creation here
                const first = split[0], second = split[2];

                auto firstRefs = store(first.splitter(alternativesSeparator).map!idup, firstLang, firstSense, origin);

                if (!second.empty)
                {
                    auto secondRefs = store(second.splitter(alternativesSeparator).map!idup, secondLang, secondSense, origin);
                    connectMtoN(firstRefs, role, secondRefs, origin, weight, true);
                }
            }
        }
        catch (std.exception.ErrnoException e) { /* OK: If file doesn't exist */ }
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
        foreach (expr; File("../knowledge/en/opposites.txt").byLine.filter!(a => !a.empty))
        {
            auto split = expr.findSplit([roleSeparator]); // TODO allow key to be ElementType of Range to prevent array creation here
            const auto first = split[0], second = split[2];
            NWeight weight = 1.0;
            const sense = commonSense(first, second);
            connect(store(first.idup, lang, sense, origin),
                    Role(Rel.oppositeOf),
                    store(second.idup, lang, sense, origin),
                    origin, weight);
        }
    }

    /// Learn Verb Reversions.
    void learnVerbReversions()
    {
        // TODO Copy all from krels.toHuman
        learnVerbReversion(`is a`, `can be`, Lang.en);
        learnVerbReversion(`leads to`, `can infer`, Lang.en);
        learnVerbReversion(`is part of`, `contains`, Lang.en);
        learnVerbReversion(`is member of`, `has member`, Lang.en);
    }

    /// Learn Verb Reversion.
    Ln[] learnVerbReversion(S)(S forward,
                                    S backward,
                                    Lang lang = Lang.unknown) if (isSomeString!S)
    {
        const origin = Origin.manual;
        auto all = [store(forward, lang, Sense.verbInfinitive, origin),
                    store(backward, lang, Sense.verbPastParticiple, origin)];
        return connectAll(Role(Rel.reversionOf), all.filter!(a => a.defined), lang, origin);
    }

    /// Learn Etymologically Derived Froms.
    void learnEtymologicallyDerivedFroms()
    {
        learnEtymologicallyDerivedFrom(`holiday`, Lang.en, Sense.noun,
                                       `holy day`, Lang.en, Sense.noun);
        learnEtymologicallyDerivedFrom(`juletide`, Lang.en, Sense.noun,
                                       `juletid`, Lang.sv, Sense.noun);
        learnEtymologicallyDerivedFrom(`smorgosbord`, Lang.en, Sense.noun,
                                       `smörgåsbord`, Lang.sv, Sense.noun);
        learnEtymologicallyDerivedFrom(`förgätmigej`, Lang.sv, Sense.noun,
                                       `förgät mig ej`, Lang.sv, Sense.unknown); // TODO uppmaning
    }

    /** Learn that $(D first) in language $(D firstLang) is etymologically
        derived from $(D second) in language $(D secondLang) both in sense $(D sense).
     */
    Ln learnEtymologicallyDerivedFrom(S1, S2)(S1 first, Lang firstLang, Sense firstSense,
                                              S2 second, Lang secondLang, Sense secondSense)
    {
        return connect(store(first, firstLang, Sense.noun, Origin.manual),
                       Role(Rel.etymologicallyDerivedFrom),
                       store(second, secondLang, Sense.noun, Origin.manual),
                       Origin.manual, 1.0);
    }

    /** Learn English Irregular Verb.
     */
    Ln[] learnEnglishIrregularVerb(S1, S2, S3)(S1 infinitive,
                                               S2 past,
                                               S3 pastParticiple,
                                               Origin origin = Origin.manual)
    {
        enum lang = Lang.en;
        Nd[] all;
        all ~= store(infinitive, lang, Sense.verbIrregularInfinitive, origin);
        all ~= store(past, lang, Sense.verbIrregularPast, origin);
        all ~= store(pastParticiple, lang, Sense.verbIrregularPastParticiple, origin);
        return connectAll(Role(Rel.formOfVerb), all.filter!(a => a.defined), lang, origin);
    }

    /** Learn English Acronym.
     */
    Ln learnEnglishAcronym(S)(S acronym,
                                   S expr,
                                   NWeight weight = 1.0,
                                   Sense sense = Sense.unknown,
                                   Origin origin = Origin.manual) if (isSomeString!S)
    {
        enum lang = Lang.en;
        return connect(store(acronym, lang, Sense.nounAcronym, origin),
                       Role(Rel.acronymFor),
                       store(expr.toLower, lang, sense, origin),
                       origin, weight);
    }

    /** Learn English $(D words) related to attribute.
     */
    Ln[] learnMto1(R, S)(Lang lang,
                         R words,
                         Role role,
                         S attribute,
                         Sense wordSense = Sense.unknown,
                         Sense attributeSense = Sense.noun,
                         NWeight weight = 0.5,
                         Origin origin = Origin.manual) if (isInputRange!R &&
                                                            (isSomeString!(ElementType!R)) &&
                                                            isSomeString!S)
    {
        return connectMto1(store(words, lang, wordSense, origin),
                           role,
                           store(attribute, lang, attributeSense, origin),
                           origin, weight);
    }

    Ln[] learnMto1Maybe(S)(Lang lang,
                           string wordsPath,
                           Role role,
                           S attribute,
                           Sense wordSense = Sense.unknown,
                           Sense attributeSense = Sense.noun,
                           NWeight weight = 0.5,
                           Origin origin = Origin.manual) if (isSomeString!S)
    {
        try
        {
            return learnMto1(lang,
                             rdT(wordsPath).splitter('\n').filter!(w => !w.empty),
                             role,
                             attribute,
                             wordSense,
                             attributeSense,
                             weight,
                             origin);
        }
        catch (std.file.FileException e)
        {
            return typeof(return).init; /* OK: If file doesn't exist */
        }
    }

    /** Learn English Emoticon.
     */
    Ln[] learnEnglishEmoticon(S)(S[] emoticons,
                                      S[] exprs,
                                      NWeight weight = 1.0,
                                      Sense sense = Sense.unknown,
                                      Origin origin = Origin.manual) if (isSomeString!S)
    {
        return connectMtoN(store(emoticons, Lang.any, Sense.unknown, origin),
                           Role(Rel.emoticonFor),
                           store(exprs, Lang.en, sense, origin),
                           origin, weight);
    }

    /** Learn English Computer Acronyms.
     */
    void learnEnglishComputerKnowledge()
    {
        // TODO Context: Computer
        learnEnglishAcronym(`IETF`, `Internet Engineering Task Force`);
        learnEnglishAcronym(`RFC`, `Request For Comments`);
        learnEnglishAcronym(`FYI`, `For Your Information`);
        learnEnglishAcronym(`BCP`, `Best Current Practise`);
        learnEnglishAcronym(`LGTM`, `Looks Good To Me`);

        learnEnglishAcronym(`AJAX`, `Asynchronous Javascript And XML`, 1.0); // 5-star
        learnEnglishAcronym(`AJAX`, `Associação De Jogadores Amadores De Xadrez`, 0.2); // 1-star

        // TODO Context: (Orakel) Computer
        learnEnglishAcronym(`3NF`, `Third Normal Form`);
        learnEnglishAcronym(`ACID`, `Atomicity, Consistency, Isolation, and Durability`);
        learnEnglishAcronym(`ACL`, `Access Control List`);
        learnEnglishAcronym(`ACLs`, `Access Control Lists`);
        learnEnglishAcronym(`ADDM`, `Automatic Database Diagnostic Monitor`);
        learnEnglishAcronym(`ADR`, `Automatic Diagnostic Repository`);
        learnEnglishAcronym(`ASM`, `Automatic Storage Management`);
        learnEnglishAcronym(`AWR`, `Automatic Workload Repository`);
        learnEnglishAcronym(`AWT`, `Asynchronous WriteThrough`);
        learnEnglishAcronym(`BGP`, `Basic Graph Pattern`);
        learnEnglishAcronym(`BLOB`, `Binary Large Object`);
        learnEnglishAcronym(`CBC`, `Cipher Block Chaining`);
        learnEnglishAcronym(`CCA`, `Control Center Agent`);
        learnEnglishAcronym(`CDATA`, `Character DATA`);
        learnEnglishAcronym(`CDS`, `Cell Directory Services`);
        learnEnglishAcronym(`CFS`, `Cluster File System`);
        learnEnglishAcronym(`CIDR`, `Classless Inter-Domain Routing`);
        learnEnglishAcronym(`CLOB`, `Character Large OBject`);
        learnEnglishAcronym(`CMADMIN`, `Connection Manager Administration`);
        learnEnglishAcronym(`CMGW`, `Connection Manager GateWay`);
        learnEnglishAcronym(`COM`, `Component Object Model`);
        learnEnglishAcronym(`CORBA`, `Common Object Request Broker API`);
        learnEnglishAcronym(`CORE`, `Common Oracle Runtime Environment`);
        learnEnglishAcronym(`CRL`, `certificate revocation list`);
        learnEnglishAcronym(`CRSD`, `Cluster Ready Services Daemon`);
        learnEnglishAcronym(`CSS`, `Cluster Synchronization Services`);
        learnEnglishAcronym(`CT`, `Code Template`);
        learnEnglishAcronym(`CVU`, `Cluster Verification Utility`);
        learnEnglishAcronym(`CWM`, `Common Warehouse Metadata`);
        learnEnglishAcronym(`DAS`, `Direct Attached Storage`);
        learnEnglishAcronym(`DBA`, `DataBase Administrator`);
        learnEnglishAcronym(`DBMS`, `DataBase Management System`);
        learnEnglishAcronym(`DBPITR`, `Database Point-In-Time Recovery`);
        learnEnglishAcronym(`DBW`, `Database Writer`);
        learnEnglishAcronym(`DCE`, `Distributed Computing Environment`);
        learnEnglishAcronym(`DCOM`, `Distributed Component Object Model`);
        learnEnglishAcronym(`DDL LCR`, `DDL Logical Change Record`);
        learnEnglishAcronym(`DHCP`, `Dynamic Host Configuration Protocol`);
        learnEnglishAcronym(`DICOM`, `Digital Imaging and Communications in Medicine`);
        learnEnglishAcronym(`DIT`, `Directory Information Tree`);
        learnEnglishAcronym(`DLL`, `Dynamic-Link Library`);
        learnEnglishAcronym(`DN`, `Distinguished Name`);
        learnEnglishAcronym(`DNS`, `Domain Name System`);
        learnEnglishAcronym(`DOM`, `Document Object Model`);
        learnEnglishAcronym(`DTD`, `Document Type Definition`);
        learnEnglishAcronym(`DTP`, `Distributed Transaction Processing`);
        learnEnglishAcronym(`Dnnn`, `Dispatcher Process`);
        learnEnglishAcronym(`DoS`, `Denial-Of-Service`);
        learnEnglishAcronym(`EJB`, `Enterprise JavaBean`);
        learnEnglishAcronym(`EMCA`, `Enterprise Manager Configuration Assistant`);
        learnEnglishAcronym(`ETL`, `Extraction, Transformation, and Loading`);
        learnEnglishAcronym(`EVM`, `Event Manager`);
        learnEnglishAcronym(`EVMD`, `Event Manager Daemon`);
        learnEnglishAcronym(`FAN`, `Fast Application Notification`);
        learnEnglishAcronym(`FIPS`, `Federal Information Processing Standard`);
        learnEnglishAcronym(`GAC`, `Global Assembly Cache`);
        learnEnglishAcronym(`GCS`, `Global Cache Service`);
        learnEnglishAcronym(`GDS`, `Global Directory Service`);
        learnEnglishAcronym(`GES`, `Global Enqueue Service`);
        learnEnglishAcronym(`GIS`, `Geographic Information System`);
        learnEnglishAcronym(`GNS`, `Grid Naming Service`);
        learnEnglishAcronym(`GNSD`, `Grid Naming Service Daemon`);
        learnEnglishAcronym(`GPFS`, `General Parallel File System`);
        learnEnglishAcronym(`GSD`, `Global Services Daemon`);
        learnEnglishAcronym(`GV$`, `global dynamic performance views`);
        learnEnglishAcronym(`HACMP`, `High Availability Cluster Multi-Processing`);
        learnEnglishAcronym(`HBA`, `Host Bus Adapter`);
        learnEnglishAcronym(`IDE`, `Integrated Development Environment`);
        learnEnglishAcronym(`IPC`, `Interprocess Communication`);
        learnEnglishAcronym(`IPv4`, `IP Version 4`);
        learnEnglishAcronym(`IPv6`, `IP Version 6`);
        learnEnglishAcronym(`ITL`, `Interested Transaction List`);
        learnEnglishAcronym(`J2EE`, `Java 2 Platform, Enterprise Edition`);
        learnEnglishAcronym(`JAXB`, `Java Architecture for XML Binding`);
        learnEnglishAcronym(`JAXP`, `Java API for XML Processing`);
        learnEnglishAcronym(`JDBC`, `Java Database Connectivity`);
        learnEnglishAcronym(`JDK`, `Java Developer's Kit`);
        learnEnglishAcronym(`JNDI`,`Java Naming and Directory Interface`);
        learnEnglishAcronym(`JRE`,`Java Runtime Environment`);
        learnEnglishAcronym(`JSP`,`JavaServer Pages`);
        learnEnglishAcronym(`JSR`,`Java Specification Request`);
        learnEnglishAcronym(`JVM`,`Java Virtual Machine`);
        learnEnglishAcronym(`KDC`,`Key Distribution Center`);
        learnEnglishAcronym(`KWIC`, `Key Word in Context`);
        learnEnglishAcronym(`LCR`, `Logical Change Record`);
        learnEnglishAcronym(`LDAP`, `Lightweight Directory Access Protocol`);
        learnEnglishAcronym(`LDIF`, `Lightweight Directory Interchange Format`);
        learnEnglishAcronym(`LGWR`, `LoG WRiter`);
        learnEnglishAcronym(`LMD`, `Global Enqueue Service Daemon`);
        learnEnglishAcronym(`LMON`, `Global Enqueue Service Monitor`);
        learnEnglishAcronym(`LMSn`, `Global Cache Service Processes`);
        learnEnglishAcronym(`LOB`, `Large OBject`);
        learnEnglishAcronym(`LOBs`, `Large Objects`);
        learnEnglishAcronym(`LRS Segment`, `Geometric Segment`);
        learnEnglishAcronym(`LUN`, `Logical Unit Number`);
        learnEnglishAcronym(`LUNs`, `Logical Unit Numbers`);
        learnEnglishAcronym(`LVM`, `Logical Volume Manager`);
        learnEnglishAcronym(`MAPI`, `Messaging Application Programming Interface`);
        learnEnglishAcronym(`MBR`, `Master Boot Record`);
        learnEnglishAcronym(`MS DTC`, `Microsoft Distributed Transaction Coordinator`);
        learnEnglishAcronym(`MTTR`, `Mean Time To Recover`);
        learnEnglishAcronym(`NAS`, `Network Attached Storage`);
        learnEnglishAcronym(`NCLOB`, `National Character Large Object`);
        learnEnglishAcronym(`NFS`, `Network File System`);
        learnEnglishAcronym(`NI`, `Network Interface`);
        learnEnglishAcronym(`NIC`, `Network Interface Card`);
        learnEnglishAcronym(`NIS`, `Network Information Service`);
        learnEnglishAcronym(`NIST`, `National Institute of Standards and Technology`);
        learnEnglishAcronym(`NPI`, `Network Program Interface`);
        learnEnglishAcronym(`NS`, `Network Session`);
        learnEnglishAcronym(`NTP`, `Network Time Protocol`);
        learnEnglishAcronym(`OASIS`, `Organization for the Advancement of Structured Information`);
        learnEnglishAcronym(`OCFS`, `Oracle Cluster File System`);
        learnEnglishAcronym(`OCI`, `Oracle Call Interface`);
        learnEnglishAcronym(`OCR`, `Oracle Cluster Registry`);
        learnEnglishAcronym(`ODBC`, `Open Database Connectivity`);
        learnEnglishAcronym(`ODBC INI`, `ODBC Initialization File`);
        learnEnglishAcronym(`ODP NET`, `Oracle Data Provider for .NET`);
        learnEnglishAcronym(`OFA`, `optimal flexible architecture`);
        learnEnglishAcronym(`OHASD`, `Oracle High Availability Services Daemon`);
        learnEnglishAcronym(`OIFCFG`, `Oracle Interface Configuration Tool`);
        learnEnglishAcronym(`OLM`, `Object Link Manager`);
        learnEnglishAcronym(`OLTP`, `online transaction processing`);
        learnEnglishAcronym(`OMF`, `Oracle Managed Files`);
        learnEnglishAcronym(`ONS`, `Oracle Notification Services`);
        learnEnglishAcronym(`OO4O`, `Oracle Objects for OLE`);
        learnEnglishAcronym(`OPI`, `Oracle Program Interface`);
        learnEnglishAcronym(`ORDBMS`, `object-relational database management system`);
        learnEnglishAcronym(`OSI`, `Open Systems Interconnection`);
        learnEnglishAcronym(`OUI`, `Oracle Universal Installer`);
        learnEnglishAcronym(`OraMTS`, `Oracle Services for Microsoft Transaction Server`);
        learnEnglishAcronym(`ASM`, `Automatic Storage Management`);
        learnEnglishAcronym(`RAC`, `Real Application Clusters`);
        learnEnglishAcronym(`PCDATA`, `Parsed Character Data`);
        learnEnglishAcronym(`PGA`, `Program Global Area`);
        learnEnglishAcronym(`PKI`, `Public Key Infrastructure`);
        learnEnglishAcronym(`RAID`, `Redundant Array of Inexpensive Disks`);
        learnEnglishAcronym(`RDBMS`, `Relational Database Management System`);
        learnEnglishAcronym(`RDN`, `Relative Distinguished Name`);
        learnEnglishAcronym(`RM`, `Resource Manager`);
        learnEnglishAcronym(`RMAN`, `Recovery Manager`);
        learnEnglishAcronym(`ROI`, `Return On Investment`);
        learnEnglishAcronym(`RPO`, `Recovery Point Objective`);
        learnEnglishAcronym(`RTO`, `Recovery Time Objective`);
        learnEnglishAcronym(`SAN`, `Storage Area Network`);
        learnEnglishAcronym(`SAX`, `Simple API for XML`);
        learnEnglishAcronym(`SCAN`, `Single Client Access Name`);
        learnEnglishAcronym(`SCN`, `System Change Number`);
        learnEnglishAcronym(`SCSI`, `Small Computer System Interface`);
        learnEnglishAcronym(`SDU`, `Session Data Unit`);
        learnEnglishAcronym(`SGA`, `System Global Area`);
        learnEnglishAcronym(`SGML`, `Structured Generalized Markup Language`);
        learnEnglishAcronym(`SHA`, `Secure Hash Algorithm`);
        learnEnglishAcronym(`SID`, `System IDentifier`);
        learnEnglishAcronym(`SKOS`, `Simple Knowledge Organization System`);
        learnEnglishAcronym(`SOA`, `Service-Oriented Architecture`);
        learnEnglishAcronym(`SOAP`, `Simple Object Access Protocol`);
        learnEnglishAcronym(`SOP`, `Service Object Pair`);
        learnEnglishAcronym(`SQL`, `Structured Query Language`);
        learnEnglishAcronym(`SRVCTL`, `Server Control`);
        learnEnglishAcronym(`SSH`, `Secure Shell`);
        learnEnglishAcronym(`SSL`, `Secure Sockets Layer`);
        learnEnglishAcronym(`SSO`, `Single Sign-On`);
        learnEnglishAcronym(`STS`, `Sql Tuning Set`);
        learnEnglishAcronym(`SWT`, `Synchronous WriteThrough`);
        learnEnglishAcronym(`TAF`, `Transparent Application Failover`);
        learnEnglishAcronym(`TCO`, `Total Cost of Ownership`);
        learnEnglishAcronym(`TNS`, `Transparent Network Substrate`);
        learnEnglishAcronym(`TSPITR`, `Tablespace Point-In-Time Recovery`);
        learnEnglishAcronym(`TTC`, `Two-Task Common`);
        learnEnglishAcronym(`UGA`, `User Global Area`);
        learnEnglishAcronym(`UID`, `Unique IDentifier`);
        learnEnglishAcronym(`UIX`, `User Interface XML`);
        learnEnglishAcronym(`UNC`, `Universal Naming Convention`);
        learnEnglishAcronym(`UTC`, `Coordinated Universal Time`);
        learnEnglishAcronym(`VPD`, `Virtual Private Database`);
        learnEnglishAcronym(`VSS`, `Volume Shadow Copy Service`);
        learnEnglishAcronym(`W3C`, `World Wide Web Consortium`);
        learnEnglishAcronym(`WG`, `Working Group`);
        learnEnglishAcronym(`WebDAV`, `World Wide Web Distributed Authoring and Versioning`);
        learnEnglishAcronym(`Winsock`, `Windows sockets`);
        learnEnglishAcronym(`XDK`, `XML Developer's Kit`);
        learnEnglishAcronym(`XIDs`,`Transaction Identifiers`);
        learnEnglishAcronym(`XML`,`eXtensible Markup Language`);
        learnEnglishAcronym(`XQuery`,`XML Query`);
        learnEnglishAcronym(`XSL`,`eXtensible Stylesheet Language`);
        learnEnglishAcronym(`XSLFO`, `eXtensible Stylesheet Language Formatting Object`);
        learnEnglishAcronym(`XSLT`, `eXtensible Stylesheet Language Transformation`);
        learnEnglishAcronym(`XSU`, `XML SQL Utility`);
        learnEnglishAcronym(`XVM`, `XSLT Virtual Machine`);
        learnEnglishAcronym(`Approximate CSCN`, `Approximate Commit System Change Number`);
        learnEnglishAcronym(`mDNS`, `Multicast Domain Name Server`);
        learnEnglishAcronym(`row LCR`, `Row Logical Change Record`);

        /* Use: atLocation (US) */

        /* Context: Non-animal methods for toxicity testing */

        learnEnglishAcronym(`3D`,`three dimensional`);
        learnEnglishAcronym(`3RS`,`Replacement, Reduction, Refinement`);
        learnEnglishAcronym(`AALAS`,`American Association for Laboratory Animal Science`);
        learnEnglishAcronym(`ADI`,`Acceptable Daily Intake [human]`);
        learnEnglishAcronym(`AFIP`,`Armed Forces Institute of Pathology`);
        learnEnglishAcronym(`AHI`,`Animal Health Institute (US)`);
        learnEnglishAcronym(`AIDS`,`Acquired Immune Deficiency Syndrome`);
        learnEnglishAcronym(`ANDA`,`Abbreviated New Drug Application (US FDA)`);
        learnEnglishAcronym(`AOP`,`Adverse Outcome Pathway`);
        learnEnglishAcronym(`APHIS`,`Animal and Plant Health Inspection Service (USDA)`);
        learnEnglishAcronym(`ARDF`,`Alternatives Research and Development Foundation`);
        learnEnglishAcronym(`ATLA`,`Alternatives to Laboratory Animals`);
        learnEnglishAcronym(`ATSDR`,`Agency for Toxic Substances and Disease Registry (US CDC)`);
        learnEnglishAcronym(`BBMO`,`Biosensors Based on Membrane Organization to Replace Animal Testing`);
        learnEnglishAcronym(`BCOP`,`Bovine Corneal Opacity and Permeability assay`);
        learnEnglishAcronym(`BFR`,`German Federal Institute for Risk Assessment`);
        learnEnglishAcronym(`BLA`,`Biological License Application (US FDA)`);
        learnEnglishAcronym(`BRD`,`Background Review Document (ICCVAM)`);
        learnEnglishAcronym(`BSC`,`Board of Scientific Counselors (US NTP)`);
        learnEnglishAcronym(`BSE`,`Bovine Spongiform Encephalitis`);
        learnEnglishAcronym(`CAAI`,`University of California Center for Animal Alternatives Information`);
        learnEnglishAcronym(`CAAT`,`Johns Hopkins Center for Alternatives to Animal Testing`);
        learnEnglishAcronym(`CAMVA`,`Chorioallantoic Membrane Vascularization Assay`);
        learnEnglishAcronym(`CBER`,`Center for Biologics Evaluation and Research (US FDA)`);
        learnEnglishAcronym(`CDC`,`Centers for Disease Control and Prevention (US)`);
        learnEnglishAcronym(`CDER`,`Center for Drug Evaluation and Research (US FDA)`);
        learnEnglishAcronym(`CDRH`,`Center for Devices and Radiological Health (US FDA)`);
        learnEnglishAcronym(`CERHR`,`Center for the Evaluation of Risks to Human Reproduction (US NTP)`);
        learnEnglishAcronym(`CFR`,`Code of Federal Regulations (US)`);
        learnEnglishAcronym(`CFSAN`,`Center for Food Safety and Applied Nutrition (US FDA)`);
        learnEnglishAcronym(`CHMP`,`Committees for Medicinal Products for Human Use`);
        learnEnglishAcronym(`CMR`,`Carcinogenic, Mutagenic and Reprotoxic`);
        learnEnglishAcronym(`CO2`,`Carbon Dioxide`);
        learnEnglishAcronym(`COLIPA`,`European Cosmetic Toiletry & Perfumery Association`);
        learnEnglishAcronym(`COMP`,`Committee for Orphan Medicinal Products`);
        learnEnglishAcronym(`CORDIS`,`Community Research & Development Information Service`);
        learnEnglishAcronym(`CORRELATE`,`European Reference Laboratory for Alternative Tests`);
        learnEnglishAcronym(`CPCP`,`Chemical Prioritization Community of Practice (US EPA)`);
        learnEnglishAcronym(`CPSC`,`Consumer Product Safety Commission (US)`);
        learnEnglishAcronym(`CTA`,`Cell Transformation Assays`);
        learnEnglishAcronym(`CVB`,`Center for Veterinary Biologics (USDA)`);
        learnEnglishAcronym(`CVM`,`Center for Veterinary Medicine (US FDA)`);
        learnEnglishAcronym(`CVMP`,`Committee for Medicinal Products for Veterinary Use`);
        learnEnglishAcronym(`DARPA`,`Defense Advanced Research Projects Agency (US)`);
        learnEnglishAcronym(`DG`,`Directorate General`);
        learnEnglishAcronym(`DOD`,`Department of Defense (US)`);
        learnEnglishAcronym(`DOT`,`Department of Transportation (US)`);
        learnEnglishAcronym(`DRP`,`Detailed Review Paper (OECD)`);
        learnEnglishAcronym(`EC`,`European Commission`);
        learnEnglishAcronym(`ECB`,`European Chemicals Bureau`);
        learnEnglishAcronym(`ECHA`,`European Chemicals Agency`);
        learnEnglishAcronym(`ECOPA`,`European Consensus Platform for Alternatives`);
        learnEnglishAcronym(`ECVAM`,`European Centre for the Validation of Alternative Methods`);
        learnEnglishAcronym(`ED`,`Endocrine Disrupters`);
        learnEnglishAcronym(`EDQM`,`European Directorate for Quality of Medicines & HealthCare`);
        learnEnglishAcronym(`EEC`,`European Economic Commission`);
        learnEnglishAcronym(`EFPIA`,`European Federation of Pharmaceutical Industries and Associations`);
        learnEnglishAcronym(`EFSA`,`European Food Safety Authority`);
        learnEnglishAcronym(`EFSAPPR`,`European Food Safety Authority Panel on plant protection products and their residues`);
        learnEnglishAcronym(`EFTA`,`European Free Trade Association`);
        learnEnglishAcronym(`ELINCS`,`European List of Notified Chemical Substances`);
        learnEnglishAcronym(`ELISA`,`Enzyme-Linked ImmunoSorbent Assay`);
        learnEnglishAcronym(`EMEA`,`European Medicines Agency`);
        learnEnglishAcronym(`ENVI`,`European Parliament Committee on the Environment, Public Health and Food Safety`);
        learnEnglishAcronym(`EO`,`Executive Orders (US)`);
        learnEnglishAcronym(`EPA`,`Environmental Protection Agency (US)`);
        learnEnglishAcronym(`EPAA`,`European Partnership for Alternative Approaches to Animal Testing`);
        learnEnglishAcronym(`ESACECVAM`,`Scientific Advisory Committee (EU)`);
        learnEnglishAcronym(`ESOCOC`,`Economic and Social Council (UN)`);
        learnEnglishAcronym(`EU`,`European Union`);
        learnEnglishAcronym(`EURL`,`ECVAM European Union Reference Laboratory on Alternatives to Animal Testing`);
        learnEnglishAcronym(`EWG`,`Expert Working group`);

        learnEnglishAcronym(`FAO`,`Food and Agriculture Organization of the United Nations`);
        learnEnglishAcronym(`FDA`,`Food and Drug Administration (US)`);
        learnEnglishAcronym(`FFDCA`,`Federal Food, Drug, and Cosmetic Act (US)`);
        learnEnglishAcronym(`FHSA`,`Federal Hazardous Substances Act (US)`);
        learnEnglishAcronym(`FIFRA`,`Federal Insecticide, Fungicide, and Rodenticide Act (US)`);
        learnEnglishAcronym(`FP`,`Framework Program`);
        learnEnglishAcronym(`FRAME`,`Fund for the Replacement of Animals in Medical Experiments`);
        learnEnglishAcronym(`GCCP`,`Good Cell Culture Practice`);
        learnEnglishAcronym(`GCP`,`Good Clinical Practice`);
        learnEnglishAcronym(`GHS`,`Globally Harmonized System for Classification and Labeling of Chemicals`);
        learnEnglishAcronym(`GJIC`,`Gap Junction Intercellular Communication [assay]`);
        learnEnglishAcronym(`GLP`,`Good Laboratory Practice`);
        learnEnglishAcronym(`GMO`,`Genetically Modified Organism`);
        learnEnglishAcronym(`GMP`,`Good Manufacturing Practice`);
        learnEnglishAcronym(`GPMT`,`Guinea Pig Maximization Test`);
        learnEnglishAcronym(`HCE`,`Human corneal epithelial cells`);
        learnEnglishAcronym(`HCE`,`T Human corneal epithelial cells`);
        learnEnglishAcronym(`HESI`,`ILSI Health and Environmental Sciences Institute`);
        learnEnglishAcronym(`HET`,`CAM Hen’s Egg Test – Chorioallantoic Membrane assay`);
        learnEnglishAcronym(`HHS`,`Department of Health and Human Services (US)`);
        learnEnglishAcronym(`HIV`,`Human Immunodeficiency Virus`);
        learnEnglishAcronym(`HMPC`,`Committee on Herbal Medicinal Products`);
        learnEnglishAcronym(`HPV`,`High Production Volume`);
        learnEnglishAcronym(`HSUS`,`The Humane Society of the United States`);
        learnEnglishAcronym(`HTS`,`High Throughput Screening`);
        learnEnglishAcronym(`HGP`,`Human Genome Project`);
        learnEnglishAcronym(`IARC`,`International Agency for Research on Cancer (WHO)`);
        learnEnglishAcronym(`ICAPO`,`International Council for Animal Protection in OECD`);
        learnEnglishAcronym(`ICCVAM`,`Interagency Coordinating Committee on the Validation of Alternative Methods (US)`);
        learnEnglishAcronym(`ICE`,`Isolated Chicken Eye`);
        learnEnglishAcronym(`ICH`,`International Conference on Harmonization of Technical Requirements for Registration of Pharmaceuticals for Human Use`);
        learnEnglishAcronym(`ICSC`,`International Chemical Safety Cards`);
        learnEnglishAcronym(`IFAH`,`EUROPE International Federation for Animal Health Europe`);
        learnEnglishAcronym(`IFPMA`,`International Federation of Pharmaceutical Manufacturers & Associations`);
        learnEnglishAcronym(`IIVS`,`Institute for In Vitro Sciences`);
        learnEnglishAcronym(`ILAR`,`Institute for Laboratory Animal Research`);
        learnEnglishAcronym(`ILO`,`International Labour Organization`);
        learnEnglishAcronym(`ILSI`,`International Life Sciences Institute`);
        learnEnglishAcronym(`IND`,`Investigational New Drug (US FDA)`);
        learnEnglishAcronym(`INVITROM`,`International Society for In Vitro Methods`);
        learnEnglishAcronym(`IOMC`,`Inter-Organization Programme for the Sound Management of Chemicals (WHO)`);
        learnEnglishAcronym(`IPCS`,`International Programme on Chemical Safety (WHO)`);
        learnEnglishAcronym(`IQF`,`International QSAR Foundation to Reduce Animal Testing`);
        learnEnglishAcronym(`IRB`,`Institutional review board`);
        learnEnglishAcronym(`IRE`,`Isolated rabbit eye`);
        learnEnglishAcronym(`IWG`,`Immunotoxicity Working Group (ICCVAM)`);
        learnEnglishAcronym(`JACVAM`,`Japanese Center for the Validation of Alternative Methods`);
        learnEnglishAcronym(`JAVB`,`Japanese Association of Veterinary Biologics`);
        learnEnglishAcronym(`JECFA`,`Joint FAO/WHO Expert Committee on Food Additives`);
        learnEnglishAcronym(`JMAFF`,`Japanese Ministry of Agriculture, Forestry and Fisheries`);
        learnEnglishAcronym(`JPMA`,`Japan Pharmaceutical Manufacturers Association`);
        learnEnglishAcronym(`JRC`,`Joint Research Centre (EU)`);
        learnEnglishAcronym(`JSAAE`,`Japanese Society for Alternatives to Animal Experiments`);
        learnEnglishAcronym(`JVPA`,`Japanese Veterinary Products Association`);

        learnEnglishAcronym(`KOCVAM`,`Korean Center for the Validation of Alternative Method`);
        learnEnglishAcronym(`LIINTOP`,`Liver Intestine Optimization`);
        learnEnglishAcronym(`LLNA`,`Local Lymph Node Assay`);
        learnEnglishAcronym(`MAD`,`Mutual Acceptance of Data (OECD)`);
        learnEnglishAcronym(`MEIC`,`Multicenter Evaluation of In Vitro Cytotoxicity`);
        learnEnglishAcronym(`MEMOMEIC`,`Monographs on Time-Related Human Lethal Blood Concentrations`);
        learnEnglishAcronym(`MEPS`,`Members of the European Parliament`);
        learnEnglishAcronym(`MG`,`Milligrams [a unit of weight]`);
        learnEnglishAcronym(`MHLW`,`Ministry of Health, Labour and Welfare (Japan)`);
        learnEnglishAcronym(`MLI`,`Molecular Libraries Initiative (US NIH)`);
        learnEnglishAcronym(`MSDS`,`Material Safety Data Sheets`);

        learnEnglishAcronym(`MW`,`Molecular Weight`);
        learnEnglishAcronym(`NC3RSUK`,`National Center for the Replacement, Refinement and Reduction of Animals in Research`);
        learnEnglishAcronym(`NKCA`,`Netherlands Knowledge Centre on Alternatives to animal use`);
        learnEnglishAcronym(`NCBI`,`National Center for Biotechnology Information (US)`);
        learnEnglishAcronym(`NCEH`,`National Center for Environmental Health (US CDC)`);
        learnEnglishAcronym(`NCGCNIH`,`Chemical Genomics Center (US)`);
        learnEnglishAcronym(`NCI`,`National Cancer Institute (US NIH)`);
        learnEnglishAcronym(`NCPDCID`,`National Center for Preparedness, Detection and Control of Infectious Diseases`);
        learnEnglishAcronym(`NCCT`,`National Center for Computational Toxicology (US EPA)`);
        learnEnglishAcronym(`NCTR`,`National Center for Toxicological Research (US FDA)`);
        learnEnglishAcronym(`NDA`,`New Drug Application (US FDA)`);
        learnEnglishAcronym(`NGO`,`Non-Governmental Organization`);
        learnEnglishAcronym(`NIAID`,`National Institute of Allergy and Infectious Diseases`);
        learnEnglishAcronym(`NICA`,`Nordic Information Center for Alternative Methods`);
        learnEnglishAcronym(`NICEATM`,`National Toxicology Program Interagency Center for Evaluation of Alternative Toxicological Methods (US)`);
        learnEnglishAcronym(`NIEHS`,`National Institute of Environmental Health Sciences (US NIH)`);
        learnEnglishAcronym(`NIH`,`National Institutes of Health (US)`);
        learnEnglishAcronym(`NIHS`,`National Institute of Health Sciences (Japan)`);
        learnEnglishAcronym(`NIOSH`,`National Institute for Occupational Safety and Health (US CDC)`);
        learnEnglishAcronym(`NITR`,`National Institute of Toxicological Research (Korea)`);
        learnEnglishAcronym(`NOAEL`,`Nd-Observed Adverse Effect Level`);
        learnEnglishAcronym(`NOEL`,`Nd-Observed Effect Level`);
        learnEnglishAcronym(`NPPTAC`,`National Pollution Prevention and Toxics Advisory Committee (US EPA)`);
        learnEnglishAcronym(`NRC`,`National Research Council`);
        learnEnglishAcronym(`NTP`,`National Toxicology Program (US)`);
        learnEnglishAcronym(`OECD`,`Organisation for Economic Cooperation and Development`);
        learnEnglishAcronym(`OMCLS`,`Official Medicines Control Laboratories`);
        learnEnglishAcronym(`OPPTS`,`Office of Prevention, Pesticides and Toxic Substances (US EPA)`);
        learnEnglishAcronym(`ORF`,`open reading frame`);
        learnEnglishAcronym(`OSHA`,`Occupational Safety and Health Administration (US)`);
        learnEnglishAcronym(`OSIRIS`,`Optimized Strategies for Risk Assessment of Industrial Chemicals through the Integration of Non-test and Test Information`);
        learnEnglishAcronym(`OT`,`Cover-the-counter [drug]`);

        learnEnglishAcronym(`PBPK`,`Physiologically-Based Pharmacokinetic (modeling)`);
        learnEnglishAcronym(`P&G`,` Procter & Gamble`);
        learnEnglishAcronym(`PHRMA`,`Pharmaceutical Research and Manufacturers of America`);
        learnEnglishAcronym(`PL`,`Public Law`);
        learnEnglishAcronym(`POPS`,`Persistent Organic Pollutants`);
        learnEnglishAcronym(`QAR`, `Quantitative Structure Activity Relationship`);
        learnEnglishAcronym(`QSM`,`Quality, Safety and Efficacy of Medicines (WHO)`);
        learnEnglishAcronym(`RA`,`Regulatory Acceptance`);
        learnEnglishAcronym(`REACH`,`Registration, Evaluation, Authorization and Restriction of Chemicals`);
        learnEnglishAcronym(`RHE`,`Reconstructed Human Epidermis`);
        learnEnglishAcronym(`RIPSREACH`,`Implementation Projects`);
        learnEnglishAcronym(`RNAI`,`RNA Interference`);
        learnEnglishAcronym(`RLLNA`,`Reduced Local Lymph Node Assay`);
        learnEnglishAcronym(`SACATM`,`Scientific Advisory Committee on Alternative Toxicological Methods (US)`);
        learnEnglishAcronym(`SAICM`,`Strategic Approach to International Chemical Management (WHO)`);
        learnEnglishAcronym(`SANCO`,`Health and Consumer Protection Directorate General`);
        learnEnglishAcronym(`SCAHAW`,`Scientific Committee on Animal Health and Animal Welfare`);
        learnEnglishAcronym(`SCCP`,`Scientific Committee on Consumer Products`);
        learnEnglishAcronym(`SCENIHR`,`Scientific Committee on Emerging and Newly Identified Health Risks`);
        learnEnglishAcronym(`SCFCAH`,`Standing Committee on the Food Chain and Animal Health`);
        learnEnglishAcronym(`SCHER`,`Standing Committee on Health and Environmental Risks`);
        learnEnglishAcronym(`SEPS`,`Special Emphasis Panels (US NTP)`);
        learnEnglishAcronym(`SIDS`,`Screening Information Data Sets`);
        learnEnglishAcronym(`SOT`,`Society of Toxicology`);
        learnEnglishAcronym(`SPORT`,`Strategic Partnership on REACH Testing`);
        learnEnglishAcronym(`TBD`,`To Be Determined`);
        learnEnglishAcronym(`TDG`,`Transport of Dangerous Goods (UN committee)`);
        learnEnglishAcronym(`TER`,`Transcutaneous Electrical Resistance`);
        learnEnglishAcronym(`TEWG`,`Technical Expert Working Group`);
        learnEnglishAcronym(`TG`,`Test Guideline (OECD)`);
        learnEnglishAcronym(`TOBI`,`Toxin Binding Inhibition`);
        learnEnglishAcronym(`TSCA`,`Toxic Substances Control Act (US)`);
        learnEnglishAcronym(`TTC`,`Threshold of Toxicological Concern`);

        learnEnglishAcronym(`UC`,`University of California`);
        learnEnglishAcronym(`UCD`,`University of California Davis`);
        learnEnglishAcronym(`UK`,`United Kingdom`);
        learnEnglishAcronym(`UN`,`United Nations`);
        learnEnglishAcronym(`UNECE`,`United Nations Economic Commission for Europe`);
        learnEnglishAcronym(`UNEP`,`United Nations Environment Programme`);
        learnEnglishAcronym(`UNITAR`,`United Nations Institute for Training and Research`);
        learnEnglishAcronym(`USAMRICD`,`US Army Medical Research Institute of Chemical Defense`);
        learnEnglishAcronym(`USAMRIID`,`US Army Medical Research Institute of Infectious Diseases`);
        learnEnglishAcronym(`USAMRMC`,`US Army Medical Research and Material Command`);
        learnEnglishAcronym(`USDA`,`United States Department of Agriculture`);
        learnEnglishAcronym(`USUHS`,`Uniformed Services University of the Health Sciences`);
        learnEnglishAcronym(`UV`,`ultraviolet`);
        learnEnglishAcronym(`VCCEP`,`Voluntary Children’s Chemical Evaluation Program (US EPA)`);
        learnEnglishAcronym(`VICH`,`International Cooperation on Harmonization of Technical Requirements for Registration of Veterinary Products`);
        learnEnglishAcronym(`WHO`,`World Health Organization`);
        learnEnglishAcronym(`WRAIR`,`Walter Reed Army Institute of Research`);
        learnEnglishAcronym(`ZEBET`,`Centre for Documentation and Evaluation of Alternative Methods to Animal Experiments (Germany)`);

        // TODO Context: Digital Communications
    	learnEnglishAcronym(`AAMOF`, `as a matter of fact`);
	learnEnglishAcronym(`ABFL`, `a big fat lady`);
	learnEnglishAcronym(`ABT`, `about`);
	learnEnglishAcronym(`ADN`, `any day now`);
	learnEnglishAcronym(`AFAIC`, `as far as I’m concerned`);
	learnEnglishAcronym(`AFAICT`, `as far as I can tell`);
	learnEnglishAcronym(`AFAICS`, `as far as I can see`);
	learnEnglishAcronym(`AFAIK`, `as far as I know`);
	learnEnglishAcronym(`AFAYC`, `as far as you’re concerned`);
	learnEnglishAcronym(`AFK`, `away from keyboard`);
	learnEnglishAcronym(`AH`, `asshole`);
	learnEnglishAcronym(`AISI`, `as I see it`);
	learnEnglishAcronym(`AIUI`, `as I understand it`);
	learnEnglishAcronym(`AKA`, `also known as`);
	learnEnglishAcronym(`AML`, `all my love`);
	learnEnglishAcronym(`ANFSCD`, `and now for something completely different`);
	learnEnglishAcronym(`ASAP`, `as soon as possible`);
	learnEnglishAcronym(`ASL`, `assistant section leader`);
	learnEnglishAcronym(`ASL`, `age, sex, location`);
	learnEnglishAcronym(`ASLP`, `age, sex, location, picture`);
	learnEnglishAcronym(`A/S/L`, `age/sex/location`);
	learnEnglishAcronym(`ASOP`, `assistant system operator`);
	learnEnglishAcronym(`ATM`, `at this moment`);
	learnEnglishAcronym(`AWA`, `as well as`);
	learnEnglishAcronym(`AWHFY`, `are we having fun yet?`);
	learnEnglishAcronym(`AWGTHTGTTA`, `are we going to have to go trough this again?`);
	learnEnglishAcronym(`AWOL`, `absent without leave`);
	learnEnglishAcronym(`AWOL`, `away without leave`);
	learnEnglishAcronym(`AYOR`, `at your own risk`);
	learnEnglishAcronym(`AYPI`, `?	and your point is?`);

	learnEnglishAcronym(`B4`, `before`);
	learnEnglishAcronym(`BAC`, `back at computer`);
	learnEnglishAcronym(`BAG`, `busting a gut`);
	learnEnglishAcronym(`BAK`, `back at the keyboard`);
	learnEnglishAcronym(`BBIAB`, `be back in a bit`);
	learnEnglishAcronym(`BBL`, `be back later`);
	learnEnglishAcronym(`BBLBNTSBO`, `be back later but not to soon because of`);
	learnEnglishAcronym(`BBR`, `burnt beyond repair`);
	learnEnglishAcronym(`BBS`, `be back soon`);
	learnEnglishAcronym(`BBS`, `bulletin board system`);
	learnEnglishAcronym(`BC`, `be cool`);
	learnEnglishAcronym(`B`, `/C	because`);
	learnEnglishAcronym(`BCnU`, `be seeing you`);
	learnEnglishAcronym(`BEG`, `big evil grin`);
	learnEnglishAcronym(`BF`, `boyfriend`);
	learnEnglishAcronym(`B/F`, `boyfriend`);
	learnEnglishAcronym(`BFN`, `bye for now`);
	learnEnglishAcronym(`BG`, `big grin`);
	learnEnglishAcronym(`BION`, `believe it or not`);
	learnEnglishAcronym(`BIOYIOB`, `blow it out your I/O port`);
	learnEnglishAcronym(`BITMT`, `but in the meantime`);
	learnEnglishAcronym(`BM`, `bite me`);
	learnEnglishAcronym(`BMB`, `bite my bum`);
	learnEnglishAcronym(`BMTIPG`, `brilliant minds think in parallel gutters`);
	learnEnglishAcronym(`BKA`, `better known as`);
	learnEnglishAcronym(`BL`, `belly laughing`);
	learnEnglishAcronym(`BOB`, `back off bastard`);
	learnEnglishAcronym(`BOL`, `be on later`);
	learnEnglishAcronym(`BOM`, `bitch of mine`);
	learnEnglishAcronym(`BOT`, `back on topic`);
	learnEnglishAcronym(`BRB`, `be right back`);
	learnEnglishAcronym(`BRBB`, `be right back bitch`);
	learnEnglishAcronym(`BRBS`, `be right back soon`);
	learnEnglishAcronym(`BRH`, `be right here`);
	learnEnglishAcronym(`BRS`, `big red switch`);
	learnEnglishAcronym(`BS`, `big smile`);
	learnEnglishAcronym(`BS`, `bull shit`);
	learnEnglishAcronym(`BSF`, `but seriously folks`);
	learnEnglishAcronym(`BST`, `but seriously though`);
	learnEnglishAcronym(`BTA`, `but then again`);
	learnEnglishAcronym(`BTAIM`, `be that as it may`);
	learnEnglishAcronym(`BTDT`, `been there done that`);
	learnEnglishAcronym(`BTOBD`, `be there or be dead`);
	learnEnglishAcronym(`BTOBS`, `be there or be square`);
	learnEnglishAcronym(`BTSOOM`, `beats the shit out of me`);
	learnEnglishAcronym(`BTW`, `by the way`);
	learnEnglishAcronym(`BUDWEISER`, `because you deserve what every individual should ever receive`);
	learnEnglishAcronym(`BWQ`, `buzz word quotient`);
	learnEnglishAcronym(`BWTHDIK`, `but what the heck do I know`);
	learnEnglishAcronym(`BYOB`, `bring your own bottle`);
	learnEnglishAcronym(`BYOH`, `Bat You Onna Head`);

	learnEnglishAcronym(`C&G`, `chuckle and grin`);
	learnEnglishAcronym(`CAD`, `ctrl-alt-delete`);
	learnEnglishAcronym(`CADET`, `can’t add, doesn’t even try`);
	learnEnglishAcronym(`CDIWY`, `couldn’t do it without you`);
	learnEnglishAcronym(`CFV`, `call for votes`);
	learnEnglishAcronym(`CFS`, `care for secret?`);
	learnEnglishAcronym(`CFY`, `calling for you`);
	learnEnglishAcronym(`CID`, `crying in disgrace`);
	learnEnglishAcronym(`CIM`, `CompuServe information manager`);
	learnEnglishAcronym(`CLM`, `career limiting move`);
	learnEnglishAcronym(`CM@TW`, `catch me at the web`);
	learnEnglishAcronym(`CMIIW`, `correct me if I’m wrong`);
	learnEnglishAcronym(`CNP`, `continue in next post`);
	learnEnglishAcronym(`CO`, `conference`);
	learnEnglishAcronym(`CRAFT`, `can’t remember a f**king thing`);
	learnEnglishAcronym(`CRS`, `can’t remember shit`);
	learnEnglishAcronym(`CSG`, `chuckle snicker grin`);
	learnEnglishAcronym(`CTS`, `changing the subject`);
	learnEnglishAcronym(`CU`, `see you`);
	learnEnglishAcronym(`CU2`, `see you too`);
	learnEnglishAcronym(`CUL`, `see you later`);
	learnEnglishAcronym(`CUL8R`, `see you later`);
	learnEnglishAcronym(`CWOT`, `complete waste of time`);
	learnEnglishAcronym(`CWYL`, `chat with you later`);
	learnEnglishAcronym(`CYA`, `see ya`);
	learnEnglishAcronym(`CYA`, `cover your ass`);
	learnEnglishAcronym(`CYAL8R`, `see ya later`);
	learnEnglishAcronym(`CYO`, `see you online`);

	learnEnglishAcronym(`DBA`, `doing business as`);
	learnEnglishAcronym(`DCed`, `disconnected`);
	learnEnglishAcronym(`DFLA`, `disenhanced four-letter acronym`);
	learnEnglishAcronym(`DH`, `darling husband`);
	learnEnglishAcronym(`DIIK`, `darn if i know`);
	learnEnglishAcronym(`DGA`, `digital guardian angel`);
	learnEnglishAcronym(`DGARA`, `don’t give a rats ass`);
	learnEnglishAcronym(`DIKU`, `do I know you?`);
	learnEnglishAcronym(`DIRTFT`, `do it right the first time`);
	learnEnglishAcronym(`DITYID`, `did I tell you I’m distressed`);
	learnEnglishAcronym(`DIY`, `do it yourself`);
	learnEnglishAcronym(`DL`, `download`);
	learnEnglishAcronym(`DL`, `dead link`);
	learnEnglishAcronym(`DLTBBB`, `don’t let the bad bugs bite`);
	learnEnglishAcronym(`DMMGH`, `don’t make me get hostile`);
	learnEnglishAcronym(`DQMOT`, `don’t quote me on this`);
	learnEnglishAcronym(`DND`, `do not disturb`);
	learnEnglishAcronym(`DTC`, `damn this computer`);
	learnEnglishAcronym(`DTRT`, `do the right thing`);
	learnEnglishAcronym(`DUCT`, `did you see that?`);
	learnEnglishAcronym(`DWAI`, `don’t worry about it`);
	learnEnglishAcronym(`DWIM`, `do what I mean`);
	learnEnglishAcronym(`DWIMC`, `do what I mean, correctly`);
	learnEnglishAcronym(`DWISNWID`, `do what I say, not what I do`);
	learnEnglishAcronym(`DYJHIW`, `don’t you just hate it when...`);
	learnEnglishAcronym(`DYK`, `do you know`);

	learnEnglishAcronym(`EAK`, `eating at keyboard`);
	learnEnglishAcronym(`EIE`, `enough is enough`);
	learnEnglishAcronym(`EG`, `evil grin`);
	learnEnglishAcronym(`EMFBI`, `excuse me for butting in`);
	learnEnglishAcronym(`EMFJI`, `excuse me for jumping in`);
	learnEnglishAcronym(`EMSG`, `email message`);
	learnEnglishAcronym(`EOD`, `end of discussion`);
	learnEnglishAcronym(`EOF`, `end of file`);
	learnEnglishAcronym(`EOL`, `end of lecture`);
	learnEnglishAcronym(`EOM`, `end of message`);
	learnEnglishAcronym(`EOS`, `end of story`);
	learnEnglishAcronym(`EOT`, `end of thread`);
	learnEnglishAcronym(`ETLA`, `extended three letter acronym`);
	learnEnglishAcronym(`EYC`, `excitable, yet calm`);

	learnEnglishAcronym(`F`, `female`);
	learnEnglishAcronym(`F/F`, `face to face`);
	learnEnglishAcronym(`F2F`, `face to face`);
	learnEnglishAcronym(`FAQ`, `frequently asked questions`);
	learnEnglishAcronym(`FAWC`, `for anyone who cares`);
	learnEnglishAcronym(`FBOW`, `for better or worse`);
	learnEnglishAcronym(`FBTW`, `fine, be that way`);
	learnEnglishAcronym(`FCFS`, `first come, first served`);
	learnEnglishAcronym(`FCOL`, `for crying out loud`);
	learnEnglishAcronym(`FIFO`, `first in, first out`);
	learnEnglishAcronym(`FISH`, `first in, still here`);
	learnEnglishAcronym(`FLA`, `four-letter acronym`);
	learnEnglishAcronym(`FOAD`, `f**k off and die`);
	learnEnglishAcronym(`FOAF`, `friend of a friend`);
	learnEnglishAcronym(`FOB`, `f**k off bitch`);
	learnEnglishAcronym(`FOC`, `free of charge`);
	learnEnglishAcronym(`FOCL`, `falling of chair laughing`);
	learnEnglishAcronym(`FOFL`, `falling on the floor laughing`);
	learnEnglishAcronym(`FOS`, `freedom of speech`);
	learnEnglishAcronym(`FOTCL`, `falling of the chair laughing`);
	learnEnglishAcronym(`FTF`, `face to face`);
	learnEnglishAcronym(`FTTT`, `from time to time`);
	learnEnglishAcronym(`FU`, `f**ked up`);
	learnEnglishAcronym(`FUBAR`, `f**ked up beyond all recognition`);
	learnEnglishAcronym(`FUDFUCT`, `fear, uncertainty and doubt`);
	learnEnglishAcronym(`FUCT`, `failed under continuas testing`);
	learnEnglishAcronym(`FURTB`, `full up ready to burst (about hard disk drives)`);
	learnEnglishAcronym(`FW`, `freeware`);
	learnEnglishAcronym(`FWIW`, `for what it’s worth`);
	learnEnglishAcronym(`FYA`, `for your amusement`);
	learnEnglishAcronym(`FYE`, `for your entertainment`);
	learnEnglishAcronym(`FYEO`, `for your eyes only`);
	learnEnglishAcronym(`FYI`, `for your information`);

	learnEnglishAcronym(`G`, `grin`);
	learnEnglishAcronym(`G2B`,`going to bed`);
	learnEnglishAcronym(`G&BIT`, `grin & bear it`);
        learnEnglishAcronym(`G2G`, `got to go`);
        learnEnglishAcronym(`G2GGS2D`, `got to go get something to drink`);
	learnEnglishAcronym(`G2GTAC`, `got to go take a crap`);
        learnEnglishAcronym(`G2GTAP`, `got to go take a pee`);
	learnEnglishAcronym(`GA`, `go ahead`);
	learnEnglishAcronym(`GA`, `good afternoon`);
	learnEnglishAcronym(`GAFIA`, `get away from it all`);
	learnEnglishAcronym(`GAL`, `get a life`);
	learnEnglishAcronym(`GAS`, `greetings and salutations`);
	learnEnglishAcronym(`GBH`, `great big hug`);
	learnEnglishAcronym(`GBH&K`, `great big huh and kisses`);
	learnEnglishAcronym(`GBR`, `garbled beyond recovery`);
	learnEnglishAcronym(`GBY`, `god bless you`);
	learnEnglishAcronym(`GD`, `&H	grinning, ducking and hiding`);
	learnEnglishAcronym(`GD&R`, `grinning, ducking and running`);
	learnEnglishAcronym(`GD&RAFAP`, `grinning, ducking and running as fast as possible`);
	learnEnglishAcronym(`GD&REF&F`, `grinning, ducking and running even further and faster`);
	learnEnglishAcronym(`GD&RF`, `grinning, ducking and running fast`);
	learnEnglishAcronym(`GD&RVF`, `grinning, ducking and running very`);
	learnEnglishAcronym(`GD&W`, `grin, duck and wave`);
	learnEnglishAcronym(`GDW`, `grin, duck and wave`);
	learnEnglishAcronym(`GE`, `good evening`);
	learnEnglishAcronym(`GF`, `girlfriend`);
	learnEnglishAcronym(`GFETE`, `grinning from ear to ear`);
	learnEnglishAcronym(`GFN`, `gone for now`);
	learnEnglishAcronym(`GFU`, `good for you`);
	learnEnglishAcronym(`GG`, `good game`);
	learnEnglishAcronym(`GGU`, `good game you two`);
	learnEnglishAcronym(`GIGO`, `garbage in garbage out`);
	learnEnglishAcronym(`GJ`, `good job`);
	learnEnglishAcronym(`GL`, `good luck`);
	learnEnglishAcronym(`GL&GH`, `good luck and good hunting`);
	learnEnglishAcronym(`GM`, `good morning / good move / good match`);
	learnEnglishAcronym(`GMAB`, `give me a break`);
	learnEnglishAcronym(`GMAO`, `giggling my ass off`);
	learnEnglishAcronym(`GMBO`, `giggling my butt off`);
	learnEnglishAcronym(`GMTA`, `great minds think alike`);
	learnEnglishAcronym(`GN`, `good night`);
	learnEnglishAcronym(`GOK`, `god only knows`);
	learnEnglishAcronym(`GOWI`, `get on with it`);
	learnEnglishAcronym(`GPF`, `general protection fault`);
	learnEnglishAcronym(`GR8`, `great`);
	learnEnglishAcronym(`GR&D`, `grinning, running and ducking`);
	learnEnglishAcronym(`GtG`, `got to go`);
	learnEnglishAcronym(`GTSY`, `glad to see you`);

	learnEnglishAcronym(`H`, `hug`);
	learnEnglishAcronym(`H/O`, `hold on`);
	learnEnglishAcronym(`H&K`, `hug and kiss`);
	learnEnglishAcronym(`HAK`, `hug and kiss`);
	learnEnglishAcronym(`HAGD`, `have a good day`);
	learnEnglishAcronym(`HAGN`, `have a good night`);
	learnEnglishAcronym(`HAGS`, `have a good summer`);
	learnEnglishAcronym(`HAG1`, `have a good one`);
	learnEnglishAcronym(`HAHA`, `having a heart attack`);
	learnEnglishAcronym(`HAND`, `have a nice day`);
	learnEnglishAcronym(`HB`, `hug back`);
	learnEnglishAcronym(`HB`, `hurry back`);
	learnEnglishAcronym(`HDYWTDT`, `how do you work this dratted thing`);
	learnEnglishAcronym(`HF`, `have fun`);
	learnEnglishAcronym(`HH`, `holding hands`);
	learnEnglishAcronym(`HHIS`, `hanging head in shame`);
	learnEnglishAcronym(`HHJK`, `ha ha, just kidding`);
	learnEnglishAcronym(`HHOJ`, `ha ha, only joking`);
	learnEnglishAcronym(`HHOK`, `ha ha, only kidding`);
	learnEnglishAcronym(`HHOS`, `ha ha, only seriously`);
	learnEnglishAcronym(`HIH`, `hope it helps`);
	learnEnglishAcronym(`HILIACACLO`, `help I lapsed into a coma and can’t log off`);
	learnEnglishAcronym(`HIWTH`, `hate it when that happens`);
	learnEnglishAcronym(`HLM`, `he loves me`);
	learnEnglishAcronym(`HMS`, `home made smiley`);
	learnEnglishAcronym(`HMS`, `hanging my self`);
	learnEnglishAcronym(`HMT`, `here’s my try`);
	learnEnglishAcronym(`HMWK`, `homework`);
	learnEnglishAcronym(`HOAS`, `hold on a second`);
	learnEnglishAcronym(`HSIK`, `how should i know`);
	learnEnglishAcronym(`HTH`, `hope this helps`);
	learnEnglishAcronym(`HTHBE`, `hope this has been enlightening`);
	learnEnglishAcronym(`HYLMS`, `hate you like my sister`);

	learnEnglishAcronym(`IAAA`, `I am an accountant`);
	learnEnglishAcronym(`IAAL`, `I am a lawyer`);
	learnEnglishAcronym(`IAC`, `in any case`);
	learnEnglishAcronym(`IC`, `I see`);
	learnEnglishAcronym(`IAE`, `in any event`);
	learnEnglishAcronym(`IAG`, `it’s all good`);
	learnEnglishAcronym(`IAG`, `I am gay`);
	learnEnglishAcronym(`IAIM`, `in an Irish minute`);
	learnEnglishAcronym(`IANAA`, `I am not an accountant`);
	learnEnglishAcronym(`IANAL`, `I am not a lawyer`);
	learnEnglishAcronym(`IBN`, `I’m bucked naked`);
	learnEnglishAcronym(`ICOCBW`, `I could of course be wrong`);
	learnEnglishAcronym(`IDC`, `I don’t care`);
	learnEnglishAcronym(`IDGI`, `I don’t get it`);
	learnEnglishAcronym(`IDGARA`, `I don’t give a rat’s ass`);
	learnEnglishAcronym(`IDGW`, `in a good way`);
	learnEnglishAcronym(`IDI`, `I doubt it`);
	learnEnglishAcronym(`IDK`, `I don’t know`);
	learnEnglishAcronym(`IDTT`, `I’ll drink to that`);
	learnEnglishAcronym(`IFVB`, `I feel very bad`);
	learnEnglishAcronym(`IGP`, `I gotta pee`);
	learnEnglishAcronym(`IGTP`, `I get the point`);
	learnEnglishAcronym(`IHTFP`, `I hate this f**king place`);
	learnEnglishAcronym(`IHTFP`, `I have truly found paradise`);
	learnEnglishAcronym(`IHU`, `I hate you`);
	learnEnglishAcronym(`IHY`, `I hate you`);
	learnEnglishAcronym(`II`, `I’m impressed`);
	learnEnglishAcronym(`IIT`, `I’m impressed too`);
	learnEnglishAcronym(`IIR`, `if I recall`);
	learnEnglishAcronym(`IIRC`, `if I recall correctly`);
	learnEnglishAcronym(`IJWTK`, `I just want to know`);
	learnEnglishAcronym(`IJWTS`, `I just want to say`);
	learnEnglishAcronym(`IK`, `I know`);
	learnEnglishAcronym(`IKWUM`, `I know what you mean`);
	learnEnglishAcronym(`ILBCNU`, `I’ll be seeing you`);
	learnEnglishAcronym(`ILU`, `I love you`);
	learnEnglishAcronym(`ILY`, `I love you`);
	learnEnglishAcronym(`ILYFAE`, `I love you forever and ever`);
	learnEnglishAcronym(`IMAO`, `in my arrogant opinion`);
	learnEnglishAcronym(`IMFAO`, `in my f***ing arrogant opinion`);
	learnEnglishAcronym(`IMBO`, `in my bloody opinion`);
	learnEnglishAcronym(`IMCO`, `in my considered opinion`);
	learnEnglishAcronym(`IME`, `in my experience`);
	learnEnglishAcronym(`IMHO`, `in my humble opinion`);
	learnEnglishAcronym(`IMNSHO`, `in my, not so humble opinion`);
	learnEnglishAcronym(`IMO`, `in my opinion`);
	learnEnglishAcronym(`IMOBO`, `in my own biased opinion`);
	learnEnglishAcronym(`IMPOV`, `in my point of view`);
	learnEnglishAcronym(`IMP`, `I might be pregnant`);
	learnEnglishAcronym(`INAL`, `I’m not a lawyer`);
	learnEnglishAcronym(`INPO`, `in no particular order`);
	learnEnglishAcronym(`IOIT`, `I’m on Irish Time`);
	learnEnglishAcronym(`IOW`, `in other words`);
	learnEnglishAcronym(`IRL`, `in real life`);
	learnEnglishAcronym(`IRMFI`, `I reply merely for information`);
	learnEnglishAcronym(`IRSTBO`, `it really sucks the big one`);
	learnEnglishAcronym(`IS`, `I’m sorry`);
	learnEnglishAcronym(`ISEN`, `internet search environment number`);
	learnEnglishAcronym(`ISTM`, `it seems to me`);
	learnEnglishAcronym(`ISTR`, `I seem to recall`);
	learnEnglishAcronym(`ISWYM`, `I see what you mean`);
	learnEnglishAcronym(`ITFA`, `in the final analysis`);
	learnEnglishAcronym(`ITRO`, `in the reality of`);
	learnEnglishAcronym(`ITRW`, `in the real world`);
	learnEnglishAcronym(`ITSFWI`, `if the shoe fits, wear it`);
	learnEnglishAcronym(`IVL`, `in virtual live`);
	learnEnglishAcronym(`IWALY`, `I will always love you`);
	learnEnglishAcronym(`IWBNI`, `it would be nice if`);
	learnEnglishAcronym(`IYKWIM`, `if you know what I mean`);
	learnEnglishAcronym(`IYSWIM`, `if you see what I mean`);

	learnEnglishAcronym(`JAM`, `just a minute`);
	learnEnglishAcronym(`JAS`, `just a second`);
	learnEnglishAcronym(`JASE`, `just another system error`);
	learnEnglishAcronym(`JAWS`, `just another windows shell`);
	learnEnglishAcronym(`JIC`, `just in case`);
	learnEnglishAcronym(`JJWY`, `just joking with you`);
	learnEnglishAcronym(`JK`, `just kidding`);
	learnEnglishAcronym(`J/K`, `just kidding`);
	learnEnglishAcronym(`JMHO`, `just my humble opinion`);
	learnEnglishAcronym(`JMO`, `just my opinion`);
	learnEnglishAcronym(`JP`, `just playing`);
	learnEnglishAcronym(`J/P`, `just playing`);
	learnEnglishAcronym(`JTLYK`, `just to let you know`);
	learnEnglishAcronym(`JW`, `just wondering`);

	learnEnglishAcronym(`K`, `OK`);
	learnEnglishAcronym(`K`, `kiss`);
	learnEnglishAcronym(`KHYF`, `know how you feel`);
	learnEnglishAcronym(`KB`, `kiss back`);
	learnEnglishAcronym(`KISS`, `keep it simple sister`);
	learnEnglishAcronym(`KIS(S)`, `keep it simple (stupid)`);
	learnEnglishAcronym(`KISS`, `keeping it sweetly simple`);
	learnEnglishAcronym(`KIT`, `keep in touch`);
	learnEnglishAcronym(`KMA`, `kiss my ass`);
	learnEnglishAcronym(`KMB`, `kiss my butt`);
	learnEnglishAcronym(`KMSMA`, `kiss my shiny metal ass`);
	learnEnglishAcronym(`KOTC`, `kiss on the cheek`);
	learnEnglishAcronym(`KOTL`, `kiss on the lips`);
	learnEnglishAcronym(`KUTGW`, `keep up the good work`);
	learnEnglishAcronym(`KWIM`, `know what I mean?`);

	learnEnglishAcronym(`L`, `laugh`);
	learnEnglishAcronym(`L8R`, `later`);
	learnEnglishAcronym(`L8R`, `G8R	later gator`);
	learnEnglishAcronym(`LAB`, `life’s a bitch`);
	learnEnglishAcronym(`LAM`, `leave a message`);
	learnEnglishAcronym(`LBR`, `little boys room`);
	learnEnglishAcronym(`LD`, `long distance`);
	learnEnglishAcronym(`LIMH`, `laughing in my head`);
	learnEnglishAcronym(`LG`, `lovely greetings`);
	learnEnglishAcronym(`LIMH`, `laughing in my head`);
	learnEnglishAcronym(`LGR`, `little girls room`);
	learnEnglishAcronym(`LHM`, `Lord help me`);
	learnEnglishAcronym(`LHU`, `Lord help us`);
	learnEnglishAcronym(`LL&P`, `live long & prosper`);
	learnEnglishAcronym(`LNK`, `love and kisses`);
	learnEnglishAcronym(`LMA`, `leave me alone`);
	learnEnglishAcronym(`LMABO`, `laughing my ass back on`);
	learnEnglishAcronym(`LMAO`, `laughing my ass off`);
	learnEnglishAcronym(`MBO`, `laughing my butt off`);
	learnEnglishAcronym(`LMHO`, `laughing my head off`);
	learnEnglishAcronym(`LMFAO`, `laughing my fat ass off`);
	learnEnglishAcronym(`LMK`, `let me know`);
	learnEnglishAcronym(`LOL`, `laughing out loud`);
	learnEnglishAcronym(`LOL`, `lots of love`);
	learnEnglishAcronym(`LOL`, `lots of luck`);
	learnEnglishAcronym(`LOLA`, `laughing out loud again`);
	learnEnglishAcronym(`LOML`, `light of my life (or love of my life)`);
	learnEnglishAcronym(`LOMLILY`, `light of my life, I love you`);
	learnEnglishAcronym(`LOOL`, `laughing out outrageously loud`);
	learnEnglishAcronym(`LSHIPMP`, `laughing so hard I pissed my pants`);
	learnEnglishAcronym(`LSHMBB`, `laughing so hard my belly is bouncing`);
	learnEnglishAcronym(`LSHMBH`, `laughing so hard my belly hurts`);
	learnEnglishAcronym(`LTNS`, `long time no see`);
	learnEnglishAcronym(`LTR`, `long term relationship`);
	learnEnglishAcronym(`LTS`, `laughing to self`);
	learnEnglishAcronym(`LULAS`, `love you like a sister`);
	learnEnglishAcronym(`LUWAMH`, `love you with all my heart`);
	learnEnglishAcronym(`LY`, `love ya`);
	learnEnglishAcronym(`LYK`, `let you know`);
	learnEnglishAcronym(`LYL`, `love ya lots`);
	learnEnglishAcronym(`LYLAB`, `love ya like a brother`);
	learnEnglishAcronym(`LYLAS`, `love ya like a sister`);

	learnEnglishAcronym(`M`, `male`);
	learnEnglishAcronym(`MB`, `maybe`);
	learnEnglishAcronym(`MYOB`, `mind your own business`);
	learnEnglishAcronym(`M8`, `mate`);

	learnEnglishAcronym(`N`, `in`);
	learnEnglishAcronym(`N2M`, `not too much`);
	learnEnglishAcronym(`N/C`, `not cool`);
	learnEnglishAcronym(`NE1`, `anyone`);
	learnEnglishAcronym(`NETUA`, `nobody ever tells us anything`);
	learnEnglishAcronym(`NFI`, `no f***ing idea`);
	learnEnglishAcronym(`NL`, `not likely`);
	learnEnglishAcronym(`NM`, `never mind / nothing much`);
	learnEnglishAcronym(`N/M`, `never mind / nothing much`);
	learnEnglishAcronym(`NMH`, `not much here`);
	learnEnglishAcronym(`NMJC`, `nothing much, just chillin’`);
	learnEnglishAcronym(`NOM`, `no offense meant`);
	learnEnglishAcronym(`NOTTOMH`, `not of the top of my mind`);
	learnEnglishAcronym(`NOYB`, `none of your business`);
	learnEnglishAcronym(`NOYFB`, `none of your f***ing business`);
	learnEnglishAcronym(`NP`, `no problem`);
	learnEnglishAcronym(`NPS`, `no problem sweet(ie)`);
	learnEnglishAcronym(`NTA`, `non-technical acronym`);
	learnEnglishAcronym(`N/S`, `no shit`);
	learnEnglishAcronym(`NVM`, `nevermind`);

	learnEnglishAcronym(`OBTW`, `oh, by the way`);
	learnEnglishAcronym(`OIC`, `oh, I see`);
	learnEnglishAcronym(`OF`, `on fire`);
	learnEnglishAcronym(`OFIS`, `on floor with stitches`);
	learnEnglishAcronym(`OK`, `abbreviation of oll korrect (all correct)`);
	learnEnglishAcronym(`OL`, `old lady (wife, girlfriend)`);
	learnEnglishAcronym(`OM`, `old man (husband, boyfriend)`);
	learnEnglishAcronym(`OMG`, `oh my god / gosh / goodness`);
	learnEnglishAcronym(`OOC`, `out of character`);
	learnEnglishAcronym(`OT`, `Off topic / other topic`);
	learnEnglishAcronym(`OTOH`, `on the other hand`);
	learnEnglishAcronym(`OTTOMH`, `off the top of my head`);

	learnEnglishAcronym(`P@H`, `parents at home`);
	learnEnglishAcronym(`PAH`, `parents at home`);
	learnEnglishAcronym(`PAW`, `parents are watching`);
	learnEnglishAcronym(`PDS`, `please don’t shoot`);
	learnEnglishAcronym(`PEBCAK`, `problem exists between chair and keyboard`);
	learnEnglishAcronym(`PIZ`, `parents in room`);
	learnEnglishAcronym(`PLZ`, `please`);
	learnEnglishAcronym(`PM`, `private message`);
	learnEnglishAcronym(`PMJI`, `pardon my jumping in (Another way for PMFJI)`);
	learnEnglishAcronym(`PMFJI`, `pardon me for jumping in`);
	learnEnglishAcronym(`PMP`, `peed my pants`);
	learnEnglishAcronym(`POAHF`, `put on a happy face`);
	learnEnglishAcronym(`POOF`, `I have left the chat`);
	learnEnglishAcronym(`POTB`, `pats on the back`);
	learnEnglishAcronym(`POS`, `parents over shoulder`);
	learnEnglishAcronym(`PPL`, `people`);
	learnEnglishAcronym(`PS`, `post script`);
	learnEnglishAcronym(`PSA`, `public show of affection`);

	learnEnglishAcronym(`Q4U`, `question for you`);
	learnEnglishAcronym(`QSL`, `reply`);
	learnEnglishAcronym(`QSO`, `conversation`);
	learnEnglishAcronym(`QT`, `cutie`);

	learnEnglishAcronym(`RCed`, `reconnected`);
	learnEnglishAcronym(`RE`, `hi again (same as re’s)`);
	learnEnglishAcronym(`RME`, `rolling my eyses`);
	learnEnglishAcronym(`ROFL`, `rolling on floor laughing`);
	learnEnglishAcronym(`ROFLAPMP`, `rolling on floor laughing and peed my pants`);
	learnEnglishAcronym(`ROFLMAO`, `rolling on floor laughing my ass off`);
	learnEnglishAcronym(`ROFLOLAY`, `rolling on floor laughing out loud at you`);
	learnEnglishAcronym(`ROFLOLTSDMC`, `rolling on floor laughing out loud tears streaming down my cheeks`);
	learnEnglishAcronym(`ROFLOLWTIME`, `rolling on floor laughing out loud with tears in my eyes`);
	learnEnglishAcronym(`ROFLOLUTS`, `rolling on floor laughing out loud unable to speak`);
	learnEnglishAcronym(`ROTFL`, `rolling on the floor laughing`);
	learnEnglishAcronym(`RVD`, `really very dumb`);
	learnEnglishAcronym(`RUTTM`, `are you talking to me`);
	learnEnglishAcronym(`RTF`, `read the FAQ`);
	learnEnglishAcronym(`RTFM`, `read the f***ing manual`);
	learnEnglishAcronym(`RTSM`, `read the stupid manual`);

	learnEnglishAcronym(`S2R`, `send to receive`);
	learnEnglishAcronym(`SAMAGAL`, `stop annoying me and get a live`);
	learnEnglishAcronym(`SCNR`, `sorry, could not resist`);
	learnEnglishAcronym(`SETE`, `smiling ear to ear`);
	learnEnglishAcronym(`SH`, `so hot`);
	learnEnglishAcronym(`SH`, `same here`);
	learnEnglishAcronym(`SHICPMP`, `so happy I could piss my pants`);
	learnEnglishAcronym(`SHID`, `slaps head in disgust`);
	learnEnglishAcronym(`SHMILY`, `see how much I love you`);
	learnEnglishAcronym(`SNAFU`, `situation normal, all F***ed up`);
	learnEnglishAcronym(`SO`, `significant other`);
	learnEnglishAcronym(`SOHF`, `sense of humor failure`);
	learnEnglishAcronym(`SOMY`, `sick of me yet?`);
	learnEnglishAcronym(`SPAM`, `stupid persons’ advertisement`);
	learnEnglishAcronym(`SRY`, `sorry`);
	learnEnglishAcronym(`SSDD`, `same shit different day`);
	learnEnglishAcronym(`STBY`, `sucks to be you`);
	learnEnglishAcronym(`STFU`, `shut the f*ck up`);
	learnEnglishAcronym(`STI`, `stick(ing) to it`);
	learnEnglishAcronym(`STW`, `search the web`);
	learnEnglishAcronym(`SWAK`, `sealed with a kiss`);
	learnEnglishAcronym(`SWALK`, `sweet, with all love, kisses`);
	learnEnglishAcronym(`SWL`, `screaming with laughter`);
	learnEnglishAcronym(`SIM`, `shit, it’s Monday`);
	learnEnglishAcronym(`SITWB`, `sorry, in the wrong box`);
	learnEnglishAcronym(`S/U`, `shut up`);
	learnEnglishAcronym(`SYS`, `see you soon`);
	learnEnglishAcronym(`SYSOP`, `system operator`);

	learnEnglishAcronym(`TA`, `thanks again`);
	learnEnglishAcronym(`TCO`, `taken care of`);
	learnEnglishAcronym(`TGIF`, `thank god its Friday`);
	learnEnglishAcronym(`THTH`, `to hot to handle`);
	learnEnglishAcronym(`THX`, `thanks`);
	learnEnglishAcronym(`TIA`, `thanks in advance`);
	learnEnglishAcronym(`TIIC`, `the idiots in charge`);
	learnEnglishAcronym(`TJM`, `that’s just me`);
	learnEnglishAcronym(`TLA`, `three-letter acronym`);
	learnEnglishAcronym(`TMA`, `take my advice`);
	learnEnglishAcronym(`TMI`, `to much information`);
	learnEnglishAcronym(`TMS`, `to much showing`);
	learnEnglishAcronym(`TNSTAAFL`, `there’s no such thing as a free lunch`);
	learnEnglishAcronym(`TNX`, `thanks`);
	learnEnglishAcronym(`TOH`, `to other half`);
	learnEnglishAcronym(`TOY`, `thinking of you`);
	learnEnglishAcronym(`TPTB`, `the powers that be`);
	learnEnglishAcronym(`TSDMC`, `tears streaming down my cheeks`);
	learnEnglishAcronym(`TT2T`, `to tired to talk`);
	learnEnglishAcronym(`TTFN`, `ta ta for now`);
	learnEnglishAcronym(`TTT`, `thought that, too`);
	learnEnglishAcronym(`TTUL`, `talk to you later`);
	learnEnglishAcronym(`TTYIAM`, `talk to you in a minute`);
	learnEnglishAcronym(`TTYL`, `talk to you later`);
	learnEnglishAcronym(`TTYLMF`, `talk to you later my friend`);
	learnEnglishAcronym(`TU`, `thank you`);
	learnEnglishAcronym(`TWMA`, `till we meet again`);
	learnEnglishAcronym(`TX`, `thanx`);
	learnEnglishAcronym(`TY`, `thank you`);
	learnEnglishAcronym(`TYVM`, `thank you very much`);

	learnEnglishAcronym(`U2`, `you too`);
	learnEnglishAcronym(`UAPITA`, `you’re a pain in the ass`);
	learnEnglishAcronym(`UR`, `your`);
	learnEnglishAcronym(`UW`, `you’re welcom`);
	learnEnglishAcronym(`URAQT!`, `you are a cutie!`);

	learnEnglishAcronym(`VBG`, `very big grin`);
	learnEnglishAcronym(`VBS`, `very big smile`);

	learnEnglishAcronym(`W8`, `wait`);
	learnEnglishAcronym(`W8AM`, `wait a minute`);
	learnEnglishAcronym(`WAY`, `what about you`);
	learnEnglishAcronym(`WAY`, `who are you`);
	learnEnglishAcronym(`WB`, `welcome back`);
	learnEnglishAcronym(`WBS`, `write back soon`);
	learnEnglishAcronym(`WDHLM`, `why doesn’t he love me`);
	learnEnglishAcronym(`WDYWTTA`, `What Do You Want To Talk About`);
	learnEnglishAcronym(`WE`, `whatever`);
	learnEnglishAcronym(`W/E`, `whatever`);
	learnEnglishAcronym(`WFM`, `works for me`);
	learnEnglishAcronym(`WNDITWB`, `we never did it this way before`);
	learnEnglishAcronym(`WP`, `wrong person`);
	learnEnglishAcronym(`WRT`, `with respect to`);
	learnEnglishAcronym(`WTF`, `what/who the F***?`);
	learnEnglishAcronym(`WTG`, `way to go`);
	learnEnglishAcronym(`WTGP`, `want to go private?`);
	learnEnglishAcronym(`WTH`, `what/who the heck?`);
	learnEnglishAcronym(`WTMI`, `way to much information`);
	learnEnglishAcronym(`WU`, `what’s up?`);
	learnEnglishAcronym(`WUD`, `what’s up dog?`);
	learnEnglishAcronym(`WUF`, `where are you from?`);
	learnEnglishAcronym(`WUWT`, `whats up with that`);
	learnEnglishAcronym(`WYMM`, `will you marry me?`);
	learnEnglishAcronym(`WYSIWYG`, `what you see is what you get`);

	learnEnglishAcronym(`XTLA`, `extended three letter acronym`);

	learnEnglishAcronym(`Y`, `why?`);
	learnEnglishAcronym(`Y2K`, `you’re too kind`);
	learnEnglishAcronym(`YATB`, `you are the best`);
	learnEnglishAcronym(`YBS`, `you’ll be sorry`);
	learnEnglishAcronym(`YG`, `young gentleman`);
	learnEnglishAcronym(`YHBBYBD`, `you’d have better bet your bottom dollar`);
	learnEnglishAcronym(`YKYWTKM`, `you know you want to kiss me`);
	learnEnglishAcronym(`YL`, `young lady`);
	learnEnglishAcronym(`YL`, `you ’ll live`);
	learnEnglishAcronym(`YM`, `you mean`);
	learnEnglishAcronym(`YM`, `young man`);
	learnEnglishAcronym(`YMMD`, `you’ve made my day`);
	learnEnglishAcronym(`YMMV`, `your mileage may vary`);
	learnEnglishAcronym(`YVM`, `you’re very welcome`);
	learnEnglishAcronym(`YW`, `you’re welcome`);
	learnEnglishAcronym(`YWIA`, `you’re welcome in advance`);
	learnEnglishAcronym(`YWTHM`, `you want to hug me`);
	learnEnglishAcronym(`YWTLM`, `you want to love me`);
	learnEnglishAcronym(`YWTKM`, `you want to kiss me`);
	learnEnglishAcronym(`YOYO`, `you’re on your own`);
	learnEnglishAcronym(`YY4U`, `two wise for you`);

	learnEnglishAcronym(`?`, `huh?`);
	learnEnglishAcronym(`?4U`, `question for you`);
	learnEnglishAcronym(`>U`, `screw you!`);
	learnEnglishAcronym(`/myB`, `kick my boobs`);
	learnEnglishAcronym(`2U2`, `to you too`);
	learnEnglishAcronym(`2MFM`, `to much for me`);
	learnEnglishAcronym(`4AYN`, `for all you know`);
	learnEnglishAcronym(`4COL`, `for crying out loud`);
	learnEnglishAcronym(`4SALE`, `for sale`);
	learnEnglishAcronym(`4U`, `for you`);
	learnEnglishAcronym(`=w=`, `whatever`);
	learnEnglishAcronym(`*G*`, `giggle or grin`);
	learnEnglishAcronym(`*H*`, `hug`);
	learnEnglishAcronym(`*K*`, `kiss`);
	learnEnglishAcronym(`*S*`, `smile`);
	learnEnglishAcronym(`*T*`, `tickle`);
	learnEnglishAcronym(`*W*`, `wink`);

        // https://en.wikipedia.org/wiki/List_of_emoticons
        learnEnglishEmoticon([`:-)`, `:)`, `:)`, `:o)`, `:]`, `:3`, `:c)`, `:>`],
                             [`Smiley`, `Happy`]);
    }

    /** Learn English Irregular Verbs.
        TODO Move to irregular_verb.txt in format: bewas,werebeen
        TODO Merge with http://www.enchantedlearning.com/wordlist/irregularverbs.shtml
     */
    void learnEnglishIrregularVerbs()
    {
        learnEnglishIrregularVerb(`arise`, `arose`, `arisen`);
        learnEnglishIrregularVerb(`rise`, `rose`, `risen`);
        learnEnglishIrregularVerb(`wake`, [`woke`, `awaked`], `woken`);
        learnEnglishIrregularVerb(`be`, [`was`, `were`], `been`);
        learnEnglishIrregularVerb(`bear`, [`bore`, `born`], `borne`);
        learnEnglishIrregularVerb(`beat`, `beat`, `beaten`);
        learnEnglishIrregularVerb(`become`, `became`, `become`);
        learnEnglishIrregularVerb(`begin`, `began`, `begun`);
        learnEnglishIrregularVerb(`bend`, `bent`, `bent`);
        learnEnglishIrregularVerb(`bet`, `bet`, `bet`);
        learnEnglishIrregularVerb(`bid`, [`bid`, `bade`], [`bid`, `bidden`]);
        learnEnglishIrregularVerb(`bind`, `bound`, `bound`);
        learnEnglishIrregularVerb(`bite`, `bit`, `bitten`);
        learnEnglishIrregularVerb(`bleed`, `bled`, `bled`);
        learnEnglishIrregularVerb(`blow`, `blew`, `blown`);
        learnEnglishIrregularVerb(`break`, `broke`, `broken`);
        learnEnglishIrregularVerb(`breed`, `bred`, `bred`);
        learnEnglishIrregularVerb(`bring`, `brought`, `brought`);
        learnEnglishIrregularVerb(`build`, `built`, `built`);
        learnEnglishIrregularVerb(`burn`, [`burnt`, `burned`], [`burnt`, `burned`]);
        learnEnglishIrregularVerb(`burst`, `burst`, `burst`);
        learnEnglishIrregularVerb(`buy`, `bought`, `bought`);
        learnEnglishIrregularVerb(`cast`, `cast`, `cast`);
        learnEnglishIrregularVerb(`catch`, `caught`, `caught`);
        learnEnglishIrregularVerb(`choose`, `chose`, `chosen`);
        learnEnglishIrregularVerb(`come`, `came`, `come`);
        learnEnglishIrregularVerb(`cost`, `cost`, `cost`);
        learnEnglishIrregularVerb(`creep`, `crept`, `crept`);
        learnEnglishIrregularVerb(`cut`, `cut`, `cut`);
        learnEnglishIrregularVerb(`deal`, `dealt`, `dealt`);
        learnEnglishIrregularVerb(`dig`, `dug`, `dug`);
        learnEnglishIrregularVerb(`dive`, [`dived`, `dove`], `dived`);
        learnEnglishIrregularVerb(`do`, `did`, `done`);
        learnEnglishIrregularVerb(`draw`, `drew`, `drawn`);
        learnEnglishIrregularVerb(`dream`, [`dreamt`, `dreamed`], [`dreamt`, `dreamed`]);
        learnEnglishIrregularVerb(`drink`, `drank`, `drunk`);
        learnEnglishIrregularVerb(`drive`, `drove`, `driven`);
        learnEnglishIrregularVerb(`dwell`, `dwelt`, `dwelt`);
        learnEnglishIrregularVerb(`eat`, `ate`, `eaten`);
        learnEnglishIrregularVerb(`fall`, `fell`, `fallen`);
        learnEnglishIrregularVerb(`feed`, `fed`, `fed`);
        learnEnglishIrregularVerb(`fight`, `fought`, `fought`);
        learnEnglishIrregularVerb(`find`, `found`, `found`);
        learnEnglishIrregularVerb(`flee`, `fled`, `fled`);
        learnEnglishIrregularVerb(`fly`, `flew`, `flown`);
        learnEnglishIrregularVerb(`forbid`, [`forbade`, `forbad`], `forbidden`);
        learnEnglishIrregularVerb(`forget`, `forgot`, `forgotten`);
        learnEnglishIrregularVerb(`forgive`, `forgave`, `forgiven`);
        learnEnglishIrregularVerb(`forsake`, `forsook`, `forsaken`);
        learnEnglishIrregularVerb(`freeze`, `froze`, `frozen`);

        learnEnglishIrregularVerb(`get`, `got`, [`gotten`, `got`]);
        learnEnglishIrregularVerb(`give`, `gave`, `given`);
        learnEnglishIrregularVerb(`go`, `went`, `gone`);
        learnEnglishIrregularVerb(`grind`, `ground`, `ground`);
        learnEnglishIrregularVerb(`grow`, `grew`, `grown`);

        learnEnglishIrregularVerb(`hang`, [`hanged`, `hung`], [`hanged`, `hung`]);
        learnEnglishIrregularVerb(`have`, `had`, `had`);
        learnEnglishIrregularVerb(`hear`, `heard`, `heard`);
        learnEnglishIrregularVerb(`hide`, `hid`, `hidden`);
        learnEnglishIrregularVerb(`hit`, `hit`, `hit`);
        learnEnglishIrregularVerb(`hold`, `held`, `held`);
        learnEnglishIrregularVerb(`hurt`, `hurt`, `hurt`);

        learnEnglishIrregularVerb(`keep`, `kept`, `kept`);
        learnEnglishIrregularVerb(`kneel`, `knelt`, `knelt`);
        learnEnglishIrregularVerb(`knit`, [`knit`, `knitted`], [`knit`, `knitted`]);
        learnEnglishIrregularVerb(`know`, `knew`, `known`);

        learnEnglishIrregularVerb(`lay`, `laid`, `laid`);
        learnEnglishIrregularVerb(`lead`, `led`, `led`);

        learnEnglishIrregularVerb(`lean`, [`leaned`, `leant`], [`leaned`, `leant`]);
        learnEnglishIrregularVerb(`leap`, [`leaped`, `leapt`], [`leaped`, `leapt`]);

        learnEnglishIrregularVerb(`learn`, [`learned`, `learnt`], [`learned`, `learnt`]);
        learnEnglishIrregularVerb(`leave`, `left`, `left`);
        learnEnglishIrregularVerb(`lend`, `lent`, `lent`);
        learnEnglishIrregularVerb(`let`, `let`, `let`);
        learnEnglishIrregularVerb(`lie`, `lay`, `lain`);
        learnEnglishIrregularVerb(`light`, [`lighted`, `lit`], [`lighted`, `lit`]);
        learnEnglishIrregularVerb(`lose`, `lost`, `lost`);

        learnEnglishIrregularVerb(`make`, `made`, `made`);
        learnEnglishIrregularVerb(`mean`, `meant`, `meant`);
        learnEnglishIrregularVerb(`meet`, `met`, `met`);
        learnEnglishIrregularVerb(`mistake`, `mistook`, `mistaken`);

        learnEnglishIrregularVerb(`partake`, `partook`, `partaken`);
        learnEnglishIrregularVerb(`pay`, `paid`, `paid`);
        learnEnglishIrregularVerb(`put`, `put`, `put`);

        learnEnglishIrregularVerb(`read`, `read`, `read`);
        learnEnglishIrregularVerb(`rend`, `rent`, `rent`);
        learnEnglishIrregularVerb(`rid`, `rid`, `rid`);
        learnEnglishIrregularVerb(`ride`, `rode`, `ridden`);
        learnEnglishIrregularVerb(`run`, `ran`, `run`);

        learnEnglishIrregularVerb(`say`, `said`, `said`);
        learnEnglishIrregularVerb(`see`, `saw`, `seen`);
        learnEnglishIrregularVerb(`seek`, `sought`, `sought`);
        learnEnglishIrregularVerb(`sell`, `sold`, `sold`);
        learnEnglishIrregularVerb(`send`, `sent`, `sent`);
        learnEnglishIrregularVerb(`set`, `set`, `set`);
        learnEnglishIrregularVerb(`shake`, `shook`, `shaken`);
        learnEnglishIrregularVerb(`shed`, `shed`, `shed`);
        learnEnglishIrregularVerb(`shine`, `shone`, `shone`);
        learnEnglishIrregularVerb(`shoot`, `shot`, `shot`);
        learnEnglishIrregularVerb(`shrink`, `shrank`, `shrunk`);
        learnEnglishIrregularVerb(`shut`, `shut`, `shut`);
        learnEnglishIrregularVerb(`sing`, `sang`, `sung`);
        learnEnglishIrregularVerb(`sink`, `sank`, `sank`);
        learnEnglishIrregularVerb(`sit`, `sat`, `sat`);
        learnEnglishIrregularVerb(`slay`, `slew`, `slain`);
        learnEnglishIrregularVerb(`sleep`, `slept`, `slept`);
        learnEnglishIrregularVerb(`sling`, `slung`, `slung`);
        learnEnglishIrregularVerb(`slit`, `slit`, `slit`);
        learnEnglishIrregularVerb(`speak`, `spoke`, `spoken`);
        learnEnglishIrregularVerb(`spin`, `spun`, `spun`);
        learnEnglishIrregularVerb(`spit`, `spat`, `spat`);
        learnEnglishIrregularVerb(`split`, `split`, `split`);
        learnEnglishIrregularVerb(`spring`, `sprang`, `sprung`);
        learnEnglishIrregularVerb(`stand`, `stood`, `stood`);
        learnEnglishIrregularVerb(`steal`, `stole`, `stolen`);
        learnEnglishIrregularVerb(`stick`, `stuck`, `stuck`);
        learnEnglishIrregularVerb(`sting`, `stung`, `stung`);
        learnEnglishIrregularVerb(`stink`, `stank`, `stunk`);
        learnEnglishIrregularVerb(`stride`, `strode`, `stridden`);
        learnEnglishIrregularVerb(`strive`, `strove`, `striven`);
        learnEnglishIrregularVerb(`swear`, `swore`, `sworn`);
        learnEnglishIrregularVerb(`sweep`, `swept`, `swept`);
        learnEnglishIrregularVerb(`swim`, `swam`, `swum`);
        learnEnglishIrregularVerb(`swing`, `swung`, `swung`);

        learnEnglishIrregularVerb(`slide`, `slid`, [`slid`, `slidden`]);
        learnEnglishIrregularVerb(`speed`, [`sped`, `speeded`], [`sped`, `speeded`]);
        learnEnglishIrregularVerb(`tread`, `trod`, [`trodden`, `trod`]);

        learnEnglishIrregularVerb(`take`, `took`, `taken`);
        learnEnglishIrregularVerb(`teach`, `taught`, `taught`);
        learnEnglishIrregularVerb(`tear`, `tore`, `torn`);
        learnEnglishIrregularVerb(`tell`, `told`, `told`);
        learnEnglishIrregularVerb(`think`, `thought`, `thought`);
        learnEnglishIrregularVerb(`throw`, `threw`, `thrown`);

        learnEnglishIrregularVerb(`understand`, `understood`, `understood`);
        learnEnglishIrregularVerb(`upset`, `upset`, `upset`);

        learnEnglishIrregularVerb(`wear`, `wore`, `worn`);
        learnEnglishIrregularVerb(`weave`, `wove`, `woven`);
        learnEnglishIrregularVerb(`weep`, `wept`, `wept`);
        learnEnglishIrregularVerb(`win`, `won`, `won`);
        learnEnglishIrregularVerb(`wind`, `wound`, `wound`);
        learnEnglishIrregularVerb(`wring`, `wrung`, `wrung`);
        learnEnglishIrregularVerb(`write`, `wrote`, `written`);
    }

    void learnMath()
    {
        const origin = Origin.manual;

        connect(store(`π`, Lang.math, Sense.numberIrrational, origin),
                Role(Rel.translationOf),
                store(`pi`, Lang.en, Sense.numberIrrational, origin), // TODO other Langs?
                origin, 1.0);
        connect(store(`e`, Lang.math, Sense.numberIrrational, origin),
                Role(Rel.translationOf),
                store(`e`, Lang.en, Sense.numberIrrational, origin), // TODO other Langs?
                origin, 1.0);

        /// http://www.geom.uiuc.edu/~huberty/math5337/groupe/digits.html
        connect(store(`π`, Lang.math, Sense.numberIrrational, origin),
                Role(Rel.definedAs),
                store(`3.14159265358979323846264338327950288419716939937510`,
                      Lang.math, Sense.decimal, origin),
                origin, 1.0);

        connect(store(`e`, Lang.math, Sense.numberIrrational, origin),
                Role(Rel.definedAs),
                store(`2.71828182845904523536028747135266249775724709369995`,
                      Lang.math, Sense.decimal, origin),
                origin, 1.0);

        learnMto1(Lang.en, [`quaternary`, `quinary`, `senary`, `octal`, `decimal`, `duodecimal`, `vigesimal`, `quadrovigesimal`, `duotrigesimal`, `sexagesimal`, `octogesimal`],
                  Role(Rel.hasProperty, true), `counting system`, Sense.adjective, Sense.noun, 1.0);
    }

    void learnPunctuation()
    {
        const origin = Origin.manual;

        connect(store(`:`, Lang.unknown, Sense.punctuation, origin),
                Role(Rel.definedAs),
                store(`colon`,
                      Lang.en, Sense.noun, origin),
                origin, 1.0);

        connect(store(`;`, Lang.unknown, Sense.punctuation, origin),
                Role(Rel.definedAs),
                store(`semicolon`,
                      Lang.en, Sense.noun, origin),
                origin, 1.0);

        connectMto1(store([`,`, `،`, `、`], Lang.unknown, Sense.punctuation, origin),
                    Role(Rel.definedAs),
                    store(`comma`,
                          Lang.en, Sense.noun, origin),
                    origin, 1.0);

        connectMtoN(store([`/`, `⁄`], Lang.unknown, Sense.punctuation, origin),
                    Role(Rel.definedAs),
                    store([`slash`, `stroke`, `solidus`],
                          Lang.en, Sense.noun, origin),
                    origin, 1.0);

        connect(store(`-`, Lang.unknown, Sense.punctuation, origin),
                Role(Rel.definedAs),
                store(`hyphen`, Lang.en, Sense.noun, origin),
                origin, 1.0);

        connect(store(`-`, Lang.unknown, Sense.punctuation, origin),
                Role(Rel.definedAs),
                store(`hyphen-minus`, Lang.en, Sense.noun, origin),
                origin, 1.0);

        connect(store(`?`, Lang.unknown, Sense.punctuation, origin),
                Role(Rel.definedAs),
                store(`question mark`, Lang.en, Sense.noun, origin),
                origin, 1.0);

        connect(store(`!`, Lang.unknown, Sense.punctuation, origin),
                Role(Rel.definedAs),
                store(`exclamation mark`, Lang.en, Sense.noun, origin),
                origin, 1.0);

        connect1toM(store(`.`, Lang.unknown, Sense.punctuation, origin),
                    Role(Rel.definedAs),
                    store([`full stop`, `period`], Lang.en, Sense.noun, origin),
                    origin, 1.0);

        connectMto1(store([`’`, `'`], Lang.unknown, Sense.punctuation, origin),
                    Role(Rel.definedAs),
                    store(`apostrophe`, Lang.en, Sense.noun, origin),
                    origin, 1.0);

        connectMto1(store([`‒`, `–`, `—`, `―`], Lang.unknown, Sense.punctuation, origin),
                    Role(Rel.definedAs),
                    store(`dash`, Lang.en, Sense.noun, origin),
                    origin, 1.0);

        connectMto1(store([`‘’`, `“”`, `''`, `""`], Lang.unknown, Sense.punctuation, origin),
                    Role(Rel.definedAs),
                    store(`quotation marks`, Lang.en, Sense.noun, origin),
                    origin, 1.0);

        connectMto1(store([`…`, `...`], Lang.unknown, Sense.punctuation, origin),
                    Role(Rel.definedAs),
                    store(`ellipsis`, Lang.en, Sense.noun, origin),
                    origin, 1.0);

        connect(store(`()`, Lang.unknown, Sense.punctuation, origin),
                Role(Rel.definedAs),
                store(`parenthesis`, Lang.en, Sense.noun, origin),
                origin, 1.0);

        connect(store(`{}`, Lang.unknown, Sense.punctuation, origin),
                Role(Rel.definedAs),
                store(`curly braces`, Lang.en, Sense.noun, origin),
                origin, 1.0);

        connectMto1(store([`[]`, `()`, `{}`, `⟨⟩`], Lang.unknown, Sense.punctuation, origin),
                    Role(Rel.definedAs),
                    store(`brackets`, Lang.en, Sense.noun, origin),
                    origin, 1.0);

        learnNumerals();
    }

    // Learn Numerals (Groupings/Aggregates) (MÄngdmått)
    void learnNumerals()
    {
        const origin = Origin.manual;

        connect(store("single", Lang.en, Sense.numeral, origin),
                Role(Rel.definedAs),
                store("1", Lang.math, Sense.integer, origin),
                origin, 1.0);
        connect(store("pair", Lang.en, Sense.numeral, origin),
                Role(Rel.definedAs),
                store("2", Lang.math, Sense.integer, origin),
                origin, 1.0);
        connect(store("duo", Lang.en, Sense.numeral, origin),
                Role(Rel.definedAs),
                store("2", Lang.math, Sense.integer, origin),
                origin, 1.0);
        connect(store("triple", Lang.en, Sense.numeral, origin),
                Role(Rel.definedAs),
                store("3", Lang.math, Sense.integer, origin),
                origin, 1.0);
        connect(store("quadruple", Lang.en, Sense.numeral, origin),
                Role(Rel.definedAs),
                store("4", Lang.math, Sense.integer, origin),
                origin, 1.0);
        connect(store("quintuple", Lang.en, Sense.numeral, origin),
                Role(Rel.definedAs),
                store("5", Lang.math, Sense.integer, origin),
                origin, 1.0);
        connect(store("sextuple", Lang.en, Sense.numeral, origin),
                Role(Rel.definedAs),
                store("6", Lang.math, Sense.integer, origin),
                origin, 1.0);
        connect(store("septuple", Lang.en, Sense.numeral, origin),
                Role(Rel.definedAs),
                store("7", Lang.math, Sense.integer, origin),
                origin, 1.0);

        // Greek Numbering
        // TODO Also Latin?
        connect(store("tetra", Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                store("4", Lang.math, Sense.integer, origin), origin, 1.0);
        connect(store("penta", Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                store("5", Lang.math, Sense.integer, origin), origin, 1.0);
        connect(store("hexa", Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                store("6", Lang.math, Sense.integer, origin), origin, 1.0);
        connect(store("hepta", Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                store("7", Lang.math, Sense.integer, origin), origin, 1.0);
        connect(store("octa", Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                store("8", Lang.math, Sense.integer, origin), origin, 1.0);
        connect(store("nona", Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                store("9", Lang.math, Sense.integer, origin), origin, 1.0);
        connect(store("deca", Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                store("10", Lang.math, Sense.integer, origin), origin, 1.0);
        connect(store("hendeca", Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                store("11", Lang.math, Sense.integer, origin), origin, 1.0);
        connect(store("dodeca", Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                store("12", Lang.math, Sense.integer, origin), origin, 1.0);
        connect(store("trideca", Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                store("13", Lang.math, Sense.integer, origin), origin, 1.0);
        connect(store("tetradeca", Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                store("14", Lang.math, Sense.integer, origin), origin, 1.0);
        connect(store("pentadeca", Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                store("15", Lang.math, Sense.integer, origin), origin, 1.0);
        connect(store("hexadeca", Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                store("16", Lang.math, Sense.integer, origin), origin, 1.0);
        connect(store("heptadeca", Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                store("17", Lang.math, Sense.integer, origin), origin, 1.0);
        connect(store("octadeca", Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                store("18", Lang.math, Sense.integer, origin), origin, 1.0);
        connect(store("enneadeca", Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                store("19", Lang.math, Sense.integer, origin), origin, 1.0);
        connect(store("icosa", Lang.el, Sense.numeral, origin), Role(Rel.definedAs),
                store("20", Lang.math, Sense.integer, origin), origin, 1.0);

        learnEnglishOrdinalShorthands();
        learnSwedishOrdinalShorthands();

        // Aggregate
        connect(store("dozen", Lang.en, Sense.numeral, origin),
                Role(Rel.definedAs),
                store("12", Lang.math, Sense.integer, origin),
                origin, 1.0);
        connect(store("baker's dozen", Lang.en, Sense.numeral, origin),
                Role(Rel.definedAs),
                store("13", Lang.math, Sense.integer, origin),
                origin, 1.0);
        connect(store("tjog", Lang.sv, Sense.numeral, origin),
                Role(Rel.definedAs),
                store("20", Lang.math, Sense.integer, origin),
                origin, 1.0);
        connect(store("flak", Lang.sv, Sense.numeral, origin),
                Role(Rel.definedAs),
                store("24", Lang.math, Sense.integer, origin),
                origin, 1.0);
        connect(store("skock", Lang.sv, Sense.numeral, origin),
                Role(Rel.definedAs),
                store("60", Lang.math, Sense.integer, origin),
                origin, 1.0);

        connectMto1(store(["dussin", "tolft"], Lang.sv, Sense.numeral, origin),
                    Role(Rel.definedAs),
                    store("12", Lang.math, Sense.integer, origin),
                    origin, 1.0);

        connect(store("gross", Lang.en, Sense.numeral, origin),
                Role(Rel.definedAs),
                store("144", Lang.math, Sense.integer, origin),
                origin, 1.0);
        connect(store("gross", Lang.sv, Sense.numeral, origin), // TODO Support [Lang.en, Lang.sv]
                Role(Rel.definedAs),
                store("144", Lang.math, Sense.integer, origin),
                origin, 1.0);

        connect(store("small gross", Lang.en, Sense.numeral, origin),
                Role(Rel.definedAs),
                store("120", Lang.math, Sense.integer, origin),
                origin, 1.0);

        connect(store("great gross", Lang.en, Sense.numeral, origin),
                Role(Rel.definedAs),
                store("1728", Lang.math, Sense.integer, origin),
                origin, 1.0);

    }

    /** Learn English Ordinal Shorthands.
     */
    void learnEnglishOrdinalShorthands()
    {
        const pairs = [tuple("1st", "first"),
                       tuple("2nd", "second"),
                       tuple("3rd", "third"),
                       tuple("4th", "fourth"),
                       tuple("5th", "fifth"),
                       tuple("6th", "sixth"),
                       tuple("7th", "seventh"),
                       tuple("8th", "eighth"),
                       tuple("9th", "ninth"),
                       tuple("10th", "tenth"),
                       tuple("11th", "eleventh"),
                       tuple("12th", "twelfth"),
                       tuple("13th", "thirteenth"),
                       tuple("14th", "fourteenth"),
                       tuple("15th", "fifteenth"),
                       tuple("16th", "sixteenth"),
                       tuple("17th", "seventeenth"),
                       tuple("18th", "eighteenth"),
                       tuple("19th", "nineteenth"),
                       tuple("20th", "twentieth"),
                       tuple("21th", "twenty-first"),
                       tuple("30th", "thirtieth"),
                       tuple("40th", "fourtieth"),
                       tuple("50th", "fiftieth"),
                       tuple("60th", "sixtieth"),
                       tuple("70th", "seventieth"),
                       tuple("80th", "eightieth"),
                       tuple("90th", "ninetieth"),
                       tuple("100th", "one hundredth"),
                       tuple("1000th", "one thousandth"),
                       tuple("1000000th", "one millionth"),
                       tuple("1000000000th", "one billionth")];
        foreach (pair; pairs)
        {
            connect(store(pair[0], Lang.sv, Sense.numeralOrdinal, Origin.manual), Role(Rel.abbreviationFor),
                    store(pair[1], Lang.sv, Sense.numeralOrdinal, Origin.manual), Origin.manual, 1.0);
        }
    }

    /** Learn Swedish Ordinal Shorthands.
     */
    void learnSwedishOrdinalShorthands()
    {
        const pairs = [tuple("1:a", "första"),
                       tuple("2:a", "andra"),
                       tuple("3:a", "tredje"),
                       tuple("4:e", "fjärde"),
                       tuple("5:e", "femte"),
                       tuple("6:e", "sjätte"),
                       tuple("7:e", "sjunde"),
                       tuple("8:e", "åttonde"),
                       tuple("9:e", "nionde"),
                       tuple("10:e", "tionde"),
                       tuple("11:e", "elfte"),
                       tuple("12:e", "tolfte"),
                       tuple("13:e", "trettonde"),
                       tuple("14:e", "fjortonde"),
                       tuple("15:e", "femtonde"),
                       tuple("16:e", "sextonde"),
                       tuple("17:e", "sjuttonde"),
                       tuple("18:e", "artonde"),
                       tuple("19:e", "nittonde"),
                       tuple("20:e", "tjugonde"),
                       tuple("21:a", "tjugoförsta"),
                       tuple("22:a", "tjugoandra"),
                       tuple("23:e", "tjugotredje"),
                       // ..
                       tuple("30:e", "trettionde"),
                       tuple("40:e", "fyrtionde"),
                       tuple("50:e", "femtionde"),
                       tuple("60:e", "sextionde"),
                       tuple("70:e", "sjuttionde"),
                       tuple("80:e", "åttionde"),
                       tuple("90:e", "nittionde"),
                       tuple("100:e", "hundrade"),
                       tuple("1000:e", "tusende"),
                       tuple("1000000:e", "miljonte")];
        foreach (pair; pairs)
        {
            connect(store(pair[0], Lang.sv, Sense.numeralOrdinal, Origin.manual), Role(Rel.abbreviationFor),
                    store(pair[1], Lang.sv, Sense.numeralOrdinal, Origin.manual), Origin.manual, 1.0);
        }
    }

    /** Learn Math.
     */
    void learnPhysics()
    {
        learnMto1(Lang.en, rdT("../knowledge/en/si_base_unit_name.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `SI base unit name noun`, Sense.baseSIUnit, Sense.noun, 1.0);
        // TODO Name Symbol, Quantity, In SI units, In Si base units
        learnMto1(Lang.en, rdT("../knowledge/en/si_derived_unit_name.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `SI derived unit name noun`, Sense.derivedSIUnit, Sense.noun, 1.0);
    }

    void learnComputers()
    {
        learnMto1(Lang.en, rdT("../knowledge/en/programming_language.txt").splitter('\n').filter!(w => !w.empty), Role(Rel.isA), `programming language`, Sense.languageProgramming, Sense.language, 1.0);
    }

    /** Learn English Irregular Verbs.
     */
    void learnEnglishOther()
    {
        connectMto1(store(["preserve food",
                           "cure illness",
                           "augment cosmetics"],
                          Lang.en, Sense.noun, Origin.manual),
                    Role(Rel.uses),
                    store("herb", Lang.en, Sense.noun, Origin.manual),
                    Origin.manual, 1.0);

        connectMto1(store(["enrich taste of food",
                           "improve taste of food",
                           "increase taste of food"],
                          Lang.en, Sense.noun, Origin.manual),
                    Role(Rel.uses),
                    store("spice", Lang.en, Sense.noun, Origin.manual),
                    Origin.manual, 1.0);

        connect1toM(store("herb", Lang.en, Sense.noun, Origin.manual),
                    Role(Rel.madeOf),
                    store(["leaf", "plant"], Lang.en, Sense.noun, Origin.manual),
                    Origin.manual, 1.0);

        connect1toM(store("spice", Lang.en, Sense.noun, Origin.manual),
                    Role(Rel.madeOf),
                    store(["root", "plant"], Lang.en, Sense.noun, Origin.manual),
                    Origin.manual, 1.0);
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
        const origin = Origin.manual;
        auto all = [tryStore(imperative, lang, Sense.verbImperative, origin),
                    tryStore(infinitive, lang, Sense.verbInfinitive, origin),
                    tryStore(present, lang, Sense.verbPresent, origin),
                    tryStore(past, lang, Sense.verbPast, origin),
                    tryStore(pastParticiple, lang, Sense.verbPastParticiple, origin)];
        connectAll(Role(Rel.formOfVerb), all.filter!(a => a.defined), lang, origin);
    }

    /** Learn Swedish (Irregular) Verbs.
    */
    void learnSwedishIrregularVerbs()
    {
        learnSwedishIrregularVerb(`eka`, `eka`, `ekar`, `ekade`, `ekat`); // English:echo
        learnSwedishIrregularVerb(`ge`, `ge`, `ger`, `gav`, `gett/givit`);
        learnSwedishIrregularVerb(`ange`, `ange`, `anger`, `angav`, `angett/angivit`);
        learnSwedishIrregularVerb(`anse`, `anse`, `anser`, `ansåg`, `ansett`);
        learnSwedishIrregularVerb(`avgör`, `avgöra`, `avgör`, `avgjorde`, `avgjort`);
        learnSwedishIrregularVerb(`avstå`, `avstå`, `avstår`, `avstod`, `avstått`);
        learnSwedishIrregularVerb(`be`, `be`, `ber`, `bad`, `bett`);
        learnSwedishIrregularVerb(`bestå`, `bestå`, `består`, `bestod`, `bestått`);
        learnSwedishIrregularVerb([], [], `bör`, `borde`, `bort`);
        learnSwedishIrregularVerb(`dra`, `dra`, `drar`, `drog`, `dragit`);
        learnSwedishIrregularVerb([], `duga`, `duger`, `dög/dugde`, `dugit`);
        learnSwedishIrregularVerb(`dyk`, `dyka`, `dyker`, `dök/dykte`, `dykit`);
        learnSwedishIrregularVerb(`dö`, `dö`, `dör`, `dog`, `dött`);
        learnSwedishIrregularVerb(`dölj`, `dölja`, `döljer`, `dolde`, `dolt`);
        learnSwedishIrregularVerb(`ersätt`, `ersätta`, `ersätter`, `ersatte`, `ersatt`);
        learnSwedishIrregularVerb(`fortsätt`, `fortsätta`, `fortsätter`, `fortsatte`, `fortsatt`);
        learnSwedishIrregularVerb(`framstå`, `framstå`, `framstår`, `framstod`, `framstått`);
        learnSwedishIrregularVerb(`få`, `få`, `får`, `fick`, `fått`);
        learnSwedishIrregularVerb(`förstå`, `förstå`, `förstår`, `förstod`, `förstått`);
        learnSwedishIrregularVerb(`förutsätt`, `förutsätta`, `förutsätter`, `förutsatte`, `förutsatt`);
        learnSwedishIrregularVerb(`gläd`, `glädja`, `gläder`, `gladde`, `glatt`);
        learnSwedishIrregularVerb(`gå`, `gå`, `går`, `gick`, `gått`);
        learnSwedishIrregularVerb(`gör`, `göra`, `gör`, `gjorde`, `gjort`);
        learnSwedishIrregularVerb(`ha`, `ha`, `har`, `hade`, `haft`);
        learnSwedishIrregularVerb([], `heta`, `heter`, `hette`, `hetat`);
        learnSwedishIrregularVerb([], `ingå`, `ingår`, `ingick`, `ingått`);
        learnSwedishIrregularVerb(`inse`, `inse`, `inser`, `insåg`, `insett`);
        learnSwedishIrregularVerb(`kom`, `komma`, `kommer`, `kom`, `kommit`);
        learnSwedishIrregularVerb([], `kunna`, `kan`, `kunde`, `kunnat`);
        learnSwedishIrregularVerb(`le`, `le`, `ler`, `log`, `lett`);
        learnSwedishIrregularVerb(`lev`, `leva`, `lever`, `levde`, `levt`);
        learnSwedishIrregularVerb(`ligg`, `ligga`, `ligger`, `låg`, `legat`);
        learnSwedishIrregularVerb(`lägg`, `lägga`, `lägger`, `la`, `lagt`);
        learnSwedishIrregularVerb(`missförstå`, `missförstå`, `missförstår`, `missförstod`, `missförstått`);
        learnSwedishIrregularVerb([], [], `måste`, `var tvungen`, `varit tvungen`);
        learnSwedishIrregularVerb(`se`, `se`, `ser`, `såg`, `sett`);
        learnSwedishIrregularVerb(`skilj`, `skilja`, `skiljer`, `skilde`, `skilt`);
        learnSwedishIrregularVerb([], [], `ska`, `skulle`, []);
        learnSwedishIrregularVerb(`smaksätt`, `smaksätta`, `smaksätter`, `smaksatte`, `smaksatt`);
        learnSwedishIrregularVerb(`sov`, `sova`, `sover`, `sov`, `sovit`);
        learnSwedishIrregularVerb(`sprid`, `sprida`, `sprider`, `spred`, `spridit`);
        learnSwedishIrregularVerb(`stjäl`, `stjäla`, `stjäl`, `stal`, `stulit`);
        learnSwedishIrregularVerb(`stå`, `stå`, `står`, `stod`, `stått`);
        learnSwedishIrregularVerb(`stöd`, `stödja`, `stöder`, `stödde`, `stött`);
        learnSwedishIrregularVerb(`svälj`, `svälja`, `sväljer`, `svalde`, `svalt`);
        learnSwedishIrregularVerb(`säg`, `säga`, `säger`, `sa`, `sagt`);
        learnSwedishIrregularVerb(`sälj`, `sälja`, `säljer`, `sålde`, `sålt`);
        learnSwedishIrregularVerb(`sätt`, `sätta`, `sätter`, `satte`, `satt`);
        learnSwedishIrregularVerb(`ta`, `ta`, `tar`, `tog`, `tagit`);
        learnSwedishIrregularVerb(`tillsätt`, `tillsätta`, `tillsätter`, `tillsatte`, `tillsatt`);
        learnSwedishIrregularVerb(`umgås`, `umgås`, `umgås`, `umgicks`, `umgåtts`);
        learnSwedishIrregularVerb(`uppge`, `uppge`, `uppger`, `uppgav`, `uppgivit`);
        learnSwedishIrregularVerb(`utgå`, `utgå`, `utgår`, `utgick`, `utgått`);
        learnSwedishIrregularVerb(`var`, `vara`, `är`, `var`, `varit`);
        learnSwedishIrregularVerb([], `veta`, `vet`, `visste`, `vetat`);
        learnSwedishIrregularVerb(`vik`, `vika`, `viker`, `vek`, `vikt`);
        learnSwedishIrregularVerb([], `vilja`, `vill`, `ville`, `velat`);
        learnSwedishIrregularVerb(`välj`, `välja`, `väljer`, `valde`, `valt`);
        learnSwedishIrregularVerb(`vänj`, `vänja`, `vänjer`, `vande`, `vant`);
        learnSwedishIrregularVerb(`väx`, `växa`, `växer`, `växte`, `växt`);
        learnSwedishIrregularVerb(`återge`, `återge`, `återger`, `återgav`, `återgivit`);
        learnSwedishIrregularVerb(`översätt`, `översätta`, `översätter`, `översatte`, `översatt`);
        learnSwedishIrregularVerb(`tyng`, `tynga`, `tynger`, `tyngde`, `tyngt`);
        learnSwedishIrregularVerb(`glöm`, `glömma`, `glömmer`, `glömde`, `glömt`);
        learnSwedishIrregularVerb(`förgät`, `förgäta`, `förgäter`, `förgat`, `förgätit`);

        // TODO Allow alternatives for all arguments
        static if (false)
        {
            learnSwedishIrregularVerb(`ids`, `idas`, [`ids`, `ides`], `iddes`, [`itts`, `idats`]);
            learnSwedishIrregularVerb(`gitt`, `gitta;1`, `gitter`, [`gitte`, `get`, `gat`], `gittat;1`);
        }

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
        connectAll(Role(Rel.formOfAdjective), all.filter!(a => a.defined), lang, origin);
    }

    void learnAdjective(S)(Lang lang,
                           S[3] forms) if (isSomeString!S)
    {
        return learnAdjective(lang, forms[0], forms[1], forms[2]);
    }


    /** Learn Swedish Adjectives.
     */
    void learnSwedishAdjectives()
    {
        enum lang = Lang.sv;
        learnAdjective(lang, "tung", "tyngre", "tyngst");
        learnAdjective(lang, "få", "färre", "färst");
        learnAdjective(lang, "många", "fler", "flest");
        learnAdjective(lang, "bra", "bättre", "bäst");
        learnAdjective(lang, "dålig", "sämre", "sämst");
        learnAdjective(lang, "liten", "mindre", "minst");
        learnAdjective(lang, "gammal", "äldre", "äldst");
        learnAdjective(lang, "hög", "högre", "högst");
        learnAdjective(lang, "låg", "lägre", "lägst");
        learnAdjective(lang, "lång", "längre", "längst");
        learnAdjective(lang, "stor", "större", "störst");
        learnAdjective(lang, "tung", "tyngre", "tyngst");
        learnAdjective(lang, "ung", "yngre", "yngst");
        learnAdjective(lang, "mycket", "mer", "mest");
        learnAdjective(lang, "gärna", "hellre", "helst");
    }

    /** Learn English Adjectives.
     */
    void learnEnglishAdjectives()
    {
        const lang = Lang.en;
        connectMto1(store([`ablaze`, `abreast`, `afire`, `afloat`, `afraid`, `aghast`, `aglow`,
                           `alert`, `alike`, `alive`, `alone`, `aloof`, `ashamed`, `asleep`,
                           `awake`, `aware`, `fond`, `unaware`],
                          lang, Sense.adjectivePredicateOnly, Origin.manual),
                    Role(Rel.isA),
                    store("predicate only adjective",
                          lang, Sense.noun, Origin.manual),
                    Origin.manual);
    }

    /** Learn Swedish Grammar.
     */
    void learnSwedishGrammar()
    {
        enum lang = Lang.sv;
        connectMto1(store(["grundform", "genitiv"], lang, Sense.noun, Origin.manual),
                    Role(Rel.isA),
                    store("kasus", lang, Sense.noun, Origin.manual),
                    Origin.manual);
        connectMto1(store(["reale", "neutrum"], lang, Sense.noun, Origin.manual),
                    Role(Rel.isA),
                    store("genus", lang, Sense.noun, Origin.manual),
                    Origin.manual);
    }

    /** Lookup-or-Store $(D Node) named $(D expr) in language $(D lang). */
    Nd store(Expr expr,
             Lang lang,
             Sense sense,
             Origin origin,
             ContextIx context = ContextIx.asUndefined) in { assert(!expr.empty); }
    body
    {
        auto lemma = Lemma(expr, lang, sense, context);
        if (lemma in nodeRefByLemma)
        {
            return nodeRefByLemma[lemma]; // lookup
        }
        else
        {
            const specializedLemma = learnLemma(lemma);
            if (specializedLemma != lemma) // if an existing more specialized lemma was found
            {
                return nodeRefByLemma[specializedLemma];
            }

            auto wordsSplit = lemma.expr.findSplit(expressionWordSeparator);
            if (!wordsSplit[1].empty) // TODO add implicit bool conversion to return of findSplit()
            {
                ++multiWordNodeLemmaCount;
                exprWordCountSum += max(0, lemma.expr.count(expressionWordSeparator) - 1);
            }

            // store
            assert(allNodes.length <= nullIx);
            const cix = Nd(cast(Ix)allNodes.length);
            allNodes ~= Node(lemma, origin); // .. new node that is stored

            nodeRefByLemma[lemma] = cix; // store index to ..
            nodeStringLengthSum += lemma.expr.length;

            ++nodeCountByLang[lemma.lang];
            ++nodeCountBySense[lemma.sense];

            return cix;
        }
    }

    /** Try to Lookup-or-Store $(D Node) named $(D expr) in language $(D lang).
     */
    Nd tryStore(Expr expr,
                Lang lang,
                Sense sense,
                Origin origin,
                ContextIx context = ContextIx.asUndefined)
    {
        if (expr.empty)
            return Nd.asUndefined;
        return store(expr, lang, sense, origin, context);
    }

    Nd[] store(Exprs)(Exprs exprs,
                      Lang lang,
                      Sense sense,
                      Origin origin,
                      ContextIx context = ContextIx.asUndefined) if (isIterable!Exprs)
    {
        typeof(return) nodeRefs;
        foreach (expr; exprs)
        {
            nodeRefs ~= store(expr, lang, sense, origin, context);
        }
        return nodeRefs;
    }

    /** Directed Connect Many Sources $(D srcs) to Many Destinations $(D dsts).
     */
    Ln[] connectMtoN(S, D)(S srcs,
                           Role role,
                           D dsts,
                           Origin origin,
                           NWeight weight = 1.0,
                           bool checkExisting = false) if (isIterableOf!(S, Nd) &&
                                                           isIterableOf!(D, Nd))
    {
        typeof(return) linkIxes;
        foreach (src; srcs)
        {
            foreach (dst; dsts)
            {
                linkIxes ~= connect(src, role, dst, origin, weight, checkExisting);
            }
        }
        return linkIxes;
    }
    alias connectFanInFanOut = connectMtoN;

    /** Fully Connect Every-to-Every in $(D all).
        See also: http://forum.dlang.org/thread/iqkybajwdzcvdytakgvw@forum.dlang.org#post-iqkybajwdzcvdytakgvw:40forum.dlang.org
        See also: https://issues.dlang.org/show_bug.cgi?id=6788
    */
    Ln[] connectAll(R)(Role role,
                       R all,
                       Lang lang,
                       Origin origin,
                       NWeight weight = 1.0) if (isIterableOf!(R, Nd))
        in { assert(role.rel.isSymmetric); }
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
                linkIxes ~= connect(me, role, you, origin, weight);
                ++j;
            }
            ++i;
        }
        return linkIxes;
    }
    alias connectMtoM = connectAll;
    alias connectFully = connectAll;
    alias connectStar = connectAll;

    /** Fan-Out Connect $(D first) to Every in $(D rest). */
    Ln[] connect1toM(R)(Nd first,
                        Role role,
                        R rest,
                        Origin origin, NWeight weight = 1.0) if (isIterableOf!(R, Nd))
    {
        typeof(return) linkIxes;
        foreach (you; rest)
        {
            if (first != you)
            {
                linkIxes ~= connect(first, role, you, origin, weight, false);
            }
        }
        return linkIxes;
    }
    alias connectFanOut = connect1toM;

    /** Fan-In Connect $(D first) to Every in $(D rest). */
    Ln[] connectMto1(R)(R rest,
                        Role role,
                        Nd first,
                        Origin origin, NWeight weight = 1.0) if (isIterableOf!(R, Nd))
    {
        typeof(return) linkIxes;
        foreach (you; rest)
        {
            if (first != you)
            {
                linkIxes ~= connect(you, role, first, origin, weight);
            }
        }
        return linkIxes;
    }
    alias connectFanIn = connectMto1;

    /** Cyclic Connect Every in $(D all). */
    void connectCycle(R)(Rel rel, R all) if (isIterableOf!(R, Nd))
    {
    }
    alias connectCircle = connectCycle;

    /** Add Link from $(D src) to $(D dst) of type $(D rel) and weight $(D weight).
        TODO checkExisting is currently set to false because searching
        existing links is currently too slow
     */
    Ln connect(Nd src,
               Role role,
               Nd dst,
               Origin origin = Origin.unknown,
               NWeight weight = 1.0, // 1.0 means absolutely true for Origin manual
               bool checkExisting = false) in {
        assert(src != dst,
               at(src).lemma.expr ~
               " must not be equal to " ~
               at(dst).lemma.expr);
    }
    body
    {
        if (src == dst) { return Ln.asUndefined; } // Don't allow self-reference for now

        if (checkExisting)
        {
            if (auto existingIx = areConnected(src, role, dst, origin, weight))
            {
                if (false)
                {
                    dln("warning: Nodes ",
                        at(src).lemma.expr, " and ",
                        at(dst).lemma.expr, " already related as ",
                        role.rel);
                }
                return existingIx;
            }
        }

        // TODO group these
        assert(allLinks.length <= nullIx);
        auto ln = Ln(cast(Ix)allLinks.length);

        auto link = Link(role.reversion ? dst : src,
                         Role(role.rel, false, role.negation),
                         role.reversion ? src : dst,
                         origin);

        linkConnectednessSum += 2;

        at(src).links ~= ln.forward;
        at(dst).links ~= ln.backward;
        nodeConnectednessSum += 2;

        symmetricRelCount += role.rel.isSymmetric;
        transitiveRelCount += role.rel.isTransitive;
        ++relCounts[role.rel];
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
            dln(" src:", at(src).lemma.expr,
                " dst:", at(dst).lemma.expr,
                " rel:", role.rel,
                " origin:", origin,
                " negation:", role.negation,
                " reversion:", role.reversion);
        }

        allLinks ~= link; // TODO Avoid copying here

        return ln; // allLinks.back;"
    }
    alias relate = connect;

    /** Read ConceptNet5 URI.
        See also: https://github.com/commonsense/conceptnet5/wiki/URI-hierarchy-5.0
    */
    Nd readCN5ConceptURI(T)(const T part)
    {
        auto items = part.splitter('/');

        const lang = items.front.decodeLang; items.popFront;

        static if (useRCString) { immutable expr = items.front.replace("_", " "); }
        else                    { immutable expr = items.front.replace("_", " ").idup; }

        items.popFront;
        auto sense = Sense.unknown;
        if (!items.empty)
        {
            const item = items.front;
            sense = item.decodeWordSense;
            if (sense == Sense.unknown && item != `_`)
            {
                dln(`Unknown Sense code `, items.front);
            }
        }

        return store(expr.correctLemmaExpr, lang, sense, Origin.cn5, anyContext);
    }

    import std.algorithm: splitter;

    /** Lookup Context by $(D name). */
    ContextIx contextByName(S)(S name) if (isSomeString!S)
    {
        auto context = anyContext;
        if (name in contextIxByName)
        {
            context = contextIxByName[name];
        }
        else
        {
            assert(contextIxCounter != contextIxCounter.max);
            context._ix = contextIxCounter++;
            contextNameByIx[context] = name;
            contextIxByName[name] = context;
        }
        return context;
    }

    /** Read NELL Entity from $(D part). */
    Tuple!(Nd, string, Ln) readNELLEntity(S)(const S part)
    {
        const show = false;

        auto entity = part.splitter(':');

        if (entity.front == "concept")
        {
            entity.popFront; // ignore no-meaningful information
        }

        if (show) dln("ENTITY:", entity);

        auto personContextSplit = entity.front.findSplitAfter("person");
        if (!personContextSplit[0].empty)
        {
            /* dln(personContextSplit, " livesIn ", personContextSplit[1]); */
            /* lookupOrStoreContext(personContextSplit[0]); */
        }
        else
        {
            /* lookupOrStoreContext(entity.front); */
        }

        /* context */
        immutable contextName = entity.front.idup; entity.popFront;
        const context = contextByName(contextName);

        if (entity.empty)
        {
            return typeof(return).init;
        }

        const lang = Lang.en;   // use English for now
        const sense = Sense.noun;

        /* name */
        // clean cases such as concept:language:english_language
        immutable entityName = (entity.front.endsWith("_" ~ contextName) ?
                                entity.front[0 .. $ - (contextName.length + 1)] :
                                entity.front).idup;
        entity.popFront;

        auto entityIx = store(entityName.replace(`_`, ` `).correctLemmaExpr, lang, sense, Origin.nell, context);

        return tuple(entityIx,
                     contextName,
                     connect(entityIx,
                             Role(Rel.isA),
                             store(contextName.replace(`_`, ` `).correctLemmaExpr, lang, sense, Origin.nell, context),
                             Origin.nell, 1.0,
                             true)); // need to check duplicates here
    }

    /** Read NELL CSV Line $(D line) at 0-offset line number $(D lnr). */
    void readNELLLine(R, N)(R line, N lnr)
    {
        auto rel = Rel.any;
        auto negation = false;
        auto reversion = false;
        auto tense = Tense.unknown;

        Nd entityIx;
        Nd valueIx;

        string entityContextName;
        char[] relationName;
        string valueContextName;

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
                    entityContextName = entity[1];
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
                            valueContextName = value[1];

                            relationName.skipOver(entityContextName); // strip dumb prefix
                            relationName.skipOverBack(valueContextName); // strip dumb suffix

                            rel = relationName.decodeRelationPredicate(entityContextName,
                                                              valueContextName,
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
            auto mainLinkRef = connect(entityIx, Role(rel, reversion, negation), valueIx,
                                       Origin.nell, mainWeight);
        }

        if (show) writeln;
    }

    struct Location
    {
        double latitude;
        double longitude;
    }

    /** Node Locations. */
    Location[Nd] locations;

    /** Set Location of Node $(D cix) to $(D location) */
    void setLocation(Nd cix, in Location location)
    {
        assert (cix !in locations);
        locations[cix] = location;
    }

    /** If $(D link) node origins unknown propagate them from $(D link)
        itself. */
    bool propagateLinkNodes(ref Link link,
                            Nd src,
                            Nd dst)
    {
        bool done = false;
        if (!link.origin.defined)
        {
            // TODO prevent duplicate lookups to at
            if (!at(src).origin.defined) at(src).origin = link.origin;
            if (!at(dst).origin.defined) at(dst).origin = link.origin;
            done = true;
        }
        return done;
    }

    Origin decodeCN5OriginDirect(char[] path, out Lang lang,
                                 Origin currentOrigin)
    {
        switch (path) with (Origin)
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
                    switch (part) with (Origin)
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
    Ln readCN5Line(R, N)(R line, N lnr)
    {
        auto rel = Rel.any;
        auto negation = false;
        auto reversion = false;
        auto tense = Tense.unknown;

        Nd src, dst;
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
                        dln("Couldn't decode origin ", part);
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
            return connect(src, Role(rel, reversion, negation), dst, origin, weight);
        }
        else
        {
            return Ln.asUndefined;
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

    void readSwesaurus()
    {
        readSynlexFile("~/Knowledge/swesaurus/synpairs.xml".expandTilde.buildNormalizedPath);
        readFolketsFile("~/Knowledge/swesaurus/folkets_en_sv_public.xdxf".expandTilde.buildNormalizedPath, Lang.en, Lang.sv);
        readFolketsFile("~/Knowledge/swesaurus/folkets_sv_en_public.xdxf".expandTilde.buildNormalizedPath, Lang.sv, Lang.en);
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
                        Role(Rel.synonymFor),
                        store(w2, lang, Sense.unknown, origin),
                        origin, weight, true);
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
                case "pm": senses ~= Sense.name; break;
                case "nn": senses ~= Sense.noun; break;
                case "vb": senses ~= Sense.verb; break;
                case "hjälpverb": senses ~= Sense.auxiliaryVerb; break;
                case "jj": senses ~= Sense.adjective; break;
                case "pc": senses ~= Sense.adjective; break; // TODO can be either adjective or verb
                case "ab": senses ~= Sense.adverb; break;
                case "pp": senses ~= Sense.preposition; break;
                case "pn": senses ~= Sense.pronoun; break;
                case "ps": senses ~= Sense.pronounPossessive; break;
                case "kn": senses ~= Sense.conjunction; break;
                case "in": senses ~= Sense.interjection; break;
                case "abbrev": senses ~= Sense.abbrevation; break;
                case "nn, abbrev":
                case "abbrev, nn":
                    senses ~= Sense.nounAbbrevation; break;
                case "article": senses ~= Sense.article; break;
                case "rg":
                case "rg, nn": senses ~= Sense.integer; break;
                case "ro":
                case "ro, nn": senses ~= Sense.ordinalNumber; break;
                case "in, nn": senses ~= [Sense.interjection, Sense.noun]; break;
                case "jj, nn": senses ~= [Sense.adjective, Sense.noun]; break;
                case "jj, pp": senses ~= [Sense.adjective, Sense.preposition]; break;
                case "jj, pc": senses ~= [Sense.adjective]; break; // TODO can be either adjective or verb
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
                case "ie": senses ~= Sense.conjunction; break; // TODO "ie" is a strange abbrevation for "conjunction"
                default: dln(`warning: TODO "`, src, `" have sense "`, gr, `"`); break;
            }

            foreach (sense; senses)
            {
                foreach (dst; dsts.filter!(a => !a.empty))
                {
                    auto src_ = src.splitter(',').map!(a => a.strip(' ')).filter!(a => !a.empty);
                    auto dst_ = dst.splitter(',').map!(a => a.strip(' ')).filter!(a => !a.empty);

                    connectMtoN(store(src_, srcLang, sense, origin),
                                Role(Rel.translationOf),
                                store(dst_, dstLang, sense, origin),
                                origin, 1.0, true);
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

        foreach (rel; enumMembers!Rel)
        {
            const count = relCounts[rel];
            if (count)
            {
                writeln(indent, rel.to!string, `: `, count);
            }
        }

        writeln(`Node Count: `, allNodes.length);

        writeln(`Node Count by Origin:`);
        foreach (source; enumMembers!Origin)
        {
            const count = linkSourceCounts[source];
            if (count)
            {
                writeln(indent, source.toNice, `: `, count);
            }
        }

        writeln(`Node Count by Language:`);
        foreach (lang; enumMembers!Lang)
        {
            const count = nodeCountByLang[lang];
            if (count)
            {
                writeln(indent, lang.toHuman, ` : `, count);
            }
        }

        writeln(`Node Count by Sense:`);
        foreach (sense; enumMembers!Sense)
        {
            const count = nodeCountBySense[sense];
            if (count)
            {
                writeln(indent, sense.toHuman, ` : `, count);
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

        writeln(indent, `Node Connectedness Average: `, cast(NWeight)nodeConnectednessSum/allNodes.length);
        writeln(indent, `Link Connectedness Average: `, cast(NWeight)linkConnectednessSum/allLinks.length);
    }

    /** Return Index to Link from $(D a) to $(D b) if present, otherwise Ln.max.
     */
    Ln areConnectedInOrder(Nd a, Role role, Nd b,
                           Origin origin = Origin.unknown,
                           NWeight nweight = 1.0)
    {
        const bDir = (role.rel.isSymmetric ?
                      RelDir.any :
                      RelDir.forward);
        foreach (aLinkRef; at(a).links)
        {
            const aLink = at(aLinkRef);
            if (aLink.role.rel == role.rel &&
                aLink.role.negation == role.negation && // no need to check reversion (all links are bidirectional)
                aLink.origin == origin &&
                (aLink.actors[]
                      .canFind(Nd(b, bDir))) &&
                abs(aLink.nweight - nweight) < 1.0e-2) // TODO adjust
            {
                return aLinkRef;
            }
        }

        return typeof(return).asUndefined;
    }

    /** Return Index to Link relating $(D a) to $(D b) in any direction if present, otherwise Ln.max.
        TODO warn about negation and reversion on existing rels
     */
    Ln areConnected(Nd a, Role role, Nd b,
                    Origin origin = Origin.unknown,
                    NWeight weight = 1.0)
    {
        return either(areConnectedInOrder(a, role, b, origin, weight),
                      areConnectedInOrder(b, role, a, origin, weight));
    }

    /** Return Index to Link relating if $(D a) and $(D b) if they are related. */
    Ln areConnected(in Lemma a, Role role, in Lemma b,
                    Origin origin = Origin.unknown,
                    NWeight weight = 1.0)
    {
        if (a in nodeRefByLemma && // both lemmas exist
            b in nodeRefByLemma)
        {
            return areConnected(nodeRefByLemma[a],
                                role,
                                nodeRefByLemma[b],
                                origin, weight);
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

    void showLinkRef(Ln ln)
    {
        auto link = at(ln);
        showLink(link.role.rel, ln.dir, link.role.negation);
    }

    void showNode(in Node node, NWeight weight)
    {
        if (node.lemma.expr)
            write(` "`, node.lemma.expr, // .replace(`_`, ` `)
                  `"`);

        write(` (`); // open

        if (node.lemma.meaningNr != 0)
        {
            write(`[`, node.lemma.meaningNr, `]`);
        }

        if (node.lemma.lang != Lang.unknown)
        {
            write(node.lemma.lang);
        }
        if (node.lemma.sense != Sense.unknown)
        {
            write(`:`, node.lemma.sense);
        }
        if (node.lemma.context != ContextIx.asUndefined)
        {
            write(`:`, contextNameByIx[node.lemma.context]);
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

    void showNds(R)(R nodeRefs,
                    Rel rel = Rel.any,
                    bool negation = false)
    {
        foreach (nd; nodeRefs)
        {
            const lineNode = at(nd);

            write(`  -`);

            if (lineNode.lemma.meaningNr != 0)
            {
                write(` meaning [`, lineNode.lemma.meaningNr, `]`);
            }

            if (lineNode.lemma.lang != Lang.unknown)
            {
                write(` in `, lineNode.lemma.lang.toHuman);
            }
            if (lineNode.lemma.sense != Sense.unknown)
            {
                write(` of sense `, lineNode.lemma.sense);
            }
            writeln;

            // TODO Why is cast needed here?
            auto linkRefs = cast(LinkRefs)linkRefsOf(lineNode, RelDir.any, Role(rel, false, negation));

            linkRefs[].multiSort!((a, b) => (at(a).nweight >
                                             at(b).nweight),
                                  (a, b) => (at(a).role.rel.rank <
                                             at(b).role.rel.rank),
                                  (a, b) => (at(a).role.rel <
                                             at(b).role.rel));
            foreach (ln; linkRefs)
            {
                auto link = at(ln);
                showLinkRef(ln);
                foreach (linkedNode; link.actors[]
                                         .filter!(actorNodeRef => (actorNodeRef.ix !=
                                                                   nd.ix)) // don't self reference
                                         .map!(nd => at(nd)))
                {
                    showNode(linkedNode, link.nweight);
                }
                writeln;
            }
        }
    }

    alias TriedLines = bool[string]; // TODO use std.container.set

    void showFixedLine(string line)
    {
        writeln(`> Line "`, line, `"`);
    }

    const durationInMsecs = 1000; // duration in milliseconds

    const fuzzyExprMatchMaximumRecursionDepth = 8;

    import std.datetime: StopWatch;
    private StopWatch showNodesSW;

    bool showNodes(string line,
                   Lang lang = Lang.unknown,
                   Sense sense = Sense.unknown,
                   string lineSeparator = `_`,
                   TriedLines triedLines = TriedLines.init,
                   uint depth = 0)
    {
        if      (depth == 0) { showNodesSW.start(); } // if top-level call start it
        else if (depth >= fuzzyExprMatchMaximumRecursionDepth)
        {
            // writeln(`Maximum recursion depth reached for `, line, ` ...`);
            return false;       // limit maximum recursion depth
        }
        if (showNodesSW.peek().msecs >= durationInMsecs)
        {
            // writeln(`Out of time. Skipping testing of `, line, ` ...`);
            return false;
        }

        import std.ascii: whitespace;
        import std.algorithm: splitter;
        import std.string: strip;

        if (line in triedLines) // if already tested
            return false;
        triedLines[line] = true;

        // dln("depth:", depth, " line: ", line);

        // auto normLine = line.strip.splitter!isWhite.filter!(a => !a.empty).joiner(lineSeparator).to!S;
        // See also: http://forum.dlang.org/thread/pyabxiraeabfxujiyamo@forum.dlang.org#post-euqwxskfypblfxiqqtga:40forum.dlang.org
        auto normLine = line.strip.tr(std.ascii.whitespace, ` `, `s`);
        if (normLine.empty)
            return false;

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
        else if (normLine.skipOver(`anagramsof(`) ||
                 normLine.skipOver(`anagrams_of(`))
        {
            const split = normLine.findSplitBefore(`)`);
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
        else if (normLine.skipOver(`synonymsof(`) ||
                 normLine.skipOver(`synonyms_of(`))
        {
            const split = normLine.findSplitBefore(`)`);
            const arg = split[0];
            if (!arg.empty)
            {
                foreach (synonymNode; synonymsOf(arg))
                {
                    showLinkNode(at(synonymNode),
                                 Rel.instanceOf,
                                 NWeight.infinity,
                                 RelDir.backward);
                }
            }
        }
        else if (normLine.skipOver(`rhymesof(`) ||
                 normLine.skipOver(`rhymes_of(`))
        {
            const split = normLine.findSplitBefore(`)`);
            const arg = split[0];
            if (!arg.empty)
            {
                foreach (rhymingNode; rhymesOf(arg))
                {
                    showLinkNode(at(rhymingNode),
                                 Rel.instanceOf,
                                 NWeight.infinity,
                                 RelDir.backward);
                }
            }
        }
        else if (normLine.skipOver(`translationsof(`) ||
                 normLine.skipOver(`translations_of(`) ||
                 normLine.skipOver(`translate(`))
        {
            const split = normLine.findSplitBefore(`)`);
            const arg = split[0];
            if (!arg.empty)
            {
                foreach (translationNode; translationsOf(arg))
                {
                    showLinkNode(at(translationNode),
                                 Rel.instanceOf,
                                 NWeight.infinity,
                                 RelDir.backward);
                }
            }
        }
        else if (normLine.skipOver(`languagesof(`) ||
                 normLine.skipOver(`languages_of(`))
        {
            normLine.skipOver(" "); // TODO all space using skipOver!isSpace
            const split = normLine.findSplitBefore(`)`);
            const arg = split[0];
            if (!arg.empty)
            {
                auto hist = languagesOf(arg.splitter(" "));
                showTopLanguages(hist);
            }
        }
        else if (normLine.skipOver(`languageof(`) ||
                 normLine.skipOver(`language_of(`))
        {
            normLine.skipOver(" "); // TODO all space using skipOver!isSpace
            const split = normLine.findSplitBefore(`)`);
            const arg = split[0];
            if (!arg.empty)
            {
                auto hist = languagesOf(arg.splitter(" "));
                showTopLanguages(hist, 1);
            }
        }
        else if (normLine.skipOver(`startswith(`) ||
                 normLine.skipOver(`starts_with(`) ||
                 normLine.skipOver(`beginswith(`) ||
                 normLine.skipOver(`begins_with(`) ||
                 normLine.skipOver(`hasbegin(`) ||
                 normLine.skipOver(`has_begin(`) ||
                 normLine.skipOver(`hasstart(`) ||
                 normLine.skipOver(`has_start(`))
        {
            normLine.skipOver(" "); // TODO all space using skipOver!isSpace
            const split = normLine.findSplitBefore(`)`);
            const arg = split[0];
            if (!arg.empty)
            {
                auto hits = startsWith(arg);
                foreach (node; hits.map!(a => at(a)))
                {
                    showNode(node, 1.0);
                    writeln;
                }
            }
        }
        else if (normLine.skipOver(`endswith(`) ||
                 normLine.skipOver(`ends_with(`) ||
                 normLine.skipOver(`hasend(`) ||
                 normLine.skipOver(`has_end(`) ||
                 normLine.skipOver(`hassuffix(`) ||
                 normLine.skipOver(`has_suffix(`))
        {
            normLine.skipOver(" "); // TODO all space using skipOver!isSpace
            const split = normLine.findSplitBefore(`)`);
            const arg = split[0];
            if (!arg.empty)
            {
                auto hits = endsWith(arg);
                foreach (node; hits.map!(a => at(a)))
                {
                    showNode(node, 1.0);
                    writeln;
                }
            }
        }
        else if (normLine.skipOver(`canfind(`) ||
                 normLine.skipOver(`can_find(`) ||
                 normLine.skipOver(`contain(`) ||
                 normLine.skipOver(`contains(`))
        {
            normLine.skipOver(" "); // TODO all space using skipOver!isSpace
            const split = normLine.findSplitBefore(`)`);
            const arg = split[0];
            if (!arg.empty)
            {
                auto hits = canFind(arg);
                foreach (node; hits.map!(a => at(a)))
                {
                    showNode(node, 1.0);
                    writeln;
                }
            }
        }
        else if (normLine.skipOver(`as`)) // asSense
        {
            const split = normLine.findSplit(`(`);
            const senseString = split[0].strip;
            const arg = split[2].until(')').array.strip;
            try
            {
                const qSense = senseString.toLower.to!Sense;
                dln(senseString, ", ", arg, " ", qSense);
            }
            catch (std.conv.ConvException e)
            {
            }
        }
        else if (normLine.skipOver(`in`)) // inLanguage
        {
            const split = normLine.findSplit(`(`);
            const langString = split[0].strip;
            const arg = split[2].until(')').array.strip;
            try
            {
                const qLang = langString.toLower.to!Lang;
                dln(langString, ", ", arg, " ", qLang);
            }
            catch (std.conv.ConvException e)
            {
            }
        }

        if (normLine.empty)
            return false;

        // queried line nodes
        auto lineNds = nodeRefsOf(normLine, lang, sense);

        if (!lineNds.empty)
        {
            showFixedLine(normLine);
            showNds(lineNds);
        }

        const commonSplitters = [` `, // prefer space
                                `-`,
                                `'`];

        const commonJoiners = [` `, // prefer space
                               `-`,
                               ``,
                               `'`];

        // try joined
        if (lineNds.empty)
        {
            auto spaceWords = normLine.splitter(' ').filter!(a => !a.empty);
            if (spaceWords.count >= 2)
            {
                foreach (combWords; permutations.permutations(spaceWords.array)) // TODO remove .array
                {
                    foreach (separator; commonJoiners)
                    {
                        showNodes(combWords.joiner(separator).to!string,
                                  lang, sense, lineSeparator, triedLines, depth + 1);
                    }
                }
            }

            auto minusWords = normLine.splitter('-').filter!(a => !a.empty);
            if (minusWords.count >= 2)
            {
                foreach (separator; commonJoiners)
                {
                    showNodes(minusWords.joiner(separator).to!string,
                              lang, sense, lineSeparator, triedLines, depth + 1);
                }
            }

            auto quoteWords = normLine.splitter(`'`).filter!(a => !a.empty);
            if (quoteWords.count >= 2)
            {
                foreach (separator; commonJoiners)
                {
                    showNodes(quoteWords.joiner(separator).to!string,
                              lang, sense, lineSeparator, triedLines, depth + 1);
                }
            }

            // stemmed
            auto stemLine = normLine;
            while (true)
            {
                const stemResult = stemLine.stemIn(lang);
                auto stemMoreLine = stemResult[0];
                const stemLang = stemResult[1];
                if (stemMoreLine == stemLine)
                    break;
                // writeln(`> Stemmed to "`, stemMoreLine, `" in language `, stemLang);
                showNodes(stemMoreLine, stemLang, sense, lineSeparator, triedLines, depth + 1);
                stemLine = stemMoreLine;
            }

            // non-interpuncted
            if (normLine.startsWith('.', '?', '!'))
            {
                const nonIPLine = normLine.dropOne;
                // writeln(`> As a non-interpuncted "`, nonIPLine, `"`);
                showNodes(nonIPLine, lang, sense, lineSeparator, triedLines, depth + 1);
            }

            // non-interpuncted
            if (normLine.endsWith('.', '?', '!'))
            {
                const nonIPLine = normLine.dropBackOne;
                // writeln(`> As a non-interpuncted "`, nonIPLine, `"`);
                showNodes(nonIPLine, lang, sense, lineSeparator, triedLines, depth + 1);
            }

            // interpuncted
            if (!normLine.endsWith('.') &&
                !normLine.endsWith('?') &&
                !normLine.endsWith('!'))
            {
                // questioned
                const questionedLine = normLine ~ '?';
                // writeln(`> As a question "`, questionedLine, `"`);
                showNodes(questionedLine, lang, sense, lineSeparator, triedLines, depth + 1);

                // exclaimed
                const exclaimedLine = normLine ~ '!';
                // writeln(`> As an exclamation "`, exclaimedLine, `"`);
                showNodes(exclaimedLine, lang, sense, lineSeparator, triedLines, depth + 1);

                // dotted
                const dottedLine = normLine ~ '.';
                // writeln(`> As a dotted "`, dottedLine, `"`);
                showNodes(dottedLine, lang, sense, lineSeparator, triedLines, depth + 1);
            }

            // lowered
            const loweredLine = normLine.toLower;
            if (loweredLine != normLine)
            {
                // writeln(`> Lowercased to "`, loweredLine, `"`);
                showNodes(loweredLine, lang, sense, lineSeparator, triedLines, depth + 1);
            }

            // uppered
            const upperedLine = normLine.toUpper;
            if (upperedLine != normLine)
            {
                // writeln(`> Uppercased to "`, upperedLine, `"`);
                showNodes(upperedLine, lang, sense, lineSeparator, triedLines, depth + 1);
            }

            // capitalized
            const capitalizedLine = normLine.capitalize;
            if (capitalizedLine != normLine)
            {
                // writeln(`> Capitalized to (name) "`, capitalizedLine, `"`);
                showNodes(capitalizedLine, lang, sense, lineSeparator, triedLines, depth + 1);
            }
        }

        return false;
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
        showNds(nodes, Rel.synonymFor); // TODO traverse synonyms
        return nodes;
    }

    /** Get Links of $(D currents) type $(D rel) learned from $(D origins).
    */
    auto linkRefsOf(Nd nd,
                    Rel rel,
                    Origin[] origins = [])
    {
        return at(nd).links[]
                     .filter!(ln => (at(ln).role.rel == rel &&
                                     (origins.empty ||
                                      origins.canFind(at(ln).origin))));
    }

    /** Get Nearest Neighbours of $(D currents) over links of type $(D rel)
        learned from $(D origins).
    */
    auto nearsOf(Nd nd,
                 Rel rel,
                 Origin[] origins = [])
    {
        return linkRefsOf(nd, rel, origins).map!(ln =>
                                                 at(ln).actors[]
                                                       .filter!(actor => actor != nd))
                                                .joiner(); // no self
    }

    /** Get Nearest Neighbours of $(D srcs) over links of type $(D rel) learned
        from $(D origins).
    */
    // auto nearsOf(R)(R nodeRefs,
    //                 Rel rel,
    //                 Origin[] origins = []) if (isSourceOf!(R, Nd))
    // {
    //     return nodeRefs[].map!(nd => nearsOf(nd, rel, origins));
    // }

    /** Get Possible Rhymes of $(D text) sorted by falling rhymness (relevance).
        Set withSameSyllableCount to true to get synonyms which can be used to
        help in translating songs with same rhythm.
        See also: http://stevehanov.ca/blog/index.php?id=8
     */
    Nds rhymesOf(S)(S expr,
                    Lang[] langs = [],
                    Origin[] origins = [],
                    size_t commonPhonemeCountMin = 2,  // at least two phonenes in common at the end
                    bool withSameSyllableCount = false) if (isSomeString!S)
    {
        foreach (src_; nodeRefsOf(expr))
        {
            const src = at(src_);
            if (langs.empty) { langs = [src.lemma.lang]; } // stay within language by default

            // foreach (link; linksOf(src_).filter!(link => link.rel == Rel.hasPronounciation))
            // {
            //     writeln("src_: ", at(src_));
            //     writeln("link.rel: ", link.rel);
            //     writeln("link.actors: ", link.actors);
            // }

            foreach (dst_; nearsOf(src_, Rel.hasPronounciation, origins))
            {
                const dst = at(dst_);
                writeln("src_:", src_, " src:", src, " dst_:", dst_, " dst:", dst);
                auto hits = allNodes.filter!(a => langs.canFind(a.lemma.lang))
                                    .map!(a => tuple(a, commonSuffixCount(a.lemma.expr,
                                                                          at(src_).lemma.expr)))
                                    .filter!(a => a[1] >= commonPhonemeCountMin)
                                    // .sorted!((a, b) => false)
                ;
            }
        }
        return typeof(return).init;
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
    void showTopLanguages(NWeight[Lang] hist, size_t maxCount = size_t.max)
    {
        size_t i = 0;
        foreach (e; hist.pairs.sort!((a, b) => (a[1] > b[1])))
        {
            if (i == maxCount) { break; }
            writeln("  - ", e[0].toHuman, ": ", e[1], " #hits");
            ++i;
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
        showNds(nodes, Rel.translationOf); // TODO traverse synonyms and translations
        // en => sv:
        // en-en => sv-sv
        /* auto translations = nodes.map!(node => linkRefsOf(node, RelDir.any, rel, false))/\* .joiner *\/; */
        return nodes;
    }

    /** Get Node References whose Lemma Expr starts with $(D prefix). */
    auto canFind(S)(S part,
                    Lang lang = Lang.unknown,
                    Sense sense = Sense.unknown) if (isSomeString!S)
    {
        return nodeRefByLemma.values.filter!(nd => at(nd).lemma.expr.canFind(part));
    }

    /** Get Node References whose Lemma Expr starts with $(D prefix). */
    auto startsWith(S)(S prefix,
                       Lang lang = Lang.unknown,
                       Sense sense = Sense.unknown) if (isSomeString!S)
    {
        return nodeRefByLemma.values.filter!(nd => at(nd).lemma.expr.startsWith(prefix));
    }

    /** Get Node References whose Lemma Expr starts with $(D suffix). */
    auto endsWith(S)(S suffix,
                     Lang lang = Lang.unknown,
                     Sense sense = Sense.unknown) if (isSomeString!S)
    {
        return nodeRefByLemma.values.filter!(nd => at(nd).lemma.expr.endsWith(suffix));
    }

    /** Relatedness.
        Sum of all paths relating a to b where each path is the path weight
        product.
    */
    real relatedness(Nd a,
                     Nd b) const @safe @nogc pure nothrow
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

    void inferSpecializedSenses()
    {
        bool show = true;
        foreach (pair; lemmasByExpr.byPair)
        {
            const expr = pair[0];
            auto lemmas = pair[1];
            if (lemmas.map!(lemma => lemma.lang).allEqual)
            {
                switch (lemmas.length)
                {
                    case 2:
                        if (lemmas[0].sense.specializes(lemmas[1].sense))
                        {
                            if (show)
                            {
                                dln(`Specializing Lemma expr "`, expr,
                                    `" in `, lemmas[0].lang.toHuman, ` of sense from "`,
                                    lemmas[1].sense, `" to "`, lemmas[0].sense, `"`);
                            }
                            // lemmas[1].sense = lemmas[0].sense;
                        }
                        else if (lemmas[1].sense.specializes(lemmas[0].sense))
                        {
                            if (show)
                            {
                                dln(`Specializing Lemma expr "`, expr,
                                    `" in `, lemmas[0].lang.toHuman, ` of sense from "`,
                                    lemmas[0].sense, `" to "`, lemmas[1].sense, `"`);
                            }
                            // lemmas[0].sense = lemmas[1].sense;
                        }
                        break;
                    default:
                        break;
                }
            }
        }
    }
}
