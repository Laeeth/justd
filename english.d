#!/usr/bin/env rdmd-dev

/** English Language.

    Copyright: Per Nordlöw 2014-.
    License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
    Authors: $(WEB Per Nordlöw)
*/
module english;

/** Get english order name of $(D n). */
string nthString(T)(T n) @safe pure {
    import std.conv : to;
    string s;
    switch (n) {
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
    case 20: s = "twenteenth"; break;
    }
    return s;
}
