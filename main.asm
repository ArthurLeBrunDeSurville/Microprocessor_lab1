/* This section assigns the port pins using keywords, as the hardware connections can change dynamically. 
By using identifiers, modifications become easy. For example, if port A is connected today and later port B is used,
 only the identifier needs to be changed, making it quick and error-free.*/
.EQU 	shiftPORT=PORTA
.EQU 	ShiftDDR=DDRA
.EQU	ShiftSDI=0		;SDI => PA0
.EQU	ShiftCLK=1		;SRCLK => PA1
.EQU	ShiftLATCH=2		;RCLK => PA2

.ORG	0
RJMP	MAIN
    
.ORG	0X40
MAIN:
// Configure PA0, PA1, PA2 as output with initial value 0. It's recommended to write using the identifiers defined above.
LDI     R16, (1 << ShiftSDI) | (1 << ShiftCLK) | (1 << ShiftLATCH)
OUT     ShiftDDR, R16        ; Set PA0, PA1, PA2 as output
CLR     R16
OUT     shiftPORT, R16       ; Clear PORTA

LOOP:
    ; Turn on LEDs gradually from left to right
	LDI R18, 7
	SBI     shiftPORT, shiftSDI  ; Write 1 for every LED

ON_LOOP:

    CALL    SHO_8                ; Call subroutine to output data
    RCALL   DELAY_500ms          ; Call 500ms delay
    DEC     R18                  ; Decrement counter
    BRNE    ON_LOOP              ; Repeat until all LEDs are on

    ; Turn off LEDs gradually from left to right
	LDI     R18,7
	CBI     shiftPORT, shiftSDI  ; Write 1 for every LED
OFF_LOOP:

    RCALL   SHO_8                ; Call subroutine to output data
    RCALL   DELAY_500ms          ; Call 500ms delay
    DEC     R18                  ; Decrement counter
    BRNE    OFF_LOOP             ; Repeat until all LEDs are off

    RJMP    LOOP                 ; Repeat the entire loop indefinitely



//--------------------------------------------------------
// Subroutines
//--------------------------------------------------------
/* SHO_8
INPUT: R20
OUTPUT: QA to QH on IC595
Description: 
*/
SHO_8:	 	
	LDI	R20,9	
SH_LOOP: 	
	ROL	R17					
	BRCC	BIT_0					
	SBI	shiftPORT,shiftSDI	
	RJMP	NEXT			
BIT_0:		
	CBI	shiftPORT,shiftSDI	
NEXT:		
	SBI	shiftPORT,shiftCLK	
	CBI	shiftPORT,shiftCLK
	DEC	R20			
	BRNE	SH_LOOP
	SBI	shiftPORT,shiftLATCH	
	CBI	shiftPORT,shiftLATCH
RET

/* DELAY_500ms
   Creates a 500ms delay using nested loops.
*/
DELAY_500ms:
    LDI     R16, 50             ; Outer loop count (adjust as needed)
DELAY_OUTER:
    LDI     R17, 255            ; Inner loop count
DELAY_INNER:
    DEC     R17                 ; Decrement inner loop counter
    BRNE    DELAY_INNER         ; Repeat until inner loop completes
    DEC     R16                 ; Decrement outer loop counter
    BRNE    DELAY_OUTER         ; Repeat until outer loop completes
    RET