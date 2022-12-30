BUILD = ./build
SRC = ./src
OBJECTS = nes-pi.o

all: nes-pi.nes

clean:
	mkdir -p $(BUILD)
	rm -rf build/*.o nes-pi.nes

nes-pi.nes: $(OBJECTS)
	cl65 -t nes -o nes-pi.nes $(BUILD)/*.o

%.o: $(SRC)/%.s
	ca65 $< -o $(BUILD)/$@  -t nes
