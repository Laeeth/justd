module knet.lectures.pos;

import std.file;
import knet.base;

void learnPartOfSpeech(Graph graph)
{
    import knet.lectures.pronouns;
    graph.learnPronouns();

    import knet.lectures.adjectives;
    graph.learnAdjectives();

    import knet.lectures.adverbs;
    graph.learnAdverbs();

    import knet.lectures.articles;
    graph.learnArticles();

    import knet.lectures.conjunctions;
    graph.learnConjunctions();

    import knet.lectures.interjections;
    graph.learnInterjections();

    // Verb
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/regular_verb.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `regular verb`, Sense.verbRegular, Sense.noun, 1.0);

    graph.learnMto1(Lang.en, rdT(`../knowledge/en/determiner.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `determiner`, Sense.determiner, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/predeterminer.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `predeterminer`, Sense.predeterminer, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/adverbs.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `adverb`, Sense.adverb, Sense.noun, 1.0);
    graph.learnMto1(Lang.en, rdT(`../knowledge/en/preposition.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `preposition`, Sense.preposition, Sense.noun, 1.0);

    graph.learnMto1(Lang.en, [`since`, `ago`, `before`, `past`], Role(Rel.instanceOf), `time preposition`, Sense.prepositionTime, Sense.noun, 1.0);

    import knet.readers.moby;
    graph.learnMobyPoS();

    // learn these after Moby as Moby is more specific
    import knet.lectures.nouns;
    graph.learnNouns();

    import knet.lectures.verbs;
    graph.learnVerbs();

    graph.learnMto1(Lang.en, rdT(`../knowledge/en/figure_of_speech.txt`).splitter('\n').filter!(w => !w.empty), Role(Rel.instanceOf), `figure of speech`, Sense.unknown, Sense.noun, 1.0);

    graph.learnMobyEnglishPronounciations();
}
