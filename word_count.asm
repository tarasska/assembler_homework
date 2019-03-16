        section .text

        global _start

_start:
        pop             rax
        cmp             rax, 2
        jne             incorrect_args

        pop             rax
        pop             rdi
        mov             rax, 2
        xor             rsi, rsi
        xor             rdx, rdx
        syscall

        cmp             rax, 0
        jl              open_fail
        mov             [fd], rax
        xor             rbx, rbx

        call            words_cnt
        call            print_and_exit


;       r8 - words cnt
;       r9 = 1 if last byte is white_space, 0 - otherwise
;       return value in rax
;       r11 - char code
words_cnt:
        xor             r8, r8
        mov             r9, 1
.read_loop:
        xor             rax, rax
        mov 		    rdi, [fd]
        mov 		    rsi, buf
        mov 		    rdx, 1
        syscall
        cmp             rax, 0
        je              .last_word
        jl              read_fail
        mov             r11, [buf]
        jmp             .check_white_space_1
        xor             r9, r9
        jmp             .read_loop

.check_white_space_1:
        cmp             r11, 9
        jl              .flush_and_read_again
        cmp             r11, 13
        jg              .check_white_space_2
        jmp             .update_cnt

.check_white_space_2:
        cmp             r11, 32
        jne             .flush_and_read_again
        jmp             .update_cnt

.update_cnt:
        cmp             r9, 1
        je              .read_loop
        mov             r9, 1
        add             r8, 1
        jmp             .read_loop

.flush_and_read_again:
        xor             r9, r9
        jmp             .read_loop

.last_word:
        cmp             r9, 1
        je              .return
        add             r8, 1
        jmp             .return

.return:
        mov             rax, r8
        ret

;   convert rax to string buf
;   words count in rax
print_and_exit:
        xor             rcx, rcx
        mov             rbx, 10
        add             rdx, 10
        push            rdx
        inc             rcx

        .loop1:
            xor             rdx, rdx
            div             rbx
            add             rdx, '0'
            push            rdx
            inc             rcx
            cmp             rax, 0
            jg              .loop1

            mov             [buf_len], rcx
            xor             rbx, rbx
        .loop2:
            pop             r10
            mov             [buf + rbx], r10
            inc             rbx
            dec             rcx
            cmp             rcx, 0
            jg              .loop2

            mov             rax, 1
            mov             rdx, [buf_len]
            mov             rdi, 1
            mov             rsi, buf
            syscall


exit:
        mov     rax, 3
        mov     rdi, fd
        syscall
        mov     rax, 60
        mov     rdi, 1
        syscall


incorrect_args:
        mov             rsi, incorrect_args_msg
        mov             rdx, incorrect_args_msg_size
        jmp             exit_with_error

open_fail:
        mov             rsi, open_fail_msg
        mov             rdx, open_fail_msg_size
        jmp             exit_with_error

read_fail:
        mov             rsi, read_fail_msg
        mov             rdx, read_fail_msg_size
        jmp             exit_with_error

write_fail:
        mov             rsi, write_fail_msg
        mov             rdx, write_fail_msg_size
        jmp             exit_with_error

exit_with_error:
        mov             rax, 1
        mov             rdi, 1
        syscall

        mov             rax, 60
        mov             rdi, 1
        syscall


        section         .rodata
incorrect_args_msg:   db      "invalid arguments"
incorrect_args_msg_size: equ $ - incorrect_args_msg
open_fail_msg:        db      "open failed"
open_fail_msg_size: equ $ - open_fail_msg
read_fail_msg:        db      "read failed"
read_fail_msg_size: equ $ - read_fail_msg
write_fail_msg:       db      "write failed"
write_fail_msg_size: equ $ - write_fail_msg

        section         .bss

buf         resb        1024
buf_len     resq        1
fd          resq        1

