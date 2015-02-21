module knet.readers.cn5;

import std.stdio: writeln;
import std.traits: isSomeChar, isSomeString;
import std.array: array, replace;
import std.algorithm: joiner;
import std.conv: to;
import core.exception: UnicodeException;
import std.utf: UTFException;
import std.path: buildNormalizedPath, expandTilde, extension;
import std.file;

import predicates: of;
import grammars: Tense, Manner;

import knet.base;

Origin decodeCN5OriginDirect(S)(S path, out Lang lang,
                                Origin currentOrigin) if (isSomeString!S)
{
    switch (path) with (Origin)
    {
        case `/s/dbpedia/3.7`:
        case `/s/dbpedia/3.9/umbel`:
        case `/d/dbpedia/en`:
            lang = Lang.en;
            return dbpedia;

        case `/d/wordnet/3.0`:
        case `/s/wordnet/3.0`:
            return wordnet;

        case `/d/umbel`:
            return umbel;

        case `/d/jmdict`:
            return jmdict;

        case `/s/site/verbosity`:
            return verbosity;

        default:
            // dln(`Handle `, path);
            return unknown;
    }
}

/** Decode ConceptNet5 Origin $(D path). */
Origin decodeCN5OriginPath(S)(S path, out Lang lang,
                              Origin currentOrigin) if (isSomeString!S)
{
    auto origin = decodeCN5OriginDirect(path, lang, currentOrigin);
    if (origin != Origin.unknown)
    {
        return origin;
    }

    bool fromSource = false;
    bool fromDictionary = false;
    bool fromSite = false;

    size_t ix = 0;
    foreach (part; path.splitter('/'))
    {
        switch (ix)
        {
            case 0:
                break;
            case 1:
                switch (part)
                {
                    case `s`: fromSource = true; break;
                    case `d`: fromDictionary = true; break;
                    default: break;
                }
                break;
            case 2:
                switch (part) with (Origin)
                {
                    case `dbpedia`: origin = dbpedia; break;
                    case `wordnet`: origin = wordnet; break;
                    case `wiktionary`: origin = wiktionary; break;
                    case `globalmind`: origin = globalmind; break;
                    case `conceptnet`: origin = cn5; break;
                    case `verbosity`: origin = verbosity; break;
                    case `site`: fromSite = true; break;
                    default: break;
                }
                break;
            case 3: // TODO what is this?
                break;
            default:
                break;
        }
        ++ix;
    }

    if (origin == Origin.unknown)
    {
        if (path.canFind(`wiktionary.org`))
        {
            origin = Origin.wiktionary;
        }
        else
        {
            origin = Origin.cn5;
        }
    }

    return origin;
}

/** Decode ConceptNet5 Relation $(D path). */
Rel decodeCN5RelationPath(S)(S path,
                             out bool negation,
                             out bool reversion,
                             out Tense tense) if (isSomeString!S)
{
    import knet.decodings: decodeRelationPredicate;
    return path[3..$].decodeRelationPredicate(null, null, Origin.cn5,
                                              negation, reversion, tense);
}

/** Read ConceptNet5 URI.
    See also: https://github.com/commonsense/conceptnet5/wiki/URI-hierarchy-5.0
*/
Nd readCN5ConceptURI(T)(Graph graph,
                        const T part)
{
    auto items = part.splitter('/');

    import knet.languages: decodeLang;
    const lang = items.front.decodeLang; items.popFront;
    const expr = items.front.replace(`_`, ` `); items.popFront;

    auto sense = Sense.unknown;
    if (!items.empty)
    {
        const item = items.front;
        import knet.senses: decodeWordSense;
        sense = item.decodeWordSense;
        if (sense == Sense.unknown && item != `_`)
        {
            writeln(`warning: Unknown Sense code `, items.front);
        }
    }

    import knet.lemmas: correctLemmaExpr;
    return graph.add(expr.correctLemmaExpr,
                       lang, sense, Origin.cn5, anyContext,
                       Manner.formal, false, 0, false);
}

