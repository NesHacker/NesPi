BUILD = ./build
SRC = ./src
OBJECTS = nes-pi.o

all: build-dir nes-pi.nes

clean: build-dir
	rm -rf build/*.o nes-pi.nes

build-dir:
	mkdir -p $(BUILD)

nes-pi.nes: $(OBJECTS)
	cl65 -t nes -o nes-pi.nes $(BUILD)/*.o

%.o: $(SRC)/%.s
	ca65 $< -o $(BUILD)/$@  -t nes
