module knet.readers.folklex;

import knet.base: Graph;
import knet.languages: Lang;
import knet.roles: Role, Rel;
import knet.lemmas: correctLemmaExpr;
import knet.senses: Sense;
import knet.origins: Origin;

/** Read Folkets Lexikon Synonyms File $(D path) in XML format.
 */
void readFolketsFile(Graph graph,
                     string path,
                     Lang srcLang,
                     Lang dstLang,
                     size_t maxCount = size_t.max)
{
    import std.stdio: writeln;
    import std.xml: DocumentParser, ElementParser, Element;

    size_t lnr = 0;
    writeln(`Reading Folkets Lexikon from `, path, ` ...`);

    import std.file;
    try
    {
        const str = cast(string)read(path);

        auto doc = new DocumentParser(str);
        doc.onStartTag[`ar`] = (ElementParser elp)
        {
            string src, gr_;
            string[] dsts;
            elp.onEndTag[`k`] = (in Element e) { src = e.text.correctLemmaExpr; };
            elp.onEndTag[`gr`] = (in Element e) { gr_ = e.text.correctLemmaExpr; };
            elp.onEndTag[`dtrn`] = (in Element e)
            {
                dsts ~= e.text;
            };

            elp.parse;

            Sense[] senses;
            switch (gr_)
            {
                case ``:        // ok for unknown
                case `latin`:
                    senses ~= Sense.unknown;
                    break;
                case `prefix`: senses ~= Sense.prefix; break;
                case `suffix`: senses ~= Sense.suffix; break;
                case `pm`: senses ~= Sense.name; break;
                case `nn`: senses ~= Sense.noun; break;
                case `vb`: senses ~= Sense.verb; break;
                case `hjälpverb`: senses ~= Sense.auxiliaryVerb; break;
                case `jj`: senses ~= Sense.adjective; break;
                case `pc`: senses ~= Sense.adjective; break; // TODO can be either adjective or verb
                case `ab`: senses ~= Sense.adverb; break;
                case `pp`: senses ~= Sense.preposition; break;
                case `pn`: senses ~= Sense.pronoun; break;
                case `ps`: senses ~= Sense.pronounPossessive; break;
                case `kn`: senses ~= Sense.conjunction; break;
                case `in`: senses ~= Sense.interjection; break;
                case `abbrev`: senses ~= Sense.abbrevation; break;
                case `nn, abbrev`:
                case `abbrev, nn`:
                    senses ~= Sense.nounAbbrevation; break;
                case `article`: senses ~= Sense.article; break;
                case `rg`:
                case `rg, nn`: senses ~= Sense.integer; break;
                case `ro`:
                case `ro, nn`: senses ~= Sense.ordinalNumber; break;
                case `in, nn`: senses ~= [Sense.interjection, Sense.noun]; break;
                case `jj, nn`: senses ~= [Sense.adjective, Sense.noun]; break;
                case `jj, pp`: senses ~= [Sense.adjective, Sense.preposition]; break;
                case `jj, pc`: senses ~= [Sense.adjective]; break; // TODO can be either adjective or verb
                case `nn, jj`: senses ~= [Sense.noun, Sense.adjective]; break;
                case `jj, nn, ab`: senses ~= [Sense.adjective, Sense.noun, Sense.adverb]; break;
                case `ab, jj`: senses ~= [Sense.adverb, Sense.adjective]; break;
                case `jj, ab`: senses ~= [Sense.adjective, Sense.adverb]; break;
                case `ab, pp`: senses ~= [Sense.adverb, Sense.preposition]; break;
                case `ab, pn`: senses ~= [Sense.adverb, Sense.pronoun]; break;
                case `pp, ab`: senses ~= [Sense.preposition, Sense.adverb]; break;
                case `pp, kn`: senses ~= [Sense.preposition, Sense.conjunction]; break;
                case `ab, kn`: senses ~= [Sense.adverb, Sense.conjunction]; break;
                case `vb, nn`: senses ~= [Sense.verb, Sense.noun]; break;
                case `nn, vb`: senses ~= [Sense.noun, Sense.verb]; break;
                case `vb, abbrev`: senses ~= [Sense.verbAbbrevation]; break;
                case `jj, abbrev`: senses ~= [Sense.adjectiveAbbrevation]; break;
                case `ie`: senses ~= Sense.conjunction; break; // TODO "ie" is a strange abbrevation for "conjunction"
                default: writeln(`warning: TODO "`, src, `" have sense "`, gr_, `"`); break;
            }

            foreach (sense; senses)
            {
                import std.algorithm: filter, map;
                import std.algorithm.iteration: splitter;
                import std.range: empty;

                foreach (dst; dsts.filter!(a => !a.empty))
                {
                    import std.algorithm: strip;
                    auto src_ = src.splitter(',').map!(a => a.strip(' ')).filter!(a => !a.empty);
                    auto dst_ = dst.splitter(',').map!(a => a.strip(' ')).filter!(a => !a.empty);

                    enum origin = Origin.folketsLexikon;
                    graph.connectMtoN(graph.store(src_, srcLang, sense, origin),
                                      Role(Rel.translationOf),
                                      graph.store(dst_, dstLang, sense, origin),
                                      origin, 1.0, true);
                }
            }
        };
        doc.parse;

        writeln(`Read Folkets Lexikon `, path, ` having `, lnr, ` lines`);
    }
    catch (std.file.FileException e)
    {
        writeln(`Failed Reading Folkets Lexikon from `, path);
    }
}
