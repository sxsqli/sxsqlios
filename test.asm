; test
; TAB=4

        ORG		0xc400			; 

		MOV		SI,msg
		CALL	putloop
fin:
		HLT						; 处理器暂停
		JMP		fin
putloop:
		MOV		AL,[SI]
		ADD		SI,1			; 
		CMP		AL,0
		JE		over
		MOV		AH,0x0e			; 
		MOV		BX,15			; 
		INT		0x10			; 
		JMP		putloop
over:
		RET						; 
msg:
		DB		0x0d, 0x0a		; 
		DB		"just for test."
		DB		0x0d			; 
		DB		0