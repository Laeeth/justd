#!/usr/bin/env rdmd

module t_shared;

import core.atomic;

/**
 * \file t_shared.d
 * \brief
 */

import std.stdio;

struct vec {
    int x, y;
};

atomic shared i;
shared vec x;

void main(string[] args)
{
}
