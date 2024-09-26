;
; Lab1_2.asm
;
; Created: 23/09/2024 17:40:02
; Author : ArthurLBDS
;


.include "m324PAdef.inc"
.org 00

	ldi r16,0x01
	out	DDRA, r16
start:
		call delay_1ms
        sbi	PORTA,PINA0
	    call delay_1ms
        cbi	PORTA, PINA0
		rjmp start

DELAY_1MS:
    ldi     r18, 125       ; load 125 in r18 (boucle intérieure)
L1: ldi		r19, 25
L2:	nop
	nop
    dec     r19            ; Decrease r18
    brne    L2             ; if R19 isn't 0, go to L2
	dec R18
	brne L1
    ret                    ; Retour de la fonction

DELAY_10MS:
	ldi r20, 10
L3: 
	call delay_1ms
	dec r20
	brne L3
	ret
