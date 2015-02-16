#!/usr/bin/env rdmd-dev

import etc.linux.memoryerror;
import backtrace.backtrace;

int main(string[] args)
{
    import std.stdio: stderr;
    backtrace.backtrace.install(stderr);
    registerMemoryErrorHandler();

    int* x = null;
    *x = 42;
    return 0;
}
