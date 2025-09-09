.PHONY: all clean test

all: bin/menus

bin/menus: menus.c | bin
	clang -std=c99 -O3 -F/System/Library/PrivateFrameworks/ -framework Carbon -framework SkyLight $< -o $@

bin:
	mkdir bin

clean:
	rm -rf bin

test:
	@echo "No tests implemented"

