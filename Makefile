vpath %.exe bin/
vpath %.nim src/

NIMFLAGS = --d:mingw --d:release --cpu=amd64 --app=console --deadCodeElim:on --opt:size --stackTrace:off --lineTrace:off
SRCS_BINS = $(notdir $(wildcard src/*.nim))
BINS = $(patsubst %.nim,%.exe,$(SRCS_BINS))

.PHONY: clean

default: build

build: $(BINS)

rebuild: clean build

clean:
	rm -rf bin/*.exe

%.exe : %.nim
	nim c $(NIMFLAGS) --app=console --cpu=amd64 --out=bin/$*.exe $<