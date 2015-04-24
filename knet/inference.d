module knet.inference;

import knet.base;

/* TODO Infer in multiple steps/passes:
   synonymFor ==specializes==> abbreviationFor ==specializes=> acronymFor
   */
void inferSpecializedRelations(Graph gr)
{
}

/** Check if $(D rel) propagates Sense(s). */
bool propagatesSense(Rel rel) @safe @nogc pure nothrow
{
    with (Rel) return rel.among!(translationOf,
                                 synonymFor,
                                 antonymFor) != 0;
}

/** Check if $(D rel) propagates Sense(s). */
Tuple!(Sense, Sense) inferredSenses(Rel rel) @safe @nogc pure nothrow
{
    typeof(return) senses;

    import knet.relations: specializes;

    with (Rel) switch (rel)
    {
        case partOf:
        case writtenAboutInPublication:
        case hasA:
        case uses:
        case usesLanguage:
        case usesTool:
        case capableOf:
        case hasHome:
        case languageSchoolInCity:
        case grownAtLocation:
        case producedAtLocation:
        case inRoom:
        case bornInLocation:
        case diedInLocation:
        case hasOfficeIn:
        case headquarteredIn:
        case borderedBy:
        case causes:
        case causesSideEffect:

        case similarSizeTo:
        case similarAppearanceTo:

        case hasSubevent:
        case hasFirstSubevent:
        case hasLastSubevent:

        case hasPrerequisite:

        case physicallyConnectedWith:
        case arisesFrom:
        case emptiesInto:

        case hasShape:
        case hasColor:
        case hasSize:
        case hasDiameter:
        case hasArea:
        case hasLength:
        case hasHeight:
        case hasWidth:
        case hasThickness:
        case hasWeight:
        case hasAge:
        case hasWebsite:
        case hasOfficialWebsite:
        case hasJobPosition:
        case hasTeamPosition:
        case hasTournament:
        case hasCapital:
        case hasExpert:
        case hasLanguage:
        case hasOrigin:
        case hasCurrency:

        case instanceOf:
        case madeOf:
        case madeBy:

        case isTallerThan:
        case isLargerThan:
        case isHeavierThan:
        case isOlderThan:
        case areMoreThan:

        case hasNameDay:

        case hasRelative:
        case hasFamilyMember:

        case hasFriend:
        case hasTeamMate:
        case hasEnemy:

        case hasSpouse:
        case hasWife:
        case hasHusband:

        case hasSibling:
        case hasBrother:
        case hasSister:

        case hasGrandParent:
        case hasParent:
        case hasFather:
        case hasMother:

        case hasGrandChild:
        case hasChild:
        case hasSon:
        case hasDaugther:
        case hasPet:

        case hasScore:
        case hasLoserScore:
        case hasWinnerScore:

        case competesWith:
        case involvedWith:
        case collaboratesWith:

        case graduatedFrom:
        case agentCreated:

        case createdAtDate:

        case chargedWithCrime:

        case movedTo:

        case cookedWith:
        case servedWith:
        case wornWith:

            senses = tuple(Sense.noun,
                           Sense.noun);
            break;
        case madeAt:
            senses = tuple(Sense.noun,
                           Sense.noun); // TODO location
            break;

        case atTime:
        case beganAtTime:
        case endedAtTime:
        case bornIn:
        case foundedIn:
        case marriedIn:
        case diedIn:
            senses = tuple(Sense.noun,
                           Sense.timePoint);
            break;

        case diedAtAge:
            senses = tuple(Sense.noun,
                           Sense.timePeriod);
            break;

        case substanceHolonym:
            senses = tuple(Sense.substance,
                           Sense.substance);
            break;
        case memberOfEconomicSector:
        case participatesIn:
        case growsIn:
            senses = tuple(Sense.noun, // TODO plant
                           Sense.noun);
            break;
        case attends:
            senses = tuple(Sense.noun, // TODO person
                           Sense.noun);
            break;
        case worksFor:
        case worksInAcademicField:
        case writesForPublication:
        case leaderOf:
        case coaches:
        case ceoOf:
        case represents:
        case concerns:
        case plays:
        case playsInstrument:
        case playsIn:
        case playsFor:
        case wins:
        case loses:
        case contributesTo:
        case topMemberOf:
        case hasCitizenship:
        case hasEthnicity:
        case hasResidenceIn:
            senses = tuple(Sense.noun, // TODO person
                           Sense.noun);
            break;
        case locatedNear:
            senses = tuple(Sense.noun,
                           Sense.noun); // TODO location
            break;
        default:
            if (rel.specializes(Rel.atLocation))
            {
                senses = tuple(Sense.unknown,
                               Sense.noun); // TODO location
            }
            break;
    }
    return senses;
}

/** Check if $(D sense) always infers instanceOf relation. */
bool infersInstanceOf(Sense sense) @safe @nogc pure nothrow
{
    with (Sense) return sense.among!(weekday,
                                     month,
                                     dayOfMonth,
                                     year,
                                     season) != 0;
}

