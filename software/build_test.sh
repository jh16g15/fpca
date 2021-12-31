
LINKER_SCRIPT="test.ld"

# -c for compile-only, no linkng
GCC_ARGS="-g -O0 -march=rv32i -mabi=ilp32 -nostartfiles -nostdlib -nodefaultlibs -c"


GCC_INPUT="src/blinky.c"
GCC_OUTPUT="build/blinky.elf"

HEX_OUTPUT="build/blinky.hex"

echo "Cleaning build/"
rm -rf build/*

echo "Building Test Software..."
riscv32-unknown-elf-gcc $GCC_ARGS $GCC_INPUT -o $GCC_OUTPUT
riscv32-unknown-elf-objdump -d -S $GCC_OUTPUT

echo "Creating HEX file..."
## NOTE: we need to use the SiFive elf2hex (https://github.com/sifive/elf2hex), 
#        not the elf2hex packaged witth Spike
riscv32-unknown-elf-elf2hex --bit-width 32 --input $GCC_OUTPUT --output $HEX_OUTPUT


