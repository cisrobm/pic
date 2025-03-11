	list p=p16f690
	list b=4
	#include <p16f690.inc>
        errorlevel -1302
        radix dec

;  __config _FCMEN_OFF& _IESO_OFF& _MCLRE_OFF& _WDTE_OFF& _INTOSCIO & _CPD_OFF & _CP_OFF & _BOR_ON & _PWRTE_ON

	config	FOSC = INTRCIO, WDTE = OFF, PWRTE = ON, MCLRE = OFF
	config	BOREN = OFF, IESO = OFF, FCMEN = OFF


;  _FCMEN_OFF           ; -- fail safe clock monitor enable off
;  _IESO_OFF            ; -- int/ext switch over enable off
;  _BOR_ON              ; default, brown out reset on
;  _CPD_OFF             ; default, eeprom protection off
;  _CP_OFF              ; default, program code protection off
;  _MCLRE_OFF            ; -- use MCLR pin as digital input
;  _PWRTE_OFF           ; default, power up timer off
;  _WDT_OFF             ; -- watch dog timer off
;  _INTOSCIO            ; -- internal osc, OSC1 and OSC2 I/O

; choose display type here
SSD1306_OLED_64 = 0		; 128x64
SSD1306_OLED_32 = 0		; 128x32
SH1106_OLED_64 = 1		; 128x64

; define scl and sda port and pins
i2c_tris	equ TRISC
i2c_port	equ PORTC
sclpin		equ RC0
sdapin		equ RC1
; user config ends here

	if (SSD1306_OLED_64 && SSD1306_OLED_32 || SSD1306_OLED_64 && SH1106_OLED_64 || SSD1306_OLED_32 && SH1106_OLED_64)
		error "Only one OLED Type can be defined"
	endif

	if SSD1306_OLED_64
SSD1306_LINES = 7	; 3 for 128x32, 7 for 128x64
SSD1306_FILL_LOOPS = 4
	endif

	if SSD1306_OLED_32
SSD1306_LINES = 3
SSD1306_FILL_LOOPS = 2
	endif

; variables
	cblock  0x20
	tmpvar1
	tmpvar2
	tmpvar3
	tmpvar5
	endc
    
	cblock  0x70
	loopctr                         ; i2c_write()
	tmpvar4                         ; i2c_write()
	addrptra:2
	addrptrb:2
	addrptrc:2
	addrptrd:2
	globalvar1
	globalvar2
	globalvar3
	globalvar4
	line			; these keep track of the current
	col				; line and column
	endc
	
	#include "helper_macros.asm"

; print a single char to the OLED
putchar macro param
	movlw	param
	call	PutC
	endm

; output a string to the OLED	
putstring macro param
	movlw	high param
	movwf	addrptra+1
	movlw	low param
	movwf	addrptra
	call	PutS
	endm

; reset vector
        org     0x000
Reset
        clrf    STATUS		; bank 0 and IRP = 0
        goto    Setup
; interrupt vector
        org     0x004
IRQ
		nop

Setup
	clrf	INTCON
	bsf     STATUS,RP1		; bank 2
	clrf    ANSEL           ; turn off analog pin functions
	clrf    ANSELH
	bcf     STATUS,RP1
	bsf     STATUS,RP0		; bank 1
	
	movlw   b'01110000'     ; setup INTOSC for 8MHz
	movwf   OSCCON
	btfss   OSCCON,HTS      ; osc stable? yes, skip, else
	goto    $-1             ; test again
	
	clrf    TRISC           ; RC5..RC0 all outputs
	clrf    TRISB           ; RB7..RB4 all outputs
	clrf    TRISA           ; all outputs, except RA3
	bcf     STATUS,RP0      ; bank 0
	clrf    PORTC
	clrf    PORTB
	bsf		PORTB,RB7		; turn off LED
	
	;  setup I2C pins, scl = RC0, sda = RC1
	bsf     STATUS,RP0
	bsf     i2c_tris,sclpin ; make scl pin input
	bsf     i2c_tris,sdapin ; make sda pin input
	goto	Main

	#include "i2c.asm"

