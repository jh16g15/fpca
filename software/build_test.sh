
LINKER_SCRIPT="riscv32-fpca.ld"

GCC_OPT="-O0"
# from https://twilco.github.io/riscv-from-scratch/2019/04/27/riscv-from-scratch-2.html
GCC_ARGS="-g -march=rv32i -mabi=ilp32 -ffreestanding -Wl,--gc-sections -nostartfiles -nostdlib -nodefaultlibs"      # no other libraries
# GCC_ARGS="-g -march=rv32i -mabi=ilp32 -ffreestanding -Wl,--gc-sections -nostartfiles "    # allow stdlib and defaultlibs (for soft mult/div etc)
LD_ARGS="-Wl,-T,$LINKER_SCRIPT"


GCC_INPUT="src/crt0.s src/blinky.c"
GCC_OUTPUT="build/blinky.elf"

HEX_OUTPUT="build/blinky.hex"

echo "Cleaning build/"
rm -rf build/*

echo "Building Test Software..."
riscv32-unknown-elf-gcc $GCC_OPT $GCC_ARGS $LD_ARGS $GCC_INPUT -o $GCC_OUTPUT
riscv32-unknown-elf-objdump -d -S $GCC_OUTPUT

echo "Creating HEX file..."
## NOTE: we need to use the SiFive elf2hex (https://github.com/sifive/elf2hex),
#        not the elf2hex packaged witth Spike
riscv32-unknown-elf-elf2hex --bit-width 32 --input $GCC_OUTPUT --output $HEX_OUTPUT


