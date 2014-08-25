#!/usr/bin/env rdmd-dev

/** Generic Language Constructs. */
module languages;

/** Programming Language. */
enum Lang
{
    unknown,                    // Unknown: ?
    c,                          // C
    cxx,                        // C++
    objective_c,                       // Objective-C
    d,                          // D
    java,                       // Java
}

unittest
{
    assert(toTag(Lang.init) == `?`);
    assert(toTag(Lang.c) == `C`);
    assert(toTag(Lang.cxx) == `C++`);
    assert(toTag(Lang.d) == `D`);
    assert(toTag(Lang.java) == `Java`);
}

string toTag(Lang lang)
{
    final switch (lang)
    {
        case Lang.unknown: return `?`;
        case Lang.c: return `C`;
        case Lang.cxx: return `C++`;
        case Lang.d: return `D`;
        case Lang.java: return `Java`;
        case Lang.objective_c: return `Objective-C`;
    }
}

Lang language(string name)
{
    switch (name)
    {
        case `C`:    return Lang.c;
        case `C++`:  return Lang.cxx;
        case `Objective-C`:  return Lang.objective_c;
        case `D`:    return Lang.d;
        case `Java`: return Lang.java;
        default:     return Lang.unknown;
    }
}

/** Markup Language */
enum MarkupLang
{
    unknown,                    // Unknown: ?
    HTML,
    MathML
}

enum Usage { definition, reference }

enum TokenId { unknown,
               keyword, type, constant, comment,
               variableName, functionName, builtinName, templateName, macroName, aliasName,
               enumeration, enumerator,
               constructor, destructors, operator }
