;=========================================================================
; prints the contents of linkage register QL as a 2 digit hex number
;=========================================================================
            page 0              ;  suppress page headings in asw listing file

            cpu MK3873

bdrate      equ 00001011B  ; command send to brport to set baud rate to 9600
txcmd       equ 10000010B  ; command sent to cnport to configure shift register to transmit 10 bits
rxcmd       equ 10010000B  ; command send to cnport to configure shift register to receive 10 bits

; port addresses
brport      equ 0CH        ; address of baud rate port
cnport      equ 0DH        ; address of control port
duport      equ 0EH        ; address of upper data port
dlport      equ 0FH        ; address of lower data port

; scratchpad RAM
count       equ 00H
delaycnt    equ 01H        ; scratchpad RAM
loopcnt     equ 02H        ; scratchpad RAM
txdata      equ 0AH        ; transmit buffer in scratchpad RAM
rxdata      equ 0BH        ; receive buffer in scratchpad RAM

            org 0000H

init:       li bdrate      ; baud rate value for 9600 bps
            outs brport    ; output to baud rate port
            li rxcmd       ; start in receiver mode
            outs cnport    ; write to control port
            clr
            outs duport    ; clear upper half of data port
            outs dlport    ; clear lower half of data port
            ins cnport     ; clear error status
            ins duport     ; clear ready status

            clr
            lr count,A

tstloop:    lr A,count
            inc
            lr count,A

            lr QL,A
            pi hexbyte

            li 0DH
            lr txdata,A
            pi putchar

            li 50
            lr delaycnt,A
            pi delay
            br tstloop

;------------------------------------------------------------------------
; prints (to the serial port) the contents of linkage register QL as a 2 digit hex number
;------------------------------------------------------------------------
hexbyte:    lr K,P         ; save the caller's return address (stack register P) in linkage register K
            lr A,QL        ; retrieve the byte from QL
            sr 4           ; shift the 4 most significant bits to the 4 least significant position
            ai 30H         ; add 30H to convert from binary to ASCII
            ci '9'         ; compare to ASCII '9'
            bp hexbyte1    ; branch if '0'-'9'
            ai 07H         ; else add 7 to convert to ASCII 'A'-'F'
hexbyte1:   lr txdata,A    ; put it into the transmit buffer
            pi putchar     ; print the most significant hex digit
            lr A,QL        ; retrieve the byte from QL
            sl 4           ; shift left
            sr 4           ; then shift right to remove the 4 most significant bits
            ai 30H         ; add 30H to convert from binary to ASCII
            ci '9'         ; compare to ASCII '9'
            bp hexbyte2    ; branch if '0'-'9'
            ai 07H         ; else add 7 to convert to ASCII 'A' to 'F'
hexbyte2:   lr txdata,A    ; put it into the transmit buffer
            pi putchar     ; print the least significant hex digit
            pk             ; Program Counter (P0) is loaded with the contents of linkage register K.

;------------------------------------------------------------------------
; delay = 10,014 µS times number in 'delaycnt'
;------------------------------------------------------------------------
delay:      clr                  ;   1 cycle
            lr loopcnt,A         ;   2 cycle
delay1:     in 0FFH              ;     4 cycles
            in 0FFH              ;     4 cycles
            in 0FFH              ;     4 cycles
            nop                  ;     1 cycles
            ds loopcnt           ;     1.5 cycles
            bnz delay1           ;     3.5 cycles
            ds delaycnt          ;   1.5 cycles
            bnz delay            ;   3.5 cycles
            pop                  ; 2 cycles

;-----------------------------------------------------------------------------------
; transmit the character in the tx buffer 'txdata' through the serial port
;-----------------------------------------------------------------------------------
putchar:    lr A,txdata    ; load the character to be tranmitted from the transmit buffer
            sl 1           ; shift left to make room for the start bit
            outs dlport    ; store into the lower data port
            lr A,txdata    ; reload the character to prepare the value for the upper data port
            sr 4           ; shift right 7 places...
            sl 1           ;   so that all that remains of the data...
            sr 4           ;   is bit 7
            oi 00000010B   ; bitwise 'OR' the stop bit with bit 7 of the data
            outs duport    ; store into the upper data port
            li txcmd       ; transmit command for control port
            outs cnport    ; shift it out
putchar1:   ins cnport     ; read the control port to check for completion of transmission
            sl 1           ; shift the underrun error bit into into the sign bit position
            bp putchar1    ; loop until no underrun error (all 10 bits have been shifted out)
            li rxcmd
            outs cnport    ; return to receiver mode
            ins duport     ; clear ready status
            pop

