;Specific code from the Serial, for Albireo interface.
;This file mostly coming from https://github.com/cpcsdk/unofficial_arkos_rom_pack/blob/master/src/Albireo.asm, by Cloudstrife + Pulkomandy from Shinra.
        
        INTERFACE_COUNT = INTERFACE_COUNT + 1
        
TIMEOUT_LOOP = 5000             ;Large to manage slow replay music (25hz, etc.).

; Register base address
ACE_ADDR	EQU 0xfeb0	; IO base address
ACE_ADDRh	EQU 0xfe  	; IO base address
ACE_ADDRl	EQU 0xb0  	; IO base address
; Register offsets
ACE_RBR_OFF	EQU 0     	; Receiver buffer (read, DLAB=0)
ACE_THR_OFF	EQU 0     	; Transmitter holding register (write, DLAB=0)
ACE_IER_OFF	EQU 1     	; Interrupt enable register (DLAB=0)
ACE_IIR_OFF	EQU 2     	; Interrupt identification register (read)
ACE_FCR_OFF	EQU 2     	; FIFO control register (write)
ACE_LCR_OFF	EQU 3     	; Line control register
ACE_MCR_OFF	EQU 4     	; Modem control register
ACE_LSR_OFF	EQU 5     	; Line status register
ACE_MSR_OFF	EQU 6     	; Modem status register
ACE_SCR_OFF	EQU 7     	; Scratch register
ACE_DLL_OFF	EQU 0     	; Divisor latch LSB (DLAB=1)
ACE_DLM_OFF	EQU 1     	; Divisor latch MSB (DLAB=1)
ACE_EFR_OFF	EQU 2     	; Extended functions rgister (LCR=&BF)
; Register address
ACE_RBR		EQU ACE_ADDR+ACE_RBR_OFF
ACE_THR		EQU ACE_ADDR+ACE_THR_OFF
ACE_IER		EQU ACE_ADDR+ACE_IER_OFF
ACE_IIR		EQU ACE_ADDR+ACE_IIR_OFF
ACE_FCR		EQU ACE_ADDR+ACE_FCR_OFF
ACE_LCR		EQU ACE_ADDR+ACE_LCR_OFF
ACE_MCR		EQU ACE_ADDR+ACE_MCR_OFF
ACE_LSR		EQU ACE_ADDR+ACE_LSR_OFF
ACE_MSR		EQU ACE_ADDR+ACE_MSR_OFF
ACE_SCR		EQU ACE_ADDR+ACE_SCR_OFF
ACE_DLL		EQU ACE_ADDR+ACE_DLL_OFF
ACE_DLM		EQU ACE_ADDR+ACE_DLM_OFF
ACE_EFR		EQU ACE_ADDR+ACE_EFR_OFF
; Register address (high/low bits separeted)
ACE_RBRh	EQU ACE_ADDRh
ACE_RBRl	EQU ACE_ADDRl+ACE_RBR_OFF
ACE_THRh	EQU ACE_ADDRh
ACE_THRl	EQU ACE_ADDRl+ACE_THR_OFF
ACE_IERh	EQU ACE_ADDRh
ACE_IERl	EQU ACE_ADDRl+ACE_IER_OFF
ACE_IIRh	EQU ACE_ADDRh
ACE_IIRl	EQU ACE_ADDRl+ACE_IIR_OFF
ACE_FCRh	EQU ACE_ADDRh
ACE_FCRl	EQU ACE_ADDRl+ACE_FCR_OFF
ACE_LCRh	EQU ACE_ADDRh
ACE_LCRl	EQU ACE_ADDRl+ACE_LCR_OFF
ACE_MCRh	EQU ACE_ADDRh
ACE_MCRl	EQU ACE_ADDRl+ACE_MCR_OFF
ACE_LSRh	EQU ACE_ADDRh
ACE_LSRl	EQU ACE_ADDRl+ACE_LSR_OFF
ACE_MSRh	EQU ACE_ADDRh
ACE_MSRl	EQU ACE_ADDRl+ACE_MSR_OFF
ACE_SCRh	EQU ACE_ADDRh
ACE_SCRl	EQU ACE_ADDRl+ACE_SCR_OFF
ACE_DLLh	EQU ACE_ADDRh
ACE_DLLl	EQU ACE_ADDRl+ACE_DLL_OFF
ACE_DLMh	EQU ACE_ADDRh
ACE_DLMl	EQU ACE_ADDRl+ACE_DLM_OFF
ACE_EFRh	EQU ACE_ADDRh
ACE_EFRl	EQU ACE_ADDRl+ACE_EFR_OFF
; Error code
ACE_ERR_NONE        	EQU    0
ACE_ERR_NOT_DETECTED	EQU    1
ACE_ERR_IN_FIFO     	EQU   10
ACE_ERR_OVERRUN     	EQU   20
ACE_ERR_PARITY      	EQU   21
ACE_ERR_FRAMING     	EQU   22
ACE_ERR_BREAK       	EQU   23
; Interrupt Enable Register (IER) bits
ACE_IER_ERBI 	EQU    0
ACE_IER_ETBEI	EQU    1
ACE_IER_ELSE 	EQU    2
ACE_IER_EDSSI	EQU    3
; Line Control Register (LCR) bits
ACE_LCR_WLS0  	EQU    0
ACE_LCR_WLS1  	EQU    1
ACE_LCR_STB   	EQU    2
ACE_LCR_PEN   	EQU    3
ACE_LCR_EPS   	EQU    4
ACE_LCR_STICKP	EQU    5
ACE_LCR_BREAK 	EQU    6
ACE_LCR_DLAB  	EQU    7
; Line Status Register (LSR) bits
ACE_LSR_DR        	EQU    0
ACE_LSR_OE        	EQU    1
ACE_LSR_PE        	EQU    2
ACE_LSR_FE        	EQU    3
ACE_LSR_BI        	EQU    4
ACE_LSR_THRE      	EQU    5
ACE_LSR_TEMT      	EQU    6
ACE_LSR_RCVRFIOERR	EQU    7
; Modem Control Register (MCR) bits
ACE_MCR_DTR 	EQU    0
ACE_MCR_RTS 	EQU    1
ACE_MCR_OUT1	EQU    2
ACE_MCR_OUT2	EQU    3
ACE_MCR_LOOP	EQU    4
ACE_MCR_AFE 	EQU    5

