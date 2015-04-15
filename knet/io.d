module knet.io;

import std.conv: to, ConvException;
import std.algorithm: findSplitBefore;

import knet.base;
import knet.languages: toHuman;
import knet.senses: toHuman;
import knet.origins: toNice;
import knet.relations: RelDir;
import knet.roles: toHuman;

/** Show Network Relations.
 */
void showRelations(Graph gr,
                   uint indent_depth = 2)
{
    writeln(`Link Count by Relation Type:`);

    import std.range: cycle;
    auto indent = `- `; // TODO use clever range plus indent_depth

    foreach (rel; enumMembers!Rel)
    {
        const count = gr.stat.relCounts[rel];
        if (count)
        {
            writeln(indent, rel.to!string, `: `, count);
        }
    }

    writeln(`Node Count: `, gr.db.tabs.allNodes.length);

    writeln(`Node Count by Origin:`);
    foreach (source; enumMembers!Origin)
    {
        const count = gr.stat.linkSourceCounts[source];
        if (count)
        {
            writeln(indent, source.toNice, `: `, count);
        }
    }

    writeln(`Node Count by Language:`);
    foreach (lang; enumMembers!Lang)
    {
        const count = gr.stat.nodeCountByLang[lang];
        if (count)
        {
            writeln(indent, lang.toHuman, ` : `, count);
        }
    }

    writeln(`Node Count by Sense:`);
    foreach (sense; enumMembers!Sense)
    {
        const count = gr.stat.nodeCountBySense[sense];
        if (count)
        {
            writeln(indent, sense.toHuman, ` : `, count);
        }
    }

    writeln(`Stats:`);

    if (gr.stat.weightSumCN5)
    {
        writeln(indent, `CN5 Weights Min,Max,Average: `, gr.stat.weightMinCN5, ',', gr.stat.weightMaxCN5, ',', cast(NWeight)gr.stat.weightSumCN5/gr.db.tabs.allLinks.length);
        writeln(indent, `CN5 Packed Weights Histogram: `, gr.stat.pweightHistogramCN5);
    }
    if (gr.stat.weightSumNELL)
    {
        writeln(indent, `NELL Weights Min,Max,Average: `, gr.stat.weightMinNELL, ',', gr.stat.weightMaxNELL, ',', cast(NWeight)gr.stat.weightSumNELL/gr.db.tabs.allLinks.length);
        writeln(indent, `NELL Packed Weights Histogram: `, gr.stat.pweightHistogramNELL);
    }

    writeln(indent, `Node Count (All/Multi-Word): `,
            gr.db.tabs.allNodes.length,
            `/`,
            gr.stat.multiWordNodeLemmaCount);
    writeln(indent, `Lemma Expression Word Length Average: `, cast(real)gr.stat.exprWordCountSum/gr.db.ixes.ndByLemma.length);
    writeln(indent, `Link Count: `, gr.db.tabs.allLinks.length);
    writeln(indent, `Link Count By Group:`);
    writeln(indent, `- Symmetric: `, gr.stat.symmetricRelCount);
    writeln(indent, `- Transitive: `, gr.stat.transitiveRelCount);

    writeln(indent, `Lemmas Expression Count: `, gr.db.ixes.lemmasByExpr.length);

    writeln(indent, `Node Indexes by Lemma Count: `, gr.db.ixes.ndByLemma.length);
    writeln(indent, `Node String Length Average: `, cast(NWeight)gr.stat.nodeStringLengthSum/gr.db.tabs.allNodes.length);

    writeln(indent, `Node Connectedness Average: `, cast(NWeight)gr.stat.nodeConnectednessSum/gr.db.tabs.allNodes.length);
    writeln(indent, `Link Connectedness Average: `, cast(NWeight)gr.stat.linkConnectednessSum/gr.db.tabs.allLinks.length);
}

void showLink(Graph gr, Role role, Lang lang = Lang.en, RelDir dir = RelDir.fwd)
{
    enum indent = `    - `;
    if (dir == RelDir.bwd)
    {
        role.reversed = true;
    }
    write(indent, role.toHuman(lang), `: `);
}

void showLink(Graph gr, in Link link, Lang lang = Lang.en)
{
    enum indent = `    - `;
    write(indent, link.role.toHuman(lang), `: `);
}

void showLn(Graph gr, Ln ln, Lang lang = Lang.en)
{
    gr.showLink(gr[ln].role, lang, ln.dir);
}

