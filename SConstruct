#!/usr/bin/env scons-file

import os.path
import multiprocessing
from pprint import pprint as ppr

# half because DMD is currently too heavy on memory
num_jobs = min(int(multiprocessing.cpu_count() + 1), 5)
SetOption("num_jobs", num_jobs)
print "scons: Using at maximum " + str(num_jobs) + " number of jobs"

# D compilation flags
dflags = ["-vcolumns", "-wi", "-debug"]

# Build Type
AddOption("--build-type", dest="build-type", type="string")

default_build_type = "release"

build_type = GetOption("build-type")
if not build_type:
    build_type = default_build_type

for build_flag in build_type.split("-"):
    dflags.append("-" + build_flag)
    if build_flag == "release":
        dflags.append("-O")
    if build_flag == "debug":
        dflags += ["-g", "-gs"]

env = Environment(DC="/usr/bin/dmd", # "/home/per/opt/x86_64-unknown-linux-gnu/dmd/linux/bin64/dmd",
                  DFLAGS=dflags)
env.Decider("MD5-timestamp")
env.CacheDir(os.path.expanduser("~/.cache/scons"))
dflags_value = env.Value(dflags)
# ppr(dflags_value.__dict__)

knetquery_srcs = (["knetquery/source/app.d",
                   "stdx/container/fixed_array.d",
                   "stdx/container/sorted.d",
                   "dbg.d", "msgpack.d", "predicates.d", "getopt_ex.d",
                   "wordnet.d",
                   "grammars.d", "stemming.d", "ixes.d",
                   "bitset.d", "assert_ex.d", "range_ex.d", "algorithm_ex.d", "traits_ex.d", "sort_ex.d", "mmfile_ex.d", "skip_ex.d", "typecons_ex.d",
                   "bylines.d",
                   "rational.d", "combinations.d", "permutations.d", "arsd/dom.d", "arsd/characterencodings.d",
                   "backtrace/backtrace.d" ] +
                  env.Glob("knet/*.d") +
                  env.Glob("knet/*/*.d"))

# TODO remove when DFLAGS new SCons version with DFLAGS fix is released
knetquery_objs = []
for src in knetquery_srcs:
    obj = env.StaticObject(src)
    env.Depends(obj, [dflags_value])
    knetquery_objs.append(obj)

knetquery = env.Program(target="knetquery/knetquery",
                        source=knetquery_objs)
Default(knetquery)

AddOption("--list-default-targets", dest="list-default-targets", type="string")
list_targets = GetOption("list-default-targets")

if list_targets:
    print "scons: Default targets are", map(str, DEFAULT_TARGETS)
