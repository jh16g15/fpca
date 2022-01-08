
# Basic Automatic Variables
#
# $@	Filename of the Target (that caused the recipe to be run)
# $<	Name of the first prerequisite
# $?	Names of all prerequisites newer than the target
# $^	Names of all prerequisites


# we should really pass the std lib (libgcc.a) to the linker as a libray
objects = \
	build/main.o \
	build/crt0.o \
	build/uart.o \
	build/utils.o \
	# ~/riscv32/lib/gcc/riscv32-unknown-elf/11.1.0/libgcc.a



CC=riscv32-unknown-elf-gcc
LD=riscv32-unknown-elf-ld
OBJDUMP=riscv32-unknown-elf-objdump
ELF2HEX=riscv32-unknown-elf-elf2hex

COPT = -O0

# compile only
CFLAGS= -g -c $(COPT)

CFLAGS_RV = $(CFLAGS) -march=rv32i -mabi=ilp32 -ffreestanding

# CC_PC=gcc
# CFLAGS_PC= $(CFLAGS)

LDFLAGS =
# LDFLAGS_RV = $(LDFLAGS) --gc-sections -nostartfiles -T riscv32-fpca.ld
# we don't need -nostartfiles as a standalone linker invocation requires it to be provided explicitly
# we also need the stdlib and defaultlibs to allow for soft-mult etc
LDFLAGS_RV = $(LDFLAGS) --gc-sections  -T riscv32-fpca.ld

# as this is the first "recipe", executing "make" on its own will run this
main : hex/main.hex

# alternative target to get the disassembly as well
asm : build/main.asm main

all: main asm # hosted
	@echo Made everything!

# always treat this file as "out-of-date", so we always display the asm to the terminal
.PHONY : build/main.asm

# This regenerates the hex/main.hex file, building the other files as necessary
hex/main.hex : build/main.elf
	@echo "Building main.hex"
	$(ELF2HEX) --bit-width 32 --input $< --output $@

build/main.asm : build/main.elf
	@echo Build the hex for good measure

	@# output to file and to terminal
	riscv32-unknown-elf-objdump -d -S $< > $@
	riscv32-unknown-elf-objdump -d -S $<

# This step links all the object files together
build/main.elf : $(objects)
	@echo Linking $^
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