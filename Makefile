CC:=clang
LD:=ld
COPTS:=-O0 -ffreestanding
KERNEL_BINARY_TEXT_SEGMENT_ADDRESS:=C000
LDOPTS=-e _kernel_main -segaddr __TEXT $(KERNEL_BINARY_TEXT_SEGMENT_ADDRESS) \
	-pagezero_size 0 -S -static -no_function_starts
BOOT_SECTOR_SIZE=1BF8

kmain.kernel: kmain.o
	$(LD) $(LDOPTS) -o $@ $^

kmain.o: kmain.c
	$(CC) -o $@ -c kmain.c $(COPTS)

.PHONY : clean bootsector calculate_c_jump_target

bootsector: boot.mach-o boot.bin

boot.mach-o: boot.asm
	nasm $^ -o boot.mach-o -f macho32 -g -DORGSTATEMENT=

boot.bin: boot.asm kmain.kernel
	echo $(C_JUMP_TARGET)
	nasm boot.asm -o boot.bin -f bin -g -DORGSTATEMENT='org 0x7c00' -DKERNEL_C_JUMP_TARGET=0x$(shell ./calculate-c-jump-target.sh kmain.kernel $(KERNEL_BINARY_TEXT_SEGMENT_ADDRESS))

diskimage: boot.bin kmain.kernel
	cat $^ > diskimage


clean:
	-rm kmain.o kmain.kernel boot.bin boot.mach-o
