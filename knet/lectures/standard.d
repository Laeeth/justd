module knet.lectures.standard;

import std.file;
import knet.base;
import knet.lectures.precise;
import knet.lectures.trained;

void learnDefault(Graph graph)
{
    // absolute (trusthful) things before untrusted machine generated data
    graph.learnPreciseThings();

    import knet.readers.wordnet;
    graph.readWordNet(`../knowledge/en/wordnet`);

    import knet.lectures.trained;
    graph.learnTrainedThings();

    import knet.lectures.associations;
    graph.learnAssociativeThings();
}
