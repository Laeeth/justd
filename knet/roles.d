module knet.roles;

import std.bitmanip: bitfields;
public import knet.relations;

struct Role
{
    @safe @nogc pure nothrow:
    this(Rel rel = Rel.any,
         bool reversed = false,
         bool negation = false)
    {
        this.rel = rel;
        this.reversed = reversed;
        this.negation = negation;
    }
    this(string role)
    {
        this.reversed = false;
        this.negation = false;
        switch (role) with (Rel)
        {
            case `isA`: this.rel = isA; break;

            case `antonym`:
            case `antonymFor`: this.rel = antonymFor; break;

            case `meronym`:
                this.rel = partOf; break;

            case `memberOf`:
                this.rel = memberOf; break;

            case `partOf`:
                this.rel = partOf; break;

            case `wholeOf`:
            case `holonym`:
                this.rel = partOf; this.reversed = true; break;

            case `hypernym`:
                this.rel = isA; this.reversed = true; break;

            case `instanceHypernym`:
            case `instanceHypernymOf`:
                this.rel = instanceHypernymOf; break;

            case `hyponym`:
                this.rel = isA; break;

            case `instanceHyponym`:
            case `instanceHyponymOf`:
                this.rel = instanceHyponymOf; break;

            case `canBe`: this.rel = isA; break;

            case `cause`:
            case `causes`:
                this.rel = causes; break;

            case `entail`:
            case `entails`:
                this.rel = causes; this.reversed = true; break;

            default:
                this.rel = relatedTo;
                // assert(false, `Unexpected role `);
                break;
        }
    }
    Rel rel;
    mixin(bitfields!(bool, "reversed", 1,
                     bool, "negation", 1,
                     uint, "pad", 6));
}

import knet.senses: Sense;

