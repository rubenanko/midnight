global _start

;; programme de test de la construction dynamique du code via le script python
;; nasm -f elf64 test_obfuscated.s -o test_obfuscated.o
;; ld -z execstack -o test_obfuscated test_obfuscated.o

section .text
_start:
    mov cl,0x61 ;; initialisation

    sub cl,0x5c ;; construction du code dans la stack
    add rax,rcx
    shl rax,8
    add cl,0xa
    add rax,rcx
    shl rax,8
    sub cl,0xf
    add rax,rcx
    shl rax,8
    add cl,0x0
    add rax,rcx
    shl rax,8
    add cl,0x0
    add rax,rcx
    shl rax,8
    add cl,0x3c
    add rax,rcx
    shl rax,8
    add cl,0x7c
    add rax,rcx
    shl rax,8
    add cl,0x47
    add rax,rcx
    push rax
    xor rax,rax
    sub cl,0xce
    add rax,rcx
    shl rax,8
    add cl,0x17
    add rax,rcx
    shl rax,8
    sub cl,0x43
    add rax,rcx
    shl rax,8
    add cl,0xa
    add rax,rcx
    shl rax,8
    add cl,0x4f
    add rax,rcx
    shl rax,8
    sub cl,0xa
    add rax,rcx
    shl rax,8
    sub cl,0x54
    add rax,rcx
    shl rax,8
    add cl,0xa
    add rax,rcx
    push rax
    xor rax,rax
    add cl,0x41
    add rax,rcx
    shl rax,8
    add cl,0x4
    add rax,rcx
    shl rax,8
    add cl,0x19
    add rax,rcx
    shl rax,8
    sub cl,0x66
    add rax,rcx
    shl rax,8
    add cl,0xc0
    add rax,rcx
    shl rax,8
    sub cl,0x3f
    add rax,rcx
    shl rax,8
    sub cl,0x3b
    add rax,rcx
    shl rax,8
    add cl,0xb2
    add rax,rcx
    push rax
    xor rax,rax
    sub cl,0x71
    add rax,rcx
    shl rax,8
    sub cl,0x41
    add rax,rcx
    shl rax,8
    add cl,0x7f
    add rax,rcx
    shl rax,8
    sub cl,0x3e
    add rax,rcx
    shl rax,8
    sub cl,0x41
    add rax,rcx
    shl rax,8
    add cl,0x10
    add rax,rcx
    shl rax,8
    sub cl,0x57
    add rax,rcx
    shl rax,8
    add cl,0x69
    add rax,rcx
    push rax
    xor rax,rax

    call rsp ;; call final