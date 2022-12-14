CC:=/usr/local/Cellar/gcc/12.2.0/bin/gcc-12
LD:=/usr/local/Cellar/x86_64-elf-binutils/2.39/x86_64-elf/bin/ld
COPTS:=-O0 -ffreestanding -m32 -fno-stack-protector
KERNEL_BINARY_TEXT_SEGMENT_ADDRESS:=C000
LDOPTS=-e _kernel_main 

BOOT_SECTOR_SIZE=1BF8

kmain.kernel: kmain.o logger.o
	$(LD) $(LDOPTS) -o $@ $^

kmain.o: kmain.c
	$(CC) -g -o $@ -c kmain.c $(COPTS)

logger.o: logger.c
	$(CC) -g -o $@ -c logger.c $(COPTS)

.PHONY : clean bootsector

bootsector: boot.mach-o boot.bin

boot.mach-o: boot.asm
	nasm $^ -o boot.mach-o -f macho32 -g -DORGSTATEMENT= -DKERNEL_C_JUMP_TARGET=0x$(shell ./calculate-c-jump-target.sh kmain.kernel $(KERNEL_BINARY_TEXT_SEGMENT_ADDRESS))

boot.bin: boot.asm kmain.kernel
	nasm boot.asm -o boot.bin -f bin -g -DORGSTATEMENT='org 0x7c00' -DKERNEL_C_JUMP_TARGET=0x$(shell ./calculate-c-jump-target.sh kmain.kernel $(KERNEL_BINARY_TEXT_SEGMENT_ADDRESS))

diskimage: boot.bin kmain.kernel
	cat $^ > diskimage

clean:
	-rm kmain.kernel boot.bin boot.mach-o *.o
