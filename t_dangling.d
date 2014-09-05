#!/usr/bin/env rdmd-unittest-module

import std.stdio, std.algorithm;

int* g;

int* id(int* a)
{
    g = a;
    return a;
}

T* tid(T)(T* a)
{
    return a;
}

@safe int* dangling(bool x)
{
    int i = 1234;
    return x ? tid(&i) : id(&i);
}

int add_one()
{
    int* num = dangling(false);
    int* tum = dangling(true);
    return *num + *tum + 1;
}

void main(string args[])
{
    add_one();
}
