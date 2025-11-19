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
    dw 2                     ; e_phnum
    dw 0                     ; e_shentsize
    dw 0                     ; e_shnum <------------- à modifier notammment pour corrompre le header
    dw 0                     ; e_shstrndx
ehdr_size equ $ - ehdr

; Program Header
phdr:
    dd 1                     ; p_type: PT_LOAD
    dd 5                     ; p_flags: PF_R | PF_X ;; exécution de la stack
    dq 0                     ; p_offset
    dq $$                    ; p_vaddr
    dq $$                    ; p_paddr
    dq filesize              ; p_filesz
    dq filesize              ; p_memsz
    dq 0x1000                ; p_align
phdr_size equ $ - phdr

; Program Header 2 pour exécution de la stack
phdr2:
    dd 0x6474e551            ; p_type = PT_GNU_STACK 
    dd 7                     ; p_flags = PF_R | PF_W | PF_X  
    dq 0                     ; p_offset = 0
    dq 0                     ; p_vaddr = 0
    dq 0                     ; p_paddr = 0
    dq 0                     ; p_filesz = 0
    dq 0                     ; p_memsz = 0
    dq 8                     ; p_align = 8 (pas important)
phdr2_size equ $ - phdr2

;; point d'entrée
_start:
    pop rdi ;; le nombre d'arguments
    pop rdi ;; le premier argument : l'exécutable
    pop rdi ;; le second argument : la chaine en entrée
    call get_length ;; fausse condition de taille pour embrouiller les camarades
    db 0x62
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
    dw 0x54
    dq 0x8461338410134865 ;; instruction overlapping
    dq 0x6235411016105610 ;; instruction overlapping
.length_end:
    cmp dl,9
    jge .fake_check_cesar1
    jl .fake_check_cesar2
    mov r11, rip
    db 0x33 ;; mot de passe
    dq 0x6235411016105610 ;; instruction overlapping
    dq 0x8461338410134865 ;; instruction overlapping

.fake_check_cesar1: ;; fausse comparaison avec un chiffré de césar, avec génération d'un hash dans r9
    test cl,cl
    je .tmp1
    jmp .tmp2
    db 0x62
    dq 0x8511535110134865 ;; instruction overlapping   
.tmp2:
    xor cl,cl
    jmp .tmp1
    db 0x12
    dq 0x6235411016105610 ;; instruction overlapping
    dq 0x8461338410134865 ;; instruction overlapping   
.tmp1:
    mov r8,0x6E7169716F757165   ;; "kosmogol" + 2
.loop_fake_check_cesar1:
    cmp cl,8
    je .pre_fake_check_cesar2
    sub r8b,2
    cmp BYTE [rdi+rcx],r8b

    lea rdx,rbp-0x100 ;; future adresse du code dans la stack, subtilement stockée

    jne .continue ;; sortie dans le cas du mdp
    shr r8,8
    mov r10b,BYTE [rdi+rcx]
    imul r10,r10,2
    add r9,r10
    imul r9,r9,42
    inc cl

    jmp .loop_fake_check_cesar1

    dw 0x5212
    dq 0x6235411016105610 ;; instruction overlapping
    dq 0x8461338410134865 ;; instruction overlapping
    dq 0x6235411016105610 ;; instruction overlapping
    dq 0x8461338410134865 ;; instruction overlapping   


.pre_fake_check_cesar2:
    add rdi,8
    jmp .fake_check_cesar2
    db 0x12
    dq 0x6235411016105610 ;; instruction overlapping
    dq 0x8461338410134865 ;; instruction overlapping
    dq 0x6235411016105610 ;; instruction overlapping
    dq 0x8461338410134865 ;; instruction overlapping  

.fake_check_cesar2: ;; si le mdp commence par kosmogol, on passe dans le deuxième faux check 
    test cl,cl ;; qui multiplie nième octet du hash avec le nième octet de r8
    je .tmp3 ;;  et prends le premier octet de la multiplication pour le comparer avec le nième de rdi+8, 
    jmp .tmp4 ;; l'égalité est vérifiée si rdi+8 = shadok
    db 0x62
    dq 0x8511535110134865 ;; instruction overlapping

.tmp4:
    xor cl,cl
    jmp .tmp3
    db 0x12
    dq 0x6235411016105610 ;; instruction overlapping
    dq 0x8461338410134865 ;; instruction overlapping

.tmp3:
    mov r8,0x6E716c10a85cdbfb ;; r9 = 0x6ff5fbc058d78

.loop_fake_check_cesar2:
    cmp BYTE [rdi+rcx],0
    je .pre_exit_with_error

    mov r10b,r8b
    mov r11b,r9b

    add r10,r11
    mov dl,r10b
    cmp dl,byte[rdi+rcx]

    jne .continue
    shr r8,8
    shr r9,8
    inc cl
    jmp .loop_fake_check_cesar2

    db 0x12
    dq 0x6235411016105610 ;; instruction overlapping
    dq 0x8461338410134865 ;; instruction overlapping
    dq 0x6235411016105610 ;; instruction overlapping
    dq 0x8461338410134865 ;; instruction overlapping   

.pre_exit_with_error:
    mov rax,r9
    add rax,0x36
    jmp .exit_with_error

.continue:
    ;; preparation des registres

    ;; generation du code dans la stack

    call rdx


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
    push 0
    pop rdi
    mov rax,0x3c
    syscall

.exit_with_error:
    ;; exit 1
    push 1
    pop rdi
    syscall

filesize equ $ - $$