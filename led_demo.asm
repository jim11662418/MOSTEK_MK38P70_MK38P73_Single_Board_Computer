;=========================================================================
; flash the LEDs connected to port 4 pins once each second
;=========================================================================
            PAGE 0               ;  suppress page headings in ASW listing file

            cpu MK3873

; port address
LEDport     equ 04H              ; parallel I/O port 4

; scratchpad RAM
count       equ 00H              ; scratchpad RAM
delaycnt    equ 01H              ; scratchpad RAM
loopcnt     equ 02H              ; scratchpad RAM

            org 0000H

; since the outputs of port 4 are open drain, writing '1' to a port 4 output port pin
; results in a '0' at that output port pin. the cathodes of the LEDs are connected to
; the output pins of port 4, therefore, outputing '1' pulls the cathode low and turns
; the LED on. outputing '0' turns the LED off.

            li 0FFH
            lr count,A

loop:       lr A,count
            inc
            lr count,A
            outs LEDport         ; output A to port 4
            li 100
            lr delaycnt,A
            pi delay             ; delay 1 Sec
            br loop

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

            end