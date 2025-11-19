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
    dq 1                     ; e_shoff (no sections) <------------- modifié pour corrompre le header
    dd 2                     ; e_flags <------------- modifié pour corrompre le header
    dw ehdr_size             ; e_ehsize
    dw phdr_size             ; e_phentsize
    dw 2                     ; e_phnum
    dw 0                     ; e_shentsize
    dw 2                     ; e_shnum <------------- modifié pour corrompre le header
    dw 1                     ; e_shstrndx <------------- modifié pour corrompre le header
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
    cmp dl,16 ;; vérification de la taille max
    jle .fake_condition
    mov rdi,1
    mov rax,0x3c
    syscall

.fake_condition:
    cmp dl,9
    mov r11, $ ;; sauvegarde de la position du mdp, qui est donc à r11+19
    jge .fake_check_cesar1
    jl .fake_check_cesar2
    db 0x33 
    dq 0xD4649694C6B6A466 ;; mot de passe partie 1
    dq 0x8AC8E6C86686A8DA ;; mot de passe partie 2
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

    mov rbx,rsp ;; future adresse du code + 262 dans la stack, subtilement stockée

    jne .pre_continue ;; sortie dans le cas du mdp
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

.pre_continue:
    ;; preparation des registres pour le stack call
    sub rbx,257
    mov cl,BYTE [rdi]
    jmp .continue

    db 0x84
    dq 0x6235411016105610 ;; instruction overlapping
    dq 0x8461316154434865 ;; instruction overlapping
    dq 0x6235411016105610 ;; instruction overlapping
    dq 0x8464888410134865 ;; instruction overlapping   