/** Convert $(D rel) to Human Language Representation. */
auto toHuman(const Role role,
             const Lang targetLang = Lang.en, // present statement in this language
             const Sense targetSense = Sense.unknown,
             const Lang srcLang = Lang.en, // TODO use
             const Lang dstLang = Lang.en) // TODO use
    @safe pure
{
    const Rel rel = role.rel;
    const bool negation = role.negation;

    string[] words;
    import std.array: array;
    import std.algorithm: joiner;

    auto not = negation ? negationIn(targetLang) : null; // negation string
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
                default: words = ["is", not, "a reversed of"]; break;
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
            if (!role.reversed)
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
        case hypernymOf:
            if (role.reversed) // just a reversed of isA for now
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
            if (!role.reversed)
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
            if (!role.reversed)
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
                    default: words = ["does", not, "have part"]; break;
                }
            }
            break;
        case madeOf:
            if (!role.reversed)
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
            if (!role.reversed)
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
            if (!role.reversed)
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
            if (!role.reversed)
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
            if (!role.reversed)
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
            if (!role.reversed)
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
            if (!role.reversed)
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
            if (!role.reversed)
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
            if (!role.reversed)
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
            if (!role.reversed)
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
            if (!role.reversed)
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
            if (!role.reversed)
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
            if (!role.reversed)
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
            if (!role.reversed)
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
            if (!role.reversed)
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
            if (!role.reversed)
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
            if (!role.reversed)
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
            if (!role.reversed)
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
            if (!role.reversed)
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
            if (!role.reversed)
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
            if (!role.reversed)
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
            if (!role.reversed)
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
            if (!role.reversed)
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
            if (!role.reversed)
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
            if (!role.reversed)
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
            if (!role.reversed)
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
            if (!role.reversed)
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
            if (!role.reversed)
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
            if (!role.reversed)
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
            if (!role.reversed)
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
            if (!role.reversed)
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
            if (!role.reversed)
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
            if (!role.reversed)
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
            if (!role.reversed)
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
            if (!role.reversed)
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
            if (!role.reversed)
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
                    case sv: words = ["kan", not, "ha instansen"]; break;
                    case en:
                    default: words = ["may", not, "have the instance"]; break;
                }
            }
            break;
        case instanceHypernymOf:
            if (!role.reversed)
            {
                switch (targetLang)
                {
                    case sv: words = ["är", not, "en hypernyminstans av"]; break;
                    case en:
                    default: words = ["is", not, "an instance hypernym of"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["kan", not, "ha hypernyminstansen"]; break;
                    case en:
                    default: words = ["may", not, "have the hypernym instance"]; break;
                }
            }
            break;
        case instanceHyponymOf:
            if (!role.reversed)
            {
                switch (targetLang)
                {
                    case sv: words = ["är", not, "en hyponyminstans av"]; break;
                    case en:
                    default: words = ["is", not, "an instance hyponym of"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["kan", not, "ha hyponyminstansen"]; break;
                    case en:
                    default: words = ["may", not, "have the hyponym instance"]; break;
                }
            }
            break;
        case substanceHolonym:
            if (!role.reversed)
            {
                switch (targetLang)
                {
                    case sv: words = ["är", not, "en substansholonym av"]; break;
                    case en:
                    default: words = ["is", not, "a substance holonym of"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["kan", not, "ha substansholonymen"]; break;
                    case en:
                    default: words = ["may", not, "have the substance holonym"]; break;
                }
            }
            break;
        case topicDomainOfSynset:
            if (!role.reversed)
            {
                switch (targetLang)
                {
                    case sv: words = ["är", not, "en temadomän av"]; break;
                    case en:
                    default: words = ["is", not, "a topic domain of"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["har", not, "temadomänen"]; break;
                    case en:
                    default: words = ["does", not, "have the topic domain"]; break;
                }
            }
            break;
        case regionDomainOfSynset:
            if (!role.reversed)
            {
                switch (targetLang)
                {
                    case sv: words = ["är", not, "en regiondomän av"]; break;
                    case en:
                    default: words = ["is", not, "a region domain of"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["har", not, "regiondomänen"]; break;
                    case en:
                    default: words = ["does", not, "have the region domain"]; break;
                }
            }
            break;
        case usageDomainOfSynset:
            if (!role.reversed)
            {
                switch (targetLang)
                {
                    case sv: words = ["är", not, "en användningsdomän av"]; break;
                    case en:
                    default: words = ["is", not, "a usage domain of"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["har", not, "användningsdomänen"]; break;
                    case en:
                    default: words = ["does", not, "have the usage domain"]; break;
                }
            }
            break;
        case memberOfTopicDomain:
            if (!role.reversed)
            {
                switch (targetLang)
                {
                    case sv: words = ["är", not, "en medlem av temadomänen"]; break;
                    case en:
                    default: words = ["is", not, "a member of the topic domain"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["har", not, "temadomänmedlemmen"]; break;
                    case en:
                    default: words = ["does", not, "have the topic domain member"]; break;
                }
            }
            break;
        case memberOfRegionDomain:
            if (!role.reversed)
            {
                switch (targetLang)
                {
                    case sv: words = ["är", not, "en medlem av regiondomänen"]; break;
                    case en:
                    default: words = ["is", not, "a member of the region domain"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["har", not, "regionsdomänmedlemmen"]; break;
                    case en:
                    default: words = ["does", not, "have the region domain member"]; break;
                }
            }
            break;
        case memberOfUsageDomain:
            if (!role.reversed)
            {
                switch (targetLang)
                {
                    case sv: words = ["är", not, "en medlem av användningsdomänen"]; break;
                    case en:
                    default: words = ["is", not, "a member of the usage domain"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["har", not, "användingsdomän medlemmen"]; break;
                    case en:
                    default: words = ["does", not, "have the usage domain member"]; break;
                }
            }
            break;
        case decreasesRiskOf:
            if (!role.reversed)
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
            if (!role.reversed)
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
            if (!role.reversed)
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
            if (!role.reversed)
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
            if (!role.reversed)
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
            if (!role.reversed)
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
            if (!role.reversed)
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
            if (!role.reversed)
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
            if (!role.reversed)
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
            if (!role.reversed)
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
            if (!role.reversed)
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
            if (!role.reversed)
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
            if (!role.reversed)
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
            if (!role.reversed)
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
        case slangFor:
            if (!role.reversed)
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
            if (!role.reversed)
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
        case pertainym:
            if (!role.reversed)
            {
                switch (targetLang)
                {
                    case sv: words = ["har", not, "pertainymen"]; break;
                    case en:
                    default: words = ["has", not, "the pertainym"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["är", not, "en pertainym till"]; break;
                    case en:
                    default: words = ["is", not, "a pertainym of"]; break;
                }
            }
            break;
        case attribute:
            if (!role.reversed)
            {
                switch (targetLang)
                {
                    case sv: words = ["har", not, "attribut form"]; break;
                    case en:
                    default: words = ["has", not, "attribute form"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["är", not, "en attributform till"]; break;
                    case en:
                    default: words = ["is", not, "is an attribute form of"]; break;
                }
            }
            break;
        case derivationallyRelatedForm:
            if (!role.reversed)
            {
                switch (targetLang)
                {
                    case sv: words = ["har", not, "en härledd form"]; break;
                    case en:
                    default: words = ["has", not, "a derivationally related form"]; break;
                }
            }
            else
            {
                switch (targetLang)
                {
                    case sv: words = ["är", not, "en härledd form av"]; break;
                    case en:
                    default: words = ["is ", not, "a derivationally related form of"]; break;
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
        case alsoSee:
            switch (targetLang)
            {
                case sv: words = ["see", not, "också"]; break;
                case en:
                default: words = ["also ", not, "see"]; break;
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
            const prefix = (ordered && role.reversed ? `<` : ``);
            const suffix = (ordered && (!role.reversed) ? `>` : ``);
            words = [prefix ~ `-` ~ rel.to!string ~ `-` ~ suffix];
            break;
    }

    import std.algorithm.iteration: filter;
    return words.filter!(word => word !is null) // strip not
                .joiner(" "); // add space
}
