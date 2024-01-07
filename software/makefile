
# Basic Automatic Variables
#
# $@	Filename of the Target (that caused the recipe to be run)
# $<	Name of the first prerequisite
# $?	Names of all prerequisites newer than the target
# $^	Names of all prerequisites


#############################################################
# Variables
#############################################################
COM_PORT = COM4

# we should really pass the std lib (libgcc.a) to the linker as a libray
# we need
objects = \
build/main.o \
build/crt0.o \
build/uart.o \
build/timer.o \
build/utils.o \
build/ssd1306_i2c.o \
build/terminal.o \
build/text_display.o \
build/spi.o \
build/console.o

lib_misc_includes = -Isrc/lib/misc

lib_printf_includes = -Isrc/lib/printf/src -Isrc/lib/printf/src/printf
lib_printf_objects = build/lib/printf.o

lib_sdcard_includes = -Isrc/lib/sdcard
lib_sdcard_objects = build/lib/mmc.o

lib_fatfs_includes = -Isrc/lib/fatfs
lib_fatfs_objects = \
build/lib/ff.o
# build/lib/ffunicode.o			# for Long File Name extension
# build/lib/ffsystem.o			# OS dependent functions, for thread-safe

lib_objects = \
$(lib_printf_objects) \
$(lib_sdcard_objects) \
$(lib_fatfs_objects)

LIB_INCLUDES = \
$(lib_printf_includes) \
$(lib_fatfs_includes) \
$(lib_sdcard_includes) \
$(lib_misc_includes)

# for configuring libraries
LIB_DEFINES = -DPRINTF_INCLUDE_CONFIG_H=1

boot_objects = \
build/minimal_boot.o

CC=riscv32-unknown-elf-gcc
# linking with gcc instead of ld is recommended
LD=riscv32-unknown-elf-gcc
OBJDUMP=riscv32-unknown-elf-objdump
ELF2HEX=riscv32-unknown-elf-elf2hex
NM=riscv32-unknown-elf-nm
ASCII_HEX_SWAP_ENDIAN=python3 endian_swap.py
ASCII_HEX_TO_BIN=xxd -r -p

COPT = -O0

# compile only
CFLAGS= -g -c $(COPT) -Isrc $(LIB_INCLUDES) $(LIB_DEFINES)

# Change the RV extensions here:
CFLAGS_RV = $(CFLAGS) -march=rv32i -mabi=ilp32 -ffreestanding -mstrict-align

CC_PC=gcc
CFLAGS_PC= $(CFLAGS)

LDFLAGS = -Map=build/output.map 
# LDFLAGS_RV = $(LDFLAGS) --gc-sections -nostartfiles -T riscv32-fpca.ld
# we don't need -nostartfiles as a standalone linker invocation requires it to be provided explicitly
# we need libgcc.a (-lgcc) for soft mult/div, as we aren't using RV32IM
# we also need one of the following: libc.a, libc_nano.a, libg.a, libg_nano.a for malloc etc

# As we are running without an OS, for syscalls we use libnosys.a (_sbrk etc)
LDFLAGS_RV = -nostartfiles -Wl,-Map=build/output.map,--gc-sections,-T,riscv32-fpca.ld,-lgcc,-lg_nano,-lnosys

#############################################################
# Main Outputs
#############################################################
# as this is the first "recipe", executing "make" on its own will run this
all: main boot # hosted
	@echo Made everything!

# For checking against ILAs etc
main : hex/main.hex

upload : hex/main.hex
	./upload.sh $(COM_PORT)

# alternative target to get the disassembly as well
asm : build/main.asm  main build/minimal_boot.asm

# This regenerates the hex/main.hex file, building the other files as necessary
hex/main.hex : build/main.elf asm
	@echo "Building main.hex"
	$(ELF2HEX) --bit-width 32 --input $< --output $@
	$(ASCII_HEX_SWAP_ENDIAN) hex/main.hex build/main.hexr
	$(ASCII_HEX_TO_BIN) build/main.hexr hex/main.bin

build/main.asm : build/main.elf
	@# output to file and to terminal
	@# @echo ""
	@# @echo "******************** START $@ *********************"
	@# @echo ""
	@# riscv32-unknown-elf-objdump -d -S $<
	@# @echo ""
	@# @echo "********************* END $@ **********************"
	@# @echo ""
	@echo "dumping ASM to $@"
	riscv32-unknown-elf-objdump -d -S $< > $@

# This step links all the object files together
build/main.elf : $(objects) $(lib_objects)
	@echo Linking...
	$(LD) -o $@ $^ $(LDFLAGS_RV)

#############################################################
# Hosted build (for small tests)
#############################################################
hosted :
	$(CC_PC) -g src/hosted-test.c -o build/hosted-test
	./build/hosted-test

#############################################################
# Bootloader
#############################################################
boot : hex/boot.hex

hex/boot.hex : build/minimal_boot.o
	@echo "Building boot.hex"
	$(ELF2HEX) --bit-width 32 --input $< --output $@
	$(ASCII_HEX_SWAP_ENDIAN) hex/boot.hex build/boot.hexr
	$(ASCII_HEX_TO_BIN) build/boot.hexr hex/boot.bin

build/minimal_boot.o : src/boot/minimal_boot.c src/boot/crt0-boot.s
	$(CC) -g -O0 -march=rv32i -mabi=ilp32 -ffreestanding -Wl,--gc-sections \
	-nostartfiles -nostdlib -nodefaultlibs -Wl,-T,riscv32-fpca-boot.ld $^ -o $@

build/minimal_boot.asm : build/minimal_boot.o
	riscv32-unknown-elf-objdump -d -S $< > $@
	@#@echo ""
	@#@echo "******************** START $@ *********************"
	@#@echo ""
	@#riscv32-unknown-elf-objdump -d -S $<
	@#@echo ""
	@#@echo "********************* END $@ **********************"
	@#@echo ""

#############################################################
# PrintF Library
#############################################################
build/lib/printf.o : src/lib/printf/src/printf/printf.c
	@echo building $@ from $<
	$(CC) $(CFLAGS_RV) -Isrc/lib/ $< -o $@

#############################################################
# SD Card Library
#############################################################
build/lib/mmc.o : src/lib/sdcard/mmc.c
	@echo building $@ from $<
	$(CC) $(CFLAGS_RV) $< -o $@

#############################################################
# FatFs Library
#############################################################
build/lib/ff.o : src/lib/fatfs/ff.c
	@echo building $@ from $<
	$(CC) $(CFLAGS_RV) $< -o $@

#############################################################
# Generic Build Rules
#############################################################
build/%.o : src/%.c
	@echo building $@ from $<
	$(CC) $(CFLAGS_RV)  $< -o $@

build/%.o : src/%.s
	@echo building $@ from $<
	$(CC) $(CFLAGS_RV)  $< -o $@

#############################################################
# Clean
#############################################################
clean_all: clean clean_libs clean_boot

clean:
	rm -rf build/*.*
	rm -rf hex/*.*

clean_libs:
	rm -rf build/lib/*

clean_boot:
	rm -rf build/boot/*
#############################################################