OLEDCmd
	bsf		STATUS,RP0
	call	i2c_start
	movlw	0x78
	call	i2c_write
	movlw	0x00		; command
	goto	i2c_write

OLEDData
	call	i2c_start
	movlw	0x78
	call	i2c_write
	movlw	0x40		; data
	goto	i2c_write

	if (SSD1306_OLED_64 || SSD1306_OLED_32)
; change address to write next character
; at col, line
SSD1306Goto
	call	OLEDCmd
	i2c(0x21)		; set column command
	movf	col,w
	call	i2c_write
	i2c(127)
	call	i2c_stop
	call	OLEDCmd
	i2c(0x22)		; set page command
	movf	line,w
	call	i2c_write
	i2c(SSD1306_LINES)
	goto	i2c_stop

; for 128x32 and 128x64 SSD1306 OLEDs
SSD1306Init
	call OLEDCmd
	i2c(0xAE)
	if SSD1306_OLED_64
	i2c(0xD4)	; D5 for 128x32, D4 for 64
	else
	i2c(0xD5)
	endif
	i2c(0xF0)
	i2c(0xA8)
	if SSD1306_OLED_64
	i2c(0x3F)	; 1F for 128x32, 3F for 64
	else
	i2c(0x1F)
	endif
	i2c(0xD3)
	i2c(0x00)	; this sets the vertical shift
	i2c(0x40)
	i2c(0x8D)
	i2c(0x14)
	i2c(0xA1)
	i2c(0xC8)
	i2c(0xDA)
	if SSD1306_OLED_64
	i2c(0x12)	; 02 for 128x32, 12 for 64
	else
	i2c(0x02)
	endif
	i2c(0x81)
	i2c(0x8F)
	i2c(0xD9)
	i2c(0xF1)
	i2c(0xDB)
	i2c(0x40)
	i2c(0xA4)
	i2c(0xA6)
	i2c(0x20)
	i2c(0x00)
	i2c(0xAF)
	goto i2c_stop

; clear the display
SSD1306Clear
	clrf	line
	clrf	col
	call	SSD1306Goto
	call	OLEDData
	clrf	tmpvar1
	movlw	SSD1306_FILL_LOOPS
	movwf	tmpvar2
_SSD1306Clear1
	i2c(0x00)
	decfsz	tmpvar1,f
	goto	_SSD1306Clear1
	decfsz	tmpvar2,f
	goto	_SSD1306Clear1
	goto	i2c_stop

	endif

; for SH1106
SH1106Init
	call	SH1106Clear
	call	OLEDCmd
	i2c(0xaf)			; turn display on
	i2c(0x02)			; set lower nibble column address to 2
	i2c(0x10)			; set upper   "      "      "     to 0
	i2c(0xb0)			; page address
	i2c(0xa1)			; flip horizontal a0/a1
	i2c(0xc8)			; flip vertical c0/c8
	i2c(0x81)			; set brightness
	i2c(0x00)			; 0x00 (dimmest) - 0xff (brightest)
	goto	i2c_stop

SH1106Goto
	call	OLEDCmd
	movlw	0xb0		; select page (i.e. line)
	iorwf	line,w
	call	i2c_write
	movlw	0x02		; column low nibble
	iorwf	col,w
	call	i2c_write
	i2c(0x10)			; column high nibble
	goto	i2c_stop

SH1106Clear
	clrf	globalvar1
_SH1106Clear1
	call	OLEDCmd
	movlw	0xb0
	iorwf	globalvar1,w	; set page command
	call	i2c_write
	i2c(0x00)
	i2c(0x10)
	call	i2c_stop
	movlw	132			; 132 columns
	movwf	globalvar2
	call	OLEDData
_SH1106Clear2
	i2c(0x00)
	decfsz	globalvar2,f
	goto	_SH1106Clear2	; next column
	call	i2c_stop
	incf	globalvar1,f
	movf	globalvar1,w
	addlw	248				; 256-248=8 pages
	btfss	STATUS,C
	goto	_SH1106Clear1	; next page
	clrf	line
	clrf	col
	return

; main loop
Main
	call	SH1106Init
	clrf	globalvar4
	bsf		globalvar4,3	; globalvar4 = 8
