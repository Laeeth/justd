module knet.io;

import std.algorithm: map;

import knet.base;
import knet.languages: Lang, toHuman;
import knet.senses: Sense, toHuman;
import knet.roles: Role;
import knet.origins: toNice;
import knet.relations: Rel, RelDir, toHuman;
import std.conv;

alias TriedLines = bool[string]; // TODO use std.container.set

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
        write(`:`, graph.db.contextNameByCtx[node.lemma.context]);
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

        auto lns = graph.lnsOf(lineNode, RelDir.any, Role(rel, false, negation)).array;

        import std.algorithm: multiSort;
        import dbg: dln;
        dln("warning: multiSort is disabled");
        // lns.multiSort!((a, b) => (graph[a].nweight >
        //                           graph[b].nweight),
        //                (a, b) => (graph[a].role.rel.rank <
        //                           graph[b].role.rel.rank),
        //                (a, b) => (graph[a].role.rel <
        //                           graph[b].role.rel));

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
    import std.algorithm: splitter;
    import std.string: strip;
    import std.range: empty;

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
        foreach (palindromeNode; graph.db.allNodes.filter!(node =>
                                                           node.lemma.expr.toLower.isPalindrome(3)))
        {
            graph.showLinkNode(palindromeNode,
                               Rel.instanceOf,
                               NWeight.infinity,
                               RelDir.backward);
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
                                   RelDir.backward);
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
                                   RelDir.backward);
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
                                   RelDir.backward);
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
                                   RelDir.backward);
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
    else if (normLine.skipOverShortestOf(`begin(`,
                                         `begins(`,
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
    else if (normLine.skipOverShortestOf(`end(`,
                                         `ends(`,
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
        catch (std.conv.ConvException e)
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
        catch (std.conv.ConvException e)
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
            const nonIPLine = normLine.dropOne;
            // writeln(`> As a non-interpuncted ``, nonIPLine, `"`);
            graph.showNodes(nonIPLine, lang, sense, lineSeparator, triedLines, depth + 1);
        }

        // non-interpuncted
        if (normLine.endsWith('.', '?', '!'))
        {
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
