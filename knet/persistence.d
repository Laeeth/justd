module knet.persistence;

import msgpack;
import std.range: empty;
import knet.base;

/** Store all Data to disk. */
void save(Graph gr,
          string dirPath)
{
    const cachePath = buildNormalizedPath(dirPath.expandTilde, `knet.msgpack`);
    writeln(`Saving tables to "`, cachePath, `" ...`);
    auto file = File(cachePath, `wb`);
    file.rawWrite(gr.db.ixes.pack);
    file.rawWrite(gr.stat.pack);
}

void load(Graph gr,
          string dirPath)
{
    const cachePath = buildNormalizedPath(dirPath.expandTilde, `knet.msgpack`);
    writeln(`Loading tables from "`, cachePath, `" ...`);
    try
    {
        // TODO functionize
        auto file = File(cachePath, `rb`);
        ubyte[] dbData; dbData.length = file.size;
        file.rawRead(dbData);
        // dbData.unpack(gr.db); // TODO make this compile
        // dbData.unpack(gr.stat); // TODO make this compile
    }
    catch (std.file.FileException e)
    {
        writeln(`Failed loading tables from "`, cachePath, `"`);
    }
}

enum uniquelySenseLemmasFilename = `knet_uniquely_sensed_lemmas_within_language.msgpack`;

/** Load all Lemmas that have unique a Sense in a given language.
 */
auto loadUniquelySensedLemmas(Graph gr,
                              string dirPath)
{
    try
    {
        const cachePath = buildNormalizedPath(dirPath.expandTilde,
                                              uniquelySenseLemmasFilename);
        writeln(`Loading all Lemmas with unique Sense in a given language from "`,
                cachePath,
                `" ...`);

        // TODO functionize
        auto file = File(cachePath, `wb`);
        ubyte[] data; data.length = file.size;
        file.rawRead(data);

        size_t cnt = 0;
        while (!data.empty)
        {
            auto expr = data.unpack!MutExpr;
            auto lemma = data.unpack!Lemma;

            // TODO Use learnLemma(lemma, true) instead of these two lines
            lemma.hasUniqueSense = true;
            gr.db.ixes.lemmasByExpr[expr] = [lemma];

            ++cnt;
        }
        writeln(`Loaded `, cnt, ` Lemmas with unique Sense in a given language from "`,
                cachePath, `"`);
    }
    catch (std.file.FileException e) {}
}

/** Save all Lemmas that have unique a Sense in a given language.
 */
auto saveUniquelySensedLemmas(Graph gr,
                              string dirPath,
                              bool ignoreUnknownSense = true)
{
    const cachePath = buildNormalizedPath(dirPath.expandTilde,
                                          uniquelySenseLemmasFilename);
    writeln(`Saving all Lemmas that have unique a sense in a given language to "`,
            cachePath,
            `" ...`);
    auto file = File(cachePath, `wb`);
    size_t cnt = 0;
    foreach (pair; gr.db.ixes.lemmasByExpr.byPair)
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
    writeln(`Save `, cnt, ` number of Lemmas with a unique a Sense in a given language to "`,
            cachePath, `"`);
}
