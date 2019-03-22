section         .text

                global          _start
_start:
                sub             rsp, 2 * 256 * 8
                lea             rdi, [rsp + 256 * 8]
                mov             rcx, 256
                call            read_long
                mov             rdi, rsp
                call            read_long
                lea             rsi, [rsp + 256 * 8]

                call            mul_long_long

                call            write_long

                mov             al, 0x0a
                call            write_char

                jmp             exit


; multiplicate two long number
;    rdi -- address of number #1 (long number)
;    rsi -- address of number #2 (long number)
;    rcx -- length of long numbers in qwords
; result:
;    mul is written to rdi
;    rcx -- result length
mul_long_long:
                push            rdi
                push            rsi
                push            rbx
                push            r8
                push            r9
                push            r10
                push            r11
                push            r12
                push            r15

                sub             rsp, 2 * 256 * 8 ;reserved memory
                mov             r14, rsp
                call            set_zero_with_save_reg

                ;r8 -> buffer for rdi(save input number), r9 -> result
                lea             r8, [rsp]
                lea             r9, [rsp + 256 * 8]

                call            move_reg_to_buffer

                ; swap rdi and r8 to use rdi in orignals methods
                mov             r11, r8
                mov             r8, rdi
                mov             rdi, r11


                xor             r15, r15 ;shift size
                mov             r13, rcx ;loop it
                mov             rcx, 256
                clc
                multiplication_loop:
                        ;multiply zero acceleration
                        jmp            if_digit_is_zero
                        continue:
                        mov             rbx, [rsi]
                        ;multiply first long number by [rsi]
                        call            mul_long_short
                        ;shift of the result of multiplication by several qwords
                        call            shift_rdi
                        mov             r10, rsi
                        mov             rsi, r9
                        ;addition multiplication step and result
                        call            add_long_long
                        ;r8 (orignals value of long number) -> rdi
                        call            move_buffer_to_reg
                        mov             rsi, r10
                        lea             rsi, [rsi + 8]
                        inc             r15
                        dec             r13
                        jnz             multiplication_loop
                mul_end:
                mov             rdi, r8
                mov             r8, r9
                ;r9 -> rdi : move multiplication result to rdi
                ;instead of the first number
                call            move_buffer_to_reg
                add             rsp, 2 * 256 * 8

                pop             r15
                pop             r12
                pop             r11
                pop             r10
                pop             r9
                pop             r8
                pop             rbx
                pop             rsi
                pop             rdi


; rdi - address of long number
; r15 - shift size
; rcx - length of long number in q qwords
shift_rdi:
                push            rdx
                push            r15
                push            rbx
                push            rcx
                push            rdi
                mov             rcx, 129
                lea             rdi, [rdi + rcx * 8]
                .shift_loop:
                        sub             rdi, 8
                        mov             rbx, [rdi]
                        mov             [rdi + r15 * 8], rbx
                        dec             rcx
                        cmp             rcx, 0
                        je              .break
                        jmp             .shift_loop

                .break:
                xor             rbx, rbx
                .loop:
                        cmp             r15, 0
                        je              .end
                        mov             [rdi], rbx
                        lea             rdi, [rdi + 8]
                        dec             r15
                        jmp             .loop

                .end:
                pop             rdi
                pop             rcx
                pop             rbx
                pop             r15
                pop             rdx
                ret


;compare [rsi] with 0
if_digit_is_zero:
                cmp             r13, 0
                je              mul_end
                mov             r14, [rsi]
                cmp             r14, 0x0
                jne             continue
                lea             rsi, [rsi + 8]
                inc             r15
                dec             r13
                jmp             multiplication_loop


; r14 - adress of previous
;
set_zero_with_save_reg:
                push            rcx
                push            rdi
                mov             rcx, 256
                mov             rdi, r14
                call            set_zero
                pop             rdi
                pop             rcx
                ret

; move r8 to rdi
; refresh value in rdi
move_buffer_to_reg:
                push            rdi
                push            rcx
                push            r8
                push            r9
                .loop:
                    mov             r9, [r8]
                    mov             [rdi], r9
                    lea             rdi, [rdi + 8]
                    lea             r8, [r8 + 8]
                    dec             rcx
                    jnz             .loop

                pop             r9
                pop             r8
                pop             rcx
                pop             rdi

                ret
;  move rdi to r8
;  rdi - long number
;  r8 - copy of rdi
move_reg_to_buffer:
                push            rdi
                push            rcx
                push            r8
                push            r9
                xor             r9, r9
                .loop:
                    mov             r9, [rdi]
                    mov             [r8], r9
                    lea             rdi, [rdi + 8]
                    lea             r8, [r8 + 8]
                    dec             rcx
                    jnz             .loop

                pop             r9
                pop             r8
                pop             rcx
                pop             rdi

                ret
return:
                ret

; adds two long number
;    rdi -- address of summand #1 (long number)
;    rsi -- address of summand #2 (long number)
;    rcx -- length of long numbers in qwords
; result:
;    sum is written to rsi
add_long_long:
                push            rdi
                push            rsi
                push            rcx
                push            r14
                push            rax

                mov             r14, rdi
                mov             rdi, rsi
                mov             rsi, r14

                clc
.loop:
                mov             rax, [rsi]
                lea             rsi, [rsi + 8]
                adc             [rdi], rax
                lea             rdi, [rdi + 8]
                dec             rcx
                jnz             .loop

                pop             rax
                pop             r14
                pop             rcx
                pop             rsi
                pop             rdi
                ret

