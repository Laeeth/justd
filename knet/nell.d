module knet.nell;

import std.stdio: writeln;
import std.traits: isSomeChar, isSomeString;
import std.array: array, replace;
import std.algorithm: splitter, map, joiner, endsWith;
import std.conv: to;
import std.stdio: File;
import core.exception: UnicodeException;
import std.utf: UTFException;
import std.path: buildNormalizedPath, expandTilde, extension;
import std.file: dirEntries;
import std.range: empty;

import mmfile_ex;
import predicates: of;
import grammars: Tense, Manner;
import dbg: dln;

import knet.origins: Origin;
import knet.senses: Sense;
import knet.base;
import knet.languages: Lang;
import knet.roles: Role, Rel;

/** Read NELL File $(D path) in CSV format.
 */
void readNELLFile(Graph graph,
                  string path, size_t maxCount = size_t.max)
{
    import std.exception;
    writeln(`Reading NELL from `, path, ` ...`);
    size_t lnr = 0;
    try
    {
        foreach (line; File(path.expandTilde.buildNormalizedPath).byLine)
        {
            graph.readNELLLine(line, lnr);
            if (++lnr >= maxCount) break;
        }
        writeln(`Read NELL `, path, ` having `, lnr, ` lines`);
    }
    catch (std.exception.ErrnoException e)
    {
        writeln(`Failed reading NELL `, path);
    }
}

/** Read NELL CSV Line $(D line) at 0-offset line number $(D lnr). */
void readNELLLine(R, N)(Graph graph,
                        R line, N lnr)
{
    auto rel = Rel.any;
    auto negation = false;
    auto reversion = false;
    auto tense = Tense.unknown;

    Nd entityIx;
    Nd valueIx;

    string entityContextName;
    char[] relationName;
    string valueContextName;

    auto ignored = false;
    NWeight mainWeight;
    auto show = false;

    auto parts = line.splitter('\t');
    size_t ix;
    foreach (part; parts)
    {
        switch (ix)
        {
            case 0:
                auto entity = graph.readNELLEntity(part);
                entityIx = entity[0];
                entityContextName = entity[1];
                if (!entityIx.defined) { return; }

                break;
            case 1:
                auto predicate = part.splitter(':');

                if (predicate.front == `concept`)
                    predicate.popFront; // ignore no-meaningful information
                else
                    if (show) dln(`TODO Handle non-concept predicate `, predicate);

                relationName = predicate.front;

                break;
            case 2:
                if (relationName == `haswikipediaurl`)
                {
                    // TODO check if url is special compared to entity and
                    // store it only if it's not
                    ignored = true;
                }
                else
                {
                    if (relationName == `latitudelongitude`)
                    {
                        const loc = part.findSplit(`,`);
                        if (!loc[1].empty)
                        {
                            graph.setLocation(entityIx,
                                              Location(loc[0].to!double,
                                                       loc[2].to!double));
                        }
                    }
                    else
                    {
                        auto value = graph.readNELLEntity(part);
                        valueIx = value[0];
                        if (!valueIx.defined) { return; }
                        valueContextName = value[1];

                        relationName.skipOver(entityContextName); // strip dumb prefix
                        relationName.skipOverBack(valueContextName); // strip dumb suffix

                        import knet.decodings: decodeRelationPredicate;
                        rel = relationName.decodeRelationPredicate(entityContextName,
                                                                   valueContextName,
                                                                   Origin.nell,
                                                                   negation, reversion, tense);
                    }
                }
                break;
            case 4:
                mainWeight = part.to!NWeight;
                break;
            default:
                if (ix < 5 && !ignored)
                {
                    if (show) dln(` MORE:`, part);
                }
                break;
        }
        ++ix;
    }

    if (entityIx.defined &&
        valueIx.defined)
    {
        auto mainLinkRef = graph.connect(entityIx, Role(rel, reversion, negation), valueIx,
                                         Origin.nell, mainWeight);
    }

    if (show) writeln;
}

/** Read NELL Entity from $(D part). */
Tuple!(Nd, string, Ln) readNELLEntity(S)(Graph graph,
                                         const S part)
{
    const show = false;

    auto entity = part.splitter(':');

    if (entity.front == `concept`)
    {
        entity.popFront; // ignore no-meaningful information
    }

    if (show) dln(`ENTITY:`, entity);

    auto personContextSplit = entity.front.findSplitAfter(`person`);
    if (!personContextSplit[0].empty)
    {
        /* dln(personContextSplit, ` livesIn `, personContextSplit[1]); */
        /* lookupOrStoreContext(personContextSplit[0]); */
    }
    else
    {
        /* lookupOrStoreContext(entity.front); */
    }

    /* context */
    immutable contextName = entity.front.idup; entity.popFront;
    const context = graph.contextOfName(contextName);

    if (entity.empty)
    {
        return typeof(return).init;
    }

    const lang = Lang.en;   // use English for now
    const sense = Sense.noun;

    /* name */
    // clean cases such as concept:language:english_language
    immutable entityName = (entity.front.endsWith(`_` ~ contextName) ?
                            entity.front[0 .. $ - (contextName.length + 1)] :
                            entity.front).idup;
    entity.popFront;

    import knet.lemmas: correctLemmaExpr;
    auto entityIx = graph.store(entityName.replace(`_`, ` `).correctLemmaExpr,
                                lang, sense, Origin.nell, context);

    return tuple(entityIx,
                 contextName,
                 graph.connect(entityIx,
                               Role(Rel.instanceOf),
                               graph.store(contextName.replace(`_`, ` `).correctLemmaExpr, lang, sense, Origin.nell, context),
                               Origin.nell, 1.0,
                               true)); // need to check duplicates here
}
