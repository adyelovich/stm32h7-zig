PREFIX := arm-none-eabi-
CC := $(PREFIX)gcc
LD := $(PREFIX)ld
AS := $(PREFIX)as
OBJCOPY := $(PREFIX)objcopy

SRCDIR := src
OBJDIR := obj
INCDIR := include

ASFLAGS := -mcpu=cortex-m7
LDFLAGS := -Timage.ld -nostdlib

all: dirs image.bin

dirs:
	- mkdir -p obj

image.bin: image.elf
	$(OBJCOPY) -Obinary image.elf image.bin

image.elf: $(OBJDIR)/start.o $(OBJDIR)/image.o
	$(LD) $^ -o $@ $(LDFLAGS)

$(OBJDIR)/start.o: $(SRCDIR)/start.s
	$(AS) $(ASFLAGS) $< -g -o $@

home: $(SRCDIR)/home.zig $(SRCDIR)/sys/sys.zig
	zig build-exe -ODebug --name home \
	--dep sys -Mroot=$(SRCDIR)/home.zig \
	-Msys=$(SRCDIR)/sys/sys.zig

# right now Zig build seems too volatile to depend upon/keep up with for now
# so just hard code the command in this Makefile for the time being
$(OBJDIR)/image.o: $(SRCDIR)/main.zig $(SRCDIR)/sys/sys.zig
	zig build-obj -ODebug --name image \
	-fno-formatted-panics -fno-entry \
	-target thumb-freestanding-eabi -mcpu cortex_m7 \
	--dep sys -Mroot=$(SRCDIR)/main.zig \
	-Msys=$(SRCDIR)/sys/sys.zig

	mv image.o $(OBJDIR)
	rm image.o.o

flash:
	st-flash --flash=2m --freq=4M --format=binary --reset \
	--connect-under-reset write image.bin 0x8000000

openocd:
	openocd -f interface/stlink.cfg -f target/stm32h7x.cfg

clean:
	rm -rf image.elf image.bin obj home.o home

.PHONY: all dirs flash openocd clean
