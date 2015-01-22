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
    const path = "~/justd/knowledge/moby/pronounciation.txt";
    import std.stdio: writeln;
    foreach (line; mmFileLinesRO(path))
    {
    }
}
