#!/bin/bash
nasm ./boot.asm  -f macho32 -g -DORGSTATEMENT= -E
