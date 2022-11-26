CC=clang
LD=ld
COPTS=-O0 -ffreestanding
LDOPTS=-e _kernel_main -segaddr __TEXT 0xC000 -pagezero_size 0 -S -static -no_function_starts

kmain.kernel: kmain.o
	$(LD) $(LDOPTS) -o $@ $^

kmain.o: kmain.c
	$(CC) -o $@ -c kmain.c $(COPTS)

.PHONY : clean
clean:
	-rm kmain.o kmain.kernel
