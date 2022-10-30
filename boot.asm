; boot.asm
org 0x7c00
begin:
        mov bx, hello_string
        call write_via_interrupt

        mov byte [0x7c00 + 512], 0x00

        call read_second_sector

        call verify_second_sector_magic

        mov bx, boot_second_sector
        call write_via_interrupt
        jmp done

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
        ret

read_second_sector: 
        mov ah, 0x2             ; Read
        mov al, 1               ; Sector count
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
        db 'Hello', 0
read_error_string:
        db 'Read interrupt error', 0
sector_magic_incorrect:
        db 'Second sector magic number invalid', 0
        ;; Pad remainder of this section with null plus 2-byte boot
        ;; sector magic number
        times 510-($-$$) db 0

        db 0x55
        db 0xAA

second_sector_magic:
        db 0xAA
        db 0x55
boot_second_sector:
        db '2nd boot sector', 0

