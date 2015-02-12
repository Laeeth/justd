module knet.lectures.usage;

import knet.base;

void learnEnglishWordUsageRanks(Graph graph)
{
    const path = `../knowledge/en/word_usage_rank.txt`;
    foreach (line; File(path).byLine)
    {
        auto split = line.splitter(roleSeparator);
        const rank = split.front.idup; split.popFront;
        const word = split.front;
        graph.connect(graph.store(word, Lang.en, Sense.unknown, Origin.manual), Role(Rel.hasAttribute),
                      graph.store(rank, Lang.en, Sense.rank, Origin.manual), Origin.manual, 1.0);
    }
}
