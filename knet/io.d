module knet.io;

import std.conv: ConvException;
import std.algorithm: findSplitBefore;

import knet.base;
import knet.languages: toHuman;
import knet.senses: toHuman;
import knet.origins: toNice;
import knet.relations: RelDir, toHuman;

/** Show Network Relations.
 */
void showRelations(Graph graph,
                   uint indent_depth = 2)
{
    writeln(`Link Count by Relation Type:`);

    import std.range: cycle;
    auto indent = `- `; // TODO use clever range plus indent_depth

    foreach (rel; enumMembers!Rel)
    {
        const count = graph.stat.relCounts[rel];
        if (count)
        {
            import std.conv: to;
            writeln(indent, rel.to!string, `: `, count);
        }
    }

    writeln(`Node Count: `, graph.db.tabs.allNodes.length);

    writeln(`Node Count by Origin:`);
    foreach (source; enumMembers!Origin)
    {
        const count = graph.stat.linkSourceCounts[source];
        if (count)
        {
            writeln(indent, source.toNice, `: `, count);
        }
    }

    writeln(`Node Count by Language:`);
    foreach (lang; enumMembers!Lang)
    {
        const count = graph.stat.nodeCountByLang[lang];
        if (count)
        {
            writeln(indent, lang.toHuman, ` : `, count);
        }
    }

    writeln(`Node Count by Sense:`);
    foreach (sense; enumMembers!Sense)
    {
        const count = graph.stat.nodeCountBySense[sense];
        if (count)
        {
            writeln(indent, sense.toHuman, ` : `, count);
        }
    }

    writeln(`Stats:`);

    if (graph.stat.weightSumCN5)
    {
        writeln(indent, `CN5 Weights Min,Max,Average: `, graph.stat.weightMinCN5, ',', graph.stat.weightMaxCN5, ',', cast(NWeight)graph.stat.weightSumCN5/graph.db.tabs.allLinks.length);
        writeln(indent, `CN5 Packed Weights Histogram: `, graph.stat.pweightHistogramCN5);
    }
    if (graph.stat.weightSumNELL)
    {
        writeln(indent, `NELL Weights Min,Max,Average: `, graph.stat.weightMinNELL, ',', graph.stat.weightMaxNELL, ',', cast(NWeight)graph.stat.weightSumNELL/graph.db.tabs.allLinks.length);
        writeln(indent, `NELL Packed Weights Histogram: `, graph.stat.pweightHistogramNELL);
    }

    writeln(indent, `Node Count (All/Multi-Word): `,
            graph.db.tabs.allNodes.length,
            `/`,
            graph.stat.multiWordNodeLemmaCount);
    writeln(indent, `Lemma Expression Word Length Average: `, cast(real)graph.stat.exprWordCountSum/graph.db.ixes.ndByLemma.length);
    writeln(indent, `Link Count: `, graph.db.tabs.allLinks.length);
    writeln(indent, `Link Count By Group:`);
    writeln(indent, `- Symmetric: `, graph.stat.symmetricRelCount);
    writeln(indent, `- Transitive: `, graph.stat.transitiveRelCount);

    writeln(indent, `Lemmas Expression Count: `, graph.db.ixes.lemmasByExpr.length);

    writeln(indent, `Node Indexes by Lemma Count: `, graph.db.ixes.ndByLemma.length);
    writeln(indent, `Node String Length Average: `, cast(NWeight)graph.stat.nodeStringLengthSum/graph.db.tabs.allNodes.length);

    writeln(indent, `Node Connectedness Average: `, cast(NWeight)graph.stat.nodeConnectednessSum/graph.db.tabs.allNodes.length);
    writeln(indent, `Link Connectedness Average: `, cast(NWeight)graph.stat.linkConnectednessSum/graph.db.tabs.allLinks.length);
}

void showLink(Graph graph,
              Rel rel,
              RelDir dir,
              bool negation = false,
              Lang lang = Lang.en)
{
    auto indent = `    - `;
    write(indent, rel.toHuman(dir, negation, lang), `: `);
}

