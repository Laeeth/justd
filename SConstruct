#!/usr/bin/env scons-file

import os.path

env = Environment(DC="/home/per/opt/x86_64-unknown-linux-gnu/dmd/linux/bin64/dmd")
env.CacheDir(os.path.expanduser("~/.cache/scons"))

libraries = ['phobos', 'pthread', 'm']

env.Program(target="knetquery/knetquery",
            source=[ "knetquery/source/app.d",
                     "dbg.d", "msgpack.d", "predicates.d",
                     "knet/languages.d", "knet/roles.d", "knet/origins.d", "knet/thematics.d",
                     "knet/decodings.d", "knet/relations.d", "knet/senses.d", "knet/lemmas.d",
                     "knet/base.d",
                     "knet/cn5.d", "knet/nell.d", "knet/wordnet.d", "knet/moby.d",
                     "knet/synlex.d", "knet/folklex.d", "knet/swesaurus.d",
                     "knet/lectures/all.d", "knet/dummy.d",
                     "wordnet.d",
                     "grammars.d", "stemming.d", "ixes.d",
                     "assert_ex.d", "range_ex.d", "algorithm_ex.d", "traits_ex.d", "sort_ex.d", "mmfile_ex.d", "skip_ex.d",
                     "bylines.d",
                     "rational.d", "combinations.d", "permutations.d", "arsd/dom.d", "arsd/characterencodings.d",
                     "backtrace/backtrace.d" ])

# libraryPaths = ['/usr/share/dmd/lib',
#                 '/usr/share/dmd/src/druntime/import',
#                 '/usr/share/dmd/src/phobos']
