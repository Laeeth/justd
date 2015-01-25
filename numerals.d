/** English Numerals.
 */
module numerals;

import std.conv: to;
import std.traits: isSomeString;

/** Get English Ordinal Number of $(D n).
    See also: https://en.wikipedia.org/wiki/Ordinal_number_(linguistics)
 */
string toOrdinal(T)(T n) @safe pure
{
    string s;
    switch (n)
    {
        default: s = to!string(n) ~ `:th`; break;
        case 0: s = `zeroth`; break;
        case 1: s = `first`; break;
        case 2: s = `second`; break;
        case 3: s = `third`; break;
        case 4: s = `fourth`; break;
        case 5: s = `fifth`; break;
        case 6: s = `sixth`; break;
        case 7: s = `seventh`; break;
        case 8: s = `eighth`; break;
        case 9: s = `ninth`; break;
        case 10: s = `tenth`; break;
        case 11: s = `eleventh`; break;
        case 12: s = `twelveth`; break;
        case 13: s = `thirteenth`; break;
        case 14: s = `fourteenth`; break;
        case 15: s = `fifteenth`; break;
        case 16: s = `sixteenth`; break;
        case 17: s = `seventeenth`; break;
        case 18: s = `eighteenth`; break;
        case 19: s = `nineteenth`; break;
        case 20: s = `twentieth`; break;
    }
    return s;
}

enum onesNumerals = [ `zero`, `one`, `two`, `three`, `four`,
                      `five`, `six`, `seven`, `eight`, `nine` ];
enum singleWords = onesNumerals ~ [ `ten`, `eleven`, `twelve`, `thirteen`, `fourteen`,
                                    `fifteen`, `sixteen`, `seventeen`, `eighteen`, `nineteen` ];
enum tensNumerals = [ null, `ten`, `twenty`, `thirty`, `forty`,
                      `fifty`, `sixty`, `seventy`, `eighty`, `ninety`, ];

enum englishNumeralsMap = [ `zero`:0, `one`:1, `two`:2, `three`:3, `four`:4,
                            `five`:5, `six`:6, `seven`:7, `eight`:8, `nine`:9,
                            `ten`:10, `eleven`:11, `twelve`:12, `thirteen`:13, `fourteen`:14,
                            `fifteen`:15, `sixteen`:16, `seventeen`:17, `eighteen`:18, `nineteen`:19,
                            `twenty`:20,
                            `thirty`:30,
                            `forty`:40,
                            `fourty`:40, // common missspelling
                            `fifty`:50,
                            `sixty`:60,
                            `seventy`:70,
                            `eighty`:80,
                            `ninety`:90,
                            `hundred`:100,
                            `thousand`:1000,
                            `million`:1000000,
                            `billion`:1000000000 ];

static immutable ubyte[string] _onesPlaceWordsAA;

/* NOTE Be careful with this logic
   This fails: foreach (ubyte i, e; onesNumerals) { _onesPlaceWordsAA[e] = i; }
   See also: http://forum.dlang.org/thread/vtenbjmktplcxxmbyurt@forum.dlang.org#post-iejbrphbqsszlxcxjpef:40forum.dlang.org
   */
static this()
{
    import std.exception: assumeUnique;
    ubyte[string] tmp;
    foreach (ubyte i, e; onesNumerals)
    {
        tmp[e] = i;
    }
    _onesPlaceWordsAA = assumeUnique(tmp); /* Don't alter tmp from here on. */
}

import std.traits: isIntegral;

/** Convert the number $(D number) to its English textual representation
    (numeral) also called cardinal number.
    Opposite: fromNumeral
    See also: https://en.wikipedia.org/wiki/Numeral_(linguistics)
    See also: https://en.wikipedia.org/wiki/Cardinal_number_(linguistics)
*/
string toNumeral(T)(T number, string minusName = `minus`) if (isIntegral!T)
{
    string word;

    if (number == 0)
        return `zero`;

    if (number < 0)
    {
        word = minusName ~ ' ';
        number = -number;
    }

    while (number)
    {
        if (number < 100)
        {
            if (number < singleWords.length)
            {
                word ~= singleWords[cast(int) number];
                break;
            }
            else
            {
                auto tens = number / 10;
                word ~= tensNumerals[cast(int) tens];
                number = number % 10;
                if (number)
                    word ~= `-`;
            }
        }
        else if (number < 1_000)
        {
            auto hundreds = number / 100;
            word ~= onesNumerals[cast(int) hundreds] ~ ` hundred`;
            number = number % 100;
            if (number)
                word ~= ` and `;
        }
        else if (number < 1_000_000)
        {
            auto thousands = number / 1_000;
            word ~= toNumeral(thousands) ~ ` thousand`;
            number = number % 1_000;
            if (number)
                word ~= `, `;
        }
        else if (number < 1_000_000_000)
        {
            auto millions = number / 1_000_000;
            word ~= toNumeral(millions) ~ ` million`;
            number = number % 1_000_000;
            if (number)
                word ~= `, `;
        }
        else if (number < 1_000_000_000_000)
        {
            auto n = number / 1_000_000_000;
            word ~= toNumeral(n) ~ ` billion`;
            number = number % 1_000_000_000;
            if (number)
                word ~= `, `;
        }
        else if (number < 1_000_000_000_000_000)
        {
            auto n = number / 1_000_000_000_000;
            word ~= toNumeral(n) ~ ` trillion`;
            number = number % 1_000_000_000_000;
            if (number)
                word ~= `, `;
        }
        else
        {
            return to!string(number);
        }
    }

    return word;
}
alias toTextual = toNumeral;

