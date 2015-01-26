module knet.swesaurus;

import knet.base: Graph;

void readSwesaurus(Graph graph)
{
    import std.path: buildNormalizedPath, expandTilde;

    import knet.languages: Lang;
    import knet.synlex: readSynlexFile;
    import knet.folklex: readFolketsFile;

    graph.readSynlexFile(`~/Knowledge/swesaurus/synpairs.xml`.expandTilde.buildNormalizedPath);
    graph.readFolketsFile(`~/Knowledge/swesaurus/folkets_en_sv_public.xdxf`.expandTilde.buildNormalizedPath, Lang.en, Lang.sv);
    graph.readFolketsFile(`~/Knowledge/swesaurus/folkets_sv_en_public.xdxf`.expandTilde.buildNormalizedPath, Lang.sv, Lang.en);
}
