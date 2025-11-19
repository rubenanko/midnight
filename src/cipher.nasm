; cipher.nasm
BITS 64

section .data
  value dd 4
    
  ; Test data : "TestPassword1234"
  test_data_1 dq 0x7373615064736554  ; "TestPass" (little-endian)
  test_data_2 dq 0x3433323164726F77  ; "word1234" (little-endian)

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
  
  ; On boucle sur les 8 premiers octets
  xor r9, r9
  mov r8, 8 
    
.loop: 
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
    
  ; Après avoir traité les 8 premiers octets
  ; on stocke le résultat rbx dans rdx 
  ; et on continue sur "rsi" désormais affecté à rdi
  dec r8
  jnz .loop
  
  test r9, r9
  jnz .exit ; 8 derniers octets de l'input déjà traités -> on sort
  
  ; Transition vers la seconde moitié
  mov rdx, rbx ; Sauvegarder le cipher des 8 premiers octets
  xor rbx, rbx ; Réinitialiser l'accumulateur
  mov rdi, rsi ; Charger les 8 derniers octets
  mov r8, 8 ; Réinitialiser le compteur
  mov r9, 1 ; Marquer qu'on est dans la seconde phase
  jmp .loop
  
.exit:
  pop rbp
  ret
