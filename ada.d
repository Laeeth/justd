#!/usr/bin/env rdmd-dev-module

/** Ada Parser.
    Copyright: Per Nordlöw 2014-.
    License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
    Authors: $(WEB Per Nordlöw)
    See also: https://mentorembedded.github.io/cxx-abi/abi.html
 */
module ada;

import std.traits: isSomeString;

/** Ada Parser. */
class Parser(R) if (isSomeString!R)
{
    this(R r,
         bool show = false)
    {
        this.r = r;
        this.show = show;
    }
    R r;
    bool show = false;
    bool supportDollars = true; // support GCC-style dollars in symbols
private:
    string[] sourceNames;
}

/** Expression */
class Expr
{
    size_t soff; // byte offset into source
}

/** Unary Operation */
class UOp : Expr
{
    Expr uArg;
}

/** Binary Operation */
class BOp : Expr
{
    Expr lArg, rArg;
}

/** N-arry Operation */
class NOp : Expr
{
    Expr[] args;
}

/** Identifier */
class Id : Expr
{
}

/** Keyword */
class Keyword : Expr
{
}

/** Numeric Literal */
class Num : Expr
{
}

auto parseId(R)(R r)
{
}

auto parse(R)(R r)
{
    return new Parser!R(r);
}

unittest
{
    import dbg;
    dln(parse("name"));
    dln(parse("42"));
    dln(parse("1.1"));
}