void showLn(Graph graph,
            Ln ln)
{
    auto link = graph[ln];
    graph.showLink(link.role.rel, ln.dir, link.role.negation);
}

void showNode(Graph graph,
              in Node node, NWeight weight)
{
    if (node.lemma.expr)
        write(` "`, node.lemma.expr, // .replace(`_`, ` `)
              `"`);

    write(` (`); // open

    if (node.lemma.meaningNr != 0)
    {
        write(`[`, node.lemma.meaningNr, `]`);
    }

    if (node.lemma.lang != Lang.unknown)
    {
        write(node.lemma.lang);
    }
    if (node.lemma.sense != Sense.unknown)
    {
        write(`:`, node.lemma.sense);
        if (node.lemma.hasUniqueSense)
        {
            write("(unique)");
        }
    }
    if (node.lemma.isRegexp)
    {
        write(`:rx`);
    }
    if (node.lemma.context != Ctx.asUndefined)
    {
        write(`:`, graph.db.ixes.contextNameByCtx[node.lemma.context]);
    }

    writef(`:%.0f%%-%s),`, 100*weight, node.origin.toNice); // close
}

void showLinkNode(Graph graph,
                  in Node node,
                  Rel rel,
                  NWeight weight,
                  RelDir dir)
{
    graph.showLink(rel, dir);
    graph.showNode(node, weight);
    writeln;
}

void showNds(R)(Graph graph,
                R nds,
                Rel rel = Rel.any,
                bool negation = false)
{
    foreach (nd; nds)
    {
        auto lineNode = graph[nd];

        write(`  -`);

        if (lineNode.lemma.meaningNr != 0)
        {
            write(` meaning [`, lineNode.lemma.meaningNr, `]`);
        }

        if (lineNode.lemma.lang != Lang.unknown)
        {
            write(` in `, lineNode.lemma.lang.toHuman);
        }
        if (lineNode.lemma.sense != Sense.unknown)
        {
            write(` of sense `, lineNode.lemma.sense.toHuman);
        }
        writeln;

        import knet.iteration;
        auto lns = graph.lnsOf(lineNode, RelDir.any, Role(rel, false, negation)).array;

        import std.algorithm: multiSort;
        import dbg: dln;
        dln("warning: multiSort is disabled");

        graph.sortLns(lns);

        foreach (ln; lns)
        {
            auto link = graph[ln];
            graph.showLn(ln);
            foreach (linkedNode; link.actors[]
                                     .filter!(actorNodeRef => (actorNodeRef.ix !=
                                                               nd.ix)) // don't self reference
                                     .map!(nd => graph[nd]))
            {
                graph.showNode(linkedNode, link.nweight);
            }
            writeln;
        }
    }
}

void showFixedLine(string line)
{
    writeln(`> Line "`, line, `"`);
}

/** Show Languages Sorted By Falling Weight. */
void showTopLanguages(Graph graph,
                      NWeight[Lang] hist, size_t maxCount = size_t.max)
{
    size_t i = 0;
    import std.algorithm: sort;
    foreach (e; hist.pairs.sort!((a, b) => (a[1] > b[1])))
    {
        if (i == maxCount) { break; }
        writeln(`  - `, e[0].toHuman, `: `, e[1], ` #hits`);
        ++i;
    }
}

alias TriedLines = bool[string]; // TODO use std.container.set

