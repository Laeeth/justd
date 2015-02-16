#!/usr/bin/env rdmd-dev

@safe pure nothrow void strictVoid(T)(T x) { }
@safe pure nothrow bool strictBool(T)(T x) { return false; }
@safe pure nothrow void nonstrictVoid(T)(ref T x) { x += 1; }
@safe pure nothrow bool nonstrictBool(T)(ref T x) { x += 1; return false; }

@safe pure void mayThrow() { throw new Exception("Here!"); }

void main(string args[])
{
    int x = 3;
    strictVoid(x);
    nonstrictVoid(x);
    strictBool(x);
    nonstrictBool(x);
}