; On albireo board, these control the interrupt routing
ALB_INT     EQU ACE_MCR_OUT1
ALB_NMI     EQU ACE_MCR_OUT2

; Anything will do.
ACE_MAGIC_NUMBER    EQU #61

;Initializes the card. May clear the buffer.
;OUT:   Carry = 1 = OK. 0 if undetected or a problem occurred.
Initialize:
        ; SIO_DETECT_INTERFACE
        LD  BC,ACE_SCR
        LD  A,ACE_MAGIC_NUMBER
        OUT (C),A
        IN  A,(C)
        XOR ACE_MAGIC_NUMBER    ; Clear carry flag
        jp NZ,Initialize_Error  ; Not found!
    
        ; Clear DLAB (to access configuration registers)
        LD  BC,ACE_LCR  ; 4µs -
        IN  A,(C)       ; 4µs - S Z P/V
        RES ACE_LCR_DLAB,A  ; Reset DLAB bit to select read/write buffer register - 2µs -
        OUT (C),A       ; 4µs -
    
        ; Disable interupts
        LD  BC,ACE_IER
        OUT (C),0
    
        ; Disable INT and NMI
        LD  BC,ACE_MCR
        IN  A,(C)
        SET ALB_INT,A
        SET ALB_NMI,A
        OUT (C),A
    
        ; Set baudrate.
        LD  HL,13       ;13 for 115200 bauds, 1 for 1500000 (!) bauds.
        LD  BC,ACE_LCR  ; 4µs -
        IN  A,(C)       ; 4µs - S Z P/V
        SET ACE_LCR_DLAB,A  ; Set DLAB for enable write to divisor register - 2µs -
        OUT (C),A       ; 4µs -
        LD  BC,ACE_DLM  ; 4µs -
        OUT (C),H       ; 4µs -
        LD  BC,ACE_DLL  ; 4µs -
        OUT (C),L       ; 4µs -
SIO_CLEAR_DLAB:
        LD  BC,ACE_LCR  ; 4µs -
        IN  A,(C)       ; 4µs - S Z P/V
        RES ACE_LCR_DLAB,A  ; Reset DLAB bit to select read/write buffer register - 2µs -
        OUT (C),A       ; 4µs -
    
        ; Set 8N1
        LD  BC,ACE_LCR
        IN  A,(C)
        AND %11000000   ; We keep actual Divisor register slection and Break if they are activated.
        OR  %00000011
        OUT (C),A
    
        ; Activate and clear FIFO (up to 24 bytes before we try to stop the PC
        ; from sending data).
        LD  BC,ACE_FCR
        LD  A,%10000111
        OUT (C),A
    
        ; Disable loopback (just in case)
        LD BC,ACE_MCR
        OUT (C),0
                        
        scf
        ret

Initialize_Error:
        or a                    ;Shouldn't be useful, remove this method if OK. TODO ***
        ret
        

        
;Waits for a byte in the buffer.
;It waits indefinitely, but after a while, the PSG sound is stopped.
;MOD:   AF, BC.
WaitForByteWithTimeout:
        push hl
        
WaitForByteWithTimeout_Restart:
        ld hl,TIMEOUT_LOOP
        ld bc,ACE_LSR
WaitForByteWithTimeout_Loop:
        in a,(c)
        rra
        jr c,WaitForByteWithTimeout_End
        
        ;Byte not ready yet. Loop.
        dec hl
        ld a,l
        or h
        jr nz,WaitForByteWithTimeout_Loop
        ;Timeout. Stops the sound.
        call StopSounds
        jr WaitForByteWithTimeout_Restart
WaitForByteWithTimeout_End:
        pop hl
        ret

;Reads the byte which MUST be present in the buffer.
;OUT:   A = the byte.
ReadPresentByte:
        ld bc,ACE_ADDRh * 256 + ACE_RBRl
        in a,(c)
        ret