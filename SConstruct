#!/usr/bin/env scons-file

import os.path
import multiprocessing

# half because DMD is currently too heavy on memory
num_jobs = int(multiprocessing.cpu_count() / 2 + 1)
SetOption("num_jobs", num_jobs)
print "scons: Using at maximum " + str(num_jobs) + " number of jobs"

dflags = ["-vcolumns", "-wi"]

build_type = ""

if build_type == "debug":
    dflags += ["-debug", "-g", "-gs"]
if build_type == "debug-unittest":
    dflags += ["-debug", "-g", "-gs", "-unittest"]
elif build_type == "release":
    dflags += ["-release"]

env = Environment(DC="/home/per/opt/x86_64-unknown-linux-gnu/dmd/linux/bin64/dmd",
                  DFLAGS=dflags)
env.CacheDir(os.path.expanduser("~/.cache/scons"))

env.Program(target="knetquery/knetquery",
            source=(["knetquery/source/app.d",
                     "dbg.d", "msgpack.d", "predicates.d",
                     "wordnet.d",
                     "grammars.d", "stemming.d", "ixes.d",
                     "assert_ex.d", "range_ex.d", "algorithm_ex.d", "traits_ex.d", "sort_ex.d", "mmfile_ex.d", "skip_ex.d",
                     "bylines.d",
                     "rational.d", "combinations.d", "permutations.d", "arsd/dom.d", "arsd/characterencodings.d",
                     "backtrace/backtrace.d" ] +
                    env.Glob("knet/*.d") +
                    env.Glob("knet/*/*.d")))
