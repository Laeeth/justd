module knet.readers.swesaurus;

import knet.base;

void readSwesaurus(Graph graph)
{
    import std.path: buildNormalizedPath, expandTilde;

    import knet.readers.synlex: readSynlexFile;
    import knet.readers.folklex: readFolketsFile;

    readSynlexFile(graph, `~/Knowledge/swesaurus/synpairs.xml`.expandTilde.buildNormalizedPath);
    readFolketsFile(graph, `~/Knowledge/swesaurus/folkets_en_sv_public.xdxf`.expandTilde.buildNormalizedPath, Lang.en, Lang.sv);
    readFolketsFile(graph, `~/Knowledge/swesaurus/folkets_sv_en_public.xdxf`.expandTilde.buildNormalizedPath, Lang.sv, Lang.en);
}
