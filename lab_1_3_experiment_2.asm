/* OBJECTIVES : 
    Display the number of time a button is pressed on a LCD
*/

/*
CONNECTING COMPONENTS:
PORT A: LCD
PORT B: BAR LED
PINC0: BUTTON
*/	
.ORG 0
.EQU LCD_PORT=PORTA       ; Define LCD port
.EQU LCD_DDR=DDRA         ; Define LCD data direction
.EQU LED_PORT=PORTB       ; Define LED port
.EQU LED_DDR=DDRB         ; Define LED data direction
.EQU RS=0                 ; Register Select pin
.EQU RW=1                 ; Read/Write pin
.EQU EN=2                 ; Enable pin

    RJMP MAIN             ; Jump to main program
    .ORG 0X40             ; Origin for other data

// MAIN ----------------------------------
MAIN:
    LDI R16, LOW(RAMEND)  ; Load the low address of RAMEND into R16
    OUT SPL, R16          ; Output the low byte to the stack pointer low
    LDI R16, HIGH(RAMEND) ; Load the high address of RAMEND into R16
    OUT SPH, R16          ; Output the high byte to the stack pointer high

// Declare LED PORT as OUTPUT and initialize it to 0 to turn off the LED.
LDI R16, 0xFF
OUT LED_DDR, R16
LDI R16, 0x00
OUT LED_PORT
// Declare PC0 as input with a pull-up resistor enabled.
LDI R16, 0x00
OUT DDRC, R16
SBI PORTC, 0

/*
Connect port A to the LCD: RS=PA0, RW=PA1, EN=PA2, Data[4:7] = PA4:PA7
=> Declare PA0, PA1, PA2, PA4, PA5, PA6, PA7 as output, initialize the values as follows: Data = 0, RS=0, RW=1, EN=0.
*/	
LDI R16, (1<<RS)|(1<<RW)|(1<<EN)|0xF0
OUT LCD_DDR, R16

LDI R16, (1<<RW)
OUT LCD_PORT, R16

// Call the subroutine to initialize power (POWERUP_LCD_4BIT) for 4-bit LCD mode. Refer to the curriculum for details. If this subroutine is not called, the LCD will not display anything.
CALL POWERUP_LCD_4BIT
// Call the subroutine to configure the LCD.
CALL INIT_LCD_4BIT
// Call the command to set the DDRAM pointer to 0x00.
LDI R16, 0x80
CALL WRITE_COMMAND

    ; R18 stores the number of times the button is pressed
    LDI R18, 0
    ; R19 is a constant for converting to ASCII; note that the count from 0, 1, ... displayed on the LCD needs to be incremented by 48 (decimal).
    LDI R19, 48 
;---------------------------------------------------------	
; Write code to print the string LINE1 on the LCD
;---------------------------------------------------------

// LOOP ----------------------------------------------------
LOOP:
    // Write the command to set the DDRAM address to 0x40, display the number of button presses on the second line
    ...	

    RCALL CHECK_BUTTON 
    CALL NUM_8_BIT_TO_BCD

    CPI R22, 0
    BRNE HANG_TRAM // Hundreds place
    CPI R21, 0
    BRNE HANG_CHUC //Tens place
    CPI R20, 0
    BRNE HANG_DONVI  //Ones place

HANG_TRAM:
    MOV R17, R22
    ADD R17, R19
    CALL WRITE_DATA

HANG_CHUC:
    MOV R17, R21
    ADD R17, R19
    CALL WRITE_DATA

HANG_DONVI:
    MOV R17, R20
    ADD R17, R19
    CALL WRITE_DATA
    RJMP LOOP

;------------------------------------------------------------
; INPUT: PINC.0
; OUTPUT: R17, R18 is the count of button presses
; DESCRIPTION:
;------------------------------------------------------------
CHECK_BUTTON:
BUTTON_PRESSED:             ; BUTTON PRESS
    SBIC PINC, 0            ; Skip if button not pressed
    RJMP PRESSED_BUTTON     ; Keep checking button press
    LDI R16, 250            ; DELAY 10MS
    RCALL DELAY_US          ; Call delay subroutine
    SBIC PINC, 0            ; Skip if button not pressed
    RJMP BUTTON_PRESSED     ; Keep checking button press

BUTTON_RELEASED:            ; BUTTON RELEASE
    SBIS PINC, 0            ; Skip if button pressed
    RJMP BUTTON_RELEASED    ; Keep checking button release
    LDI R16, 250            ; DELAY 25MS
    RCALL DELAY_US          ; Call delay subroutine
    SBIS PINC, 0            ; Skip if button pressed
    RJMP BUTTON_RELEASED    ; Keep checking button release

    ; Process when button is pressed
    INC R18                 ; Increment the press count
    OUT LED_PORT, R18       ; Output the count to LED port
    MOV R17, R18            ; Move the count to R17
    RCALL NUM_8_BIT_TO_BCD  ; Convert to BCD
    RET

