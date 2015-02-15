#!/usr/bin/env scons-file

import os.path
import multiprocessing

# half because DMD is currently too heavy on memory
num_jobs = int(multiprocessing.cpu_count() + 1)
SetOption("num_jobs", num_jobs)
print "scons: Using at maximum " + str(num_jobs) + " number of jobs"

# D compilation flags
dflags = ["-vcolumns", "-wi"]

# build type
AddOption('--build-type', dest='build-type', type='string')
build_type = GetOption('build-type')
if build_type == "debug":
    dflags += ["-debug", "-g", "-gs"]
if build_type == "debug-unittest":
    dflags += ["-debug", "-g", "-gs", "-unittest"]
elif build_type == "release":
    dflags += ["-release"]
elif build_type == "release-unittest":
    dflags += ["-release", "-unittest"]

env = Environment(DC="/home/per/opt/x86_64-unknown-linux-gnu/dmd/linux/bin64/dmd",
                  DFLAGS=dflags)
env.Decider("MD5-timestamp")
env.CacheDir(os.path.expanduser("~/.cache/scons"))

knetquery = env.Program(target="knetquery/knetquery",
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
Default(knetquery)

AddOption('--list-default-targets', dest='list-default-targets', type='string')
list_targets = GetOption('list-default-targets')

if list_targets:
    print "scons: Default targets are", map(str, DEFAULT_TARGETS)
