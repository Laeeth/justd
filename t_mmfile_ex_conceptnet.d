import mmfile_ex;

void main()
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
        size_t ix;
        foreach (line; mmFileLinesRO(filePath))
        {
            ++ix;
        }
        writeln("Read ", ix, " lines from ", filePath);
    }

}
