;Source code from the Serial, using CPC/Mini Booster interface.
        
        INTERFACE_COUNT = INTERFACE_COUNT + 1

TIMEOUT_LOOP = 5000             ;Large to manage slow replay music (25hz, etc.).

;Initializes the card. May clear the buffer.
;OUT:   Carry = 1 = OK. 0 if undetected or a problem occurred.
Initialize:
        ;Is the card present?
        ld bc,#ff00
	in a,(c)
	cp 170
	jr nz,Initialize_Failure
	inc c
	in a,(c)
	cp 85           ;CPC Booster.
	jr z,Initialize_CPCBooster
        cp 238          ;Mini Booster.
        jr z,Initialize_MiniBooster
Initialize_Failure:
        or a
        ret
Initialize_CPCBooster:
	ld a,#05                ;Sets Baudrate to 115200 (5). 2 = 230400bps
        jr Initialize_Common
Initialize_MiniBooster:
	ld a,#07                ;Sets Baudrate to 115200 (7). 3 = 230400bps
Initialize_Common:
        ld c,#04
	out (c),c
	out (c),a
        
        ld c,#07		;Asynchronous, no Parity, 1 bit stop, 8 bits carac.
	ld a,%00000110
	out (c),c
	out (c),a

	ld c,#0b		;Enables buffer.
	in a,(c)
	set 4,a
	out (c),a

	ld c,#1c		;Resets buffer.
	xor a
	out (c),a
        
        scf
        ret

;Waits for a byte in the buffer.
;It waits indefinitely, but after a while, the PSG sound is stopped.
;MOD:   AF, BC.
WaitForByteWithTimeout:
        push hl
        
WaitForByteWithTimeout_Restart:
        ld hl,TIMEOUT_LOOP
        ld bc,#ff1c
WaitForByteWithTimeout_Loop:
        in a,(c)
        or a
        jr nz,WaitForByteWithTimeout_End
        
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
        ld bc,#ff1d
        in a,(c)
        ret