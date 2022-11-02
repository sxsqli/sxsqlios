; sxsqlios boot
; TAB=4

CYLS	EQU		10					; CYLS=10,读10个柱面（共80个柱面）

		ORG		0x7c00				; 指明程序装载地址

; 以下记述用于标准FTA12格式软盘

		JMP		entry					; jump
		DB		0x90					;
		DB		"SXSQLIOS"		; 启动区名称，可任意（8字节）
		DW		512						; 每个扇区（sector）的大小（必须为512字节）
		DB		1							; 簇（cluster）的大小（必须为1个扇区）
		DW		1							; FAT的起始位置（一般从第1个扇区开始）
		DB		2							; FAT的个数（必须为2）
		DW		224						; 根目录的大小（一般设置成224项）
		DW		2880					; 该磁盘的大小（必须是2880扇区）
		DB		0xf0					; 磁盘的种类（必须是0xf0）
		DW		9							; FAT的长度（必须是9扇区）
		DW		18						; 1个磁道（track）有几个扇区（必须是18）
		DW		2							; 磁头数（必须是2）
		DD		0							; 不使用分区（必须是0）
		DD		2880					; 重写一边磁盘大小
		DB		0,0,0x29			; 意义不明，固定
		DD		0xffffffff		; （可能是）卷标号码
		DB		"SXSQLIOS   "	; 磁盘名称（11字节）
		DB		"FAT12   "		; 磁盘格式名称（8字节）
		RESB	18						; 空出18字节

; 启动区程序本体

entry:
		MOV		AX,0					; 初始化寄存器
		MOV		SS,AX					; 堆栈段寄存器
		MOV		SP,0x7c00			; 堆栈指针
		MOV		DS,AX					; 数据段寄存器

; 开始读磁盘

		MOV		AX,0x0800		; 16位模式的段寄存器ES
		MOV		ES,AX			; 16位模式的段寄存器ES
		MOV		CH,0			; 柱面0
		MOV		DH,0			; 磁头0
		MOV		CL,1			; 扇区1
readloop:
		MOV		SI,0					; 初始化试错计数
retry:
		MOV		AH,0x02				; INT 0x13模式参数，0x02表示读盘模式，0x03表示写盘
		MOV		AL,1					; INT 0x13一次读/写多少个扇区
		MOV		BX,0					; ES:BX，目标地址
		MOV		DL,0x00				; INT 0x13驱动器参数，A驱动器
		INT		0x13					; 调用磁盘BIOS
		JNC		next					; jump if not carry，进位标志为零则跳转（INT 0x13返回值FLGCS.CF==0为没有出错）
		ADD		SI,1					; 试错计数加1
		CMP		SI,5
		JAE		error					; jump if above or equal
		MOV		AH,0x00				; INT 0x13模式参数，0x00重置驱动器
		MOV		DL,0x00				; INT 0x13驱动器参数，A驱动器
		INT		0x13					; 调用磁盘BIOS
		JMP		retry					; jump
next:
		MOV		AX,ES					; ES+=0x0020
		ADD		AX,0x0020			; ES+=0x0020
		MOV		ES,AX					; ES+=0x0020
		ADD		CL,1					; 扇区加1
		CMP		CL,18
		JBE		readloop			; jump if below or equal
		MOV		CL,1					; 1扇区
		ADD		DH,1					; 磁头加1
		CMP		DH,2
		JB		readloop			; jump if below
		MOV		DH,0					; 0磁头
		ADD		CH,1					; 柱面加1
		CMP		CH,CYLS
		JB		readloop			; jump if below

; 读取完成，打印信息

		MOV		SI,finish_msg
		CALL	putloop

; 跳转操作系统

		MOV		[0X0ff0],CH;
		JMP		0xc400
error:
		MOV		SI,error_msg
		CALL	putloop
fin:
		HLT									; 处理器暂停
		JMP		fin
putloop:
		MOV		AL,[SI]
		ADD		SI,1
		CMP		AL,0
		JE		over
		MOV		AH,0x0e
		MOV		BX,15
		INT		0x10
		JMP		putloop
over:
		RET
error_msg:
		DB		0x0d, 0x0a
		DB		"Disk load error"
		DB		0x0d, 0x0a
		DB		0
finish_msg:
		DB		0x0d, 0x0a
		DB		"Disk load finish"
		DB		0x0d, 0x0a
		DB		0

		TIMES 510-($-$$) DB 0 	; 不够510字节的用0填充
		DW 		0xAA55
