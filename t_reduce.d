#!/usr/bin/env rdmd-unittest

/** \file t_reduce.d
 * \brief
 */

import all;

void main(string[] args)
{
    writeln(0.reduce!"a+b"([1, 2, 3]));
    // writeln([1, 2, 3].reduce!"a+b"(0));

    const numbers = 10.iota.map!(_ => uniform01).array;
    // const minmax = numbers.reduce!(min, max);
}
