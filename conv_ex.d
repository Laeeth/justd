/** Extensions to std.conv.
*/
module conv_ex;

import std.conv: to;
import std.traits: isSomeString;

/** Get English Order Name of $(D n). */
string nthString(T)(T n) @safe pure
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

enum onesPlaceWords = [ `zero`, `one`, `two`, `three`, `four`,
                        `five`, `six`, `seven`, `eight`, `nine` ];
enum singleWords = onesPlaceWords ~ [ `ten`, `eleven`, `twelve`, `thirteen`, `fourteen`,
                                      `fifteen`, `sixteen`, `seventeen`, `eighteen`, `nineteen` ];
enum tensPlaceWords = [ null, `ten`, `twenty`, `thirty`, `forty`,
                        `fifty`, `sixty`, `seventy`, `eighty`, `ninety`, ];

enum onesPlaceWordsAA = [ `zero`:0, `one`:1, `two`:2, `three`:3, `four`:4,
                          `five`:5, `six`:6, `seven`:7, `eight`:8, `nine`:9 ];

/* NOTE Disabled because this segfaults at run-time.
   See also: http://forum.dlang.org/thread/vtenbjmktplcxxmbyurt@forum.dlang.org#post-iejbrphbqsszlxcxjpef:40forum.dlang.org
   */
version(none)
{
    static immutable ubyte[string] _onesPlaceWordsAA;
    static immutable ubyte[string] _singleWordsAA;
    static immutable ubyte[string] _tensPlaceWordsAA;
    static this() {
        foreach (ubyte i, e; onesPlaceWords) { _onesPlaceWordsAA[e] = i; }
        foreach (ubyte i, e; singleWords) { _singleWordsAA[e] = i; }
        foreach (ubyte i, e; tensPlaceWords) { _tensPlaceWordsAA[e] = i; }
    }
}

import std.traits: isIntegral;

/** Convert the number $(D number) to its English textual representation.
    Opposite: toTextualIntegerMaybe
*/
string toTextualString(T)(T number, string minusName = `minus`)
    @safe pure nothrow if (isIntegral!T)
{
    string word;

    if (number == 0)
        return `zero`;

    if (number < 0)
    {
        word = minusName;
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
                word ~= tensPlaceWords[cast(int) tens];
                number = number % 10;
                if (number)
                    word ~= `-`;
            }
        }
        else if (number < 1_000)
        {
            auto hundreds = number / 100;
            word ~= onesPlaceWords[cast(int) hundreds] ~ ` hundred`;
            number = number % 100;
            if (number)
                word ~= ` and `;
        }
        else if (number < 1_000_000)
        {
            auto thousands = number / 1_000;
            word ~= toTextualString(thousands) ~ ` thousand`;
            number = number % 1_000;
            if (number)
                word ~= `, `;
        }
        else if (number < 1_000_000_000)
        {
            auto millions = number / 1_000_000;
            word ~= toTextualString(millions) ~ ` million`;
            number = number % 1_000_000;
            if (number)
                word ~= `, `;
        }
        else if (number < 1_000_000_000_000)
        {
            auto n = number / 1_000_000_000;
            word ~= toTextualString(n) ~ ` billion`;
            number = number % 1_000_000_000;
            if (number)
                word ~= `, `;
        }
        else if (number < 1_000_000_000_000_000)
        {
            auto n = number / 1_000_000_000_000;
            word ~= toTextualString(n) ~ ` trillion`;
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
alias toTextual = toTextualString;

unittest {
    assert(1.toTextualString == `one`);
    assert(5.toTextualString == `five`);
    assert(13.toTextualString == `thirteen`);
    assert(54.toTextualString == `fifty-four`);
    assert(178.toTextualString == `one hundred and seventy-eight`);
    assert(592.toTextualString == `five hundred and ninety-two`);
    assert(1_234.toTextualString == `one thousand, two hundred and thirty-four`);
    assert(10_234.toTextualString == `ten thousand, two hundred and thirty-four`);
    assert(105_234.toTextualString == `one hundred and five thousand, two hundred and thirty-four`);
    assert(71_05_234.toTextualString == `seven million, one hundred and five thousand, two hundred and thirty-four`);
    assert(3_007_105_234.toTextualString == `three billion, seven million, one hundred and five thousand, two hundred and thirty-four`);
    assert(900_003_007_105_234.toTextualString == `nine hundred trillion, three billion, seven million, one hundred and five thousand, two hundred and thirty-four`);
}

import std.typecons: Nullable;

version = show;

/** Convert the number $(D number) to its English textual representation.
    Opposite: toTextualString.
    TODO Throw if number doesn't fit in long.
    TODO Add variant to toTextualBigIntegerMaybe.
    TODO Could this be merged with to!(T)(string) if (isInteger!T) ?
*/
Nullable!long toTextualIntegerMaybe(S)(S x)
@safe pure if (isSomeString!S)
{
    import std.algorithm: splitter, countUntil, skipOver;

    auto words = x.splitter; // split words by whitespace

    const negative = (words.skipOver(`minus`) ||
                      words.skipOver(`negative`));

    words.skipOver(`plus`); // no semantic effect

    typeof(return) value = get(onesPlaceWordsAA, words.front, typeof(return).init);
    if (!value.isNull)
    {
        value *= negative ? -1 : 1;
    }

    version(show)
    {
        import dbg;
        debug dln(`Input "`, x, `" decoded to `, value);
    }

    return value;
}

unittest
{
    foreach (i; 0..9)
    {
        const ti = i.toTextualString;
        assert(-i == (`minus ` ~ ti).toTextualIntegerMaybe);
        assert(+i == (`plus ` ~ ti).toTextualIntegerMaybe);
        assert(+i == ti.toTextualIntegerMaybe);
    }
}
