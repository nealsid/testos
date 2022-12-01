CC:=clang
LD:=ld
COPTS:=-O0 -ffreestanding
KERNEL_BINARY_LOAD_ADDRESS:=C000
LDOPTS=-e _kernel_main -segaddr __TEXT $(KERNEL_BINARY_LOAD_ADDRESS) \
	-pagezero_size 0 -S -static -no_function_starts

kmain.kernel: kmain.o
	$(LD) $(LDOPTS) -o $@ $^

kmain.o: kmain.c
	$(CC) -o $@ -c kmain.c $(COPTS)

.PHONY : clean bootsector calculate_c_jump_target

bootsector: boot.mach-o boot.bin

boot.mach-o: boot.asm
	nasm $^ -o boot.mach-o -f macho32 -g -DORGSTATEMENT=

boot.bin: boot.asm
	nasm $^ -o boot.bin -f bin -g -DORGSTATEMENT='org 0x7c00'


diskimage: boot.bin kmain.kernel
	cat $^ > diskimage

# C Jump target is:
#	0x7C00 (boot sector load address)
#       + size of boot sector image
#       + offset of kernel_main() in text section of kmain.kernel
# Since a lot of the boot sector image is empty space for
# padding, I'm hardcoding it rather than calculating it on
# demand, as that would require assembling it twice, once to
# get the size, and again to reassemble it with the jump
# target calculated.
calculate_c_jump_target: kmain.kernel
	BOOT_SECTOR_SIZE=1BF8
#       I love that bc interprets the obase parameter in the base specified in ibase...
	echo $(shell echo "ibase=16;obase=10;`nm $^ | grep _kernel_main | tr '[:lower:]' '[:upper:]' | cut -f 1 -d ' '` - $(KERNEL_BINARY_LOAD_ADDRESS)" | bc) > /tmp/kernel-entry-offset
	C_JUMP_TARGET=$(shell echo "ibase=16;obase=10;7C00 + 1BF8 + `cat /tmp/kernel-entry-offset`" | bc)

clean:
	-rm kmain.o kmain.kernel boot.bin boot.mach-o
