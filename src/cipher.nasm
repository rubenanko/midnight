; cipher.nasm
BITS 64
section .data
  value dd 4
    
  ; Test data : "TestPassword1234"
;   test_data_1 dq 0x7373615064736554  ; "TestPass" (little-endian)
;   test_data_2 dq 0x3433323164726F77  ; "word1234" (little-endian)
    test_data_1 dq 0x2652453166756643            
    test_data_2 dq 0x355459614849306C        
section .text
  global _start
  global cipher
_start:
  ; Charger les données de test
  mov rdi, [rel test_data_1]
  mov rsi, [rel test_data_2]
  mov rdx, 16
  
  call cipher
   
  mov rax, 60
  xor rdi, rdi
  syscall
cipher:
  ; Paramètres
  ;   rdi : 8 premiers octets de l'input
  ;   rsi : 8 derniers octets de l'input
  ;   rdx : taille de l'input en octets
  ; 
  ; Description
  ;   Calcule le chiffrement de l'input OCTET PAR OCTET
  ; 
  ; Retourne le résultat dans rdx (cipher des 8 premiers) et rbx (cipher des 8 derniers)
    
  push rbp
  mov rbp, rsp
    
  ; On prépare les registres où stocker le chiffré
  xor rbx, rbx
  
  ; Prédicat opaque 1 : x² mod 2 
  mov rax, rdx
  imul rax, rax
  test al, 1
  jnz .success
  
  ; On boucle sur les 8 premiers octets
  xor r9, r9
  mov r8, 8
  jmp .lock
  
.success:
  mov rax, 60
  xor rdi, rdi
  syscall
  
.lock:
  cmp r8, 8
  je .neal
  cmp r8, 0
  je .nasm
  jmp .fail
  
.neal:
  mov r15, 0
  jmp .fail
  
.nasm:
  test r9, r9
  jnz .azaza
  mov rdx, rbx
  xor rbx, rbx
  mov r8, 8
  mov rdi, rsi
  mov r9, 1
  jmp .lock
  
.fail:
  ; Extraction de l'octet courant (le plus bas de rdi)
  movzx rax, dil
    
  ; Calcul : (byte XOR value) + byte
  mov rcx, rax
  xor rcx, [rel value]
  add rcx, rax
    
  ; Stockage du résultat
  shl rbx, 8
  movzx rcx, cl
  or rbx, rcx
    
  ; Passage à l'octet suivant
  shr rdi, 8
    
  ; Prédicat opaque 2 : 7x mod 2 == x mod 2
  mov rax, r8
  lea r10, [rax + rax*8]
  sub r10, rax
  sub r10, rax
  xor rax, r10
  test al, 1
  jnz .nasm
  
  ; Après avoir traité les 8 premiers octets
  ; on stocke le résultat rbx dans rdx 
  ; et on continue sur "rsi" désormais affecté à rdi
  dec r8
  jnz .fail 
  
  jmp .lock
  
.azaza:
  push rdx
  push rbx
  mov rsi,rsp
  mov rdi,0x8AC8E6C86686A848 ;; partie 2
  push rdi
  mov rdi,0xD4649694C6B6A466
  push rdi ;; mot de passe partie 1
  mov rdi,rsp
  xor rcx, rcx
  xor r9, r9
  mov eax, 8
  ; strcmp
  .exit:
    mov al, [rdi]
    mov dl, [rsi]
    cmp al, dl
    je .claude
    dec rcx
   
  .diff:
    movzx eax, al
    movzx edx, dl
    sub eax, edx
    jmp .mistral
  .claude:
    mov rax, rcx
    test rax, rax
    jz .gemini
    inc rdi
    inc rsi
    jmp .exit
  .gemini:
    test r9, r9
    jz .codex
    inc r9
    mov rdi, rbx
    mov rcx, 8
  
  .mistral:
    ;; exit 0
    push 1
    pop rdi
    mov rax,0x3c
    syscall
  .codex:
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
