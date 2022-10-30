Just working through some OS bootup code.

``
$ nasm ./boot.asm -o boot.bin -f bin && /usr/local/bin/qemu-system-x86_64 -singlestep boot.bin  -nographic
``