/**
   Infer Relations of Compound Nouns and Verbs.

   noun:"red light"
   - isA noun:"light"
   - hasAttribute adjective:"red"

   noun:"red light"
   - isA noun:"light"
   - hasAttribute adjective:"red"
*/
size_t inferPhraseRelations(Graph gr,
                            Expr expr,
                            Lemmas compoundLemmas,
                            Lang[] langs)
{
    const words = expr.split(` `);
    size_t cnt = 0;
    switch (words.length)
    {
        case 2:
            import knet.iteration: ndsOf;
            import knet.filtering: matches;
            foreach (compoundLemma; compoundLemmas.filter!(lemma => (langs.matches(lemma.lang) &&
                                                                     [Sense.noun].matches(lemma.sense, true, lemma.lang)))) // noun:"red light"
            {
                const compoundNd = gr.db.ixes.ndByLemma[compoundLemma];
                foreach (const qualifierNd; gr.ndsOf(words[0], [compoundLemma.lang], [Sense.noun,
                                                                                      Sense.adjective], false, false)) // adjective:red
                {
                    const sense = gr[qualifierNd].lemma.sense;

                    // TODO functionize?
                    Rel rel;
                    with (Sense) switch (sense)
                    {
                        case noun: rel = Rel.relatedTo; break;
                        case adjective: rel = Rel.hasAttribute; break;
                        default: break;
                    }

                    gr.connect(compoundNd, Role(rel), qualifierNd, Origin.inference, 1.0);
                    ++cnt;
                }
                foreach (const nounNd; gr.ndsOf(words[1], [compoundLemma.lang], [Sense.noun], false, false)) // noun:light
                {
                    gr.connect(compoundNd, Role(Rel.isA), nounNd, Origin.inference, 1.0);
                    ++cnt;
                }
            }
            break;
        default:
            break;
    }
    return cnt;
}

size_t propagateSenses(Graph gr,
                       Lemmas lemmas) @safe @nogc pure nothrow
{
    // TODO use propagatesSense
    size_t cnt = 0;
    return cnt;
}

size_t inferSpecializedSenses(Graph gr, Lemmas lemmas)
{
    size_t cnt = 0;
    bool show = false;
    import std.algorithm.iteration: groupBy;
    foreach (lemmasOfSameLang; lemmas.groupBy!((lemmaA,
                                                lemmaB) => (lemmaA.lang ==
                                                            lemmaB.lang)))
    {
        import knet.senses: specializes;
        import knet.languages: toHuman;
        switch (lemmasOfSameLang.count)
        {
            case 2:
                const lang = lemmas[0].lang;
                const lemmas_ = lemmasOfSameLang.array;
                if (lemmas[0].sense.specializes(lemmas[1].sense, true, lang, false, true))
                {
                    if (show)
                    {
                        writeln(`Specializing Lemma expr "`, lemmas[1],
                                `" in `, lemmas[0].lang.toHuman, ` of sense from "`,
                                lemmas[1].sense, `" to "`, lemmas[0].sense, `": `, lemmas[1], " => ", lemmas[0]);
                    }
                    // TODO replace all Nds of lemmas[1] with Nds of lemmas[0]
                    // lemmas[1].sense = lemmas[0].sense;
                    ++cnt;
                }
                else if (lemmas[1].sense.specializes(lemmas[0].sense, true, lang, false, true))
                {
                    if (show)
                    {
                        writeln(`Specializing Lemma expr "`, lemmas[0],
                                `" in `, lemmas[0].lang.toHuman, ` of sense from "`,
                                lemmas[0].sense, `" to "`, lemmas[1].sense, `": `, lemmas[1], " => ", lemmas[0]);
                    }
                    // TODO use propagatesSense
                    // TODO replace all Nds of lemmas[0] with Nds of lemmas[1]
                    // lemmas[0].sense = lemmas[1].sense;
                    ++cnt;
                }
                break;
            default:
                break;
        }
    }
    return cnt;
}

void inferAll(Graph gr)
{
    writeln(`Inferring ...`);
    size_t inferSpecializedSensesCount = 0;
    size_t inferPhraseRelationsCount = 0;
    size_t propagateSensesCount = 0;
    foreach (pair; gr.db.ixes.lemmasByExpr.byPair)
    {
        propagateSensesCount += gr.propagateSenses(pair[1]);
        inferSpecializedSensesCount += gr.inferSpecializedSenses(pair[1]);
        inferPhraseRelationsCount += gr.inferPhraseRelations(pair[0], pair[1], [Lang.en, Lang.de, Lang.sv]);
    }
    writeln(`- Inferred Propagations of `, propagateSensesCount, ` Lemma Senses`);
    writeln(`- Inferred Specializations of `, inferSpecializedSensesCount, ` Lemma Senses`);
    writeln(`- Inferred `, inferPhraseRelationsCount, ` Noun/Verb Phrase Relations`);
    writeln(`Inference done`);
}

import knet.senses: Sense;

import std.algorithm.comparison: among;
