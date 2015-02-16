#!/usr/bin/env rdmd-dev

module t_typetuple;

/** \file t_typetuple.d
 * \brief
 */

import std.stdio, std.algorithm;
import dbg;

void main(string[] args)
{
     auto x = [1, 2, 3];
     dln(x);
     x = x.remove!"a==1";
     dln(x);
}
