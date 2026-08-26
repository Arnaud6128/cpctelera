CC=gcc
BINDIR=/usr/bin
SRC  = src
BIN  = bin

all: rle 
rle:
	mkdir -p $(BIN)
	$(CC) $(SRC)/rlewb.c -o $(BIN)/rlewb

clean: 
	rm -rf *.o rle unrle

cleanall: 
	rm -rf *.o rle unrle

