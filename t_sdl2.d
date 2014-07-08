#!/usr/bin/env rdmd-dev

// This example shows how to import all of the DerelictSDL2 bindings. Of course,
// you only need to import the modules that correspond to the libraries you
// actually need to load.

import derelict.sdl2.sdl;
import derelict.sdl2.image;
import derelict.sdl2.mixer;
import derelict.sdl2.ttf;
import derelict.sdl2.net;

pragma(lib, "dl");
// pragma(lib, "SDL2");
// pragma(lib, "SDL2_image");
// pragma(lib, "SDL2_mixer");
// pragma(lib, "SDL2_ttf");
// pragma(lib, "pthread");

void main() {
    // This example shows how to load all of the SDL2 libraries. You only need
    // to call the load methods for those libraries you actually need to load.

    // Load the SDL 2 library.
    DerelictSDL2.load();

    // Load the SDL2_image library.
    DerelictSDL2Image.load();

    // Load the SDL2_mixer library.
    DerelictSDL2Mixer.load();

    // Load the SDL2_ttf library
    DerelictSDL2ttf.load();

    // Load the SDL2_net library.
    DerelictSDL2Net.load();

    // Now SDL 2 functions for all of the SDL2 libraries can be called.
}
