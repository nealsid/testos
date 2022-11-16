#!/bin/bash
nasm ./boot.asm -o boot.mach-o -f macho32 -g -DORGSTATEMENT=
nasm ./boot.asm -o boot.bin -f bin -g -DORGSTATEMENT='org 0x7c00'