; adds 64-bit number to long number
;    rdi -- address of summand #1 (long number)
;    rax -- summand #2 (64-bit unsigned)
;    rcx -- length of long number in qwords
; result:
;    sum is written to rdi
add_long_short:
                push            rdi
                push            rcx
                push            rdx

                xor             rdx,rdx
.loop:
                add             [rdi], rax
                adc             rdx, 0
                mov             rax, rdx
                xor             rdx, rdx
                add             rdi, 8
                dec             rcx
                jnz             .loop

                pop             rdx
                pop             rcx
                pop             rdi
                ret

; multiplies long number by a short
;    rdi -- address of multiplier #1 (long number)
;    rbx -- multiplier #2 (64-bit unsigned)
;    rcx -- length of long number in qwords
; result:
;    product is written to rdi
mul_long_short:
                push            rax
                push            rdi
                push            rcx
                push            rsi
                push            rbx

                xor             rsi, rsi
.loop:
                mov             rax, [rdi]
                mul             rbx
                add             rax, rsi
                adc             rdx, 0
                mov             [rdi], rax
                add             rdi, 8
                mov             rsi, rdx
                dec             rcx
                jnz             .loop

                pop             rbx
                pop             rsi
                pop             rcx
                pop             rdi
                pop             rax
                ret

; divides long number by a short
;    rdi -- address of dividend (long number)
;    rbx -- divisor (64-bit unsigned)
;    rcx -- length of long number in qwords
; result:
;    quotient is written to rdi
;    rdx -- remainder
div_long_short:
                push            rdi
                push            rax
                push            rcx

                lea             rdi, [rdi + 8 * rcx - 8]
                xor             rdx, rdx

.loop:
                mov             rax, [rdi]
                div             rbx
                mov             [rdi], rax
                sub             rdi, 8
                dec             rcx
                jnz             .loop

                pop             rcx
                pop             rax
                pop             rdi
                ret

; assigns a zero to long number
;    rdi -- argument (long number)
;    rcx -- length of long number in qwords
set_zero:
                push            rax
                push            rdi
                push            rcx

                xor             rax, rax
                rep stosq

                pop             rcx
                pop             rdi
                pop             rax
                ret

; checks if a long number is a zero
;    rdi -- argument (long number)
;    rcx -- length of long number in qwords
; result:
;    ZF=1 if zero
is_zero:
                push            rax
                push            rdi
                push            rcx

                xor             rax, rax
                rep scasq

                pop             rcx
                pop             rdi
                pop             rax
                ret

; read long number from stdin
;    rdi -- location for output (long number)
;    rcx -- length of long number in qwords
read_long:
                push            rcx
                push            rdi

                call            set_zero
.loop:
                call            read_char
                or              rax, rax
                js              exit
                cmp             rax, 0x0a
                je              .done
                cmp             rax, '0'
                jb              .invalid_char
                cmp             rax, '9'
                ja              .invalid_char

                sub             rax, '0'
                mov             rbx, 10
                call            mul_long_short
                call            add_long_short
                jmp             .loop

.done:
                pop             rdi
                pop             rcx
                ret

.invalid_char:
                mov             rsi, invalid_char_msg
                mov             rdx, invalid_char_msg_size
                call            print_string
                call            write_char
                mov             al, 0x0a
                call            write_char

.skip_loop:
                call            read_char
                or              rax, rax
                js              exit
                cmp             rax, 0x0a
                je              exit
                jmp             .skip_loop

; write long number to stdout
;    rdi -- argument (long number)
;    rcx -- length of long number in qwords
write_long:
                push            rax
                push            rcx

                mov             rax, 20
                mul             rcx
                mov             rbp, rsp
                sub             rsp, rax

                mov             rsi, rbp

.loop:
                mov             rbx, 10
                call            div_long_short
                add             rdx, '0'
                dec             rsi
                mov             [rsi], dl
                call            is_zero
                jnz             .loop

                mov             rdx, rbp
                sub             rdx, rsi
                call            print_string

                mov             rsp, rbp
                pop             rcx
                pop             rax
                ret

; read one char from stdin
; result:
;    rax == -1 if error occurs
;    rax \in [0; 255] if OK
read_char:
                push            rcx
                push            rdi

                sub             rsp, 1
                xor             rax, rax
                xor             rdi, rdi
                mov             rsi, rsp
                mov             rdx, 1
                syscall

                cmp             rax, 1
                jne             .error
                xor             rax, rax
                mov             al, [rsp]
                add             rsp, 1

                pop             rdi
                pop             rcx
                ret
.error:
                mov             rax, -1
                add             rsp, 1
                pop             rdi
                pop             rcx
                ret

; write one char to stdout, errors are ignored
;    al -- char
write_char:
                sub             rsp, 1
                mov             [rsp], al

                mov             rax, 1
                mov             rdi, 1
                mov             rsi, rsp
                mov             rdx, 1
                syscall
                add             rsp, 1
                ret

exit:
                mov             rax, 60
                xor             rdi, rdi
                syscall

; print string to stdout
;    rsi -- string
;    rdx -- size
print_string:
                push            rax

                mov             rax, 1
                mov             rdi, 1
                syscall

                pop             rax
                ret


                section         .rodata
invalid_char_msg:
                db              "Invalid character: "
invalid_char_msg_size: equ             $ - invalid_char_msg

