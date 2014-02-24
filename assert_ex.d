#!/usr/bin/env rdmd-dev

module assert_ex;

// import std.string : format;
import core.exception : AssertError;
import std.conv: to;

/** A Better assert.
    See also: http://poita.org/2012/09/02/a-better-assert-for-d.html?utm_source=feedburner&utm_medium=feed&utm_campaign=Feed%3A+poita+%28poita.org%29
    TODO: Can we convert args to strings like GCC's __STRING(expression)?
    TODO: Make these be able to be called in unittest placed in struct scopes
*/
@trusted nothrow void assertTrue(T, string file = __FILE__, uint line = __LINE__, Args...) (T test, lazy Args args)
{
    version (assert) if (!test)
        throw new AssertError("at \n" ~file~ ":" ~to!string(line)~ ":\n  test: " ~to!string(test));
}
@trusted nothrow void assertEqual(T, U, string file = __FILE__, uint line = __LINE__, Args...) (T lhs, U rhs, lazy Args args)
{
    version (assert) if (lhs != rhs)
        throw new AssertError("at \n" ~file~ ":" ~to!string(line)~ ":\n  lhs: " ~to!string(lhs)~ " !=\n  rhs: " ~to!string(rhs));
}
@trusted nothrow void assertLessThanOrEqual(T, U, string file = __FILE__, uint line = __LINE__, Args...) (T lhs, U rhs, lazy Args args)
{
    version (assert) if (lhs <= rhs)
        throw new AssertError("at \n" ~file~ ":" ~to!string(line)~ ":\n  lhs: " ~to!string(lhs)~ " >\n  rhs: " ~to!string(rhs));
}
@trusted nothrow void assertNotEqual(T, U, string file = __FILE__, uint line = __LINE__, Args...) (T lhs, U rhs, lazy Args args)
{
    version (assert) if (lhs == rhs)
        throw new AssertError("at \n" ~file~ ":" ~to!string(line)~ ":\n  lhs: " ~to!string(lhs)~ " ==\n  rhs: " ~to!string(rhs));
}
