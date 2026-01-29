# ---------------------------------------------------------
# Makefile für ACME-basierte cbm-edit-rom Builds
# ersetzt alle build-*.bat Skripte
# ---------------------------------------------------------

ACME = acme
ACMEFLAGS = -f cbm

SRC := $(wildcard *.asm)
BINS := $(patsubst %.asm,build/%.bin,$(SRC))
LBL  := $(patsubst %.asm,build/%.lbl,$(SRC))


all:
	acme config-custom/\!custom.asm
#all: build $(BINS)

build:
	mkdir -p build

# Regel: .asm → .bin + .lbl
build/%.bin: %.asm
	$(ACME) $(ACMEFLAGS) -l build/$*.lbl -o $@ $<

clean:
	rm -rf build

.PHONY: all clean
