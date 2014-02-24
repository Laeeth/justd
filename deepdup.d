#!/usr/bin/env rdmd-dev

// See: http://forum.dlang.org/thread/hojk95$4mk$1@digitalmars.com
// TODO: Support inout relevant for const?

module deepdup;

import std.stdio, std.algorithm;

template TypeofDeepdup(T) {
    alias typeof(deepdup(T.init)) TypeofDeepdup;
}

ref Unqual!T deepdup(T)(T t) if (is(T == struct) && !is(T.Types)) {
    staticMap!(TypeofDeepdup, typeof(t.tupleof)) tup;
    foreach(i,Type; tup) { tup[i] = deepdup(t.tupleof[i]);}
    return Unqual!T(tup);
}

Tuple!(staticMap!(TypeofDeepdup, T.Types))
deepdup(T)(T t) if (is(T.Types)) {
    staticMap!(TypeofDeepdup, T.Types) tup;
    foreach(i,Type; tup) { tup[i] = deepdup(t.field[i]);}
    return tuple(tup);
}

Unqual!T deepdup(T)(T t) if (is(T == class)) {
    staticMap!(TypeofDeepdup, typeof(t.tupleof)) tup;
    foreach(i,Type; tup) { tup[i] = deepdup(t.tupleof[i]);}
    return new Unqual!T(tup);
}

TypeofDeepdup!(ElementType!T)[] deepdup(T)(T t) if (isDynamicArray!T) {
    auto result = new TypeofDeepdup!(ElementType!T)[](t.length);
    foreach(i, elem; t) result[i] = deepdup(elem);
    return result;
}

TypeofDeepdup!(ElementType!T)[T.length] deepdup(T)(T t) if (isStaticArray!T){
    TypeofDeepdup!(ElementType!T)[T.length] result = t;
    foreach(ref elem; result) elem = deepdup(elem);
    return result;
}

TypeofDeepdup!T* deepdup(T)(T* t) {
    return &deepdup(*t);
}

Unqual!T deepdup(T)(T t) if (!is(T == struct) && !is(T == class) &&
                             !isArray!T && !is(T.Types) && !isPointer!T) {
    return cast(Unqual!T)t;
}

unittest {
    auto x = [1, 2, 3];
    assert(x == x.dup);
    auto y = x;
    assert(&x[0] == &y[0]);
    assert(&x[0] != &x.dup[0]);
}

void main(string[] args) {
}