void showNode(Graph gr,
              in Node node, NWeight weight = 1.0)
{
    if (node.lemma.expr)
        write(`"`, node.lemma.expr, // .replace(`_`, ` `)
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
        write(`:`, gr.db.ixes.contextNameByCtx[node.lemma.context]);
    }

    writef(`:%.0f%%-%s)`, 100*weight, node.origin.toNice); // close
}

void showNode(Graph gr,
              const Nd nd, NWeight weight)
{
    gr.showNode(gr[nd], weight);
}

void showLinkNode(Graph gr,
                  in Node node,
                  Role role,
                  NWeight weight,
                  Lang lang = Lang.en)
{
    gr.showLink(role, lang);
    gr.showNode(node, weight);
    writeln;
}

void showNds(R)(Graph gr,
                R nds,
                Rel rel = Rel.any,
                bool negation = false)
{
    foreach (nd; nds)
    {
        auto lineNode = gr[nd];

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
        auto lns = gr.lnsOf(lineNode, RelDir.any, Role(rel, false, negation)).array;
        gr.sortLns(lns);
        foreach (ln; lns)
        {
            auto link = gr[ln];
            gr.showLn(ln);
            foreach (linkedNode; link.actors[]
                                     .filter!(actorNodeRef => (actorNodeRef.ix !=
                                                               nd.ix)) // don't self reference
                                     .map!(nd => gr[nd]))
            {
                gr.showNode(linkedNode, link.nweight);
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
void showTopLanguages(Graph gr,
                      NWeight[Lang] hist,
                      size_t maxCount = size_t.max)
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

void showSenses(Senses)(Graph gr,
                        Senses senses,
                        size_t maxCount = size_t.max) if (isIterableOf!(Senses, Sense))
{
    size_t i = 0;
    foreach (e; senses)
    {
        if (i == maxCount) { break; }
        writeln(`  - `, e.toHuman);
        ++i;
    }
}

alias TriedLines = bool[string]; // TODO use std.container.set

bool query(Graph gr,
           string line,
           Lang userLang = Lang.unknown,
           Sense userSense = Sense.unknown,
           uint userCount = 20,
           string lineSeparator = `_`,
           TriedLines triedLines = TriedLines.init,
           uint depth = 0,
           bool exact = false) // perform exact quoted match
{
    import dbg: dln;

    import std.algorithm.iteration: joiner;

    if      (depth == 0) { gr.querySW.start(); } // if top-level call start it
    else if (depth >= gr.fuzzyExprMatchMaximumRecursionDepth)
    {
        // writeln(`Maximum recursion depth reached for `, line, ` ...`);
        return false;       // limit maximum recursion depth
    }
    if (gr.querySW.peek().msecs >= gr.durationInMsecs)
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

    // exact match
    if (exact)
    {
        auto exactLineNds = gr.ndsOf(normLine, userLang, userSense);
        if (!exactLineNds.empty)
        {
            showFixedLine(normLine);
            gr.showNds(exactLineNds);
            return true;
        }
        return false;
    }

    // try: $(NUMBER) $(Lang)
    auto counted = normLine.split(' ');
    if (counted.length >= 2)
    {
        try
        {
            const count = counted[0].to!(typeof(userCount));
            const hit = gr.query(counted[1 .. $].joiner(` `).to!string,
                                 userLang, userSense, count, lineSeparator,
                                 triedLines, depth + 1); // recurse
            if (hit) { return hit; }
        }
        catch (Exception e) {}
    }

    // try: $(EXPR) in $(Lang)
    auto suffixLangedWords = normLine.split(' ');
    if (suffixLangedWords.length >= 3 &&
        suffixLangedWords[$ - 2] == `in`)
    {
        Lang inLang = Lang.unknown;

        // try to lookup. TODO functionize to generic fuzzyTo
        try
        {
            inLang = suffixLangedWords[$ - 1].to!Lang;
        }
        catch (Exception e)
        {
            try
            {
                inLang = suffixLangedWords[$ - 1].toLower.to!Lang;
            }
            catch (Exception e)
            {
            }
        }

        if (inLang != Lang.unknown)
        {
            const hit = gr.query(suffixLangedWords[0 .. $ - 2].joiner(` `).to!string,
                                 inLang, userSense, userCount, lineSeparator,
                                 triedLines, depth + 1); // recurse
            if (hit) { return hit; }
        }
    }

    // try: $(EXPR) as $(Sense)
    auto suffixSensedWords = normLine.split(' ');
    if (suffixSensedWords.length >= 3 &&
        suffixSensedWords[$ - 2] == `as`)
    {
        Sense asSense = Sense.unknown;

        // try to lookup. TODO functionize to generic fuzzyTo
        try
        {
            asSense = suffixSensedWords[$ - 1].to!Sense;
        }
        catch (Exception e)
        {
            try
            {
                asSense = suffixSensedWords[$ - 1].toLower.to!Sense;
            }
            catch (Exception e) {}
        }

        if (asSense != Sense.unknown)
        {
            const hit = gr.query(suffixSensedWords[0 .. $ - 2].joiner(` `).to!string,
                                 userLang, asSense, userCount, lineSeparator,
                                 triedLines, depth + 1); // recurse
            if (hit) { return hit; }
        }
    }

    if (normLine == `palindrome`)
    {
        foreach (palindromeNode; gr.db.tabs.allNodes.filter!(node =>
                                                             node.lemma.expr.toLower.isPalindrome(3)))
        {
            gr.showLinkNode(palindromeNode,
                            Role(Rel.instanceOf, true), NWeight.infinity, userLang);
        }
    }
    else if (normLine.skipOverShortestOf(`anagrams(`, `anagramsof(`, `anagrams_of(`))
    {
        const split = normLine.findSplitBefore(`)`);
        const arg = split[0];
        if (!arg.empty)
        {
            foreach (anagramNode; gr.anagramsOf(arg))
            {
                gr.showLinkNode(anagramNode,
                                Role(Rel.instanceOf, true), NWeight.infinity, userLang);
            }
        }
    }
    else if (normLine.skipOverShortestOf(`synonymsof(`, `synonyms_of(`))
    {
        const split = normLine.findSplitBefore(`)`);
        const arg = split[0];
        if (!arg.empty)
        {
            foreach (synonymNode; gr.synonymsOf(arg))
            {
                gr.showLinkNode(gr[synonymNode],
                                Role(Rel.instanceOf, true), NWeight.infinity);
            }
        }
    }
    else if (normLine.skipOverShortestOf(`opposites(`, `oppositesof(`, `opposites_of(`,
                                         `antonyms(`, `antonymsof(`, `antonyms_of(`))
    {
        const split = normLine.findSplitBefore(`)`);
        const arg = split[0];
        if (!arg.empty)
        {
            foreach (antonymNode; gr.antonymsOf(arg))
            {
                gr.showLinkNode(gr[antonymNode],
                                Role(Rel.instanceOf, true), NWeight.infinity);
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
            foreach (rhymingNode; gr.rhymesOf(arg))
            {
                gr.showLinkNode(gr[rhymingNode],
                                Role(Rel.instanceOf, true), NWeight.infinity, userLang);
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
            foreach (translationNode; gr.translationsOf(arg))
            {
                gr.showLinkNode(gr[translationNode],
                                Role(Rel.instanceOf, true), NWeight.infinity, userLang);
            }
        }
    }
    else if (normLine.skipOverShortestOf(`sensesof(`,
                                         `senses_of(`,
                                         `senses(`))
    {
        normLine.skipOver(` `); // TODO all space using skipOver!isSpace
        const split = normLine.findSplitBefore(`)`);
        const arg = split[0];
        if (!arg.empty)
        {
            import knet.lookup: sensesOfExpr;
            auto senses = gr.sensesOfExpr(arg, true);
            gr.showSenses(senses);
        }
    }
    else if (normLine.skipOverShortestOf(`languagesof(`,
                                         `languages_of(`,
                                         `langsof(`,
                                         `languages(`,
                                         `langs(`))
    {
        normLine.skipOver(` `); // TODO all space using skipOver!isSpace
        const split = normLine.findSplitBefore(`)`);
        const arg = split[0];
        if (!arg.empty)
        {
            auto hist = gr.languagesOf(arg.splitter(` `));
            gr.showTopLanguages(hist);
        }
    }
    else if (normLine.skipOverShortestOf(`languageof(`,
                                         `language_of(`,
                                         `langof(`,
                                         `language(`,
                                         `lang(`))
    {
        normLine.skipOver(` `); // TODO all space using skipOver!isSpace
        const split = normLine.findSplitBefore(`)`);
        const arg = split[0];
        if (!arg.empty)
        {
            auto hist = gr.languagesOf(arg.splitter(` `));
            gr.showTopLanguages(hist, 1);
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
            auto hits = gr.startsWith(arg);
            foreach (node; hits.map!(a => gr[a]))
            {
                gr.showNode(node, 1.0);
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
            auto hits = gr.endsWith(arg);
            foreach (node; hits.map!(a => gr[a]))
            {
                gr.showNode(node, 1.0);
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
            auto hits = gr.canFind(arg);
            foreach (node; hits.map!(a => gr[a]))
            {
                gr.showNode(node, 1.0);
                writeln;
            }
        }
    }
    else if (normLine.skipOverShortestOf(`ctxs(`,
                                         `ctxs_of(`,
                                         `ctxsof(`,
                                         `contexts(`,
                                         `contexts_of(`,
                                         `contextsof(`))
    {
        normLine.skipOver(` `); // TODO all space using skipOver!isSpace
        const split = normLine.findSplitBefore(`)`);
        const arg = split[0];
        if (!arg.empty)
        {
            import knet.association: contextsOf, Hits;
            import knet.filtering: Filter;
            import knet.traversal: WalkStrategy;
            import std.algorithm: uniq;
            auto arg_splitter = arg.splitter.uniq;
            if (arg_splitter.count >= 2)
            {
                const walkerFilter = Filter();
                writeln("> Contexts of senses(s) ", userSense, " in language(s) ", userLang, ":");
                const result = gr.contextsOf!(WalkStrategy.dijkstraMinDistance)(arg_splitter,
                                                                                walkerFilter,
                                                                                [userLang],
                                                                                [userSense],
                                                                                userCount, 2000);
                const contexts = result[0];
                foreach (const context; contexts)
                {
                    const Nd nd = context.key;
                    const Hits hits = context.value;
                    gr.showNode(nd, hits.goodnessSum);
                    writeln(" visitCount: ", hits.visitCount);
                }
            }
        }
    }
    else if (normLine.skipOver(`nd(`))
    {
        normLine.skipOver(` `); // TODO all space using skipOver!isSpace
        const split = normLine.findSplitBefore(`)`);
        const arg = split[0];
        if (!arg.empty)
        {
            try
            {
                const ix = arg.to!(Nd.Ix);
                if (ix < gr.db.tabs.allNodes.length)
                {
                    write(`> `);
                    gr.showNode(gr[Nd(ix)], 1.0);
                    writeln;
                }
                else
                {
                    writeln(`> Node index `, ix, ` is too large`);
                }
            }
            catch (ConvException e)
            {
                writeln(`> Cannot convert nd() argument `, arg, ` to an Nd`);
            }
        }
    }
    else if (normLine.skipOver(`ln(`))
    {
        normLine.skipOver(` `); // TODO all space using skipOver!isSpace
        const split = normLine.findSplitBefore(`)`);
        const arg = split[0];
        if (!arg.empty)
        {
            try
            {
                const ix = arg.to!(Ln.Ix);
                if (ix < gr.db.tabs.allNodes.length)
                {
                    write(`> `);
                    gr.showLink(gr[Ln(ix)]);
                    writeln;
                }
                else
                {
                    writeln(`> Link index `, ix, ` is too large`);
                }
            }
            catch (ConvException e)
            {
                writeln(`> Cannot convert ln() argument `, arg, ` to an Ln`);
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
    auto lineNds = gr.ndsOf(normLine, userLang, userSense); // TODO move this calculation up to top
    if (!lineNds.empty)
    {
        showFixedLine(normLine);
        gr.showNds(lineNds);
        return true;
    }

    enum commonSplitters = [` `, // prefer space
                            `-`,
                            `'`];

    enum commonJoiners = [` `, // prefer space
                          `-`,
                          ``,
                          `'`];

    // try modified line
    if (lineNds.empty)
    {
        // try: "$(EXPR)"
        import std.algorithm.searching: startsWith, endsWith;
        if (normLine.startsWith(`"`) &&
            normLine.endsWith(`"`))
        {
            const hit = gr.query(normLine[1 .. $ - 1],
                                 userLang, userSense, userCount, lineSeparator,
                                 triedLines, depth + 1, true); // recurse
            if (hit) { return hit; }
        }

        // try: $(Sense):$(EXPR)
        auto qualifierSplit = normLine.findSplit(qualifierSeparatorString);
        if (!qualifierSplit[0].empty &&
            !qualifierSplit[1].empty &&
            !qualifierSplit[2].empty)
        {
            try
            {
                const inSense = qualifierSplit[0].to!Sense;
                const hit = gr.query(qualifierSplit[2],
                                     userLang, inSense, userCount, lineSeparator,
                                     triedLines, depth + 1); // recurse
                if (hit) { return hit; }
            }
            catch (Exception e) {}
            try
            {
                const inLang = qualifierSplit[0].to!Lang;
                const hit = gr.query(qualifierSplit[2],
                                     inLang, userSense, userCount, lineSeparator,
                                     triedLines, depth + 1); // recurse
                if (hit) { return hit; }
            }
            catch (Exception e) {}
        }

        auto spaceWords = normLine.splitter(' ').filter!(a => !a.empty);
        if (spaceWords.count >= 2)
        {
            foreach (combWords; permutations.permutations(spaceWords.array)) // TODO remove .array
            {
                foreach (separator; commonJoiners)
                {
                    gr.query(combWords.joiner(separator).to!string,
                             userLang, userSense, userCount, lineSeparator, triedLines, depth + 1); // recurse
                }
            }
        }

        auto minusWords = normLine.splitter('-').filter!(a => !a.empty);
        if (minusWords.count >= 2)
        {
            foreach (separator; commonJoiners)
            {
                gr.query(minusWords.joiner(separator).to!string,
                         userLang, userSense, userCount, lineSeparator, triedLines, depth + 1); // recurse
            }
        }

        auto quoteWords = normLine.splitter(`'`).filter!(a => !a.empty);
        if (quoteWords.count >= 2)
        {
            foreach (separator; commonJoiners)
            {
                gr.query(quoteWords.joiner(separator).to!string,
                         userLang, userSense, userCount, lineSeparator, triedLines, depth + 1); // recurse
            }
        }

        // stemmed
        auto stemLine = normLine;
        while (true)
        {
            import stemming;
            const stemResult = stemLine.stemIn(userLang);
            auto stemMoreLine = stemResult[0];
            const stemLang = stemResult[1];
            if (stemMoreLine == stemLine)
                break;
            // writeln(`> Stemmed to ``, stemMoreLine, `` in language `, stemLang);
            gr.query(stemMoreLine,
                     stemLang, userSense, userCount, lineSeparator, triedLines, depth + 1); // recurse
            stemLine = stemMoreLine;
        }

        import std.algorithm: startsWith, endsWith;

        // non-interpuncted
        if (normLine.startsWith('.', '?', '!'))
        {
            import std.range: dropOne;
            const nonIPLine = normLine.dropOne;
            // writeln(`> As a non-interpuncted ``, nonIPLine, `"`);
            gr.query(nonIPLine, userLang, userSense, userCount, lineSeparator, triedLines, depth + 1); // recurse
        }

        // non-interpuncted
        if (normLine.endsWith('.', '?', '!'))
        {
            import std.range: dropBackOne;
            const nonIPLine = normLine.dropBackOne;
            // writeln(`> As a non-interpuncted "`, nonIPLine, `"`);
            gr.query(nonIPLine, userLang, userSense, userCount, lineSeparator, triedLines, depth + 1); // recurse
        }

        // interpuncted
        if (!normLine.endsWith('.') &&
            !normLine.endsWith('?') &&
            !normLine.endsWith('!'))
        {
            // questioned
            const questionedLine = normLine ~ '?';
            // writeln(`> As a question "`, questionedLine, `"`);
            gr.query(questionedLine, userLang, userSense, userCount, lineSeparator, triedLines, depth + 1); // recurse

            // exclaimed
            const exclaimedLine = normLine ~ '!';
            // writeln(`> As an exclamation "`, exclaimedLine, `"`);
            gr.query(exclaimedLine, userLang, userSense, userCount, lineSeparator, triedLines, depth + 1); // recurse

            // dotted
            const dottedLine = normLine ~ '.';
            // writeln(`> As a dotted "`, dottedLine, `"`);
            gr.query(dottedLine, userLang, userSense, userCount, lineSeparator, triedLines, depth + 1); // recurse
        }

        // lowered
        const loweredLine = normLine.toLower;
        if (loweredLine != normLine)
        {
            // writeln(`> Lowercased to "`, loweredLine, `"`);
            gr.query(loweredLine, userLang, userSense, userCount, lineSeparator, triedLines, depth + 1); // recurse
        }

        // uppered
        const upperedLine = normLine.toUpper;
        if (upperedLine != normLine)
        {
            // writeln(`> Uppercased to "`, upperedLine, `"`);
            gr.query(upperedLine, userLang, userSense, userCount, lineSeparator, triedLines, depth + 1); // recurse
        }

        // capitalized
        const capitalizedLine = normLine.capitalize;
        if (capitalizedLine != normLine)
        {
            // writeln(`> Capitalized to (name) "`, capitalizedLine, `"`);
            gr.query(capitalizedLine, userLang, userSense, userCount, lineSeparator, triedLines, depth + 1); // recurse
        }
    }

    return false;
}
