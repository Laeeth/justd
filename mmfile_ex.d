module mmfile_ex;

/** Read-Only Lines of Contents of file $(D path).
   */
auto mmFileLinesRO(ElementType = char)(string path)
{
    version(linux)
    {
        import core.sys.posix.sys.shm: __getpagesize;
        const pageSize = __getpagesize();
    }
    else
    {
        const pageSize = 4096;
    }
    import std.mmfile: MmFile;
    import std.path: expandTilde, buildNormalizedPath;
    auto mmf = new MmFile(path.expandTilde.buildNormalizedPath,
                          MmFile.Mode.read, 0, null, pageSize);
    import algorithm_ex: byLine, Newline;
    return (cast(ElementType[])mmf[]).byLine!(Newline.native);
}

unittest
{
    const dirPath = `~/Knowledge/conceptnet5-5.3/data/assertions/`;
    import std.stdio: writeln;
    import std.file: dirEntries, SpanMode;
    import std.path: expandTilde, buildNormalizedPath, extension;
    import std.algorithm: filter;
    foreach (filePath; dirPath.expandTilde
                              .buildNormalizedPath
                              .dirEntries(SpanMode.shallow)
                              .filter!(name => name.extension == `.csv`))
    {
        writeln("Reading ", filePath);
        foreach (line; mmFileLinesRO(filePath))
        {
        }
    }

}
