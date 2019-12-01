SOURCES=$(wildcard *.nim)
EXES=$(patsubst %.nim, %.exe, $(SOURCES))

all: $(EXES)

%.exe: %.nim
	nim c --out:$@ $<
