BUILD=./build
NES=./nes
LIB=./lib

all:
	ca65 -t nes -o $(BUILD)/nes-pi.o nes-pi.s
	cl65 -t nes -o $(NES)/nes-pi.nes $(BUILD)/nes-pi.o

clean:
	mkdir -p $(BUILD)
	mkdir -p $(NES)
	rm -rf build/*.o nes/*.nes
