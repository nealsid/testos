#!/bin/bash

# Calculcates the address to jump to in the compiled C kernel binary.
# $1 is the kernel binary
# $2 is the load address of the kernel code segment from the binary.
#
# grep for the line with kernel_main, translate it to upper case for BC, and select the first column
KERNEL_MAIN_ADDRESS=`nm $1 | grep _kernel_main | tr '[:lower:]' '[:upper:]' | cut -f 1 -d ' '`
KERNEL_BINARY_LOAD_ADDRESS=$2

# C Jump target is:
#	0x7C00 (boot sector load address)
#       + size of boot sector image
#       + offset of kernel_main() in text section of kmain.kernel
# Since a lot of the boot sector image is empty space for
# padding, I'm hardcoding it rather than calculating it on
# demand, as that would require assembling it twice, once to
# get the size, and again to reassemble it with the jump
# target calculated.
# I love that bc interprets the obase parameter in the base specified in ibase...

bc -e "ibase=16;obase=10;7C00 + 1BF8 + $KERNEL_MAIN_ADDRESS - $KERNEL_BINARY_LOAD_ADDRESS"
