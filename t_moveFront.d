#!/usr/bin/env rdmd-dev-module

import all;

int main(string[] args)
{
    auto x = [11, 22];
    writeln(x.moveFront);
    writeln(x.moveFront);
    x.popFront;
    writeln(x.moveFront);
    writeln(x.moveFront);
    return 0;
}
