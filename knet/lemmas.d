module knet.lemmas;

import std.traits: isSomeString;

/// Correct Formatting of Lemma Expression $(D s).
auto ref correctLemmaExpr(S)(S s) if (isSomeString!S)
{
    switch (s)
    {
        case `honey be`: return `honey bee`;
        case `bath room`: return `bathroom`;
        case `bed room`: return `bedroom`;
        case `diningroom`: return `dining room`;
        case `livingroom`: return `living room`;
        default: return s;
    }
}
