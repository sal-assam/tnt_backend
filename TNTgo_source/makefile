include makefile.inc

.PHONY: all clean

all: $(DIR_TNT)/bin/tnt_web_new

$(DIR_TNT)/bin/tnt_web_new: webdmrg.o webload.o webmain.o webmpsmodify.o webpmps.o webtebd.o
	$(FF) -o $@ $^ $(FFLAGS) 
	
../obj/%.o: %.c tntweb.h
	$(CC) -c -o $@ $< $(CFLAGS) 

clean:
	rm ../obj/*
