;-------------------------------------------------------------------------
; timer interrupt every 10 milliseconds
;-------------------------------------------------------------------------
            PAGE 0               ;  suppress page headings in ASW listing file

            cpu MK3873

; port addresses
LEDport     equ 04H              ; parallel I/O port 4
icp         equ 06H              ; interrupt control port
timerport   equ 07H              ; timer port

; scratchpad RAM
LEDs        equ 00H              ; value output to LEDs
intcounter  equ 01H              ; count of interrupts

; for a 3.6864 MHz crystal...
;  icp       divide            timer       timer
; value      factor            clock       period
;  2AH    3.6864 MHz/2/2   = 921,600 Hz    1.08 µS
;  4AH    3.6864 MHz/2/5   = 368,640 Hz    2.71 µS
;  6AH    3.6864 MHz/2/10  = 184,320 Hz    5.42 µS
;  8AH    3.6864 MHz/2/20  =  92,160 Hz   12.17 µS
;  AAH    3.6864 MHz/2/40  =  46,080 Hz   21.70 µS
;  CAH    3.6864 MHz/2/100 =  18,432 Hz   54.25 µS
;  EAH    3.6864 MHz/2/200 =   9,216 Hz  108.50 µS

            org 0000H

            clr
            lr intcounter,A
            lr LEDs,A
            li 0CAH
            out icp              ; crystal freq is divided by 2 and then by 100 to clock timer at 18,432 Hz
            li 184
            out timerport        ; program timer to interrupt at every 184 clocks or every 10 milliseconds
            ei                   ; enable interrupts
here:       br here              ; wait here for an interrupt

            org 0020H            ; timer interrupt vector

timerisr:   lr A,intcounter
            inc
            lr intcounter,A      ; increment the interrupt counter
            ci 100               ; have 100 interrupts (or one second) been counted?
            bnz timerisr1        ; exit if not
            clr
            lr intcounter,A      ; else, reset the interrupt counter
            lr A,LEDs
            inc
            lr LEDs,A
            outs LEDport         ; flash the LEDs every second
timerisr1:  ei                   ; re-enable interrupts
            pop                  ; return from interrupt

            end