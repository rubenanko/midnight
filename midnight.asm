BITS 64
ORG 0x400000

; ELF Header minimal
ehdr:
    db 0x7F, "ELF"          ; Magic
    db 2, 1, 1, 0           ; 64-bit, little-endian, version, padding
    times 8 db 0
    dw 2                     ; e_type: ET_EXEC
    dw 0x3E                  ; e_machine: x86-64
    dd 1                     ; e_version
    dq _start                ; e_entry
    dq phdr - ehdr           ; e_phoff
    dq 0                     ; e_shoff (no sections)
    dd 0                     ; e_flags
    dw ehdr_size             ; e_ehsize
    dw phdr_size             ; e_phentsize
    dw 1                     ; e_phnum
    dw 0                     ; e_shentsize
    dw 0                     ; e_shnum
    dw 0                     ; e_shstrndx
ehdr_size equ $ - ehdr

; Program Header
phdr:
    dd 1                     ; p_type: PT_LOAD
    dd 5                     ; p_flags: PF_R | PF_X
    dq 0                     ; p_offset
    dq $$                    ; p_vaddr
    dq $$                    ; p_paddr
    dq filesize              ; p_filesz
    dq filesize              ; p_memsz
    dq 0x1000                ; p_align
phdr_size equ $ - phdr

_start:
    ;; print ok
    push 1
    pop rax
    mov rdi,rax
    mov rdx,rdi
    add rdx,2
    push 0x000a4b4f
    push rsp
    pop rsi
    syscall
    
    ;; exit 0
    xor rdi,rdi
    mov rax,0x3c
    syscall

filesize equ $ - $$