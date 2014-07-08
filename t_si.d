#!/usr/bin/env rdmd

import std.si;

void foo()
{
  enum foo = baseUnit!("foo", "f");
  enum bar = scale!(foo, 21, "bar", "b");

  auto a = 2 * bar;
  assert(convert!foo(a) == 42 * foo);
}
