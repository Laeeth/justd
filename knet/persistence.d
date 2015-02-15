module knet.persistence;

import msgpack;
import std.range: empty;
import knet.base;

/** Store all Data to disk. */
void save(Graph graph,
          string dirPath)
{
    const cachePath = buildNormalizedPath(dirPath.expandTilde, `knet.msgpack`);
    writeln(`Storing Tables to "`, cachePath, `" ...`);
    auto file = File(cachePath, "wb");
    file.rawWrite(graph.db.pack);
    file.rawWrite(graph.stat.pack);
}

void load(Graph graph,
          string dirPath)
{
    const cachePath = buildNormalizedPath(dirPath.expandTilde, `knet.msgpack`);
    writeln(`Loading tables from "`, cachePath, `" ...`);
    try
    {
        auto file = File(cachePath, "rb");
    }
    catch (std.file.FileException e)
    {
        writeln(`Failed loading tables from "`, cachePath, `"`);
    }
}

enum uniquelySenseLemmasFilename = `knet_uniquely_sensed_lemmas_within_language.msgpack`;

/** Load all Lemmas that have unique a Sense in a given language.
 */
auto loadUniquelySensedLemmas(Graph graph,
                              string dirPath)
{
    try
    {
        const cachePath = buildNormalizedPath(dirPath.expandTilde,
                                              uniquelySenseLemmasFilename);
        writeln(`Loading all Lemmas with unique Sense in a given language from "`,
                cachePath,
                `" ...`);
        auto file = File(cachePath, "wb");
        ubyte[] data; file.rawRead(data);
        size_t cnt = 0;
        while (!data.empty)
        {
            auto expr = data.unpack!MutExpr;
            auto lemma = data.unpack!Lemma;

            // TODO Use learnLemma(lemma, true) instead of these two lines
            lemma.hasUniqueSense = true;
            graph.db.lemmasByExpr[expr] = [lemma];

            ++cnt;
        }
        writeln(`Loaded `, cnt, ` Lemmas with unique Sense in a given language from "`,
                cachePath, `"`);
    }
    catch (std.file.FileException e) {}
}

/** Save all Lemmas that have unique a Sense in a given language.
 */
auto saveUniquelySensedLemmas(Graph graph,
                              string dirPath,
                              bool ignoreUnknownSense = true)
{
    const cachePath = buildNormalizedPath(dirPath.expandTilde,
                                          uniquelySenseLemmasFilename);
    writeln(`Storing all Lemmas that have unique a sense in a given language to "`,
            cachePath,
            `" ...`);
    auto file = File(cachePath, "wb");
    size_t cnt = 0;
    foreach (pair; graph.db.lemmasByExpr.byPair)
    {
        const expr = pair[0];
        auto lemmas = pair[1];
        auto filteredLemmas = lemmas.filter!(lemma => lemma.sense != Sense.unknown);
        if (!filteredLemmas.empty &&
            filteredLemmas.allEqual)
        {
            file.rawWrite(expr.pack);
            import std.range: front;
            file.rawWrite(lemmas.front.pack);
            ++cnt;
        }
    }
    writeln(`Stored `, cnt, ` number of Lemmas with a unique a Sense in a given language to "`,
            cachePath, `"`);
}
