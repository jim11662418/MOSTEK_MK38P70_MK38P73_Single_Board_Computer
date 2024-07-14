;===================================================================================
; print the contents of linkage register QL as a 3  decimal digits
;===================================================================================
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
digit       equ 03H        ; hundreds, tens and units digit to be printed
zeroflag    equ 04H        ; leading zero flag (set to enable printing zeros)
txdata      equ 0AH        ; transmit buffer in scratchpad RAM
rxdata      equ 0BH        ; receive buffer in scratchpad RAM

            org 0000H

; initialize serial communications for 9600 bps, N-8-1            
init:       li bdrate      ; baud rate value for 9600 bps
            outs brport    ; output to baud rate port
            li rxcmd       ; start in receiver mode
            outs cnport    ; write to control port
            clr
            outs duport    ; clear upper half of data port
            outs dlport    ; clear lower half of data port
            ins cnport     ; clear error status
            ins duport     ; clear ready status
            
            li 0FFH
            lr count,A
            
tstloop:    lr A,count
            inc            ; increment 'count'
            lr count,A
            
            lr QL,A
            pi prndec
            
            li 0DH
            lr txdata,A
            pi putchar
            
            li 50
            lr delaycnt,A
            pi delay
            br tstloop
            
;------------------------------------------------------------------------
; prints (to the serial port) the contents of linkage register QL as a 3 
; digit decimal number. leading zeros are suppressed.
;------------------------------------------------------------------------              
prndec:     lr K,P         ; save the caller's return address (stack register P) in linkage register K
            clr
            lr zeroflag,A  ; clear 'print zeros' flag

; hundreds digit
            li '0'-1
            lr digit,A     ; initialize 'digit'
prndec1:    lr A,digit
            inc
            lr digit,A     ; increment 'digit'
            lr A,QL        ; recall the number from QL
            ai (~100)+1    ; add 2's complement of 100 (subtract 100)
            lr QL,A        ; save the number in QL
            bc prndec1     ; if there's no underflow, go back and subtract 100 from the number again
            ai 100         ; else, add 100 back to the number to correct the underflow
            lr QL,A        ; save the number in QL
            lr A,digit     ; recall the hundreds digit
            ci 30H         ; is the hundreds digit '0'?
            bz prndec2     ; if so, skip the hundreds digit and go to the tens digit
            lr txdata,A    ; else, save the hundreds digit in the tx buffer
            pi putchar     ; print the hundreds digit
            li 0FFH
            lr zeroflag,A  ; set the zero flag (all zeros from now on will now be printed)
            
; tens digit            
prndec2:    li '0'-1
            lr digit,A     ; initialize 'digit'
prndec3:    lr A,digit
            inc
            lr digit,A     ; increment 'digit'
            lr A,QL        ; recall the number from QL
            ai (~10)+1     ; add 2's complement of 10 (subtract 10)
            lr QL,A        ; save the number in QL
            bc prndec3     ; if there's no underflow, go back and subtract 10 from the number again
            ai 10          ; else add 10 back to the number to correct the underflow
            lr QL,A        ; save the number in QL
            lr A,digit     ; recall the ten's digit
            ci 30H         ; is the tens digit zero?
            bnz prndec4    ; if not, go print the tens digit
            lr A,zeroflag  ; else, check the zero flag
            ci 0           ; is the flag zero?
            bz prndec5     ; if so, skip the tens digit and print the units digit
prndec4:    lr A,digit     ; else recall the tens digit
            lr txdata,A    ; save it in the tx buffer
            pi putchar     ; print the tens digit           
            
; units digit            
prndec5:    lr A,QL        ; what remains in QL after subtracting hundreds and tens is the units    
            ai 30H         ; convert to ASCII
            lr txdata,A    ; save it in the tx buffer
            pi putchar     ; print the units digit
            
            pk             ; Program Counter (P0) is loaded with the contents of linkage register K.
          
;------------------------------------------------------------------------            
; delay = 10,014 µS times number in 'delaycnt'
;------------------------------------------------------------------------
delay:      clr                  ;   1 cycle
            lr	loopcnt,A         ;   2 cycle
delay1:     in 0FFH              ;     4 cycles
            in 0FFH              ;     4 cycles
            in 0FFH              ;     4 cycles
            nop                  ;     1 cycles           
            ds loopcnt           ;     1.5 cycles  
            bnz delay1           ;     3.5 cycles 
            ds	delaycnt          ;   1.5 cycles
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

