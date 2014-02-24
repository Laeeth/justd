#!/usr/bin/env rdmd-release

/**
 * \file palindrome.d
 * \brief
 * \see http://stackoverflow.com/questions/14469612/template-conflict-for-palindrome-algorithm-on-string-array
 * \see
 */

import std.stdio, std.datetime, std.array, std.typetuple,
       std.range, std.algorithm;

bool isPalindrome0(T)(in T[] s) @safe pure nothrow {
    size_t i = 0;
    for (; i < s.length / 2 && s[i] == s[$ - i - 1]; ++i) {}
    return i == s.length / 2;
}

bool isPalindrome1(T)(T[] s) @safe pure nothrow {
    while (s.length > 1 && s.front == s.back) {
        s.popBack;
        s.popFront;
    }
    return s.length <= 1;
}

bool isPalindrome2(T)(T[] s) @safe pure nothrow {
    for (;
         s.length > 1 && s.front == s.back;
         s.popBack, s.popFront) {}
    return s.length <= 1;
}

bool isPalindrome3(T)(in T[] s) @safe pure nothrow {
    foreach (immutable i; 0 .. s.length / 2)
        if (s[i] != s[$ - i - 1])
            return false;
    return true;
}

/// A high-level version.
bool isPalindrome4(T)(in T[] s) @safe pure /* nothrow */ {
    return s.retro.equal(s);
}

/** Returns: true if a is a Palindrome. */
bool isPalindrome5(T)(T[] a)
{
    for (; a.length >= 2; a = a[1 .. $-1]) {
        if (a[0] != a[$-1]) {
            return false;
        }
    }
    return true;
}

/** Returns: true if r is a Palindrome. */
bool isPalindrome6(Range)(Range r) if (!isArray!Range) {
    while (!r.empty) {
        if (a.front != a.back) { return false; }
        r.popFront();
        if (r.empty) { return true; }
        r.popBack();
    }
    // for (; !r.empty; r.popFront(), r.popBack()) {
    //   if (a.front != a.back) {
    //     return false;
    //   }
    // }
    return true;
}

// unittest { assert(isPalindrome0("dallassallad")); }
// unittest { assert(isPalindrome1("dallassallad")); }
// unittest { assert(isPalindrome2("dallassallad")); }
// unittest { assert(isPalindrome3("dallassallad")); }
// unittest { assert(isPalindrome4("dallassallad")); }
// unittest { assert(isPalindrome5("dallassallad")); }
// unittest { assert(isPalindrome6("dallassallad")); }

int test(alias F)(in int nLoops) @safe pure /* nothrow */ {
    int[10] a;
    typeof(return) n = 0;
    foreach (immutable _; 0 .. nLoops) {
        a[4] = !a[4];
        n += F(a);
    }
    return n;
}

void main() {
    enum size_t nLoops = 20_000_000;
    StopWatch sw;
    foreach (alg; TypeTuple!(isPalindrome0,
                             isPalindrome1,
                             isPalindrome2,
                             isPalindrome3,
                             isPalindrome4)) {
        sw.reset;
        sw.start;
        immutable n = test!alg(nLoops);
        sw.stop;
        writeln(alg.stringof, ": ", n, " ", sw.peek.msecs, "ms");
    }
}
