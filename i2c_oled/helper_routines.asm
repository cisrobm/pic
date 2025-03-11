; ~1s delay @ 8MHz
Delay1s
	clrf	globalvar1
	clrf	globalvar2
	clrf	loopctr
	bsf		loopctr,4	; loopctr = 16
_Delay1s1
	decfsz	globalvar1,f
	goto	_Delay1s1
	decfsz	globalvar2,f
	goto	_Delay1s1
	decfsz	loopctr,f
	goto	_Delay1s1
	return

; read only the lower byte from flash address
; return in w
; variables affected: none
FlashRead
	bsf		STATUS,RP0
	bsf		STATUS,RP1		; bank 3
	bsf		EECON1,EEPGD	; select program memory
	bsf		EECON1,RD		; initiate read
	nop
	nop
	bcf		STATUS,RP0		; bank 2
	movf	EEDAT,w			; get read value from EEDAT register
	bcf		STATUS,RP1		; bank 0
	return

; multiply value in addrptra by 6 (shift & add)
; affected variables: addrptra (return value), addrptrb(trashed)
Times6
	bcf		STATUS,C		; clear carry
	rlf		addrptra,f		; rotate low byte first
	rlf		addrptra+1,f	; then the high byte, carry gets taken care of automatically
	movf	addrptra+1,w
	movf	addrptra,w
; addrptra has been multiplied by two
	copy16	addrptra, addrptrb
	bcf		STATUS,C
	rlf		addrptra,f	; do another rotate operation on addrptra
	rlf		addrptra+1,f
; now we have the *2 value in addrptrb and the *4 value in addrptra
	call	AddAddress
; addrptra has been multiplied by 6
	return

; add addrptra and addrptrb
; result in addrptra
AddAddress
	movf	addrptrb+1,w
	addwf	addrptra+1,f
	movf	addrptrb,w
	addwf	addrptra,f
	btfsc	STATUS,C
	incf	addrptra+1,f
	return
