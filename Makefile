CC=clang
LD=ld
COPTS=-O0 -ffreestanding
LDOPTS=-e _kernel_main -segaddr __TEXT 0xC000 -pagezero_size 0 -S -static -no_function_starts

kmain.kernel: kmain.o
	$(LD) $(LDOPTS) -o $@ $^

kmain.o: kmain.c
	$(CC) -o $@ -c kmain.c $(COPTS)

.PHONY : clean bootsector

bootsector: boot.mach-o boot.bin

boot.mach-o: boot.asm
	nasm $^ -o boot.mach-o -f macho32 -g -DORGSTATEMENT=

boot.bin: boot.asm
	nasm $^ -o boot.bin -f bin -g -DORGSTATEMENT='org 0x7c00'

diskimage: boot.bin kmain.kernel
	cat $^ > diskimage

clean:
	-rm kmain.o kmain.kernel boot.bin boot.mach-o
