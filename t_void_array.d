#!/usr/bin/env rdmd-dev

/** Test void Initialized Arrays.
    See also: http://forum.dlang.org/thread/jykthdxlxjvktlfdjucc@forum.dlang.org#post-qnprlkztsbtkcpitadhv:40forum.dlang.org
 */

import std.stdio, std.algorithm, std.range;
import dbg;

unittest {
    int n = 3;
    auto b = new float[n];
    dln(b);

    int[3] c = void;
}
