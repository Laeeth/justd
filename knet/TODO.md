# TODO

### TODO Use ~/Knowledge/Svåra Ord (1989)/svaraord.txt

### TODO Rename Role to Pred or Act or Conn? What does WordNet call it?

### BUG in sv/homophone.txt
    - noun:bor (är ett grundämne), verb:bor (i Sverige)
    - noun:te (är en dryc), verb:te (sig)

### BUG WordNet stores proper names in lowercase

This could be detected and fixed in learnLemma() if existing lemmas in uppercase
and has sense that specializes noun.

### TODO Find dubious words:
- Swedish: trumpetare - trum-petare
- Swedish: tunnelbanan - tunnel-banan

### TODO hymesOf() may reuse Walk.byNode walkOver(Rel.prounounciation)

### BUG Enable readNELLFile and fix bug in it

### TODO specializeUniquely John to name in English if first letter isUpper

### TODO "startsWith(larger than)" gives duplicate searches and takes long

### TODO Add Syllable into Phonemes using some special UTF-8 character middle-dot character.
### TODO Learn Syllables:
- Extend syllables.d and test it against knowledge/moby/hyphentation.txt
- Use Java at: https://stackoverflow.com/questions/405161/detecting-syllables-in-a-word
- https://stackoverflow.com/questions/27889604/open-syllabification-database
- lemmasByExpr[`one-liner`] => Lemma(`one-liner`) =>
- May require bool checkSyllables = false;
- if expr.canFind(syllableSeparator) use splitter(syllableSeparator) instead of findWordSplit()

### TODO Infer: {1} isA NOUN => {1} isA NOUN

### TODO If WordNet is loaded explicitly skip it when loading CN5.

### TODO Prompt Queries:
### TODO canA(NOUN, VERB), canA(bird, fly), canA(man, walk), canA(dead man, walk)
### TODO isA(NOUN, NOUN), canA(bird, animal)
### TODO is(NOUN, ADVERB), canA(bird, dead) infer from: {} hasProperty ADVERB
### TODO all(birds)
### TODO all(bird)
### TODO instancesOf(bird)
### TODO examplesOf(bird)
### TODO anslateTo(EXPR, LANGUAGE)

### TODO Infer: x hasProperty dead => x is dead

### TODO Use pattern matching
### TODO {A} means one word referred to with {A}
### TODO {A B} means one word referred to with {A B}
### TODO {1} means one word
### TODO {2} means one word
### TODO {1,2} means one or two words
### TODO {*} means zero or more words
### TODO {+} means one or more words

### TODO In Swedish: *lig <=> *ligt can be inferred to adjective <=> adverb
### TODO In English: X <=> Xely can be inferred to adjective <=> adverb
### TODO In English: X <=> Xly can be inferred to adjective <=> adverb

### TODO Infer English-Swedish Translations: "[are|is] requirED = krävs" because of "require = kräva"

### TODO Use lemma.sense = lemma.expr.until(':').to!Sense.specialize(lemma.sense) in Lemma()

### TODO Make context a Nd such Nd("mammal") =>isA=> Nd("animal")

### TODO Infer senses of consecutive word when reading sorted word list.
Requires knowledge of Language specfic ending grammar for verbs, nouns,
adjectives, adverbs. Use (verb|noun|adjective)(Ir)Regular to indicate regularity
- Swedish: "ersätt", "ersätta", "ersätter", "ersatte", "ersatt"

### TODO Move specific knowledge from wordnet.d to beginning of learnPreciseThings()

### TODO Show warning and then exceptions when adding a word as a language that doesn't support include its characters

### BUG Skriv in smärta i prompt: gives wrong relations: "[give" and "cause] pain; grieve"

### BUG eversion no effect for book_property.txt

### BUG Don't stem words containing non-English letters

Reuse variadic version of x.canFind(englishLetters...)

### TODO functionize uses of splitter-map-filter to convert CSV-strings to string[]

### TODO Replace comma in .txt files with some other ASCII separator

### TODO Learn Sense.nounUncountablesNouns first and then reuse and specializes "love" in Sense.noun

### TODO Google for Henry Liebermann's Open CommonSense Knowledge Base

### TODO At end of store() use convert Sense to string Rel.noun => "noun" and store it

connect(secondRef, Rel.isA, store(groupName, firstLang, Sense.noun, origin), firstLang, origin, weight, false, false, true);

### TODO Learn: https://sv.wikipedia.org/wiki/Modalt_hj%C3%A4lpverb

### TODO Use http://www.wordfrequency.info/files/entriesWithoutCollocates.txt etc

### TODO CN5: Infer Sense from specific Rels such as instanceOf Ra
### TODO Infer Senses in both directions over synonymWith typically: plåga (unknown) synonymWith tortera (noun) => plåga must have sense here
### TODO CN5: Parse parens after "Ra (board game)" and put in context
### TODO Infer:
- X isA Y and Y hasProperty Z => X hasProperty Z: expressed as X.getPropertyMaybe(Z)
- if X rel Y and assert(R.isSymmetric): Sense can be inferred in both directions if some Sense is unknown
- shampoo atLocation bathroom, shampoo stored in bottles => bottles atLocation bathroom
- sulfur synonymWith sulphur => sulfuric synonymWith sulphuric

### TODO Learn word meanings (WordNet) first. Then other higher rules can lookup these
     meanings before they are added.
### TODO For lemmas with Sense.unknown lookup its others lemmasOf. If only one
other non-unknown Sense exists assume it to be its meaning.

### TODO Nd getEmotion(Nd start, Rel[] overRels) { walkNds(); }

### TODO Add randomness to traverser if normalized distance similarity between
traversed nodes is smaller than a randomnessThreshold

### TODO Integrate Hits from Google: "list of word emotions" using new relations hasEmotionLove

### TODO See checkExisting in connect() to true only for Origin.manual

### TODO Make use of stealFront and stealBack

### TODO ansiktstvätt => "facial wash"
### TODO biltvätt => findSplit [bil tvätt] => search("car wash") or search("car_wash") or search("carwash")
### TODO promote equal splits through weigthing sum_over_i(x[i].length^)2

### TODO Template on NodeData and rename Concept to Node. Instantiate with
NodeData begin Concept and break out Concept outside.

### TODO Profile read
### TODO Use containers.HashMap
### TODO Call GC.disable/enable around construction and search.

### TODO Should we store acronyms and emoticons in lowercase or not?
### TODO Should we lowercase the key Lemma but not the Concept Lemma?

### TODO Extend Link with an array of relation types (Rel) for all its
     actors and context. We can then describe contextual knowledge.
     Perhaps Merge with NELL's ContextIx.

### BUG Searching for good gives incorrect oppositeOf relations

### BUG No manual learning has been done for cry <oppositeOf> laugh
> Line cry
- in English
- is the opposite of:  laugh(en:1.00@Manual),
- is the opposite of:  laugh(en-verb:1.00@CN5),
- is the opposite of:  laugh(en:1.00@Manual),

### BUG hate is learned twice. Add duplicate detection.
< Concept(s) or ? for help: love
> Line love
- in English of sense nounUncountable
- is a:  nounUncountable(en-nounUncountable:1.00@Manual),
- in English
- is the opposite of:  hate(en:1.00@CN5),
- is the opposite of:  hate(en-verb:1.00@CN5),
- is the opposite of:  hatred(en-noun:1.00@CN5),
- is the opposite of:  hate(en:0.55@CN5),

## Assert that SUMO has these
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
