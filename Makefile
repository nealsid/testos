CC=clang
LD=ld
COPTS=-O0 -ffreestanding
LDOPTS=-e _kernel_main -segaddr _TEXT 0XC000 -pagezero_size 0 -S -static

kmain.o: kmain.c
	$(CC) -o $@ -c kmain.c $(COPTS)

kmain.kernel: kmain.o
	$(LD) $(LDOPTS) -o $@ $^