.continue:
    ;; preparation des arguments de la fonction dans le stack call
    mov rsi,QWORD [rdi]
    mov rdi,QWORD [rdi+8]

    ;; generation du code dans la stack
    ;; cypher encodé
    sub cl,0x67
    add al,cl
    shl rax,8
    add cl,0xa
    add al,cl
    shl rax,8
    sub cl,0xf
    add al,cl
    shl rax,8
    add cl,0x0
    add al,cl
    shl rax,8
    add cl,0x0
    add al,cl
    shl rax,8
    add cl,0x3c
    add al,cl
    shl rax,8
    add cl,0x7c
    add al,cl
    shl rax,8
    sub cl,0x59
    add al,cl
    push rax
    shl rax,8
    sub cl,0x5f
    add al,cl
    shl rax,8
    add cl,0x6a
    add al,cl
    shl rax,8
    sub cl,0x65
    add al,cl
    shl rax,8
    add cl,0xa
    add al,cl
    shl rax,8
    add cl,0x4f
    add al,cl
    shl rax,8
    sub cl,0xa
    add al,cl
    shl rax,8
    sub cl,0x54
    add al,cl
    shl rax,8
    add cl,0xa
    add al,cl
    push rax
    shl rax,8
    add cl,0x41
    add al,cl
    shl rax,8
    add cl,0x4
    add al,cl
    shl rax,8
    add cl,0x19
    add al,cl
    shl rax,8
    sub cl,0x66
    add al,cl
    shl rax,8
    add cl,0xc0
    add al,cl
    shl rax,8
    sub cl,0x3f
    add al,cl
    shl rax,8
    sub cl,0x3b
    add al,cl
    shl rax,8
    add cl,0xb2
    add al,cl
    push rax
    shl rax,8
    sub cl,0x71
    add al,cl
    shl rax,8
    sub cl,0x41
    add al,cl
    shl rax,8
    add cl,0x7f
    add al,cl
    shl rax,8
    sub cl,0x3e
    add al,cl
    shl rax,8
    sub cl,0x41
    add al,cl
    shl rax,8
    add cl,0x10
    add al,cl
    shl rax,8
    sub cl,0x57
    add al,cl
    shl rax,8
    add cl,0x69
    add al,cl
    push rax
    shl rax,8
    sub cl,0x65
    add al,cl
    shl rax,8
    add cl,0xa
    add al,cl
    shl rax,8
    sub cl,0xf
    add al,cl
    shl rax,8
    add cl,0x0
    add al,cl
    shl rax,8
    add cl,0x0
    add al,cl
    shl rax,8
    add cl,0x3c
    add al,cl
    shl rax,8
    add cl,0x7c
    add al,cl
    shl rax,8
    sub cl,0x59
    add al,cl
    push rax
    shl rax,8
    sub cl,0x5e
    add al,cl
    shl rax,8
    add cl,0x69
    add al,cl
    shl rax,8
    sub cl,0x6a
    add al,cl
    shl rax,8
    add cl,0x0
    add al,cl
    shl rax,8
    add cl,0x0
    add al,cl
    shl rax,8
    add cl,0x8
    add al,cl
    shl rax,8
    add cl,0xb1
    add al,cl
    shl rax,8
    add cl,0x26
    add al,cl
    push rax
    shl rax,8
    sub cl,0x56
    add al,cl
    shl rax,8
    sub cl,0x41
    add al,cl
    shl rax,8
    add cl,0x81
    add al,cl
    shl rax,8
    add cl,0x36
    add al,cl
    shl rax,8
    sub cl,0xb6
    add al,cl
    shl rax,8
    sub cl,0x34
    add al,cl
    shl rax,8
    add cl,0x5f
    add al,cl
    shl rax,8
    add cl,0x55
    add al,cl
    push rax
    shl rax,8
    sub cl,0x44
    add al,cl
    shl rax,8
    sub cl,0x38
    add al,cl
    shl rax,8
    sub cl,0x3d
    add al,cl
    shl rax,8
    add cl,0xdb
    add al,cl
    shl rax,8
    sub cl,0xcf
    add al,cl
    shl rax,8
    add cl,0x58
    add al,cl
    shl rax,8
    add cl,0x5e
    add al,cl
    shl rax,8
    sub cl,0x4e
    add al,cl
    push rax
    shl rax,8
    add cl,0x62
    add al,cl
    shl rax,8
    add cl,0x5
    add al,cl
    shl rax,8
    sub cl,0x25
    add al,cl
    shl rax,8
    add cl,0x39
    add al,cl
    shl rax,8
    sub cl,0xb7
    add al,cl
    shl rax,8
    add cl,0x7f
    add al,cl
    shl rax,8
    add cl,0x38
    add al,cl
    shl rax,8
    sub cl,0xb7
    add al,cl
    push rax
    shl rax,8
    sub cl,0x3a
    add al,cl
    shl rax,8
    add cl,0x66
    add al,cl
    shl rax,8
    add cl,0x55
    add al,cl
    shl rax,8
    sub cl,0x45
    add al,cl
    shl rax,8
    sub cl,0x78
    add al,cl
    shl rax,8
    add cl,0x68
    add al,cl
    shl rax,8
    add cl,0x4c
    add al,cl
    shl rax,8
    sub cl,0x3c
    add al,cl
    push rax
    shl rax,8
    sub cl,0x5e
    add al,cl
    shl rax,8
    add cl,0x4f
    add al,cl
    shl rax,8
    add cl,0x5b
    add al,cl
    shl rax,8
    sub cl,0x98
    add al,cl
    shl rax,8
    add cl,0x91
    add al,cl
    shl rax,8
    add cl,0x35
    add al,cl
    shl rax,8
    sub cl,0xe8
    add al,cl
    shl rax,8
    add cl,0x74
    add al,cl
    push rax
    shl rax,8
    sub cl,0x83
    add al,cl
    shl rax,8
    add cl,0x83
    add al,cl
    shl rax,8
    sub cl,0x8a
    add al,cl
    shl rax,8
    add cl,0x0
    add al,cl
    shl rax,8
    add cl,0x0
    add al,cl
    shl rax,8
    add cl,0xf
    add al,cl
    shl rax,8
    add cl,0xaa
    add al,cl
    shl rax,8
    add cl,0x10
    add al,cl
    push rax
    shl rax,8
    sub cl,0x98
    add al,cl
    shl rax,8
    add cl,0x1c
    add al,cl
    shl rax,8
    sub cl,0x3a
    add al,cl
    shl rax,8
    add cl,0x68
    add al,cl
    shl rax,8
    add cl,0x12
    add al,cl
    shl rax,8
    sub cl,0x44
    add al,cl
    shl rax,8
    add cl,0x9d
    add al,cl
    shl rax,8
    sub cl,0x5d
    add al,cl
    push rax
    shl rax,8
    sub cl,0x41
    add al,cl
    shl rax,8
    add cl,0xb
    add al,cl
    shl rax,8
    sub cl,0x1
    add al,cl
    shl rax,8
    add cl,0x41
    add al,cl
    shl rax,8
    add cl,0x58
    add al,cl
    shl rax,8
    sub cl,0x24
    add al,cl
    shl rax,8
    sub cl,0x52
    add al,cl
    shl rax,8
    add cl,0x53
    add al,cl
    push rax
    shl rax,8
    add cl,0x37
    add al,cl
    shl rax,8
    sub cl,0xb6
    add al,cl
    shl rax,8
    add cl,0x67
    add al,cl
    shl rax,8
    sub cl,0x3b
    add al,cl
    shl rax,8
    sub cl,0x74
    add al,cl
    shl rax,8
    add cl,0xa7
    add al,cl
    shl rax,8
    add cl,0x28
    add al,cl
    shl rax,8
    sub cl,0x9f
    add al,cl
    push rax
    shl rax,8
    add cl,0x1b
    add al,cl
    shl rax,8
    add cl,0x76
    add al,cl
    shl rax,8
    sub cl,0x99
    add al,cl
    shl rax,8
    add cl,0x20
    add al,cl
    shl rax,8
    add cl,0x79
    add al,cl
    shl rax,8
    sub cl,0x99
    add al,cl
    shl rax,8
    add cl,0x20
    add al,cl
    shl rax,8
    add cl,0x77
    add al,cl
    push rax
    shl rax,8
    sub cl,0xac
    add al,cl
    shl rax,8
    add cl,0x79
    add al,cl
    shl rax,8
    sub cl,0x41
    add al,cl
    shl rax,8
    add cl,0x74
    add al,cl
    shl rax,8
    sub cl,0x37
    add al,cl
    shl rax,8
    sub cl,0x3d
    add al,cl
    shl rax,8
    sub cl,0x44
    add al,cl
    shl rax,8
    add cl,0xe7
    add al,cl
    push rax
    shl rax,8
    sub cl,0x2e
    add al,cl
    shl rax,8
    sub cl,0x79
    add al,cl
    shl rax,8
    add cl,0x83
    add al,cl
    shl rax,8
    sub cl,0xc2
    add al,cl
    shl rax,8
    add cl,0x3f
    add al,cl
    shl rax,8
    add cl,0x81
    add al,cl
    shl rax,8
    sub cl,0x13
    add al,cl
    shl rax,8
    sub cl,0xa7
    add al,cl
    push rax
    shl rax,8
    add cl,0x39
    add al,cl
    shl rax,8
    sub cl,0x40
    add al,cl
    shl rax,8
    add cl,0xdb
    add al,cl
    shl rax,8
    sub cl,0x22
    add al,cl
    shl rax,8
    sub cl,0x79
    add al,cl
    shl rax,8
    add cl,0x79
    add al,cl
    shl rax,8
    sub cl,0xc0
    add al,cl
    shl rax,8
    add cl,0x47
    add al,cl
    push rax
    shl rax,8
    add cl,0xb7
    add al,cl
    shl rax,8
    add cl,0x0
    add al,cl
    shl rax,8
    add cl,0x0
    add al,cl
    shl rax,8
    sub cl,0x6c
    add al,cl
    shl rax,8
    sub cl,0x86
    add al,cl
    shl rax,8
    add cl,0x26
    add al,cl
    shl rax,8
    add cl,0x15
    add al,cl
    shl rax,8
    add cl,0x79
    add al,cl
    push rax
    shl rax,8
    sub cl,0x38
    add al,cl
    shl rax,8
    sub cl,0x41
    add al,cl
    shl rax,8
    add cl,0x7f
    add al,cl
    shl rax,8
    sub cl,0x11
    add al,cl
    shl rax,8
    sub cl,0xa7
    add al,cl
    shl rax,8
    add cl,0x39
    add al,cl
    shl rax,8
    add cl,0x86
    add al,cl
    shl rax,8
    add cl,0x1d
    add al,cl
    push rax
    shl rax,8
    sub cl,0xeb
    add al,cl
    shl rax,8
    add cl,0x0
    add al,cl
    shl rax,8
    add cl,0x0
    add al,cl
    shl rax,8
    add cl,0x1
    add al,cl
    shl rax,8
    add cl,0xb8
    add al,cl
    shl rax,8
    sub cl,0x78
    add al,cl
    shl rax,8
    add cl,0xb6
    add al,cl
    shl rax,8
    sub cl,0x6e
    add al,cl
    push rax
    shl rax,8
    sub cl,0x41
    add al,cl
    shl rax,8
    sub cl,0x48
    add al,cl
    shl rax,8
    add cl,0x0
    add al,cl
    shl rax,8
    add cl,0x0
    add al,cl
    shl rax,8
    add cl,0x8
    add al,cl
    shl rax,8
    add cl,0xb0
    add al,cl
    shl rax,8
    sub cl,0x77
    add al,cl
    shl rax,8
    add cl,0x9a
    add al,cl
    push rax
    shl rax,8
    sub cl,0xaa
    add al,cl
    shl rax,8
    add cl,0x17
    add al,cl
    shl rax,8
    add cl,0x92
    add al,cl
    shl rax,8
    sub cl,0x51
    add al,cl
    shl rax,8
    sub cl,0x41
    add al,cl
    shl rax,8
    add cl,0xa
    add al,cl
    shl rax,8
    add cl,0x23
    add al,cl
    shl rax,8
    add cl,0x54
    add al,cl
    push rax
    shl rax,8
    sub cl,0x44
    add al,cl
    shl rax,8
    sub cl,0x38
    add al,cl
    shl rax,8
    sub cl,0x31
    add al,cl
    shl rax,8
    add cl,0xcf
    add al,cl
    shl rax,8
    sub cl,0xeb
    add al,cl
    shl rax,8
    add cl,0x0
    add al,cl
    shl rax,8
    add cl,0x0
    add al,cl
    shl rax,8
    add cl,0x0
    add al,cl
    push rax
    shl rax,8
    add cl,0xbf
    add al,cl
    shl rax,8
    sub cl,0x7e
    add al,cl
    shl rax,8
    sub cl,0x1d
    add al,cl
    shl rax,8
    add cl,0xc7
    add al,cl
    shl rax,8
    sub cl,0xe1
    add al,cl
    shl rax,8
    add cl,0x6a
    add al,cl
    shl rax,8
    sub cl,0x74
    add al,cl
    shl rax,8
    add cl,0xf8
    add al,cl
    push rax
    shl rax,8
    sub cl,0x75
    add al,cl
    shl rax,8
    sub cl,0x3a
    add al,cl
    shl rax,8
    sub cl,0x41
    add al,cl
    shl rax,8
    add cl,0x6c
    add al,cl
    shl rax,8
    sub cl,0x6c
    add al,cl
    shl rax,8
    add cl,0xf0
    add al,cl
    shl rax,8
    sub cl,0x75
    add al,cl
    shl rax,8
    sub cl,0x3a
    add al,cl
    push rax
    shl rax,8
    sub cl,0x44
    add al,cl
    shl rax,8
    add cl,0xa
    add al,cl
    shl rax,8
    sub cl,0xf
    add al,cl
    shl rax,8
    add cl,0x0
    add al,cl
    shl rax,8
    add cl,0x0
    add al,cl
    shl rax,8
    add cl,0x1
    add al,cl
    shl rax,8
    add cl,0xbe
    add al,cl
    shl rax,8
    sub cl,0xbf
    add al,cl
    push rax
    shl rax,8
    add cl,0x0
    add al,cl
    shl rax,8
    add cl,0x0
    add al,cl
    shl rax,8
    add cl,0x3c
    add al,cl
    shl rax,8
    add cl,0x7c
    add al,cl
    shl rax,8
    sub cl,0xac
    add al,cl
    shl rax,8
    add cl,0xdf
    add al,cl
    shl rax,8
    sub cl,0xeb
    add al,cl
    shl rax,8
    add cl,0x0
    add al,cl
    push rax
    shl rax,8
    add cl,0x0
    add al,cl
    shl rax,8
    add cl,0x8
    add al,cl
    shl rax,8
    add cl,0xb0
    add al,cl
    shl rax,8
    sub cl,0x77
    add al,cl
    shl rax,8
    add cl,0x88
    add al,cl
    shl rax,8
    sub cl,0x98
    add al,cl
    shl rax,8
    add cl,0x1c
    add al,cl
    shl rax,8
    sub cl,0x42
    add al,cl
    push rax
    shl rax,8
    add cl,0x6a
    add al,cl
    shl rax,8
    sub cl,0x74
    add al,cl
    shl rax,8
    add cl,0xa7
    add al,cl
    shl rax,8
    add cl,0x18
    add al,cl
    shl rax,8
    sub cl,0x11
    add al,cl
    shl rax,8
    sub cl,0xa0
    add al,cl
    shl rax,8
    add cl,0x39
    add al,cl
    shl rax,8
    add cl,0x88
    add al,cl
    push rax
    shl rax,8
    sub cl,0x47
    add al,cl
    shl rax,8
    sub cl,0x41
    add al,cl
    shl rax,8
    add cl,0x93
    add al,cl
    shl rax,8
    sub cl,0xaa
    add al,cl
    shl rax,8
    add cl,0x17
    add al,cl
    shl rax,8
    add cl,0x9d
    add al,cl
    shl rax,8
    sub cl,0x5c
    add al,cl
    shl rax,8
    sub cl,0x41
    add al,cl
    push rax
    shl rax,8
    add cl,0xd
    add al,cl
    shl rax,8
    sub cl,0x55
    add al,cl
    shl rax,8
    add cl,0x0
    add al,cl
    shl rax,8
    add cl,0x0
    add al,cl
    shl rax,8
    add cl,0x4
    add al,cl
    shl rax,8
    add cl,0x8c
    add al,cl
    shl rax,8
    add cl,0x0
    add al,cl
    shl rax,8
    add cl,0x0
    add al,cl
    push rax
    shl rax,8

    call rbx

.exit_with_error:
    ;; exit 1
    push 1
    pop rdi
    syscall

filesize equ $ - $$