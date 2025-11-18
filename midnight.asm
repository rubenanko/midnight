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
    dw 0                     ; e_shnum <------------- à modifier notammment pour corrompre le header
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

;; point d'entrée
_start:
    pop rdi ;; le nombre d'arguments
    pop rdi ;; le premier argument : l'exécutable
    pop rdi ;; le second argument : la chaine en entrée
    call get_length ;; fausse condition de taille pour embrouiller les camarades
    dq 0x5403565545125344 ;; instruction overlapping
    dq 0x3104840387452923 ;; instruction overlapping
    dq 0x1320444702638491 ;; instruction overlapping
    dq 0x4380109662308712 ;; instruction overlapping
    dq 0x1684063102329871 ;; instruction overlapping

;; capture la taille de la chaine dans rdi (entrée utilisateur)
get_length:
.length_loop:
    cmp BYTE [rdi+rdx],0x00
    je .length_end ;; get_length prends la suite de _start et déroule la suite du programme.
    inc dl
    jmp .length_loop
    dq 0x8461338410134865 ;; instruction overlapping
    dq 0x6235411016105610 ;; instruction overlapping
.length_end:
    cmp dl,9

    ;; cette portion est à réutiliser dans la partie critique en stack
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