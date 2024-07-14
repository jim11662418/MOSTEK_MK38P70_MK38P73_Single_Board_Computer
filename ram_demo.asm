;=========================================================================
; demonstration of accessing different types of RAM on the MK38P73
;=========================================================================
            PAGE 0               ;  suppress page headings in ASW listing file
            
            cpu MK3873            

; 64 bytes of 'executable' RAM accessed indirectly through DC:
;   0FC0=0FFFH

; 12 bytes of 'scratchpad' RAM accessed directly:
;   00-0BH

; 48 bytes of 'scratchpad' RAM accessed indirectly through ISAR:
;   10-17H
;   18-1FH
;   20-27H
;   28-2FH
;   30-37H
;   38-3FH

; port address
LEDport     equ 04H              ; parallel I/O port 4

; scratchpad RAM
count       equ 0FC0H            ; executable RAM accessed indirectly through DC
delaycnt    equ 01H              ; scratchpad RAM accessed directly
loopcnt     equ 38H              ; scratchpad RAM accessed indirectly through LSIR

            org 0000H

            dci count            ; load DC with the address of 'count'
            lr Q,DC              ; save DC in linkage register Q
            li 0FFH
            st                   ; store A at [DC] (DC is incremented)
            
            li loopcnt     
            lr IS,A              ; load LSIR with address of 'loopcnt'

loop:       lr DC,Q              ; restore DC from Q
            lm                   ; load A from RAM addressed by [DC] (DC is incremented)
            inc                  ; increment A
            lr DC,Q              ; restore DC from Q
            st                   ; store A at RAM addressed by [DC] (DC is incremented)
            outs LEDport         ; output A to port 4
            li 100
            lr delaycnt,A
            pi delay             ; delay 1 Sec
            br loop

;------------------------------------------------------------------------            
; delay = 10,014 µS times number in 'delaycnt'
;------------------------------------------------------------------------
delay:      clr
            lr	S,A               ; store A in scratchpad RAM addressed by [LISR]. 'S' means do not increment or decrement ISIR
delay1:     in 0FFH
            in 0FFH
            in 0FFH
            nop
            ds S                 ; decrement scratchpad RAM addressed by [LISR]. 'S' means do not increment or decrement ISIR
            bnz delay1
            ds	delaycnt
            bnz delay
            pop

            end