#!/usr/bin/env rdmd-dev

import std.stdio;
import pegged.peg;
import pegged.grammar;

pragma(lib, "pegged");

mixin(grammar(`
Arithmetic:
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
`));

void main(string[] args)
{
    enum parseTree1 = Arithmetic("1 + 2 - (3*x-5)*6");
    // pragma(msg, parseTree1.matches);
    assert(parseTree1.matches == ["1", "+", "2", "-", "(", "3", "*", "x", "-", "5", ")", "*", "6"]);
    writeln(parseTree1);
}
