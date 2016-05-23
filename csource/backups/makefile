include makefile.inc

.PHONY: all clean

all: $(DIR_TNT)/bin/tnt_web

$(DIR_TNT)/bin/tnt_web: ../obj/webload.o ../obj/webmain.o ../obj/webpmsp.o 
	mkdir --parents ../bin
	$(FF) -o $@ $^ $(FFLAGS) 
	
../obj/%.o: %.c
	mkdir --parents ../obj
	$(CC) -c -o $@ $< $(CFLAGS) 

clean:
	rm ../obj/* $(DIR_TNT)/bin/tnt_web
