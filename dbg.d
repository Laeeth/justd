#!/usr/bin/env rdmd-dev-module

/** Various debug tools.
    Copyright: Per Nordlöw 2014-.
    License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
    Authors: $(WEB Per Nordlöw)
*/
module dbg;

@trusted:

/* http://stackoverflow.com/questions/19413340/escaping-safety-with-debug-statements */
debug auto trustedPureDebugCall(alias fn, A...) (A args) pure
{
    debug return fn(args);
}

void debug_writeln(string file = __FILE__, uint line = __LINE__, string fun = __FUNCTION__, T...)(T t)
{
    import std.stdio: writeln;
    writeln(file, ":",line, ":",fun, ":debug: ", t);
}
alias dln = debug_writeln;

void debug_writefln(string file = __FILE__, uint line = __LINE__, string fun = __FUNCTION__, T...)(T t)
{
    import std.stdio: writefln;
    writefln(file, ":",line, ":",fun, ":debug: ", t);
}
alias dfln = debug_writefln;

void debug_variableln(alias T, string file = __FILE__, uint line = __LINE__, string fun = __FUNCTION__)()
{
    import std.stdio: writeln;
    writeln(file, ":",line, ":",fun, ":debug: ", T.stringof, ":", T);
}
alias dvr = debug_variableln;
