#!/usr/bin/env rdmd-dev-module

import all;

void main()
{
    int[] x;
    assert(!x.canFind(1));
}
