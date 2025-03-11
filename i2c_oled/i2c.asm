;  bit banging I2C subroutines
;  these always assume to be in bank 1

;  define scl and sda port and pins
;i2c_tris equ    TRISC
;i2c_port equ    PORTC
;sclpin  equ     RC0
;sdapin  equ     RC1

; macros to make the code more readable
i2c	macro param
	movlw param
	call i2c_write
	endm

scl_hi macro
	bsf		i2c_tris,sclpin	; set as input
	endm
	
scl_lo macro
	bcf		i2c_tris,sclpin ; set as output
	endm

sda_hi macro
	bsf		i2c_tris,sdapin	; set as input
	endm

sda_lo macro
	bcf		i2c_tris,sdapin	; set as output
	endm

delay macro
	call _dly_ret	; waste 4 cycles, see http://picprojects.org.uk/projects/pictips.htm#Waste%20four
	endm

i2c_stop
	sda_lo
	delay
	scl_hi
	delay
	sda_hi
	delay
	return

i2c_start
	sda_hi
	delay
	scl_hi
	delay
	sda_lo
	delay
	scl_lo
	delay
	return

; transmit byte in w
; affected variables: loopctr, tmpvar4
i2c_write
	clrf	loopctr
	bsf		loopctr,3	; loopctr = 8
	movwf	tmpvar4		; store byte in tmpvar4
_i2c_write1
	movf	i2c_tris,w	; load tristate register into w
	iorlw	1<<sdapin	; set sda bit high in w
	btfss	tmpvar4,7	; test data bit
	xorlw	1<<sdapin	; clear bit in w if it tested 0
	movwf	i2c_tris	; output to port
	delay
	scl_hi
	delay
	rlf		tmpvar4,f	; rotate left for next bit
	scl_lo
	delay
	decfsz	loopctr,f
	goto	_i2c_write1
	sda_hi
	scl_hi
	delay
	; could read ACK here, OLED works fine without
	scl_lo
_dly_ret
	return
