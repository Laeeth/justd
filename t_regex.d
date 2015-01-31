class DustmiteCommand
{
    void delegate(int, string) check(string regex_match)
    {
        return (code, output)
        {
            import std.regex;
            if (match(output, regex_match))
                logInfo;
        };
    }
}
