# ---------------------------------------------------------
# Makefile for acme
# ---------------------------------------------------------

ACME = acme
ACMEFLAGS = -f cbm

SRC_KERNAL=https://www.zimmers.net/anonftp/pub/cbm/firmware/computers/pet/8296/kernal-basic-324746-01.bin
SRC_EDITOR=https://www.zimmers.net/anonftp/pub/cbm/firmware/computers/pet/8296/edit-50hz-324243-04.bin
SRC := $(wildcard *.asm)
BINS := $(patsubst %.asm,build/%.bin,$(SRC))
LBL  := $(patsubst %.asm,build/%.lbl,$(SRC))

SUBDIRS = loader fat32
LOADER = loader/loader.bin

all: $(SUBDIRS) tmp/firmware-b000.bin

custom: 
	acme config-custom/\!custom.asm

$(SUBDIRS):
	$(MAKE) -C $@

tmp/firmware.bin:
	mkdir -p tmp
	wget $(SRC_KERNAL) -O tmp/firmware.bin 
	wget $(SRC_EDITOR) -O tmp/editor.bin 

tmp/firmware-b000.bin: tmp/firmware.bin
	acme -r cp256-ps2.rpt config-custom/\!cp256-ps2.asm
	acme -r cp256-kbd64.rpt config-custom/\!cp256-kbd64.asm
	split -b 4096 tmp/firmware.bin tmp/f
ifneq ($(wildcard $(LOADER)),)
	@echo "Patching Loader..."
	dd if=$(LOADER) of=kernel4.bin bs=1 seek=3421 conv=notrunc 
endif
# create images for flashing
	cat basic-4.901465-23-20-21.bin binaries/editrom-cp256ps2.bin kernel4.bin >tmp/firmware-b000.bin
#	cat basic-4.901465-23-20-21.bin binaries/editrom-cp256kbd64.bin kernel4.bin >tmp/firmware-b000.bin
#	cat tmp/faa tmp/fab tmp/fac binaries/editrom-cp256kbd64.bin tmp/fad >tmp/firmware-b000.bin
	cat tmp/faa tmp/fab tmp/fac tmp/editor.bin tmp/fad >tmp/firmware-o-b000.bin
	cat tmp/faa tmp/faa skernal/rom-a000.bin tmp/firmware-b000.bin >32k
	cat 32k 32k 32k 32k >128k 
	cat 128k 128k 128k 128k >512k

clean:
	rm -f tmp/firmware-b000.bin
	rm -f tmp/firmware-o-b000.bin
	@for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir clean; \
	done

build:
	mkdir -p build

# rule: .asm → .bin + .lbl
build/%.bin: %.asm
	$(ACME) $(ACMEFLAGS) -l build/$*.lbl -o $@ $<

fullclean:
	rm -rf build
	rm -rf tmp


.PHONY: all clean $(SUBDIRS)
