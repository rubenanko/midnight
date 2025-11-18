; Constantes (supposées déclarées en amont)
value dd 4 

cipher:
  ; Paramètres
  ;   rdi : 8 premiers octets de l'input
  ;   rsi : 8 derniers octets de l'input
  ;   rdx : taille de l'input en octets
  ; 
  ; Description
  ;   Calcule le chiffrement de l'input
  ; 
  ; Retourne le résultat dans rdx (hash des 8 premiers) et rbx (hash des 8 derniers)
    
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
    
    ; Accumulation dans rbx
    add rbx, rcx
    
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
    mov rdx, rbx ; Sauvegarder le hash des 8 premiers octets
    xor rbx, rbx ; Réinitialiser l'accumulateur
    mov rdi, rsi  ; Charger les 8 derniers octets
    mov r8, 8 ; Réinitialiser le compteur
    mov r9, 1 ; Marquer qu'on est dans la seconde phase
    jmp .loop
    
.exit:
    pop rbp
    ret
  
  
