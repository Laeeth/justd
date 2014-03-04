CTAGS = ctasg
ECTAGS_LANGS = Make,C,C++,D,Pascal,Sh,Ada,Lisp,Go,Protobuf
TAGS_FILES = *.d */*.d Makefile

all: tags
deps:
	sudo add-apt-repository -y "ppa:zoogie/sdl2-snapshots";
	sudo apt-get install -y libsdl2-dev;
	sudo apt-get update;
	sudo apt-get dist-upgrade;
	bld_SDL2_all;
tags: $(TAGS_FILES)
	@$(CTAGS) --sort=yes --links=no --excmd=number --languages=$(ECTAGS_LANGS) --extra=+f --file-scope=yes --fields=afikmsSt --totals=yes $(TAGS_FILES)
clean:
	$(RM) tags TAGS
	$(RM) *.o *.11.core