;------------------------------------------------------------
; INPUT: R17
; OUTPUT: R22: hundreds place, R21: tens place, R20: units place
; DESCRIPTION: Get 3 BCD digits from R17
;------------------------------------------------------------
NUM_8_BIT_TO_BCD: 
    CLR R20                 ; Clear units place
    CLR R21                 ; Clear tens place
    CLR R22                 ; Clear hundreds place

    LDI R16, 10             ; Load divisor (10)
    RCALL DIV10             ; Call division subroutine
    MOV R20, R16            ; R20: units place
    LDI R16, 10             ; Load divisor (10)
    RCALL DIV10             ; Call division subroutine
    MOV R21, R16            ; R21: tens place
    MOV R22, R17            ; R22: hundreds place
    RET

;------------------------------------------------------------
; INPUT: R17, R16 = 10
; OUTPUT: R16: remainder, R17: quotient
; DESCRIPTION: Divide R17 by R16
;------------------------------------------------------------
DIV10: 
    CLR R15                 ; R15: quotient
SUBSTRACT:
    SUB R17, R16            ; Subtract R16 from R17
    BRCS RINT_RESULT      ; Branch if carry set (not divisible)
    INC R15                 ; Increment quotient
    RJMP SUBSTRACT      ; Continue subtracting
PRINT_RESULT:
    ADD R17, R16            ; Restore the remainder
    MOV R16, R17            ; R16: remainder
    MOV R17, R15            ; R17: quotient
    RET

;------------------------------------------------------------
POWERUP_LCD_4BIT:
    LDI R16, 250            ; Load delay value
    RCALL DELAY_US          ; Call delay subroutine
    LDI R16, 250            ; Load delay value
    RCALL DELAY_US          ; Call delay subroutine
    LDI R17, $30            ; Command to initialize LCD in 8-bit mode
    RCALL OUT_COMMAND       ; Call to output command
    LDI R16, 50             ; Load delay value
    RCALL DELAY_US          ; Call delay subroutine
    LDI R17, $30            ; Command to initialize LCD in 8-bit mode again
    RCALL OUT_COMMAND       ; Call to output command
    LDI R16, 2              ; Load delay value
    RCALL DELAY_US          ; Call delay subroutine
    LDI R17, $20            ; Command for 4-bit mode
    RCALL OUT_COMMAND       ; Call to output command
    RET

INIT_LCD_4BIT:
    LDI R17, $28            ; Command for 4-bit mode, 2 lines, 5x8 dots
    CALL WRITE_COMMAND      ; Call to write command
    LDI R17, $01            ; Command to clear the display
    CALL WRITE_COMMAND      ; Call to write command
    LDI R17, $0C            ; Command to turn on display, cursor off
    CALL WRITE_COMMAND      ; Call to write command
    LDI R17, $06            ; Command to shift cursor right
    CALL WRITE_COMMAND      ; Call to write command
    RET

WRITE_COMMAND: 
    PUSH R17                ; Save R17 on the stack
    ANDI R17, $F0          ; Output the first 4 bits
    RCALL OUT_COMMAND       ; Call to output command
    POP R17                 ; Restore R17 from the stack
    SWAP R17                ; Swap nibbles
    ANDI R17, $F0          ; Output the last 4 bits
    RCALL OUT_COMMAND       ; Call to output command
    RET

WRITE_DATA: 
    PUSH R17                ; Save R17 on the stack
    ANDI R17, $F0          ; Output first 4 bits
    RCALL OUT_DATA          ; Call to output data
    POP R17                 ; Restore R17 from the stack
    SWAP R17                ; Swap nibbles
    ANDI R17, $F0          ; Output last 4 bits
    RCALL OUT_DATA          ; Call to output data
    RET

OUT_COMMAND:
    OUT LCD_PORT, R17      ; Output command to the LCD port
    CBI LCD_PORT, RS       ; Clear RS
    CBI LCD_PORT, RW       ; Clear RW
    SBI LCD_PORT, EN       ; Set Enable
    NOP                     ; No operation
    CBI LCD_PORT, EN       ; Clear Enable
    LDI R16, 20            ; Load delay
    CALL DELAY_US          ; Call delay subroutine
    RET

OUT_DATA:
    OUT LCD_PORT, R17      ; Output data to the LCD port
    SBI LCD_PORT, RS       ; Set RS for data
    CBI LCD_PORT, RW       ; Clear RW
    SBI LCD_PORT, EN       ; Set Enable
    NOP                     ; No operation
    CBI LCD_PORT, EN       ; Clear Enable
    LDI R16, 20            ; Load delay
    CALL DELAY_US          ; Call delay subroutine
    RET

DELAY_US:                  ; DELAY R16 * 100 MICROSECONDS
    MOV R15, R16           ; Copy R16 to R15 for looping
    LDI R16, 200           ; Load a constant for the delay
L1: MOV R14, R16           ; Copy delay value to R14
L2: DEC R14                ; Decrement R14
    NOP                     ; No operation
    BRNE L2                ; Branch if not zero
    DEC R15                ; Decrement R15
    BRNE L1                ; Branch if not zero
    RET

LINE1:  .DB "NUMBER OF BUTTON PRESSES",$00
