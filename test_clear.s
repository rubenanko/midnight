global _start

section .text

_start:
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