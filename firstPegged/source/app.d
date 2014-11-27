#!/usr/bin/env rdmd-dev

import std.stdio;
import pegged.peg;
import pegged.grammar;
import std.typecons: tuple;

import dbg;

/*  ========================= A grammar ==================================== */

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

/* shared Tuple!(string, string)[] fileWrites; */

static if (grammar_A == grammarCached_A)
{
    pragma(msg, "Unchanged grammar " ~ grammarPath_A);
    enum parser_A = parserCached_A;
}
else
{
    pragma(msg, "Grammar " ~ grammarPath_A ~ " has changed");
    enum parser_A = grammar(grammar_A);
    /* fileWrites ~= tuple(grammarPath_A, grammar_A); */
    /* fileWrites ~= tuple(parserPath_A, parser_A); */
}

mixin(parser_A);

/*  ========================= C grammar ==================================== */

enum grammarC = `
C:

TranslationUnit <- ExternalDeclaration (:Spacing ExternalDeclaration)*

ExternalDeclaration < FunctionDefinition / Declaration

FunctionDefinition < DeclarationSpecifiers? Declarator DeclarationList? CompoundStatement

PrimaryExpression < Identifier
                  / CharLiteral
                  / StringLiteral
                  / FloatLiteral
                  / IntegerLiteral
                  / '(' Expression ')'

PostfixExpression < PrimaryExpression ( '[' Expression ']'
                                      / '(' ')'
                                      / '(' ArgumentExpressionList ')'
                                      / '.' Identifier
                                      / "->" Identifier
                                      / "++"
                                      / "--"
                                      )*

ArgumentExpressionList < AssignmentExpression (',' AssignmentExpression)*

UnaryExpression < PostfixExpression
                / IncrementExpression
                / DecrementExpression
                / UnaryOperator CastExpression
                / "sizeof" UnaryExpression
                / "sizeof" '(' TypeName ')'

IncrementExpression < PlusPlus UnaryExpression
PlusPlus <- "++"
DecrementExpression < "--" UnaryExpression

UnaryOperator <- [-&*+~!]

CastExpression < UnaryExpression
               / '(' TypeName ')' CastExpression

MultiplicativeExpression    < CastExpression ([*%/] MultiplicativeExpression)*

AdditiveExpression          < MultiplicativeExpression ([-+] AdditiveExpression)*

ShiftExpression             < AdditiveExpression (("<<" / ">>") ShiftExpression)*

RelationalExpression        < ShiftExpression (("<=" / ">=" / "<" / ">") RelationalExpression)*

EqualityExpression          < RelationalExpression (("==" / "!=") EqualityExpression)*

ANDExpression               < EqualityExpression ('&' ANDExpression)*

ExclusiveORExpression       < ANDExpression ('^' ExclusiveORExpression)*

InclusiveORExpression       < ExclusiveORExpression ('|' InclusiveORExpression)*

LogicalANDExpression        < InclusiveORExpression ("&&" LogicalANDExpression)*

LogicalORExpression         < LogicalANDExpression ("||" LogicalORExpression)*

ConditionalExpression       < LogicalORExpression ('?' Expression ':' ConditionalExpression)?

AssignmentExpression < UnaryExpression AssignmentOperator AssignmentExpression
                     / ConditionalExpression

AssignmentOperator <- "=" / "*=" / "/=" / "%=" / "+=" / "-=" / "<<=" / ">>=" / "&=" / "^=" / "|="

Expression < AssignmentExpression (',' AssignmentExpression)*

ConstantExpression <- ConditionalExpression

#
# C declaration rules
#

Declaration < DeclarationSpecifiers InitDeclaratorList? ';'

DeclarationSpecifiers < ( StorageClassSpecifier
                        / TypeSpecifier
                        / TypeQualifier
                        ) DeclarationSpecifiers?

InitDeclaratorList < InitDeclarator (',' InitDeclarator)*

InitDeclarator < Declarator ('=' Initializer)?

StorageClassSpecifier <- "typedef" / "extern" / "static" / "auto" / "register"

TypeSpecifier <- "void"
               / "char" / "short" / "int" / "long"
               / "float" / "double"
               / "signed" / "unsigned"
               / StructOrUnionSpecifier
               / EnumSpecifier
               #/ TypedefName # To reactivate with an associated semantic action:
               # - keep a list of typedef'd names
               # - and verify that the read identifier is already defined

StructOrUnionSpecifier < ("struct" / "union") ( Identifier ('{' StructDeclarationList '}')?
                                              / '{' StructDeclarationList '}')

StructDeclarationList <- StructDeclaration (:Spacing StructDeclaration)*

StructDeclaration < SpecifierQualifierList StructDeclaratorList ';'

SpecifierQualifierList <- (TypeQualifier / TypeSpecifier) (:Spacing (TypeQualifier / TypeSpecifier))*

StructDeclaratorList < StructDeclarator (',' StructDeclarator)*

StructDeclarator < ( Declarator ConstantExpression?
                   / ConstantExpression)

EnumSpecifier < "enum" ( Identifier ('{' EnumeratorList '}')?
                       / '{' EnumeratorList '}')

EnumeratorList < Enumerator (',' Enumerator)*

Enumerator < EnumerationConstant ('=' ConstantExpression)?

EnumerationConstant <- Identifier

TypeQualifier <- "const" / "volatile"

Declarator < Pointer? DirectDeclarator

DirectDeclarator < (Identifier / '(' Declarator ')') ( '[' ']'
                                                     / '[' ConstantExpression ']'
                                                     / '(' ')'
                                                     / '(' ParameterTypeList ')'
                                                     / '(' IdentifierList ')'
                                                     )*

Pointer < ('*' TypeQualifier*)*

TypeQualifierList <- TypeQualifier (:Spacing TypeQualifier)*

ParameterTypeList < ParameterList (',' "...")?

ParameterList < ParameterDeclaration (',' ParameterDeclaration)*

ParameterDeclaration < DeclarationSpecifiers (Declarator / AbstractDeclarator)?

IdentifierList < Identifier (',' Identifier)*

TypeName < SpecifierQualifierList AbstractDeclarator?

AbstractDeclarator < Pointer DirectAbstractDeclarator
                   / DirectAbstractDeclarator
                   / Pointer

DirectAbstractDeclarator < ('(' AbstractDeclarator ')'
                           / '[' ']'
                           / '[' ConstantExpression ']'
                           / '(' ')'
                           / '(' ParameterTypeList ')'
                           )
                           ( '[' ']'
                           / '[' ConstantExpression ']'
                           / '(' ')'
                           / '(' ParameterTypeList ')'
                           )*

TypedefName <- Identifier

Initializer < AssignmentExpression
            / '{' InitializerList ','? '}'

InitializerList < Initializer (',' Initializer)*

#
# C statement rules
#

Statement < LabeledStatement
          / CompoundStatement
          / ExpressionStatement
          / IfStatement
          / SwitchStatement
          / IterationStatement
          / GotoStatement
          / ContinueStatement
          / BreakStatement
          / ReturnStatement

LabeledStatement < Identifier ':' Statement
                 / 'case' ConstantExpression ':' Statement
                 / 'default' ':' Statement

CompoundStatement < '{' '}'
                  / '{' DeclarationList '}'
                  / '{' StatementList '}'
                  / '{' DeclarationList StatementList '}'

DeclarationList <- Declaration (:Spacing Declaration)*

StatementList <- Statement (:Spacing Statement)*

ExpressionStatement < Expression? ';'

IfStatement < "if" '(' Expression ')' Statement ('else' Statement)?

SwitchStatement < "switch" '(' Expression ')' Statement

IterationStatement < WhileStatement / DoStatement / ForStatement

WhileStatement < "while" '(' Expression ')' Statement

DoStatement < "do" Statement "while" '(' Expression ')' ';'

ForStatement < "for" '(' Expression? ';' Expression? ';' Expression? ')' Statement

GotoStatement < "goto" Identifier ';'

ContinueStatement < "continue" ';'

BreakStatement < "break" ';'

ReturnStatement < Return Expression? :';'

Return <- "return"

# The following comes from me, not an official C grammar

Identifier <~ !Keyword [a-zA-Z_] [a-zA-Z0-9_]*

Keyword <- "auto" / "break" / "case" / "char" / "const" / "continue"
         / "default" / "double" / "do" / "else" / "enum" / "extern"
         / "float" / "for" / "goto" / "if" / "inline" / "int" / "long"
         / "register" / "restrict" / "return" / "short" / "signed"
         / "sizeof" / "static" / "struct" / "switch" / "typedef" / "union"
         / "unsigned" / "void" / "volatile" / "while"
         / "_Bool" / "_Complex" / "_Imaginary"

Spacing <~ (space / endOfLine / Comment)*

Comment <~ "//" (!endOfLine .)* endOfLine

StringLiteral <~ doublequote (DQChar)* doublequote

DQChar <- EscapeSequence
        / !doublequote .

EscapeSequence <~ backslash ( quote
                            / doublequote
                            / backslash
                            / [abfnrtv]
                            )

CharLiteral <~ quote (!quote (EscapeSequence / .)) quote

IntegerLiteral <~ Sign? Integer IntegerSuffix?

Integer <~ digit+

IntegerSuffix <- "Lu" / "LU" / "uL" / "UL"
               / "L" / "u" / "U"

FloatLiteral <~ Sign? Integer "." Integer? (("e" / "E") Sign? Integer)?

Sign <- "-" / "+"
`;

enum parserC = grammar(grammarC);
mixin(parserC);

shared static this()
{
    import std.file: write;
    import std.path: buildNormalizedPath;
    write(buildNormalizedPath("generated_source", parserPath_A), parser_A);
    write(buildNormalizedPath("generated_source/", grammarPath_A), grammar_A);
}

void main(string[] args)
{
    /* writeln(parser_A); */
    auto parseTree1 = A("1 + 2 - (3*x-5)*6");
    ParseTree f;
    // pragma(msg, parseTree1.matches);
    assert(parseTree1.matches == ["1", "+", "2", "-", "(", "3", "*", "x", "-", "5", ")", "*", "6"]);
    writeln(parseTree1);

    /* writeln(parserC); */
    auto cTree = C(`int x;`);    // TODO is it possible to prune non-terminal single child nodes?
    writeln(cTree);
}