module knet.readers.synlex;

import knet.base;

/** Read SynLex Synonyms File $(D path) in XML format.
 */
void readSynlexFile(Graph graph,
                    string path, size_t maxCount = size_t.max)
{
    import std.stdio: writeln;
    import std.xml: DocumentParser, ElementParser, Element;

    size_t lnr = 0;

    writeln(`Reading SynLex from `, path, ` ...`);

    enum lang = Lang.sv;
    enum origin = Origin.synlex;

    import std.file;

    try
    {
        const str = cast(string)read(path);

        auto doc = new DocumentParser(str);
        doc.onStartTag[`syn`] = (ElementParser elp)
        {
            import std.conv: to;
            const level = elp.tag.attr[`level`].to!real; // level on a scale from 1 to 5
            const weight = level/5.0; // normalized weight
            string w1, w2;

            import std.uni: toLower;
            import knet.lemmas: correctLemmaExpr;

            elp.onEndTag[`w1`] = (in Element e) { w1 = e.text.toLower.correctLemmaExpr; };
            elp.onEndTag[`w2`] = (in Element e) { w2 = e.text.toLower.correctLemmaExpr; };

            elp.parse;

            if (w1 != w2) // there might be a bug in the xml...
            {
                graph.connect(graph.add(w1, lang, Sense.unknown, origin),
                              Role(Rel.synonymFor),
                              graph.add(w2, lang, Sense.unknown, origin),
                              origin, weight, true);
                ++lnr;
            }
        };
        doc.parse;

        writeln(`Read SynLex `, path, ` having `, lnr, ` lines`);
    }
    catch (std.file.FileException e)
    {
        writeln(`Failed Reading SynLex from `, path);
    }
}