/** Read ConceptNet5 CSV Line $(D line) at 0-offset line number $(D lnr). */
Ln readCN5Line(R, N)(Graph graph,
                     R line, N lnr)
{
    auto rel = Rel.any;
    auto negation = false;
    auto reversion = false;
    auto tense = Tense.unknown;

    Nd src, dst;
    NWeight weight;
    auto lang = Lang.unknown;
    auto origin = Origin.unknown;

    size_t ix;
    foreach (part; line.splitter('\t'))
    {
        switch (ix)
        {
            case 1:
                rel = decodeCN5RelationPath(part, negation, reversion, tense);
                break;
            case 2:         // source concept
                try
                {
                    if (part.skipOver(`/c/`)) { src = graph.readCN5ConceptURI(part); }
                    else { /* dln(`TODO `, part); */ }
                    /* dln(part); */
                }
                catch (UTFException e)
                {
                    /* dln(`UTFException when reading line:`, line, */
                    /*     ` part:`, part, */
                    /*     ` lnr:`, lnr); */
                }
                break;
            case 3:         // destination concept
                if (part.skipOver(`/c/`)) { dst = graph.readCN5ConceptURI(part); }
                else { /* dln(`TODO `, part); */ }
                break;
            case 4:
                if (part != `/ctx/all`) { /* dln(`TODO `, part); */ }
                break;
            case 5:
                weight = part.to!NWeight;
                break;
            case 6:
                origin = decodeCN5OriginPath(part, lang, origin);
                break;
            case 7:
                break;
            case 8:
                if (origin.of(Origin.any)) // if still nothing special
                {
                    origin = decodeCN5OriginPath(part, lang, origin);
                }
                if (origin.of(Origin.any)) // if still nothing special
                {
                    writeln(`warning: Couldn't decode Origin `, part);
                }
                break;
            default:
                break;
        }

        ix++;
    }

    if (origin.of(Origin.any)) // if still nothing special
    {
        origin = Origin.cn5;
    }

    if (src.defined &&
        dst.defined &&
        src != dst)
    {
        return graph.connect(src, Role(rel, reversion, negation), dst, origin, weight);
    }
    else
    {
        return Ln.asUndefined;
    }
}

/** Read ConceptNet5 Assertions File $(D path) in CSV format.
    Setting $(D useMmFile) to true increases IO-bandwidth by about a magnitude.
*/
void readCN5File(Graph graph,
                 string path, size_t maxCount = size_t.max, bool useMmFile = false)
{
    writeln(`Reading ConceptNet from `, path, ` ...`);
    size_t lnr = 0;
    try
    {
        if (useMmFile)
        {
            import mmfile_ex: mmFileLinesRO;
            foreach (line; mmFileLinesRO(path))
            {
                graph.readCN5Line(line, lnr);
                if (++lnr >= maxCount) break;
            }
        }
        else
        {
            import std.stdio: File;
            foreach (line; File(path).byLine)
            {
                graph.readCN5Line(line, lnr);
                if (++lnr >= maxCount) break;
            }
        }
        writeln(`Read ConceptNet from `, path, ` having `, lnr, ` lines`);
    }
    catch (std.file.FileException e)
    {
        writeln(`Failed Reading ConceptNet File from `, path);
    }
}

/// Read ConceptNet.
void readCN5(Graph graph,
             string path, size_t maxCount)
{
    try
    {
        foreach (file; path.expandTilde
                           .buildNormalizedPath
                           .dirEntries(SpanMode.shallow)
                           .filter!(name => name.extension == `.csv`))
        {
            graph.readCN5File(file, maxCount, false);
        }
    }
    catch (std.file.FileException e)
    {
        writeln(`Failed Reading ConceptNet File Set from `, path);
    }
}
