module knet.lectures.articles;

import knet.base;
import knet.separators;

void learnArticles(Graph graph)
{
    graph.learnUndefiniteArticles();
    graph.learnDefiniteArticles();
    graph.learnPartitiveArticles();
}

void learnDefiniteArticles(Graph graph)
{
    writeln(`Reading Definite Articles ...`);

    graph.learnMto1(Lang.en, [`the`],
                    Role(Rel.instanceOf), `definite article`, Sense.articleDefinite, Sense.nounPhrase, 1.0);
    graph.learnMto1(Lang.de, [`der`, `die`, `das`, `des`, `dem`, `den`],
                    Role(Rel.instanceOf), `definite article`, Sense.articleDefinite, Sense.nounPhrase, 1.0);
    graph.learnMto1(Lang.fr, [`le`, `la`, `l'`, `les`],
                    Role(Rel.instanceOf), `definite article`, Sense.articleDefinite, Sense.nounPhrase, 1.0);
    graph.learnMto1(Lang.sv, [`den`, `det`],
                    Role(Rel.instanceOf), `definite article`, Sense.articleDefinite, Sense.nounPhrase, 1.0);
}

void learnUndefiniteArticles(Graph graph)
{
    writeln(`Reading Undefinite Articles ...`);

    graph.learnMto1(Lang.en, [`a`, `an`],
                    Role(Rel.instanceOf), `undefinite article`, Sense.articleIndefinite, Sense.nounPhrase, 1.0);
    graph.learnMto1(Lang.de, [`ein`, `eine`, `eines`, `einem`, `einen`, `einer`],
                    Role(Rel.instanceOf), `undefinite article`, Sense.articleIndefinite, Sense.nounPhrase, 1.0);
    graph.learnMto1(Lang.fr, [`un`, `une`, `des`],
                    Role(Rel.instanceOf), `undefinite article`, Sense.articleIndefinite, Sense.nounPhrase, 1.0);
    graph.learnMto1(Lang.sv, [`en`, `ena`, `ett`],
                    Role(Rel.instanceOf), `undefinite article`, Sense.articleIndefinite, Sense.nounPhrase, 1.0);
}

void learnPartitiveArticles(Graph graph)
{
    writeln(`Reading Partitive Articles ...`);

    graph.learnMto1(Lang.en, [`some`],
                    Role(Rel.instanceOf), `partitive article`, Sense.articlePartitive, Sense.nounPhrase, 1.0);
    graph.learnMto1(Lang.fr, [`du`, `de`, `la`, `de`, `l'`, `des`],
                    Role(Rel.instanceOf), `partitive article`, Sense.articlePartitive, Sense.nounPhrase, 1.0);
}
