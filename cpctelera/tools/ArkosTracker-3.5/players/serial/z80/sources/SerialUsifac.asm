;Source code from the Serial, using USIfAC interface.
        
        INTERFACE_COUNT = INTERFACE_COUNT + 1

TIMEOUT_LOOP = 5000             ;Large to manage slow replay music (25hz, etc.).

;Initializes the card. May clear the buffer.
;OUT:   Carry = 1 = OK. 0 if undetected or a problem occurred.
Initialize:
        ;Clears the buffer.
        ld a,1
        ld bc,#fbd1
        out (c),a
        
        scf
        ret

;Waits for a byte in the buffer.
;It waits indefinitely, but after a while, the PSG sound is stopped.
WaitForByteWithTimeout:
        ld bc,TIMEOUT_LOOP
        
WaitForByteWithTimeout_Loop:
        ld a,#fb
        in a,(#d1)
        dec a
        ret nz

        ;Byte not ready yet. Loop.
        dec bc
        ld a,b
        or c
        jr nz,WaitForByteWithTimeout_Loop
        ;Timeout. Stops the sound.
        call StopSounds
        jr WaitForByteWithTimeout

;Reads the byte which MUST be present in the buffer.
;OUT:   A = the byte.
ReadPresentByte:
        ld a,#fb
        in a,(#d0)
        ret