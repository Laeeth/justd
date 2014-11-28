/** Pegged Generated Arithmetic Parser. */
module lang_A;

import pegged.grammar;

/** Pegged Arithmetic Grammar. */
enum grammar_A = `
A:
    Term     < Factor (Add / Sub)*
    Add      < "+" Factor
    Sub      < "-" Factor
    Factor   < Primary (Mul / Div)*
    Mul      < "*" Primary
    Div      < "/" Primary
    Primary  < Parens / Neg / Number / Variable
    Parens   < "(" Term ")"
    Neg      < "-" Primary
    Number   < ~([0-9]+)
    Variable <- identifier
`;

enum parserPath_A = "parser_A.d";
enum grammarPath_A = "grammar_A.peg";

static if (__traits(compiles, { enum string _ = import(parserPath_A); })) // TODO faster way?
{
    pragma(msg, "Loaded cached parser " ~ parserPath_A);
    enum parserCached_A = import(parserPath_A);
}
else
{
    pragma(msg, "Skipped cached parser " ~ parserPath_A);
    enum parserCached_A = [];
}

static if (__traits(compiles, { enum string _ = import(grammarPath_A); })) // TODO faster way?
{
    pragma(msg, "Loaded cached grammar " ~ grammarPath_A);
    enum grammarCached_A = import(grammarPath_A);
}
else
{
    pragma(msg, "Skipped cached grammar " ~ grammarPath_A);
    enum grammarCached_A = [];
}

static if (grammar_A == grammarCached_A)
{
    pragma(msg, "Unchanged grammar " ~ grammarPath_A ~ ", reusing existing cached parser");
    enum parser_A = parserCached_A;
}
else
{
    pragma(msg, "Grammar " ~ grammarPath_A ~ " has changed, regenerating parser");
    enum parser_A = grammar(grammar_A);
}

mixin(parser_A);

shared static this()
{
    import std.file: write;
    import std.path: buildNormalizedPath;
    write(buildNormalizedPath("generated_source", parserPath_A), parser_A);
    write(buildNormalizedPath("generated_source/", grammarPath_A), grammar_A);
}
