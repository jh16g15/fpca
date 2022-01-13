.section .init, "ax"            # Place in "init" section that is allocatable and executable
.global _start                  # make _start visible to the linker
_start:                         # start the _start definition
    .cfi_startproc              # start function
    .cfi_undefined ra           # don't restore ra to previous value (before _start was called)
    .option push                # when loading the global pointer, ensure it is always loaded with AUIPC, ADDI rather than being optimised
    .option norelax
    # la gp, __global_pointer$    # load global pointer from __global_pointer   ## GLOBAL POINTER NOT USED
    .option pop
    la sp, __stack_top          # set up our stack pointer
    add s0, sp, zero            # init s0/frame pointer to stack pointer
    jal zero, main              # jump to main (no ra)
    .cfi_endproc                # end function
    .end                        # end the assembly file
