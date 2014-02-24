deps:
	sudo add-apt-repository -y "ppa:zoogie/sdl2-snapshots";
	sudo apt-get install -y libsdl2-dev;
	sudo apt-get update;
	sudo apt-get dist-upgrade;
	bld_SDL2_all;
tags:

clean:
	$(RM) *.o *.11.core
