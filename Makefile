ECTAGS_LANGS = Make,C,D,C++,Pascal,Sh,Ada,D,Lisp,Go,Protobuf
TAGS_FILES = *.d */*.d Makefile

all: tags
deps:
	sudo add-apt-repository -y "ppa:zoogie/sdl2-snapshots";
	sudo apt-get install -y libsdl2-dev;
	sudo apt-get update;
	sudo apt-get dist-upgrade;
	bld_SDL2_all;
tags:
	@ctags --sort=yes --links=no --excmd=number --languages=$(ECTAGS_LANGS) --extra=+f --file-scope=yes --fields=afikmsSt --totals=yes $(TAGS_FILES)
clean:
	$(RM) tags TAGS
	$(RM) *.o *.11.core
