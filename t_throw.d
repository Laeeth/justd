#!/usr/bin/env rdmd-dev

/* See also: https://github.com/yazd/backtrace-d */

import std.stdio, std.algorithm;

void main()
{
    throw new Exception("Exception thrown");
}
