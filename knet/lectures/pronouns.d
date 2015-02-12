module knet.lectures.pronouns;

import std.stdio: writeln;

import knet.base;

void learnPronouns(Graph graph)
{
    writeln(`Reading Pronouns ...`);
    graph.learnEnglishPronouns();
    graph.learnSwedishPronouns();
}

void learnEnglishPronouns(Graph graph)
{
    enum lang = Lang.en;

    // Singular
    graph.learnMto1(lang, [`I`, `me`], Role(Rel.instanceOf), `singular personal pronoun`, Sense.pronounPersonalSingular1st, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`you`], Role(Rel.instanceOf), `singular personal pronoun`, Sense.pronounPersonalSingular2nd, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`it`], Role(Rel.instanceOf), `singular personal pronoun`, Sense.pronounPersonalSingular, Sense.nounPhrase, 1.0);

    graph.learnMto1(lang, [`he`], Role(Rel.instanceOf), `1st-person male singular personal pronoun`, Sense.pronounPersonalSingularMale1st, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`him`], Role(Rel.instanceOf), `2nd-person male singular personal pronoun`, Sense.pronounPersonalSingularMale2nd, Sense.nounPhrase, 1.0);

    graph.learnMto1(lang, [`she`], Role(Rel.instanceOf), `1st-person female singular personal pronoun`, Sense.pronounPersonalSingularFemale1st, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`her`], Role(Rel.instanceOf), `2nd-person female singular personal pronoun`, Sense.pronounPersonalSingularFemale2nd, Sense.nounPhrase, 1.0);

    graph.learnMto1(lang, [`we`, `us`], Role(Rel.instanceOf), `1st-person plural personal pronoun`, Sense.pronounPersonalPlural1st, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`you`], Role(Rel.instanceOf), `2nd-person plural personal pronoun`, Sense.pronounPersonalPlural2nd, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`they`, `they`], Role(Rel.instanceOf), `3rd-person plural personal pronoun`, Sense.pronounPersonalPlural3rd, Sense.nounPhrase, 1.0);

    graph.learnMto1(lang, [`this`, `that`], Role(Rel.instanceOf), `singular demonstrative pronoun`, Sense.pronounDemonstrativeSingular, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`these`, `those`], Role(Rel.instanceOf), `plural demonstrative pronoun`, Sense.pronounDemonstrativePlural, Sense.nounPhrase, 1.0);

    // Possessive
    graph.learnMto1(lang, [`my`, `your`], Role(Rel.instanceOf), `singular possessive adjective`, Sense.adjectivePossessiveSingular, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`our`, `their`], Role(Rel.instanceOf), `plural possessive adjective`, Sense.adjectivePossessivePlural, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`mine`, `yours`], Role(Rel.instanceOf), `singular possessive pronoun`, Sense.pronounPossessiveSingular, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`his`], Role(Rel.instanceOf), `male singular possessive pronoun`, Sense.pronounPossessiveSingularMale, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`hers`], Role(Rel.instanceOf), `female singular possessive pronoun`, Sense.pronounPossessiveSingularFemale, Sense.nounPhrase, 1.0);

    graph.learnMto1(lang, [`ours`], Role(Rel.instanceOf), `1st-person plural possessive pronoun`, Sense.pronounPossessivePlural1st, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`yours`], Role(Rel.instanceOf), `2nd-person plural possessive pronoun`, Sense.pronounPossessivePlural2nd, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`theirs`], Role(Rel.instanceOf), `3rd-person plural possessive pronoun`, Sense.pronounPossessivePlural3rd, Sense.nounPhrase, 1.0);

    graph.learnMto1(lang, [`who`, `whom`, `what`, `which`, `whose`, `whoever`, `whatever`, `whichever`], Role(Rel.instanceOf), `interrogative pronoun`, Sense.pronounInterrogative, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`myself`, `yourself`, `himself`, `herself`, `itself`], Role(Rel.instanceOf), `singular reflexive pronoun`, Sense.pronounReflexiveSingular, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`ourselves`, `yourselves`, `themselves`], Role(Rel.instanceOf), `plural reflexive pronoun`, Sense.pronounReflexivePlural, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`each other`, `one another`], Role(Rel.instanceOf), `reciprocal pronoun`, Sense.pronounReciprocal, Sense.nounPhrase, 1.0);

    graph.learnMto1(lang, [`who`, `whom`, // generally only for people
                           `whose`, // possession
                           `which`, // things
                           `that` // things and people
                        ], Role(Rel.instanceOf), `relative pronoun`, Sense.pronounRelative, Sense.nounPhrase, 1.0);

    graph.learnMto1(lang, [`all`, `any`, `more`, `most`, `none`, `some`, `such`], Role(Rel.instanceOf), `indefinite pronoun`, Sense.pronounIndefinitePlural, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`another`, `anybody`, `anyone`, `anything`, `each`, `either`, `enough`,
                           `everybody`, `everyone`, `everything`, `less`, `little`, `much`, `neither`,
                           `nobody`, `noone`, `one`, `other`,
                           `somebody`, `someone`,
                           `something`, `you`], Role(Rel.instanceOf), `singular indefinite pronoun`, Sense.pronounIndefiniteSingular, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`both`, `few`, `fewer`, `many`, `others`, `several`, `they`], Role(Rel.instanceOf), `plural indefinite pronoun`, Sense.pronounIndefinitePlural, Sense.nounPhrase, 1.0);

    // Rest
    graph.learnMto1(lang, rdT(`../knowledge/en/pronoun.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `pronoun`, Sense.pronoun, Sense.nounSingular, 1.0); // TODO Remove?
}

void learnSwedishPronouns(Graph graph)
{
    enum lang = Lang.sv;

    // Personal
    graph.learnMto1(lang, [`jag`, `mig`], Role(Rel.instanceOf), `1st-person singular personal pronoun`, Sense.pronounPersonalSingular1st, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`du`, `dig`], Role(Rel.instanceOf), `2nd-person singular personal pronoun`, Sense.pronounPersonalSingular2nd, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`den`, `det`], Role(Rel.instanceOf), `3rd-person singular personal pronoun`, Sense.pronounPersonalSingular3rd, Sense.nounPhrase, 1.0);

    graph.learnMto1(lang, [`han`], Role(Rel.instanceOf), `1st-person male singular personal pronoun`, Sense.pronounPersonalSingularMale1st, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`honom`], Role(Rel.instanceOf), `2nd-person male singular personal pronoun`, Sense.pronounPersonalSingularMale2nd, Sense.nounPhrase, 1.0);

    graph.learnMto1(lang, [`hon`], Role(Rel.instanceOf), `1st-person female singular personal pronoun`, Sense.pronounPersonalSingularFemale1st, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`henne`], Role(Rel.instanceOf), `2nd-person female singular personal pronoun`, Sense.pronounPersonalSingularFemale2nd, Sense.nounPhrase, 1.0);

    graph.learnMto1(lang, [`hen`], Role(Rel.instanceOf), `androgyn singular personal pronoun`, Sense.pronounPersonalSingular, Sense.nounPhrase, 1.0);

    graph.learnMto1(lang, [`vi`, `oss`], Role(Rel.instanceOf), `1st-person plural personal pronoun`, Sense.pronounPersonalPlural1st, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`ni`], Role(Rel.instanceOf), `2nd-person plural personal pronoun`, Sense.pronounPersonalPlural2nd, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`de`, `dem`], Role(Rel.instanceOf), `3rd-person plural personal pronoun`, Sense.pronounPersonalPlural3rd, Sense.nounPhrase, 1.0);

    // Possessive
    graph.learnMto1(lang, [`min`], Role(Rel.instanceOf), `1st-person singular possessive adjective`, Sense.pronounPossessiveSingular1st, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`din`], Role(Rel.instanceOf), `2nd-person possessive adjective`, Sense.pronounPossessiveSingular2nd, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`hans`], Role(Rel.instanceOf), `male singular possessive pronoun`, Sense.pronounPossessiveSingularMale, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`hennes`], Role(Rel.instanceOf), `female singular possessive pronoun`, Sense.pronounPossessiveSingularFemale, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`hens`], Role(Rel.instanceOf), `singular possessive pronoun`, Sense.pronounPossessiveSingular, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`dens`, `dets`], Role(Rel.instanceOf), `singular possessive pronoun`, Sense.pronounPossessiveSingularNeutral, Sense.nounPhrase, 1.0);

    graph.learnMto1(lang, [`vår`], Role(Rel.instanceOf), `1st-person plural possessive pronoun`, Sense.pronounPossessivePlural1st, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`er`], Role(Rel.instanceOf), `2nd-person plural possessive pronoun`, Sense.pronounPossessivePlural2nd, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`deras`], Role(Rel.instanceOf), `3rd-person plural possessive pronoun`, Sense.pronounPossessivePlural3rd, Sense.nounPhrase, 1.0);

    // Demonstrative
    graph.learnMto1(lang, [`den här`, `den där`], Role(Rel.instanceOf), `singular demonstrative pronoun`, Sense.pronounDemonstrativeSingular, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`de här`, `de där`], Role(Rel.instanceOf), `plural demonstrative pronoun`, Sense.pronounDemonstrativePlural, Sense.nounPhrase, 1.0);

    graph.learnMto1(lang, [`den`, `det`], Role(Rel.instanceOf),
                    `singular determinative pronoun`,
                    Sense.pronounDeterminativeSingular, Sense.nounPhrase, 1.0);

    graph.learnMto1(lang, [`de`, `dem`], Role(Rel.instanceOf),
                    `singular determinative pronoun`,
                    Sense.pronounDeterminativePlural, Sense.nounPhrase, 1.0);

    graph.learnMto1(lang, [`en sådan`], Role(Rel.instanceOf),
                    `singular determinative pronoun`,
                    Sense.pronounDeterminativeSingular, Sense.nounPhrase, 1.0);

    graph.learnMto1(lang, [`sådant`, `sådana`], Role(Rel.instanceOf),
                    `singular determinative pronoun`,
                    Sense.pronounDeterminativePlural, Sense.nounPhrase, 1.0);

    // Other
    graph.learnMto1(lang, [`vem`, `som`, `vad`, `vilken`, `vems`], Role(Rel.instanceOf), `interrogative pronoun`, Sense.pronounInterrogative, Sense.nounPhrase, 1.0);
    graph.learnMto1(lang, [`mig själv`, `dig själv`, `han själv`, `henne själv`, `hen själv`, `den själv`, `det själv`], Role(Rel.instanceOf), `singular reflexive pronoun`, Sense.pronounReflexiveSingular, Sense.nounPhrase, 1.0); // TODO person
    graph.learnMto1(lang, [`oss själva`, `er själva`, `dem själva`], Role(Rel.instanceOf), `plural reflexive pronoun`, Sense.pronounReflexivePlural, Sense.nounPhrase, 1.0); // TODO person
    graph.learnMto1(lang, [`varandra`], Role(Rel.instanceOf), `reciprocal pronoun`, Sense.pronounReciprocal, Sense.nounPhrase, 1.0);
}
