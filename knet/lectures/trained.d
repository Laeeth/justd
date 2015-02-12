module knet.lectures.trained;

import knet.base;

/// Learn Externally (Trained) Supervised Things.
void learnTrainedThings(Graph graph)
{
    import knet.readers.swesaurus;
    graph.readSwesaurus;

    const quick = true;
    const maxCount = quick ? 50000 : size_t.max; // 50000 doesn't crash CN5

    // CN5
    import knet.readers.cn5;
    graph.readCN5(`~/Knowledge/conceptnet5-5.3/data/assertions/`, maxCount);

    // NELL
    import knet.readers.nell;
    //graph.readNELLFile(`~/Knowledge/nell/NELL.08m.895.esv.csv`, maxCount);
}