_MMain
	putstring	HelloString
	clrf	col
	incf	line,f
	call	SH1106Goto
	decfsz	globalvar4,f
	goto	_MMain

_Main
	goto    _Main               ; infinite loop

; write a two-digit hex number to the screen at col,line
; affected variables: globalvar1
PrintByte
	movwf	tmpvar3
	swapf	tmpvar3,w
	andlw	0x0f
	call	PrintDigit
	movf	tmpvar3,w
	andlw	0x0f
	call	PrintDigit
	movf	tmpvar3,w
	return

; print a space character
PrintSpace
	movwf	globalvar1		; save w
	call	OLEDData
	i2c(0)
	i2c(0)
	i2c(0)
	i2c(0)
	i2c(0)
	i2c(0)
	movf	globalvar1,w
	goto	i2c_stop


; write a single hex digit to the screen
; affected variables: loopctr, tmpvar1, tmpvar2
PrintDigit
	movwf	tmpvar2
	movwf	loopctr
	bcf		STATUS,RP0
	bsf		STATUS,RP1	; bank 2
	movlw	high hexchars
	movwf	EEADRH
	movlw	low hexchars
	movwf	EEADR
	movlw	6
; increment address
_PrintDigit2
	addwf	EEADR,f
	decfsz	loopctr,f
	goto	_PrintDigit2
	bcf		STATUS,RP1		; bank 0
; write actual data
	call	OLEDData
	movlw	6				; loop 6 times
	movwf	tmpvar1
NumLoop
	call	FlashRead
	call	i2c_write
	bsf		STATUS,RP1		; bank 2
	incf	EEADR,f			; next byte
	bcf		STATUS,RP1		; bank 0
	decfsz	tmpvar1,f
	goto	NumLoop
	movf	tmpvar2,w
	return

; string address is in addrptra
; affected variables:
; addrptra, addrptrb, addrptrc
; globalvar1 - loop counter
; globalvar2 - temp. storage
PutS
	bcf		STATUS,RP0
	bsf		STATUS,RP1	; bank 2
	copy16	addrptra, addrptrc	; save string address in addrptrc
	toeeadr	addrptrc	; write it to the EEADR register
	call	FlashRead	; read first byte, the length of the string
	movwf	globalvar1	; store it, it will be our loop counter
	bsf		STATUS,RP1	; bank 2
_PutS1
	incf16	addrptrc	; increment address
	toeeadr	addrptrc	; copy addrptrc to EEADR register
	call	FlashRead	; read next char into W
	call	PutC		; print it
	bsf		STATUS,RP1	; bank 2
	decfsz	globalvar1,f
	goto	_PutS1
	return

; char in w
; affected vars: addrptra, addrptrb, tmpvar1
PutC
	clrf	addrptra+1		; clear high byte
	movwf	addrptra		; ASCII code in addrptra
	movlw	0x20			; subtract 0x20 from it because our
	subwf	addrptra,f		; font doesn't have the first 32 characters
	call	Times6			; multiply by char width to get the offset
	movlw	high font6x8	; store font address in addrptrb
	movwf	addrptrb+1
	movlw	low	font6x8
	movwf	addrptrb
	call	AddAddress		; add addrptra and b to get address of char
; addrptra now points to start of character in font array
	bcf		STATUS,RP0
	bsf		STATUS,RP1		; bank 2
	toeeadr addrptra
	bcf		STATUS,RP1
	bsf		STATUS,RP0		; bank 1
	call	OLEDData
	bcf		STATUS,RP0
	movlw	6				; loop 6 times
	movwf	tmpvar1
_PutC1
	call	FlashRead
	bsf		STATUS,RP0
	call	i2c_write
	bcf		STATUS,RP0
	bsf		STATUS,RP1		; bank 2
	incf	EEADR,f			; next byte
	bcf		STATUS,RP1		; bank 0
	decfsz	tmpvar1,f
	goto	_PutC1
	movlw	6
	addwf	col,f
	return
	
	#include "helper_routines.asm"

	org 0xd00
	
HelloString
	de		d'13',"Hello, World!"

	#include "font_hexchars.inc"
	#include "font.inc"

	end
