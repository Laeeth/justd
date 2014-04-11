#!/usr/bin/env scons-file

env = Environment()
libraries    = ['phobos', 'pthread', 'm']
# libraryPaths = ['/usr/share/dmd/lib',
#                 '/usr/share/dmd/src/druntime/import',
#                 '/usr/share/dmd/src/phobos']

env.Program(target = "fs",
            source = ["fs.d"],
            LIBS = libraries,
            # LIBPATH = libraryPaths
)
