BITS 64
default rel

%define ENTRY_SIZE 24

struc entry
    .name:  resq 1
    .min:   resd 1
    .max:   resd 1
    .sum:   resd 1
    .count: resd 1
endstruc

section .bss
    entries:   resb 24 * 4096
    nentries:  resq 1

section .data
    fname:  db "../../data/measurements.txt", 0
    rmode:  db "rb", 0
    fmt:    db "%s", 9, "%d", 9, "%d", 9, "%d", 9, "%d", 10, 0
    errmsg: db "failed to open input", 10, 0

section .text
    global main
    extern fopen, fread, fclose, fseek, ftell, malloc
    extern qsort, strcmp, printf, exit

main:
    push rbp
    push rbx
    push r12
    push r13
    push r14
    push r15

    lea rdi, [fname]
    lea rsi, [rmode]
    call fopen
    test rax, rax
    jz .fail
    mov r12, rax

    mov rdi, r12
    xor rsi, rsi
    mov rdx, 2
    call fseek
    mov rdi, r12
    call ftell
    mov r13, rax

    mov rdi, r12
    xor rsi, rsi
    xor rdx, rdx
    call fseek

    lea rdi, [r13 + 1]
    call malloc
    test rax, rax
    jz .fail
    mov r14, rax
    mov byte [r14 + r13], 0

    mov rdi, r14
    mov rsi, 1
    mov rdx, r13
    mov rcx, r12
    call fread

    mov rdi, r12
    call fclose

    mov rdi, r14
    mov rsi, r13
    call parse

    lea rdi, [entries]
    mov rsi, [nentries]
    mov rdx, ENTRY_SIZE
    lea rcx, [cmp_entry]
    call qsort

    lea rbx, [entries]
    mov rbp, [nentries]
.print_loop:
    test rbp, rbp
    jz .print_done
    xor eax, eax
    lea rdi, [fmt]
    mov rsi, [rbx + entry.name]
    mov edx, [rbx + entry.min]
    mov ecx, [rbx + entry.max]
    mov r8d, [rbx + entry.sum]
    mov r9d, [rbx + entry.count]
    call printf
    add rbx, ENTRY_SIZE
    dec rbp
    jmp .print_loop
.print_done:
    xor edi, edi
    call exit

.fail:
    lea rdi, [errmsg]
    call printf
    mov edi, 1
    call exit

parse:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15

    mov r14, rdi
    lea r12, [rdi + rsi]
    mov r13, rdi
    xor r15d, r15d

.line:
    cmp r13, r12
    jae .finished

    mov rsi, r13
.find_semi:
    cmp rsi, r12
    jae .finished
    cmp byte [rsi], ';'
    je .semi_found
    inc rsi
    jmp .find_semi
.semi_found:
    mov byte [rsi], 0
    mov rbx, r13
    lea rdi, [rsi + 1]
    mov rcx, rsi
.find_nl:
    cmp rcx, r12
    jae .nl_end
    cmp byte [rcx], 10
    je .nl_found
    inc rcx
    jmp .find_nl
.nl_found:
    mov byte [rcx], 0
    lea r13, [rcx + 1]
    jmp .have_line
.nl_end:
    mov r13, r12
.have_line:
    call parse_temp
    mov ebp, eax

    lea rsi, [entries]
    mov rcx, r15
.lookup:
    test rcx, rcx
    jz .new_entry
    mov rdi, [rsi]
    push rsi
    mov rsi, rbx
    push rcx
    call strcmp
    pop rcx
    pop rsi
    test eax, eax
    je .found_entry
    add rsi, ENTRY_SIZE
    dec rcx
    jmp .lookup
.found_entry:
    mov eax, ebp
    cmp eax, [rsi + entry.min]
    jge .skip_min
    mov [rsi + entry.min], eax
.skip_min:
    cmp eax, [rsi + entry.max]
    jle .skip_max
    mov [rsi + entry.max], eax
.skip_max:
    add [rsi + entry.sum], eax
    inc dword [rsi + entry.count]
    jmp .line
.new_entry:
    imul rax, r15, ENTRY_SIZE
    lea rsi, [entries + rax]
    mov [rsi + entry.name], rbx
    mov eax, ebp
    mov [rsi + entry.min], eax
    mov [rsi + entry.max], eax
    mov [rsi + entry.sum], eax
    mov dword [rsi + entry.count], 1
    inc r15d
    jmp .line

.finished:
    mov [nentries], r15
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret

parse_temp:
    xor ecx, ecx
    movzx edx, byte [rdi]
    cmp dl, '-'
    jne .digits
    mov ecx, 1
    inc rdi
.digits:
    xor eax, eax
.digit_loop:
    movzx edx, byte [rdi]
    cmp dl, '.'
    je .frac
    cmp dl, '0'
    jb .no_frac
    cmp dl, '9'
    ja .no_frac
    lea eax, [rax + rax * 4]
    add eax, eax
    sub edx, '0'
    add eax, edx
    inc rdi
    jmp .digit_loop
.frac:
    inc rdi
    movzx edx, byte [rdi]
    sub edx, '0'
    lea eax, [rax + rax * 4]
    add eax, eax
    add eax, edx
    jmp .sign
.no_frac:
    lea eax, [rax + rax * 4]
    add eax, eax
.sign:
    test ecx, ecx
    jz .ret
    neg eax
.ret:
    ret

cmp_entry:
    mov rdi, [rdi]
    mov rsi, [rsi]
    jmp strcmp

section .note.GNU-stack noalloc noexec nowrite progbits
