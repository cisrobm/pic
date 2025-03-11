; copy address from RAM to EEPROM register
toeeadr macro param
	movf	param+1,w
	movwf	EEADRH
	movf	param,w
	movwf	EEADR
	endm

; copy address from EEPROM register to RAM
fromeeadr macro param
	movf	EEADRH,w
	movwf	param+1
	movf	EEADR,w
	movwf	param
	endm
	
; increment a 16 bit value
incf16 macro param
	incf	param,f
	btfsc	STATUS,Z	; check for overFlow
	incf	param+1,f
	endm

; copy a 16 bit value	
copy16 macro src, dst
	movf	src+1,w
	movwf	dst+1
	movf	src,w
	movwf	dst
	endm

; debugging aid: light up led connected to RB7 (active low) and stop the program
dbgled macro
	bcf		STATUS,RP0
	bcf		STATUS,RP1
	bcf		PORTB,RB7
	goto	$
	endm
