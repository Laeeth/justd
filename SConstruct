#!/usr/bin/env scons-file

import os.path
import multiprocessing
from pprint import pprint as ppr

# half because DMD is currently too heavy on memory
num_jobs = min(int(multiprocessing.cpu_count() + 1), 5)
SetOption("num_jobs", num_jobs)
print "scons: Using at maximum " + str(num_jobs) + " number of jobs"

# D compilation flags
dflags = ["-vcolumns", "-wi"]

# Build Type
AddOption("--build-type", dest="build-type", type="string")
build_type = GetOption("build-type")
if build_type == "debug":
    dflags += ["-debug", "-g", "-gs"]
if build_type == "debug-unittest":
    dflags += ["-debug", "-g", "-gs", "-unittest"]
elif build_type == "release":
    dflags += ["-release", "-O"]
elif build_type == "debug-release":
    dflags += ["-debug", "-release", "-O"]
elif build_type == "release-unittest":
    dflags += ["-release", "-unittest"]
elif build_type == "unittest-release":
    dflags += ["-unittest", "-release", "-O"]
elif build_type == "debug-unittest-release":
    dflags += ["-debug", "-unittest", "-release", "-O"]
elif (build_type in ["profile-release", "release-profile"]):
    dflags += ["-profile", "-release", "-O"]

env = Environment(DC="/home/per/opt/x86_64-unknown-linux-gnu/dmd/linux/bin64/dmd",
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
