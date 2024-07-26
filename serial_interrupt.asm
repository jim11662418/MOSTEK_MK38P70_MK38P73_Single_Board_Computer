;========================================================================
; serial communications demo. echo any characters received
; N-8-1 at 9600 bps
;========================================================================
            PAGE 0               ;  suppress page headings in ASW listing file

            cpu MK3873
         
; serial reception:         
; bits are shifted in from left to right
; bits 1-7 of the received character are in bits 0-6 of the the upper data port
; bit 0 of the received character is in bit 7 of the lower data port         
;       ---upper data port----    ---lower data port----   
;       7  6  5  4  3  2  1  0  7  6  5  4  3  2  1  0
;       -------received bits--------
; SI--> S  7  6  5  4  3  2  1  0  S  -  -  -  -  -  -

; serial transmission:       
; bits are shifted out from left to right
; bits 0-6 of the character to be transmitted are stored in bits 1-7 of the the lower data port
; bit 7 of the character to be transmitted is stored in bit 0 of the upper data port         
;       ---upper data port----  ---lower data port----   
;       7  6  5  4  3  2  1  0  7  6  5  4  3  2  1  0
;                      ----bits to be transmitted-----
;       -  -  -  -  -  -  S  7  6  5  4  3  2  1  0  S --> SO
        
; baud rate control port (address 0CH) value
; for asynchronous operation, the baud rate is the crystal
; frequency divided by the the divide factor.
; for a 3.6864 MHz crystal...
; port      divide      baud 
; value     factor      rate
; 1 0 1 1     384       9600
; 1 0 1 0     768       4800
; 1 0 0 1    1536       2400
; 1 0 0 0    3072       1200
; 0 1 1 1    6144        600
; 0 1 1 0   12288        300 
; 0 1 0 1   24576        150
; 0 1 0 0   33536        110
; 0 0 1 1   49152         75

; constants
bdrate      equ 00001011B  ; command send to brport to set baud rate to 9600
txcmd       equ 10000010B  ; command sent to cnport to configure shift register to transmit 10 bits
rxcmd       equ 10010001B  ; command send to cnport to configure shift register to receive 10 bits, interrupt

; port addresses
brport      equ 0CH        ; address of baud rate port
cnport      equ 0DH        ; address of control port
duport      equ 0EH        ; address of upper data port
dlport      equ 0FH        ; address of lower data port

; scratchpad RAM
saveA       equ 02H
txdata      equ 06H        ; transmit buffer in scratchpad RAM
rxdata      equ 05H        ; receive buffer in scratchpad RAM

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
            ei
            
            dci testtxt    ; load the address of the first character of the 'testtxt' string into DC
            pi putstr      ; print the string            
            
tstloop:    lr A,rxdata
            ni 0FFH        ; set flags
            bp tstloop     ; loop until bit 7 is set
            
            ni 7FH         ; mask out bit 7
            lr rxdata,A    ; save it
            lr txdata,A    ; save the received character into the tx buffer
            pi putchar     ; echo the received character
            br tstloop
            
            org 0060H      ; serial port receive interrupt vector
;--------------------------------------------------------------------------
; serial receive interrupt service routine
; 1. save status register and accumulator
; 2. read the character
; 3. set bit 7 of the character and save the character in the rx buffer
; 4. restore status register and accumulator and return from interrupt
;--------------------------------------------------------------------------            
serialisr:  lr J,W         ; save status register
            lr saveA,A     ; save accumulator

            ins duport     ; read the upper data port
            sl 1
            lr rxdata,A    ; save bits 7-1 of the received character
            ins dlport     ; read the lower data port
            sr 4           ; shift right 7 places...
            sl 1           ;   so that all that remains of the data ...
            sr 4           ;   is bit 7
            xs rxdata      ; combine bits 7-1 (in rxdata) with bit 0 (in the accumulator)
            oi 80H         ; set bit 7 to indicate that this is a new character
            lr rxdata,A    ; save the new character in the rx buffer
            
            lr A,saveA     ; restore original accumulator
            lr W,J         ; restore original status register
            ei             ; re-enable interrupts
            pop            ; return from interrupt
            
;-----------------------------------------------------------------------------------
; print the zero-terminated string whose first character is addressed by DC
;-----------------------------------------------------------------------------------
putstr:     lr K,P         ; save the caller's return address (stack register P) in linkage register K
putstr1:    lm             ; load the character addressed by DC and increment DC
            ci 0           ; is the character zero (end of string)?
            bnz putstr2    ; branch if not the end of the string
            pk             ; program counter (P0) is loaded with the contents of linkage register K. thus, return to caller
putstr2:    lr txdata,A    ; put the character into the tx buffer
            pi putchar     ; print the character
            br putstr1     ; go back for the next character
            
testtxt:    db "This is a test of the serial port.",0DH,0            
            
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

;-----------------------------------------------------------------------------------
; print (to the serial port) carriage return followed by linefeed
;-----------------------------------------------------------------------------------
newline:    lr K,P         ; save return address
            lis 0DH        ; carriage return
            lr txdata,A    ; put it into the tx buffer
            pi putchar     ; print the carriage return
            lis 0AH        ; line feed
            lr txdata, A   ; put it in the tx buffer
            pi putchar     ; print line feed
            pk             ;return

            end