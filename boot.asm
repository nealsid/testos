; boot.asm
bits 16

; macro meant to be specified on command line,
; e.g. -DORGSTATEMENT='org 0x7c00'. it is specified as empty
; for building a binary GDB can read for debugging
ORGSTATEMENT

begin:
        mov ax, 0
        mov ss, AX
        mov sp, 0x7C00

        push hello_string
        call write_via_interrupt

        mov byte [0x7c00 + 512], 0x00

        call read_second_sector

        call verify_second_sector_magic

        push boot_second_sector
        call write_via_interrupt

        call generate_physical_memory_map
        cli
        lgdt [lgdt_param]
        smsw cx
        or cx, 1
        lmsw cx
        jmp 0x0008:protected_mode

write_via_interrupt:
        mov ah, 0xE
        mov word bx, [esp + 2]
        ;; index
print_start:
        cmp byte [bx], 0
        je print_done
        mov byte al, [bx]
        int 0x10
        inc bx
        jmp print_start
print_done:
        ret

verify_second_sector_magic:
        cmp word [0x7c00 + 512], 0x55AA
        jnz magic_number_error
        cmp word [0x7c00 + 1022], 0x55AA
        jnz magic_number_error
        ret

read_second_sector:
        mov ah, 0x2             ; Read
        mov al, 0x16            ; Sector count
        mov ch, 0               ; Cylinder
        mov cl, 2               ; Sector #
        mov dh, 0               ; Head
        mov dl, 0x80            ; Drive (C:)
        mov bx, ($$ + 512)      ; Store address (after end of boot sector)
        int 0x13
        jc read_error
        ret

read_error:
        push read_error_string
        call write_via_interrupt
        jmp done

magic_number_error:
        push sector_magic_incorrect
        call write_via_interrupt
        jmp done

generate_physical_memory_map:
        mov edi, 0x5000
        mov ebx, 0
        mov dword [0x6000], 1

generate_physical_memory_map_start:
        mov eax, 0x0000E820
        mov ecx, 24
        mov edx, 0x534D4150

        clc
        int 0x15
        jc generate_physical_memory_map_done
        cmp ebx, 0
        jz generate_physical_memory_map_done
        cmp eax, 0x534D4150
        jnz generate_physical_memory_map_done_error
        inc dword [0x6000]
        add edi, ecx
        jmp generate_physical_memory_map_start
generate_physical_memory_map_done_error:
        ret
generate_physical_memory_map_done:
        ret

done:
        jmp done

hello_string:
        db 'Hello', 0xa, 0xd, 0

read_error_string:
        db 'Read interrupt error', 0xa, 0xd, 0

sector_magic_incorrect:
        db 'Second sector magic number invalid', 0xa, 0xd, 0

        ;; Pad remainder of this section with noop plus 2-byte boot
        ;; sector magic number
        times 510-($-$$) db 0x90

        db 0x55
        db 0xAA

;;; Sector after boot sector.
second_sector_magic:
        db 0xAA
        db 0x55
boot_second_sector:
        db '2nd boot sector', 0xa, 0xd, 0
        ;; 0x7e14
lgdt_param:
        db 0x17, 0x00
        dd gdt

align 8
gdt:
first_entry:
        dw 0x0000, 0x0000       ;First entry is unused
        dw 0x0000, 0x0000
second_entry:
        dw 0xFFFF               ; segment limit 0-15
        dw 0x0000               ; segment base 0-15
        dw 0x9A00               ; base 16-23, followed by type == 1010 (execute/read),and
                                ; flags = 9 = 1001 for present = 1,dpl=00,code/data = 1
        dw 0x00CF               ; seg limit 16-19 = 0xF, flags = 1110
                                ; granularity, default operation size
                                ; (32bit), and 64-bit code segment =
                                ; 1, base 24-31 = 0
third_entry:
        dw 0xFFFF               ; same as above, except the segment is
                                ; read/write, not execute/read (0x9200
                                ; in 2nd doubleword, not 0x9A00)
        dw 0x0000
        dw 0x9200
        dw 0x00CF
gdt_end:

        bits 32
protected_mode:
        mov ax, 0x10
        mov ds, ax
        mov ss, ax
        mov ax, 0x0
        mov es, ax
        mov fs, ax
        mov gs, ax
        lidt [lidt_param]
        sti

protected_mode_loop:
        push 0x5000         ; address of physical memory map
        mov byte [0xb8000], '5'
        jmp 0xA748              ; figure out some way to not hardcode this

        times 1016 - ($-$$) db 0

lidt_param:
        dw 0X7FF
        dd idt_start

second_sector_endmagic:
        db 0xAA
        db 0x55

third_sector:                   ;0x8000
%macro interrupt_handler 1
ihlabel%[%1]:
        inc dword [0x1A000 + %1 * 4]
%if %1 = 8 || %1 = 10 || %1 = 11 || %1 = 12 || %1 = 13 || %1 = 14 || %1 = 17 || %1 = 21
%if %1 = 8
        ; Interrupt 8 (timer) might be signalled spuriously by the
        ; BIOS after re-enabling interrupts in protected mode, so test
        ; for this case by seeing if 0 has been pushed on the stack,
        ; which is the error code for the doublefault interrupt 8.
        cmp dword [esp],0
        jnz %%endinterrupt
%endif
        add esp, 0x4        ; move stack pointer for interrupt
                            ; handlers that have an exception code
                            ; pushed onto the stack
%%endinterrupt:
%endif
        iretd
%endmacro

%assign i 0
%rep 256
align 16
interrupt_handler %[i]
%assign i i + 1
%endrep

align 8

idt_start:
%assign i 0
%rep 256
        dw 0x8000 + 16 * i      ; lower 16 of handler address in segment.
        dw 0x0008               ; segment selector
        dw 0x8E00               ; bits 0-8 = 0/reserved, bits 9-11 = 1
                                ; to indicate interrupt gate as well
                                ; as 32 bits (bit 11), bits 15-12 are
                                ; 1000 to indicate present, privilege
                                ; level 00, and specified to be 0.
        dw 0x0000               ; upper 16 of handler address offset in segment.
%assign i i + 1
%endrep
