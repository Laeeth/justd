#!/usr/bin/env rdmd-dev-module

/** Various debug tools. */
module dbg;

/* http://stackoverflow.com/questions/19413340/escaping-safety-with-debug-statements */
debug auto trustedPureDebugCall (alias fn, A...) (A args) @trusted pure {
    debug return fn(args);
}

@trusted void debug_writeln(string file = __FILE__, uint line = __LINE__, T...)(T t) {
    import std.stdio: writeln;
    writeln(file,":", line,":debug: ", t);
}
alias debug_writeln dln;

@trusted void debug_writefln(string file = __FILE__, uint line = __LINE__, T...)(T t) {
    import std.stdio: writefln;
    writefln(file,":", line,":debug: ", t);
}
alias debug_writefln dfln;

@trusted void debug_variableln(alias T, string file = __FILE__, uint line = __LINE__)() {
    import std.stdio: writeln;
    writeln(file,":", line,":debug: ", T.stringof, ":", T);
}
alias debug_variableln dvr;
