
# Basic Automatic Variables
#
# $@	Filename of the Target (that caused the recipe to be run)
# $<	Name of the first prerequisite
# $?	Names of all prerequisites newer than the target
# $^	Names of all prerequisites


# we should really pass the std lib (libgcc.a) to the linker as a libray
# we need
objects = \
build/main.o \
build/crt0.o \
build/uart.o \
build/utils.o \
build/ssd1306_i2c.o \
build/terminal.o \
build/text_display.o \
build/spi.o \
build/console.o

lib_objects = \
build/lib/printf.o

LIB_INCLUDES = -Isrc/lib/printf/src
# for configuring libraries
LIB_DEFINES = -DPRINTF_INCLUDE_CONFIG_H=1

boot_objects = \
build/minimal_boot.o

CC=riscv32-unknown-elf-gcc
LD=riscv32-unknown-elf-ld
OBJDUMP=riscv32-unknown-elf-objdump
ELF2HEX=riscv32-unknown-elf-elf2hex
NM=riscv32-unknown-elf-nm
ASCII_HEX_SWAP_ENDIAN=python3 endian_swap.py
ASCII_HEX_TO_BIN=xxd -r -p

COPT = -O0

# compile only
CFLAGS= -g -c $(COPT) $(LIB_INCLUDES) $(LIB_DEFINES)

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
LDFLAGS_RV = $(LDFLAGS) -lgcc -lg_nano -lnosys --gc-sections  -T riscv32-fpca.ld

# as this is the first "recipe", executing "make" on its own will run this
all: clean_libs main boot asm # hosted
	@echo Made everything!

# For checking against ILAs etc
main : hex/main.hex

# alternative target to get the disassembly as well
asm : build/main.asm  main build/minimal_boot.asm


# always treat this file as "out-of-date", so we always display the asm to the terminal
.PHONY : build/main.asm

boot : hex/boot.hex

hex/boot.hex : build/minimal_boot.o
	@echo "Building boot.hex"
	$(ELF2HEX) --bit-width 32 --input $< --output $@
	$(ASCII_HEX_SWAP_ENDIAN) hex/boot.hex build/boot.hexr
	$(ASCII_HEX_TO_BIN) build/boot.hexr hex/boot.bin

build/minimal_boot.asm : build/minimal_boot.o

	riscv32-unknown-elf-objdump -d -S $< > $@
	@#@echo ""
	@#@echo "******************** START $@ *********************"
	@#@echo ""
	@#riscv32-unknown-elf-objdump -d -S $<
	@#@echo ""
	@#@echo "********************* END $@ **********************"
	@#@echo ""

build/minimal_boot.o : src/boot/minimal_boot.c src/boot/crt0-boot.s
	$(CC) -g -O0 -march=rv32i -mabi=ilp32 -ffreestanding -Wl,--gc-sections \
	-nostartfiles -nostdlib -nodefaultlibs -Wl,-T,riscv32-fpca-boot.ld $^ -o $@



# This regenerates the hex/main.hex file, building the other files as necessary
hex/main.hex : build/main.elf
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
	riscv32-unknown-elf-objdump -d -S $< > $@

# This step links all the object files together
build/main.elf : $(objects) $(lib_objects)
	@echo Linking...
	$(LD) -o $@ $^ $(LDFLAGS_RV)


hosted :
	$(CC_PC) -g src/hosted-test.c -o build/hosted-test
	./build/hosted-test

# Make specific libraries as required
build/lib/printf.o : src/lib/printf/src/printf/printf.c
	@echo building $@ from $<
	$(CC) $(CFLAGS_RV) -Isrc/lib/ $< -o $@

build/%.o : src/%.c
	@echo building $@ from $<
	$(CC) $(CFLAGS_RV)  $< -o $@

build/%.o : src/%.s
	@echo building $@ from $<
	$(CC) $(CFLAGS_RV)  $< -o $@

upload : hex/main.hex
	./upload.sh COM8

clean_all: clean clean_libs clean_boot

clean:
	rm -rf build/*.*
	rm -rf hex/*.*

clean_libs:
	rm -rf build/lib/*

clean_boot:
	rm -rf build/boot/*