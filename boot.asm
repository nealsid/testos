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

        mov bx, hello_string
        call write_via_interrupt

        mov byte [0x7c00 + 512], 0x00

        call read_second_sector

        call verify_second_sector_magic

        mov bx, boot_second_sector
        call write_via_interrupt

        cli
        lgdt [lgdt_param]
        smsw cx
        or cx, 1
        lmsw cx
        jmp 0x0008:protected_mode

write_via_interrupt:
        mov ah, 0xE
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
        mov al, 0x9             ; Sector count
        mov ch, 0               ; Cylinder
        mov cl, 2               ; Sector #
        mov dh, 0               ; Head
        mov dl, 0x80            ; Drive (C:)
        mov bx, ($$ + 512)      ; Store address (after end of boot sector)
        int 0x13
        jc read_error
        ret

read_error:
        mov bx,read_error_string
        call write_via_interrupt
        jmp done
magic_number_error:
        mov bx, sector_magic_incorrect
        call write_via_interrupt
        jmp done
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
        dw 0x00EF               ; seg limit 16-19 = 0xF, flags = 1110
                                ; granularity, default operation size
                                ; (32bit), and 64-bit code segment =
                                ; 1, base 24-31 = 0
third_entry:
        dw 0xFFFF               ; same as above, except the segment is
                                ; read/write, not execute/read (0x9200
                                ; in 2nd doubleword, not 0x9A00)
        dw 0x0000
        dw 0x9200
        dw 0x00EF
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

        int 0xFF
protected_mode_loop:
        jmp protected_mode_loop
        times 1016 - ($-$$) db 0

lidt_param:
        dw 0X7FF
        dd idt_start

second_sector_endmagic:
        db 0xAA
        db 0x55

third_sector:                   ;0x8000
%assign i 0
%rep 256
        inc dword [0xA000 + i * 4]
        iret
%assign i i + 1
%endrep
align 8
idt_start:
%assign i 0
%rep 256
        dw 0x8000 + i*7         ; lower 16 of handler address in segment.
        dw 0x0008               ; segment selector
        dw 0x8E00               ; bits 0-8 = 0/reserved, bits 9-11 = 1
                                ; to indicate interrupt gate as well
                                ; as 32 bits (bit 11), bits 15-12 are
                                ; 1000 to indicate present, privilege
                                ; level 00, and specified to be 0.
        dw 0x0000               ; upper 16 of handler address offset in segmen.
%assign i i + 1
%endrep
