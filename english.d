#!/usr/bin/env rdmd-dev

/** English Language.

    Copyright: Per Nordlöw 2014-.
    License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
    Authors: $(WEB Per Nordlöw)
*/
module english;

/** Get english order name of $(D n). */
string nthString(T)(T n) @safe pure
{
    import std.conv : to;
    string s;
    switch (n)
    {
        default: s = to!string(n) ~ ":th"; break;
        case 0: s = "zeroth"; break;
        case 1: s = "first"; break;
        case 2: s = "second"; break;
        case 3: s = "third"; break;
        case 4: s = "fourth"; break;
        case 5: s = "fifth"; break;
        case 6: s = "sixth"; break;
        case 7: s = "seventh"; break;
        case 8: s = "eighth"; break;
        case 9: s = "ninth"; break;
        case 10: s = "tenth"; break;
        case 11: s = "eleventh"; break;
        case 12: s = "twelveth"; break;
        case 13: s = "thirteenth"; break;
        case 14: s = "fourteenth"; break;
        case 15: s = "fifteenth"; break;
        case 16: s = "sixteenth"; break;
        case 17: s = "seventeenth"; break;
        case 18: s = "eighteenth"; break;
        case 19: s = "nineteenth"; break;
        case 20: s = "twentieth"; break;
    }
    return s;
}

/** Return string $(D word) in plural optionally in $(D count). */
string inPlural(string word, int count = 2,
                string pluralWord = null)
{
    if (count == 1 || word.length == 0)
        return word; // it isn't actually inPlural

    if (pluralWord !is null)
        return pluralWord;

    switch (word[$ - 1])
    {
        case 's':
        case 'a', 'e', 'i', 'o', 'u':
            return word ~ "es";
        case 'f':
            return word[0 .. $-1] ~ "ves";
        case 'y':
            return word[0 .. $-1] ~ "ies";
        default:
            return word ~ "s";
    }
}

string numberToEnglish(long number)
{
    string word;
    if (number == 0)
        return "zero";

    if (number < 0)
    {
        word = "negative";
        number = -number;
    }

    while(number)
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
                    word ~= "-";
            }
        }
        else if (number < 1000)
        {
            auto hundreds = number / 100;
            word ~= onesPlaceWords[cast(int) hundreds] ~ " hundred";
            number = number % 100;
            if (number)
                word ~= " and ";
        }
        else if (number < 1000000)
        {
            auto thousands = number / 1000;
            word ~= numberToEnglish(thousands) ~ " thousand";
            number = number % 1000;
            if (number)
                word ~= ", ";
        }
        else if (number < 1_000_000_000)
        {
            auto millions = number / 1000000;
            word ~= numberToEnglish(millions) ~ " million";
            number = number % 1000000;
            if (number)
                word ~= ", ";
        }
        else if (number < 1_000_000_000_000)
        {
            auto n = number / 1000000000;
            word ~= numberToEnglish(n) ~ " billion";
            number = number % 1000000000;
            if (number)
                word ~= ", ";
        }
        else if (number < 1_000_000_000_000_000)
        {
            auto n = number / 1000000000000;
            word ~= numberToEnglish(n) ~ " trillion";
            number = number % 1000000000000;
            if (number)
                word ~= ", ";
        }
        else
        {
            import std.conv;
            return to!string(number);
        }
    }

    return word;
}

unittest {
    assert(numberToEnglish(1) == "one");
    assert(numberToEnglish(5) == "five");
    assert(numberToEnglish(13) == "thirteen");
    assert(numberToEnglish(54) == "fifty-four");
    assert(numberToEnglish(178) == "one hundred and seventy-eight");
    assert(numberToEnglish(592) == "five hundred and ninety-two");
    assert(numberToEnglish(1234) == "one thousand, two hundred and thirty-four");
    assert(numberToEnglish(10234) == "ten thousand, two hundred and thirty-four");
    assert(numberToEnglish(105234) == "one hundred and five thousand, two hundred and thirty-four");
}

enum onesPlaceWords = [
    "zero",
    "one",
    "two",
    "three",
    "four",
    "five",
    "six",
    "seven",
    "eight",
    "nine",
    ];

enum singleWords = onesPlaceWords ~ [
    "ten",
    "eleven",
    "twelve",
    "thirteen",
    "fourteen",
    "fifteen",
    "sixteen",
    "seventeen",
    "eighteen",
    "nineteen",
    ];

enum tensPlaceWords = [
    null,
    "ten",
    "twenty",
    "thirty",
    "forty",
    "fifty",
    "sixty",
    "seventy",
    "eighty",
    "ninety",
    ];

/*
  void main()
  {
  import std.stdio;
  foreach(i; 3433000 ..3433325)
  writeln(numberToEnglish(i));
  }
*/