@safe pure nothrow unittest
{
    assert(1.toNumeral == `one`);
    assert(5.toNumeral == `five`);
    assert(13.toNumeral == `thirteen`);
    assert(54.toNumeral == `fifty-four`);
    assert(178.toNumeral == `one hundred and seventy-eight`);
    assert(592.toNumeral == `five hundred and ninety-two`);
    assert(1_234.toNumeral == `one thousand, two hundred and thirty-four`);
    assert(10_234.toNumeral == `ten thousand, two hundred and thirty-four`);
    assert(105_234.toNumeral == `one hundred and five thousand, two hundred and thirty-four`);
    assert(7_105_234.toNumeral == `seven million, one hundred and five thousand, two hundred and thirty-four`);
    assert(3_007_105_234.toNumeral == `three billion, seven million, one hundred and five thousand, two hundred and thirty-four`);
    assert(900_003_007_105_234.toNumeral == `nine hundred trillion, three billion, seven million, one hundred and five thousand, two hundred and thirty-four`);
    assert((-5).toNumeral == `minus five`);
}

import std.typecons: Nullable;

version = show;

/** Convert the number $(D number) to its English textual representation.
    Opposite: toNumeral.
    TODO Throw if number doesn't fit in long.
    TODO Add variant to toTextualBigIntegerMaybe.
    TODO Could this be merged with to!(T)(string) if (isInteger!T) ?
*/
Nullable!long fromNumeral(T = long, S)(S x)
@safe pure if (isSomeString!S)
{
    import std.algorithm: splitter, countUntil, skipOver, endsWith;

    typeof(return) total;

    version(show)
    {
        import dbg;
    }

    T sum = 0;
    bool defined = false;
    bool negative = false;

    auto terms = x.splitter(`,`); // comma separate terms
    foreach (term; terms)
    {
        auto factors = term.splitter; // split factors by whitespace

        // prefixes
        factors.skipOver(`plus`); // no semantic effect
        if (factors.skipOver(`minus`) ||
            factors.skipOver(`negative`))
        {
            negative = true;
        }
        factors.skipOver(`plus`); // no semantic effect

        // main
        T product = 1;
        bool tempSum = false;
        foreach (const factor; factors)
        {
            if (factor == `and`)
            {
                tempSum = true;
            }
            else if (const value = factor in englishNumeralsMap)
            {
                if (tempSum)
                {
                    product += *value;
                    tempSum = false;
                }
                else
                {
                    product *= *value;
                }
                defined = true;
            }
            else if (factor.endsWith(`s`)) // assume plural s for common misspelling millions instead of million
            {
                if (const value = factor[0 .. $ - 1] in englishNumeralsMap) // without possible plural s
                {
                    if (tempSum)
                    {
                        product += *value;
                        tempSum = false;
                    }
                    else
                    {
                        product *= *value;
                    }
                    defined = true;
                }
            }
            else
            {
                version(show)
                {
                    debug dln(`Couldn't decode "`, x, `"`);
                }
                return typeof(return).init; // could not process
            }
        }

        sum += product;
    }

    version(show)
    {
        debug dln(`Input "`, x, `" decoded to `, sum);
    }

    if (defined)
    {
        return typeof(return)(negative ? -sum : sum);
    }
    else
    {
        return typeof(return).init;
    }
}

@safe pure unittest
{
    import std.range: chain, iota;

    // undefined cases
    assert(``.fromNumeral.isNull);
    assert(`dum`.fromNumeral.isNull);
    assert(`plus`.fromNumeral.isNull);
    assert(`minus`.fromNumeral.isNull);

    foreach (i; chain(iota(0, 20),
                      iota(20, 100, 10),
                      iota(100, 1000, 100),
                      iota(1000, 10000, 1000),
                      iota(10000, 100000, 10000),
                      iota(100000, 1000000, 100000)))
    {
        const ti = i.toNumeral;
        assert(-i == (`minus ` ~ ti).fromNumeral);
        assert(+i == (`plus ` ~ ti).fromNumeral);
        assert(+i == ti.fromNumeral);
    }

    assert(`nine thousands`.fromNumeral == 9_000);
    assert(`two millions`.fromNumeral == 2_000_000);
    assert(`one thousand, two hundred`.fromNumeral == 1_200);
    assert(`three million, one thousand, two hundred`.fromNumeral == 3_001_200);

    assert(`one hundred and five thousand`.fromNumeral == 105_000);
    assert(`one hundred and fifty thousand`.fromNumeral == 150_000);
}
