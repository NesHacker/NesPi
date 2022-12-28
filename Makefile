BUILD=./build
LIB=./lib

all:
	mkdir -p $(BUILD)
	ca65 -t nes -o $(BUILD)/nes-pi.o nes-pi.s
	cl65 -t nes -o nes-pi.nes $(BUILD)/nes-pi.o

clean:
	mkdir -p $(BUILD)
	rm -rf build/*.o nes-pi.nes
