BUILD=./build
NES=./nes
LIB=./lib

clean:
	mkdir -p $(BUILD)
	mkdir -p $(NES)
	rm -rf build/*.o nes/*.nes

nes-pi-small:
	ca65 -t nes -o $(BUILD)/nes-pi-small.o $(LIB)/nes-pi-small.s
	cl65 -t nes -o $(NES)/nes-pi-small.nes $(BUILD)/nes-pi-small.o

nes-pi:
	ca65 -t nes -o $(BUILD)/nes-pi.o $(LIB)/nes-pi.s
	cl65 -t nes -o $(NES)/nes-pi.nes $(BUILD)/nes-pi.o
