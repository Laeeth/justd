#!/usr/bin/env rdmd-dev-module

/** \file t_array.d
 * \brief
 */

import std.stdio, std.algorithm, std.range;
import dbg;

unittest {
    const x = [1, 2, 3, 4];
    assert(x[] + x[]);
    assert(x);
    assert(x);
}

unittest {
    int[] x;

    dln(x.sizeof);

    if (x) {
        dln("Here!");
    } else {
        dln("There!");
    }

    int xx[2];
    auto xc = xx;
    xc[0] = 1;
    dln(xx);
    dln(xc);
    int[2] xx_;

    auto hit = x.find(1);
    if (hit) {
        dln("Hit: ", hit);
    } else {
        dln("No hit");
    }
    int[2] z;                   // arrays are zero initialized

    dln(z);

    assert([].ptr == null);
    assert("ab"[$..$] == []);
    auto p = "ab"[$..$].ptr;
    dln(p);
    assert(p != null);

    auto w = [1, 2];
    assert(w[0..0]);
    assert(w[$..$]);
    assert(![]);
}