bool showNodes(Graph graph,
               string line,
               Lang lang = Lang.unknown,
               Sense sense = Sense.unknown,
               string lineSeparator = `_`,
               TriedLines triedLines = TriedLines.init,
               uint depth = 0)
{
    import dbg: dln;

    if      (depth == 0) { graph.showNodesSW.start(); } // if top-level call start it
    else if (depth >= graph.fuzzyExprMatchMaximumRecursionDepth)
    {
        // writeln(`Maximum recursion depth reached for `, line, ` ...`);
        return false;       // limit maximum recursion depth
    }
    if (graph.showNodesSW.peek().msecs >= graph.durationInMsecs)
    {
        // writeln(`Out of time. Skipping testing of `, line, ` ...`);
        return false;
    }

    import std.ascii: whitespace;
    import std.string: strip;

    import knet.iteration;
    import knet.searching;

    if (line in triedLines) // if already tested
        return false;
    triedLines[line] = true;

    // dln(`depth:`, depth, ` line: `, line);

    // auto normLine = line.strip.splitter!isWhite.filter!(a => !a.empty).joiner(lineSeparator).to!S;
    // See also: http://forum.dlang.org/thread/pyabxiraeabfxujiyamo@forum.dlang.org#post-euqwxskfypblfxiqqtga:40forum.dlang.org
    auto normLine = line.strip.tr(whitespace, ` `, `s`);
    if (normLine.empty)
        return false;

    if (normLine == `palindrome`)
    {
        foreach (palindromeNode; graph.db.tabs.allNodes.filter!(node =>
                                                                node.lemma.expr.toLower.isPalindrome(3)))
        {
            graph.showLinkNode(palindromeNode,
                               Rel.instanceOf,
                               NWeight.infinity,
                               RelDir.bwd);
        }
    }
    else if (normLine.skipOverShortestOf(`anagramsof(`,
                                         `anagrams_of(`))
    {
        const split = normLine.findSplitBefore(`)`);
        const arg = split[0];
        if (!arg.empty)
        {
            foreach (anagramNode; graph.anagramsOf(arg))
            {
                graph.showLinkNode(anagramNode,
                                   Rel.instanceOf,
                                   NWeight.infinity,
                                   RelDir.bwd);
            }
        }
    }
    else if (normLine.skipOverShortestOf(`synonymsof(`,
                                         `synonyms_of(`))
    {
        const split = normLine.findSplitBefore(`)`);
        const arg = split[0];
        if (!arg.empty)
        {
            foreach (synonymNode; graph.synonymsOf(arg))
            {
                graph.showLinkNode(graph[synonymNode],
                                   Rel.instanceOf,
                                   NWeight.infinity,
                                   RelDir.bwd);
            }
        }
    }
    else if (normLine.skipOverShortestOf(`rhymesof(`,
                                         `rhymes_of(`))
    {
        const split = normLine.findSplitBefore(`)`);
        const arg = split[0];
        if (!arg.empty)
        {
            writeln(`> Rhymes of "`, arg, `" are:`);
            foreach (rhymingNode; graph.rhymesOf(arg))
            {
                graph.showLinkNode(graph[rhymingNode],
                                   Rel.instanceOf,
                                   NWeight.infinity,
                                   RelDir.bwd);
            }
        }
    }
    else if (normLine.skipOverShortestOf(`translationsof(`,
                                         `translations_of(`,
                                         `translate(`))
    {
        const split = normLine.findSplitBefore(`)`);
        const arg = split[0];
        if (!arg.empty)
        {
            foreach (translationNode; graph.translationsOf(arg))
            {
                graph.showLinkNode(graph[translationNode],
                                   Rel.instanceOf,
                                   NWeight.infinity,
                                   RelDir.bwd);
            }
        }
    }
    else if (normLine.skipOverShortestOf(`languagesof(`,
                                         `languages_of(`,
                                         `langsof(`,
                                         `langs(`))
    {
        normLine.skipOver(` `); // TODO all space using skipOver!isSpace
        const split = normLine.findSplitBefore(`)`);
        const arg = split[0];
        if (!arg.empty)
        {
            auto hist = graph.languagesOf(arg.splitter(` `));
            graph.showTopLanguages(hist);
        }
    }
    else if (normLine.skipOverShortestOf(`languageof(`,
                                         `language_of(`,
                                         `langof(`,
                                         `lang(`))
    {
        normLine.skipOver(` `); // TODO all space using skipOver!isSpace
        const split = normLine.findSplitBefore(`)`);
        const arg = split[0];
        if (!arg.empty)
        {
            auto hist = graph.languagesOf(arg.splitter(` `));
            graph.showTopLanguages(hist, 1);
        }
    }
    else if (normLine.skipOverShortestOf(`prefix(`,
                                         `begin(`,
                                         `begins(`,
                                         `start(`,
                                         `starts(`,
                                         `startswith(`,
                                         `starts_with(`,
                                         `beginswith(`,
                                         `begins_with(`,
                                         `hasbegin(`,
                                         `hasbeginning(`,
                                         `has_begin(`,
                                         `hasstart(`,
                                         `has_start(`))
    {
        normLine.skipOver(` `); // TODO all space using skipOver!isSpace
        const split = normLine.findSplitBefore(`)`);
        const arg = split[0];
        if (!arg.empty)
        {
            auto hits = graph.startsWith(arg);
            foreach (node; hits.map!(a => graph[a]))
            {
                graph.showNode(node, 1.0);
                writeln;
            }
        }
    }
    else if (normLine.skipOverShortestOf(`suffix(`,
                                         `end(`,
                                         `ends(`,
                                         `finish(`,
                                         `finishes(`,
                                         `endswith(`,
                                         `ends_with(`,
                                         `hasend(`,
                                         `has_end(`,
                                         `hassuffix(`,
                                         `has_suffix(`))
    {
        normLine.skipOver(` `); // TODO all space using skipOver!isSpace
        const split = normLine.findSplitBefore(`)`);
        const arg = split[0];
        if (!arg.empty)
        {
            auto hits = graph.endsWith(arg);
            foreach (node; hits.map!(a => graph[a]))
            {
                graph.showNode(node, 1.0);
                writeln;
            }
        }
    }
    else if (normLine.skipOverShortestOf(`canfind(`,
                                         `can_find(`,
                                         `contain(`,
                                         `contains(`))
    {
        normLine.skipOver(` `); // TODO all space using skipOver!isSpace
        const split = normLine.findSplitBefore(`)`);
        const arg = split[0];
        if (!arg.empty)
        {
            auto hits = graph.canFind(arg);
            foreach (node; hits.map!(a => graph[a]))
            {
                graph.showNode(node, 1.0);
                writeln;
            }
        }
    }
    else if (normLine.skipOver(`as`)) // asSense
    {
        const split = normLine.findSplit(`(`);
        const senseString = split[0].strip;
        const arg = split[2].until(')').array.strip;
        try
        {
            const qSense = senseString.toLower.to!Sense;
            dln(senseString, `, `, arg, ` `, qSense);
        }
        catch (ConvException e)
        {
        }
    }
    else if (normLine.skipOver(`in`)) // inLanguage
    {
        const split = normLine.findSplit(`(`);
        const langString = split[0].strip;
        const arg = split[2].until(')').array.strip;
        try
        {
            const qLang = langString.toLower.to!Lang;
            dln(langString, `, `, arg, ` `, qLang);
        }
        catch (ConvException e)
        {
        }
    }

    if (normLine.empty)
        return false;

    // queried line nodes
    auto lineNds = graph.ndsOf(normLine, lang, sense);

    if (!lineNds.empty)
    {
        showFixedLine(normLine);
        graph.showNds(lineNds);
    }

    enum commonSplitters = [` `, // prefer space
                            `-`,
                            `'`];

    enum commonJoiners = [` `, // prefer space
                          `-`,
                          ``,
                          `'`];

    import std.algorithm.iteration: joiner;

    // try joined
    if (lineNds.empty)
    {
        auto spaceWords = normLine.splitter(' ').filter!(a => !a.empty);
        if (spaceWords.count >= 2)
        {
            foreach (combWords; permutations.permutations(spaceWords.array)) // TODO remove .array
            {
                foreach (separator; commonJoiners)
                {
                    graph.showNodes(combWords.joiner(separator).to!string,
                                    lang, sense, lineSeparator, triedLines, depth + 1);
                }
            }
        }

        auto minusWords = normLine.splitter('-').filter!(a => !a.empty);
        if (minusWords.count >= 2)
        {
            foreach (separator; commonJoiners)
            {
                graph.showNodes(minusWords.joiner(separator).to!string,
                                lang, sense, lineSeparator, triedLines, depth + 1);
            }
        }

        auto quoteWords = normLine.splitter(`'`).filter!(a => !a.empty);
        if (quoteWords.count >= 2)
        {
            foreach (separator; commonJoiners)
            {
                graph.showNodes(quoteWords.joiner(separator).to!string,
                                lang, sense, lineSeparator, triedLines, depth + 1);
            }
        }

        // stemmed
        auto stemLine = normLine;
        while (true)
        {
            import stemming;
            const stemResult = stemLine.stemIn(lang);
            auto stemMoreLine = stemResult[0];
            const stemLang = stemResult[1];
            if (stemMoreLine == stemLine)
                break;
            // writeln(`> Stemmed to ``, stemMoreLine, `` in language `, stemLang);
            graph.showNodes(stemMoreLine, stemLang, sense, lineSeparator, triedLines, depth + 1);
            stemLine = stemMoreLine;
        }

        import std.algorithm: startsWith, endsWith;

        // non-interpuncted
        if (normLine.startsWith('.', '?', '!'))
        {
            import std.range: dropOne;
            const nonIPLine = normLine.dropOne;
            // writeln(`> As a non-interpuncted ``, nonIPLine, `"`);
            graph.showNodes(nonIPLine, lang, sense, lineSeparator, triedLines, depth + 1);
        }

        // non-interpuncted
        if (normLine.endsWith('.', '?', '!'))
        {
            import std.range: dropBackOne;
            const nonIPLine = normLine.dropBackOne;
            // writeln(`> As a non-interpuncted "`, nonIPLine, `"`);
            graph.showNodes(nonIPLine, lang, sense, lineSeparator, triedLines, depth + 1);
        }

        // interpuncted
        if (!normLine.endsWith('.') &&
            !normLine.endsWith('?') &&
            !normLine.endsWith('!'))
        {
            // questioned
            const questionedLine = normLine ~ '?';
            // writeln(`> As a question "`, questionedLine, `"`);
            graph.showNodes(questionedLine, lang, sense, lineSeparator, triedLines, depth + 1);

            // exclaimed
            const exclaimedLine = normLine ~ '!';
            // writeln(`> As an exclamation "`, exclaimedLine, `"`);
            graph.showNodes(exclaimedLine, lang, sense, lineSeparator, triedLines, depth + 1);

            // dotted
            const dottedLine = normLine ~ '.';
            // writeln(`> As a dotted "`, dottedLine, `"`);
            graph.showNodes(dottedLine, lang, sense, lineSeparator, triedLines, depth + 1);
        }

        // lowered
        const loweredLine = normLine.toLower;
        if (loweredLine != normLine)
        {
            // writeln(`> Lowercased to "`, loweredLine, `"`);
            graph.showNodes(loweredLine, lang, sense, lineSeparator, triedLines, depth + 1);
        }

        // uppered
        const upperedLine = normLine.toUpper;
        if (upperedLine != normLine)
        {
            // writeln(`> Uppercased to "`, upperedLine, `"`);
            graph.showNodes(upperedLine, lang, sense, lineSeparator, triedLines, depth + 1);
        }

        // capitalized
        const capitalizedLine = normLine.capitalize;
        if (capitalizedLine != normLine)
        {
            // writeln(`> Capitalized to (name) "`, capitalizedLine, `"`);
            graph.showNodes(capitalizedLine, lang, sense, lineSeparator, triedLines, depth + 1);
        }
    }

    return false;
}
