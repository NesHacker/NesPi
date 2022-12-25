BUILD=./build
NES=./nes

clean:
	mkdir -p $(BUILD)
	mkdir -p $(NES)
	rm -rf build/*.o nes/*.nes

%-test: %-test.o test-wrapper.o
	cl65 \
		-t nes \
		-o $(NES)/$@.nes \
		$(BUILD)/math32-test.o $(BUILD)/test-wrapper.o

%.o: %.s
	ca65 -t nes $< -o $(BUILD)/$@
