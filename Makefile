CTAGS = ~/opt/x86_64-unknown-linux-gnu/ctags-snapshot/bin/ctags-exuberant
ECTAGS_LANGS = Make,C,C++,D,Pascal,Sh,Ada,Lisp,Go,Protobuf
TAGS_FILES = *.d */*.d */*/*.d Makefile $(shell find ~/opt/x86_64-unknown-linux-gnu/dmd -type f -iname '*.d')
TAGS_D_FILES = *.d */*.d  */*/*.d $(shell find ~/opt/x86_64-unknown-linux-gnu/dmd -type f -iname '*.d')

all: tags
deps:
	sudo add-apt-repository -y "ppa:zoogie/sdl2-snapshots";
	sudo apt-get install -y libsdl2-dev;
	sudo apt-get update;
	sudo apt-get dist-upgrade;
	bld_SDL2_all;
ctags: $(TAGS_FILES) Makefile
	@$(CTAGS) --sort=yes --links=no --excmd=number --languages=$(ECTAGS_LANGS) --extra=+f --file-scope=yes --fields=afikmsSt --totals=yes $(TAGS_FILES)
tags.dscanner: $(TAGS_D_FILES) Makefile
	dscanner -c $(TAGS_D_FILES) > $@
tags: ctags
clean:
	$(RM) tags TAGS
	$(RM) *.o *.11.core
