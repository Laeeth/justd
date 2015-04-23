module conv_ex;

import std.traits: isSomeString;

/**
   More tolerant variant of std.conv.to.
   TODO Handle more languages.
   TODO Handle plural endings in other languages.
*/
auto tolerantTo(U, S)(S t,
                      bool tryStrippingPluralS = true) if (isSomeString!S)
{
    import std.conv: to;
    try
    {
        return t.to!U;
    }
    catch (Exception e)
    {
        try
        {
            import std.uni: toLower;
            return t.toLower.to!U;
        }
        catch (Exception e)
        {
            import std.algorithm.searching: endsWith;
            if (tryStrippingPluralS &&
                t.endsWith(`s`))
            {
                try
                {
                    return t[0 .. $ - 2].tolerantTo!U;
                }
                catch (Exception e)
                {
                    return U.init;
                }
            }
            else
            {
                return U.init;
            }
        }
    }
}
