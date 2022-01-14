
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
build/bootloader.o \

boot_objects = \
build/minimal_boot.o

CC=riscv32-unknown-elf-gcc
LD=riscv32-unknown-elf-ld
OBJDUMP=riscv32-unknown-elf-objdump
ELF2HEX=riscv32-unknown-elf-elf2hex
NM=riscv32-unknown-elf-nm
ASCII_HEX_TO_BIN=xxd -r -p

COPT = -O0

# compile only
CFLAGS= -g -c $(COPT)

# Change the RV extensions here:
CFLAGS_RV = $(CFLAGS) -march=rv32i -mabi=ilp32 -ffreestanding

# CC_PC=gcc
# CFLAGS_PC= $(CFLAGS)

LDFLAGS = -Map=build/output.map
# LDFLAGS_RV = $(LDFLAGS) --gc-sections -nostartfiles -T riscv32-fpca.ld
# we don't need -nostartfiles as a standalone linker invocation requires it to be provided explicitly
# we need libgcc.a (-lgcc) for soft mult/div, as we aren't using RV32IM
LDFLAGS_RV = $(LDFLAGS) -lgcc --gc-sections  -T riscv32-fpca.ld

# as this is the first "recipe", executing "make" on its own will run this
main : hex/main.hex

# alternative target to get the disassembly as well
asm : build/main.asm main build/minimal_boot.asm

all: main boot asm # hosted
	@echo Made everything!

# always treat this file as "out-of-date", so we always display the asm to the terminal
.PHONY : build/main.asm

boot : hex/boot.hex

hex/boot.hex : build/minimal_boot.o
	@echo "Building boot.hex"
	$(ELF2HEX) --bit-width 32 --input $< --output $@
	$(ASCII_HEX_TO_BIN) $@ hex/boot.bin

build/minimal_boot.asm : build/minimal_boot.o

	@echo ""
	@echo "******************** START $@ *********************"
	@echo ""
	riscv32-unknown-elf-objdump -d -S $<
	riscv32-unknown-elf-objdump -d -S $< > $@
	@echo ""
	@echo "********************* END $@ **********************"
	@echo ""

build/minimal_boot.o : src/boot/minimal_boot.c src/boot/crt0-boot.s
	$(CC) -g -Os -march=rv32i -mabi=ilp32 -ffreestanding -Wl,--gc-sections \
	-nostartfiles -nostdlib -nodefaultlibs -Wl,-T,riscv32-fpca-boot.ld $^ -o $@



# This regenerates the hex/main.hex file, building the other files as necessary
hex/main.hex : build/main.elf
	@echo "Building main.hex"
	$(ELF2HEX) --bit-width 32 --input $< --output $@
	$(ASCII_HEX_TO_BIN) $@ hex/main.bin


build/main.asm : build/main.elf
	@# output to file and to terminal
	@echo ""
	@echo "******************** START $@ *********************"
	@echo ""
	riscv32-unknown-elf-objdump -d -S $< > $@
	@echo ""
	@echo "********************* END $@ **********************"
	@echo ""
	riscv32-unknown-elf-objdump -d -S $<

# This step links all the object files together
build/main.elf : $(objects)
	@echo Linking...
	$(LD) -o $@ $^ $(LDFLAGS_RV)


# hosted : hosted-build/hosted-test.o
# 	$(CC_PC) -g src/hosted-test.c -o build/hosted-test

# hosted-build/%.o : src/%.c
# 	@echo building $@ from $<
# 	$(CC_PC) $(CFLAGS_PC) $< -o $@

build/%.o : src/%.c
	@echo building $@ from $<
	$(CC) $(CFLAGS_RV)  $< -o $@

build/%.o : src/%.s
	@echo building $@ from $<
	$(CC) $(CFLAGS_RV)  $< -o $@


clean:
	rm -rf build/*.*
	rm -rf hex/*.*